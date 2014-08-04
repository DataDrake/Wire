require_relative '../wire'

class Wire
	module App
		def dav_host( host )
			$config[@currentURI][:dav_host] = host
		end
	end
end


class DAV

	class Resource
		include Wire::Resource

		def create

		end

		def readAll

		end

		def read

		end

		def update

		end

		def delete

		end
	end

	class App
		include Wire::App

		def resource
			File::Resource
		end
	end

end
