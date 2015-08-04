require 'rack'
require_relative 'app'
require_relative 'auth'
require_relative 'context'
require_relative 'resource'


module Wire
  class Closet
    extend Wire::App
    extend Wire::Auth
    extend Wire::Context
    extend Wire::Resource

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
        actions = actionsAllowed?( context )
        if actions.include? context[:action]
          context[:controller].invoke( actions , context )
        else
          401
        end
      end
    end

    def call(env)
      context = prepare( env )
      route( context )
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