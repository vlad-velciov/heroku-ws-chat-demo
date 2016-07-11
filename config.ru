$:.unshift ::File.dirname(__FILE__)
#\-s Puma -p 4568
require './middlewares/chat_backend.rb'
require 'app'
require 'puma'

use ChatDemo::ChatBackend
run ApiApplication
