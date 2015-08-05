require 'awesome_print'
require 'tilt'
require_relative '../wire'
require_relative 'history/svn'

module History

  def repos( path )
    $current_app[:repos_path] = path
  end

  def log( path )
    $current_app[:template] = Tilt.new( path , 1 , {ugly: true})
  end

  def web_folder( path )
    $current_app[:web] = path
  end

  def do_read( context )
    return 404 unless context[:resource_name]
    resource = context[:resource_name]
    referrer = context[:request].env['HTTP_REFERRER']
    web = context[:app][:web]
    list = get_log( web, resource , id )
    if list == 404
      return 404
    end
    if referrer.nil?
      referrer = request.url
    end
    referrer.sub!(/^.*?\/\/.*?(\/.*)$/, '\1')
    referrer.sub!(/^(.*)\/.*$/, '\1') ## TODO: Fix referral links
    template = context[:app][:template]
    template.render( self, list: list, resource: resource , id: id, referrer: referrer)
  end

  def invoke( actions , context )
    case context[:action]
      when :read
        do_read( context )
      else
        403
    end
  end
end
