# List of AIDs

[Complete list of application identifiers (AID)](https://emv.cool/2020-12-23/Complete-list-of-application-identifiers-AID/)

# My favorite applets

Here is a list of my personal favorite applets I like to use.

| Name                             | AID                    | Description                                                                                     | PIN retries                                                        | Link                                                |
|----------------------------------|------------------------|-------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|-----------------------------------------------------|
| [SmartPGP](./SmartPGP.md)        | `D27600012401`         | OpenPGP card: protects PGP private keys used for signing, decryption and login                  | 3 × user PIN (PW1), 3 × reset code/PUK, 3 × admin PIN (PW3)        | <https://github.com/github-af/SmartPGP>             |
| [NDEF](./NDEF.md)                | `D2760000850101`       | Emulates a plain NFC tag (URL, contact card, text). Protects nothing                            | none (no PIN mechanism at all)                                     | <https://github.com/OpenJavaCard/openjavacard-ndef> |
| [TOTP](./TOTP.md)                | `A0000005272101`       | Stores 2FA secrets (TOTP/HOTP) used to generate login one-time codes                            | **∞ unlimited** ⚠️ no retry counter at all                          | <https://github.com/Yubico/ykneo-oath>              |
| [PivApplet](./PivApplet.md)      | `A000000308000010000100` | PIV smart card: protects private keys/certificates, e.g. a root CA key used for signing         | 5 × PIN, 3 × PUK (PIN retries changeable via `INS 0xFA`)           | <https://github.com/arekinath/PivApplet>            |
| [FIDO2](./FIDO2.md)              | `A0000006472F0001`     | WebAuthn/passkeys: protects login credentials for websites                                      | 8 × PIN (fixed)                                                    | <https://github.com/BryanJacobs/FIDO2Applet>        |

> **⚠️ Warning: several of these applets have serious security weaknesses.**
> They are community projects, not certified secure elements. All of the points
> below were verified against the applet source code (November 2026):
>
> - **TOTP (ykneo-oath)**: The access code has **unlimited guesses** — no retry counter,
>   no lockout, and the code is used as a raw HMAC key (no KDF). Eavesdropping on one
>   legit session leaks a `(challenge, response)` pair that allows brute-forcing the code
>   **offline**, and the response check is not constant-time. Without an access code every
>   operation is unauthenticated, and `RESET` wipes the applet without any authentication.
>   Details: [TOTP.md](./TOTP.md#security-note-the-access-code-has-unlimited-guesses).
> - **FIDO2Applet**: There is **no user-presence check**: the user is "always considered
>   present" because a JavaCard cannot read a touch button. Malware on the host can silently
>   sign as long as the card sits in the reader. Credentials can be created and used without
>   a PIN unless the relying party explicitly demands user verification, and no usable
>   attestation certificate is configured by default.
> - **PivApplet**: Ships with the well-known PIV factory defaults: PIN `123456`,
>   PUK `12345678`, and the publicly documented 3DES management key
>   `010203040506070801020304050607080102030405060708`. Anyone with brief physical access
>   can take over administration (e.g. import or replace keys) until all three are changed
>   — see [PivApplet.md](./PivApplet.md#change-pin-puk-and-management-key-before-use).
> - **NDEF (`full-plain`)**: No access control at all — the stored record is world-readable
>   and, depending on the install parameters, also writable. Fine for public URLs, never for
>   anything sensitive.
> - **General**: On readers without a PIN pad the PIN travels in plaintext APDUs through the
>   USB reader, where the host OS can log it (the FIDO2 PIN protocol does encrypt
>   the channel, SmartPGP supports secure messaging per the OpenPGP 3.x spec, PivApplet does not).
>   GlobalPlatform SCP is no remedy: it secures only the card *management* channel used by
>   `gp`, never applet APDUs like `VERIFY` — and this project uses the well-known default GP
>   keys anyway.
