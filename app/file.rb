require 'awesome_print'
require_relative '../wire'

class Wire
	
	module Resource
		def file_root( path )
			$config[@currentURI][:resources][@currentResource][:file_root] = path
		end
	end

end

class File

	class Controller

		def self.readAll( context , request , response )
			path = context[:resource][:file_root]
			if( path != nil ) then
				if( File.directory?( path ) ) then
					"#{ap Dir.entries( path )}"
				else
					"#{path} is a file, not a folder"
				end
			else
				"Root Directory not specified"
			end
		end

		def self.read( id , context , request , response )
			path = context[:resource][:file_root]
			if( path != nil ) then
				"Requested: #{path}/#{id}"
			else
				"Root directory not specified"
			end
		end

	end

end
