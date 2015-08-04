require_relative 'lib/wire'

use Rack::Session::Cookie, key: 'session', secret: 'super_secret_token'
use Rack::Deflater

closet = Wire::Closet.build do

end

run closet