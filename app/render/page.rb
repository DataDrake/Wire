require_relative '../render'

module Render
  module Page
    extend Render

    def self.renderTemplate( context, template , content)
      if( template[:path] != nil ) then
        app = context[:uri]
        hash = {content: content, app: app}
        template[:sources].each do |k,s|
          uri = "http://#{context[:app][:remote_host]}/#{s[:uri]}"
          case s[:key]
            when :user
              uri += "/#{context[:user]}"
            else
              #do nothing
          end
          begin
            temp = RestClient.get uri
          rescue RestClient::ResourceNotFound
            temp = ''
          end
          hash[k] = temp.to_str
        end
        message = template[:path].render(self, hash )
        if template[:use_layout] then
          message = renderTemplate(context, $config[:apps][:global][:template] ,  message)
        end
      else
        message = 'Invalid Template'
      end
      message
    end

    def self.create( context, request , response )
      forward( nil , :create , context , request )
    end

    def self.readAll( context , request , response )
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
    def self.read( id , context , request , response )
      template = context[:app][:template]
      resource = context[:resource_name]
      message = 'Resource not specified'
      if( resource != nil ) then
        begin
          result = forward( id , :read , context , request)
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
  end
end