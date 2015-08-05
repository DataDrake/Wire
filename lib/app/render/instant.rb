require_relative '../render'

module Render
  module Instant
    extend Render

    def self.do_update( actions , context )
      app = context[:app]
      body = context[:request][:data]
      resource = context[:resource_name]
      query = context[:query]

      ## Default to not found
      message = 404
      if resource
        if body
          ## Assume unsupported mime type
          message = 403
          renderer = @config[:renderers]["#{resource}/#{id}"]
          if renderer
            template = @config[:templates][renderer]
            referrer = context[:request].env['HTTP_REFERER']
            result = template.render(self,{ actions: actions, app: app[:name], resource: query[:resource] , mime: "#{query[:resource]}/#{id}" , id: query[:id] , response: body, referrer: referrer} )
            template = context[:app][:template]
            if template
              message = template[:path].render( self , {content: result})
            else
              message = result
            end
          end
        end
      end
      message
    end

    def invoke( actions , context )
      if context[:action].eql? :update
        do_update( actions , context )
      else
        401
      end
    end
  end
end