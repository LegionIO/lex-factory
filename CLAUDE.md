# lex-factory: Spec-to-Code Pipeline

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Spec-to-code generation pipeline for LegionIO. Parses a spec document (markdown), extracts structured requirements through a Double Diamond four-stage process (discover, define, develop, deliver), scores output through a weighted quality gate, and persists resumable pipeline state to disk.

## Gem Info

- **Gem name**: `lex-factory`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Factory`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/factory/
  version.rb
  factory.rb                          # Entry point
  pipeline_runner.rb                  # PipelineRunner class — 4-stage Double Diamond, resumable state
  helpers/
    constants.rb                      # STAGES, SCORE_WEIGHTS, DEFAULT_SATISFACTION_THRESHOLD, DEFAULT_MAX_RETRIES, DEFAULT_OUTPUT_DIR
    spec_parser.rb                    # SpecParser module — parse, extract_title, extract_sections, extract_code_blocks
    quality_gate.rb                   # QualityGate module — score(completeness:, correctness:, quality:, security:)
  runners/
    factory.rb                        # run_pipeline(spec_path:, output_dir:), pipeline_status(output_dir:)
spec/
  legion/extensions/factory/
    helpers/
      spec_parser_spec.rb
      quality_gate_spec.rb
    runners/
      factory_spec.rb
    pipeline_runner_spec.rb
    client_spec.rb
```

## Four Stages (Double Diamond)

| Stage | What Happens |
|-------|--------------|
| `discover` | Parse the spec file: extract title, H2 sections, bullet items, and code blocks |
| `define` | Map each extracted bullet item to a task with `{ id:, requirement:, status: :pending }` |
| `develop` | Mark all tasks `:completed` (stub; real implementation delegates to LLM) |
| `deliver` | Compute completeness ratio, run QualityGate, produce summary |

## PipelineRunner

- `initialize(spec_path:, output_dir:, threshold:, max_retries:)` — reads `factory_settings` from `Legion::Settings[:factory]` for defaults
- `run` — iterates `STAGES`, skips already-completed stages (resumable), saves state after each stage
- State persisted to `<output_dir>/pipeline_state.json` as JSON; symbols serialized to strings and restored on load
- `status` — returns `{ spec_path:, output_dir:, current_stage:, completed_stages: }`

## QualityGate

`score(completeness:, correctness:, quality:, security:, threshold:)` returns:
```ruby
{ pass: true/false, aggregate: 0.0–1.0, threshold: 0.8, scores: { completeness:, correctness:, quality:, security: } }
```

Score weights: `completeness 0.35`, `correctness 0.35`, `quality 0.20`, `security 0.10`.

All four dimensions are clamped to `[0.0, 1.0]` before weighting.

## SpecParser

Parses a markdown file into:
- `title` — first H1 line
- `sections` — array of `{ heading: "H2 text", items: ["bullet 1", "bullet 2"] }`
- `code_blocks` — array of `{ language: "ruby", code: "..." }`

`parse_sections` only captures items from `##` headings (not `###` or deeper). Items must be `- ` or `* ` prefixed.

## Constants

```ruby
STAGES                        = %i[discover define develop deliver]
SCORE_WEIGHTS                 = { completeness: 0.35, correctness: 0.35, quality: 0.20, security: 0.10 }
DEFAULT_SATISFACTION_THRESHOLD = 0.8
DEFAULT_MAX_RETRIES           = 2
DEFAULT_OUTPUT_DIR            = 'tmp/factory'
```

## Settings

```yaml
factory:
  output_dir: tmp/factory         # where pipeline state and artifacts are written
  satisfaction_threshold: 0.8     # minimum aggregate QualityGate score to pass
  max_retries_per_stage: 2        # retry budget per stage on failure
```

## Development Notes

- `PipelineRunner` uses `::File`, `::FileUtils`, and `::JSON` with `::` prefix to avoid namespace collision inside `Legion::`
- `serialize_context` recursively converts Symbol keys/values to strings for JSON round-trip
- The `develop` stage is currently a stub that marks all tasks `:completed` immediately — real implementation would delegate to `legion-llm` or `lex-codegen`
- `module_function` is used on `SpecParser` and `QualityGate` so both are callable as `Module.method(...)`
- `private_class_method` is used on internal helpers to keep the public API clean

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
