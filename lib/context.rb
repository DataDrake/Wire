module Wire
  module Context

    VERBS = {
      'GET' => :read ,
      'HEAD' => :read ,
      'POST' => :create,
      'PUT' => :update,
      'DELETE' => :delete
    }

    def update_session( env  )
      user = env['HTTP_REMOTE_USER']
      unless user.nil?
        env['session'][:user] = user
      end
      env
    end

    def prepare( env )
      env = update_session( env )
      hash = {failure: true}
      hash[:user] = env['rack.session'][:user]
      hash[:action] = VERBS[env['REQUEST_METHOD']]
      uri = env['REQUEST_URI'].split( '/' )
      hash[:uri] = uri
      app= @apps[uri[1]]
      if app
        hash[:app] = app
        hash[:resource_name] = uri[2]
        hash[:resource] = app[:resources][uri[2]]
        hash[:type] = app[:type]
      else
        hash[:message] = 'App Undefined'
      end
      request = Rack::Request.new env
      hash[:request] = request
      hash[:query] = request.params
      response = Rack::Response.new env
      hash[:response] = response
      if env['rack.input']
        json = request.env['rack.input'].read
        begin
          hash[:params] = JSON.parse( json )
        rescue JSON::ParserError
          hash[:params] = json
        end
      end
      hash[:failure] = false
      hash
    end
  end
end