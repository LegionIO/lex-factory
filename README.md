# lex-factory

Spec-to-code autonomous pipeline for LegionIO. Takes a specification document and produces working code with tests through a 4-stage Double Diamond pipeline.

## Pipeline Stages

1. **DISCOVER** - Parse spec, identify unknowns, research patterns
2. **DEFINE** - Decompose into tasks, define interfaces, plan tests
3. **DEVELOP** - Generate code for each task, run tests
4. **DELIVER** - Score quality, produce summary

## Usage

```ruby
result = Legion::Extensions::Factory::Runners::Factory.run_pipeline(spec_path: 'path/to/spec.md')
```

## Configuration

```yaml
factory:
  satisfaction_threshold: 0.8
  output_dir: tmp/factory
  max_retries_per_stage: 2
```

## License

MIT
