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
			begin
				mime = ''
				body = ''
				if context.resource[:forward]
					response = forward(:readAll, context)
					mime     = response.headers[:content_type]
					body     = response.body
				else
					body = 401
				end

				template = context.resource[:multiple]
				hash     = { actions: actions, resource: resource, mime: mime, response: body }
				if context.resource[:sources]
					context.resource[:sources].each do |k, v|
						hash[k] = RestClient.get("http://#{context.app[:remote_host]}/#{v}")
					end
				end
				mime = 'text/html'
				if template
					[200, { 'Content-Type' => mime }, [template.render(self, hash)]]
				else
					[200, { 'Content-Type' => mime }, [body]]
				end
			rescue RestClient::ResourceNotFound
				404
			end
		end

		# Read a Partial and render it to HTML
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read(actions, context)
			app      = context.app[:uri]
			resource = context.uri[2]
			begin
				response = forward(:read, context)
				mime     = response.headers[:content_type]
				template = context.resource[:single]
				id       = context.uri[3...context.uri.length].join('/')
				hash     = { actions: actions, app: app, id: id, resource: resource, mime: mime, response: response.body }
				if context.resource[:sources]
					context.resource[:sources].each do |k, v|
						hash[k] = RestClient.get("http://#{context.app[:remote_host]}/#{v}")
					end
				end
				if template
					[200, { 'Content-Type' => 'text/html' }, [template.render(self, hash)]]
				else
					[200, { 'Content-Type' => 'text/plain' }, [response.body]]
				end
			rescue RestClient::ResourceNotFound
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
					forward(:create, context)
				when :read
					if context.uri[3]
						do_read(actions, context)
					else
						do_read_all(actions, context)
					end
				when :update
					forward(:update, context)
				when :delete
					forward(:delete, context)
				else
					403
			end
		end
	end
end