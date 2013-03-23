notification :emacs
notification :terminal

group :all do
  guard :rspec do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})           { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')        { "spec" }
    watch(%r{^spec/support/(.+)\.rb$})  { "spec" }
  end
end

group :unit do
  guard :rspec, :cli => '--tag ~integration' do
    watch(%r{^spec/lib/.+_spec\.rb$})
    watch('spec/spec_helper.rb')        { "spec" }
    watch(%r{^lib/(.+)\.rb$})           { |m| "spec/lib/#{m[1]}_spec.rb" }
  end
end
