# Origin

This is a fork of <https://github.com/xoryouyou/docker-javacard>.
I have adjusted it to my needs.

The original had three docker images:
One for ant, one for gradle and one for usb access.
I have combined them into a single image.

I am not an expert on JavaCards, so please treat all the information here with caution.
Especially the *Make a JavaCard production ready* part.

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

# What is inside this repository

- Docker image for JavaCard development
  - Tools to work with JavaCards
    - GlobalPlatformPro
    - gpshell
    - opensc-tool
    - scriptor
    - yubico-piv-tool
    - fido2-hid-bridge
  - PC/SC support
    - Daemon
    - pcsc_scan
    - pcsc_ndef
  - PKCS#11 support
  - Java with all required JDKs
  - Build tools
    - Maven
    - Gradle
    - Ant
  - Simulators
    - vsmartcard
    - jCardSim [in CLI mode](./docs/tools/jcardsim-cli.md)
    - Oracle JavaCard Simulator
- Examples for a Hello World JavaCard applet for each build tool
  - Maven (preferred)
  - Gradle
  - Ant
- A list of my favorite applets  
  See here: [./docs/favorite-applets/README.md](./docs/favorite-applets/README.md)
- A guide how to secure a JavaCard  
  See here: [./docs/MakeJavacardProductionReady.md](./docs/MakeJavacardProductionReady.md).

Note: The *Oracle JavaCard Simulator* is not bundled for licensing reasons.

# Tools to work with JavaCards

There are different tools to interact with JavaCards.

- **gp.jar** / [GlobalPlatformPro](https://github.com/martinpaljak/GlobalPlatformPro)  
  [./docs/tools/globalplatformpro.md](./docs/tools/globalplatformpro.md)  
  A modern, Java-based CLI tool, lightweight, easier to use, and more developer-friendly.
  Extensive CLI, but no support for script files.
- **GPShell**  
  [./docs/tools/gpshell.md](./docs/tools/gpshell.md)  
  a tool based on the C/C++ library GlobalPlatform,
  which offers low-level scripting of JavaCards via `.gpshell` script files.
- **opensc-tool**  
  [./docs/tools/opensc-tool.md](./docs/tools/opensc-tool.md)  
  a command-line utility used to communicate with smart cards and manage
  their contents using the OpenSC framework.
- **scriptor**  
  [./docs/tools/scriptor.md](./docs/tools/scriptor.md)  
  a command-line tool used to send APDU (Application Protocol Data Unit) commands
  to smart cards via a PC/SC interface.
- **pcsc_scan**  
  [./docs/tools/pcsc_scan.md](./docs/tools/pcsc_scan.md)  
  a command-line tool that detects and displays information about smart card readers
  and smart cards connected to a system using the PC/SC (Personal Computer/Smart Card) interface.

The naming is a bit confusing to me, because it is so similar.
There is also the *GlobalPlatform Card Manager* on the JavaCard itself,
a privileged on-card applet.

`gp.jar` is the most powerful tool of them, and the one I use most often.

See the [./docs/tools/](./docs/tools/) folder for usage examples for each.

# Download the JavaCard SDK

JavaCard SDKs are downloaded from here:
<https://github.com/martinpaljak/oracle_javacard_sdks>

```bash
git submodule update --init --recursive
```

# Build the docker image

```bash
docker build -t javacard .
```

# Build your own JavaCard applet (.cap file)

You can build your own applet.
Examples for maven, gradle and ant are in the [./examples](./examples) folder.

See [./docs/BuildJavacardApplet.md](./docs/BuildJavacardApplet.md) for details.

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

```bash
gp --key=404142434445464748494A4B4C4D4E4F --install ./my_applet.cap
```

You can specify the `--default` option to make it the default applet.
Some applets might require `--params` to be configured at installation time.
You might want to use `--create` to define a custom AID.

# Install on a Simulator

There are two choices here:

- **jCardSim**  
  [./docs/tools/jcardsim-cli.md](./docs/tools/jcardsim-cli.md)  
  a library which simulates a JavaCard.
  Can be used either in unit tests or as a stand-alone CLI tool.
- **Oracle JavaCard Simulator**  
  [./docs/tools/OracleJavaCardSimulator.md](./docs/tools/OracleJavaCardSimulator.md)  
  a simulator which supports PC/SC and basic GlobalPlatform commands.
  Can be used to install a .cap file and behaves like a real JavaCard.

You can either use jCardSim or, which I prefer, the **Oracle JavaCard Simulator**.

The latter is a simulator which supports PC/SC and basic GlobalPlatform commands.
Can be used to install a .cap file and behaves like a real JavaCard.
This is something jCardSim can't do (at least in the free edition).

So my preferred setup is to use jCardSim for unit tests, which works great there.  
And to test a `.cap` file I have built or even a third-party file, I use
Oracle's simulator.

# Make a JavaCard production ready

See here: [./docs/MakeJavacardProductionReady.md](./docs/MakeJavacardProductionReady.md).

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

- Script files for gpshell for common, re-testable tasks (test SCP03, set new keys, ..)
- `pcsc_ndef --reader='Alcor Link AK9567 00 00' --wait=3 --type=4 getmax` doesn't work yet (`No tag found`)
