require_relative '../render'

module Render
  module Document
    extend Render

    def self.do_create( context , request , response , actions)
      forward( nil , :create , context , request )
    end

    def self.do_update( id, context , request , response , actions )
      forward( id , :update , context , request )
    end

    def self.do_readAll( context , request , response , actions)
      app = context[:uri]
      resource = context[:resource_name]
      referrer = request.env['HTTP_REFERRER']
      begin
        response = forward(nil , :readAll , context , request )
        mime = response.headers[:content_type]
        renderer = $config[:renderers][mime]
        if( renderer != nil ) then
          template = $config[:templates][renderer]
          template.render( self, {referrer: referrer, app: app, resource: resource, id: '' , mime: mime , response: response.body} )
        else
          response
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.do_read( id , context , request , response , actions)
      app = context[:uri]
      resource = context[:resource_name]
      referrer = request.env['HTTP_REFERRER']
      begin
        response = forward(id , :read , context , request )
        mime = response.headers[:content_type]
      rescue RestClient::ResourceNotFound
        response = $config[:apps][404][:template][:path].render( self, locals = {referrer: referrer, app: app, resource: resource, id: id})
      end
      renderer = $config[:renderers][mime]
      if( renderer != nil ) then
        template = $config[:templates][renderer]
        template.render( self, {referrer: referrer, app: app, resource: resource, id: id , mime: mime , response: response.body} )
      else
        response
      end
    end
  end
end