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

  def do_read( id , context , request , response , actions )
    context[:sinatra].pass unless (context[:resource_name] != nil )
    resource = context[:resource_name]
    referrer = request.env['HTTP_REFERRER']
    web = context[:app][:web]
    list = get_log( web, resource , id )
    if list == 404 then
      return 404
    end
    ap referrer
    if referrer.nil? then
      referrer = request.url
    end
    referrer.sub!(/^.*?\/\/.*?(\/.*)$/, '\1')
    referrer.sub!(/^(.*)\/.*$/, '\1') ## TODO: Fix referral links
    template = context[:app][:template]
    template.render( self, list: list, resource: resource , id: id, referrer: referrer)
  end

  def do_readAll( context , request , response , actions )
    do_read( nil , context, request , response , actions)
  end
end
