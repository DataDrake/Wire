require 'awesome_print'
require 'singleton'
require 'sinatra/base'

class Sinatra::Base
	def prepare( appName , resourceName )
		hash = {:failure => false}
		hash[:sinatra] = self
		app = $config[:apps][appName]
		if( app != nil ) then
			hash[:app] = app
			resource = app[:resources][resourceName]
			if( resource != nil ) then
				hash[:resource] = resource
			end
			type = app[:type]
			if( type != nil ) then
				hash[:controller] = type
			else
				hash[:message] = "Application type Not Specified"
				hash[:failure] = true
			end
		else
			hash[:message] = "App Undefined"
			hash[:failure] = true
		end
		hash
	end	
end

class Wire

	module App

		def app( baseURI , &block)
			$config[:apps][baseURI] = {:resources => {}}
			@currentURI = baseURI
			puts "Starting App at: /#{baseURI}"
			puts "Setting up resources..."
			Docile.dsl_eval( self, &block )
		end

		def type( type )
			$config[:apps][@currentURI][:type] = type
		end

		def app_info( uri , config )
			puts "\t#{config[:type]} URI: /#{uri}"

			if( !config[:resources].empty? ) then
				puts "\n\tResources:"
				config[:resources].each do |uri, config|
					resource_info( uri , config )
				end
			end
			puts "\n"
		end
	end

	module Resource

		def resource( uri , &block )
			$config[:apps][@currentURI][:resources][uri] = {}
			@currentResource = uri
			puts "Starting Resource At: /#{@currentURI + '/' + uri}"
			Docile.dsl_eval( self , &block )
		end

		def resource_info( uri , config )
			puts "\t\tResource URI: /#{uri}"
			puts "\n"
		end
	end

	class Closet
		include Wire::App
		include Wire::Resource

		def initialize
			@sinatra = Sinatra.new

			## Create One or More
			@sinatra.put("/:app/:resource") do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( $auth.create?(a , r , session[:username] ) ) then
						context[:controller].create( context , request , response )
					else
						"Operation not allowed"
					end

				else
					context[:message]
				end
			end

			## Read all
			@sinatra.get("/:app/:resource") do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( $auth.readAll?( a , r , session[:username] ) ) then
						context[:controller].readAll( context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Read One
			@sinatra.get("/:app/:resource/*") do | a , r , i |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( $auth.read?( a , r , i , session[:username] ) ) then
						context[:controller].read( i , context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Update One or More
			@sinatra.post("/:app/:resource" ) do | a , r |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( $auth.update?( a , r , session[:username] ) ) then
						context[:controller].update( context , request , response )
					else
						"Operation not allowed"
					end
				else
					context[:message]
				end
			end

			## Delete One
			@sinatra.delete("/:app/:resource/*") do | a , r , i |
				context = prepare( a , r )
				if( !context[:failure] ) then
					if( $auth.delete?( a , r , i , session[:username] ) ) then
						context[:controller].delete( i , context , request , response )
					else
						"Operation not permitted"
					end
				else
					context[:message]
				end
			end

			$config = { :apps => {} , :renderers => {} }
		end

		def auth( auth )
			$auth = auth.new
		end

		def build( &block )
			puts "Starting Up Wire..."
			puts "Starting Apps..."
			Docile.dsl_eval( self , &block )
		end

		def info
			puts "Wire Instance Info\n\nApps:"
			$config[:apps].each do |uri , config|
				app_info( uri , config )
			end
		end

		def run
			ap $config
			puts @sinatra.routes
			@sinatra.run!
		end
	end
end
