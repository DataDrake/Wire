require 'nokogiri'
require 'wikicloth'
require 'redcarpet'
require 'RedCloth'
require 'rest_client'
require 'awesome_print'
require 'docile'
require 'tilt'
require 'json'
require_relative '../wire'

$markdown = Redcarpet::Markdown.new( Redcarpet::Render::XHTML , tables: true)

class Wire
	module App

		def remote_host( hostname )
			@currentApp[:remote_host] = hostname
		end

		def remote_uri( uri )
			@currentApp[:remote_uri] = uri	
		end

		def template( path , &block)
			@currentApp[:template] = { path: path.nil? ? nil : Tilt.new( path ) , sources: {} }
			if( block != nil ) then
				Docile.dsl_eval( self  , &block )
			end
    end

    def use_layout( truth )
      @currentApp[:template][:use_layout] = truth
    end

		def source( key, uri , &block )
			@currentApp[:template][:sources][key] = { uri:uri, key: nil }
			@currentSource = @currentApp[:template][:sources][key]

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

	def self.localContext( context )
		hash = {}
		template = context[:app][:template]
		if( template != nil ) then
			hash[:path] = template[:path]
			hash[:sources] = template[:sources]
      hash[:use_layout] = template[:use_layout]
    end
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

  module Page
    extend Wire::App

    def self.renderTemplate( context, template , content)
      if( template[:path] != nil ) then
        hash = {content: content}
        template[:sources].each do |k,s|
          uri = "http://#{context[:app][:remote_host]}/#{s[:uri]}"
          case s[:key]
            when :user
              uri += "/#{context[:user]}"
            else
              #do nothing
          end
          temp = RestClient.get uri
          hash[k] = temp.to_str
        end
        ap hash
        message = template[:path].render(self, hash )
        if template[:use_layout] then
          message = renderTemplate(context, $config[:apps][:global][:template] ,  message)
        end
      else
        message = 'Invalid Template'
      end
      message
    end

    def self.readAll( context , request , response )
      template = context[:app][:template]
      host = context[:app][:remote_host]
      app = context[:app][:remote_uri]
      resource = context[:resource_name]
      message = 'Resource not specified'
      if( resource != nil ) then
        begin
          result = RestClient.get "http://#{host}/#{app}/#{resource}"
          puts "Forward Request to http://#{host}/#{app}/#{resource}"
          if(template != nil) then
            message = renderTemplate( context, template , result )
          else
            response.headers['Content-Type'] = result.headers[:content_type]
            message = result.to_str
          end
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
      message = 'Resource not specified'
      if( resource != nil ) then
        begin
          result = RestClient.get "http://#{host}/#{app}/#{resource}/#{id}"
          puts "Forward Request to https://#{host}/#{app}/#{resource}/#{id}"
          if(template != nil) then
            message = renderTemplate( context, template , result )
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
  end

	module Instant
		extend Wire::App

		def self.update( id , context , request , response )

			local = Render.localContext( context )

			body = request[:data]
			resource = context[:resource_name]

			message = 'Resource not Specified'
			if( resource != nil ) then
				message = 'Nothing to Render'
				if( body != nil ) then
					message = 'Unsupported Render Type'
					renderer = $config[:renderers]["#{resource}/#{id}"]
					if( renderer != nil ) then
            template = $config[:templates][renderer]
						result = template.render(self,{resource: resource , mime: "#{resource}/#{id}" , id: id , response: body} )
						message = Tilt.new( local[:path] ).render( self , {content: result})
					end
				end
			end
			message
		end
	end
end
