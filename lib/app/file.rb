require 'awesome_print'
require_relative '../wire'

# Static is a Wire::App for serving read-only, static files
# @author Bryan T. Meyers
module Static
	extend Wire::App
	extend Wire::Resource

	# Map a file folder to a sub-URI
	# @param [String] resource the sub-URI
	# @param [Class] path the file folder
	# @return [void]
	def self.local(resource, path)
		$current_app[:resources][resource] = { local: path }
	end

	# Get a file listing for this folder
	# @param [Hash] context the context for this request
	# @return [Response] a listing, or status code
	def self.do_read_all(context)
		path = context.resource[:local]
		if path
			return 404 unless File.exists?(path)
			if File.directory? path
				Dir.entries(path).sort.to_s
			else
				401
			end
		else
			404
		end
	end

	# Get a file from this folder
	# @param [Hash] context the context for this request
	# @return [Response] a file, listing, or status code
	def self.do_read(context)
		path = context.resource[:local]
		id   = context.uri[3..context.uri.length].join('/')
		if path
			ext_path = File.join(path, id)
			return 404 unless File.exists?(ext_path)
			if File.directory?(ext_path)
				"#{ap Dir.entries(ext_path).sort}"
			else
				if ext_path.end_with?('.wiki') || ext_path.end_with?('.mediawiki')
					mime = 'text/wiki'
				else
					mime = `mimetype --brief #{ext_path}`
				end
				headers                  = {}
				headers['Content-Type']  = mime
				headers['Cache-Control'] = 'public'
				headers['Expires']       = "#{(Time.now + 30000000).utc}"
				body                     = File.read(ext_path)
				[200, headers, body]
			end
		else
			404
		end
	end

	# Proxy method used when routing
	# @param [Array] actions the allowed actions for this URI
	# @param [Hash] context the context for this request
	# @return [Response] a Rack Response triplet, or status code
	def self.invoke(actions, context)
		return 404 unless context.resource
		case context.action
			when :read
				if context.uri[3]
					do_read(context)
				else
					do_read_all(context)
				end
			else
				403
		end
	end
end
