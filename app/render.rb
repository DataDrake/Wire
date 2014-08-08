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

	class Controller

		def self.create( context , request , response )
			"Action not allowed"
		end

		def self.readAll( context , request , response )
			template = context[:app][:template]
			path = context[:id]
			if( path != nil ) then
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
			template = context[:app][:template]
			path = context[:id]
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

	class Image

	end

	class ML

	end

	class Page

	end

	class Video

	end

	class Wiki

	end
	
end
