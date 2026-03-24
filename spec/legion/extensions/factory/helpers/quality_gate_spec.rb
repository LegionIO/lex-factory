# frozen_string_literal: true

require 'legion/extensions/factory/helpers/quality_gate'

RSpec.describe Legion::Extensions::Factory::Helpers::QualityGate do
  describe '.score' do
    it 'returns a passing score for good results' do
      result = described_class.score(
        completeness: 1.0,
        correctness:  1.0,
        quality:      1.0,
        security:     1.0
      )
      expect(result[:pass]).to be true
      expect(result[:aggregate]).to be_within(0.01).of(1.0)
    end

    it 'returns a failing score below threshold' do
      result = described_class.score(
        completeness: 0.5,
        correctness:  0.5,
        quality:      0.5,
        security:     0.5
      )
      expect(result[:pass]).to be false
      expect(result[:aggregate]).to be_within(0.01).of(0.5)
    end

    it 'uses custom threshold' do
      result = described_class.score(
        completeness: 0.7,
        correctness:  0.7,
        quality:      0.7,
        security:     0.7,
        threshold:    0.6
      )
      expect(result[:pass]).to be true
    end

    it 'returns individual dimension scores' do
      result = described_class.score(
        completeness: 0.9,
        correctness:  1.0,
        quality:      0.8,
        security:     0.7
      )
      expect(result[:scores][:completeness]).to eq(0.9)
      expect(result[:scores][:correctness]).to eq(1.0)
    end

    it 'clamps scores to 0.0-1.0 range' do
      result = described_class.score(
        completeness: 1.5,
        correctness:  -0.1,
        quality:      0.8,
        security:     0.9
      )
      expect(result[:scores][:completeness]).to eq(1.0)
      expect(result[:scores][:correctness]).to eq(0.0)
    end
  end
end
