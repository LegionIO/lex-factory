# frozen_string_literal: true

require 'legion/extensions/factory/version'
require_relative 'factory/helpers/constants'
require_relative 'factory/helpers/spec_parser'
require_relative 'factory/helpers/quality_gate'
require_relative 'factory/pipeline_runner'
require_relative 'factory/runners/factory'

module Legion
  module Extensions
    module Factory
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core, false)

      class << self
        def data_required?
          false
        end

        def llm_required?
          true
        end

        def remote_invocable?
          false
        end
      end
    end
  end
end
