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
					go_ahead = true
					case s[:key]
						when :user
							go_ahead = (context.user and !context.user.empty?)
							uri += "/#{context.user}"
						when :resource
							go_ahead = (context.uri[2] and !context.uri[2].empty?)
							uri += "/#{context.uri[2]}"
					end
					temp = []
					if go_ahead
							temp = RL.request(:get, uri, {remote_user: context.user})
					end
					hash[k] = (temp[0] == 200) ? temp[2] : nil
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
			resource = context.uri[2]
			if resource
				result = forward(specific, context)
				template = context.app[:template]
				if template
					result[1]['Content-Type'] = 'text/html'
					result[2] = render_template(actions, context, template, result[2])
				end
			else
				result = [401,{},'Resource not specified']
			end
			result
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
						do_read(actions, context, :read)
					else
						do_read(actions, context, :readAll)
					end
				else
					405
			end
		end
	end
end
