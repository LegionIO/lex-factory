# Changelog

## [0.1.0] - 2026-03-24

### Added
- Initial release: 4-stage Double Diamond pipeline (Discover/Define/Develop/Deliver)
- SpecParser: reads specification markdown documents
- RequirementDecomposer: LLM-based requirement extraction
- CodeGenerator: LLM-based code and test generation
- QualityGate: satisfaction scoring (completeness, correctness, quality, security)
- PipelineRunner: orchestrates stages with resumable state persistence
- Factory runner entry points: run_pipeline, pipeline_status
