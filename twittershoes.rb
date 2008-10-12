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

# TODO use line 183 to insert your Twitter credentials in this testing version
# TODO this was refactored and is very much a work in progress. wiped out all the threads. 
# TODO needs testing on newer version of Shoes.rb
# TODO redo the threaded system - test
# TODO create Setup page - test
# TODO there is at least one case where link parse fails
# TODO page #'s back and forward
=end

Default_png = <<PNGSTART
\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\0000\000\000\0000\004\003\000\000\000\245,\344\264\000\000\000\001sRGB\000\256\316\034\351\000\000\0000PLTE\207cC\207eJ\211iS\212qb\214vn\214~}\220\207\215\217\220\235\224\233\260\227\244\301\233\257\324\237\267\342\241\277\360\242\304\373\236\311\377\245\313\3731j\275\350\000\000\000\001bKGD\000\210\005\035H\000\000\000\tpHYs\000\000\v\023\000\000\v\023\001\000\232\234\030\000\000\000\atIME\a\330\003\034\003\0172\"\337U\003\000\000\001TIDAT8\313c\020\304\001\030F%\bK000`\225`\016\357H\026\300&\221\375\356\335\333\311\214\230\022\032\357V\244\317\371\035\210!!\320w]\200\201u\377f\210\004\243\022\\\232\345\334\004\240l\314\017F\220\004s\347\256\251\214P\t\211?\016@\222\363\215!PB \372\317\236wMP\t\255\237 \222\365n\002PB\370\334d\345\234\347\020-\002\266?A\f\341{\r@\t\311_\n\002\354@\275`\340\367\002,q~\002P\302\372;\243 \363\271\004\210D\034X\253\320~\240\204\200\317SFA\241\365\r\020\t\333\037p\035\002~_A\022\023 \0226`;D\336\001\355\020\360\275\212\244C\353\227\"\220d{\vt\225\200\3157F\240\313\n \022\354o\003\200\244\324kE\220\253\200Ng{\023\000\r\333}\213\030\005\005j\237\203|\316z\267H\320\373\a\324\353\002\271\257\234\030\325\317O\002\205\225@\355\253\316s\213\301\022\300x\020;\177\262s\337KCp \262\256\271\263]QP\331\330\330\330\304PP\300\363\354\333\323I\320\210\022v\026\020\024\210{\367\356\335\373\211@]\246\251\216\360\250\005\231c\321\001\004\211 \363\030\030Q\342\\\200\001\232\nF\363\a\035$\000|\224\234q\3363+s\000\000\000\000IEND\256B`\202
PNGSTART
# __END__ and DATA global constant are not working under Shoes yet.
# Default_png can move there, later.

require 'rexml/document'
require 'net/http'
require 'yaml'
require 'time'
require 'base64'

require 'crypto_tool'

LIMIT = 140

TWITTER_PASSWORD = ''
TWITTER_USERNAME = ''
CRYPTO_PASSWORD = ''

class State < Struct.new( :ok, :message )
end

class Mytime < Time

  # time representation twitter_like, using: ago's
  def self.elapsed_time(e) 
    et = now - parse(e)
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

class Twitter

  TIMELINE = {
    'me' => '/statuses/friends_timeline.xml',
    'public' => '/statuses/public_timeline.xml',
    'friends' => '/statuses/friends.xml',
    'followers' => '/statuses/followers.xml'
  }
  TIMELINE_ELEMENT = {
    'me' => '/statuses/status',
    'public' => '/statuses/status',
    'friends' => '/users',
    'followers' => '/users',
    'update' => '/status'
  }

  HOST = 'twitter.com'

  attr_reader :user

  def initialize
    @user, @passwd, @timeline, @state = '', '', 'me', ''
    @path = "#{user_home}/.twittershoes"
    @settings_file = "#{@path}/twittershoes.yaml"
    @private_key_file = "#{@path}/private.pem"
    @public_key_file = "#{@path}/public.pem"
  end

  # get credentials for an old user or store new user (to twittershoes) credentials
  # There are two cases:
  # New User:
  #   new_user = true
  #   password = twitter password
  #   user = twitter username
  # Returning User:
  #   new_user = false
  #   password = private key password
  def credentials( new_user, password, user = nil )
    state = State.new( true, 'Initial state' )

    if new_user
      @user = user
      @passwd = password
      state = store_credentials
    else
      begin
        defs = YAML::load_file(@settings_file)
        @user = defs[:user]
        encrypted_data = EncryptedData.new
        EncryptedData.members.each do |key|
          encrypted_data.send( "#{key}=", Base64.decode64( defs[key] ) )
        end
        @passwd = CryptoTool.decrypt( password, @private_key_file, encrypted_data )
        
        state.ok = true
        state.message = "Loaded YAML settings. User: #{@user}"
      rescue
        state.ok = false
        state.message = "Could not load YAML file: #{$!}"
      end
    end

    state
  end

  # write credentials to file
  def store_credentials
    encrypted_data = CryptoTool.encrypt( @passwd, @public_key_file )
    state = nil

    begin
      tree = { :user => @user }
      EncryptedData.members.each do |key|
        tree[key] = Base64.encode64( encrypted_data.send( key ) )
      end
      if !File.directory?(@path)
        FileUtils.mkdir(@path)
      end
      File.open(@settings_file, 'w') do |f|
        YAML::dump(tree, f)
      end
      state = State.new( true, 'credentials successfuly stored locally' )
    rescue
      state = State.new( false, "error storing local credentials: #{$!}" )
    end

    state
  end

  # determine the user home directory based on OS
  def user_home
    if RUBY_PLATFORM =~ /win32/
      if ENV['USERPROFILE']
        if File.exist?(File.join(File.expand_path(ENV['USERPROFILE']), "Application Data"))
          File.join File.expand_path(ENV['USERPROFILE']), "Application Data"
        else
          File.expand_path(ENV['USERPROFILE'])
        end
      else
        File.join File.expand_path(Dir.getwd), "data"
      end
    else
      ENV['HOME']
    end
  end

  # setup a twitter connection
  def twitter_conn(h, *args)
    begin
      Net::HTTP.start(h) { |http|
        req = yield 
        req.set_form_data(args[0]) if req.class.to_s.include?('Post')
        req.basic_auth @user, @passwd
        response = http.request(req)
        return response.body
      }
    rescue => e
      # TODO: better Connection Error: #{$!}
      return e
    end
  end

  # pull twitter timeline xml
  def pull_xml
    twitter_conn(HOST) { Net::HTTP::Get.new(TIMELINE[@timeline]) }  # GET method
  end

  # delete posted twitter update
  def destroy_message(msg)
    twitter_conn(HOST) { Net::HTTP::Get.new(msg) }  # GET method
  end

  # post a new twitter update
  def post_message(msg)
    twitter_conn(HOST, {'status' => msg}) { Net::HTTP::Post.new('/statuses/update.xml') }  # POST method
  end

  # stack of twitter information
  def twittstack
    stack = []
    doc = REXML::Document.new pull_xml
    doc.elements.each(TIMELINE_ELEMENT[@timeline]) { |element|
      stack << [ element.text("id").to_i,
                  element.text("created_at"),
                  element.text("user/name"),
                  element.text("text"),
                  element.text("user/profile_image_url"),
                  element.text("source"),
                  element.text("truncated"),
                  element.text("user/id"),
                  element.text("user/screen_name"),
                  element.text("user/description"),
                  element.text("user/protected") ]
    }
    return stack
  end

end


class Tshoe < Shoes
  BACKGROUND = "#2F2F2F"

   url '/', :index
   url '/setup', :setup

  # Index page
  def index
    @data = nil
    @t = Twitter.new
    @state = @t.credentials( false, CRYPTO_PASSWORD ) # TODO should store password, should also check if credentials work
    # check if the credentials were loaded properly, if not try a new login password
    if @state.is_a? State and not @state.ok
      debug( "State: #{@state.inspect}" )
      @state = @t.credentials( true, TWITTER_PASSWORD, TWITTER_USERNAME )
    end
    debug( "State: #{@state.inspect}" )
    @page = 1
    fetch_data
    listen
  end

  def fetch_data
    @data = @t.twittstack
  end

  # TODO Setup page...
  def setup
    alert("set me up, please...")
  end

  # creation of a default image
  # no cache here. Image is always (because rarely) created on-time.
  def default_twitter_image
    name = File.join(CACHE_DIR, 'twitter_image.png')
    File.open(name, 'wb') do |fout|
      fout.syswrite Default_png
    end
    name
  end

  #  twit (id, image, name, screen_name, text, elapsedtime)
  #  this method sets the message to be sent to each message stack
  #  notice the final eval(uation) that packs all the string together.
  def twit(id, i, n, sn, t, e)  
    sn == @t.user ? del = link(" x", :underline => false, :stroke => "#732A2A") { @t.destroy_message("/status/destroy/#{id}.xml"); alert("Status id:#{id} has been DELETED") } : del = ""
    flow :margin => 5 do
      background "#161616", :radius => 8
      stack :width => 58 do
     #   image i, :margin => 5, :click => "http://twitter.com/#{sn}"
      end
      stack :width => -58, :margin => 5 do
        l = link(n, :click => "http://twitter.com/#{sn}", :underline => false, :stroke => orange)
        m = link(Mytime.elapsed_time(e), :font => 'smallfont', :size => 6, :stroke => '#6D6D6D', :underline => false, :click => "http://www.twitter.com/#{sn}/statuses/#{id}")
        r = link('←', :underline => false, :stroke => '#183616') { @i_say.text = "@#{sn} " }
        eval "para l, ': ', \"#{t}\", \" \", m, \" \", r, del, :font => 'Arial', :size => 8, :stroke => '#999999'"
      end
    end
  end
  
  # tweet message link parse and conversion to shoes links with eval(uation).
  # tries to discover http links in messages and prepare them for eval(uation).
  def linkparse(s) 
    s.gsub!(/\"/, "'")
    if s.include? "http://"
      r = ""
      s.each(' ') { |e|
        b = e.gsub!(/(()|(\S+))http:\/\/\S+/, "link('\\0', :click => '\\0', :font => 'Arial', :size => 8, :underline => false, :stroke => '#397EAA')")
        b.nil? ? r << e : r << "\", #{b}, \""
      }
      r
    else
      s
    end
  end

  # alert message for the number of chars left to the tweet message
  def string_alert 
    c = (LIMIT-@i_say.text.length)
    @remaining.style :stroke => "#3276BA"
    c > 10 ? (@remaining.style :stroke => orange) : (@remaining.style :stroke => red) if (c < 21)
    c > 0 ? "#{c.to_s} chars" : "Too Long!"
  end

  # send message and clear the text box
  def upandaway
    @t.post_message(@i_say.text)
    @i_say.text = ''
  end

  # Method responsable for parsing each incoming message from the XML answer
  def get_thread
    if @data != nil
      @data.each { |msg| twit(msg[0], msg[4], msg[2], msg[8], linkparse(msg[3]), msg[1]) }
    else
      m1 = 'fetching twitter data... please wait or press '
      m2 = "link('here', :font => 'Arial', :size => 8, :underline => false, :stroke => '#397EAA') { fetch_data; clear; listen }"
      m = "#{m1}, \", #{m2}, \""
      twit("0", default_twitter_image, "TwitterShoes", "twitershoes", m, Time.now.to_s)
    end
  end

  # GUI area definition method. This method draws the incoming messages area, and the message insertion area.
  def listen
    background BACKGROUND
    # stack :width => 1.0, :height => -50 do # SHOES TICKET submitted for negative heights inside a page.
    stack :width => 1.0, :height => 500 do 
      background BACKGROUND
      get_thread
    end
    flow :width => 1.0, :height => 50 do
      background BACKGROUND
      stack :width => -50 do
        @i_say = edit_box "what are you doing ?", :margin => 5, :width => 250, :height => 50, :size => 9 do
          @remaining.replace string_alert
          if @i_say.text[-1] == ?\n
            upandaway
          end
        end
      end
      stack :width => 50 do
        para(link(" Update ", :size => 8, :font => "Arial", :fill => "#4992E6" , :stroke => "#D5E0ED", :underline => false) { upandaway })
        para(link("<· ", :size => 8, :font => "Arial", :stroke => "#3276BA", :underline => false) { alert("previous page (temporarily disabled by Twitter)") },
             "  1  ", 
             link(" ·>", :size => 8, :font => "Arial", :stroke => "#3276BA", :underline => false) { alert("next page (temporarily disabled by Twitter)") }, :top => 15, :size => 7, :font => "Arial", :stroke => "#3276BA", :underline => false)
        @remaining = para "140", " chars", :top => 30, :size => 6, :font => "Arial", :stroke => "#3276BA"
      end
    end
  end

end


Shoes.app :title => "Twitter needs Shoes", :width => 300, :height => 550, :radius => 12, :resizable => true

