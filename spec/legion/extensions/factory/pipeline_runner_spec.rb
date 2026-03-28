# frozen_string_literal: true

require 'legion/extensions/factory/pipeline_runner'

RSpec.describe Legion::Extensions::Factory::PipelineRunner do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_path) { File.join(tmp_dir, 'spec.md') }

  before do
    File.write(spec_path, "# Test Feature\n\n## Requirements\n\n- Do something useful\n")
  end

  after { FileUtils.remove_entry(tmp_dir) }

  describe '#initialize' do
    it 'creates a pipeline with spec path' do
      runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      expect(runner.spec_path).to eq(spec_path)
    end
  end

  describe '#run' do
    it 'executes all stages and returns a result' do
      runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      result = runner.run
      expect(result[:success]).to be true
      expect(result[:stages_completed]).to eq(4)
    end

    it 'persists state file' do
      runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      runner.run
      state_file = File.join(tmp_dir, 'pipeline_state.json')
      expect(File.exist?(state_file)).to be true
    end
  end

  describe '#status' do
    it 'returns current pipeline status' do
      runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      status = runner.status
      expect(status[:current_stage]).to be_nil
      expect(status[:completed_stages]).to eq([])
    end
  end

  describe 'resumability' do
    it 'resumes from last completed stage' do
      runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      runner.run

      runner2 = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      status = runner2.status
      expect(status[:completed_stages].size).to eq(4)
    end
  end

  describe 'develop stage' do
    context 'when lex-codegen is unavailable' do
      before do
        allow_any_instance_of(described_class).to receive(:codegen_available?).and_return(false)
      end

      it 'falls back to stub strategy and completes all pipeline stages' do
        runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
        result = runner.run
        expect(result[:success]).to be true
        expect(result[:stages_completed]).to eq(4)
      end

      it 'sets strategy to :stub in develop context' do
        File.write(spec_path, "# Test\n\n## Requirements\n\n- Req one\n- Req two\n")
        runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
        runner.run
        state_raw = JSON.parse(File.read(File.join(tmp_dir, 'pipeline_state.json')))
        expect(state_raw.dig('develop', 'strategy')).to eq('stub')
        expect(state_raw.dig('develop', 'tasks_completed')).to eq(2)
        expect(state_raw.dig('develop', 'tasks_failed')).to eq(0)
      end
    end

    context 'when lex-codegen is available' do
      let(:codegen_module) do
        Module.new do
          def self.generate(gap:)
            { success: true, generation_id: "gen_#{gap[:id]}", tier: :simple, file_path: "/tmp/gen_#{gap[:id]}.rb" }
          end

          def self.respond_to?(method, *)
            method == :generate || super
          end
        end
      end

      before do
        allow_any_instance_of(described_class).to receive(:codegen_available?).and_return(true)
        stub_const('Legion::Extensions::Codegen::Runners::FromGap', codegen_module)
      end

      it 'delegates each task to FromGap.generate' do
        File.write(spec_path, "# Test\n\n## Requirements\n\n- Build widget\n- Add tests\n")
        expect(codegen_module).to receive(:generate).twice.and_call_original
        runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
        result = runner.run
        expect(result[:success]).to be true
        expect(result[:stages_completed]).to eq(4)
      end

      it 'sets strategy to :codegen in develop context' do
        File.write(spec_path, "# Test\n\n## Requirements\n\n- Build widget\n")
        runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
        runner.run
        state_raw = JSON.parse(File.read(File.join(tmp_dir, 'pipeline_state.json')))
        expect(state_raw.dig('develop', 'strategy')).to eq('codegen')
        expect(state_raw.dig('develop', 'tasks_completed')).to eq(1)
        expect(state_raw.dig('develop', 'tasks_failed')).to eq(0)
      end

      it 'records artifacts for each generated task' do
        File.write(spec_path, "# Test\n\n## Requirements\n\n- Build widget\n")
        runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
        runner.run
        state_raw = JSON.parse(File.read(File.join(tmp_dir, 'pipeline_state.json')))
        artifacts = state_raw.dig('develop', 'artifacts')
        expect(artifacts).to be_an(Array)
        expect(artifacts.size).to eq(1)
        expect(artifacts.first['generation_id']).to eq('gen_1')
      end

      context 'when FromGap.generate returns failure' do
        let(:failing_codegen_module) do
          Module.new do
            def self.generate(**)
              { success: false, reason: :llm_unavailable }
            end

            def self.respond_to?(method, *)
              method == :generate || super
            end
          end
        end

        before do
          stub_const('Legion::Extensions::Codegen::Runners::FromGap', failing_codegen_module)
        end

        it 'marks tasks as failed and records reason' do
          runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
          runner.run
          state_raw = JSON.parse(File.read(File.join(tmp_dir, 'pipeline_state.json')))
          expect(state_raw.dig('develop', 'tasks_failed')).to eq(1)
          expect(state_raw.dig('develop', 'tasks_completed')).to eq(0)
          failed_task = state_raw.dig('define', 'tasks')&.find { |t| t['status'] == 'failed' }
          expect(failed_task).not_to be_nil
          expect(failed_task['reason']).to eq('llm_unavailable')
        end

        it 'still completes the full pipeline' do
          runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
          result = runner.run
          expect(result[:success]).to be true
          expect(result[:stages_completed]).to eq(4)
        end
      end

      context 'when FromGap.generate raises an exception' do
        let(:raising_codegen_module) do
          Module.new do
            def self.generate(**)
              raise StandardError, 'unexpected error'
            end

            def self.respond_to?(method, *)
              method == :generate || super
            end
          end
        end

        before do
          stub_const('Legion::Extensions::Codegen::Runners::FromGap', raising_codegen_module)
        end

        it 'rescues per-task exceptions and marks tasks failed' do
          runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
          runner.run
          pipeline_state_path = File.join(tmp_dir, 'pipeline_state.json')
          raw_content = File.read(pipeline_state_path)
          state_raw = JSON.parse(raw_content)
          expect(state_raw.dig('develop', 'tasks_failed')).to eq(1)
          expect(raw_content).to include('unexpected error')
        end

        it 'still completes the full pipeline' do
          runner = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
          result = runner.run
          expect(result[:success]).to be true
        end
      end
    end
  end
end
