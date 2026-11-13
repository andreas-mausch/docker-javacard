# SmartPGP (OpenPGP)

<https://github.com/github-af/SmartPGP>

> SmartPGP is a JavaCard implementation of the OpenPGP card specifications

AID: `D27600012401`

Installation notes:

Define the right AID at install using `--create` to assign a Serial Number:
[Setting serial number? #52](https://github.com/github-af/SmartPGP/issues/52)

```bash
gp --install ./SmartPGP-v1.22.2-jc304-rsa_up_to_4096.cap --create D276000124010304AFAF123456780000
```

The AID is composed like this:

<https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-2.0.pdf>

- RID (5 bytes): `D2 76 00 01 24`
- Application / PIX (1 byte): `01`
- Version (OpenPGP 3.4): `03 04`
- Manufacturer (2 bytes): `AFAF`
- Serial number (4 bytes): `12 34 56 78`
- RFU (reserved, 2 bytes): `00 00`

- RID: *Registered application provider identifier (unique identification of FSFE), ISO 7816-5*.
- PIX: Proprietary application identifier extension
- RFU: *Reserved for Future Use*.

You can generate your own custom 4 bytes for the serial number using this command:

```bash
cat /dev/random | head -c 4 | xxd -p -u
```

## Harden for production use

### Change the User PIN, PUK and Admin PIN

The default User PIN is `123456`, the default Admin PIN is `000000`.
Change them via `gpg --card-edit`, followed by `admin` and `passwd`.

A blocked User PIN can be reset two ways: with the reset code (PUK), or
with the Admin PIN (`RESET RETRY COUNTER` with admin verification — this is
what `gpg --card-edit` → `admin` → `passwd` does). A reset code is still
worth setting: it unblocks the User PIN *without* exercising the Admin PIN,
which also guards key import, key deletion and certificate changes. Without
both, three wrong User-PIN tries are a dead end (applet reinstall only).

### Enable Secure Messaging (SM)

SmartPGP implements the OpenPGP 3.x Secure Messaging: a static ECDH key on
the card plus ephemeral session keys, after which APDUs are encrypted (`87`
cryptogram) and MAC-protected (`8E`). This is what closes the "PIN travels in
plaintext APDUs" gap flagged in the `General` warning of [README.md](./README.md).

Behavior verified against upstream master (Nov 2026):

- The SM key lives alongside the three PGP keys: generated via
  `GENERATE ASYMMETRIC KEY PAIR` (or imported via `PUT DATA`) with the SM key
  CRT (`0xa6`); related DOs are `0xD4` (SM algorithm attributes) and `0xFB`
  (SM certificate).
- Once the SM key exists, SM is **enforced**: the applet rejects unprotected
  APDUs with `SW_SECURITY_STATUS_NOT_SATISFIED`.
- Recent gpg/scdaemon versions negotiate SM transparently when the card has
  an SM key, so the PIN then crosses the wire encrypted. Verify this yourself
  rather than trusting it: log the APDUs (e.g. `pcscd`
  `SCARD_DEBUG_READER=1` or `gpg --debug-ccid-driver`) — protected commands
  show `87`/`8E` DOs instead of the PIN in the clear.
- Upstream guide for setting SM up (incl. on-board key generation and token
  authentication against MITM, via OpenKeychain):
  <https://github.com/github-af/SmartPGP#setting-up-secure-messaging-with-openkeychain>

### Enable KDF

By default the card stores the PINs in recoverable form and compares them
directly. SmartPGP implements the OpenPGP 3.x Key Derivation Function
(DO `0xF9`): with KDF enabled, the terminal sends derived hashes instead of
the PINs, and the card stores only those — iterated and salted with the
card's own AID, which includes its serial number.

```bash
gpg --card-edit
# then, in the card-edit prompt:
admin
kdf on
```

What it buys you:

- A dump of the card memory no longer yields directly usable PINs.
- The stored hashes are bound to this card's serial: replaying a dump on
  another (cloned) card fails.
- Offline guessing of a captured/extracted hash costs the iteration factor.

Caveats:

- It cannot be disabled again over the card API — clearing it means
  reinstalling the applet (with the data loss that comes with it).
- Existing PINs are reset to their defaults and existing keys become
  unusable. Enable KDF *before* generating keys; if you enable it later,
  change all PINs again and regenerate keys.
- KDF is *passive* protection only: it protects neither the transport
  (the derived hash becomes the secret on the wire — see the Secure Messaging
  section above) nor against guessing (it adds no retry counter).

### Retry counters are fixed

The retry counters (3 × user PIN, 3 × reset code/PUK, 3 × admin PIN) are
compile-time constants in `Constants.java` passed to `OwnerPIN`. There is
no install parameter for them (`install()` ignores parameters) and no
runtime change: the OpenPGP 3.x DOs `7F2C`/`7F2D` via `PUT DATA` are not
implemented. The only way to change them: edit `Constants.java`, rebuild
the CAP and reinstall — which wipes keys and resets PINs to defaults.
Verified against upstream master (Nov 2026).

Then generate your personal keys and use them.
