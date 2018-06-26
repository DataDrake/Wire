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

require 'rack'
require_relative 'app'
require_relative 'closet/auth'
require_relative 'closet/config'
require_relative 'closet/context'
require_relative 'closet/renderer'


module Wire
  # A Closet is a configured Wire Environment
  # @author Bryan T. Meyers
  class Closet
    include Wire::Auth

    attr_reader :apps, :editors, :renderers, :templates
    attr_reader :dbs, :env, :repos, :mode

    # Create an empty Closet and connect to datasources.
    # @return [Wire::Closet] the new closet
    def initialize
      @mode = ENV['RACK_ENV']
      if @mode.nil? or @mode.empty?
        @mode = 'production'
      end
      if @mode.eql? 'development'
        $stderr.puts 'Starting Up Wire...'
        $stderr.puts 'Reading Environment Config...'
      end
      configs = Wire::Config.read_config_dir('./config/env', nil)
      @env = configs[@mode]
      if @mode.eql? 'development'
        $stderr.puts 'Reading DB Configs...'
      end
      @dbs = DB.read_configs
      if @mode.eql? 'development'
        $stderr.puts 'Reading Repo Configs...'
      end
      @repos = Repo.read_configs
    end

    # Setup the closet
    def build
      if @mode.eql? 'development'
        $stderr.puts 'Reading App Configs...'
      end
      @apps = Wire::App.read_configs
      if @mode.eql? 'development'
        $stderr.puts 'Reading [Editor|Renderer|Template] Configs...'
      end
      @editors, @renderers, @templates = Wire::Renderer.read_configs
      if @mode.eql? 'development'
        info
      end
    end

    # Route a Request to the correct Wire::App
    # @param [Wire::Context] context the context of this Request
    # @return [Response] a Rack Response triplet, or status code
    def route(context)
      actions = actions_allowed(context)
      if actions.include? context.action
        context.config['type'].invoke(actions, context)
      else
        401
      end
    end

    # Fulfill the current request
    # @param [Hash] env the Rack environment
    # @return [Response] a Rack Response triplet, or status code
    def call(env)
      headers = {}
      begin
        context  = Wire::Context.new(self, env)
        response = route(context)
      rescue Exception => e
        $stderr.puts e.message
        $stderr.puts e.backtrace
        $stderr.flush
        response = [500, headers, e.message + "\n" + e.backtrace]
      end
      if response.is_a? Array
        if response[2] and not response[2].is_a? Array
          response[2] = [response[2]]
        end
      else
        if response.is_a? Integer
          response = [response, headers, []]
        else
          response = [200, headers, [response]]
        end
      end
      response
    end

    # Print out a human-readable configuration
    # @return [void]
    def info
      $stderr.puts "Apps:\n"
      @apps.each do |app, config|
        $stderr.puts "\u{2502}"
        $stderr.puts "\u{251c} Name: #{app}"
        if config['auth_handler']
          $stderr.puts "\u{2502}\t\u{251c} Auth:"
          $stderr.puts "\u{2502}\t\u{2502}\t\u{2514} Handler:\t#{config['auth_handler']}"
        end
        if config['auth_read_only']
          $stderr.puts "\u{2502}\t\u{251c} Auth:"
          $stderr.puts "\u{2502}\t\u{2502}\t\u{2514} Read Only:\t#{config['auth_read_only']}"
        end
        if config['type']
          $stderr.puts "\u{2502}\t\u{2514} Type: #{config['type']}"
        end
      end
    end
  end
end
