# frozen_string_literal: true

require 'legion/extensions/factory/helpers/constants'

RSpec.describe Legion::Extensions::Factory::Helpers::Constants do
  it 'defines STAGES' do
    expect(described_class::STAGES).to eq(%i[discover define develop deliver])
  end

  it 'defines SCORE_WEIGHTS' do
    weights = described_class::SCORE_WEIGHTS
    expect(weights.keys).to contain_exactly(:completeness, :correctness, :quality, :security)
    expect(weights.values.sum).to be_within(0.01).of(1.0)
  end

  it 'defines DEFAULT_SATISFACTION_THRESHOLD' do
    expect(described_class::DEFAULT_SATISFACTION_THRESHOLD).to eq(0.8)
  end

  it 'defines DEFAULT_MAX_RETRIES' do
    expect(described_class::DEFAULT_MAX_RETRIES).to eq(2)
  end
end
