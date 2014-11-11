require 'nokogiri'
require 'wikicloth'
require 'redcarpet'
require 'RedCloth'
require 'rest_client'
require 'awesome_print'
require 'docile'
require 'tilt'
require_relative '../wire'



class Wire
	module App

		def remote_host( hostname )
			@currentApp[:remote_host] = hostname
		end

		def remote_uri( uri )
			@currentApp[:remote_uri] = uri	
		end

		def template( path , &block)
			@currentApp[:template] = { path: path , sources: {} }
			if( block != nil ) then
				Docile.dsl_eval( self  , &block )
			end
		end

		def source( uri , &block )
			@currentApp[:template][:sources][uri] = { key: nil }
			@currentSource = @currentApp[:template][:sources][uri]

			if( block != nil ) then
				Docile.dsl_eval( self , &block )
			end
		end

		def key( type )
			@currentSource[:key] = type
		end
  end

  module Renderer

    def renderer( klass , &block)
      @currentRenderer = klass
      Docile.dsl_eval( self , &block )
    end

    def partial( template )
      @currentTemplate = Tilt.new( template )
    end

    def mime( mime )
      $config[:renderers][mime] = @currentRenderer
      $config[:templates][@currentRenderer] = @currentTemplate
    end

  end

  class Closet
    include Wire::Renderer
  end
end

class Render

	def self.localContext( id , context )
		hash = {}
		t = context[:app][:template]
		if( t != nil ) then
			hash[:path] = t[:path]
			hash[:sources] = t[:sources]
		end
		hash[:resource] = context[:resource_name]
		hash[:host] = context[:app][:remote_host]
		hash[:app] = context[:app][:remote_uri]
		hash[:resource] = context[:resource_name]
		hash[:user] = context[:user]
		hash
	end

  module Document
    extend Wire::App
    def self.read( id , context , request , response )
      host = context[:app][:remote_host]
      path = context[:app][:remote_uri]
      resource = context[:resource_name]
      begin
        response = RestClient.get "http://#{host}/#{path}/#{resource}/#{id}"
        mime = response.headers[:content_type]
        renderer = $config[:renderers][mime]
        if( renderer != nil ) then
          template = $config[:templates][renderer]
          template.render( self, {resource: resource, id: id , mime: mime , response: response.body} )
        else
          mime
        end
      rescue RestClient::ResourceNotFound
        "File Not Found at http://#{host}/#{path}/#{resource}/#{id}"
      end
    end
  end

  module Partial

  end

	module Instant
		extend Wire::App

		def self.update( id , context , request , response )

			local = Render.localContext( id , context )

			body = request[:data]
			resource = local[:resource]

			message = 'Resource not Specified'
			if( resource != nil ) then
				message = 'Nothing to Render'
				if( body != nil ) then
					message = 'Unsupported Render Type'
					renderer = $config[:renderers]["#{resource}/#{id}"]
					if( renderer != nil ) then
						doc = Nokogiri::XML('<page></page>')
            template = $config[:templates][renderer]
						result = template.render(self,{resource: resource , mime: "#{resource}/#{id}" , id: id , response: body} )
						doc2 = Nokogiri::XML( result.to_str )
						doc.root.add_child( doc2.root )
						local[:sources].each do |k , v|
							url = "http://#{local[:host]}/#{k}"
							content = ''
							if( v[:key] != nil ) then
								case( v[:key] )
									when :user
										url = url + "/#{local[:user]}"
								end
							end
							begin
								content = RestClient.get( url )
							rescue
								content = '<failure>nothing returned</failure>'
							end
							doc2 = Nokogiri::XML( content.to_str )
							doc.root.add_child( doc2.root )
						end
						xslt = Nokogiri::XSLT( File.read(local[:path]) )
						message = xslt.transform( doc ).to_xml
					end
				end
			end
			message
		end
	end

	module Page

		def self.create( context , request , response )
			'Action not allowed'
		end

		def self.readAll( context , request , response )
			template = context[:app][:template]
			host = context[:app][:remote_host]
			app = context[:app][:remote_uri]
			resource = context[:resource_name]

			message = 'Resource not specified'
			if( resource != nil ) then
				begin
					response = RestClient.get "http://#{host}/#{app}/#{resource}"
					puts "Forward Request to https://#{host + '/' + app + '/' + resource}"
					message = response.to_str
				rescue RestClient::ResourceNotFound
					message = "File not found at http://#{host}/#{app}/#{resource}"
				end
			end
			message
		end

		def self.read( id , context , request , response )
			template = context[:app][:template]
			host = context[:app][:remote_host]
			app = context[:app][:remote_uri]
			resource = context[:resource_name]
			sources = template[:sources]
			message = 'Resource not specified'
			if( resource != nil ) then
				begin
					result = RestClient.get "http://#{host}/#{app}/#{resource}/#{id}"
					puts "Forward Request to https://#{host}/#{app}/#{resource}/#{id}"
					if( template[:path] != nil ) then
						page = "<page>#{result.to_str}"
						sources.each do |k,s|
							uri = "http://#{host}/#{k}"
							case s[:key]
								when :user 
									uri += "/#{context[:user]}"
								else
									#do nothing
							end
							temp = RestClient.get uri
							page += temp.to_str
						end
						page += '</page>'
						puts page
						doc = Nokogiri::XML( page.to_str )

						xslt = Nokogiri::XSLT( File.read(template[:path]) )
						message = xslt.transform( doc , context[:params] ).to_xml
					else
						response.headers['Content-Type'] = result.headers[:content_type]
						message = result.to_str
					end
				rescue RestClient::ResourceNotFound
					message = "File not found at http://#{host}/#{app}/#{resource}/#{id}"
				end
			end
			message
		end

		def self.update( id , context , request , response )
			'Action not allowed'
		end

		def self.delete( id , context , request , response )
			'Action not allowed'
		end

  end

  $markdown = Redcarpet::Markdown.new( Redcarpet::Render::XHTML , tables: true)
	
end
