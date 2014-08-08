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
			path = context[:resource][:file_root]
			if( path != nil ) then
				context[:sinatra].pass unless File.exists?(path)
				if( File.directory?( path ) ) then
					"#{ap Dir.entries( path ).sort}"
				else
					"This is a file"
				end
			else
				"Root Directory not specified"
			end
		end

		def self.read( id , context , request , response )
			path = context[:resource][:file_root]
			if( path != nil ) then
				"Requested: #{path}/#{id}"
				ext_path = File.join( path , id )

				context[:sinatra].pass unless File.exists?(ext_path)
					if( File.directory?( ext_path ) ) then
						"#{ap Dir.entries( ext_path ).sort}"
					else
						response.headers['Content-Type'] = FileMagic.new(FileMagic::MAGIC_MIME).file(ext_path)
						response.body = File.read( ext_path )
					end
			else
				"Root directory not specified"
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
