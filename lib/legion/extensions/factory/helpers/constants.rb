# frozen_string_literal: true

module Legion
  module Extensions
    module Factory
      module Helpers
        module Constants
          STAGES = %i[discover define develop deliver].freeze

          SCORE_WEIGHTS = {
            completeness: 0.35,
            correctness: 0.35,
            quality: 0.20,
            security: 0.10
          }.freeze

          DEFAULT_SATISFACTION_THRESHOLD = 0.8
          DEFAULT_MAX_RETRIES           = 2
          DEFAULT_OUTPUT_DIR            = 'tmp/factory'
        end
      end
    end
  end
end
