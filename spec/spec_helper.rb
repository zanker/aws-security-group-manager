path = File.expand_path("../../", __FILE__)
require "#{path}/lib/aws-security-group-manager"

Dir["#{path}/spec/support/*.rb"].each {|file| require file}

RSpec.configure do |c|
  c.mock_with :rspec
end
