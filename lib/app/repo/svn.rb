##
# Copyright 2017 Bryan T. Meyers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
##

require 'nori'
require 'fileutils'
require_relative '../repo'

module Repo
  # Repo::SVN is a connector for svnserve
  # @author Bryan T. Meyers
  module SVN
    extend Repo

    # Force Nori to convert tag names to Symbols
    @@nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

    # Read a single file
    # @param [String] conf the repo config
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @param [String] rev the revision number to access
    # @return [String] the file
    def self.do_read_file(conf, repo, id, rev)
      options = "--username #{conf['user']} --password #{conf['password']}"
      if rev.nil?
        rev = 'HEAD'
      end
      if conf['web_folder'].nil?
        body = `svn cat #{options} -r #{rev} '#{conf['protocol']}://#{conf['host']}/#{repo}/#{id}'`
      else
        body = `svn cat #{options} -r #{rev} '#{conf['protocol']}://#{conf['host']}/#{repo}/#{conf['web_folder']}/#{id}'`
      end

      if $?.success?
        body
      else
        500
      end
    end

    # Read a directory listing
    # @param [String] conf the repo config
    # @param [String] repo the repo name
    # @param [String] id the relative path to the file
    # @return [Array] the directory listing
    def self.do_read_listing(conf, repo, id = nil)
      options = "--username #{conf['user']} --password #{conf['password']}"
      if conf['web_folder'].nil?
        if id.nil?
          list = `svn list #{options} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}'`
        else
          list = `svn list #{options} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}/#{id}'`
        end
      else
        if id.nil?
          list = `svn list #{options} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}/#{conf['web_folder']}'`
        else
          list = `svn list #{options} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}/#{conf['web_folder']}/#{id}'`
        end
      end
      unless $?.exitstatus == 0
        return 404
      end
      list = @@nori.parse(list)
      list[:lists][:list][:entry]
    end

    # Read Metadata for a single file
    # @param [String] conf the repo config
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @param [String] rev the revision number to access
    # @return [Hash] the metadata
    def self.do_read_info(conf, repo, id, rev)
      options = "--username #{conf['user']} --password #{conf['password']}"
      if rev.nil?
        rev = 'HEAD'
      end
      if conf['web_folder'].nil?
        info = `svn info #{options} -r #{rev} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}/#{id}'`
      else
        info = `svn info #{options} -r #{rev} --xml '#{conf['protocol']}://#{conf['host']}/#{repo}/#{conf['web_folder']}/#{id}'`
      end

      unless $?.exitstatus == 0
        return 404
      end
      info = @@nori.parse(info)
      info[:info][:entry]
    end

    # Get a file's MIME type
    # @param [String] conf the repo config
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @param [String] rev the revision number to access
    # @return [String] the MIME type
    def self.do_read_mime(conf, repo, id, rev)
      options = "--username #{conf['user']} --password #{conf['password']}"
      if rev.nil?
        rev = 'HEAD'
      end
      if conf['web_folder'].nil?
        mime = `svn propget #{options} -r #{rev} --xml svn:mime-type '#{conf['protocol']}://#{conf['host']}/#{repo}/#{id}'`
      else
        mime = `svn propget #{options} -r #{rev} --xml svn:mime-type '#{conf['protocol']}://#{conf['host']}/#{repo}/#{conf['web_folder']}/#{id}'`
      end
      unless $?.success?
        return 500
      end
      mime = @@nori.parse(mime)
      if mime[:properties].nil?
        'application/octet-stream'
      else
        mime[:properties][:target][:property]
      end
    end

    # Update or create a single file
    # @param [String] conf the repo config
    # @param [String] repo the new repo name
    # @param [String] id the relative path to the file
    # @param [String] content the updated file
    # @param [String] message the commit message
    # @param [String] mime the mime-type to set
    # @param [String] username the Author of this change
    # @return [Integer] status code
    def self.do_update_file(conf, repo, id, content, message, mime, username)
      options = "--depth empty --username #{conf['user']} --password #{conf['password']}"
      status  = 500
      repo_path = "/tmp/#{username}/#{repo}"
      unless Dir.exist? repo_path
        FileUtils.mkdir_p(repo_path)
      end

      `svn checkout #{options} '#{conf['protocol']}://#{conf['host']}/#{repo}' '#{repo_path}'`

      if $?.exitstatus == 0
        file_path = CGI.unescape(id)
        if conf['web_folder']
          file_path = "#{conf['web_folder']}/#{file_path}"
        end
        folder_path = file_path.split('/')
        folder_path.pop
        folder_path = folder_path.join('/')

        unless Dir.exist? folder_path
          FileUtils.mkdir_p(folder_path)
        end

        file = File.open(file_path, 'w+')
        file.syswrite(content)
        file.close
        `svn add --force "#{repo_path}/*"`
        `svn propset svn:mime-type "#{mime}" "#{file_path}"`
        `svn commit #{options} -m "#{message}" "#{repo_path}"`
        if $?.exitstatus == 0
          status = 200
        end
        `svn propset #{options} --revprop -r HEAD svn:author '#{username}' "#{repo_path}"`
      end
      `rm -R '#{repo_path}'`
      status
    end

    self.alias_method :do_create_file, :do_update_file

  end
end