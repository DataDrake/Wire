require_relative '../render'

module Render
  module Style
    extend Render

    def self.style( resource , path)
      if $currentApp[:styles].nil? then
        $currentApp[:styles] = {}
      end
      $currentApp[:styles][resource] = path.nil? ? nil : Tilt.new( path , 1 , {ugly: true})
    end

    def self.readAll( context , request , response )
      begin
        resource = context[:resource_name]
        template = context[:app][:styles][resource]
        if( template != nil ) then
          response.headers['Content-Type'] = 'text/css'
          template.render
        else
          500
        end
      rescue RestClient::ResourceNotFound
        404
      end
    end
  end
end