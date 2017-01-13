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

require_relative '../render'

module Render
	# Partials are URI mapped renderers which generate only a piece of a document
	# @author Bryan T.Meyers
	module Partial
		extend Render

		# DSL method to enable forwarding to remote
		# @return [void]
		def self.use_forward
			$current_resource[:forward] = true
		end

		# DSL method to pull in Source like objects
		# @param [Symbol] name the key for this item
		# @param [Hash] path the remote sub-URI for this item
		# @return [void]
		def self.extra(name, path)
			unless $current_resource[:sources]
				$current_resource[:sources] = {}
			end
			$current_resource[:sources][name] = path
		end

		# Read a listing and render to HTML
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read_all(actions, context)
			resource = context.uri[2]
			body = ''
			mime = ''
			if context.resource[:forward]
				response = forward(:readAll, context)
				return response if response[0] != 200
				mime     = response[1][:content_type]
				body     = response[2]
			end
			template = context.resource[:multiple]
			if template
				hash     = { actions: actions, resource: resource, mime: mime, response: body }
				if context.resource[:sources]
					context.resource[:sources].each do |k, v|
						hash[k] = RL.request(:get,
																 "http://#{context.app[:remote_host]}/#{v}",
																 {remote_user: context.user}
						)[2]
					end
				end
				mime = 'text/html'
				body = template.render(self,hash)
			end
			[200,{'Content-Type' => mime },body]
		end

		# Read a Partial and render it to HTML
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read(actions, context)
			app      = context.uri[1]
			resource = context.uri[2]
			id       = context.uri[3...context.uri.length].join('/')
			body = ''
			mime = ''
			if context.resource[:forward]
				response = forward(:read, context)
				return response if response[0] != 200
				mime     = response[1][:content_type]
				body     = response[2]
			end
			template = context.resource[:single]
			if template
				hash     = { actions: actions, app: app, resource: resource, id: id, mime: mime, response: body }
				if context.resource[:sources]
					context.resource[:sources].each do |k, v|
						hash[k] = RL.request(:get, "http://#{context.app[:remote_host]}/#{v}")[2]
					end
				end
				mime = 'text/html'
				body = template.render(self,hash)
			end
			[200,{'Content-Type' => mime },body]
		end

		# Proxy method used when routing
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.invoke(actions, context)
			case context.action
				when :create,:update,:delete
					forward(context.action, context)
				when :read
					if context.uri[3]
						do_read(actions, context)
					else
						do_read_all(actions, context)
					end
				else
					403
			end
		end
	end
end