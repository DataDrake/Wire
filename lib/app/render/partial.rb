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

require 'rest-less'
require 'tilt'

module Render
  # Partials are URI mapped renderers which generate only a piece of a document
  # @author Bryan T.Meyers
  module Partial

    # Configure repo with listing template
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure(conf)
      conf['resources'].each do |k, v|
        if v.is_a? Hash
          conf['resources'][k]['multiple'] = Tilt.new(v['multiple'], 1, { ugly: true })
          conf['resources'][k]['single']   = Tilt.new(v['single'], 1, { ugly: true })
        elsif v.is_a? String
          conf['resources'][k] = { 'all' => Tilt.new(v, 1, { ugly: true }) }
        end
      end
      conf
    end

    # Read a listing and render to HTML
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.do_read_all(actions, context)
      body     = ''
      mime     = ''
      resource = context.config['resources'][context.resource]
      if resource['use_forward']
        response = context.forward(:readAll)
        return response if response[0] != 200
        mime = response[1][:content_type]
        body = response[2]
      end
      if resource['all']
        template = resource['all']
      else
        template = resource['multiple']
      end
      if template
        hash = { actions:  actions,
                 context:  context,
                 resource: resource,
                 mime:     mime,
                 response: body }
        if resource['extras']
          resource['extras'].each do |k, v|
            temp = RL.request(:get,
                              "http://#{context.config['remote'].split('/')[0]}/#{v}",
                              { remote_user: context.user }
            )[2]
            begin
              hash[k.to_sym] = JSON.parse_clean(temp)
            rescue
              hash[k.to_sym] = temp
            end

          end
        end
        mime = 'text/html'
        body = template.render(self, hash)
      end
      [200, { 'Content-Type' => mime }, body]
    end

    # Read a Partial and render it to HTML
    # @param [Array] actions the allowed actions for this URI
    # @param [Hash] context the context for this request
    # @return [Response] a Rack Response triplet, or status code
    def self.do_read(actions, context)
      body     = ''
      mime     = ''
      resource = context.config['resources'][context.resource]

      if resource['use_forward']
        response = context.forward(:read)
        return response if response[0] != 200
        mime = response[1][:content_type]
        body = response[2]
      end
      if resource['all']
        template = resource['all']
      else
        template = resource['single']
      end
      if template
        hash = { actions:  actions,
                 context:  context,
                 resource: resource,
                 mime:     mime,
                 response: body }
        if resource['extras']
          resource['extras'].each do |k, v|
            temp = RL.request(:get, "http://#{context.config['remote'].split('/')[0]}/#{v}")[2]
            begin
              hash[k.to_sym] = JSON.parse_clean(temp)
            rescue
              hash[k.to_sym] = temp
            end
          end
        end
        mime = 'text/html'
        body = template.render(self, hash)
      end
      [200, { 'Content-Type' => mime }, body]
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
            do_read(actions, context)
          else
            do_read_all(actions, context)
          end
        else
          403
      end
    end
  end
end