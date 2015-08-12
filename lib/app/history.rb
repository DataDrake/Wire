require 'awesome_print'
require 'tilt'
require_relative '../wire'
require_relative 'history/svn'

# History is a Wire::App for accessing the history of versioned content
# @author Bryan T. Meyers
module History

	# Select the location of the repositories
	# @param [Symbol] path location of the repositories
	# @return [void]
	def repos(path)
		$current_app[:repos_path] = path
	end

	# Select the render template for histories
	# @param [Symbol] path location of the Tilt compatible template
	# @return [void]
	def log(path)
		$current_app[:template] = Tilt.new(path, 1, { ugly: true })
	end

	# Select the sub-directory for web-serveable content
	# @param [Symbol] path the sub-directory path
	# @return [void]
	def web_folder(path)
		$current_app[:web] = path
	end

	# Get the history of a single file or directory
	# @param [Hash] context the context for this request
	# @return [Response] the history, or status code
	def do_read(actions, context)
		resource = context.uri[2]
		web      = context.app[:web]
		id       = context.uri[3...context.uri.length].join('/')
		list     = get_log(web, resource, id)
		if list == 404
			return 404
		end
		template = context.app[:template]
		template.render(self, actions: actions, context: context, list: list)
	end

	# Proxy method used when routing
	# @param [Array] actions the allowed actions for this URI
	# @param [Hash] context the context for this request
	# @return [Response] a Rack Response triplet, or status code
	def invoke(actions, context)
		return 404 unless context.uri[2]
		case context.action
			when :read
				do_read(actions, context)
			else
				403
		end
	end
end
