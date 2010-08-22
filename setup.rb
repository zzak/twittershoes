=begin
    TwitterShoes
    twittershoes.rb
    ruby script created to be a Twitter (http://www.twitter.com) client,
    that uses Shoes.rb to be run on various platforms (Linux, MacOSX, Windows).
    Copyright (C) 2007, 2008 Pedro Mg <http://blog.tquadrado.com>
    Copyright (C) 2008 Terence Lee <hone02@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

# performs any setup required.  Downloads prequisite gems needed to run the app.
#Shoes.setup do
#  gem 'json_pure'
#  gem 'metafusion-crypto'
#  gem 'twitter4r'
#end

#require 'metafusion/crypto'

# Need to define for lib twitter
# def require_local( suffix )
#   require File.expand_path( File.join( File.dirname( __FILE__ ), suffix ) )
# end

require_local 'lib/twitter'
