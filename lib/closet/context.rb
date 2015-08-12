module Wire
	# Context is a class containing request information
	# @author Bryan T. Meyers
	class Context

		attr_reader :action, :app, :body, :env, :json, :query,
								:query_string, :referer, :resource, :type,
								:uri, :user, :verb

		# Maps HTTP verbs to actions
		HTTP_ACTIONS = {
				'GET'    => :read,
				'HEAD'   => :read,
				'POST'   => :create,
				'PUT'    => :update,
				'DELETE' => :delete
		}

		# Maps HTTP verbs to Symbols
		HTTP_VERBS = {
				'GET'    => :get,
				'HEAD'   => :head,
				'POST'   => :post,
				'PUT'    => :put,
				'DELETE' => :delete
		}

		# Add user info to session
		# @param [Hash] env the Rack environment
		# @return [Hash] the updated environment
		def update_session(env)
			user                       = env['HTTP_REMOTE_USER']
			user                       = user ? user : 'nobody'
			env['rack.session'][:user] = user
			env
		end

		# Builds a new Context
		# @param [Hash] env the Rack environment
		# @return [Context] a new Context
		def initialize(env)
			@env    = update_session(env)
			@user   = env['rack.session'][:user]
			@verb   = HTTP_VERBS[env['REQUEST_METHOD']]
			@action = HTTP_ACTIONS[env['REQUEST_METHOD']]
			if env['HTTP_REFERER']
				@referer = env['HTTP_REFERER'].split('/')
			else
				@referer = []
			end
			@uri = env['REQUEST_URI'].split('?')[0].split('/')
			app  = $apps[@uri[1]]
			if app
				@app      = app
				@resource = app[:resources][@uri[2]]
				@type     = app[:type]
			else
				throw Exception.new("App: #{@uri[1]} is Undefined")
			end
			@query = {}
			env['QUERY_STRING'].split('&').each do |q|
				param                   = q.split('=')
				@query[param[0].to_sym] = param[1]
			end
			@query_string = env['QUERY_STRING']
			if env['rack.input']
				@body = env['rack.input'].read
				begin
					@json = JSON.parse_clean(@body)
				rescue JSON::ParserError
					$stderr.puts 'Warning: Failed to parse body as JSON'
				end
			end
		end
	end
end