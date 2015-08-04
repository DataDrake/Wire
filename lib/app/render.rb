require 'nokogiri'
require 'wiki-this'
require 'redcarpet'
require 'RedCloth'
require 'rest_client'
require 'awesome_print'
require 'docile'
require 'tilt'
require 'json'
require 'tilt/haml'
require_relative '../wire'
require_relative 'render/document'
require_relative 'render/editor'
require_relative 'render/instant'
require_relative 'render/page'
require_relative 'render/partial'
require_relative 'render/style'

$markdown = Redcarpet::Markdown.new( Redcarpet::Render::HTML , tables: true )

module Wire

  module Renderer

    def renderer( klass , &block)
      $currentRenderer = klass
      $currentEditor = nil
      Docile.dsl_eval( self , &block )
    end

    def mime( mime )
      if $currentRenderer != nil then
        $config[:renderers][mime] = $currentRenderer
        $config[:templates][$currentRenderer] = $currentTemplate
      end
      if $currentEditor != nil then
        $config[:editors][mime] = $currentEditor
      end
    end

    def partial( template )
      $currentTemplate = Tilt.new( template , 1 , {ugly:true})
    end

    def editor( editor , &block)
      $currentEditor = Tilt.new( editor , 1 , {ugly:true})
      $currentRenderer = nil
      Docile.dsl_eval( self , &block )
    end

  end

  class Closet
    extend Wire::Renderer
  end
end

module Render
  extend Wire::App
  extend Wire::Resource

  def remote( hostname , uri)
    $currentApp[:remote_host] = hostname
    $currentApp[:remote_uri] = uri
  end

  def template( path , &block)
    $currentApp[:template] = { path: path.nil? ? nil : Tilt.new( path , 1 , {ugly: true}) , sources: {} }
    if( block != nil ) then
      Docile.dsl_eval( self  , &block )
    end
  end

  def use_layout
    $currentApp[:template][:use_layout] = true
  end

  def source( key, uri , &block )
    $currentApp[:template][:sources][key] = { uri:uri, key: nil }
    $currentSource = $currentApp[:template][:sources][key]

    if( block != nil ) then
      Docile.dsl_eval( self , &block )
    end
  end

  def key( type )
    $currentSource[:key] = type
  end

  def single( template )
    partial = Tilt.new( template , 1 , {ugly:true})
    $currentResource[:single] = partial
  end

  def multiple( template )
    partial = Tilt.new( template , 1 , {ugly:true})
    $currentResource[:multiple] = partial
  end

  def all( template )
    multiple( template )
    single( template )
  end

  def forward( id , method , context , request )
    host = context[:app][:remote_host]
    path = context[:app][:remote_uri]
    resource = context[:resource_name]
    if request.env['HTTP_REFERRER'].nil? then
      referrer = request.url
    else
      referrer = request.env['HTTP_REFERRER']
    end
    query = context[:query]
    q = '?'
    query.each do |k,v|
      unless v.is_a? Hash or v.is_a? Array or k.eql? 'resource' or k.eql? 'app'
        q = "#{q}#{k}=#{v}&"
      end
    end
    case(method)
      when :create
        puts "POST: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
        RestClient.post "http://#{host}/#{path}/#{resource}#{q}" , request.body
      when :update
        puts "PUT: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.put "http://#{host}/#{path}/#{resource}/#{id}#{q}" , request.body
      when :readAll
        ##puts "GET: Forward Request to https://#{host}/#{path}/#{resource}#{q}"
        RestClient.get "http://#{host}/#{path}/#{resource}#{q}" , referrer: referrer
      when :read
        ##puts "GET: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.get "http://#{host}/#{path}/#{resource}/#{id}#{q}" , referrer: referrer
      when :delete
        puts "DELETE: Forward Request to https://#{host}/#{path}/#{resource}/#{id}#{q}"
        RestClient.delete "http://#{host}/#{path}/#{resource}/#{id}#{q}"
      else
        401
    end
  end
end
