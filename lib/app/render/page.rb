require_relative '../render'

module Render
  module Page
    include Render
    extend self

    def render_template( context, template , content , actions , id = nil )
      if template[:path]
        app = context[:uri]
        resource = context[:resource_name]
        hash = {actions: actions, content: content, app: app, resource: resource, id: id}
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
        if template[:use_layout]
          message = render_template(context, $apps[:global][:template] ,  message , id)
        end
      else
        message = 'Invalid Template'
      end
      message
    end

    def do_read_all( actions , context )
      template = context[:app][:template]
      resource = context[:resource_name]
      message = 403
      headers = {}
      if resource
        begin
          result = forward( :readAll , context )
          if template
            message = render_template( context, template , result , actions)
          else
            headers['Content-Type'] = result.headers[:content_type]
            message = [200, headers, [result.to_str]]
          end
        rescue RestClient::ResourceNotFound
          message = 404
        end
      end
      message
    end

    def do_read( actions , context )
      template = context[:app][:template]
      resource = context[:resource_name]
      message = 'Resource not specified'
      headers = {}
      if resource
        begin
          result = forward( :read , context )
          if template
            id = context[:uri][3...context[:uri].length].join('/')
            message = render_template( context, template , result , actions , id )
          else
            headers['Content-Type'] = result.headers[:content_type]
            message = [200, headers, [result.to_str]]
          end
        rescue RestClient::ResourceNotFound
          message = 404
        end
      end
      message
    end

    def self.invoke( actions , context )
      case context[:action]
        when :create
          forward( :create, context )
        when :read
          if context[:uri][3]
            do_read( actions , context )
          else
            do_read_all( actions , context )
          end
        when :update
          forward( :update, context )
        else
          403
      end
    end
  end
end