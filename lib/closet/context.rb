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

require 'json'
require 'rest-less'

module Wire
  # Context is a class containing information related to the current request
  # @author Bryan T. Meyers

  class Context
    #@!attribute [r] action
    #		@return [Symbol] the action
    #@!attribute [r] app
    #		@return [Hash] the name of the Wire::App
    #@!attribute [r] body
    #		@return [String] the unparsed body
    #@!attribute [r] config
    #		@return [Hash] the Wire::App configuration
    #@!attribute [r] json
    #		@return [Hash] the JSON parsed body
    #@!attribute [r] query
    #		@return [Hash] the parsed query string
    #@!attribute [r] query_string
    #		@return [String] the raw query string
    #@!attribute [r] rack_env
    #		@return [Hash] the raw Rack environment
    #@!attribute [r] referer
    #		@return [Array] the referer URI
    #@!attribute [r] resource
    #		@return [Symbol] the name of the resource
    #@!attribute [r] uri
    #		@return [Array] the complete URI
    #@!attribute [r] user
    #		@return [String] the REMOTE_USER
    #@!attribute [r] verb
    #		@return [Symbol] the HTTP verb

    attr_reader :action, :app, :body, :closet, :config, :id,
                :json, :query, :query_string, :rack_env,
                :referer, :resource, :uri, :user, :verb
    attr_writer :id, :referer, :resource, :uri

    # Maps HTTP verbs to actions
    HTTP_ACTIONS = {
        'GET':    :read,
        'HEAD':   :read,
        'POST':   :create,
        'PUT':    :update,
        'DELETE': :delete
    }

    # Maps HTTP verbs to Symbols
    HTTP_VERBS   = {
        'GET':    :get,
        'HEAD':   :head,
        'POST':   :post,
        'PUT':    :put,
        'DELETE': :delete
    }

    # Add user info to session
    # @param [Hash] env the Rack environment
    # @return [Hash] the updated environment
    def update_session(env)
      user = env['HTTP_REMOTE_USER']
      unless user.nil? or user.empty? or user.eql? 'nobody' or user.eql? '(null)'
        env['rack.session']['user'] = user
      end
      env['REMOTE_USER'] = env['rack.session']['user'] ? env['rack.session']['user'] : nil
      env
    end

    # Builds a new Context
    # @param [Closet] closet the Wire::Closet
    # @param [Hash] env the Rack environment
    # @return [Context] a new Context
    def initialize(closet, env)
      @closet   = closet
      @rack_env = update_session(env)
      @user     = env['rack.session']['user']
      @verb     = HTTP_VERBS[env['REQUEST_METHOD'].to_sym]
      @action   = HTTP_ACTIONS[env['REQUEST_METHOD'].to_sym]
      @uri      = env['REQUEST_URI'].split('?')[0].split('/')
      if env['HTTP_REFERER']
        @referer = env['HTTP_REFERER'].split('/')
      else
        @referer = ['http:', '', env['HTTP_HOST']].concat(@uri[1...@uri.length])
      end
      @config = @closet.apps[@uri[1]]
      if @config
        @app      = @uri[1]
        @resource = @uri.length >= 3 ? URI.unescape(@uri[2]) : nil
        @id       = @uri.length > 3 ? URI.unescape(@uri[3...@uri.length].join('/')) : nil
      else
        throw Exception.new("App: #{@uri[1]} is Undefined")
      end
      @query = {}
      if env['QUERY_STRING']
        env['QUERY_STRING'].split('&').each do |q|
          param                   = q.split('=')
          @query[param[0].to_sym] = param[1]
        end
      end
      @query_string = env['QUERY_STRING'] ? env['QUERY_STRING'] : ""
      if env['rack.input']
        @body = env['rack.input'].read
        begin
          @json = JSON.parse_clean(@body)
        rescue JSON::ParserError
          if closet.mode.eql? 'development'
            $stderr.puts 'Warning: Failed to parse body as JSON'
          end
        end
      end
    end

    CONVERT = {
        create:  :post,
        read:    :get,
        readAll: :get,
        update:  :put,
        delete:  :delete
    }

    # Proxy method used when forwarding requests
    # @param [Symbol] method the action to use when forwarding
    # @return [Response] a Rack Response triplet, or status code
    def forward(method)
      headers = { referer:     @referer.join('/'),
                  remote_user: @user }
      verb    = CONVERT[method]
      uri     = "http://#{@config['remote']}/#{@resource}"
      if [:update, :read, :delete].include?(method)
        uri += "/#{@id}"
      end
      uri  += '?' + @query_string
      body = [:create, :update].include?(method) ? @body : nil
      $stderr.puts "#{verb.upcase}: Forward Request to #{uri}"
      RL.request verb, URI.escape(uri), headers, body
    end
  end
end
