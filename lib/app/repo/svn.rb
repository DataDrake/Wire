require_relative '../repo'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
  module SVN
    extend Wire::App
    extend Wire::Resource
    extend Repo

    @options = "--username=#{$env[:repos_user]} --password=#{$env[:repos_password]}"

    def self.do_create_file( path , repo)
      result = 200
      `svnadmin create #{path}/#{repo}`
      if $?.exitstatus != 0
        return 500
      end

      if $?.exitstatus != 0
        500
      else
        result
      end
    end

    def self.do_read_file( rev, web, path, repo , id )
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        body = `svn cat #{@options} -r #{rev} 'svn://localhost/#{repo}/#{id}'`
      else
        body = `svn cat #{@options} -r #{rev} 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      if $?.success?
        body
      else
        500
      end
    end

    def self.do_read_listing( web, path, repo , id = nil)
      if web.nil?
        if id.nil?
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}'`
        else
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{id}'`
        end
      else
        if id.nil?
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{web}'`
        else
          list = `svn list #{@options} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
        end
      end
      unless $?.exitstatus == 0
        return 404
      end
      list = $nori.parse( list )
      list[:lists][:list][:entry]
    end

    def self.do_read_info( rev, web, path, repo , id)
      if rev.nil?
        rev = 'HEAD'
      end
      if web.nil?
        info = `svn info #{@options} -r #{rev} --xml 'svn://localhost/#{repo}/#{id}'`
      else
        info = `svn info #{@options} -r #{rev} --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
      end

      unless $?.exitstatus == 0
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

      unless $?.success?
        return 500
      end
      mime = $nori.parse( mime )
      if mime[:properties].nil?
        'application/octet-stream'
      else
        mime[:properties][:target][:property]
      end
    end

    def self.do_update_file( web, path, repo, id , content, message , mime , user)
      status = 500
      `svn checkout #{@options} svn://localhost/#{repo} /tmp/svn/#{repo}`
      if $?.exitstatus == 0
        if web.nil?
          file_path = "/tmp/svn/#{repo}/#{id}"
        else
          file_path = "/tmp/svn/#{repo}/#{web}/#{id}"
        end
        file = File.open( file_path ,'w+')
        file.syswrite( content )
        file.close
        `svn add #{file_path}`
        `svn propset svn:mime-type #{mime} #{file_path}`
        `svn commit #{@options} -m '#{message}' /tmp/svn/#{repo}`
        if $?.exitstatus == 0
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