require_relative '../repo'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
  module SVN
    extend Wire::App
    extend Wire::Resource
    extend Repo

    def self.do_create( path , repo)
      result = 200
      `svnadmin create #{path}/#{repo}`
      if $?.exitstatus != 0 then
        return 500
      end

      `sed 's/# anon-access = read/anon-access = read/g' #{path}/#{repo}/conf/svnserve.conf`
      `sed 's/# auth-access = read/auth-access = write/g' #{path}/#{repo}/conf/svnserve.conf`

      if $?.exitstatus != 0 then
        500
      else
        result
      end
    end

    def self.do_read( path, repo , id )
      body = `svn cat 'svn://localhost/#{repo}/#{id}'`
      if $?.success? then
        body
      else
        500
      end
    end

    def self.do_read_listing( path, repo , id = nil)
      if id.nil? then
        list = `svn --xml list 'svn://localhost/#{repo}'`
      else
        list = `svn --xml list 'svn://localhost/#{repo}/#{id}'`
      end
      unless $?.exitstatus == 0 then
        return 404
      end
      list = $nori.parse( list )
      list[:lists][:list][:entry]
    end

    def self.do_read_info( path, repo , id)
      info = `svn info --xml 'svn://localhost/#{repo}/#{id}'`
      unless $?.exitstatus == 0 then
        return 404
      end
      info = $nori.parse( info )
      info[:info][:entry]
    end

    def self.do_read_mime(path, repo , id)
      mime = `svn --xml propget svn:mime-type 'svn://localhost/#{repo}/#{id}'`
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

    def self.do_update( path, repo, id , file, message , user)
      status = 500
      `svn checkout 'svn://localhost#{repo}' /tmp/svn/#{repo}`
      if $?.success? then
        add = true
        if File.exist? "/tmp/svn/#{repo}/#{id}" then
          `echo #{file} > /tmp/svn/#{repo}/#{id}`
        else
          `echo #{file} > /tmp/svn/#{repo}/#{id}`
          `svn add /tmp/svn/#{repo}/#{id}`
          unless $?.success? then
            add = false
          end
        end
        if add then
          `svn commit --username #{user} -m "#{message}" /tmp/svn/#{repo}`
          if $?.success? then
            status = 200
          end
        end
      end
      `rm -R /tmp/svn/#{repo}`
      status
    end
  end
end