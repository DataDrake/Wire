require_relative '../render'

module Render

  module Editor
    extend Render

    def self.create( context , request , response )
      forward( nil , :create , context , request )
    end

    def self.read( id , context , request , response )
      resource = context[:resource_name]
      begin
        response = forward( id , :read , context , request )
        mime = response.headers[:content_type]
        template = $config[:editors][mime]
        if( template != nil ) then
          template.render( self, {resource: resource, id: id , mime: mime , response: response.body} )
        else
          response.body
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.update( id, context, request , response )
      response = forward( id , :update , context , request )
      200
    end
  end

end