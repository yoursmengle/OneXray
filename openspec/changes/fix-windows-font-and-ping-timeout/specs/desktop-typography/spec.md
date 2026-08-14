## Purpose

Keeps desktop, especially Windows, labels and list rows complete when display scale or CJK fallback would otherwise enlarge text and clip content.

## ADDED Requirements

### Requirement: Desktop text remains complete at common Windows scale

The system MUST render page titles, list row titles, supporting lines, badges, and navigation labels in full on desktop Windows at 100%–150% display scale without adding a user-facing font-size setting. Text that is longer than its row MUST ellipsize rather than overflow or drop trailing glyphs.

#### Scenario: Windows host at typical display scale

- **WHEN** the user opens Home or a node list on Windows at 100%–150% display scale
- **THEN** node names, delay text, and subscription titles remain visible in their rows without being cut off mid-character

#### Scenario: Long node name

- **WHEN** a list row title is longer than the available width
- **THEN** the title ellipsizes and the delay or status badge stays on the same row

### Requirement: Windows accessibility text scale is bounded

On desktop, the system MUST clamp the applied text scaler so OS “make text bigger” settings cannot enlarge app type enough to hide row content. Users MUST still be able to use a modest scale above 1.0.

#### Scenario: Large Windows text size

- **WHEN** the OS text scale is greater than the app clamp
- **THEN** the app uses the clamp and list rows still show title plus delay or status

### Requirement: CJK fallback does not inflate dense rows

Windows CJK fallback fonts MUST be used for glyphs missing from Geist, and MUST NOT increase dense row line height enough to clip the second line or badge.

#### Scenario: Chinese node name on Windows

- **WHEN** a list row title contains Chinese characters
- **THEN** the glyphs render with the Windows fallback family and the row still shows the title and supporting line without vertical clipping
