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

require 'tilt'
require_relative 'history/svn'

# History is a Wire::App for accessing the history of versioned content
# @author Bryan T. Meyers
module History

  # Configure this History with a log template
  # @param [Hash] conf the raw configuration
  # @return [Hash] post-processed configuration
  def configure(conf)
    conf['log'] = Tilt.new(conf['log'], 1)
    conf
  end

  # Get the history of a single file or directory
  # @param [Hash] context the context for this request
  # @return [Response] the history, or status code
  def do_read(actions, context)
    list = get_log(context.closet.repos[context.config['repo']],
                   context.resource,
                   context.id)
    if list == 404
      return [404, {}, "File Not Found"]
    end
    template = context.config['log']
    template.render(self, actions: actions, context: context, list: list)
  end

  # Proxy method used when routing
  # @param [Array] actions the allowed actions for this URI
  # @param [Hash] context the context for this request
  # @return [Response] a Rack Response triplet, or status code
  def invoke(actions, context)
    return 404 unless context.resource
    case context.action
      when :read
        do_read(actions, context)
      else
        403
    end
  end
end
