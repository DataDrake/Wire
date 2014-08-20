require 'uri'
require 'nokogiri'
require 'wikicloth'
require 'redcarpet'
require 'RedCloth'
require 'rest_client'
require 'filemagic'
require 'awesome_print'
require 'docile'
require_relative '../wire'

class Wire
	
	module App

		def mime( mime )
			$config[:renderers][mime] = @currentRenderer
		end

		def remote_host( hostname )
			$config[:apps][@currentURI][:remote_host] = hostname
		end

		def remote_uri( uri )
			$config[:apps][@currentURI][:remote_uri] = uri	
		end

		def renderer( klass , &block)
			@currentRenderer = klass
			Docile.dsl_eval( self , &block )
		end

		def template( path )
			$config[:apps][@currentURI][:template] = path
		end
	end

end

class Render

	class Audio
		def self.render( resource , id , mime , content )
			"<content><div id=\"audio\" class=\"small-12 medium-12 large-12 columns\"><div id=\"title\" class=\"top\">#{id}</div><div id=\"player\" class=\"row bottom\"><audio controls=\"true\"><source src=\"/static/#{resource}/#{id}\"></source></audio></div></div></content>"
		end
	end

	module Instant
		extend Wire::App

		def self.update( id , context , request , response )

			template = context[:app][:template]
			body = request[:data]
			resource = context[:resource_name]

			message = "Resource not Specified"
			if( resource != nil ) then
				message = "Nothing to Render"
				if( body != nil ) then
					message = "Unsupported Render Type"
					renderer = $config[:renderers]["#{resource}/#{id}"]
					if( renderer != nil ) then
						result = renderer.render( resource , id , "#{resource}/#{id}" , body )
						doc = Nokogiri::XML( result.to_str )
						xslt = Nokogiri::XSLT( File.read(template) )
						message = xslt.transform( doc ).to_xml
					end
				end
			end
			message
		end
	end

	module Page

		def self.create( context , request , response )
			"Action not allowed"
		end

		def self.readAll( context , request , response )
			template = context[:app][:template]
			host = context[:app][:remote_host]
			app = context[:app][:remote_uri]
			resource = context[:resource_name]

			message = "Resource not specified"
			if( resource != nil ) then
				begin
					response = RestClient.get "http://#{host}/#{app}/#{resource}"
					"Forward Request to https://#{host + '/' + app + '/' + resource}"
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

			message = "Resource not specified"
			if( resource != nil ) then
				begin
					result = RestClient.get "http://#{host}/#{app}/#{resource}/#{id}"
					"Forward Request to https://#{host}/#{app}/#{resource}/#{id}"
					if( template != nil ) then 
						doc = Nokogiri::XML( result.to_str )
						xslt = Nokogiri::XSLT( File.read(template) )
						message = xslt.transform( doc ).to_xml
					else
						puts result.headers[:content_type]
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
			"Action not allowed"
		end

		def self.delete( id , context , request , response )
			"Action not allowed"
		end

	end

	class Image
		def self.render( resource , id , mime , content )
			"<content><img src=\"/static/#{resource}/#{id}\"></img></content>"
		end
	end

	class ML
		def self.render( resource , id , mime , content )
			result = ""
			case( mime )
				when 'text/html'
					xml = Nokogiri::XML( content )
					result = xml.at('body')
				when 'application/xml'
					result = content
			end
			"<content><div id=\"ml\" class=\"small-12 medium-12 large-12 columns\"><div class=\"top row\">#{id}</div><div class=\"bottom row\">#{result}</div></div></content>"
		end
	end

	class Video
		def self.render( resource , id , mime , content )
			"<content><div id=\"video\" class=\"small-12 medium-12 large-12 columns\"><div class=\"top\">#{id}</div><div class=\"row bottom\"><div class=\"small-12 medium-8 large-6 large-centered columns\"><video controls=\"true\"><source src=\"/static/#{resource}/#{id}\"></source></video></div></div></div></content>"
		end
	end

	class Wiki

		@@markdown = Redcarpet::Markdown.new( Redcarpet::Render::XHTML , tables: true)

		def self.render( resource , id , mime , content )
			result = ""
			case (mime)
				when 'text/wiki'
					result = WikiCloth::Parser.new( :data => content , :noedit => true ).to_html
				when 'text/x-markdown'
					result = @@markdown.render( content )
				when 'text/x-textile'
					result = RedCloth.new( content ).to_html
			end
			"<content><div id=\"wiki\" class=\"small-12 medium-12 large-12 columns\"><div class=\"top\"><h1>#{id.capitalize}</h1></div><div class=\"bottom row\">#{result}</div></div></div></content>"
		end
	end
	
end
