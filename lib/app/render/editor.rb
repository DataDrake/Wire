require_relative '../render'

module Render

  module Editor
    extend Render

    def self.do_read( actions, context )
      resource = context[:resource_name]
      query = context[:query]
      begin
        response = forward( :read , context )
        mime = response.headers[:content_type]
      rescue RestClient::ResourceNotFound
        if query['type']
          mime = query['type']
          response.body = ''
        else
          return 404
        end
      end
      template = $editors[mime]
      if template
        template.render( self, {actions: actions, resource: resource, id: id , mime: mime , response: response.body} )
      else
        response.body
      end
    end

    def invoke( actions , context )
      case context[:action]
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