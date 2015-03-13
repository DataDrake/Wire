require 'awesome_print'
require 'sinatra'

class Sinatra::Base
	def actionAllowed?( action , app , resource , id , username )
		authConfig = $config[:apps][app][:auth]
		level = authConfig[:level]
		case level
			when :any
				true
			when :app
				authConfig[:handler].actionAllowed?( action , resource , id , username )
			when :user
				( username == authConfig[:user] )
      else
        false
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
    if request.env['rack.request.form_vars'] != nil then
      begin
		    hash[:params] = JSON.parse(request.env['rack.request.form_vars'])
      rescue JSON::ParserError
        hash[:params] = request.env['rack.request.form_vars']
      end
    end
    hash[:failure] = false
		hash
	end	
end

class Wire

	module App

		def app( baseURI , &block)
			@currentURI = baseURI
			$config[:apps][baseURI] = {resources: {}}
			@currentApp = $config[:apps][baseURI]
			puts "Starting App at: /#{baseURI}"
			puts 'Setting up resources...'
			Docile.dsl_eval( self, &block )
		end

		def type( type )
			@currentApp[:type] = type
		end

		def create( context , request , response )
			401
		end

		def readAll( context , request , response )
			401
		end

		def read( id , context , request , response )
			401
		end

		def update( id , context , request , response )
			401
		end

		def delete( id , context , request , response )
			401
    end

	end

	module Auth

		def auth_handler( handler )
			@currentApp[:auth][:handler] = handler
		end

		def auth_level( level )
			@currentApp[:auth] = { level: level }
		end
		
		def auth_user( user )
			@currentApp[:auth][:user] = user
		end
	end

	module Resource

		def resource( uri , &block )
			@currentApp[:resources][uri] = {}
			@currentResource = @currentApp[:resources][uri]
			puts "Starting Resource At: /#{@currentURI + '/' + uri}"
			Docile.dsl_eval( self , &block )
		end

	end

	class Closet
		include Wire::App
		include Wire::Auth
		include Wire::Resource

		attr_reader :sinatra

		def initialize
			@sinatra = Sinatra.new

			## Create One or More
			@sinatra.post('/:app/:resource') do | a , r |
				user = headers[:from]
				context = prepare( a , r , user , r )
				if( !context[:failure] ) then
					if( actionAllowed?( :create , a , r , nil , user ) ) then
						context[:controller].create( context , request , response )
					else
						401
					end
				else
					context[:message]
				end
			end

			## Read all
			@sinatra.get('/:app/:resource') do | a , r |
				user = headers[:from]
				context = prepare( a , r , user , r)
				if( !context[:failure] ) then
					if( actionAllowed?( :readAll , a , r , nil , user ) ) then
						context[:controller].readAll( context , request , response )
					else
						401
					end
				else
					context[:message]
				end
			end

			## Read One
			@sinatra.get('/:app/:resource/*') do | a , r , i |
				user = headers[:from]
				context = prepare( a , r , user, i)
				if( !context[:failure] ) then
					if( actionAllowed?( :read , a , r , i , user ) ) then
						context[:controller].read( i , context , request , response )
					else
						401
					end
				else
					context[:message]
				end
			end

			## Update One or More
			@sinatra.put('/:app/:resource/*' ) do | a , r , i |
				user = headers[:from]
				context = prepare( a , r , user , i)
				if( !context[:failure] ) then
					if( actionAllowed?( :update , a , r , i , user ) ) then
						context[:controller].update( i , context , request , response )
					else
						401
					end
				else
					context[:message]
				end
			end

			## Delete One
			@sinatra.delete('/:app/:resource/*') do | a , r , i |
				user = headers[:from]
				context = prepare( a , r , user , i)
				if( !context[:failure] ) then
					if( actionAllowed?( :delete , a , r , i , user ) ) then
						context[:controller].delete( i , context , request , response )
					else
						401
					end
				else
					context[:message]
				end
			end

			$config = { apps: {} , editors:{}, renderers: {} , templates: {} }
		end

		def build( &block )
			puts 'Starting Up Wire...'
			puts 'Starting Apps...'
			Docile.dsl_eval( self , &block )
		end

		def info
			ap $config
		end
	end
end
