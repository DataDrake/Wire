require 'nokogiri'
require 'rest-client'
require 'awesome_print'
require 'docile'
require 'tilt'
require 'json'
require_relative '../wire'
require_relative 'render/document'
require_relative 'render/editor'
require_relative 'render/instant'
require_relative 'render/page'
require_relative 'render/partial'
require_relative 'render/style'

# Render is an Abstract Wire::App for transforming content
# @author Bryan T. Meyers
module Render
	include Wire::Resource

	# Setup the remote connection for content
	# @param [String] hostname http hostname and port of remote
	# @param [String] uri the base URI for content on the remote
	# @return [void]
	def remote(hostname, uri)
		$current_app[:remote_host] = hostname
		$current_app[:remote_uri]  = uri
	end

	# Setup the template for rendering
	# @param [String] path location of the template
	# @param [Proc] block block to execute for setting up template
	# @return [void]
	def template(path, &block)
		$current_app[:template] = { path: path.nil? ? nil : Tilt.new(path, 1, { ugly: true }), sources: {} }
		if block
			Docile.dsl_eval(self, &block)
		end
	end

	# Enable the use of an outer layout, for the current template
	def use_layout
		$current_app[:template][:use_layout] = true
	end

	# Setup the source for additional template information
	# @param [Symbol] key the type of key for this source
	# @param [String] uri the path for a remote source
	# @param [Proc] block block to execute for setting up source
	# @return [void]
	def source(key, uri, &block)
		$current_app[:template][:sources][key] = { uri: uri, key: nil }
		$current_source                        = $current_app[:template][:sources][key]
		if block
			Docile.dsl_eval(self, &block)
		end
	end

	# Setup the key for additional source information
	# @param [Symbol] type the type of key for this source
	# @return [void]
	def key(type)
		$current_source[:key] = type
	end

	# Setup the template for rendering single items
	# @param [String] template the path to the template
	# @return [void]
	def single(template)
		partial                    = Tilt.new(template, 1, { ugly: true })
		$current_resource[:single] = partial
	end

	# Setup the template for rendering multiple items
	# @param [String] template the path to the template
	# @return [void]
	def multiple(template)
		partial                      = Tilt.new(template, 1, { ugly: true })
		$current_resource[:multiple] = partial
	end

	# Setup the template for rendering one or more items
	# @param [String] template the path to the template
	# @return [void]
	def all(template)
		multiple(template)
		single(template)
	end

	# Proxy method used when forwarding requests
	# @param [Symbol] method the action to use when forwarding
	# @param [Hash] context the context for this request
	# @return [Response] a Rack Response triplet, or status code
	def forward(method, context)
		host     = context.app[:remote_host]
		path     = context.app[:remote_uri]
		resource = context.uri[2]
		referer = context.referer.join('/')
		q  = '?' + context.query_string
		id = context.uri[3...context.uri.length].join('/')
		headers = {referer: referer, remote_user: context.user}
		case (method)
			when :create
				$stderr.puts "POST: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
				RestClient.post "http://#{host}/#{path}/#{resource}#{q}", context.body, headers
			when :update
				$stderr.puts "PUT: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
				RestClient.put "http://#{host}/#{path}/#{resource}/#{id}#{q}", context.body , headers
			when :readAll
				$stderr.puts "GET: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
				RestClient.get "http://#{host}/#{path}/#{resource}#{q}", headers
			when :read
				$stderr.puts "GET: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
				RestClient.get "http://#{host}/#{path}/#{resource}/#{id}#{q}", headers
			when :delete
				$stderr.puts "DELETE: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
				RestClient.delete "http://#{host}/#{path}/#{resource}/#{id}#{q}" , headers
			else
				401
		end
	end
end
