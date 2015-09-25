require_relative '../app'
require_relative '../closet/resource'
require_relative '../app/render'

module Cache
	module Memory
		include Wire::App
		include Wire::Resource
		extend Render

		def self.write_aware
			$current_resource[:write_aware] = true
		end

		def self.update_cache(context)
			ap $cache
			action = (context.uri.length == 3) ? :readAll : :read
			action = ((context.uri.length == 4) and context.uri[3].eql?('new')) ? :readAll : action
			if action.eql? :read
				content = forward(action,context)
			end
			all = forward( :readAll , context)
			target = $cache
			context.uri.each_with_index do |current,i|
				unless i == 0 
					puts i
					unless target[current]
						target[current] = {}
					end
					target = target[current]
					if i == 2
						target[:all] = all
					end
				end
			end
			if action.eql? :read
				content
			else
				all
			end
		end

		def self.get_cached(context)
			result = $cache
			context.uri[1..(context.uri.length-1)].each do |current|
				if result
					result = result[current]
				end
			end
			if result and (context.uri.length == 3)
				result = result[:all]
			end
			result
		end

		def self.invoke(actions,context)
			begin
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
			rescue RestClient::ResourceNotFound
				404
			end
		end
	end
end
