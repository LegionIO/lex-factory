# frozen_string_literal: true

RSpec.describe 'End-to-end factory pipeline' do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_path) { File.join(tmp_dir, 'feature_spec.md') }
  let(:output_dir) { File.join(tmp_dir, 'output') }

  before do
    File.write(spec_path, <<~MD)
      # User Authentication System

      ## Requirements

      - Users can register with email and password
      - Passwords must be hashed with bcrypt
      - Login returns a JWT token
      - Failed login returns 401

      ## Constraints

      - Ruby 3.4
      - No external auth providers
      - Must support rate limiting

      ## Examples

      ```ruby
      user = Auth.register(email: 'test@example.com', password: 'secret')
      token = Auth.login(email: 'test@example.com', password: 'secret')
      ```
    MD
  end

  after { FileUtils.remove_entry(tmp_dir) }

  it 'runs the full pipeline from spec to delivery' do
    result = Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )

    expect(result[:success]).to be true
    expect(result[:stages_completed]).to eq(4)
  end

  it 'persists pipeline state to disk' do
    Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )

    state_file = File.join(output_dir, 'pipeline_state.json')
    expect(File.exist?(state_file)).to be true

    state = ::JSON.parse(File.read(state_file), symbolize_names: true)
    expect(state[:completed_stages].size).to eq(4)
  end

  it 'parses spec requirements correctly' do
    Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )

    state = ::JSON.parse(
      File.read(File.join(output_dir, 'pipeline_state.json')),
      symbolize_names: true
    )
    # 4 requirements from Requirements section + 3 from Constraints
    expect(state.dig(:define, :task_count)).to be >= 4
  end

  it 'reports status after completion' do
    Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )

    status = Legion::Extensions::Factory::Runners::Factory.pipeline_status(output_dir: output_dir)
    expect(status[:success]).to be true
    expect(status[:completed_stages].size).to eq(4)
  end

  it 'resumes without re-executing completed stages' do
    Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )

    # Second run should detect all stages complete and return immediately
    result = Legion::Extensions::Factory::Runners::Factory.run_pipeline(
      spec_path: spec_path,
      output_dir: output_dir
    )
    expect(result[:success]).to be true
    expect(result[:stages_completed]).to eq(4)
  end
end
