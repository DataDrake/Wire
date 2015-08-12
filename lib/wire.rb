$environment = {} unless $environment

require_relative 'closet'
require_relative 'app'

require 'docile'
require 'json'
require 'rack'

module JSON
	def self.parse_clean(source, opts = {})
		opts[:symbolize_names] = true
		parse(source, opts)
	end
end

module Wire
	VERSION = '0.1.0'
end
