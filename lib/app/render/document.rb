require_relative '../render'

module Render
	# Document renders a file to an HTML representation
	# @author Bryan T. Meyers
	module Document
		extend Render

		# Renders a document or listing to HTML
		# @param [Array] actions the actions allowed for this URI
		# @param [Wire::Context] context the context for this request
		# @param [Symbol] specific the type of read to perform
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read(actions, context, specific)
			response = forward(specific, context)
			mime     = response[1]['Content-Type']
			renderer = $renderers[mime]
			if renderer
				template = $templates[renderer]
				template.render(self, { actions: actions, context: context, mime: mime, response: response[2] })
			else
				response
			end
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