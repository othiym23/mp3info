# CLAUDE.md

## Build & Test

- `rake` runs both `rspec` (tests) and `standard` (linting). Run this before every commit.
- If `standard` reports formatting errors, run `standardrb --fix` to auto-format, then re-run `rake` to confirm.
- `mise exec -- ruby` or just `ruby` (if ~/.bashrc activates mise) to run Ruby 4.
- `rspec spec/path/to/spec.rb` to run a single spec file.
- `rspec spec/path/to/spec.rb:42` to run a single test by line number.

## Code Style

- Standard Ruby (`standardrb`) enforces all formatting. No additional style config.
- Double-quoted strings, 2-space indentation, no trailing whitespace.
- Use `require_relative` for internal requires, not `require` with load path manipulation.
- Binary conversion methods (`to_binary_array`, `to_binary_decimal`, etc.) are refinements — files that need them must have `using Mp3InfoLib::BinaryConversions` at the top level.
- Same for size formatting: `using Mp3InfoLib::SizeUnits`.

## Architecture

- `Mp3Info` is the main entry point. It reads MPEG headers, Xing/VBRI/LAME headers, ID3v1/v2 tags, APE tags, and Lyrics3 tags.
- `MPEGStream` iterates over individual MPEG frames. `StreamValidator` walks all frames and produces a validation report.
- ID3v2 frames are always stored as arrays internally; `[]` unwraps single-element arrays for backward compatibility; `frames(key)` returns the raw array.
- Default ID3v2 output version is v2.3 (best interop). Set `id3v2_tag.write_version = 4` for v2.4.
- `MPEGFile` module methods are private on all including classes — never expose them publicly.
