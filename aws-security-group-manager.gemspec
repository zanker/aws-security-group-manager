$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "manager/version"

Gem::Specification.new do |s|
  s.name        = "aws-security-group-manager"
  s.version     = AWSSecurityGroups::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Anker"]
  s.email       = ["zach.anker@gmail.com"]
  s.homepage    = "http://github.com/zanker/aws-security-group-manager"
  s.summary     = "Simplifies AWS/EC2 security group management"
  s.description = "Gem for managing AWS/EC2 security groups across regions"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency "fog", "~>1.5.0"

  s.add_development_dependency "rspec", "~>2.8.0"
  s.add_development_dependency "guard-rspec", "~>0.6.0"

  s.executables  = ["aws-security-groups"]
  s.files        = Dir.glob("lib/**/*") + %w[LICENSE README.md Rakefile]
  s.require_path = "lib"
end