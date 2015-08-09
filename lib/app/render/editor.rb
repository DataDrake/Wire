require_relative '../render'

module Render

  module Editor
    extend Render

    def self.do_read( actions, context )
      resource = context.uri[2]
      query = context.query
      id = context.uri[3...context.uri.length].join('/')
      body = ''
      begin
        response = forward( :read , context )
        mime = response.headers[:content_type]
        body = response.body
      rescue RestClient::ResourceNotFound
        if query[:type]
          mime = query[:type]
        else
          return 404
        end
      end
      template = $editors[mime]
      if template
        template.render( self, {actions: actions, resource: resource, id: id , mime: mime , response: body} )
      else
        body
      end
    end

    def self.invoke( actions , context )
      case context.action
        when :create
          forward( :create , context )
        when :read
          do_read( actions ,context )
        when :update
          forward( :update, context )
        else
          403
      end
    end
  end
end