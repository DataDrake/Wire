require_relative '../repo'
require 'nori'
require 'fileutils'

# Force Nori to convert tag names to Symbols
$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module Repo
	# Repo::SVN is a connector for svnserve
	# @author Bryan T. Meyers
	module SVN
		extend Wire::App
		extend Wire::Resource
		extend Repo

		# Make a new SVN repo
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @return [Integer] status code
		def self.do_create_file(path, repo)
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

		# Read a single file
		# @param [String] rev the revision number to access
		# @param [String] web the subdirectory for web content
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @param [String] id the relative path to the file
		# @return [String] the file
		def self.do_read_file(rev, web, path, repo, id)
			@options = "--username=#{$environment[:repos_user]} --password=#{$environment[:repos_password]}"
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

		# Read a directory listing
		# @param [String] web the subdirectory for web content
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @param [String] id the relative path to the file
		# @return [Array] the directory listing
		def self.do_read_listing(web, path, repo, id = nil)
			@options = "--username=#{$environment[:repos_user]} --password=#{$environment[:repos_password]}"
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
			list = $nori.parse(list)
			list[:lists][:list][:entry]
		end

		# Read Metadata for a single file
		# @param [String] rev the revision number to access
		# @param [String] web the subdirectory for web content
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @param [String] id the relative path to the file
		# @return [Hash] the metadata
		def self.do_read_info(rev, web, path, repo, id)
			@options = "--username=#{$environment[:repos_user]} --password=#{$environment[:repos_password]}"
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
			info = $nori.parse(info)
			info[:info][:entry]
		end

		# Get a file's MIME type
		# @param [String] rev the revision number to access
		# @param [String] web the subdirectory for web content
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @param [String] id the relative path to the file
		# @return [String] the MIME type
		def self.do_read_mime(rev, web, path, repo, id)
			@options = "--username=#{$environment[:repos_user]} --password=#{$environment[:repos_password]}"
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
			mime = $nori.parse(mime)
			if mime[:properties].nil?
				'application/octet-stream'
			else
				mime[:properties][:target][:property]
			end
		end

		# Update a single file
		# @param [String] web the subdirectory for web content
		# @param [String] path the path to the repositories
		# @param [String] repo the new repo name
		# @param [String] id the relative path to the file
		# @param [String] content the updated file
		# @param [String] message the commit message
		# @param [String] mime the mime-type to set
		# @param [String] user the Author of this change
		# @return [Integer] status code
		def self.do_update_file(web, path, repo, id, content, message, mime, user)
			@options = "--username=#{$environment[:repos_user]} --password=#{$environment[:repos_password]}"
			status   = 500
			`svn checkout #{@options} svn://localhost/#{repo} /tmp/svn/#{repo}`
			if $?.exitstatus == 0
				if web.nil?
					file_path = "/tmp/svn/#{repo}/#{id}"
				else
					dir_path = "/tmp/svn/#{repo}/#{web}"
					unless Dir.exist? dir_path
						FileUtils.mkdir_p( dir_path )
					end
					file_path = "/tmp/svn/#{repo}/#{web}/#{id}"
				end

				if File.exist? file_path
					file = File.open(file_path, 'w+')
				end
				file.syswrite(content)
				file.close
				`svn add #{file_path}`
				`svn propset svn:mime-type #{mime} #{file_path}`
				`svn commit #{@options} -m "#{message}" /tmp/svn/#{repo}`
				if $?.exitstatus == 0
					status = 200
				end
				info = `svn info /tmp/svn/#{repo}`
				rev  = info.match(/Last Changed Rev: (\d+)/)[1]
				`svn propset --revprop -r #{rev} svn:author '#{user}' /tmp/svn/#{repo}`
			end
			`rm -R /tmp/svn/#{repo}`
			status
		end
	end
end