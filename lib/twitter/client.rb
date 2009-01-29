# client.rb contains the classes, methods and extends <tt>Twitter4R</tt> 
# features to define client calls to the Twitter REST API.
# 
# See:
# * <tt>Twitter::Client</tt>

# Used to query or post to the Twitter REST API to simplify code.
class Twitter::Client
  include Twitter::ClassUtilMixin
end

require_local('twitter/client/base.rb')
require_local('twitter/client/timeline.rb')
require_local('twitter/client/status.rb')
require_local('twitter/client/friendship.rb')
require_local('twitter/client/messaging.rb')
require_local('twitter/client/user.rb')
require_local('twitter/client/auth.rb')
require_local('twitter/client/favorites.rb')

