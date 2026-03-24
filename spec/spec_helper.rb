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

    def self.data=(data)
      @data = data
    end
  end

  module LLM
    def self.started?
      true
    end

    def self.ask(_message: nil)
      { content: 'stub LLM response' }
    end

    def self.structured(_message: nil, _schema: nil, **_opts)
      { content: {} }
    end
  end

  module Logging
    def self.debug(_msg) = nil
    def self.info(_msg) = nil
    def self.warn(_msg) = nil
    def self.error(_msg) = nil
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
