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

require File.expand_path( File.join( File.dirname(__FILE__), '..', 'twittershoes' ) )

# Represents the current state of the application
module TwitterShoes
  class State < Struct.new( :ok, :message )
  end
end
