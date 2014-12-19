require 'awesome_print'
require_relative '../wire'

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
      path = context[:app][:repos_path]
      if( path != nil ) then
        unless Dir.exists?("#{path}/#{context[:resource_name]}")
          401
        else
          list = `svn ls --xml https://kgcoe-research.rit.edu/dav/Test`
          ap list
          if $?.success? then
            list
          else
            500
          end
        end
      else
        'Root Directory not specified'
      end
    end

    def self.read( id , context , request , response )
      context[:sinatra].pass unless (context[:resource] != nil )
      path = context[:resource][:local_path]
      if( path != nil ) then

        if( ext_path.end_with?( '.wiki' ) || ext_path.end_with?( '.mediawiki' ) ) then
          mime = 'text/wiki'
        else
          mime = `mimetype --brief #{ext_path}`
        end
        response.headers['Content-Type'] = mime
        response.headers['Cache-Control'] = 'public'
        response.headers['Expires'] = "#{(Time.now + 30000000).utc}"
        response.body = File.read( ext_path )

      else
        404
      end
    end
  end
end
