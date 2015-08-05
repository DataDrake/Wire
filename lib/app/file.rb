require 'awesome_print'
require_relative '../wire'

module Static

	module Controller
		extend Wire::App
    extend Wire::Resource

    def self.local( resource, path )
      $currentApp[:resources][resource] = {local: path}
    end

		def self.do_read_all( actions , context )
			  return 404 unless context[:resource]
				path = context[:resource][:local]
				if path
					return 404 unless File.exists?(path)
					if File.directory? path
						Dir.entries( path ).sort.to_s
					else
						401
					end
				else
					404
				end
		end

		def self.do_read( actions , context )
      return 404 unless context[:resource]
			path = context[:resource][:local]
      id = context[:uri][3..context[:uri].length].join('/')
      ap id
			if path
				ext_path = File.join( path , id )
        ap ext_path
				return 404 unless File.exists?(ext_path)
					if File.directory?( ext_path )
						"#{ap Dir.entries( ext_path ).sort}"
					else
						if ext_path.end_with?( '.wiki' ) || ext_path.end_with?( '.mediawiki' )
							mime = 'text/wiki'
						else
							mime = `mimetype --brief #{ext_path}`
            end
            headers = {}
						headers['Content-Type'] = mime
            headers['Cache-Control'] = 'public'
            headers['Expires'] = "#{(Time.now + 30000000).utc}"
						body = File.read( ext_path )
            [200, headers, body]
					end
			else
				404
		  end
    end

    def self.invoke( actions, context )
      case context[:action]
        when :read
          if context[:uri][3]
            do_read( actions , context )
          else
            do_read_all( actions , context )
          end
        else
          403
      end
    end
  end
end
