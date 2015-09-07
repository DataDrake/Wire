module Wire

	# Resource is a DSL function for mapping sub-URI in Wire::App(s)
	# @author Bryan T. Meyers
	module Resource

		# Setup a Renderer
		# @param [String] uri the sub-URI
		# @param [Proc] block for configuring this resource
		# @return [void]
		def resource(uri, &block)
			$current_app[:resources][uri] = {}
			$current_resource             = $current_app[:resources][uri]
			if ENV['RACK_ENV'].eql? 'development'
				$stderr.puts "Starting Resource At: /#{$current_uri + '/' + uri}"
			end
			Docile.dsl_eval(self, &block)
		end
	end
end