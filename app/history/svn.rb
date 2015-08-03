require_relative '../repo'
require_relative '../../../env/production'
require 'nori'

$nori = Nori.new :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }

module History
  module SVN
    extend Wire::App
    extend Wire::Resource
    extend History

    def self.get_log(web, repo , id = nil)
      if id.nil? then
        log = `svn log --xml 'svn://localhost/#{repo}'`
      else
        if web.nil?
          log = `svn log --xml 'svn://localhost/#{repo}/#{id}'`
        else
          log = `svn log --xml 'svn://localhost/#{repo}/#{web}/#{id}'`
        end
      end
      unless $?.exitstatus == 0 then
        return 404
      end
      log = $nori.parse( log )
      ap log
      log[:log][:logentry]
    end
  end
end