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

      # Create new runner pointing to same output dir
      runner2 = described_class.new(spec_path: spec_path, output_dir: tmp_dir)
      status = runner2.status
      expect(status[:completed_stages].size).to eq(4)
    end
  end
end
