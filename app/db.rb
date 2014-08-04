require_relative '../wire'

class Wire
	
	module App
		def db_setup( namespace , location )
			$config[@currentURI][:db_namespace] = namespace
			$config[@currentURI][:db_location] = location
			DataMapper.setup( namespace , location )
		end
	end

	module Resource
		def db_model( model )
			$config[@currentURI][:resources][@currentResource][:db_model] = model
		end
	end

end

class DB

	class Controller

		def self.readAll( context , request , response )
			model = context[:resource][:db_model]
			if( model != nil ) then
				items = model.all
				items.map do |item|
					model.inflate( item )
				end
				items
			else
				"Undefined DB Model"
			end
		end

		def self.read( id , context , request , response )
			model = context[:resource][:db_model]
			if( model != nil ) then
				hash = model.get( id )
				if( hash != nil ) then
					model.inflate( hash )
				else
					"Could Not Find record #{id}"
				end
			else
				"Undefined DB Model"
			end
		end

	end

end
