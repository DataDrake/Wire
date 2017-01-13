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
			actions = []
			app     = context.app
			user    = context.user
			if app
				auth  = app[:auth]
				level = auth[:level]
				case level
					when :any
						actions = [:create, :read, :readAll, :update, :delete]
					when :app
						actions = auth[:handler].actions_allowed(context)
					when :read_only
						actions = [:read,:readAll]
					when :user
						if user == auth[:user]
							actions = [:create, :read, :readAll, :update, :delete]
						end
				end
			end
			actions
		end

		# Setup auth for an App
		# @param [Symbol] level the type of authz to perform
		# @param [Proc] block setup for the authz
		# @return [void]
		def auth(level, &block)
			$current_app[:auth] = { level: level }
			unless (level == :any) || (block.nil?)
				Docile.dsl_eval(self, &block)
			end
		end

		# Select handler for :app level of auth
		# @param [Module] handler the type of authz to perform
		# @return [void]
		def handler(handler)
			$current_app[:auth][:handler] = handler
		end

		# Select user for :user level of auth
		# @return [void]
		def user(user)
			$current_app[:auth][:user] = user
		end
	end
end