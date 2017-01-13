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

require_relative '../render'

module Render
	# Style uses Tilt to render and serve stylesheets
	# @author Bryan T. Meyers
	module Style
		extend Render

    # Configure styles
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure(conf)
      conf['styles'].each do |k,v|
        conf['styles'][k] = Tilt.new(v, 1, { ugly: true }).render
      end
      conf
    end

		# Render a stylesheet to CSS
		# @param [Hash] context the context for this request
		# @return [Response] a Rack Response triplet, or status code
		def self.do_read_all(context)
			resource = context.uri[2]
			template = context.app['styles'][resource]
			headers  = {'Cache-Control': 'public,max-age=3600'}
			if template
				headers['Content-Type'] = 'text/css'
				[200, headers, [template]]
			else
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