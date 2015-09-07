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
				template = errors[result.first]
				if template
					result[2] = template.render(self, {actions: actions, context: context, result: result})
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
					headers = {}
					result.headers.each do |k,v|
						headers[k.to_s.capitalize] = v
					end
					result = [result.code,headers,[result.to_s]]
				end
			rescue RestClient::ResourceNotFound => e
				result = [404,{},e.to_s]
			end
			error_check(actions, context, result)
		end
	end
end