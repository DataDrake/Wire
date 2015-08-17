require_relative '../render'

module Render
	# Page builds the a page that is presented directly to a user
	# @author Bryan T. Meyers
	module Page
		include Render
		extend self

		# Render a full template, handling the gathering of additional Sources
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @param [Tilt::Template] template a pre-loaded Tilt template to render
		# @param [String] content the content to render into the page
		# @return [Response] a Rack Response triplet, or status code
		def render_template(actions, context, template, content)
			if template[:path]
				hash = { actions: actions, context: context, content: content }
				template[:sources].each do |k, s|
					uri = "http://#{context.app[:remote_host]}/#{s[:uri]}"
					case s[:key]
						when :user
							uri += "/#{context.user}"
						when :resource
							uri += "/#{context.uri[2]}"
					end
					begin
						temp = RestClient.get uri
					rescue RestClient::ResourceNotFound
						temp = nil
					end
					hash[k] = temp
				end
				message = template[:path].render(self, hash)
				if template[:use_layout]
					message = render_template(actions, context, $apps[:global][:template], message)
				end
			else
				message = 'Invalid Template'
			end
			message
		end

		# Render a page to its final form
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @param [Symbol] specific the kind of read to perform
		# @return [Response] a Rack Response triplet, or status code
		def do_read(actions, context, specific)
			template = context.app[:template]
			resource = context.uri[2]
			message  = 'Resource not specified'
			headers  = {}
			if resource
				begin
					result = forward(specific, context)
					if template
						message = render_template(actions, context, template, result)
					else
						headers['Content-Type'] = result.headers[:content_type]
						message                 = [200, headers, result.to_str]
					end
				rescue RestClient::ResourceNotFound
					message = 404
				end
			end
			message
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
						do_read(actions, context, :read)
					else
						do_read(actions, context, :readAll)
					end
				when :update
					forward(:update, context)
				else
					405
			end
		end
	end
end