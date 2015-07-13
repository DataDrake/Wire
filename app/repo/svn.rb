require_relative '../repo'
require_relative '../../../env/production'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
  module SVN
    extend Wire::App
    extend Wire::Resource
    extend Repo

    @options = "--username=#{$production[:repos_user]} --password=#{$production[:repos_password]}"

    def self.do_create( path , repo)
      result = 200
      `svnadmin create #{path}/#{repo}`
      if $?.exitstatus != 0 then
        return 500
      end

      if $?.exitstatus != 0 then
        500
      else
        result
      end
    end

    def self.do_read( rev, web, path, repo , id )
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil? then
        body = `svn cat #{@options} -r #{rev} 'svn://localhost/#{repo}/#{id}'`
      else
        body = `svn cat #{@options} -r #{rev} 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      if $?.success? then
        body
      else
        500
      end
    end

    def self.do_read_listing( web, path, repo , id = nil)
      if web.nil? then
        if id.nil? then
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}'`
        else
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{id}'`
        end
      else
        if id.nil? then
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{web}'`
        else
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
        end
      end
      unless $?.exitstatus == 0 then
        return 404
      end
      list = $nori.parse( list )
      list[:lists][:list][:entry]
    end

    def self.do_read_info( rev, web, path, repo , id)
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil? then
        info = `svn info #{@options} -r #{rev} --xml 'svn://localhost/#{repo}/#{id}'`
      else
        info = `svn info #{@options} -r #{rev} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      unless $?.exitstatus == 0 then
        return 404
      end
      info = $nori.parse( info )
      info[:info][:entry]
    end

    def self.do_read_mime( rev, web, path, repo , id)
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        mime = `svn propget #{@options} -r #{rev} --xml svn:mime-type 'svn://localhost/#{repo}/#{id}'`
      else
        mime = `svn propget #{@options} -r #{rev} --xml svn:mime-type 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      unless $?.success? then
        return 500
      end
      mime = $nori.parse( mime )
      unless mime[:properties].nil? then
        mime[:properties][:target][:property]
      else
        'application/octet-stream'
      end
    end

    def self.do_update( web, path, repo, id , content, message , mime , user)
      status = 500
      `svn checkout #{@options} svn://localhost/#{repo} /tmp/svn/#{repo}`
      if $?.exitstatus == 0 then
        if web.nil?
          filepath = "/tmp/svn/#{repo}/#{id}"
        else
          filepath = "/tmp/svn/#{repo}/#{web}/#{id}"
        end
        file = File.open( filepath ,'w+')
        file.syswrite( content )
        file.close
        `svn add #{filepath}`
        `svn propset svn:mime-type #{mime} #{filepath}`
        `svn commit #{@options} -m '#{message}' /tmp/svn/#{repo}`
        if $?.exitstatus == 0 then
          status = 200
        end
        info = `svn info /tmp/svn/#{repo}`
        rev = info.match(/Last Changed Rev: (\d+)/)[1]
        `svn propset --revprop -r #{rev} svn:author '#{user}' /tmp/svn/#{repo}`
      end
      `rm -R /tmp/svn/#{repo}`
      status
    end
  end
end