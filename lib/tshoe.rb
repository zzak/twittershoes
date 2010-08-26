=begin
    TwitterShoes
    tshoe.rb
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
  # GUI (Shoes) part of the application
  class Tshoe < Shoes
    DELETE_SLEEP_DURATION = 0.5
    LIMIT = 140
    STATUS_STACK_HEIGHT = 70
    STATUS_RIGHT_PANE_WIDTH = 50
    TEXT_BOX_WIDTH = 235
    ACCOUNT_WINDOW_WIDTH = 250
    ACCOUNT_WINDOW_HEIGHT = 175
    BACKGROUND = "#2F2F2F"
    DEFAULT_TEXT = "what are you doing?"
    # hash containing all escape characters and their mapped characters
    # keyed by escape sequence
    # value is coresponding character
    ESCAPE_CHAR = {
        '&lt;' => '<',
        '&gt;' => '>'
    }
    Default_png = <<PNGSTART
\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\0000\000\000\0000\004\003\000\000\000\245,\344\264\000\000\000\001sRGB\000\256\316\034\351\000\000\0000PLTE\207cC\207eJ\211iS\212qb\214vn\214~}\220\207\215\217\220\235\224\233\260\227\244\301\233\257\324\237\267\342\241\277\360\242\304\373\236\311\377\245\313\3731j\275\350\000\000\000\001bKGD\000\210\005\035H\000\000\000\tpHYs\000\000\v\023\000\000\v\023\001\000\232\234\030\000\000\000\atIME\a\330\003\034\003\0172\"\337U\003\000\000\001TIDAT8\313c\020\304\001\030F%\bK000`\225`\016\357H\026\300&\221\375\356\335\333\311\214\230\022\032\357V\244\317\371\035\210!!\320w]\200\201u\377f\210\004\243\022\\\232\345\334\004\240l\314\017F\220\004s\347\256\251\214P\t\211?\016@\222\363\215!PB \372\317\236wMP\t\255\237 \222\365n\002PB\370\334d\345\234\347\020-\002\266?A\f\341{\r@\t\311_\n\002\354@\275`\340\367\002,q~\002P\302\372;\243 \363\271\004\210D\034X\253\320~\240\204\200\317SFA\241\365\r\020\t\333\037p\035\002~_A\022\023 \0226`;D\336\001\355\020\360\275\212\244C\353\227\"\220d{\vt\225\200\3157F\240\313\n \022\354o\003\200\244\324kE\220\253\200Ng{\023\000\r\333}\213\030\005\005j\237\203|\316z\267H\320\373\a\324\353\002\271\257\234\030\325\317O\002\205\225@\355\253\316s\213\301\022\300x\020;\177\262s\337KCp \262\256\271\263]QP\331\330\330\330\304PP\300\363\354\333\323I\320\210\022v\026\020\024\210{\367\356\335\373\211@]\246\251\216\360\250\005\231c\321\001\004\211 \363\030\030Q\342\\\200\001\232\nF\363\a\035$\000|\224\234q\3363+s\000\000\000\000IEND\256B`\202
PNGSTART

    url '/', :index
    url '/setup', :setup

    # Index page
    def index
      @data = nil
      @page = 1
      @profile_images = Hash.new
      @twitter_config = TwitterConfig.new
      @state = @twitter_config.state # TODO should store password, should also check if credentials work
      # check if the credentials were loaded properly, if not try a new login password
      if @state.is_a? State and not @state.ok
        debug( "State: #{@state.inspect}" )
        username_password_query
        @state = @twitter_config.state
      else
        debug( "State: #{@state.inspect}" )
        finish_setup
      end
    end

    # tasks to be run after user authenticated
    # gets collection of user favorites and loads page.
    def finish_setup
      @favorites = get_favorites
      refresh
    end

    # queries for username and password if no yaml file is found
    def username_password_query
      username = nil
      password = nil
      password_entry = nil
      username_entry = nil

      stack :margin_top => 10, :margin_left => 5, :margin_right => 5 do
        subtitle( "Account Details" )
        stack :margin_bottom => 5 do
          border black, :strokewidth => 1
          flow :displace_top => 7 do
            para( "Username: " )
            username_entry = edit_line
          end
          flow do
            para( "Password: " )
            password_entry = edit_line :secret => true
          end
        end
        button "Okay" do
          username = username_entry.text
          password = password_entry.text
          @twitter_config = TwitterConfig.new( username, password )
          password = nil
          debug( "State: #{@state.inspect}" )
          finish_setup
        end
      end
    end

    def fetch_data
      @data = @twitter_config.twitter_client.timeline_for( :friends, :id => @twitter_config.user, :page => @page )
    end

    # TODO Setup page...
    def setup
      alert("set me up, please...")
    end

    # creation of a default image
    # no cache here. Image is always (because rarely) created on-time.
    def default_twitter_image
      name = File.join( @twitter_config.cache_dir, 'twitter_image.png' )
      File.open(name, 'wb') do |fout|
        fout.syswrite Default_png
      end
      name
    end

    # downloads profile image and caches them. If file already exists just returns the path.
    def download_profile_image( path )
      key = Base64.encode64( Digest::SHA1.digest( path ) ).gsub( '/', '' ).gsub( '\n', '' ) # can't have /'s or will misinterpret as directories
      file_path = "#{@twitter_config.cache_dir}/#{key.chomp}.jpg"

      if @profile_images[key].nil?
        # TODO use shoes download instead?
        response = Net::HTTP.get_response( URI.parse( path ) )
        if response.is_a? Net::HTTPOK
          File.open( file_path, 'w' ) do |file|
            file.write( response.body )
          end
        end

        @profile_images[key] = file_path
      end

      file_path
    end

    #  twit (id, image, name, screen_name, text, elapsedtime)
    #  this method sets the message to be sent to each message stack
    #  notice the final eval(uation) that packs all the string together.
    def twit(id, i, n, sn, t, e)  
      eval_string = nil

      flow :margin => 5 do
        background "#161616", :radius => 8
        stack :width => 58 do
          image download_profile_image( i ), :margin => 5, :click => "http://twitter.com/#{sn}"
        end
        stack :width => -58, :margin => 5 do
          name = link("#{n} (#{sn})", :click => "http://twitter.com/#{sn}", :underline => false, :stroke => orange)
          elapsed_time = link( Mytime.elapsed_time(e), :font => 'smallfont', :size => 6, :stroke => '#6D6D6D', :underline => false, :click => "http://www.twitter.com/#{sn}/statuses/#{id}")
          del_reply =
            if sn == @twitter_config.user
              link( " x", :underline => false, :stroke => "#732A2A" ) { delete( id ) }
            else
              link('<-', :underline => false, :stroke => '#183616') { @i_say.text = "@#{sn} " }
            end
          favorite =
            if @favorites.include?( id )
              link( ' -', :underline => false, :stroke => yellow ) { remove_favorite( id ) }
            else
              link( ' +', :underline => false, :stroke => yellow ) { add_favorite( id ) }
            end
					eval_string = "para name, ': ', t, \" \", elapsed_time, \" \", del_reply, favorite, :font => 'Arial', :size => 8, :stroke => '#999999'"
          debug eval_string
          eval( eval_string )
        end
      end
      
      eval_string
    end

    # parses the name into a link to that person
    def name_parse( tweet )
      original_tweet = tweet

      match_data = /\B@(\w+)/.match( tweet )
      if match_data
        components = tweet.split( "@#{match_data[1]}" )
        tweet = components.join( "@\", #{generate_link( match_data[1], "http://www.twitter.com/#{match_data[1]}" )}, \"" )
        # remove unnecessary empty quote at end if name is at the end of a message
        if components.last == "\""
          tweet = tweet[0, tweet.length - 4]
        end
      end

#       tweet
      # keep parsing for names until there are no names left.
      if original_tweet == tweet
        tweet
      else
        name_parse( tweet )
      end
    end

    # parse html escape sequences
    def html_escape_parse( tweet )
      ESCAPE_CHAR.each do |sequence, character|
        tweet.gsub!( sequence, character )
      end

      tweet
    end

    # generates string of a link to be eventually eval'd
    def generate_link( text, url = nil )
      if url.nil?
        url = text
      end

      "link('#{text}', :click => '#{url}', :font => 'Arial', :size => 8, :underline => false, :stroke => '#397EAA' )"
    end

    # tweet message link parse and conversion to shoes links with eval(uation).
    # tries to discover http links in messages and prepare them for eval(uation).
    def link_parse( tweet ) 
      tweet.gsub!(/\"/, "'")
      if tweet.include? "http://"
        replacement_string = Array.new

        # check each token for http link, and build the new tweet
        tweet.split(' ') do |token|
          url_regex = /(http:\/\/\S+)/
          # check for the case where url is b/t parenthesis: (http://www.tinyurl.com)
          match_data = /[(]#{url_regex}[)]/.match( token )
          if match_data.nil?
            match_data = /[']#{url_regex}[']/.match( token )
          end

          # if it hasn't matched, check for a regular url
          if match_data.nil?
            match_data = url_regex.match( token )
          end

          # if we found a url, replace it with a link
          if match_data
            extra_tokens = token.split( match_data[1] )
            replaced_string = generate_link( match_data[1] )
            # check for prepending/postpending characters
            if extra_tokens.empty?
              replacement_string.push( replaced_string )
            else
              replacement_string.push( "\"#{extra_tokens[0]}\"" ) if extra_tokens[0] and not extra_tokens[0].empty?
              replacement_string.push( replaced_string )
              replacement_string.push( "\"#{extra_tokens[1]}\"" ) if extra_tokens[1] and not extra_tokens[1].empty?
            end
            # if no url in token
          else
            replacement_string.push( "\"#{token}\"" )
          end
        end

        replacement_string.join( ", " )
      else
      "\"#{tweet}\""
      end
    end

    # alert message for the number of chars left to the tweet message
    def string_alert 
      c = (LIMIT-@i_say.text.length)
      @remaining.style :stroke => "#3276BA"
      c > 10 ? (@remaining.style :stroke => orange) : (@remaining.style :stroke => red) if (c < 21)
      c > 0 ? "#{c.to_s} chars" : "Too Long!"
    end

    # send message and clear the text box and refreshes the page
    def upandaway
      @twitter_config.twitter_client.status( :post, @i_say.text )
      @i_say.text = ''
      refresh
    end

    # Method responsable for parsing each incoming message from the XML answer
    # TODO figure out a way to cache profile images ( use a hash, if nil, d/l ? )
    def get_thread
      if @data != nil
        @data.each do |message|
          twit( message.id, message.user.profile_image_url, message.user.name, message.user.screen_name, name_parse( link_parse( html_escape_parse( message.text ) ) ), message.created_at )
        end
      else
        m1 = 'fetching twitter data... please wait or press '
        m2 = "link('here', :font => 'Arial', :size => 8, :underline => false, :stroke => '#397EAA') { fetch_data; clear; listen }"
        m = "#{m1}, \", #{m2}, \""
        twit("0", default_twitter_image, "TwitterShoes", "twittershoes", m, Time.now.to_s)
      end
    end

    # GUI area definition method. This method draws the incoming messages area, and the message insertion area.
    def listen
      background BACKGROUND
      # text entry
      flow :width => 1.0, :margin_right => gutter, :height => STATUS_STACK_HEIGHT do
        background BACKGROUND
        stack :width => -STATUS_RIGHT_PANE_WIDTH, height => STATUS_STACK_HEIGHT do
          @i_say = edit_box DEFAULT_TEXT, :margin => 5, :width => TEXT_BOX_WIDTH, :height => STATUS_STACK_HEIGHT, :size => 9 do
            @remaining.replace string_alert
            if @i_say.text[-1] == ?\n
              upandaway
            end
          end
        end
        stack :width => STATUS_RIGHT_PANE_WIDTH, height => STATUS_STACK_HEIGHT do
          para( link( " Update ", :size => 8, :font => "Arial", :fill => "#4992E6" , :stroke => "#D5E0ED", :underline => false ) { upandaway } )
          para( link( "<- ", :size => 8, :font => "Arial", :stroke => "#3276BA", :underline => false) { previous_page },
             "  #{@page}  ", 
             link(" ->", :size => 8, :font => "Arial", :stroke => "#3276BA", :underline => false) { next_page }, :top => 15, :size => 7, :font => "Arial", :stroke => "#3276BA", :underline => false)
          @remaining = para "140", " chars", :top => 30, :size => 6, :font => "Arial", :stroke => "#3276BA"
          para( link( " Refresh ", :size => 8, :font => "Arial", :fill => "#4992E6" , :stroke => "#D5E0ED", :underline => false ) { refresh } )
        end
      end

      # displays timeline for friends
      get_thread
    end

    # increments page count and retreives the next page of the timeline
    def next_page
      @page += 1
      refresh
    end

    # decrements page count and retrieves the previous page of the timeline
    def previous_page
      @page -= 1
      @page = 1 if @page < 1
      refresh
    end

    # deletes status message
    def delete( id )
      @twitter_config.twitter_client.status( :delete, id )
      sleep( DELETE_SLEEP_DURATION ) # hack, because for some reason, if you try to refresh immediately, refreshes page too soon.
      refresh
    end

    # adds message to favorites
    def add_favorite( id )
      @twitter_config.twitter_client.favorite( :add, id )
      @favorites = get_favorites
      refresh
    end

    # removes message from favorites
    def remove_favorite( id )
      @twitter_config.twitter_client.favorite( :remove, id )
      @favorites = get_favorites
      refresh
    end

    def get_favorites
      @twitter_config.twitter_client.favorites.collect {|favorite| favorite.id }
    end
    # refresh messages
    def refresh
      self.clear
      fetch_data
      listen
    end
  end
end

Shoes.app :title => "Twitter needs Shoes", :width => 300, :height => 550, :radius => 12, :resizable => true
