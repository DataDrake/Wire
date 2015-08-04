require 'dm-serializer/to_json'
require_relative '../app'
require_relative '../resource'

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

    def self.do_create( context , request , response , actions)
      context[:sinatra].pass unless (context[:resource] != nil )
      model = context[:resource][:model]
      if( model != nil ) then
        file = context[:params]['file']
        if file
          if file['mime'].eql? 'text/csv'
            file['content'].match(/.*base64,(.*)/) do
              csv = Base64.decode64($1)
              columns = []
              errors = []
              csv.split("\n").each_with_index do |v,i|
                if i == 0
                  columns = v.split(/(?<!\[),(?!=\])/)
                  columns.map! { |v| v.delete('"').to_sym }
                else
                  values = v.split(',')
                  values.map! do |v|
                    if v.include? ';'
                      v.split(';')
                    else
                      v
                    end
                  end
                  hash = {}
                  columns.each_with_index do |c, i|
                    if values[i].is_a? String
                      values[i].delete!('"')
                    end
                    hash[c] = values[i]
                  end
                  m = model.first_or_create( hash )
                  unless m.saved?
                    errors << "row: #{i} errors: #{m.errors.delete("\n")}"
                  end
                end
              end
              if errors.length > 0
                ap errors
                [400, nil ,errors]
              else
                200
              end
            end
          else
            415
          end
        else
          if model.instance_methods.include?(:updated_by) then
            context[:params][:updated_by] = context[:user]
          end
          if model.instance_methods.include?(:created_by) then
            context[:params][:created_by] = context[:user]
          end
          instance = model.create( context[:params] )
          instance.save
          if instance.saved? then
            200
          else
            ap instance.errors
            504
          end
        end
      else
        404
      end
    end

		def self.do_readAll( context , request , response , actions )
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

		def self.do_read( id , context , request , response , actions)
      context[:sinatra].pass unless (context[:resource] != nil )
			model = context[:resource][:model]
      if id.eql?('new') or id.eql? 'upload' then
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

    def self.do_update( id, context , request , response , actions)
      context[:sinatra].pass unless (context[:resource] != nil )
      model = context[:resource][:model]
      if( model != nil ) then
        if model.respond_to?(:updated_by) then
            context[:params][:updated_by] = context[:user]
        end
        instance = model.get(id)
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