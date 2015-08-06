require_relative '../render'

module Render
  module Document
    extend Render

    def self.do_read( actions , context , specific )
      begin
        response = forward( specific , context )
        mime = response.headers[:content_type]
        renderer = $renderers[mime]
        if renderer
          template = $templates[renderer]
          template.render( self, {actions: actions, context: context , mime: mime , response: response.body} )
        else
          response
        end
      rescue RestClient::ResourceNotFound
        $apps[404][:template][:path].render( self, locals = {actions: actions, context: context})
      end
    end

    def self.invoke( actions , context )
      case context[:action]
        when :create
          forward( :create, context )
        when :read
          if context[:uri][3]
            do_read( actions, context , :read )
          else
            do_read( actions , context , :readAll )
          end
        when :update
          forward( :update , context )
        else
          403
      end
    end
  end
end