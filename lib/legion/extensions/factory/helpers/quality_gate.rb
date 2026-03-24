# frozen_string_literal: true

module Legion
  module Extensions
    module Factory
      module Helpers
        module QualityGate
          module_function

          def score(completeness:, correctness:, quality:, security:,
                    threshold: Constants::DEFAULT_SATISFACTION_THRESHOLD)
            scores = {
              completeness: clamp(completeness),
              correctness:  clamp(correctness),
              quality:      clamp(quality),
              security:     clamp(security)
            }

            aggregate = Constants::SCORE_WEIGHTS.sum do |dimension, weight|
              scores[dimension] * weight
            end

            {
              pass:      aggregate >= threshold,
              aggregate: aggregate.round(4),
              threshold: threshold,
              scores:    scores
            }
          end

          def clamp(value)
            [[value.to_f, 0.0].max, 1.0].min
          end

          private_class_method :clamp
        end
      end
    end
  end
end
