##
# Copyright 2017-2018 Bryan T. Meyers
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

  # Editor allows a document to be displayed in an editing form
  # @author Bryan T. Meyers
  module Editor

    # Open an editor for a document
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] the Editor with containing document, or status code
    def self.do_read(actions, context)
      response = context.forward(:read)
      body     = (response[0] == 200) ? response[2] : ''
      if context.query[:type]
        mime = context.query[:type]
      elsif response[1]['content-type']
        mime = response[1]['content-type']
      else
        return [404, {}, 'EDITOR: Document type not set for new document']
      end
      template = nil
      context.closet.editors.each do |k, v|
        if v['mimes'].include? mime
          template = v['file']
          break
        end
      end
      if template
        template.render(self, { actions:  actions,
                                resource: context.resource,
                                id:       context.id,
                                mime:     mime,
                                response: body })
      else
        return [404, {}, 'EDITOR: Editing of this file type is not supported']
      end
    end

    # Proxy method used when routing
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.invoke(actions, context)
      case context.action
        when :create, :update
          context.forward(context.action)
        when :read
          do_read(actions, context)
        else
          405
      end
    end
  end
end