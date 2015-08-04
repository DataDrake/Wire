module Wire
  module Resource

    def resource( uri , &block )
      $currentApp[:resources][uri] = {}
      $currentResource = $currentApp[:resources][uri]
      puts "Starting Resource At: /#{$currentURI + '/' + uri}"
      Docile.dsl_eval( self , &block )
    end

  end
end