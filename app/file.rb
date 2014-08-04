require_relative '../wire'

class File

	class Resource
		include Wire::Resource

		def enableCreate
			Web.instance.sinatra.get(@uri) do
				"This Just Happened"
			end

		end

		def enableRead
                        Web.instance.sinatra.get(@uri) do
                                "This Just Happened"
                        end
		end
	end

	class App
		include Wire::App

		def builder
			@type = 'File'
			File::Resource
		end
	end

end
