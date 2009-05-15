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

module TwitterShoes
  # Time representation for Twitter
  class Mytime < Time

    # time representation twitter_like, using: ago's
    def self.elapsed_time(e) 
      et = now - e
      case et
      when 1..60
        "#{et.to_i} secs ago"
      when 60..120
        "#{(et/60).to_i} min ago"
      when 120..3600
        "#{(et/60).to_i} mins ago"
      when 3600..7200
        "#{(et/60/60).to_i} hour ago"
      when 7200..86400
        "#{(et/60/60).to_i} hours ago"
      when 86400..172800
        "#{(et/60/60).to_i} day ago"
      else
        "#{(et/60/60/60).to_i} days ago"
      end
    end
  end
end
