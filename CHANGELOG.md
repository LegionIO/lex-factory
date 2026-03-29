# Changelog

## [0.1.2] - 2026-03-28

### Changed
- Implement develop stage via real LLM code generation, delegating to `lex-codegen` `FromGap.generate`
- Graceful fallback to stub strategy when lex-codegen is not loaded
- Exclude `pipeline_runner.rb` from `Metrics/ClassLength` and `Metrics/AbcSize` in rubocop config

## [0.1.1] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.0] - 2026-03-24

### Added
- Initial release: 4-stage Double Diamond pipeline (Discover/Define/Develop/Deliver)
- SpecParser: reads specification markdown documents
- RequirementDecomposer: LLM-based requirement extraction
- CodeGenerator: LLM-based code and test generation
- QualityGate: satisfaction scoring (completeness, correctness, quality, security)
- PipelineRunner: orchestrates stages with resumable state persistence
- Factory runner entry points: run_pipeline, pipeline_status
