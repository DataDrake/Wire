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

require 'awesome_print'

# Static is a Wire::App for serving read-only, static files
# @author Bryan T. Meyers
module Static

  # Get a file listing for this folder
  # @param [Hash] context the context for this request
  # @return [Response] a listing, or status code
  def self.do_read_all(context)
    path = context.config['path']
    if path and File.exists?(path)
      if File.directory? path
        Dir.entries(path).sort.to_s
      else
        403
      end
    else
      404
    end
  end

  # Get a file from this folder
  # @param [Hash] context the context for this request
  # @return [Response] a file, listing, or status code
  def self.do_read(context)
    path = context.config['path']
    if path
      ext_path = File.join(path, context.resource, context.id)
      return 404 unless File.exists?(ext_path)
      if File.directory?(ext_path)
        "#{ap Dir.entries(ext_path).sort}"
      else
        if ext_path.end_with?('.wiki') || ext_path.end_with?('.mediawiki')
          mime = 'text/wiki'
        else
          mime = `mimetype --brief #{ext_path}`
        end
        mime.strip!
        headers                  = {}
        headers['Content-Type']  = mime
        headers['Cache-Control'] = 'public'
        headers['Expires']       = "#{(Time.now + 30000000).utc}"
        body                     = File.read(ext_path)
        [200, headers, body]
      end
    else
      404
    end
  end

  # Proxy method used when routing
  # @param [Array] actions the allowed actions for this URI
  # @param [Hash] context the context for this request
  # @return [Response] a Rack Response triplet, or status code
  def self.invoke(actions, context)
    return 404 unless context.resource
    case context.action
      when :read
        if context.id
          do_read(context)
        else
          do_read_all(context)
        end
      else
        403
    end
  end
end
