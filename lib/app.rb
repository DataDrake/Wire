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

require_relative 'closet/config'

module Wire
  # App is a a REST endpoint for a Wire service
  # @author Bryan T. Meyers
  module App

    # Callback for handling configs
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure(conf)
      conf['type'] = Object.const_get(conf['type'])
      if conf['type'].respond_to? :configure
        conf = conf['type'].configure(conf)
      end
      if conf['auth_handler']
        conf['auth_handler'] = Object.const_get(conf['auth_handler'])
      end
      conf
    end

    # Read all of the configs in './config/apps'
    # @return [void]
    def self.read_configs
      Wire::Config.read_config_dir('config/apps', method(:configure))
    end
  end
end

require_relative 'app/cache'
require_relative 'app/db'
require_relative 'app/file'
require_relative 'app/login'
require_relative 'app/history'
require_relative 'app/render'
require_relative 'app/repo'