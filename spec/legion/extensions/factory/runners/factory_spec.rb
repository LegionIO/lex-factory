# frozen_string_literal: true

require 'legion/extensions/factory/runners/factory'

RSpec.describe Legion::Extensions::Factory::Runners::Factory do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_path) { File.join(tmp_dir, 'spec.md') }

  before do
    File.write(spec_path, "# Test Feature\n\n## Requirements\n\n- Build feature A\n- Build feature B\n")
  end

  after { FileUtils.remove_entry(tmp_dir) }

  describe '.run_pipeline' do
    it 'runs the full pipeline and returns success' do
      result = described_class.run_pipeline(spec_path: spec_path, output_dir: tmp_dir)
      expect(result[:success]).to be true
      expect(result[:stages_completed]).to eq(4)
    end

    it 'returns error for missing spec' do
      result = described_class.run_pipeline(spec_path: '/nonexistent.md', output_dir: tmp_dir)
      expect(result[:success]).to be false
    end
  end

  describe '.pipeline_status' do
    it 'returns status after a run' do
      described_class.run_pipeline(spec_path: spec_path, output_dir: tmp_dir)
      status = described_class.pipeline_status(output_dir: tmp_dir)
      expect(status[:success]).to be true
      expect(status[:completed_stages].size).to eq(4)
    end

    it 'returns empty status for fresh directory' do
      status = described_class.pipeline_status(output_dir: tmp_dir)
      expect(status[:success]).to be true
      expect(status[:completed_stages]).to eq([])
    end
  end
end
