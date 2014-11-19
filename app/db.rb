require 'dm-serializer/to_json'
require_relative '../wire'

class Wire
	
	module App
		def db_setup( namespace , location )
			@currentApp[:db_namespace] = namespace
			@currentApp[:db_location] = location
			DataMapper.setup( namespace , location )
		end
	end

	module Resource
		def model( model )
			@currentResource[:model] = model
		end
	end

end

class DB

  class Controller
		extend Wire::App

		def self.readAll( context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
			model = context[:resource][:model]
			if( model != nil ) then
				model.all.to_json
			else
				404
			end
		end

		def self.read( id , context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
			model = context[:resource][:model]
			if( model != nil ) then
				object = model.get( id )
				if( object != nil ) then
					return object.to_json
				end
      end
      404
		end
	end

end
