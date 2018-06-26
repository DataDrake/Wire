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

module Render
  module Error

    # Configure error templates
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure(conf)
      conf['errors'].each do |k, v|
        conf['errors'][k] = Tilt.new(v, 1)
      end
      conf
    end

    def self.error_check(actions, context, result)
      errors = context.config['errors']
      if errors
        template = errors[result[0]]
        if template
          result[2] = template.render(self, { actions: actions,
                                              context: context,
                                              result:  result })
        end
      end
      result
    end

    def self.invoke(actions, context)
      case context.action
        when :create, :update
          result = context.forward(context.action)
        when :read
          if context.id
            result = context.forward(:read)
          else
            result = context.forward(:readAll)
          end
        else
          result = 405
      end
      error_check(actions, context, result)
    end
  end
end