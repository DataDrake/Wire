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

require 'base64'
require 'tilt'
require_relative 'repo/svn'

# Repo is a Wire::App for accessing versioned content
# @author Bryan T. Meyers
module Repo

  # Configure repo with listing template
  # @param [Hash] conf the raw configuration
  # @return [Hash] post-processed configuration
  def configure(conf)
    conf['listing'] = Tilt.new(conf['listing'], 1, { ugly: true })
    conf
  end

  # Read all of the configs in './configs/repos'
  # @return [void]
  def self.read_configs
    Wire::Config.read_config_dir('config/repos', nil)
  end

  # Create a new file
  # @param [Hash] context the context for this request
  # @return [Response] status code
  def do_create(context)
    conf    = context.closet.repos[context.config['repo']]
    repo    = context.resource
    content = context.json
    id      = context.id
    if content[:file]
      file = content[:file][:content].match(/base64,(.*)/)[1]
      file = Base64.decode64(file)
      if context.query[:type]
        mime = context.query[:type]
      else
        mime = content[:file][:mime]
      end
      do_create_file(conf, repo, id, file, content[:message], mime, context.user)
    else
      do_create_file(conf, repo, id, URI.unescape(content[:updated]), content[:message], context.query[:type], context.user)
    end
  end

  # Get the a root directory listing
  # @param [Hash] context the context for this request
  # @return [Response] the listing, or status code
  def do_read_all(context)
    conf = context.closet.repos[context.config['repo']]
    mime = 'text/html'
    list = do_read_listing(conf, context.resource)
    if list == 404
      return 404
    end
    template = context.config['listing']
    list     = template.render(self,
                               list:     list,
                               resource: context.resource,
                               id:       '',
                               referrer: context.referer)
    headers  = { 'Content-Type'  => mime,
                 'Cache-Control' => 'public',
                 'Expires'       => "#{(Time.now + 1000).utc}" }
    [200, headers, [list]]
  end

  # Get the a single file or directory listing
  # @param [Hash] context the context for this request
  # @return [Response] the file, listing, or status code
  def do_read(context)
    conf     = context.closet.repos[context.config['repo']]
    referrer = context.referer
    repo     = context.resource
    id       = context.id
    rev      = context.query[:rev]
    info     = do_read_info(conf, repo, id, rev)
    if info == 404
      return 404
    end
    type = info[:@kind]
    if type.eql? 'dir'
      mime     = 'text/html'
      list     = do_read_listing(conf, repo, id)
      template = context.config['listing']
      body     = template.render(self,
                                 list:     list,
                                 resource: repo,
                                 id:       id,
                                 referrer: referrer)
    else
      body = do_read_file(conf, repo, id, rev)
      if body == 500
        return body
      end
      mime = do_read_mime(conf, repo, id, rev)
    end
    headers = { 'Content-Type'  => mime,
                'Cache-Control' => 'public',
                'Expires'       => "#{(Time.now + 1000).utc}" }
    [200, headers, [body]]
  end

  # Update the a single file
  # @param [Hash] context the context for this request
  # @return [Response] status code
  def do_update(context)
    conf    = context.closet.repos[context.config['repo']]
    repo    = context.resource
    content = context.json
    id      = context.id
    if content[:file]
      file = content[:file][:content].match(/base64,(.*)/)[1]
      file = Base64.decode64(file)
      if context.query[:type]
        mime = context.query[:type]
      else
        mime = content[:file][:mime]
      end
      do_update_file(conf, repo, id, file, content[:message], mime, context.user)
    else
      do_update_file(conf, repo, id, URI.unescape(content[:updated]), content[:message], context.query[:type], context.user)
    end
  end

  # Proxy method used when routing
  # @param [Array] actions the allowed actions for this URI
  # @param [Hash] context the context for this request
  # @return [Response] a Rack Response triplet, or status code
  def invoke(actions, context)
    return 404 unless context.resource
    case context.action
      when :create
        do_create(context)
      when :read
        if context.id
          do_read(context)
        else
          do_read_all(context)
        end
      when :update
        do_update(context)
      else
        403
    end
  end
end
