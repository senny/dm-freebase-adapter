$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "rubygems"
require "dm-core"
require 'freebase_adapter'
require 'spec'
require 'spec/autorun'

DataMapper.setup(:default, :adapter => 'freebase')

Spec::Runner.configure do |config|
  
end
