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
  # Document renders a file to an HTML representation
  # @author Bryan T. Meyers
  module Document

    # Renders a document or listing to HTML
    # @param [Array] actions the actions allowed for this URI
    # @param [Wire::Context] context the context for this request
    # @param [Symbol] specific the type of read to perform
    # @return [Response] a Rack Response triplet, or status code
    def self.do_read(actions, context, specific)
      response = context.forward(specific)
      mime     = response[1]['content-type']
      #TODO: Fix lookup
      renderer = $wire_renderers[mime]
      if renderer
        template = renderer['partial']
        template.render(self, { actions:  actions,
                                context:  context,
                                mime:     mime,
                                response: response[2] })
      else
        response
      end
    end

    # Proxy method used when routing
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.invoke(actions, context)
      case context.action
        when :create, :update, :delete
          context.forward(context.action)
        when :read
          if context.uri[3]
            do_read(actions, context, :read)
          else
            do_read(actions, context, :readAll)
          end
        else
          405
      end
    end
  end
end