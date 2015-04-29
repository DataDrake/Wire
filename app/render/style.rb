require_relative '../render'

module Render
  module Style
    extend Render

    def self.readAll( context , request , response )
      resource = context[:resource_name]
      begin
        if context[:resource][:forward] then
          response = forward( nil , :readAll , context , request )
        else
          401
        end
        mime = response.headers[:content_type]
        template = context[:resource][:multiple]
        hash = {resource: resource, mime: mime , response: response.body}
        if context[:resource][:sources] != nil then
          context[:resource][:sources].each do |k,v|
            hash[k] = RestClient.get( "http://#{context[:app][:remote_host]}/#{v}")
          end
        end
        if( template != nil ) then
          if template.instance_of? Tilt::SassTemplate then
            response.headers['Content-Type'] = 'text/css'
          end
          template.render( self, hash )
        else
          response.body
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.read( id , context , request , response )
      app = context[:app][:uri]
      resource = context[:resource_name]
      begin
        response = forward( id , :read , context , request )
        mime = response.headers[:content_type]
        template = context[:resource][:single]
        hash = {app: app, id: id, resource: resource, mime: mime , response: response.body}
        if context[:resource][:sources] != nil then
          context[:resource][:sources].each do |k,v|
            hash[k] = RestClient.get( "http://#{context[:app][:remote_host]}/#{v}")
          end
        end
        if( template != nil ) then
          template.render( self, hash )
        else
          response.body
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end
  end
end