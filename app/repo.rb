require 'awesome_print'
require 'nori'
require_relative '../wire'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

class Wire

  module App
    def repos_path( path )
      @currentApp[:repos_path] = path
    end
  end

end

class Repo

  class SVN
    extend Wire::App

    def self.create( context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
      path = context[:app][:repos_path]
      if( path != nil ) then
        unless Dir.exist?( "#{path}/#{context[:resource]}" )
          `svnadmin create #{path}/#{context[:resource]}`
          if $?.success? then
            200
          else
            500
          end
        else
          401
        end
      else
        'Repo Directory not specified'
      end
    end

    def self.readAll( context , request , response )
      context[:sinatra].pass unless (context[:resource_name] != nil )
      path = context[:resource_name]
      if( path != nil ) then
        referrer = request[:referrer]
        puts referrer
        info = `svn info --xml https://kgcoe-research.rit.edu/dav/#{path}`
        unless $?.success? then
          500
        end
        info = $nori.parse( info )
        mime = 'text/html'
        list = `svn --xml list https://kgcoe-research.rit.edu/dav/#{path}`
        unless $?.success? then
          500
        end
        list = $nori.parse( list )
        ap list
        referrer = request.env['HTTP_REFERRER']
        unless referrer.nil? then
          referrer = referrer.split('/')[3]
        else
          referrer = request.url.split('/')[3]
        end
        template = Tilt.new( 'views/lists/dav.haml' , 1 , {ugly: true})
        list = template.render( self, list: list[:lists][:list][:entry], resource: path , id: '',  referrer: referrer)
        body = list
        response.headers['Content-Type'] = mime
        response.headers['Cache-Control'] = 'public'
        response.headers['Expires'] = "#{(Time.now + 1000).utc}"
        response.body = body
      else
        'Root Directory not specified'
      end
    end

    def self.read( id , context , request , response )
      context[:sinatra].pass unless (context[:resource_name] != nil )
      path = context[:resource_name]
      referrer = request[:referrer]
      puts referrer
      if( path != nil ) then
        info = `svn info --xml https://kgcoe-research.rit.edu/dav/#{path}/#{id}`
        unless $?.success? then
          response.headers['Content-Type'] = 'text/html'
          response.body = Tilt.new( 'views/forms/new.haml').render
          return response
        end
        info = $nori.parse( info )
        type = info[:info][:entry][:@kind]
        if type.eql? 'dir' then
          mime = 'text/html'
          list = `svn --xml list https://kgcoe-research.rit.edu/dav/#{path}/#{id}`
          unless $?.success? then
            500
          end
          list = $nori.parse( list )
          referrer = request.env['HTTP_REFERRER']
          referrer = referrer.split('/')[3]
          template = Tilt.new( 'views/lists/dav.haml' , 1 , {ugly: true})
          list = template.render( self, list: list[:lists][:list][:entry], resource: path , id: id, referrer: referrer)
          body = list
        else
          body = `svn cat https://kgcoe-research.rit.edu/dav/#{path}/#{id}`
          unless $?.success? then
            Tilt.new( 'views/forms/new.haml').render
          end
          mime = `svn --xml propget svn:mime-type https://kgcoe-research.rit.edu/dav/#{path}/#{id}`
          unless $?.success? then
            500
          end
          mime = $nori.parse( mime )
          ap mime
          unless mime[:properties].nil? then
            mime = mime[:properties][:target][:property]
          else
            mime = 'application/octet-stream'
          end
        end
        response.headers['Content-Type'] = mime
        response.headers['Cache-Control'] = 'public'
        response.headers['Expires'] = "#{(Time.now + 1000).utc}"
        response.body = body
      else
        404
      end
    end
  end
end
