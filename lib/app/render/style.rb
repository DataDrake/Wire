require_relative '../render'

module Render
	# Style uses Tilt to render and serve stylesheets
	# @author Bryan T. Meyers
	module Style
		extend Render

		# DSL method to create a style
		# @param [String] resource the sub-URI for this style
		# @param [Hash] path the file location of the stylesheet
		# @return [void]
		def self.style(resource, path)
			unless $current_app[:styles]
				$current_app[:styles] = {}
			end
			$current_app[:styles][resource] = path.nil? ? nil : Tilt.new(path, 1, { ugly: true }).render
		end

		# Render a stylesheet to CSS
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read_all(context)
			begin
				resource = context.uri[2]
				template = context.app[:styles][resource]
				headers  = {'Cache-Control' => 'public,max-age=3600'}
				if template
					headers['Content-Type'] = 'text/css'
					[200, headers, [template]]
				else
					500
				end
			rescue RestClient::ResourceNotFound
				404
			end
		end

		# Proxy method used when routing
		# @param [Array] actions the allowed actions for this URI
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.invoke(actions, context)
			case context.action
				when :read
					do_read_all(context)
				else
					403
			end
		end
	end
end