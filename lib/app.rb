module Wire

  module App

    def app( baseURI , type, &block)
      $currentURI = baseURI
      @apps[baseURI] = {type: type, resources: {}}
      $currentApp = @apps[baseURI]
      puts "Starting App at: /#{baseURI}"
      puts 'Setting up resources...'
      Docile.dsl_eval( type, &block )
    end

    def do_create( context , request , response , actions )
      401
    end

    def do_read_All( context , request , response , actions)
      401
    end

    def do_read( id , context , request , response , actions )
      401
    end

    def do_update( id , context , request , response , actions )
      401
    end

    def do_delete( id , context , request , response , actions )
      401
    end

  end
end

require_relative 'app/db'
require_relative 'app/file'
require_relative 'app/history'
require_relative 'app/render'
require_relative 'app/repo'