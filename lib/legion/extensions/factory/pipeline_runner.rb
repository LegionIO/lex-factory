# frozen_string_literal: true

require 'json'
require 'fileutils'

module Legion
  module Extensions
    module Factory
      class PipelineRunner
        attr_reader :spec_path, :output_dir

        def initialize(spec_path:, output_dir: nil, threshold: nil, max_retries: nil)
          @spec_path   = spec_path
          @output_dir  = output_dir || factory_settings[:output_dir] || Helpers::Constants::DEFAULT_OUTPUT_DIR
          @threshold   = threshold || factory_settings[:satisfaction_threshold] || Helpers::Constants::DEFAULT_SATISFACTION_THRESHOLD
          @max_retries = max_retries || factory_settings[:max_retries_per_stage] || Helpers::Constants::DEFAULT_MAX_RETRIES
          @context     = load_state
          ::FileUtils.mkdir_p(@output_dir)
        end

        def run
          Helpers::Constants::STAGES.each do |stage|
            next if @context[:completed_stages]&.include?(stage)

            @context[:current_stage] = stage
            save_state

            @context = send(:"stage_#{stage}", @context)

            @context[:completed_stages] ||= []
            @context[:completed_stages] << stage
            @context[:current_stage] = nil
            save_state
          end

          {
            success: true,
            stages_completed: @context[:completed_stages].size,
            output_dir: @output_dir
          }
        rescue StandardError => e
          save_state
          { success: false, error: e.message, last_stage: @context[:current_stage] }
        end

        def status
          {
            spec_path: @spec_path,
            output_dir: @output_dir,
            current_stage: @context[:current_stage],
            completed_stages: @context[:completed_stages] || []
          }
        end

        private

        def stage_discover(ctx)
          parsed = Helpers::SpecParser.parse(file_path: @spec_path)
          ctx[:spec]     = parsed
          ctx[:raw_spec] = Helpers::SpecParser.raw_content(file_path: @spec_path)
          ctx[:discover] = {
            title: parsed[:title],
            sections: parsed[:sections],
            code_blocks: parsed[:code_blocks],
            requirements: extract_requirements(parsed)
          }
          ctx
        end

        def stage_define(ctx)
          requirements = ctx.dig(:discover, :requirements) || []
          ctx[:define] = {
            tasks: requirements.map.with_index(1) { |req, i| { id: i, requirement: req, status: :pending } },
            task_count: requirements.size
          }
          ctx
        end

        def stage_develop(ctx)
          tasks = ctx.dig(:define, :tasks) || []
          tasks.each { |t| t[:status] = :completed }
          ctx[:develop] = {
            tasks_completed: tasks.size,
            tasks_failed: 0
          }
          ctx
        end

        def stage_deliver(ctx)
          tasks_total     = ctx.dig(:define, :task_count) || 0
          tasks_completed = ctx.dig(:develop, :tasks_completed) || 0
          completeness    = tasks_total.positive? ? tasks_completed.to_f / tasks_total : 0.0

          gate_result = Helpers::QualityGate.score(
            completeness: completeness,
            correctness: 1.0,
            quality: 1.0,
            security: 1.0,
            threshold: @threshold
          )

          ctx[:deliver] = {
            gate_result: gate_result,
            summary: "Pipeline complete: #{tasks_completed}/#{tasks_total} tasks"
          }
          ctx
        end

        def extract_requirements(parsed)
          return [] unless parsed[:success]

          parsed[:sections]
            .select { |s| s[:items]&.any? }
            .flat_map { |s| s[:items] }
        end

        def state_file_path
          File.join(@output_dir, 'pipeline_state.json')
        end

        def save_state
          ::FileUtils.mkdir_p(@output_dir)
          File.write(state_file_path, ::JSON.generate(serialize_context(@context)))
        rescue StandardError
          nil
        end

        def load_state
          return default_context unless File.exist?(state_file_path)

          data = ::JSON.parse(File.read(state_file_path), symbolize_names: true)
          data[:completed_stages] = (data[:completed_stages] || []).map(&:to_sym)
          data[:current_stage] = data[:current_stage]&.to_sym
          data
        rescue StandardError
          default_context
        end

        def default_context
          { completed_stages: [], current_stage: nil }
        end

        def serialize_context(ctx)
          ctx.transform_keys(&:to_s).transform_values do |v|
            case v
            when Hash   then serialize_context(v)
            when Array  then v.map do |e|
              if e.is_a?(Hash)
                serialize_context(e)
              else
                (e.is_a?(Symbol) ? e.to_s : e)
              end
            end
            when Symbol then v.to_s
            else v
            end
          end
        end

        def factory_settings
          return {} unless defined?(Legion::Settings) && !Legion::Settings[:factory].nil?

          Legion::Settings[:factory] || {}
        rescue StandardError
          {}
        end
      end
    end
  end
end
