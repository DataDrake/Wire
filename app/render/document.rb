require_relative '../render'

module Render
  module Document
    extend Render

    def self.create( context , request , response )
      forward( nil , :create , context , request )
    end

    def self.readAll( context , request , response )
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

    def self.read( id , context , request , response )
      app = context[:uri]
      resource = context[:resource_name]
      referrer = request.env['HTTP_REFERRER']
      begin
        response = forward(id , :read , context , request )
        mime = response.headers[:content_type]
        renderer = $config[:renderers][mime]
        if( renderer != nil ) then
          template = $config[:templates][renderer]
          template.render( self, {referrer: referrer, app: app, resource: resource, id: id , mime: mime , response: response.body} )
        else
          response
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end
  end
end