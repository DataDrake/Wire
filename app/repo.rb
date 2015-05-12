require 'awesome_print'
require_relative '../wire'

module Repo
  extend Wire::App
  extend Wire::Resource

  def self.repos( path )
    $currentApp[:repos_path] = path
  end

  def self.listing( path )
    $currentApp[:template] = Tilt.new( path , 1 , {ugly: true})
  end

  def self.create( context , request , response )
    context[:sinatra].pass unless (context[:resource] != nil )
    path = context[:app][:repos_path]
    resource = context[:resource]
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

  def self.readAll( context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    resource = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    mime = 'text/html'
    list = do_read_listing( resource )
    if list == 500 then
      return 500
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

  def self.read( id , context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    path = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    info = do_read_info( path , id )
    if info == 404 then
      response.headers['Content-Type'] = 'text/html'
      response.body = Tilt.new( 'views/forms/new.haml').render(self, resource: path, id: id)
      response.status = 200
    end
    type = info[:@kind]
    if type.eql? 'dir' then
      mime = 'text/html'
      list = do_read_listing( path , id)
      unless referrer.nil? then
        referrer = referrer.split('/')[3]
      else
        referrer = request.url.split('/')[3]
      end
      template =context[:app][:template]
      body = template.render( self, list: list, resource: path , id: id, referrer: referrer)
    else
      body = `svn cat 'https://kgcoe-research.rit.edu/dav/#{path}/#{id}'`
      if body == 500
        return body
      end
      mime = do_read_mime( path , id )
    end
    response.headers['Content-Type'] = mime
    response.headers['Cache-Control'] = 'public'
    response.headers['Expires'] = "#{(Time.now + 1000).utc}"
    response.body = body
  end
end
