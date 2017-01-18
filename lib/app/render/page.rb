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
  # Page builds the a page that is presented directly to a user
  # @author Bryan T. Meyers
  module Page

    # Render a full template, handling the gathering of additional Sources
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @param [Tilt::Template] template a pre-loaded Tilt template to render
    # @param [String] content the content to render into the page
    # @return [Response] a Rack Response triplet, or status code
    def self.render_template(actions, context, template, content)
      if template['file']
        hash = { actions: actions, context: context, content: content }
        template['sources'].each do |k, s|
          uri      = "http://#{context.config['remote'].split('/')[0]}"
          go_ahead = true
          if s.is_a? Hash
            uri += "/#{s['uri']}"
            case s['key']
              when 'user'
                go_ahead = (context.user and !context.user.empty?)
                uri      += "/#{context.user}"
              when 'resource'
                go_ahead = (context.resource and !context.resource.empty?)
                uri      += "/#{context.resource}"
              else
                # do nothing
            end
          else
            uri += "#{s}"
          end
          temp = []
          if go_ahead
            temp = RL.request(:get, uri, { remote_user: context.user })
          end
          if temp[0] == 200
            begin
              hash[k.to_sym] = JSON.parse_clean(temp[2])
            rescue
              hash[k.to_sym] = temp[2]
            end
          end
        end
        message = template[:path].render(self, hash)
        if template['use_layout']
          message = render_template(actions, context, $wire_templates['layout'], message)
        end
      else
        message = 'Invalid Template'
      end
      message
    end

    # Render a page to its final form
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @param [Symbol] specific the kind of read to perform
    # @return [Response] a Rack Response triplet, or status code
    def self.do_read(actions, context, specific)
      if context.resource
        result   = context.forward(specific)
        #TODO: fix lookup
        name = context.config['template']
        template = $wire_templates[name]
        if template
          result[1]['Content-Type'] = 'text/html'
          result[2]                 = render_template(actions, context, template, result[2])
        end
      else
        result = [401, {}, 'Resource not specified']
      end
      result
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
          if context.id
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
