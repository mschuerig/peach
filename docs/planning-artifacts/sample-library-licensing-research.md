# Instrument Sample Library Licensing Research

**Date:** 2026-02-18
**Purpose:** Evaluate candidate sample libraries for future NotePlayer implementation
**Status:** Research complete, no selection finalized yet

## Summary

| Library | License | Commercial Use | Attribution Required | Redistribution (raw) | Risk Level |
|---|---|---|---|---|---|
| VCSL | CC0 (Public Domain) | Yes | No | Unrestricted | None |
| FluidR3 | MIT | Yes | Yes (copyright notice) | Yes (in entirety, free) | None |
| Philharmonia Orchestra | CC-BY-SA 3.0 | Yes | Yes | No ("as is" prohibited) | Low-Medium |
| U of Iowa MIS | Custom ("no restrictions") | Yes | Not stated | Unclear | Medium-High |
| Sonatina Symphonic Orchestra | CC Sampling Plus 1.0 | Derivatives only | Yes | Noncommercial only | High |
| GeneralUser GS | Custom v2.0 | Yes | Requested | With conditions | High |

## Tier 1 — Recommended (no friction)

### Versilian Community Sample Library (VCSL)

- **License:** CC0-1.0 (Creative Commons Zero / Public Domain Dedication)
- **Creator:** Versilian Studios LLC
- **Links:** [GitHub](https://github.com/sgossner/VCSL) · [Website](https://versilian-studios.com/vcsl/)
- **Terms:** Effectively public domain. No royalties, no credit, no restrictions. May be used in commercial software, modified, and redistributed without limitation.
- **Risks:** None.

### FluidR3 SoundFont

- **License:** MIT License
- **Creator:** Frank Wen (Copyright 2000-2002, 2008)
- **Links:** [GitHub](https://github.com/Jacalz/fluid-soundfont) · [License text](https://github.com/musescore/MuseScore/blob/master/share/sound/FluidR3Mono_License.md)
- **Terms:** Standard MIT — use, copy, modify, merge, publish, distribute, sublicense, sell. Must include copyright notice in all copies.
- **Author's additional wishes (non-binding):** If bundled commercially with software, the design should allow users to load any soundfont with full access to all instruments.
- **Risks:** None significant.

## Tier 2 — Usable with care

### Philharmonia Orchestra Samples

- **License:** CC-BY-SA 3.0 Unported
- **Creator:** Philharmonia Orchestra (recorded at Abbey Road Studio 2)
- **Links:** [Website](https://philharmonia.co.uk/resources/sound-samples/) · [GitHub mirror](https://github.com/skratchdot/philharmonia-samples)
- **Terms:** Free to use including commercially. Attribution required. ShareAlike — derivative works must use the same or compatible license.
- **Restrictions:** Must not be sold or redistributed "as is" (raw sample pack). Only as part of a larger creative work.
- **Note:** Often mislabeled as "London Philharmonic Orchestra" samples — it's the Philharmonia Orchestra, a different London ensemble.
- **Risks:** ShareAlike clause means modified versions of the samples themselves must remain CC-BY-SA. An app that *plays* the samples is fine — the app code can use a different license. But the boundary should be documented clearly.

## Tier 3 — Not recommended

### University of Iowa Musical Instrument Samples (MIS)

- **License:** Custom (no formal license document)
- **Creator:** Lawrence Fritts, University of Iowa Electronic Music Studios
- **Links:** [Website](https://theremin.music.uiowa.edu/MIS.html)
- **Terms:** Website states samples "may be downloaded and used for any projects, without restrictions." Available since 1997.
- **Why not recommended:** No formal license document (no CC0, no MIT, no explicit public domain dedication). Website statement is not legally robust. For certainty, would need to contact Lawrence Fritts (lawrence-fritts@uiowa.edu).

### Sonatina Symphonic Orchestra (SSO)

- **License:** Creative Commons Sampling Plus 1.0
- **Creator:** Mattias Westlund
- **Links:** [GitHub](https://github.com/peastman/sso)
- **Terms:** May sample/transform for commercial or noncommercial use. Whole unmodified work: noncommercial distribution only. Attribution required.
- **Why not recommended:** The CC Sampling Plus license was **retired by Creative Commons in 2011** and is no longer recommended for new works. Using a deprecated license signals the ecosystem has moved on.

### GeneralUser GS SoundFont

- **License:** Custom ("GeneralUser GS License v2.0")
- **Creator:** S. Christian Collins
- **Links:** [Website](https://schristiancollins.com/generaluser.php) · [GitHub](https://github.com/mrbumpy409/GeneralUser-GS)
- **Terms:** Free for personal or commercial music creation. May modify the bank.
- **Why not recommended:** The author acknowledges he "cannot be 100% sure where all of the samples originated" since the project started in 2000 as a personal project. Some samples were taken from other freely available SoundFont banks with unclear provenance. **Sample origin uncertainty = IP risk.**

## Recommendation

**Start with VCSL (CC0) and FluidR3 (MIT)** for the cleanest legal foundation. Add Philharmonia Orchestra samples (CC-BY-SA 3.0) later if orchestral depth is needed, with proper attribution documentation.

## Implications for Peach Licensing

A multi-license approach is standard for projects mixing code and assets:

- **Source code** → software license (e.g., MIT) in top-level `LICENSE` file
- **Third-party assets** → documented in `NOTICE` or `THIRD-PARTY-LICENSES` file
- **README** → brief section noting that code and assets may have separate licenses, with pointers to details
