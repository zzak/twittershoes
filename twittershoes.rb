module TwitterShoes
end

def require_local( suffix )
  require File.expand_path( File.join( File.dirname( __FILE__ ), suffix ) )
end

# External dependencies
require 'time'
require 'base64'
require 'net/http'
require 'digest/sha1'
require 'rexml/document'
require 'yaml'
require 'tmpdir'

# Internal dependencies
require_local 'setup'

# Need to redefine because twitter sets up their own require_local
def require_local( suffix )
  require File.expand_path( File.join( File.dirname( __FILE__ ), suffix ) )
end

require_local 'lib/state'
require_local 'lib/mytime'
require_local 'lib/twitter_config'

