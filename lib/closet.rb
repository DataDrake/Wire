require 'rack'
require_relative 'app'
require_relative 'closet/auth'
require_relative 'closet/context'
require_relative 'closet/resource'
require_relative 'closet/renderer'


module Wire
  class Closet
    include Wire::App
    include Wire::Auth
    include Wire::Context
    include Wire::Renderer
    include Wire::Resource

    def initialize
      @apps = {}
      @editors = {}
      @renderers = {}
      @templates =  {}
    end

    def route( context )
      if context[:failure]
        context[:message]
      else
        actions = actions_allowed( context )
        if actions.include? context[:action]
          context[:type].invoke( actions , context )
        else
          401
        end
      end
    end

    def call(env)
      context = prepare( env )
      response = route( context )
      if response.is_a? Array
        if response[2]
          unless response[2].is_a? Array
            response[2] = [response[2]]
          end
        end
      else
        if response.is_a? Integer
          response = [response,{}, []]
        else
          response = [200, {}, [response]]
        end
      end
      ap response
      response
    end

    def self.build( &block )
      closet = Wire::Closet.new
      puts 'Starting Up Wire...'
      puts 'Starting Apps...'
      Docile.dsl_eval( closet , &block )
      closet.info
      closet
    end

    def info
      puts "Apps:\n"
      @apps.each do |app, config|
        puts "\u{2502}"
        puts "\u{251c} Name: #{app}"
        if config[:auth]
          puts "\u{2502}\t\u{251c} Auth:"
          if config[:auth][:level] == :app
            puts "\u{2502}\t\u{2502}\t\u{251c} Level:\t#{config[:auth][:level]}"
            puts "\u{2502}\t\u{2502}\t\u{2514} Handler:\t#{config[:auth][:handler]}"
          else
            puts "\u{2502}\t\u{2502}\t\u{2514} Level:\t#{config[:auth][:level]}"
          end
        end
        if config[:type]
          puts "\u{2502}\t\u{2514} Type: #{config[:type]}"
        end
      end
    end
  end
end