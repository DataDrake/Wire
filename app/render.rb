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
					response = RestClient.get "http://#{host}/#{app}/#{resource}/#{id}"
					"Forward Request to https://#{host}/#{app}/#{resource}/#{id}"
					response.to_str
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

	end

	class ML

	end

	class Video

	end

	class Wiki

	end
	
end
