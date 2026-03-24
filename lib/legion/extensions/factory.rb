# frozen_string_literal: true

require 'legion/extensions/factory/version'

module Legion
  module Extensions
    module Factory
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)

      class << self
        def data_required?
          false
        end

        def llm_required?
          true
        end
      end
    end
  end
end
