module Wire
  module App
    def app( base_uri , type, &block)
      $current_uri = base_uri
      @apps[base_uri] = {type: type, resources: {}}
      $current_app = @apps[base_uri]
      puts "Starting App at: /#{base_uri}"
      puts 'Setting up resources...'
      Docile.dsl_eval( type, &block )
    end
  end
end

require_relative 'app/db'
require_relative 'app/file'
require_relative 'app/login'
require_relative 'app/history'
require_relative 'app/render'
require_relative 'app/repo'