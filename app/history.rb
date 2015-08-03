require 'awesome_print'
require_relative '../wire'
require_relative 'history/svn'

module History

  def repos( path )
    $currentApp[:repos_path] = path
  end

  def log( path )
    $currentApp[:template] = Tilt.new( path , 1 , {ugly: true})
  end

  def web_folder( path )
    $currentApp[:web] = path
  end

  def read( id , context , request , response )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    resource = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    repos = context[:app][:repos_path]
    list = get_log( repos, resource , id )
    if list == 404 then
      return 404
    end
    ap referrer
    if referrer.nil? then
      referrer = request.url
    end
    referrer.sub!(/^.*?:\/\/.*?(\/.*)$/, '\1')
    template = context[:app][:template]
    template.render( self, list: list, resource: resource , id: id, referrer: referrer)
  end

  def readAll( context , request , response )
    read( nil , context, request , response)
  end
end
