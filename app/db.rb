require_relative '../wire'

class Wire
	
	module App
		def db_setup( namespace , location )
			$config[:apps][@currentURI][:db_namespace] = namespace
			$config[:apps][@currentURI][:db_location] = location
			DataMapper.setup( namespace , location )
		end
	end

	module Resource
		def model( model )
			puts 'bump'
			$config[:apps][@currentURI][:resources][@currentResource][:model] = model
		end
	end

end

class DB

	class Controller

		def self.readAll( context , request , response )
			model = context[:resource][:model]
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
			model = context[:resource][:model]
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
