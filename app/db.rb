require 'dm-serializer/to_json'
require 'mash'
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

    def self.create( context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
      model = context[:resource][:model]
      if( model != nil ) then
        ap context[:params]
        instance = model.create( context[:params] )
        instance.save
        ap instance
        if instance.saved? then
          200
        else
          ap instance.errors
          504
        end
      else
        404
      end
    end

		def self.readAll( context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
			model = context[:resource][:model]
			if( model != nil ) then
        hash = '[ '
        model.all.each do |e|
          hash << ( e.to_json )
          if e != model.all.last then
            hash << ','
          end
        end
        hash << ']'
        ap hash
        hash
			else
				404
			end
		end

		def self.read( id , context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
			model = context[:resource][:model]
      if id.eql?('new') then
        return '{}'
      end
			if( model != nil ) then
				object = model.get( id )
				if( object != nil ) then
          ap object.to_json
					return object.to_json
				end
      end
      404
    end

    def self.update( id, context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
      model = context[:resource][:model]
      if( model != nil ) then
        instance = model.get(id)
        ap instance
        if instance.update( context[:params]) then
          200
        else
          ap instance.errors
          504
        end
      else
        404
      end
    end
  end

end
