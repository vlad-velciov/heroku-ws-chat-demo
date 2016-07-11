$:.unshift ::File.dirname(__FILE__)

require './middlewares/chat_backend.rb'
require 'app'
require 'puma'

use ChatDemo::ChatBackend
run ApiApplication
