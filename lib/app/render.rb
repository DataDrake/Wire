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

	CONVERT = {
			create: :post,
			read: :get,
			readAll: :get,
			update: :put,
			delete: :delete
	}

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
		verb = CONVERT[method]
		uri = "http://#{host}/#{path}/#{resource}"
		uri += id if [:update,:get,:delete].include?( method )
		uri += q
		body = [:create,:update].include?(method) ? context.body : nil
		$stderr.puts "#{verb.upcase}: Forward Request to #{uri}"
		RL.request verb, uri, headers, body
	end
end
