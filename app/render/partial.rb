require_relative '../render'

module Render
  module Partial
    extend Render

    def self.use_forward
      $currentResource[:forward] = true
    end

    def self.extra( name , path )
      if $currentResource[:sources] == nil then
        $currentResource[:sources] = {}
      end
      $currentResource[:sources][name] = path
    end

    def self.do_create( context , request , response , actions )
      if context[:resource][:Render] then
        forward( nil , :create , context , request )
      else
        401
      end
    end

    def self.do_readAll( context , request , response , actions )
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
          template.render( self, hash )
        else
          response.body
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.do_read( id , context , request , response , actions )
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