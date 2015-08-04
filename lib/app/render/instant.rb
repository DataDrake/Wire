require_relative '../render'

module Render
  module Instant
    extend Render

    def self.do_update( id , context , request , response , actions )
      app = context[:app]
      body = request[:data]
      resource = context[:resource_name]
      query = context[:query]

      ## Default to not found
      message = 404
      if( resource != nil ) then
        ## Implicit not found
        message = 'Nothing to Render'
        if( body != nil ) then
          ## Assume unsupported mime type
          message = 403
          renderer = $config[:renderers]["#{resource}/#{id}"]
          if( renderer != nil ) then
            template = $config[:templates][renderer]
            referrer = request.env['HTTP_REFERER']
            result = template.render(self,{app: app[:name], resource: query[:resource] , mime: "#{query[:resource]}/#{id}" , id: query[:id] , response: body, referrer: referrer} )
            template = context[:app][:template]
            if template != nil then
              message = template[:path].render( self , {content: result})
            else
              message = result
            end
          end
        end
      end
      message
    end
  end
end