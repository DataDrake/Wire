##
# Copyright 2017 Bryan T. Meyers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
##

require 'sequel'
require_relative '../app'

# DB is a Wire::App for generating REST wrappers for DataMapper
# @author Bryan T. Meyers
module DB

  # DB-specific configuration
  # @param [Hash] conf the existing configuration
  # @return [Hash] post-processed configuration
  def self.configure(conf)
    Sequel.connect($environment['db'][conf['db']])
    conf['models'].each do |m|
      conf['models'][m] = Object.const_get(m)
    end
    conf
  end

	# Add a new object to the DB table
	# @param [Hash] context the context for this request
	# @return [Response] a valid Rack response triplet, or status code
	def self.do_create(context)
		return 404 unless context.resource
		model = context.app['models'][context.resource]
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
								m = model.find_or_create(hash)
								unless m.saved?
									errors << "row: #{i} errors: #{m.errors.delete("\n")}"
								end
							end
						end
						if errors.length > 0
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
				begin
					instance = model.create(context.json)
					instance.save
					if instance.saved?
						200
					else
						errors = ''
						instance.errors.each { |e| errors += "#{e.to_s}\n"}
						[504,{}, errors]
					end
				rescue => e
					case e.class
						when DataObjects::IntegrityError.class
							[400,{},e.message]
						else
							[500,{},e.message]
					end
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
			[200,{},hash]
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
				return [200,{},object.to_json]
			end
		end
		[404,{},[]]
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
			instance.update(context.json)
		else
			404
		end
	end

	# Remove a specific object from the DB table
	# @param [Hash] context the context for this request
	# @return [Response] an object, or status code
	def self.do_delete(context)
		return 404 unless context.resource
		model = context.resource[:model]
		id    = context.uri[3]
		if model
			instance = model.get(id)
			if instance
				if instance.destroy
					200
				else
					[500,{},'Failed to delete instance']
				end
			else
				404
			end
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
			when :delete
				do_delete(context)
			else
				403
		end
	end
end
