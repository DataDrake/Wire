module Wire
  module Auth

    def actions_allowed( context )
      actions = []
      app = context[:app]
      user = context[:user]
      if app
        auth = app[:auth]
        level = auth[:level]
        case level
          when :any
            actions = [:create,:read,:readAll,:update,:delete]
          when :app
            actions = auth[:handler].actions_allowed( context )
          when :user
            if user == auth[:user]
              actions = [:create,:read,:readAll,:update,:delete]
            end
        end
      end
      actions
    end

    def auth( level , &block)
      $current_app[:auth] = { level: level }
      unless (level == :any) || (block.nil?)
        Docile.dsl_eval( self , &block )
      end
    end

    def handler( handler )
      $current_app[:auth][:handler] = handler
    end

    def user( user )
      $current_app[:auth][:user] = user
    end
  end
end