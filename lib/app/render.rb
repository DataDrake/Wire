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

require 'nokogiri'
require 'awesome_print'
require 'rest-less'
require 'docile'
require 'tilt'
require 'json'
require_relative '../wire'
require_relative 'render/document'
require_relative 'render/editor'
require_relative 'render/error'
require_relative 'render/instant'
require_relative 'render/page'
require_relative 'render/partial'
require_relative 'render/style'

# Render is an Abstract Wire::App for transforming content
# @author Bryan T. Meyers
module Render

  CONVERT = {
      create:  :post,
      read:    :get,
      readAll: :get,
      update:  :put,
      delete:  :delete
  }

  # Proxy method used when forwarding requests
  # @param [Symbol] method the action to use when forwarding
  # @param [Hash] context the context for this request
  # @return [Response] a Rack Response triplet, or status code
  def forward(method, context)
    headers = { referer:     context.referer.join('/'),
                remote_user: context.user }
    verb    = CONVERT[method]
    uri     = "http://#{context.app['remote']}/#{context.uri[2]}"
    if [:update, :read, :delete].include?(method)
      uri += "/#{context.uri[3...context.uri.length].join('/')}"
    end
    uri  += '?' + context.query_string
    body = [:create, :update].include?(method) ? context.body : nil
    $stderr.puts "#{verb.upcase}: Forward Request to #{uri}"
    RL.request verb, uri, headers, body
  end
end
