# frozen_string_literal: true

module Legion
  module Extensions
    module Factory
      module Runners
        module Factory
          module_function

          def run_pipeline(spec_path:, output_dir: nil)
            return { success: false, error: 'spec file not found' } unless ::File.exist?(spec_path)

            runner = PipelineRunner.new(spec_path: spec_path, output_dir: output_dir)
            runner.run
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def pipeline_status(output_dir:)
            runner = PipelineRunner.new(spec_path: '', output_dir: output_dir)
            status = runner.status
            { success: true, **status }
          rescue StandardError => e
            { success: false, error: e.message }
          end
        end
      end
    end
  end
end
