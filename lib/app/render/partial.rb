require_relative '../render'

module Render
  module Partial
    extend Render

    def self.use_forward
      $current_resource[:forward] = true
    end

    def self.extra( name , path )
      unless $current_resource[:sources]
        $current_resource[:sources] = {}
      end
      $current_resource[:sources][name] = path
    end

    def self.do_read_all( actions , context )
      resource = context[:resource_name]
      begin
        if context[:resource][:forward]
          response = forward( :readAll , context )
        else
          401
        end
        mime = response.headers[:content_type]
        template = context[:resource][:multiple]
        hash = {actions: actions, resource: resource, mime: mime , response: response.body}
        if context[:resource][:sources]
          context[:resource][:sources].each do |k,v|
            hash[k] = RestClient.get( "http://#{context[:app][:remote_host]}/#{v}")
          end
        end
        if template
          [200, {'Content-Type' => mime}, [template.render( self, hash )]]
        else
          [200, {'Content-Type' => mime}, [response.body]]
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.do_read( actions , context )
      app = context[:app][:uri]
      resource = context[:resource_name]
      begin
        response = forward( :read , context )
        mime = response.headers[:content_type]
        template = context[:resource][:single]
        hash = {actions: actions, app: app, id: id, resource: resource, mime: mime , response: response.body}
        if context[:resource][:sources]
          context[:resource][:sources].each do |k,v|
            hash[k] = RestClient.get( "http://#{context[:app][:remote_host]}/#{v}")
          end
        end
        if template
          [200, {'Content-Type' => mime}, [template.render( self, hash )]]
        else
          [200, {'Content-Type' => mime}, [response.body]]
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.invoke( actions , context )
      case context[:action]
        when :create
          forward( :create , context )
        when :read
          if context[:uri][3]
            do_read( actions, context )
          else
            do_read_all( actions, context )
          end
        when :update
          forward( :update , context )
        else
          403
      end
    end
  end
end