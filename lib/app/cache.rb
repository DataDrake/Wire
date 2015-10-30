require_relative '../app'
require_relative '../closet/resource'
require_relative '../app/render'

require 'lmdb'

module Cache
	module Memory
		include Wire::App
		include Wire::Resource
		extend Render

		$cache = {}

		def self.update_cached(context)
			uri = context.uri.join('/')
			all = context.uri[0..3].join('/')
			env = $cache[context.app[:remote_uri]]
			db = env.database
			begin
				if [:create,:update,:delete].include? context.action
						result = forward(:readAll,context)
						env.transaction do
							db[all] = result
						end
						result = nil
				end
				if context.uri[3]
					result = forward(:read,context)
				else
					result = forward(:readAll,context)
				end
				env.transaction do
					db[uri] = result
				end
			rescue RestClient::ResourceNotFound
				# gracefully ignore
				result = nil
			end
			result
		end

		def self.get_cached(context)
			uri = context.uri.join('/')
			env = $cache[context.app[:remote_uri]]
			db = env.database
			result = nil
			env.transaction do
				result = db[uri]
			end
			result
		end

		def self.purge_cached(context)
			uri = context.uri.join('/')
			env = $cache[context.app[:remote_uri]]
			db = env.database
			result = 200
			env.transaction do
				begin
					db.destroy(uri)
				rescue
					result = 404
				end
			end
			result
		end

		def self.invoke(actions,context)

			# Create Cache if not set up
			unless $cache[context.app[:remote_uri]]
				$cache[context.app[:remote_uri]] = LMDB.new("/tmp/cache/#{context.app[:remote_uri]}", mapsize: 2**30)
			end

			begin
			case context.action
				when :create,:update
					result = forward(context.action,context)
					update_cached(context) # write aware
					result
				when :delete
					forward(context.action,context)
					purge_cached(context)
				when :read,:readAll
					cached = get_cached(context)
					unless cached
						cached = update_cached(context)
					end
					if cached
						cached
					else
						404
					end
			end
			rescue RestClient::ResourceNotFound
				404
			end
		end
	end
end
