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

		def self.error_check(context, result)
			errors = context.app[:errors]
			if errors
				template = errors[result.first]
				if template
					result[2] = template.render(self, locals: {context: context, result: result})
				end
			end
			result
		end

		def self.invoke(actions, context)
			begin
				case context.action
					when :create
						result = forward(:create, context)
					when :read
						if context.uri[3]
							result = forward(:read, context)
						else
							result = forward(:readAll, context)
						end
					when :update
						result = forward(:update, context)
					else
						result = 405
				end
				if result.is_a? Fixnum
					result = [result,{},[]]
				else
					result = [result.code,result.headers,[result.to_str]]
				end
			rescue RestClient::ResourceNotFound => e
				result = [404,{},e.to_str]
			end
			error_check(context, result)
		end
	end
end