require 'rack'
require_relative 'app'
require_relative 'closet/auth'
require_relative 'closet/context'
require_relative 'closet/resource'
require_relative 'closet/renderer'


module Wire
	# A Closet is a configured Wire Environment
	# @author Bryan T. Meyers
	class Closet
		include Wire::App
		include Wire::Auth
		include Wire::Renderer
		include Wire::Resource

		# Create an empty Closet
		# @return [Wire::Closet] the new closet
		def initialize
			$apps      = {}
			$editors   = {}
			$renderers = {}
			$templates = {}
		end

		# Route a Request to the correct Wire::App
		# @param [Wire::Context] context the context of this Request
		# @return [Response] a Rack Response triplet, or status code
		def route(context)
			actions = actions_allowed(context)
			if actions.include? context.action
				context.type.invoke(actions, context)
			else
				401
			end
		end

		# Fulfill the current request
		# @param [Hash] env the Rack environment
		# @return [Response] a Rack Response triplet, or status code
		def call(env)
			begin
				context  = Wire::Context.new(env)
				response = route(context)
			rescue Exception => e
				$stderr.puts e.message
				$stderr.puts e.backtrace
				response = [500, {}, e.message]
			end
			if response.is_a? Array
				if response[2]
					unless response[2].is_a? Array
						response[2] = [response[2]]
					end
				end
			else
				if response.is_a? Integer
					response = [response, {}, []]
				else
					response = [200, {}, [response]]
				end
			end
			response
		end

		# A factory method for configuring a Closet
		# @param [Proc] block the configuration routine
		# @return [Wire::Closet] the configured Closet
		def self.build(&block)
			closet = Wire::Closet.new
			if ENV['RACK_ENV'].eql? 'development'
				$stderr.puts 'Starting Up Wire...'
				$stderr.puts 'Starting Apps...'
			end
			Docile.dsl_eval(closet, &block)
			if ENV['RACK_ENV'].eql? 'development'
				closet.info
			end
			closet
		end

		# Print out a human-readable configuration
		# @return [void]
		def info
			$stderr.puts "Apps:\n"
			$apps.each do |app, config|
				$stderr.puts "\u{2502}"
				$stderr.puts "\u{251c} Name: #{app}"
				if config[:auth]
					$stderr.puts "\u{2502}\t\u{251c} Auth:"
					if config[:auth][:level] == :app
						$stderr.puts "\u{2502}\t\u{2502}\t\u{251c} Level:\t#{config[:auth][:level]}"
						$stderr.puts "\u{2502}\t\u{2502}\t\u{2514} Handler:\t#{config[:auth][:handler]}"
					else
						$stderr.puts "\u{2502}\t\u{2502}\t\u{2514} Level:\t#{config[:auth][:level]}"
					end
				end
				if config[:type]
					$stderr.puts "\u{2502}\t\u{2514} Type: #{config[:type]}"
				end
			end
		end
	end
end