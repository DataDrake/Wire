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

require 'awesome_print'
require 'base64'
require_relative '../wire'
require_relative 'repo/svn'

# Repo is a Wire::App for accessing versioned content
# @author Bryan T. Meyers
module Repo

	# Select the location of the repositories
	# @param [Symbol] path location of the repositories
	# @return [void]
	def repos(path)
		$current_app[:repos_path] = path
	end

	# Select the render template for file listings
	# @param [Symbol] path location of the Tilt compatible template
	# @return [void]
	def listing(path)
		$current_app[:template] = Tilt.new(path, 1, { ugly: true })
	end

	# Select the sub-directory for web-serveable content
	# @param [Symbol] path the sub-directory path
	# @return [void]
	def web_folder(path)
		$current_app[:web] = path
	end

	# Create a new Repo
	# @param [Hash] context the context for this request
	# @return [Response] status code
	def do_create(context)
		path     = context.app[:repos_path]
		resource = context.uri[2]
		if path
			if Dir.exist?("#{path}/#{resource}")
				401
			else
				do_create_file(path, resource)
			end
		else
			400
		end
	end

	# Get the a root directory listing
	# @param [Hash] context the context for this request
	# @return [Response] the listing, or status code
	def do_read_all(context)
		resource = context.uri[2]
		referrer = context.referer
		repos    = context.app[:repos_path]
		web      = context.app[:web]
		mime     = 'text/html'
		list     = do_read_listing(web, repos, resource)
		if list == 404
			return 404
		end
		template                 = context.app[:template]
		list                     = template.render(self, list: list, resource: resource, id: '', referrer: referrer)
		headers                  = {}
		headers['Content-Type']  = mime
		headers['Cache-Control'] = 'public'
		headers['Expires']       = "#{(Time.now + 1000).utc}"
		[200, headers, [list]]
	end

	# Get the a single file or directory listing
	# @param [Hash] context the context for this request
	# @return [Response] the file, listing, or status code
	def do_read(context)
		path     = context.uri[2]
		referrer = context.referer
		repos    = context.app[:repos_path]
		web      = context.app[:web]
		rev      = context.query[:rev]
		id       = context.uri[3...context.uri.length].join('/')
		info     = do_read_info(rev, web, repos, path, id)
		if info == 404
			return 404
		end
		type = info[:@kind]
		if type.eql? 'dir'
			mime     = 'text/html'
			list     = do_read_listing(web, repos, path, id)
			template = context.app[:template]
			body     = template.render(self, list: list, resource: path, id: id, referrer: referrer)
		else
			body = do_read_file(rev, web, repos, path, id)
			if body == 500
				return body
			end
			mime = do_read_mime(rev, web, repos, path, id)
		end
		headers                  = {}
		headers['Content-Type']  = mime
		headers['Cache-Control'] = 'public'
		headers['Expires']       = "#{(Time.now + 1000).utc}"
		[200, headers, [body]]
	end

	# Update the a single file
	# @param [Hash] context the context for this request
	# @return [Response] status code
	def do_update(context)
		path    = context.uri[2]
		repos   = context.app[:repos_path]
		web     = context.app[:web]
		content = context.json
		id      = context.uri[3...context.uri.length].join('/')
		if content[:file]
			file = content[:file][:content].match(/base64,(.*)/)[1]
			file = Base64.decode64(file)
			if context.query[:type]
				mime = context.query[:type]
			else
				mime = content[:file][:mime]
			end
			do_update_file(web, repos, path, id, file, content[:message], mime, context.user)
		else
			do_update_file(web, repos, path, id, URI.unescape(content[:updated]), content[:message], context.query[:type], context.user)
		end
	end

	# Proxy method used when routing
	# @param [Array] actions the allowed actions for this URI
	# @param [Hash] context the context for this request
	# @return [Response] a Rack Response triplet, or status code
	def invoke(actions, context)
		return 404 unless context.uri[2]
		case context.action
			when :create
				do_create(context)
			when :read
				if context.uri[3]
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
