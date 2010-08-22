# client.rb contains the classes, methods and extends <tt>Twitter4R</tt> 
# features to define client calls to the Twitter REST API.
# 
# See:
# * <tt>Twitter::Client</tt>

# Used to query or post to the Twitter REST API to simplify code.
class Twitter::Client
  include Twitter::ClassUtilMixin
end

require_local('twitter/client/base')
require_local('twitter/client/timeline')
require_local('twitter/client/status')
require_local('twitter/client/friendship')
require_local('twitter/client/messaging')
require_local('twitter/client/user')
require_local('twitter/client/auth')
require_local('twitter/client/favorites')
require_local('twitter/client/blocks')
require_local('twitter/client/account')
require_local('twitter/client/graph')
require_local('twitter/client/profile')
require_local('twitter/client/search')
