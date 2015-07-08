require_relative '../render'

module Render

  module Editor
    extend Render

    def self.create( context , request , response )
      forward( nil , :create , context , request )
    end

    def self.read( id , context , request , response )
      resource = context[:resource_name]
      query = context[:query]
      begin
        response = forward( id , :read , context , request )
        mime = response.headers[:content_type]
      rescue RestClient::ResourceNotFound
        unless query['type'].nil?
          mime = query['type']
          response.body = ''
        else
          return 404
        end
      end
      template = $config[:editors][mime]
      if( template != nil ) then
        template.render( self, {resource: resource, id: id , mime: mime , response: response.body} )
      else
        response.body
      end
    end

    def self.update( id, context, request , response )
      response = forward( id , :update , context , request )
      200
    end
  end

end