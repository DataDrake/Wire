require_relative '../repo'
require 'cobravsmongoose'

module History
	# History::SVN is a connector for viewing log information in SVN
	# @author Bryan T. Meyers
	module SVN
		extend Wire::App
		extend Wire::Resource
		extend History

		# Get the log information for any part of a Repo
		# @param [String] web the web path of the repo
		# @param [String] repo the name of the repository to access
		# @param [String] id the sub-URI of the item to access
		# @return [Hash] the history entries
		def self.get_log(web, repo, id = nil)
			if id.nil?
				log = `svn log -v --xml 'svn://localhost/#{repo}'`
			else
				if web.nil?
					log = `svn log -v --xml 'svn://localhost/#{repo}/#{id}'`
				else
					log = `svn log -v --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
				end
			end
			unless $?.exitstatus == 0
				return 404
			end
			log = CobraVsMongoose.xml_to_hash(log)
			log['log']['logentry']
		end
	end
end