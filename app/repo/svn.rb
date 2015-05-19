require_relative '../repo'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
  module SVN
    extend Repo

    def self.do_create( path , repo)
      `svnadmin create #{path}/#{repo}`
      if $?.success? then
        200
      else
        500
      end
    end

    def self.do_read( path, repo , id )
      body = `svn cat '#{path}/#{repo}/#{id}'`
      if $?.success? then
        body
      else
        500
      end
    end

    def self.do_read_listing( path, repo , id = nil)
      if id.nil? then
        list = `svn --xml list '#{path}/#{repo}'`
        puts list
      else
        list = `svn --xml list '#{path}/#{repo}/#{id}'`
      end
      unless $?.success? then
        500
      end
      list = $nori.parse( list )
      list[:lists][:list][:entry]
    end

    def self.do_read_info( path, repo , id)
      info = `svn info --xml '#{path}/#{repo}/#{id}'`
      unless $?.exitstatus == 0 then
        return 404
      end
      info = $nori.parse( info )
      info[:info][:entry]
    end

    def self.do_read_mime(path, repo , id)
      mime = `svn --xml propget svn:mime-type '#{path}/#{repo}/#{id}'`
      unless $?.success? then
        500
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
      `svn checkout '#{path}/#{repo}' /tmp/svn/#{repo}`
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