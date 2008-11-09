# performs any setup required.  Downloads prequisite gems needed to run the app.
Shoes.setup do
  gem 'json_pure'
  gem 'metafusion-crypto'
end

require 'json'
require 'twitter'
require 'metafusion/crypto'
