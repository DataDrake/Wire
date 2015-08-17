module Wire
	# Context is a class containing request information
	# @author Bryan T. Meyers

	class Context
		#@!attribute [r] action
		#		@return [Symbol] the action for the current request
		#@!attribute [r] app
		#		@return [Hash] the Wire::App configuration for the current request
		#@!attribute [r] body
		#		@return [String] the unparsed body of the current request
		#@!attribute [r] env
		#		@return [Hash] the raw Rack environment of the current request
		#@!attribute [r] json
		#		@return [Hash] the JSON parsed body of the current request
		#@!attribute [r] query
		#		@return [Hash] the parsed query string of the current request
		#@!attribute [r] query_string
		#		@return [String] the raw query string of the current request
		#@!attribute [r] referer
		#		@return [Array] the referer URI of the current request
		#@!attribute [r] resource
		#		@return [Symbol] the Wire::Resource configuration of the current request
		#@!attribute [r] type
		#		@return [Module] the Wire::App of the current request
		#@!attribute [r] uri
		#		@return [Array] the URI of the current request
		#@!attribute [r] user
		#		@return [String] the REMOTE_USER of the current request
		#@!attribute [r] verb
		#		@return [Symbol] the HTTP verb of the current request

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
			user = env['HTTP_REMOTE_USER']
			unless user.nil? or user.eql? 'nobody' or user.eql? '(null)'
				env['rack.session']['user'] = user
			end
			env
		end

		# Builds a new Context
		# @param [Hash] env the Rack environment
		# @return [Context] a new Context
		def initialize(env)
			@env    = update_session(env)
			@user   = env['rack.session']['user']
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