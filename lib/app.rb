module Wire
	# App is a DSL function for mapping sub-URI to Wire::App(s)
	# @author Bryan T. Meyers
	module App

		# Setup an App
		# @param [String] base_uri the sub-URI
		# @param [Module] type the Wire::App
		# @param [Proc] block for configuring this App
		# @return [void]
		def app(base_uri, type, &block)
			$current_uri    = base_uri
			$apps[base_uri] = { type: type, resources: {} }
			$current_app    = $apps[base_uri]
			if ENV['RACK_ENV'].eql? 'development'
				$stderr.puts "Starting App at: /#{base_uri}"
				$stderr.puts 'Setting up resources...'
			end
			Docile.dsl_eval(type, &block)
		end
	end
end

require_relative 'app/db'
require_relative 'app/file'
require_relative 'app/login'
require_relative 'app/history'
require_relative 'app/render'
require_relative 'app/repo'