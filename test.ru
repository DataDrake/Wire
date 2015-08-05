require_relative 'lib/wire'
require 'awesome_print'

use Rack::Session::Cookie, key: 'session', secret: 'super_secret_token'
use Rack::Deflater

closet = Wire::Closet.build do

  app '/login', Login do
    auth :any
  end

  app 'assets', Static do
    auth :any
    local 'css' , 'test/assets/css'
  end
end

run closet