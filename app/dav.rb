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
				mime = response.headers[:content_type]
				if( mime != nil ) then
					mime.slice(0..(mime.index(';') - 1))
				end
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
				mime = response.headers[:content_type]
				if( mime != nil ) then
					mime = mime.slice(0..(mime.index(';') - 1))
				end
				renderer = $config[:renderers][mime]
				if( renderer != nil ) then
					renderer.render( resource , id )
				else
					mime
				end
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
