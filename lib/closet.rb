module Wire
  class Closet
    extend Wire::App
    extend Wire::Auth
    extend Wire::Resource

    def actionsAllowed?( app , resource , id , username)
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

    def prepare( appName , resourceName , user , id)
      if (user == nil || user.eql?( 'nobody') ) then
        user = 'nobody'
      end
      hash = {failure: true}
      hash[:sinatra] = self
      hash[:user] = user
      app = $config[:apps][appName]
      hash[:uri] = appName
      if( app != nil ) then
        hash[:app] = app
        hash[:resource_name] = resourceName
        resource = app[:resources][resourceName]
        if( resource != nil ) then
          hash[:resource] = resource
        end
        type = app[:type]
        if( type != nil ) then
          hash[:controller] = type
        else
          hash[:message] = 'Application type Not Specified'
        end
      else
        hash[:message] = 'App Undefined'
      end
      page = ''
      if( id != nil ) then
        if( id.include?('.') ) then
          page = id.slice(0..(id.index('.')-1))
        end
        page.capitalize!
      end
      hash[:query] = params
      if request.env['rack.input'] != nil then
        json = request.env['rack.input'].read
        begin
          hash[:params] = JSON.parse( json )
        rescue JSON::ParserError
          hash[:params] = json
        end
      end
      hash[:failure] = false
      hash
    end

    def updateSession( request , session )
      user = request.env['HTTP_REMOTE_USER']
      unless user.nil? or user.eql? 'nobody' or user.eql? '(null)'
        session[:user] = user
      end
      session[:user]
    end

    enable :sessions
    get('/login') do
      updateSession( request , session )
      referrer = request.env['HTTP_REFERER']
      redirect referrer
    end

    ## Create One or More
    post('/:app/:resource') do | a , r |
      user = updateSession( request , session )
      context = prepare( a , r , user , r )
      if( !context[:failure] ) then
        actions = actionsAllowed?( a , r , nil , user )
        if( actions.include? :create ) then
          context[:controller].do_create( context , request , response , actions)
        else
          401
        end
      else
        context[:message]
      end
    end

    ## Read all
    get('/:app/:resource') do | a , r |
      user = updateSession( request , session )
      context = prepare( a , r , user , r)
      if( !context[:failure] ) then
        actions = actionsAllowed?( a , r , nil , user )
        if( actions.include? :readAll ) then
          context[:controller].do_readAll( context , request , response , actions )
        else
          401
        end
      else
        context[:message]
      end
    end

    ## Read One
    get('/:app/:resource/*') do | a , r , i |
      user = updateSession( request , session )
      context = prepare( a , r , user, i)
      if( !context[:failure] ) then
        actions = actionsAllowed?( a , r , i , user )
        if( actions.include? :read ) then
          context[:controller].do_read( i , context , request , response , actions )
        else
          401
        end
      else
        context[:message]
      end
    end

    ## Update One or More
    put('/:app/:resource/*' ) do | a , r , i |
      user = updateSession( request , session )
      context = prepare( a , r , user , i)
      if( !context[:failure] ) then
        actions = actionsAllowed?( a , r , i , user )
        if( actions.include? :update ) then
          context[:controller].do_update( i , context , request , response , actions)
        else
          401
        end
      else
        context[:message]
      end
    end

    ## Delete One
    delete('/:app/:resource/*') do | a , r , i |
      user = updateSession( request , session )
      context = prepare( a , r , user , i)
      if( !context[:failure] ) then
        actions = actionsAllowed?( a , r , i , user )
        if( actions.include? :delete ) then
          context[:controller].do_delete( i , context , request , response , actions)
        else
          401
        end
      else
        context[:message]
      end
    end

    $config = { apps: {} , editors:{}, renderers: {} , templates: {} }

    def self.config( &block )
      puts 'Starting Up Wire...'
      puts 'Starting Apps...'
      Docile.dsl_eval( self , &block )
    end

    def self.info
      puts "Apps:\n"
      $config[:apps].each do |app, config|
        puts "\u{2502}"
        puts "\u{251c} Name: #{app}"
        if config[:auth] then
          puts "\u{2502}\t\u{251c} Auth:"
          if config[:auth][:level] == :app then
            puts "\u{2502}\t\u{2502}\t\u{251c} Level:\t#{config[:auth][:level]}"
            puts "\u{2502}\t\u{2502}\t\u{2514} Handler:\t#{config[:auth][:handler]}"
          else
            puts "\u{2502}\t\u{2502}\t\u{2514} Level:\t#{config[:auth][:level]}"
          end
        end
        if config[:type] then
          puts "\u{2502}\t\u{2514} Type: #{config[:type]}"
        end
      end
    end
  end
end