# List of AIDs

[Complete list of application identifiers (AID)](https://emv.cool/2020/12/23/Complete-list-of-application-identifiers-AID/)

# My favorite applets

Here is a list of my personal favorite applets I like to use.

## SmartPGP

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
- Application (1 byte): `01`
- Version (OpenPGP 3.4): `03 04`
- Manufacturer (2 bytes): `AFAF`
- Serial number (4 bytes): `12 34 56 78`
- RFU (reserved, 2 bytes): `00 00`

Change the User PIN and Admin PIN.
This can be done via `gpg --card-edit`, followed by `admin` and `passwd`.

Then generate your personal keys and use them.

## NDEF

NDEF is used to open a URL on your phone, share a contact or just text.
It emulates a more basic NFC Tag like the *NTAG215*.

<https://github.com/OpenJavaCard/openjavacard-ndef>

AID: `D2760000850101`

Installation notes:

Use the right params to define the size in bytes of the NDEF tag

```bash
# DATA SIZE [0x12 0x02 [short size]]
# 888 bytes = 0x0378

gp --params 12020378 --install ./openjavacard-ndef-full-plain.cap --default
```

The `--params` are described
[here](https://github.com/OpenJavaCard/openjavacard-ndef/blob/c036bab36a9ea85f01dcb812405ee870d0da20aa/doc/install.md#data-initial-0x80-byte-len-bytes-data).

## TOTP with Yubico Authenticator (2FA codes)

An applet which works great in combination with the
Android App [Yubico Authenticator](https://www.yubico.com/products/yubico-authenticator/).

<https://developers.yubico.com/ykneo-oath/Releases/>

<https://github.com/Yubico/ykneo-oath>

AID: `A0000005272101`

The applet is in *maintenance mode*, but it works fine with the current Android app version (7.2.3).

Use <https://www.token2.com/shop/page/totp-toolset> for testing.

Example secrets:

- `JBSWY3DPEHPK3PXP` (10 bytes, which is hex `48656C6C6F21DEADBEEF` and ASCII `Hello!....`
- `JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP` (20 bytes)

I suggest to set an authentication code (password) for the card.
You can set it inside the app.
