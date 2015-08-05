require_relative '../render'

module Render
  module Style
    extend Render

    def self.style( resource , path)
      unless $current_app[:styles]
        $current_app[:styles] = {}
      end
      $current_app[:styles][resource] = path.nil? ? nil : Tilt.new( path , 1 , {ugly: true}).render
    end

    def self.do_read_all( context )
      begin
        resource = context[:resource_name]
        template = context[:app][:styles][resource]
        headers = {}
        if template
          headers['Content-Type'] = 'text/css'
          [200, headers, [template]]
        else
          500
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end

    def self.invoke( actions , context )
      case context[:action]
        when :read
          do_read_all( context )
        else
          403
      end
    end
  end
end