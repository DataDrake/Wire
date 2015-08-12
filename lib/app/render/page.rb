require_relative '../render'

module Render
	module Page
		include Render
		extend self

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
						message                 = [200, headers, [result.to_str]]
					end
				rescue RestClient::ResourceNotFound
					message = 404
				end
			end
			message
		end

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