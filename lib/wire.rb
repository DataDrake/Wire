require_relative 'app'
require_relative 'resource'
require_relative 'closet'

require 'docile'
require 'json'

module JSON
  def self.parse_clean( source , opts = {})
    opts[:symbolize_names] = true
    parse( source , opts )
  end
end

module Wire
  VERSION = '0.1.0'
end
