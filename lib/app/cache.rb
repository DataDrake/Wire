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
			all = context.uri[0..2].join('/')
			env = $cache[context.app[:remote_uri]]
			db = env.database
			begin

				if context.uri[3]
					result = forward(:read,context)
				else
					result = forward(:readAll,context)
				end
			rescue RestClient::ResourceNotFound
				result = nil
			end
				if (result != nil) and (result.code == 200)
					env.transaction do
						if context.action == :delete
							db.destroy(uri)
						else
							db[uri] = result
						end
					end
				end
			begin
				if [:create,:update,:delete].include? context.action
					thing = forward(:readAll,context)
				end
				if (thing != nil) and (thing.code == 200)
					env.transaction do
						db[all] = thing
					end
				end
			rescue RestClient::ResourceNotFound
				# gracefully ignore
				result = 404
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
				when :create,:update,:delete
					result = forward(context.action,context)
					update_cached(context) # write aware
					result
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
