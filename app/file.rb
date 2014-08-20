require 'filemagic'
require 'awesome_print'
require_relative '../wire'

class Wire
	
	module Resource
		def local_path( path )
			$config[:apps][@currentURI][:resources][@currentResource][:local_path] = path
		end
	end

end

class File

	class Controller
		extend Wire::App

		def self.readAll( context , request , response )
			context[:sinatra].pass unless (context[:resource] != nil )
				path = context[:resource][:local_path]
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
			path = context[:resource][:local_path]
			if( path != nil ) then
				ext_path = File.join( path , id )

				context[:sinatra].pass unless File.exists?(ext_path)
					if( File.directory?( ext_path ) ) then
						"#{ap Dir.entries( ext_path ).sort}"
					else
						mime = 'text/plain'
						if( ext_path.end_with?( '.wiki' ) || ext_path.end_with?( '.mediawiki' ) ) then
							mime = 'text/wiki'
						else
							mime = `mimetype --brief #{ext_path}`
						end
						response.headers['Content-Type'] = mime
						response.body = File.read( ext_path )
					end
			else
				"Root directory not specified"
			end
		end
	end

end
