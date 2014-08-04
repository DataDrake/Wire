require 'singleton'
require 'sinatra/base'

$resources = {}

class Web
	include Singleton

	@@sinatra = Sinatra.new

	def run!
		puts @@sinatra.routes
		@@sinatra.run!
	end

	def sinatra
		@@sinatra
	end
end

class Wire

	class Closet
 
		def initialize
			@apps = {}
		end

		def build( &block )
			puts "Starting Up Wire..."
			puts "Starting Apps..."
			Docile.dsl_eval( self , &block )
		end

		def group( app , &block)
			@appType = app
			Docile.dsl_eval( self, &block )
		end

		def app( uri , &block )
			@apps[uri] = @appType.new( uri )
			Docile.dsl_eval( @apps[uri] , &block )
		end

		def info
			puts "Wire Instance Info\n\nApps:"
			@apps.each do |n ,a|
				a.info()
			end
		end

		def run
			Web.instance.run!
		end
	end

	module App
		attr_reader :baseURI

		def initialize( baseURI )
			@baseURI = baseURI
			@resources = {}
			@type = 'Wire'
			puts "Starting App at: #{baseURI}"
			puts "Setting up resources..."
		end

		def resource( uri , &block)
			@resources[uri] = builder.new( uri, @baseURI )
			$resources[ (@baseURI + uri) ] = @resources[uri]
			if( respond_to? :finish ) then
				puts "Bob can build it"
				finish(uri)
			end
			Docile.dsl_eval( @resources[uri] , &block )
		end

		def info
			puts "\t#{@type} App URI: #{@baseURI}"
			puts "\n\tResources:"
			@resources.each do |n,r|
				r.info()
			end
			puts "\n"
		end
	end

	module Resource

		attr_reader :uri

		def initialize( uri , parentURI )
			@uri = parentURI + uri
			@actions = []
			@create = {}
			@read = {}
			@update = {}
			@delete = {}
			puts "Starting Resource At: #{@uri}"
			puts "Creating actions..."
		end

		def action( name )
			puts "Enabling Action: #{name}"
			@actions << name

			case name
				when 'create'
					
					Web.instance.sinatra.put(@uri) do
						$resources[request.path].create( request , response , params)
					end
				when 'read'
                                        Web.instance.sinatra.get(@uri) do 
                                                $resources[request.path].readAll( params )
                                        end
					Web.instance.sinatra.get(@uri + "/:id") do
						$resources[request.path].read( request, response, params )
					end
				when 'update'
					@update.each do |uri, proc|
						Web.instance.sinatra.post(@uri + uri) do 
                                                        $resources[request.path].instance_eval( &proc )
                                                end
                                        end
				when 'delete'
					@delete.each do |uri, proc|
						Web.instance.sinatra.delete(@uri + uri) do 
                                                        $resources[request.path].instance_eval( &proc )
                                                end
                                        end
			end
		end

		def info
			puts "\t\tResource URI: #{@uri}"
			puts "\t\tActions Allowed:"
			@actions.each do |a|
				puts "\t\t\t#{a}"
			end
			puts "\n"
		end
	end
end
