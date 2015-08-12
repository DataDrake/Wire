require 'awesome_print'
require 'tilt'
require_relative '../wire'
require_relative 'history/svn'

module History

	def repos(path)
		$current_app[:repos_path] = path
	end

	def log(path)
		$current_app[:template] = Tilt.new(path, 1, { ugly: true })
	end

	def web_folder(path)
		$current_app[:web] = path
	end

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
