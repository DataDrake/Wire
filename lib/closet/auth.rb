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

module Wire
  # Auth is a module for handling authorization
  # @author Bryan T. Meyers
  module Auth

    # Get the allowed actions for the current URI
    # @param [Hash] context the context for this request
    # @return [Array] the allowed actions for this URI
    def actions_allowed(context)
      if context.app['auth_read_only']
        [:read, :readAll]
      elsif context.app['auth_user']
        if context.user == context.app['auth_user']
          [:create, :read, :readAll, :update, :delete]
        else
          []
        end
      elsif context.app['auth_handler']
        context.app['auth_handler'].actions_allowed(context)
      else
        [:create, :read, :readAll, :update, :delete]
      end
    end
  end
end