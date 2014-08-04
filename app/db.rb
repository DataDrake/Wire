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

	class Resource

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

	end

	class App
		include Wire::App

		def resource
			DB::Resource
		end

	end

end
