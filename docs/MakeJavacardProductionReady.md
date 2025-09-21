# Make a JavaCard production ready

## Change keys

Use this command to generate a new random key in hex format:

```bash
cat /dev/random | head -c 16 | xxd -p -u
```

### via gpshell

I was able to change the keys following this:

<https://github.com/kaoh/globalplatform/blob/2.4.2/gpshell/putKeysSCP03.txt>

Only the first part was enough:

```
mode_211
enable_trace
enable_timer
establish_context
card_connect
select -AID A000000151000000
get_key_information_templates -noStop
open_sc -scp 3 -keyind 0 -keyver 0 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f
# Replace existing key (type 0x80 = 3DES used for SCP02)
put_sc_key -keyType 80 -keyver 1 -newkeyver 1 -enc_key C3E2493EC0537F35E883BD9861216EFB -mac_key 712D973008D5D57C5D22B3167D86EEF9 -kek_key 24E0F23524D6F961C6439F60EF51DF9D
card_disconnect
release_context
```

I don't know exactly what is different to the `gp` command, but it worked.
Note the `dek` is named `kek` here, ChatGPT says:

> However, some tools or documentation (like certain hardware vendor docs) may refer to DEK as KEK (Key Encryption Key).
> They mean the same thing in this context.

> DEK is a more generic term than KEK (Key Encryption Key). I can be used for any data that needs to be kept confidential separate from the transport channel.
> -- <https://stackoverflow.com/questions/26192936/authentication-keys-in-smart-cards/26193275#26193275>

`-keyType 80` means symmetric key. It can be either DES3 or AES.
For 16 bytes, it is usually an AES key.

In order to replace an existing key, `keyver` and `newkeyver` should have the same value in `put_sc_key`.
You might need to replace the `1` by a different value for your card.
It should be displayed in the `get_key_information_templates` response.

After running this and re-connecting the card, I was able to use the new keys:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --verbose --debug --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --list
```

### keyType 0x88 for RSA SCP03 keys

The `-keyType` can be 0x80 and 0x88 (and possibly other values, too).
I have [found this](https://github.com/kaoh/globalplatform/blob/2.4.2/globalplatform/src/globalplatform/security.h#L173
)
in the implementation of globalplatform / gpshell:

```c
#define GP211_KEY_TYPE_AES 0x88 //!<'88' AES (16, 24, or 32 long keys)
```

```
# Add additional new key (type 0x88 = RSA for SCP03)
put_sc_key -keyType 88 -keyver 0 -newkeyver 2 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f
```

### For first initialization: gp

Some cards reported keys with version `255`.
However, this is just used as a placeholder.
I still tried to replace the keys with `gpshell`,
but it returned `OPGP_ERROR_KEY_CHECK_VALUE`.

I have then used `gp` to reset the keys to the default keys,
which worked.
It seems to have **added** as key version `1`, and not **replaced** anything.

Afterwards, I was able to change the keys using gpshell above.

```bash
$ gp --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --lock default
```

```
# Keyset version: 1
# Looking at key version for diversification method
[DEBUG] GPSession - PUT KEY version 1 replace=false ENC=404142434445464748494A4B4C4D4E4F (KCV: 8BAF47) MAC=404142434445464748494A4B4C4D4E4F (KCV: 8BAF47) DEK=404142434445464748494A4B4C4D4E4F (KCV: 8BAF47) for SCP02
[DEBUG] PlaintextKeys - Encrypting ENC value (KCV=8BAF47) with S-DEK (KCV=FB5558)
[DEBUG] PlaintextKeys - Encrypting MAC value (KCV=8BAF47) with S-DEK (KCV=FB5558)
[DEBUG] PlaintextKeys - Encrypting DEK value (KCV=8BAF47) with S-DEK (KCV=FB5558)
A000000151000000 locked with: 404142434445464748494A4B4C4D4E4F
Write this down, DO NOT FORGET/LOSE IT!
```

### Key derivation

`gp` supports [Key Diversification](https://github.com/martinpaljak/GlobalPlatformPro/wiki/Keys#diversification).

However, since it is not guaranteed a key derivation function is available
for all JavaCards, I have decided to not use the built-in KDFs, but rather
generate my own keys for each card using HKDF, the serial number of the card
and a master key, which is stored off-card.
This way, I stay flexible and do not have to care which KDFs my JavaCard supports.

The master key is used to generate ENC, MAC and DEK keys for each JavaCard I own,
based on their serial number.
The algorithm used for this is HKDF with SHA-256 and no salt.

Example call, where `123456789` is the serial number of the card:

```fish
openssl kdf -binary -keylen 16 -kdfopt digest:SHA2-256 -kdfopt hexkey:(pass javacard/scp-master-key | head -n 1 | tr -d '\n') -kdfopt info:'SCP|ENC|Serial:123456789' HKDF | xxd -p -u -c 99999
openssl kdf -binary -keylen 16 -kdfopt digest:SHA2-256 -kdfopt hexkey:(pass javacard/scp-master-key | head -n 1 | tr -d '\n') -kdfopt info:'SCP|MAC|Serial:123456789' HKDF | xxd -p -u -c 99999
openssl kdf -binary -keylen 16 -kdfopt digest:SHA2-256 -kdfopt hexkey:(pass javacard/scp-master-key | head -n 1 | tr -d '\n') -kdfopt info:'SCP|DEK|Serial:123456789' HKDF | xxd -p -u -c 99999
```

`pass javacard/scp-master-key` is a command which returns my master key in hex format (`3F8EDA78F1AE9F59`..).

I use `ENC`, `MAC`, and `DEK` as key names
(DEK is sometimes called KEK, but we use **DEK**).

If the serial number starts with a leading 0, it is **kept**.
Serial number refers to the `ICSerialNumber` returned by `gp --info`.
This command can be called without knowing any keys.

## Personalization

Check this:
<https://github.com/martinpaljak/GlobalPlatformPro/wiki/Lifecycle-management#setting-cplc-information>

For example:

```bash
gp --verbose --debug --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --set-pre-perso 1111111111111111 --set-perso 2222222222222222 --today
```

**Warning**:
On some cards this can only be done ONCE!

## Change card state to SECURED

**These changes cannot be reversed!**

### From OP_READY -> INITIALIZED

```bash
gp --verbose --debug --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --initialize-card
```

### From INITIALIZED -> SECURED

```bash
gp --verbose --debug --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --secure-card
```

## Tipps

Since it is not possible to "factory reset" a JavaCard,
I suggest to document all executed commands for a card.

Also, document which applets in which version you have installed.

Sometimes it is hard to know which applets you can remove
without damaging the card or make it unusable, so it is
especially important you you the applets and their AIDs
you have installed yourself if you want to revert all your changes.
