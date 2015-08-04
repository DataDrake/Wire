module Wire
  module Auth

    def actionsAllowed?( context )
      username = username ? username : 'nobody'
      authConfig = $config[:apps][app][:auth]
      level = authConfig[:level]
      case level
        when :any
          [:create,:read,:readAll,:update,:delete]
        when :app
          authConfig[:handler].actionsAllowed?( resource , id , username )
        when :user
          if ( username == authConfig[:user] )
            [:create,:read,:readAll,:update,:delete]
          else
            []
          end
        else
          []
      end
    end

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