# Description

The Oracle JavaCard Simulator is a closed-source simulator provided by Oracle.

It can be an alternative to `jCardSim` for you.

It has one big upside:
It understands basic GlobalPlatform commands.

Therefore, it can be used with common tools like `pcsc_scan`, `gp` and so on.
It will just act as a physical JavaCard and you can issue the same commands to it.

Since v26.0 it speaks **SCP03 with AES-128/192/256** (verified with `gp --info`):

```
Supports SCP03 i=10 i=20 i=60 i=70 with AES-128 AES-196 AES-256
Version:  16 (0x10) ID:   1 (0x01) type: AES          length:  16 (AES-128)
Version:  16 (0x10) ID:   2 (0x02) type: AES          length:  16 (AES-128)
Version:  16 (0x10) ID:   3 (0x03) type: AES          length:  16 (AES-128)
```

# Download

You can find the download here:

<https://www.oracle.com/java/technologies/javacard-downloads.html?er=221886#sdk-sim>

It is free of cost, but you need to have an Oracle account.

# Usage

In order to use it with the included `Dockerfile`, you need to build it like this with the `JAVACARD_SIMULATOR` parameter:

```bash
docker build --build-arg JAVACARD_SIMULATOR="java_card_devkit_simulator-linux-bin-v26.0-b_788-05-MAY-2026.tar.gz" -t javacard .
```

`java_card_devkit_simulator-linux-bin-v26.0-b_788-05-MAY-2026.tar.gz` is the filename of the simulator,
and you need to place it inside the `./external/oracle_javacard_simulator/` directory.

I cannot include the binary in this repository, because it is not under a free license.

Now when running it, make sure you also start the simulator by setting the `START_JAVACARD_SIMULATOR` environment variable:

```bash
docker run -it --rm --device /dev/bus/usb -e START_JAVACARD_SIMULATOR=y javacard
```

Now run `pcsc_scan` and your virtual JavaCard should show up.

And what is very special about this simulator compared to `jCardSim`:
You can run `gp --install` commands on it with real `.cap` files.

# Notes

We use the port `9025` to communicate with the simulator.
This can be changed if needed.

We log to `/var/log/jcsl.log`.

# Keys

## Where the keys come from

Unlike a real card, the simulator's initial SCP keyset is **injected into the `jcsl` binary**
at build time by Oracle's `Configurator.jar` tool (the `Dockerfile` does this for you):

```bash
java -jar /opt/javacard/simulator/tools/Configurator.jar \
  -binary /opt/javacard/simulator/runtime/bin/jcsl \
  -SCP-keyset \
    10 \                                  # KVN (Key Version Number), here 0x10
    404142434445464748494A4B4C4D4E4F \    # ENC
    404142434445464748494A4B4C4D4E4F \    # MAC
    404142434445464748494A4B4C4D4E4F      # DEK
```

- Accepted key lengths: 16, 24 or 32 bytes (AES-128/192/256).
- Re-injecting requires `-force`, which **overwrites** the existing keyset.
- `jcsl` must not be running while injecting, otherwise you get
  `Text file busy` / `Could not save updated binary`.

## Using gp against the simulator

Two quirks will bite you otherwise:

1. `gp` is only a shell **alias** in `~/.bashrc` — it does not work in
   non-interactive `docker exec bash -c '...'` calls. Use
   `java -jar /javacard/gp-v25.10.20.jar` directly there.
2. The image sets `GP_KEY=""` (and friends) to empty strings **on purpose**, to
   prevent accidentally hitting production cards with the built-in default key
   (see the README). As a side effect every `gp` call fails with
   `Invalid argument: Either all or nothing of enc/mac/dek keys must be set`.
   In scripts (e.g. non-interactive `bash -c`) `unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK` first.

The keys injected by our `Dockerfile` have version **16 (0x10)**, so `--key-ver 16`
is mandatory. Verify the channel works:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
java -jar /javacard/gp-v25.10.20.jar \
  --key-ver 16 \
  --key-enc 404142434445464748494A4B4C4D4E4F \
  --key-mac 404142434445464748494A4B4C4D4E4F \
  --key-dek 404142434445464748494A4B4C4D4E4F \
  --list
```

Pass ENC/MAC/DEK **explicitly**. A single `--key` is treated as a master key and
`gp` may apply key derivation to it, which the simulator does not expect
(`Card cryptogram invalid!`).

## Changing the SCP03 AES keys at runtime with gp

This works (verified with gp v25.10.20 and simulator v26.0), but only the
**full keyset in one command** is accepted:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
NEWENC=$(openssl rand -hex 16 | tr a-f A-F)
NEWMAC=$(openssl rand -hex 16 | tr a-f A-F)
NEWDEK=$(openssl rand -hex 16 | tr a-f A-F)
java -jar /javacard/gp-v25.10.20.jar \
  --key-ver 16 \
  --key-enc 404142434445464748494A4B4C4D4E4F \
  --key-mac 404142434445464748494A4B4C4D4E4F \
  --key-dek 404142434445464748494A4B4C4D4E4F \
  --lock-enc $NEWENC --lock-mac $NEWMAC --lock-dek $NEWDEK \
  --new-keyver 1 --verbose
```

Then use the new keys:

```bash
java -jar /javacard/gp-v25.10.20.jar \
  --key-ver 1 \
  --key-enc $NEWENC --key-mac $NEWMAC --key-dek $NEWDEK \
  --list
```

Important behaviors (all verified against the simulator):

- **`--new-keyver` must be outside the ranges `0x10-0x1F`, `0x20-0x2F` and `0x30-0x3F`.**
  `gp` interprets KVN ranges as scheme hints (SCP01/SCP02-KDF/SCP03-KDF3) and will
  encode/derive the keyset accordingly, which the simulator rejects
  (`6A80 Wrong data` or `6A86 Incorrect P1/P2`).
  Using `--new-keyver 16` (the Dockerfile's KVN!) is a trap that looks like a
  simulator bug but isn't. Use `1`..`0x0F`.
- The simulator stores **exactly one keyset**. After a successful PUT KEY the old
  keys stop working immediately, even at a different version
  (`INITIALIZE UPDATE failed: 0x6A88`).
- Single-key `--put-key` / `--replace-key` (only one key component per PUT KEY
  command) is **not supported** by the simulator: `6A86 (Incorrect P1/P2)`.
  Always pass `--lock-enc` **and** `--lock-mac` **and** `--lock-dek` together.
- On success the simulator returns the new KVN plus the three KCVs.

### Verifying the stored key (type and value) — no "key type" flag needed

`gp` has **no option to force the key type tag** (0x88 = AES). Instead, the type is
fixed by the SCP03 session (see above) and a wrong encoding is **rejected at the
write** (`6A80`/`6A86`) — nothing wrong can silently end up on the card.

To be sure afterwards, verify the **KCVs** (`gp --verbose` prints what the card
reports, e.g. `Card stored keys with KVN 01 (0x01) and with KCV-s: …`) and
recompute the expected AES-128 KCV yourself. Per SCP03 the KCV is over a block of
**16 bytes of `0x01`** (AES-ECB, first 3 bytes of the result):

```bash
K=00112233445566778899AABBCCDDEEFF
printf '\x01' > /tmp/kcv.bin && truncate -s 16 /tmp/kcv.bin
openssl enc -aes-128-ecb -K $K -nopad -in /tmp/kcv.bin | od -An -tx1 -N3
# -> must match the KCV reported by the card
```

Additionally `gp --info` shows the stored key templates (`type: AES length: 16`).

## The same with gpshell and gpshell3 (also verified)

Legacy `gpshell` script (`put_sc_key -keyType 88`, `0x88` = AES):

```
mode_211
establish_context
card_connect
select -AID A000000151000000
open_sc -scp 3 -keyind 0 -keyver 16 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f
put_sc_key -keyType 88 -keyver 0 -newkeyver 1 -enc_key <ENC> -mac_key <MAC> -kek_key <DEK>
card_disconnect
release_context
```

Run with `gpshell /tmp/putKeys.gp`.
**Caveat:** like with `gp`, a single `-key` in `open_sc` breaks the SCP03 channel
(`0x8030F00D The calculated pseudo random card challenge … does not match`).
Pass `-enc_key`/`-mac_key`/`-kek_key` explicitly.

`gpshell3` (the newer task-oriented CLI shipped since gpshell 3.0.0) even has an
**explicit key type flag**, which `gp` lacks:

```bash
gpshell3 --scp 3 --kv 1 --enc <ENC> --mac <MAC> --dek <DEK> \
  put-auth --type aes --kv 0 --new-kv 2 --key <NEWKEY>
```

(`--key` with `put-auth` sets ENC=MAC=DEK to the same value unless you pass
`--enc/--mac/--dek` there as well; `--kv 0` means "create new key set").

**Quirk:** `gpshell3` has no `help` subcommand — `gpshell3 help put-key` *executes*
something (and fails mutual authentication). Read usage from `gpshell3 --help` only.

All three tools (`gp`, `gpshell`, `gpshell3`) produce the same result on the
simulator, which stores exactly one keyset — each successful write invalidates
the previous keys.

## Resetting the keys

There is no "factory reset". Either PUT KEY new values as above, or re-inject via
the `Configurator.jar` (stop `jcsl` first, use `-force`, then restart).
