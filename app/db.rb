require_relative '../wire'

class DB

	class Resource
		include Wire::Resource

		def initialize( uri , parentURI )
			super( uri, parentURI )


		@create[""] = Proc.new do
			hash = request.body
			hash = @model.flatten( hash )
			@model.create( hash )
		end

		def readAll( params )
			items = @model.all
			items.map do |item|
				@model.inflate( item )
			end
			items
		end

		def read( request, response, params )
			hash = @model.get( params[:id] )
			@model.inflate( hash )
		end

		@update["/:id"] = Proc.new do
			hash = request.body
			hash = @model.flatten( hash )
			hash = @model.update( hash )
			@model.inflate( hash )
		end

		@delete["/id"] = Proc.new do
			hash = request.body
			@model.delete( hash )
		end

		end

		def enableRead
			read_all = Proc.new do
				puts "Namespace: #{@namespace}"
				DataMapper.repository(@namespace) do
					@model.all
				end
			end
                        Web.instance.sinatra.get(@uri) do
				puts self.instance_variables
				puts request.path
				puts $resources[request.path].class
				$resources[request.path].instance_eval( &read_all )
			end
		end

		def enableUpdate

		end

		def enableDelete

		end

		def db_model( klass )
			@model = klass
		end

		def db_namespace( ns )
			@namespace = ns
		end
		
		def info
			super
			puts "\t\tDB Model: #{@model}"
			puts "\n"
		end
	end

	class App
		include Wire::App

		def builder
			@type = 'DB'
			DB::Resource
		end

		def db_setup( ns , server )
			@namespace = ns
			@server = server
			DataMapper::Logger.new($stdout, :debug)
			DataMapper.setup( @namespace , @server )
		end

		def finish( uri )
			@resources[uri].db_namespace( @namespace )
		end

		def info
			super
			puts "\tDB Namespace: #{@namespace}"
			puts "\tDB Server: \'#{@server}\'"
			puts "\n"
		end
	end

end
