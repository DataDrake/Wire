require_relative '../render'

module Render
	module Instant
		extend Render

		def self.do_update(actions, context)
			body = context.body
			if body
				body = body.split('=')[1]
				if body
					body = URI.decode(body)
				end
			end
			resource = context.uri[2]
			id       = context.uri[3]
			## Default to not found
			message  = ''
			status   = 404
			if resource
				if body
					## Assume unsupported mime type
					status   = 415
					message  = 'INSTANT: Unsupported MIME Type'
					renderer = $renderers["#{resource}/#{id}"]
					if renderer
						template = $templates[renderer]
						result   = template.render(self,
																			 { actions:  actions,
																				 context:  context,
																				 mime:     "#{resource}/#{id}",
																				 response: body,
																			 })
						template = context.app[:template]
						if template
							message = template[:path].render(self, { actions: actions, context: context, content: result })
						else
							message = result
						end
						status = 200
					end
				end
			end
			[status, {}, message]
		end

		def self.invoke(actions, context)
			if context.action.eql? :update
				do_update(actions, context)
			else
				405
			end
		end
	end
end