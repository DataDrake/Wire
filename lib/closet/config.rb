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

require 'yaml'

module Wire
  module Config
    def self.read_config_dir(dir, callback)
      configs = {}
      Dir[File.join(dir,'*.yaml')].each do |entry|
        name = File.basename(entry,'.yaml')
        config = YAML.load_file(File.join(dir,entry))
        if callback
          config = callback.call(config)
        end
        configs[name] = config
      end
      configs
    end
  end
end