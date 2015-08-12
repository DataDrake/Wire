require 'dm-serializer/to_json'
require_relative '../app'
require_relative '../closet/resource'

# DB is a Wire::App for generating REST wrappers for DataMapper
# @author Bryan T. Meyers
module DB
	include Wire::App
	include Wire::Resource

	# Setup a DB connection
	# @param [Symbol] namespace namespace used by DataMapper for Repositories
	# @param [String] location connection string (e.g. mysql://localhost/Foo)
	# @return [void]
	def self.db(namespace, location)
		$current_app[:db_namespace] = namespace
		$current_app[:db_location]  = location
		DataMapper.setup(namespace, location)
	end

	# Map a DataMapper::Model to a sub-URI
	# @param [String] resource the sub-URI
	# @param [Class] model the DataMapper model
	# @return [void]
	def self.model(resource, model)
		$current_app[:resources][resource] = { model: model }
	end

	# Add a new object to the DB table
	# @param [Hash] context the context for this request
	# @return [Response] a valid Rack response triplet, or status code
	def self.do_create(context)
		return 404 unless context.resource
		model = context.resource[:model]
		if model
			file = context.json[:file]
			if file
				if file[:mime].eql? 'text/csv'
					file[:content].match(/.*base64,(.*)/) do
						csv     = Base64.decode64($1)
						columns = []
						errors  = []
						csv.split("\n").each_with_index do |v, i|
							if i == 0
								columns = v.split(/(?<!\[),(?!=\])/)
								columns.map! { |c| c.delete('"').to_sym }
							else
								values = v.split(',')
								values.map! do |c|
									c.include?(';') ? c.split(';') : c
								end
								hash = {}
								columns.each_with_index do |c, j|
									if values[j].is_a? String
										values[j].delete!('"')
									end
									hash[c] = values[j]
								end
								m = model.first_or_create(hash)
								unless m.saved?
									errors << "row: #{i} errors: #{m.errors.delete("\n")}"
								end
							end
						end
						if errors.length > 0
							ap errors
							[400, nil, errors]
						else
							200
						end
					end
				else
					415
				end
			else
				if model.instance_methods.include?(:updated_by)
					context.json[:updated_by] = context.user
				end
				if model.instance_methods.include?(:created_by)
					context.json[:created_by] = context.user
				end
				instance = model.create(context.json)
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

	# Get all objects from the DB table
	# @param [Hash] context the context for this request
	# @return [Response] all objects, or status code
	def self.do_read_all(context)
		return 404 unless context.resource
		model = context.resource[:model]
		if model
			hash = '[ '
			model.all.each do |e|
				hash << (e.to_json)
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

	# Get a specific object from the DB table
	# @param [Hash] context the context for this request
	# @return [Response] an object, or status code
	def self.do_read(context)
		return 404 unless context.resource
		model = context.resource[:model]
		id    = context.uri[3]
		if id.eql?('new') or id.eql? 'upload'
			return '{}'
		end
		if model
			object = model.get(id)
			if object
				return object.to_json
			end
		end
		404
	end

	# Update a specific object in the DB table
	# @param [Hash] context the context for this request
	# @return [Response] an object, or status code
	def self.do_update(context)
		return 404 unless context.resource
		model = context.resource[:model]
		id    = context.uri[3]
		if model
			if model.respond_to?(:updated_by)
				context.json[:updated_by] = context.user
			end
			instance = model.get(id)
			instance.update(context.json) ? 200 : 500
		else
			404
		end
	end

	# Proxy method used when routing
	# @param [Array] actions the allowed actions for this URI
	# @param [Hash] context the context for this request
	# @return [Response] a Rack Response triplet, or status code
	def self.invoke(actions, context)
		case context.action
			when :create
				do_create(context)
			when :read
				if context.uri[3]
					do_read(context)
				else
					do_read_all(context)
				end
			when :update
				do_update(context)
			else
				403
		end
	end
end