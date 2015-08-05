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

    def self.do_create( actions , context )
      return 404 unless context[:resource]
      model = context[:resource][:model]
      if model
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
                  columns.map! { |c| c.delete('"').to_sym }
                else
                  values = v.split(',')
                  values.map! do |c|
                    c.include? ';' ? c.split(';') : c
                  end
                  hash = {}
                  columns.each_with_index do |c, j|
                    if values[j].is_a? String
                      values[j].delete!('"')
                    end
                    hash[c] = values[j]
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
          if model.instance_methods.include?(:updated_by)
            context[:params][:updated_by] = context[:user]
          end
          if model.instance_methods.include?(:created_by)
            context[:params][:created_by] = context[:user]
          end
          instance = model.create( context[:params] )
          instance.save
          if instance.saved?
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

		def self.do_read_all( actions, context )
      return 404 unless context[:resource]
			model = context[:resource][:model]
			if model
        hash = '[ '
        model.all.each do |e|
          hash << ( e.to_json )
          if e != model.all.last
            hash << ','
          end
        end
        hash << ']'
        hash
			else
				404
			end
		end

		def self.do_read( actions , context )
      return 404 unless context[:resource]
			model = context[:resource][:model]
      if id.eql?('new') or id.eql? 'upload'
        return '{}'
      end
			if model
				object = model.get( id )
				if object
					return object.to_json
				end
      end
      404
    end

    def self.do_update( actions , context )
      return 404 unless (context[:resource] != nil )
      model = context[:resource][:model]
      if model
        if model.respond_to?(:updated_by)
            context[:params][:updated_by] = context[:user]
        end
        instance = model.get(id)
        instance.update( context[:params]) ? 200 : 500
      else
        404
      end
    end

    def self.invoke( actions , context )
      case context[:action]
        when :create
          do_create( actions , context )
        when :read
          if context[:uri][3]
            do_read( actions , context )
          else
            do_read_all( actions , context )
          end
        when :update
          do_update( actions , context )
        else
          403
      end
    end
  end
end