# Make a JavaCard production ready

## Change keys

### via GlobalPlatformPro (didn't work for me)

Use this command to generate a new random key in hex format:

```bash
cat /dev/random | head -c 16 | xxd -p -u
```

Now, run this command to change the three keys (ENC, MAC and DEK) to your own keys:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --verbose --debug --key-enc=404142434445464748494A4B4C4D4E4F --key-mac=404142434445464748494A4B4C4D4E4F --key-dek=404142434445464748494A4B4C4D4E4F --new-keyver=0x01 --lock-enc=C3E2493EC0537F35E883BD9861216EFB --lock-mac=712D973008D5D57C5D22B3167D86EEF9 --lock-dek=24E0F23524D6F961C6439F60EF51DF9D
```

TODO: This returns `Error: null`.
Seems to be this [Github Issue #383](https://github.com/martinpaljak/GlobalPlatformPro/issues/383).

The proposed solution `--new-keyver 0xAB` did not work for me.

Maybe related? <https://stackoverflow.com/questions/63714493/javacard-j2a040-changing-default-key-with-gpshell-script-not-work>

### via gpshell (SUCCESS)

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
open_sc -security 3 -keyind 0 -keyver 0 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f
put_sc_key -keyver 1 -newkeyver 1 -enc_key C3E2493EC0537F35E883BD9861216EFB -mac_key 712D973008D5D57C5D22B3167D86EEF9 -kek_key 24E0F23524D6F961C6439F60EF51DF9D
card_disconnect
release_context
```

I don't know exactly what is different to the `gp` command, but it worked.
Note the `dek` is named `kek` here, ChatGPT says:

> However, some tools or documentation (like certain hardware vendor docs) may refer to DEK as KEK (Key Encryption Key).
> They mean the same thing in this context.

After running this and re-connecting the card, I was able to use the new keys:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --verbose --debug --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-dek=24E0F23524D6F961C6439F60EF51DF9D --list
```

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
