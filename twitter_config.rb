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
require 'time' # needed for twitter4r
require 'rexml/document'
require 'base64'
require 'yaml'
require 'net/http'
require 'tmpdir'

# Manages
class TwitterConfig

  attr_reader :user, :twitter_client, :state, :cache_dir

  def initialize( user = nil, password = nil )
    @path = "#{user_home}/.twittershoes"
    @cache_dir = "#{@path}/cache"
    @settings_file = "#{@path}/twittershoes.yaml"
    @private_key_file = "#{@path}/rsa_key"
    @public_key_file = "#{@path}/rsa_key.pub"
    @digital_signature = get_digital_signature
    @state = credentials( user, password )

    Twitter::Client.configure do |conf|
      conf.protocol = :http # can't get SSL working atm, undefined method closed? for SSLSocket
      conf.port = 80
    end
    @twitter_client = Twitter::Client.new( { :login => @user, :password => @password } )
    @password = nil # clear password from memory

    make_cache_dir
  end

  # get credentials for an old user or store new user (to twittershoes) credentials
  # There are two cases:
  # New User:
  #   password = twitter password
  #   user = twitter username
  # Returning User:
  #   new_user = false
  #   password = private key password
  def credentials( user = nil, password = nil )
    state = State.new( true, 'Initial state' )

    if not File.exist?( @settings_file )
      @user = user
      @password = password
      state = store_credentials
    else
      begin
        defs = YAML::load_file( @settings_file )
        @user = defs[:user]
        @password = @digital_signature.decrypt( defs[:password] )
        
        state.ok = true
        state.message = "Loaded YAML settings. User: #{@user}"
      rescue
        state.ok = false
        state.message = "Could not load YAML file: #{$!}"
      end
    end

    state
  end

  # Generates a RSA Digital Signature Key Pair (public and private) if the files don't exist.
  # Sets the private/public keys for the Digital Signature
  def get_digital_signature
    if not File.exist?( @private_key_file ) or not File.exist?( @public_key_file )
      Metafusion::Crypto.generate_key_pair( @private_key_file, @public_key_file )
    end

    Metafusion::Crypto::DigitalSignature.from_keys( @public_key_file, @private_key_file )
  end

  # write credentials to file
  def store_credentials
    state = nil

    begin
      tree = {
        :user => @user,
        :password => @digital_signature.encrypt( @password )
      }
      if not File.directory?( @path )
        FileUtils.mkdir( @path )
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

  # clears cache directory or creates it if it doesn't exist
  def make_cache_dir
    if File.directory?( @cache_dir )
      files = Dir[ "#{@cache_dir}/*" ]
      FileUtils.rm( files )
    else
      FileUtils.mkdir( @cache_dir )
    end
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
end
