# frozen_string_literal: true

require 'legion/extensions/factory/helpers/spec_parser'

RSpec.describe Legion::Extensions::Factory::Helpers::SpecParser do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_path) { File.join(tmp_dir, 'spec.md') }

  after { FileUtils.remove_entry(tmp_dir) }

  describe '.parse' do
    before do
      File.write(spec_path, <<~MD)
        # Build a User Auth System

        ## Requirements

        - Users can register with email and password
        - Passwords must be hashed with bcrypt
        - Login returns a JWT token

        ## Constraints

        - Ruby 3.4
        - No external auth providers

        ## Examples

        ```ruby
        user = User.register(email: 'test@example.com', password: 'secret')
        token = User.login(email: 'test@example.com', password: 'secret')
        ```
      MD
    end

    it 'returns a parsed spec hash' do
      result = described_class.parse(file_path: spec_path)
      expect(result[:success]).to be true
      expect(result[:title]).to eq('Build a User Auth System')
    end

    it 'extracts sections' do
      result = described_class.parse(file_path: spec_path)
      expect(result[:sections].size).to be >= 3
    end

    it 'extracts requirements' do
      result = described_class.parse(file_path: spec_path)
      requirements_section = result[:sections].find { |s| s[:heading] == 'Requirements' }
      expect(requirements_section[:items].size).to eq(3)
    end

    it 'extracts code blocks' do
      result = described_class.parse(file_path: spec_path)
      expect(result[:code_blocks].size).to eq(1)
      expect(result[:code_blocks].first[:language]).to eq('ruby')
    end

    it 'returns error for missing file' do
      result = described_class.parse(file_path: '/nonexistent.md')
      expect(result[:success]).to be false
    end
  end

  describe '.raw_content' do
    it 'returns the raw markdown content' do
      File.write(spec_path, '# Hello')
      result = described_class.raw_content(file_path: spec_path)
      expect(result).to include('# Hello')
    end
  end
end
