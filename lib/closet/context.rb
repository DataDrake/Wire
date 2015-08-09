HTTP_ACTIONS = {
    'GET' => :read ,
    'HEAD' => :read ,
    'POST' => :create,
    'PUT' => :update,
    'DELETE' => :delete
}

HTTP_VERBS = {
    'GET' => :get ,
    'HEAD' => :head ,
    'POST' => :post,
    'PUT' => :put,
    'DELETE' => :delete
}

module Wire
  class Context

    attr_reader :action, :app, :body, :env, :json, :query ,
                :query_string, :referer, :resource, :type,
                :uri , :user, :verb

    def update_session( env  )
      user = env['HTTP_REMOTE_USER']
      user = user ? user : 'nobody'
      env['rack.session'][:user] = user
      env
    end

    def initialize( env )
      @env = update_session( env )
      @user = env['rack.session'][:user]
      @verb = HTTP_VERBS[env['REQUEST_METHOD']]
      @action = HTTP_ACTIONS[env['REQUEST_METHOD']]
      @referer = env['HTTP_REFERER'].split( '?' )[0].split( '/' )
      @uri = env['REQUEST_URI'].split( '?' )[0].split( '/' )
      app= $apps[@uri[1]]
      if app
        @app = app
        @resource = app[:resources][@uri[2]]
        @type = app[:type]
      else
        throw Exception.new( "App: #{@uri[1]} is Undefined" )
      end
      @query = {}
      env['QUERY_STRING'].split('&').each do |q|
        param = q.split('=')
        @query[param[0].to_sym] = param[1]
      end
      @query_string = env['QUERY_STRING']
      if env['rack.input']
        @body = env['rack.input'].read
        begin
          @json = JSON.parse_clean( @body )
        rescue JSON::ParserError
          $stderr.puts 'Warning: Failed to parse body as JSON'
        end
      end
    end
  end
end