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

require 'lmdb'

module Cache
  module Memory

    $cache = {}

    def self.update_cached(context)
      uri = context.uri.join('/')
      all = context.uri[0..2].join('/')
      env = $cache[context.config['remote']]
      db  = env.database
      if context.id
        result = context.forward(:read)
      else
        result = context.forward(:readAll)
      end
      if result[0] == 200
        env.transaction do
          if context.action == :delete
            if db[uri]
              db.delete(uri)
            end
          else
            db[uri] = result[2]
          end
        end
      end
      if [:create, :update, :delete].include? context.action
        thing = context.forward(:readAll)
        if thing[0] == 200
          env.transaction do
            db[all] = thing[2]
          end
        end
      end
      result
    end

    def self.get_cached(context)
      uri    = context.uri.join('/')
      env    = $cache[context.config['remote']]
      db     = env.database
      result = nil
      env.transaction do
        result = db[uri]
      end
      result
    end

    def self.purge_cached(context)
      uri    = context.uri.join('/')
      env    = $cache[context.config['remote']]
      db     = env.database
      result = 200
      env.transaction do
        begin
          db.delete(uri)
        rescue
          result = 404
        end
      end
      result
    end

    def self.invoke(actions, context)

      # Create Cache if not set up
      unless $cache[context.config['remote']]
        $cache[context.config['remote']] = LMDB.new("/tmp/cache/#{context.config['remote']}", mapsize: 2**30)
      end

      case context.action
        when :create, :update, :delete
          result = context.forward(context.action)
          update_cached(context) # write aware
          result
        when :read, :readAll
          cached = get_cached(context)
          unless cached
            cached = update_cached(context)
          end
          cached
        else
          403
      end
    end
  end
end
