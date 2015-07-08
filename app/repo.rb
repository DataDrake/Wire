require 'awesome_print'
require_relative '../wire'
require_relative 'repo/svn'

module Repo

  def repos( path )
    $currentApp[:repos_path] = path
  end

  def listing( path )
    $currentApp[:template] = Tilt.new( path , 1 , {ugly: true})
  end

  def web_folder( path )
    $currentApp[:web] = path
  end

  def create( context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    path = context[:app][:repos_path]
    resource = context[:resource_name]
    if( path != nil ) then
      unless Dir.exist?( "#{path}/#{resource}" )
        do_create( path, resource)
      else
        401
      end
    else
      'Repo Directory not specified'
    end
  end

  def readAll( context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    resource = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    repos = context[:app][:repos_path]
    web = context[:app][:web]
    mime = 'text/html'
    list = do_read_listing( web, repos, resource )
    if list == 404 then
      return 404
    end
    unless referrer.nil? then
      referrer = referrer.split('/')[3]
    else
      referrer = request.url.split('/')[3]
    end
    template = context[:app][:template]
    list = template.render( self, list: list, resource: resource , id: '',  referrer: referrer)
    response.headers['Content-Type'] = mime
    response.headers['Cache-Control'] = 'public'
    response.headers['Expires'] = "#{(Time.now + 1000).utc}"
    response.body = list
  end

  def read( id , context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    path = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    repos = context[:app][:repos_path]
    web = context[:app][:web]
    info = do_read_info( web, repos, path , id )
    if info == 404 then
      return 404
    end
    type = info[:@kind]
    if type.eql? 'dir' then
      mime = 'text/html'
      list = do_read_listing( web, repos, path , id)
      unless referrer.nil? then
        referrer = referrer.split('/')[3]
      else
        referrer = request.url.split('/')[3]
      end
      template =context[:app][:template]
      body = template.render( self, list: list, resource: path , id: id, referrer: referrer)
    else
      body = do_read( web, repos, path , id )
      if body == 500
        return body
      end
      mime = do_read_mime( web, repos, path , id )
    end
    response.headers['Content-Type'] = mime
    response.headers['Cache-Control'] = 'public'
    response.headers['Expires'] = "#{(Time.now + 1000).utc}"
    response.body = body
  end

  def update( id, context, request , response )
    200
  end
end
