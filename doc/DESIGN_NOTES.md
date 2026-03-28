# Design Notes

Non-obvious design decisions, constraints, and assumptions in mp3info.

## ID3v2.3 as default output version

`DEFAULT_MAJOR_VERSION = 3` in `id3v2.rb`.

ID3v2.3 is the most widely supported version across players and hardware.
ID3v2.4's key change — synchsafe frame sizes — is incorrectly implemented by
many real-world taggers, producing tags that claim to be v2.4 but use
non-synchsafe sizes. The `unsynchronized_tag?` heuristic exists specifically to
detect these broken tags. By defaulting to v2.3, we avoid the synchsafe frame
size problem entirely. When reading an existing tag, `@write_version` is set
from the parsed version, so existing v2.4 tags stay v2.4.

## No tag-level unsynchronization on v2.3 write

In v2.3, unsynchronization is a tag-level operation that transforms the
**entire** tag body — including frame headers and their size fields. After
unsync, the stored frame sizes become incorrect. The reader must de-unsync the
whole body before parsing frames. Many readers don't handle this correctly,
causing the entire tag to be misinterpreted.

In v2.4, unsync is per-frame: only the frame body is transformed, and the
frame size reflects the post-unsync size. This is clean and reversible.

We apply per-frame unsync on v2.4 write only. No tag-level unsync is applied
on v2.3 write. This matches the behavior of id3lib, mutagen, and eyeD3.
Modern players parse tags by declared size, not by sync scanning, so unsync
is unnecessary in practice.

## Synchsafe integers vs unsynchronization

The ID3v2 spec defines two separate mechanisms for preventing false MPEG sync
pattern detection. They solve the same problem but apply to different parts of
the tag.

**Synchsafe integers** keep bit 7 of each byte zeroed (7 usable bits per byte).
Used only for size descriptors: tag header size, extended header size, frame
sizes (v2.4), data length indicator, CRC-32. **Not used for frame body data.**

**Unsynchronization** inserts `0x00` after `0xFF` bytes that could form false
sync patterns. This changes the data length, which is why size fields can't use
it (chicken-and-egg: you'd need the unsync'd size before writing, but can't
compute it without writing first).

Reference: [ID3v2.4.0 structure, sections 6.1 and 6.2](https://id3.org/id3v2.4.0-structure)

Frame body data (RVA2 adjustments, APIC pictures, text) can and does contain
`0xFF` bytes. This is normal binary data, not synchsafe-encoded. The library
applies per-frame unsync on v2.4 write to protect these bytes.

## `[]` vs `frames()` — the dual frame access API

Frames are always stored as arrays internally. `[]` unwraps single-element
arrays (returning a bare frame object), while `frames()` always returns the raw
array. `each` and `values` also unwrap.

This exists for backward compatibility: existing code does `tag["TIT2"].value`
rather than `tag["TIT2"].first.value`. The `frames()` method is the "correct"
API when you need to handle multi-frame keys uniformly.

## `write_mpeg_file!` reads tag size from the header

When rewriting a file (to update ID3v2 tags), the writer needs to locate where
audio data begins. The original approach used `find_next_frame` (MPEG sync
scanning), but the frame-following validation could reject valid early frames
that weren't followed by another frame at the expected offset — for example,
Xing/LAME info frames or frames preceded by padding bytes. This caused audio
data loss on round-trip.

The fix: read the ID3v2 tag's declared size directly from its header
(`skip_id3v2_tag`) and copy everything after it. The tag knows its own size;
no scanning needed.

## Frame-following validation in `find_next_frame`

When scanning for the first MPEG frame, `0xFF` bytes followed by `0xE0+` are
common in binary data (ID3v2 tags, album art, etc.). Without validation, the
parser locks onto false sync matches inside non-audio data.

`frame_follows?` checks that a candidate frame is followed by another valid
sync pattern at exactly `position + frame_size`. If no candidate has a valid
follower (e.g., near EOF), the method falls back to the first valid-looking
candidate.

## Composition over DelegateClass(Hash)

Both `ID3` and `ID3V2` wrap an internal `@hash` with explicitly delegated
methods (`[]`, `[]=`, `keys`, `size`, `each`, etc.) rather than inheriting
from `DelegateClass(Hash)`.

`DelegateClass(Hash)` exposes the full Hash API, allowing callers to bypass
`[]=` and store raw values that violate internal invariants (e.g., ID3V2
requires all values to be arrays of Frame objects). Composition controls
exactly which operations are permitted.

## Frame flags: parsed but not preserved on round-trip

Frame flags (compression, encryption, grouping, per-frame unsync) are fully
parsed during read: compressed frames are decompressed, encrypted frames are
skipped, grouping bytes and data length indicators are consumed. However,
`encode_frame` writes fresh flags rather than preserving originals.

This is correct because: encrypted frames are skipped on read (nothing to
round-trip), compressed frames are stored decompressed (re-compressing with
unknown parameters is unreliable), and per-frame unsync is recomputed based
on actual content.

## The `unsynchronized_tag?` heuristic

Detects v2.4 tags with non-synchsafe frame sizes (a common bug in many
taggers). Walks frame headers assuming synchsafe sizes and checks each 4-byte
size field for high bits. If any byte has bit 7 set, the tag has non-synchsafe
sizes and frame parsing switches to plain big-endian.

Failure modes: for sizes < 128, synchsafe and non-synchsafe produce identical
values, so misdetection is impossible for small frames. False positives cannot
occur (a high bit is definitively not synchsafe). Corrupt tags may cause the
walk to go off the rails, guarded by the `break unless size_string.size == 4`
check.

## ID3V24 module name vs version handling

The module is named `ID3V24` but handles frames from all versions (2.2, 2.3,
2.4). The name reflects that the class hierarchy was designed around the v2.4
spec (the most complete). Backward compatibility is handled via alias
subclasses: `TXXFrame < TXXXFrame`, `COMFrame < COMMFrame`,
`PICFrame < APICFrame`, etc. The `Frame.find_class` method looks up
`"#{type}Frame"`, so a v2.2 `COM` frame finds `COMFrame`, which inherits all
behavior from `COMMFrame`.

## File layout assumptions

- **ID3v2 at the start:** the parser checks for "ID3" at position 0. Multiple
  ID3v2 tags are merged if found.
- **ID3v1 at the end:** fixed 128-byte position from EOF per spec.
- **APE tags before ID3v1:** the detector adjusts search position for ID3v1.
- **Lyrics3 before ID3v1:** same adjustment.
- **Audio data is contiguous** between the ID3v2 tag and trailing tags. The
  `streamsize` calculation subtracts tag sizes from file size. Mid-file gaps
  are not accounted for in duration calculation (but are detected by
  `StreamValidator`).
- **Only the first MPEG frame header matters** for `Mp3Info` metadata. Stream
  consistency (version/layer/sample rate across all frames) is checked by
  `StreamValidator`, not by `Mp3Info`.

## Error recovery strategy

- **ID3v2 parse errors:** caught and logged as warnings. The file can still be
  processed for MPEG data and ID3v1 tags.
- **Individual frame parse errors:** the frame is skipped; parsing continues.
- **Encrypted frames:** silently skipped (we can't decrypt them).
- **Zlib decompression failures:** frame skipped with warning.
- **MPEG frame search failure:** non-fatal; allows tag-only files.
- **Invalid frame names:** terminate frame parsing (padding at end of tag).
- **Non-synchsafe tag length:** fatal (`ID3V2Error`). This is the one
  structural check that cannot be worked around.
- **No useful metadata at all:** fatal (`Mp3InfoError`). Prevents operating on
  non-MP3 files.

## `changed?` tracking

Both `ID3` and `ID3V2` compare `@hash` against `@hash_orig` (a snapshot taken
after construction or after reading from binary). If they differ, the tag is
re-serialized on `close`. If unchanged, `to_bin` returns the cached `@raw_tag`
to avoid unnecessary re-serialization.

For ID3, `sync_bin` (private) updates `@hash_orig` after writing, preventing
redundant writes on subsequent `close` calls.

## `@write_version` vs `major_version`

`major_version` reads the version byte from the parsed tag header. It reflects
what was **read**. `@write_version` controls what version to **write**. These
can differ: a user might read a v2.3 tag and write it as v2.4, or vice versa.
`encode_frame` and `to_bin` use `@write_version` to determine encoding format
(synchsafe vs plain sizes, per-frame unsync). Using `major_version` would
produce corrupt output when the write version differs from the read version.
