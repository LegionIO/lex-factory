# frozen_string_literal: true

require_relative 'lib/legion/extensions/factory/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-factory'
  spec.version       = Legion::Extensions::Factory::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['legionio@esity.com']
  spec.summary       = 'Spec-to-code autonomous pipeline for LegionIO'
  spec.description   = 'Double Diamond pipeline that takes a specification and produces working code with tests'
  spec.homepage      = 'https://github.com/LegionIO/lex-factory'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'legion-json', '>= 1.2'
end
