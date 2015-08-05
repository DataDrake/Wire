require_relative '../render'

module Render
  module Document
    extend Render

    def self.do_read_all( actions , context )
      app = context[:uri]
      resource = context[:resource_name]
      referrer = context[:request].env['HTTP_REFERRER']
      begin
        response = forward( :readAll , context )
        mime = response.headers[:content_type]
        renderer = $renderers[mime]
        if renderer
          template = $templates[renderer]
          template.render( self, {actions: actions, referrer: referrer, app: app, resource: resource, id: '' , mime: mime , response: response.body} )
        else
          response
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.do_read( actions , context )
      app = context[:uri]
      resource = context[:resource_name]
      referrer = context[:request].env['HTTP_REFERRER']
      begin
        response = forward( :read , context )
        mime = response.headers[:content_type]
      rescue RestClient::ResourceNotFound
        response = $apps[404][:template][:path].render( self, locals = {referrer: referrer, app: app, resource: resource, id: id})
      end
      renderer = $renderers[mime]
      if renderer
        template = $templates[renderer]
        template.render( self, {actions: actions, referrer: referrer, app: app, resource: resource, id: id , mime: mime , response: response.body} )
      else
        response
      end
    end

    def self.invoke( actions , context )
      case context[:action]
        when :create
          forward( :create, context )
        when :read
          if context[:uri][3]
            do_read( actions, context )
          else
            do_read_all( actions , context )
          end
        when :update
          forward( :update , context )
        else
          403
      end
    end
  end
end