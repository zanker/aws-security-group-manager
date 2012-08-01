guard("rspec", :all_after_pass => false, :cli => "--fail-fast --color") do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) {|match| "spec/#{match[1]}_spec.rb"}
end