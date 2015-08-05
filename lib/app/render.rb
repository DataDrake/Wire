require 'nokogiri'
require 'wiki-this'
require 'rest_client'
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

module Render
  include Wire::Resource

  def remote( hostname , uri)
    $current_app[:remote_host] = hostname
    $current_app[:remote_uri] = uri
  end

  def template( path , &block)
    $current_app[:template] = { path: path.nil? ? nil : Tilt.new( path , 1 , {ugly: true}) , sources: {} }
    if block
      Docile.dsl_eval( self  , &block )
    end
  end

  def use_layout
    $current_app[:template][:use_layout] = true
  end

  def source( key, uri , &block )
    $current_app[:template][:sources][key] = { uri:uri, key: nil }
    $current_source = $current_app[:template][:sources][key]

    if block
      Docile.dsl_eval( self , &block )
    end
  end

  def key( type )
    $current_source[:key] = type
  end

  def single( template )
    partial = Tilt.new( template , 1 , {ugly:true})
    $current_resource[:single] = partial
  end

  def multiple( template )
    partial = Tilt.new( template , 1 , {ugly:true})
    $current_resource[:multiple] = partial
  end

  def all( template )
    multiple( template )
    single( template )
  end

  def forward( method , context )
    host = context[:app][:remote_host]
    path = context[:app][:remote_uri]
    resource = context[:resource_name]
    if context[:request].env['HTTP_REFERRER']
      referrer = context[:request].env['HTTP_REFERRER']
    else
      referrer = context[:request].url
    end
    query = context[:query]
    q = '?'
    query.each do |k,v|
      unless v.is_a? Hash or v.is_a? Array or k.eql? 'resource' or k.eql? 'app'
        q = "#{q}#{k}=#{v}&"
      end
    end
    id = context[:uri][3...context[:uri].length].join('/')
    request = context[:request]
    case(method)
      when :create
        puts "POST: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
        RestClient.post "http://#{host}/#{path}/#{resource}#{q}" , request.body
      when :update
        puts "PUT: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.put "http://#{host}/#{path}/#{resource}/#{id}#{q}" , request.body
      when :readAll
        puts "GET: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
        RestClient.get "http://#{host}/#{path}/#{resource}#{q}" , referrer: referrer
      when :read
        puts "GET: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.get "http://#{host}/#{path}/#{resource}/#{id}#{q}" , referrer: referrer
      when :delete
        puts "DELETE: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.delete "http://#{host}/#{path}/#{resource}/#{id}#{q}"
      else
        401
    end
  end
end
