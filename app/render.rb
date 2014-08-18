require 'nokogiri'
require 'wikicloth'
require 'redcarpet'
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

	module Page

		def self.create( context , request , response )
			"Action not allowed"
		end

		def self.readAll( context , request , response )
			template = context[:app][:template]
			host = context[:app][:remote_host]
			app = context[:app][:remote_uri]
			resource = context[:resource_name]
			if( resource != nil ) then
				begin
					response = RestClient.get "http://#{host}/#{app}/#{resource}"
					"Forward Request to https://#{host + '/' + app + '/' + resource}"
					response.to_str
				rescue RestClient::ResourceNotFound
					"File not found at http://#{host}/#{app}/#{resource}"
				end
			else
				"Resource not specified"
			end
		end

		def self.read( id , context , request , response )
			template = context[:app][:template]
			host = context[:app][:remote_host]
			app = context[:app][:remote_uri]
			resource = context[:resource_name]
			if( resource != nil ) then
				begin
					result = RestClient.get "http://#{host}/#{app}/#{resource}/#{id}"
					"Forward Request to https://#{host}/#{app}/#{resource}/#{id}"
					if( template != nil ) then 
						doc = Nokogiri::XML( result.to_str )
						xslt = Nokogiri::XSLT( File.read(template) )
						xslt.transform( doc ).to_s
					else
						puts result.headers[:content_type]
						response.headers['Content-Type'] = result.headers[:content_type]
						response.body = result.to_str
					end
				rescue RestClient::ResourceNotFound
					"File not found at http://#{host}/#{app}/#{resource}/#{id}"
				end
			else
				"Resource not specified"
			end
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
			end
			"<content><div id=\"wiki\">#{result}</div></content>"
		end
	end
	
end
