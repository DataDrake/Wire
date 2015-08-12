$environment = {} unless $environment

require_relative 'closet'
require_relative 'app'

require 'docile'
require 'json'
require 'rack'

module JSON

	# Force JSON.parse to symbolize names
	# @param [String] source the raw JSON string
	# @param [Hash] opts any further options for JSON.parse
	# @return [Hash] the parsed JSON content
	def self.parse_clean(source, opts = {})
		opts[:symbolize_names] = true
		parse(source, opts)
	end
end

# Wire is an environment for quickly building REST services
# @author Bryan T. Meyers
module Wire
	VERSION = '0.1.0'
end
