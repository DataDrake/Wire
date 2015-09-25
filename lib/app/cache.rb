require_relative '../app'
require_relative '../closet/resource'

module Cache
	module Memory
		include Wire::App
		include Wire::Resource
		extend Render

		$cache = {}

		def self.write_aware
			$current_resource[:write_aware] = true
		end

		def self.update_cache(context)
			action = (context.uri.length == 3) ? :readAll : :read
			content = forward(action,context)
			temp = context.uri.dup
			temp.shift
			target = $cache
			until temp.empty?
				current = temp.shift
				unless target[current]
					target[current] = {}
				end
				target = target[current]
			end
			target = (context.uri.length == 3) ? target[:all] : target
			target = content
		end

		def self.get_cached(context)
			temp = context.uri.dup
			temp.shift
			result = $cache
			until temp.empty?
				result = result[temp.shift]
			end
			if context.uri.length == 3
				result = result[:all]
			end
			result
		end

		def self.invoke(actions,context)
			case context.action
				when :create,:update,:delete
					result = forward(context.action,context)
					if context.resource[:write_aware]
						update_cache(context)
					end
					result
				when :read
					cached = get_cached(context)
					unless cached
						cached = update_cache(context)
					end
					cached
			end
		end
	end
end