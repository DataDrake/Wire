module Wire
  module Auth

    def auth( level , &block)
      $currentApp[:auth] = { level: level }
      unless (level == :any) || (block.nil?)
        Docile.dsl_eval( self , &block )
      end
    end

    def handler( handler )
      $currentApp[:auth][:handler] = handler
    end

    def user( user )
      $currentApp[:auth][:user] = user
    end
  end
end