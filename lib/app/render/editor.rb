require_relative '../render'

module Render

	# Editor allows a document to be displayed in an editing form
	# @author Bryan T. Meyers
	module Editor
		extend Render

		# Open an editor for a document
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] the Editor with containing document, or status code
		def self.do_read(actions, context)
			resource = context.uri[2]
			query    = context.query
			id       = context.uri[3...context.uri.length].join('/')
			response = forward(:read, context)
			return response if response[0] != 200
			body     = response[2]
			if query[:type]
				mime = query[:type]
			else
				return [404, {}, 'EDITOR: Document type not set for new document']
			end
			template = $editors[mime]
			if template
				template.render(self, { actions: actions, resource: resource, id: id, mime: mime, response: body })
			else
				body
			end
		end

		# Proxy method used when routing
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.invoke(actions, context)
			case context.action
				when :create,:update
					forward(context.action, context)
				when :read
					do_read(actions, context)
				else
					405
			end
		end
	end
end