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

    # Configure repo with listing template
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure(conf)
      conf['resources'].each do |k,v|
        if v.is_a? Hash
          conf['resources'][k]['multiple'] = Tilt.new(v['multiple'], 1, { ugly: true })
          conf['resources'][k]['single'] = Tilt.new(v['single'], 1, { ugly: true })
        elsif v.is_a? String
          #TODO: fix needless duplication
          conf['resources'][k]['multiple'] = Tilt.new(v, 1, { ugly: true })
          conf['resources'][k]['single'] = Tilt.new(v, 1, { ugly: true })
        end
      end
      conf
    end

		# Read a listing and render to HTML
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read_all(actions, context)
			resource = context.uri[2]
			body = ''
			mime = ''
			if context.resource['use_forward']
				response = forward(:readAll, context)
				return response if response[0] != 200
				mime     = response[1][:content_type]
				body     = response[2]
			end
			template = context.resource['multiple']
			if template
				hash     = { actions: actions, resource: resource, mime: mime, response: body }
				if context.resource['sources']
					context.resource['sources'].each do |k, v|
						hash[k] = RL.request(:get,
																 "http://#{context.app['remote']}/#{v}",
																 {remote_user: context.user}
						)[2]
					end
				end
				mime = 'text/html'
				body = template.render(self,hash)
			end
			[200,{'Content-Type': mime },body]
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
			if context.resource['use_forward']
				response = forward(:read, context)
				return response if response[0] != 200
				mime     = response[1][:content_type]
				body     = response[2]
			end
			template = context.resource['single']
			if template
				hash     = { actions: actions, app: app, resource: resource, id: id, mime: mime, response: body }
				if context.resource['sources']
					context.resource['sources'].each do |k, v|
						hash[k] = RL.request(:get, "http://#{context.app[:remote_host]}/#{v}")[2]
					end
				end
				mime = 'text/html'
				body = template.render(self,hash)
			end
			[200,{'Content-Type': mime },body]
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