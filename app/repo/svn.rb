require_relative '../repo'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
  module SVN
    include Repo

    def self.do_create( path , repo)
      `svnadmin create #{path}/#{repo}`
      if $?.success? then
        200
      else
        500
      end
    end

    def self.do_read( repo , id )
      body = `svn cat 'https://kgcoe-research.rit.edu/dav/#{repo}/#{id}'`
      if $?.success? then
        body
      else
        500
      end
    end

    def self.do_read_listing( repo , id)
      if id.nil? then
        list = `svn --xml list 'svn+ssh://localhost/dav/#{repo}'`
      else
        list = `svn --xml list 'svn+ssh://localhost/dav/#{repo}/#{id}'`
      end
      unless $?.success? then
        500
      end
      list = $nori.parse( list )
      list[:lists][:list][:entry]
    end

    def self.do_read_info( repo , id)
      info = `svn info --xml 'https://kgcoe-research.rit.edu/dav/#{repo}/#{id}'`
      unless $?.success? then

        return 404
      end
      info = $nori.parse( info )
      info[:info][:entry]
    end

    def self.do_read_mime(repo , id)
      mime = `svn --xml propget svn:mime-type 'https://localhost/dav/#{path}/#{id}'`
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

    def self.do_update( repo, id , file, message)
      status = 500
      `svn checkout 'https://localhost/dav/#{repo}' /tmp/svn/#{repo}`
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
          `svn commit -m "#{message}" /tmp/svn/#{repo}`
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