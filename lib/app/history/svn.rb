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

require_relative '../repo'
require 'cobravsmongoose'

module History
  # History::SVN is a connector for viewing log information in SVN
  # @author Bryan T. Meyers
  module SVN
    extend History

    # Get the log information for any part of a Repo
    # @param [String] host the name of the host to connect to
    # @param [String] repo the name of the repository to access
    # @param [String] web the web path of the repo
    # @param [String] id the sub-URI of the item to access
    # @return [Hash] the history entries
    def self.get_log(host, repo, web, id = nil)
      options = "--username #{$environment[:repos_user]} --password #{$environment[:repos_password]}"
      uri     = "svn://#{host}/#{repo}"
      if id
        if web
          uri += "/#{web}"
        end
        uri += "/#{id}"
      end
      log = `svn log #{options} -v --xml '#{uri}'`
      if $?.exitstatus != 0
        return 404
      end
      log = CobraVsMongoose.xml_to_hash(log)
      log['log']['logentry']
    end
  end
end