# NDEF NFC Tag

NDEF is used to open a URL on your phone, share a contact or just text.
It emulates a more basic NFC Tag like the *NTAG215*.

<https://github.com/OpenJavaCard/openjavacard-ndef>

AID: `D2760000850101`

Installation notes:

Use the right params to define the size in bytes of the NDEF tag

```bash
# DATA SIZE [0x12 0x02 [short size]]
# 888 bytes = 0x037A (well, actually 0x0378, but two bytes seem to be reserved)

gp --params 8202037A --install ./openjavacard-ndef-full-plain.cap --privs CardReset --create D2760000850101
gp --params 12020378 --install ./openjavacard-ndef-full-plain.cap --default
```

The `--params` are described
[here](https://github.com/OpenJavaCard/openjavacard-ndef/blob/c036bab36a9ea85f01dcb812405ee870d0da20aa/doc/install.md#data-initial-0x80-byte-len-bytes-data).

`--privs CardReset` makes the applet the default applet.
See [here](https://github.com/martinpaljak/GlobalPlatformPro/wiki/Application-management)
and [here](https://github.com/martinpaljak/GlobalPlatformPro/discussions/359).

`--create D2760000850101` is required so the applet is found by typical NDEF applications.
See [here](https://github.com/OpenJavaCard/openjavacard-ndef/issues/4#issuecomment-484023464).
