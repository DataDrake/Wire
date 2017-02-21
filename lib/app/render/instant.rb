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

module Render
  # Instant allows for previews of edited documents
  # @author Bryan T. Meyers
  module Instant

    # Render a temporary document to HTML
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.do_update(actions, context)
      ## Default to not found
      message = ''
      status  = 404
      if context.resource
        body = context.body
        if body
          body = body.split('=')[1]
          if body
            body = URI.decode(body)
          end
          ## Assume unsupported mime type
          status   = 415
          message  = 'INSTANT: Unsupported MIME Type'
          mime     = "#{context.resource}/#{context.id}"
          renderer = nil
          context.closet.renderers.each do |k, v|
            if v['mimes'].include? mime
              renderer = v['partial']
              break
            end
          end
          if renderer
            result   = renderer.render(self, { actions:  actions,
                                               context:  context,
                                               mime:     mime,
                                               response: body, })
            name     = context.config['template']
            template = context.closet.templates[name]
            if template
              message = template['file'].render(self, { actions: actions,
                                                        context: context,
                                                        content: result })
            else
              message = result
            end
            status = 200
          end
        end
      end
      [status, {}, message]
    end

    # Proxy method used when routing
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.invoke(actions, context)
      if context.action.eql? :update
        do_update(actions, context)
      else
        405
      end
    end
  end
end