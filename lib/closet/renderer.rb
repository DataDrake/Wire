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

require 'tilt'
require_relative 'config'

module Wire
  # Renderer is a module for mapping mime to rendering templates
  # @author Bryan T. Meyers
  module Renderer

    # Callback for handling partials
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure_partial(conf)
      conf['partial'] = Tilt.new(conf['partial'], 1, { ugly: true })
      conf
    end

    # Callback for handling templates
    # @param [Hash] conf the raw configuration
    # @return [Hash] post-processed configuration
    def self.configure_template(conf)
      conf['file'] = Tilt.new(conf['file'], 1, { ugly: true })
      conf
    end

    # Read all of the configs in './configs/apps'
    # @return [void]
    def self.read_configs
      $wire_editors   = Wire::Config.read_config_dir('config/editors', method(:configure_template))
      $wire_renderers = Wire::Config.read_config_dir('config/renderers', method(:configure_partial))
      $wire_templates = Wire::Config.read_config_dir('config/templates', method(:configure_template))
    end
  end
end