# Design Notes

## Synchsafe integers vs unsynchronization

The ID3v2 spec defines two separate mechanisms for preventing false MPEG sync
pattern detection within tag data. They solve the same problem but apply to
different parts of the tag.

### Synchsafe integers (for size fields)

Synchsafe integers keep bit 7 of each byte zeroed, using only 7 bits per byte.
A 32-bit synchsafe integer stores 28 bits of information. This guarantees no
byte in the encoded value is `0xFF`, so no false sync pattern can appear.

Used for:
- Tag header size (10-byte header, bytes 6-9)
- Extended header size (v2.4 only)
- Frame header size (v2.4 only; v2.3 uses plain big-endian)
- Data length indicator (v2.4 frame flag)
- CRC-32 (stored as 35-bit synchsafe in v2.4 extended header)

**Not used for frame body data.**

Reference: [ID3v2.4.0 structure, section 6.2](https://id3.org/id3v2.4.0-structure)

> "In some parts of the tag it is inconvenient to use the unsynchronisation
> scheme because the size of unsynchronised data is not known in advance, which
> is particularly problematic with size descriptors. The solution in ID3v2 is to
> use synchsafe integers, in which there can never be any false synchs."

### Unsynchronization (for body data)

Unsynchronization inserts `0x00` after any `0xFF` byte that is followed by a
byte >= `0xE0` or `0x00`. This prevents the byte sequence `0xFF 0xE0`–`0xFF 0xFF`
from appearing in the data, which would look like an MPEG sync pattern to a
naive parser.

This changes the data length, which is why size fields cannot use this scheme
(you'd need to know the unsynchronized size before writing it, but you can't
compute it without first writing the data — a chicken-and-egg problem).

- In v2.3: applied at the tag level (all frame data, including frame headers
  within the tag body). The tag-level unsync flag in byte 5 of the header
  indicates this. Frame sizes store the pre-unsync values.
- In v2.4: applied per-frame (bit 1 of the frame format flags byte). Frame
  sizes store the post-unsync values. The tag-level flag is informational.

Reference: [ID3v2.4.0 structure, section 6.1](https://id3.org/id3v2.4.0-structure)

### Implications for this library

Frame body data (e.g., RVA2 adjustment values, APIC picture data, text content)
can and does contain `0xFF` bytes. This is normal — they are ordinary binary
data, not synchsafe-encoded. If false sync protection is needed, it is provided
by unsynchronization, not by synchsafe encoding.

This means binary values like `\xFF\xFF` in RVA2 adjustment fields are correct
and expected. The library applies per-frame unsynchronization on v2.4 write to
protect these bytes from being misinterpreted as MPEG sync patterns.
