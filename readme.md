# Origin

This is a fork of <https://github.com/xoryouyou/docker-javacard>.
I have adjusted it to my needs.

The original had three docker images:
One for ant, one for gradle and one for usb access.
I have combined them into a single image.

> # docker + javacard = why ?!
> 
> Why you ask? Well I don't know either.
> 
> But the main reasons are I needed it and:
> * I don't want to taint my host system with JCDKs from the early 2000s
> * I don't want to fiddle around with a multitude of system environment variables to build a cap file
> * I don't want to maintain all this for Linux and Windows hosts
> * You get the idea... ;)
> 
> This repoository takes all the dependencies needed to build a `HelloWorld` applet
> with the `ant` or the `gradle` toolchain.
> 
> It's meant for local development by mapping the applets sourcecode into the
> running containers but is also capable to run in a typical CI/CD pipeline.
> 
> Just map the applet into `/applet` and run your tests.

# Tools to work with JavaCards

There are different tools to interact with JavaCards.

- **pcsc_scan**  
  a command-line tool that detects and displays information about smart card readers
  and smart cards connected to a system using the PC/SC (Personal Computer/Smart Card) interface.
- **opensc-tool**  
  a command-line utility used to communicate with smart cards and manage
  their contents using the OpenSC framework.
- **scriptor**  
  a command-line tool used to send APDU (Application Protocol Data Unit) commands
  to smart cards via a PC/SC interface.
- **GPShell**  
  a tool based on the C/C++ library GlobalPlatform,
  which offers low-level scripting of JavaCards via `.gpshell` script files.
- **gp.jar** / [GlobalPlatformPro](https://github.com/martinpaljak/GlobalPlatformPro)  
  A modern, Java-based CLI tool, lightweight, easier to use, and more developer-friendly.
  Extensive CLI, but no support for script files.

The naming is a bit confusing to me, because it is so similar.
There is also the *GlobalPlatform Card Manager* on the JavaCard itself,
a privileged on-card applet.

`gp.jar` is the most powerful tool of them, and the one I use most often.

See the [./docs/tools/](./docs/tools/) folder for usage examples for each.

# Download the JavaCard SDK

JavaCard SDKs are downloaded from here:
<https://github.com/martinpaljak/oracle_javacard_sdks>

```bash
git submodule init
git submodule update
```

# Build the docker image

```bash
docker build -t javacard .
```

# Build your own JavaCard applet (.cap file)

You can build your own applet.
Examples for ant and gradle are in the [./examples](./examples) folder.

See [./docs/build-javacard-applet.md](./docs/build-javacard-applet.md) for details.

# Access a physical card and list applets

We map the hosts systems `/dev/bus/usb` into the container,
so the cardreader can be accessed.

The container runs the PC/SC Smart Card Daemon `pcscd` in the background
to make your card accessible by the tools.
See here [./docker-entrypoint.sh](./docker-entrypoint.sh).

List cardreaders with `pcsc_scan`

```shell-session
$ docker run -it --rm --device=/dev/bus/usb javacard
root@55557e33ca3f:/applet# pcsc_scan 
Using reader plug'n play mechanism
Scanning present readers...
0: Alcor Micro AU9540 00 00
 
Sun Jun  5 18:14:09 2022
 Reader 0: Alcor Micro AU9540 00 00
  Event number: 1
  Card state: Card removed, 
```

Query the card with `globalplatformpro`

```shell-session
$ docker run -it --rm --device=/dev/bus/usb javacard
root@a14755c4d73f:/javacard# gp --list --key 404142434445464748494A4B4C4D4E4F
ISD: A000000151000000 (OP_READY)
```

Note: I have explicitly set all `GP_KEY*` environment variables to an empty string.
This causes `gp` to not try the default key.

I have done that to not accidentially use a command on a production card with non-default keys,
which would cause the lock-counter to increase.

If you see this error message, you need to pass the key explicitly:

```
Invalid argument: Either all or nothing of enc/mac/dek keys must be set, and no mk at the same time!
```

# Install a JavaCard applet onto a physical card

To finally install the built `.cap` file on a physical card
you can also use the docker image.

```shell-session
$ gp --key=404142434445464748494A4B4C4D4E4F --install /javacard/applets/SmartPGP-v1.22.2-jc304-rsa_up_to_4096.cap
/javacard/applets/SmartPGP-v1.22.2-jc304-rsa_up_to_4096.cap loaded: fr.anssi.smartpgp D27600012401

# DATA SIZE [0x12 0x02 [short size]]
# 888 bytes = 0x0378
$ gp --key=404142434445464748494A4B4C4D4E4F --params 12020378 --install /javacard/applets/openjavacard-ndef-full-plain.cap
```

You can specify the `--default` option to make it the default applet.

The NDEF applet I have used is this one:
<https://github.com/mohamadeq/javacard-ndef>

The `--params` are described here:
<https://github.com/mohamadeq/javacard-ndef/blob/e3b271d972a346c9287081b7eebf0a6ee6df08b4/README.md#install-time-configuration>

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
open_sc -security 3 -keyind 0 -keyver 0 -mac_key 404142434445464748494a4b4c4d4e4f -enc_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f
put_sc_key -keyver 1 -newkeyver 1 -mac_key 712D973008D5D57C5D22B3167D86EEF9 -enc_key C3E2493EC0537F35E883BD9861216EFB -kek_key 24E0F23524D6F961C6439F60EF51DF9D
card_disconnect
```

I don't know exactly what is different to the `gp` command, but it worked.
Note the `dek` is named `kek` here, ChatGPT says:

> However, some tools or documentation (like certain hardware vendor docs) may refer to DEK as KEK (Key Encryption Key).
> They mean the same thing in this context.

After running this and re-connecting the card, I was able to use the new keys:

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --verbose --debug --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-dek=24E0F23524D6F961C6439F60EF51DF9D --list
```

## Personalization

Check this:
<https://github.com/martinpaljak/GlobalPlatformPro/wiki/Lifecycle-management#setting-cplc-information>

For example:

```bash
gp --verbose --debug --key-mac=712D973008D5D57C5D22B3167D86EEF9 --key-enc=C3E2493EC0537F35E883BD9861216EFB --key-dek=24E0F23524D6F961C6439F60EF51DF9D --set-pre-perso 1111111111111111 --set-perso 2222222222222222 --today
```

**Warning**:
On some cards this can only be done ONCE!

## TODO

- Set it to the `SECURED` lifecycle state.
- Initialize applets.
- Set Admin PINs / Owner PINs for applets.
- Log: Save information about the card and which applets in which version are on it.

# Sources

* Original project https://github.com/xoryouyou/docker-javacard
* Oracle Javacard SDKs https://github.com/martinpaljak/oracle_javacard_sdks
* GlobalPlatformPro https://github.com/martinpaljak/GlobalPlatformPro
* Ant Javacard https://github.com/martinpaljak/ant-javacard
* Gradle Template https://github.com/crocs-muni/javacard-gradle-template-edu
* jcardsim https://github.com/licel/jcardsim
* Inspiration https://github.com/MrSuicideParrot/Make-JavaCards-Great-Again
* HelloWorld Applet https://github.com/devrandom/javacard-helloworld

# TODO

- Use key derivation (kdf3) instead of fixed keys (so each card has unique keys)
- How to make a JavaCard production ready?
- Script files for gpshell for common, re-testable tasks (test SCP03, set new derivation keys and so on)
- List my favorite applets
- `pcsc_ndef --reader='Alcor Link AK9567 00 00' --wait=3 --type=4 getmax` doesn't work yet (`No tag found`)
