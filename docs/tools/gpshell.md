# gpShell 3

We install gpShell 3 from the upstream [release page](https://github.com/kaoh/globalplatform/releases)
(`gpshell-3.0.0-static.deb`), because Debian's package is stuck at 2.4.0 from 2023.

The DEB ships **two** binaries:

- `gpshell` — the classic script interpreter chaining commands in one session
  (our `*.gpshell` script files keep working with it).
- `gpshell3` — a new task-oriented CLI, similar to `gp.jar`,
  with `then` to chain commands in a single session:

```shell-session
# List apps/SDs/load files, then the key templates,
# both inside one single secure channel
root@container:/# gpshell3 --scp 3 --sec mac+enc+rmac \
  --key 404142434445464748494a4b4c4d4e4f list-apps then list-keys
```

Other useful commands: `cplc`, `card-data`, `card-cap`, `install`, `delete`,
`put-key`, `put-auth`, `status`, and `apdu` for raw APDUs.

Options are verbose and explicit: `gpshell3 --help`
(or `man gpshell3`, also online:
<https://github.com/kaoh/globalplatform/blob/3.0.0/gpshell/src/gpshell3.1.md>).
New features in 3.x include SCP11 (ECC) secure channels,
Delegated Management with receipts, and DAP.

# Example script

I have run the following commands successfully on my own card (J3R180).

Taken from here:
<https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/listSCP03.txt>

Use the docker usb image to try it:

```bash
docker run -it --rm --device /dev/bus/usb javacard-usb bash -c 'pcscd --disable-polkit && gpshell'
```

```
# Set protocol mode to GlobalPlatform 2.1.1 and later
mode_211

enable_trace
establish_context
card_connect
select -AID A000000151000000
get_key_information_templates -noStop
open_sc -security 3 -keyind 0 -keyver 0 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f

# List packages
get_status -element 20 -noStop

#  List applications (and Security Domains only in GP211 and later)
get_status -element 40 -noStop

# List Card Manager / Security Issuer Domain
get_status -element 80 -noStop

# List Executable Load Files and their Executable Modules only (Only GP211 and later)
get_status -element 10 -noStop

card_disconnect
release_context
```

# SCP02 and the OpenSSL legacy provider

## Pitfall: `GET STATUS … 6A88` in `list-apps` on older cards

After a successful SCP02 mutual authentication, `gpshell3 list-apps` can
abort with

```
Error 0x80206A88: 6A88: Referenced data not found.
GET STATUS (applications) failed
```

That is **not** a secure-channel failure: the card decoded and verified
the wrapped command fine (a MAC error would give `6982`/`6688`/`6A86`).
`gpshell3` enumerates via `GET STATUS [for applications]` (`P1=0x40`)
and aborts on the first error. Older cards (GP2.1-era, e.g. JTop/JCOP
with `OP_READY` ISD and the `A0000001515350` "SP" demo package) do not
answer `P1=0x40` and reply `6A88`, even when the card is *not* empty.

`gp.jar` is tolerant here: it queries `P1=0x80` (ISD), `0x40` (apps),
`0x10`/`0x20` (load files, with modules), merely *warns* about failing
element types and prints whatever the card did return — which is why
`gp --list` shows your packages while `gpshell3 list-apps` fails.
Verify with `gp --verbose --list` and look for the
`GET STATUS failed … 6A88` warning.

Workarounds for such cards: list with `gp --list`, use `gpshell3 apdu --auth`
to send the GET STATUS element types you want manually
(`P1`: `80`=ISD — carries the card lifecycle state, `40`=applications
and Security Domains, `20`=load files, `10`=load files with modules;
`6310` means "more" → repeat with P2 bit 0 set), or use the legacy
`gpshell` script interpreter with `get_status -element 10/20/80 -noStop`
(upstream even ships per-card scripts like `listJCOP10.txt`).

```shell-session
root@container:/# gpshell3 --scp 2 --kv 1 --enc <ENC> --mac <MAC> --dek <DEK> \
    apdu --auth --nostop 80F28000024F0000,80F24000024F0000,80F21000024F0000,80F22000024F0000
```

(The four P1 values above are the only ones GP 2.1.1 defines; the
occasionally seen `B0` is not a "global directory" — at best a GP 2.2+
bit-combination of `80|20|10`, optional for cards.)

Note: `gpshell3`'s `list-apps` has no flag to skip an element type; its
SELECT-probe fallback only triggers on `6D00`/`6E00`/`6A81` errors, not
on `6A88`. And beware: `gpshell3 status …` is *SET* status (can lock or
terminate the card), not a listing command.
What all these element types (`80`/`40`/`10`/`20`) actually stand
for — ISD, applications, load files, modules — is explained in
[JavaCard-Whats-On-A-Card.md](../JavaCard-Whats-On-A-Card.md).

Other `gpshell3` operations (install, delete, keys…) work normally,
since the secure channel itself is fine.


SCP02 mutual authentication fails with

```
error:0308010C:digital envelope routines::unsupported
Mutual authentication failed
```

when the OpenSSL *legacy* provider is not activated.
Reason: every SCP02 `EXTERNAL AUTHENTICATE` computes its MAC with
`calculate_MAC_des_3des()`, which uses **single DES** (`EVP_des_cbc()`),
and OpenSSL 3.x moved single DES out of the default provider into the
legacy provider. (SCP03 uses AES and is unaffected.)

The `gpshell3` binary from the static DEB links OpenSSL statically but
still reads the OpenSSL config file (`/usr/lib/ssl/openssl.cnf`, a symlink
to `/etc/ssl/openssl.cnf`) and loads
`/usr/lib/x86_64-linux-gnu/ossl-modules/legacy.so` from the system.
The Dockerfile therefore activates the `default` and `legacy` providers
in `/etc/ssl/openssl.cnf`:

```ini
[provider_sect]
legacy = legacy_sect
default = default_sect

[default_sect]
activate = 1

[legacy_sect]
activate = 1
```

If you hit this error outside of our image, either apply the same config
or point `OPENSSL_CONF` to a config file containing the snippet above
(starting with `openssl_conf = openssl_init` / `[openssl_init]` /
`providers = provider_sect`).

Note that activating *any* provider explicitly also requires activating
`default` explicitly, otherwise AES etc. stop working everywhere.

Quick self-test (must produce ciphertext instead of "Error setting cipher"):

```shell-session
root@container:/# printf "01234567" | openssl enc -des-cbc -K 0101010101010101 -iv 0000000000000000 | od -An -tx1
 a0 68 db ea b7 3d 14 0b 92 aa 0a bc 22 4a be 26
```

# Segmentation fault

During my first tests I encountered a segmentation fault:

```shell-session
root@4f47eadef78e:/# gpshell
card_connect
card_connect
Segmentation fault (core dumped)
root@4f47eadef78e:/#
```

The reason is: You **must** execute `establish_context` as the first command.
I think this should be handled more gracefully by `gpshell` though, if missed.

# Other commands (not tested)

<https://github.com/kaoh/globalplatform/blob/3.0.0/gpshell/src/gpshell.1.md>

```
# Connect to card in the reader with readerName. By default protocol is 0 = T0.
# Protocol, 0:T=0, 1:T=1 Should not be necessary to be stated explicitly.
card_connect -reader readerName -protocol 1

# A GET DATA command returning the secure channel protocol details and remembering them for a later open_sc. NOTE: The security domain must be selected and this only works outside of a secure channel.
get_secure_channel_protocol_details

# List applets and packages and security domains
# (Open Platform 2.0.1' mode only: e0 = "everything"; undefined in GP 2.1.1 mode)
get_status -element e0

open_sc -scp 02 -key 404142434445464748494A4B4C4D4E4F

select -aid A000000151000000

send_apdu <command>

install -file helloworld.cap -sdAID A000000003000000 -pkgAID A000000003000000 -instAID A000000003000000

card_disconnect
```

- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/list.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/listSCP03.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/get_data.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloInstall.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloInstallSCP03.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloDelete.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/putKeysSCP03.txt>
