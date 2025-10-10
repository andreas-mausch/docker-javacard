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
- Application (1 byte): `01`
- Version (OpenPGP 3.4): `03 04`
- Manufacturer (2 bytes): `AFAF`
- Serial number (4 bytes): `12 34 56 78`
- RFU (reserved, 2 bytes): `00 00`

You can generate your own custom 4 bytes for the serial number using this command:

```bash
cat /dev/random | head -c 4 | xxd -p -u
```

Change the User PIN and Admin PIN.
This can be done via `gpg --card-edit`, followed by `admin` and `passwd`.

Then generate your personal keys and use them.
