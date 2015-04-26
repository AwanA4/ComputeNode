#\ -s puma
require 'bundler/setup'
require './runtime'
run Sinatra::Application
