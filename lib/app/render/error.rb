require_relative '../render'

module Render
	module Error
		extend Render

		def self.error(match, path)
			unless $current_app[:errors]
				$current_app[:errors] = {}
			end
			$current_app[:errors][match] = Tilt.new(path, 1, { ugly: true })
		end

		def self.error_check(actions, context, result)
			errors = context.app[:errors]
			if errors
				template = errors[result[0]]
				if template
					result[2] = template.render(self, {actions: actions, context: context, result: result})
				end
			end
			result
		end

		def self.invoke(actions, context)
			case context.action
				when :create,:update
					result = forward(context.action, context)
				when :read
					if context.uri[3]
						result = forward(:read, context)
					else
						result = forward(:readAll, context)
					end
				else
					result = 405
			end
			error_check(actions, context, result)
		end
	end
end