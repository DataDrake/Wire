require 'awesome_print'
require_relative '../wire'

module Static

	module Controller
		extend Wire::App
    extend Wire::Resource

    def self.local( resource, path )
      $currentApp[:resources][resource] = {local: path}
    end

		def self.readAll( context , request , response , actions )
			context[:sinatra].pass unless (context[:resource] != nil )
				path = context[:resource][:local]
				if( path != nil ) then
					context[:sinatra].pass unless File.exists?(path)
					if( File.directory?( path ) ) then
						Dir.entries( path ).sort.to_str
					else
						401
					end
				else
					404
				end
		end

		def self.read( id , context , request , response , actions )
      context[:sinatra].pass unless (context[:resource] != nil )
			path = context[:resource][:local]
			if( path != nil ) then
				ext_path = File.join( path , id )
				context[:sinatra].pass unless File.exists?(ext_path)
					if( File.directory?( ext_path ) ) then
						"#{ap Dir.entries( ext_path ).sort}"
					else
						if( ext_path.end_with?( '.wiki' ) || ext_path.end_with?( '.mediawiki' ) ) then
							mime = 'text/wiki'
						else
							mime = `mimetype --brief #{ext_path}`
						end
						response.headers['Content-Type'] = mime
            response.headers['Cache-Control'] = 'public'
            response.headers['Expires'] = "#{(Time.now + 30000000).utc}"
						response.body = File.read( ext_path )
					end
			else
				404
		  end
	  end
  end
end
