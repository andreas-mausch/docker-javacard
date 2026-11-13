# TODOs

- [ ] **SmartPGP: retry counters are compile-time only** — *partly done*:
      documented in `docs/favorite-applets/SmartPGP.md` (section "Retry
      counters are fixed"); remaining: mark the values as "fixed" in the
      `docs/favorite-applets/README.md` table.
      (retry counters 3 × user PIN / 3 × PUK / 3 × admin PIN are hardcoded
      `Constants.java` values passed to `OwnerPIN`: no install params
      (`install()` ignores them) and no runtime change (OpenPGP 3.x DOs
      `7F2C`/`7F2D` via `PUT DATA` are not implemented). Only way to change:
      edit `Constants.java`, rebuild CAP, reinstall — wipes keys, PINs reset
      to defaults. Verified in upstream source, Nov 2026.)
- [ ] **ykneo-oath fork: stretched, card-individual KDF for the access
      code** — today the access code is used as a *raw HMAC key*, so the
      stored secret is the code verbatim. Derive it with an iterated KDF
      salted by the card's serial (model: OpenPGP KDF DO `0xF9` as
      implemented by SmartPGP — bound hashes, iteration factor), so memory
      dumps yield no usable secret and replay on a cloned card fails.
      Defense-in-depth only: KDF is *not* transport protection (the derived
      hash would be the wire secret — see the KDF section in
      `docs/favorite-applets/SmartPGP.md`) and adds no retry counter, so
      the PAKE and OwnerPIN items remain required.
- [ ] **TOTP (ykneo-oath): fork to use a real `OwnerPIN` with retry counter** —
      the applet currently has *no* brute-force protection for the access code
      (no retry counter, no lockout, raw HMAC key, non-constant-time compare;
      see `docs/favorite-applets/TOTP.md`). A fork should store the access-code
      verification behind a `javacard.framework.OwnerPIN` (persistent retry
      counter, lockout after N wrong tries) instead of the transient byte with
      unlimited guesses.
- [ ] **Add secure messaging to the applets that lack it** — without SM,
      secrets (PINs via `VERIFY`, imported keys) travel in plaintext APDUs
      over PC/SC, where the untrusted host can sniff or inject them; card-side
      `OwnerPIN` does not help against this (transport vs. storage are
      independent layers). See the "General" warning in
      `docs/favorite-applets/README.md`; note GP SCP only secures the `gp`
      management channel, never applet APDUs. Not supported today:
      - [ ] **PivApplet** — no SM at all: no `MSE`, `C-MAC` or `C-DECRYPTED`
            anywhere in the source; implement the optional Secure Messaging
            extension of NIST SP 800-73 (ISO 7816-4 secure messaging with `87`
            cryptogram + `8E` MAC, ephemeral ECDH session keys, SM certificate
            in slot `0xF9`), as real PIV tokens like the YubiKey do, so
            OpenSC-compatible clients (e.g. `verify_use_sm`) benefit
      - [ ] **ykneo-oath (TOTP)** — no SM, and the raw-HMAC VALIDATE leaks
            offline-brute-forceable material to any eavesdropper (see item
            above), so plain SM around it is not enough: replace the access
            code handshake with a PAKE — PACE with ECDH Generic Mapping
            (ISO/IEC 18013-3 / BSI TR-03110) is the proven choice (every
            ePassport uses it; card side implementable with standard JavaCard
            ECDH primitives). FOSS stack on the terminal side: OpenPACE
            (GPL-3.0), Open eCard (GPL-3.0), javacard-express (Apache-2.0,
            PACE + ISO 7816-4 SM, built for jCardSim). SPAKE2+ would be the
            minimal alternative but has proof baggage (SPAKE2* withdrawal).
            PACE session keys then feed ISO 7816-4 SM (`87`/`8E`), and the
            access code moves behind an `OwnerPIN` retry counter (first item)
