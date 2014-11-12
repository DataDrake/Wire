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
			model = context[:resource][:model]
			if( model != nil ) then
				model.all.to_json
			else
				'Undefined DB Model'
			end
		end

		def self.read( id , context , request , response )
			model = context[:resource][:model]
			if( model != nil ) then
				object = model.get( id )
				if( object != nil ) then
					object.to_json
				else
					"Could Not Find record #{id}"
				end
			else
				'Undefined DB Model'
			end
		end

	end

end
