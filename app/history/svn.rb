require_relative '../repo'
require_relative '../../../env/production'
require 'cobravsmongoose'

module History
  module SVN
    extend Wire::App
    extend Wire::Resource
    extend History

    def self.get_log(web, repo , id = nil)
      if id.nil? then
        log = `svn log -v --xml 'svn://localhost/#{repo}'`
      else
        if web.nil?
          log = `svn log -v --xml 'svn://localhost/#{repo}/#{id}'`
        else
          log = `svn log -v --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
        end
      end
      unless $?.exitstatus == 0 then
        return 404
      end
      log = CobraVsMongoose.xml_to_hash( log )
      ap log
      log['log']['logentry']
    end
  end
end