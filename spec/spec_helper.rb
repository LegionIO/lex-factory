# frozen_string_literal: true

require 'bundler/setup'
require 'fileutils'
require 'tmpdir'

# Stub Legion framework modules
module Legion
  module Extensions
    module Core; end
  end
  module Settings
    def self.[](key)
      @data ||= {}
      @data[key]
    end

    def self.dig(*keys)
      @data ||= {}
      keys.reduce(@data) { |h, k| h.is_a?(Hash) ? h[k] : nil }
    end

    def self.set_test_data(data)
      @data = data
    end
  end
  module LLM
    def self.started?
      true
    end

    def self.ask(message:)
      { content: 'stub LLM response' }
    end

    def self.structured(message:, schema:, **opts)
      { content: {} }
    end
  end
  module Logging
    def self.debug(msg) = nil
    def self.info(msg) = nil
    def self.warn(msg) = nil
    def self.error(msg) = nil
  end
  module JSON
    def self.load(str)
      require 'json'
      ::JSON.parse(str, symbolize_names: true)
    end

    def self.dump(obj)
      require 'json'
      ::JSON.generate(obj)
    end
  end
end

require 'legion/extensions/factory'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.order = :random
end
