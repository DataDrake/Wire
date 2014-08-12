require 'rest_client'
require 'filemagic'
require 'awesome_print'
require_relative '../wire'

class Wire
	
	module App
		def dav_host( path )
			$config[@currentURI][:dav_host] = path
		end
	end

end

class DAV

	class Controller

		def self.create( context , request , response )
			"Action not allowed"
		end

		def self.readAll( context , request , response )
			host = context[:app][:remote_host]
			path = context[:app][:remote_uri]
			resource = context[:resource_name]
			begin
				response = RestClient.get "http://#{host}/#{path}/#{resource}" ,{ :from => context[:user] }
				response.code
			rescue RestClient::ResourceNotFound
				"File Not Found at http://#{host}/#{path}/#{resource}"
			end
		end

		def self.read( id , context , request , response )
			host = context[:app][:remote_host]
			path = context[:app][:remote_uri]
			resource = context[:resource_name]
			begin
				response = RestClient.get "http://#{host}/#{path}/#{resource}/#{id}"
				response.code
			rescue RestClient::ResourceNotFound
				"File Not Found at http://#{host}/#{path}/#{resource}/#{id}"
			end
		end

		def self.update( id , context , request , response )
			"Action not allowed"
		end

		def self.delete( id , context , request , response )
			"Action not allowed"
		end

	end

end
