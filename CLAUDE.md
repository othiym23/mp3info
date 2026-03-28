# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

- **`rake`** — runs both `rspec` and `standard` (linting). Run this before every commit.
- **`standardrb --fix`** — auto-format if `standard` reports violations, then re-run `rake`.
- **`rspec spec/path/to/spec.rb`** — run a single spec file.
- **`rspec spec/path/to/spec.rb:42`** — run a single test by line number.
- Ruby version managed via mise. Ruby 4.0+ required.

## Architecture

**Entry point:** `Mp3Info` (lib/mp3info.rb) is the primary class. It parses an MP3 file in a single pass through `initialize`, reading ID3v2 tags, MPEG frame headers, Xing/VBRI/LAME headers, and ID3v1 tags.

**Tag classes (lib/mp3info/id3.rb, id3v2.rb):** `ID3` and `ID3V2` are Hash-like objects using composition (not DelegateClass). They expose `[]`, `[]=`, `keys`, `each`, etc. ID3V2 stores frames as arrays internally; `[]` unwraps single-element arrays for backward compatibility while `frames(key)` always returns the raw array.

**Frame classes (lib/mp3info/id3v2_frames.rb):** All in the `ID3V24` module. `Frame.create_frame(type, value)` is the factory method. Frame subclasses handle encoding/decoding for text (TextFrame), comments (COMMFrame), pictures (APICFrame), replay gain (RVA2Frame, RVADFrame via BaseVolumeAdjustmentFrame), etc.

**Binary conversion (lib/mp3info/binary_conversions.rb):** Refinements on String, Array, Integer for binary↔decimal conversion, synchsafe encoding. Must be activated with `using Mp3InfoLib::BinaryConversions` at file top level. Same pattern for `Mp3InfoLib::SizeUnits`.

**MPEG internals (lib/mp3info/mpeg_utils.rb):** The `MPEGFile` module provides `write_mpeg_file!`, `find_next_frame`, `skip_id3v2_tag`. These methods are **private** on all including classes — never make them public.

**Stream analysis (lib/mp3info/mpeg_stream.rb, stream_validator.rb):** `MPEGStream#each_frame` iterates every MPEG frame. `StreamValidator#validate` walks all frames and returns a `ValidationReport` with errors, warnings, frame count, duration, bitrate analysis.

## Key Design Decisions

- **ID3v2.3 output by default.** Most players don't fully support v2.4. Set `id3v2_tag.write_version = 4` for v2.4 output. Frame sizes are synchsafe for v2.4, plain big-endian for v2.3.
- **Per-frame unsynchronization** is applied on v2.4 write only. v2.3 tag-level unsync is not applied on write (matches id3lib, mutagen, eyeD3 behavior).
- **`write_mpeg_file!` skips the ID3v2 tag by reading its size** from the header, not by scanning for MPEG sync. This prevents audio data loss.
- **Frame flags** are fully parsed for v2.3 and v2.4: compression (zlib decompressed), encryption (skipped), grouping, per-frame unsync, data length indicator.
- **Extended headers** are parsed for both v2.3 (CRC, padding) and v2.4 (CRC, restrictions, update flag).
- **Error recovery:** Bad frames are skipped with warnings rather than aborting the parse. Bad ID3v2 tags don't prevent reading MPEG headers and ID3v1 tags.

## Code Style

- Standard Ruby (`standardrb`) enforces all formatting. No additional config.
- Use `require_relative` for internal requires.
- Refinements (`using`) must be at file top level, not inside class/module bodies.
- The refinement namespace is `Mp3InfoLib` (not `Mp3Info`, which is the main class).
