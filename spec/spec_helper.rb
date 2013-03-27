require 'simplecov'
SimpleCov.start { add_filter "/_spec.rb$/" }

require 'rspec/autorun'
require 'rspec/given'

RSpec.configure do |config|
end
