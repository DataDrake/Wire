require 'dm-serializer/to_json'
require_relative '../wire'

module DB

  module Controller
		include Wire::App
    include Wire::Resource

    def self.db( namespace , location )
      $currentApp[:db_namespace] = namespace
      $currentApp[:db_location] = location
      DataMapper.setup( namespace , location )
    end

    def self.model( resource, model )
      $currentApp[:resources][resource] = {model: model}
    end

    def self.create( context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
      model = context[:resource][:model]
      if( model != nil ) then
        instance = model.create( context[:params] )
        instance.save
        if instance.saved? then
          200
        else
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
        ap context[:params]
        if instance.update( context[:params]) then
          200
        else
          500
        end
      else
        404
      end
    end
  end

end
