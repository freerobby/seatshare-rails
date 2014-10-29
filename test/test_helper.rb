$LOAD_PATH << 'test'
require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RAILS_ENV"] ||= "test"

  require 'rails/application'
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)

  require File.expand_path('../../config/environment', __FILE__)
  require 'rails/test_help'

  class ActiveSupport::TestCase
    ActiveRecord::Migration.check_pending!

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    #
    # Note: You'll currently still have to declare fixtures explicitly in integration tests
    # -- they do not yet inherit this setting
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end

  class ActionController::TestCase
    include Devise::TestHelpers
  end

  class DeviseController
    include DeviseHelper
    include ActionView::Helpers::TagHelper
    helper_method :devise_error_messages!
    helper_method :content_tag
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.

# Public: provide debugging information for tests which are known to fail intermittently
#
# issue_link - url of GitHub issue documenting this intermittent test failure
# args       - Hash of debugging information (names => values) to output on a failure
# block      - block which intermittently fails
#
# Example
#
#    fails_intermittently('https://github.com/github/github/issues/27807',
#      '@repo' => @repo, 'shas' => shas, 'expected' => expected) do
#      assert_equal expected, shas
#    end
#
# Re-raises any MiniTest::Assertion from a failing test assertion in the block.
#
# Returns the value of the yielded block when no test assertion fails.
def fails_intermittently(issue_link, args = {}, &block)
  raise ArgumentError, "provide a GitHub issue link" unless issue_link
  raise ArgumentError, "a block is required" unless block_given?
  yield
rescue MiniTest::Assertion, StandardError => boom # we have a test failure!
  STDERR.puts "\n\nIntermittent test failure! See: #{issue_link}"

  if args.empty?
    STDERR.puts "No further debugging information available."
  else
    STDERR.puts "Debugging information:\n"
    args.keys.sort.each do |key|
      STDERR.puts "#{key} => #{args[key].inspect}"
    end
  end

  raise boom
end