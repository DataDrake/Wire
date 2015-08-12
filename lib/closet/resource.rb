module Wire
	module Resource
		def resource(uri, &block)
			$current_app[:resources][uri] = {}
			$current_resource             = $current_app[:resources][uri]
			puts "Starting Resource At: /#{$current_uri + '/' + uri}"
			Docile.dsl_eval(self, &block)
		end
	end
end