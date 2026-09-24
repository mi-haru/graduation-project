require "simplecov"

SimpleCov.start "rails" do
  command_name "Minitest"
  coverage_dir "coverage/minitest"
  cover "app/**/*.rb"
  merging false
end
