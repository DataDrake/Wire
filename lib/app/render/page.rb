require_relative '../render'

module Render
  module Page
    extend Render

    def self.renderTemplate( context, template , content , id = nil)
      if( template[:path] != nil ) then
        app = context[:uri]
        resource = context[:resource_name]
        hash = {content: content, app: app, resource: resource, id: id}
        template[:sources].each do |k,s|
          uri = "http://#{context[:app][:remote_host]}/#{s[:uri]}"
          case s[:key]
            when :user
              uri += "/#{context[:user]}"
            when :resource
              uri += "/#{context[:resource_name]}"
            else
              #do nothing
          end
          begin
            temp = RestClient.get uri
          rescue RestClient::ResourceNotFound
            temp = nil
          end
          hash[k] = temp
        end
        message = template[:path].render(self, hash )
        if template[:use_layout] then
          message = renderTemplate(context, $config[:apps][:global][:template] ,  message , id)
        end
      else
        message = 'Invalid Template'
      end
      message
    end

    def self.do_create( context, request , response , actions )
      forward( nil , :create , context , request )
    end

    def self.do_readAll( context , request , response , actions )
      template = context[:app][:template]
      resource = context[:resource_name]
      message = 'Resource not specified'
      if( resource != nil ) then
        begin
          result = forward( nil , :readAll , context , request )
          if(template != nil) then
            message = renderTemplate( context, template , result )
          else
            response.headers['Content-Type'] = result.headers[:content_type]
            message = result.to_str
          end
        rescue RestClient::ResourceNotFound
          message = 404
        end
      end
      message
    end
    def self.do_read( id , context , request , response , actions )
      template = context[:app][:template]
      resource = context[:resource_name]
      message = 'Resource not specified'
      if( resource != nil ) then
        begin
          result = forward( id , :read , context , request)
          if(template != nil) then
            message = renderTemplate( context, template , result , id)
          else
            response.headers['Content-Type'] = result.headers[:content_type]
            message = result.to_str
          end
        rescue RestClient::ResourceNotFound
          message = 404
        end
      end
      message
    end
    def self.do_update( id, context, request , response , actions)
      forward( id , :update , context , request )
      200
    end
  end

end