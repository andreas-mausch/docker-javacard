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

See the [./docs](./docs) folder for usage examples for each.

# Build the docker image

```bash
docker build -t javacard .
```

# Download JavaCard SDK

**TODO**

# ant

```shell-session
$ docker run -it --rm -v ./examples/ant/helloworld:/applet javacard
root@863d7039121e:/applet# ant test
Buildfile: /applet/build.xml
      [get] Destination already exists (skipping): /javacard/libs/ant-javacard.jar
      [get] Destination already exists (skipping): /javacard/libs/jcardsim-3.0.4-SNAPSHOT.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-4.13.2.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-jupiter-api-5.8.2.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-jupiter-engine-5.8.2.jar
      [get] Destination already exists (skipping): /javacard/libs/hamcrest-2.2.jar

compile:
    [mkdir] Created dir: /applet/build/main
    [javac] Compiling 1 source file to /applet/build/main
    [javac] warning: [options] bootstrap class path not set in conjunction with -source 8
    [javac] 1 warning

test-compile:
    [mkdir] Created dir: /applet/build/test
    [javac] Compiling 1 source file to /applet/build/test
    [javac] warning: [options] bootstrap class path not set in conjunction with -source 8
    [javac] 1 warning

test:
    [junit] Running HelloWorldAppletTest
    [junit] Testsuite: HelloWorldAppletTest
    [junit] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.031 sec
    [junit] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.031 sec
    [junit] 
    [junit] ------------- Standard Output ---------------
    [junit] Running on Simulator:com.licel.jcardsim.smartcardio.CardSimulator@6f1fba17
    [junit] Done
    [junit] ------------- ---------------- ---------------

BUILD SUCCESSFUL
Total time: 1 second
root@863d7039121e:/applet# ant applet
Buildfile: /applet/build.xml
      [get] Destination already exists (skipping): /javacard/libs/ant-javacard.jar
      [get] Destination already exists (skipping): /javacard/libs/jcardsim-3.0.4-SNAPSHOT.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-4.13.2.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-jupiter-api-5.8.2.jar
      [get] Destination already exists (skipping): /javacard/libs/junit-jupiter-engine-5.8.2.jar
      [get] Destination already exists (skipping): /javacard/libs/hamcrest-2.2.jar

applet:
      [cap] INFO: using JavaCard 3.0.5 SDK in /javacard/oracle_javacard_sdks/jc305u4_kit
      [cap] INFO: Setting package name to helloworld
      [cap] Building CAP with 1 applet from package helloworld (AID: 0102030405)
      [cap] helloworld.HelloWorldApplet 0102030405060708
  [compile] Compiling files from /applet/src
  [compile] Compiling 1 source file to /tmp/jccpro9501193397923777567
  [convert] [ INFO: ] Converter [v3.0.5]
  [convert] [ INFO: ]     Copyright (c) 1998, 2020, Oracle and/or its affiliates. All rights reserved.
  [convert]     
  [convert]     
  [convert] [ INFO: ] conversion completed with 0 errors and 0 warnings.
   [verify] Verification passed
      [cap] CAP saved to /applet/build/helloworld.cap

BUILD SUCCESSFUL
Total time: 1 second
root@863d7039121e:/applet# 
```

# gradle

```shell-session
$ docker run -it --rm -v ./examples/gradle/helloworld:/applet javacard
```

Start container:
* `docker compose run --rm -ti javacard-gradle`

Run tests:
* `gradle test`

```
gradle@8aa816b693a5:/applet/helloworld$ gradle test
...
BUILD SUCCESSFUL in 2s
3 actionable tasks: 2 executed
```
Build applet:
* `gradle buildJavaCard`

```
gradle@3e496b0ab649:/applet$ gradle buildjavacard
...
BUILD SUCCESSFUL in 3s
1 actionable task: 1 executed
```

# USB image to install applets to physical card

To finally install the build cap file on a physical card 
you can use the `javacard-usb` docker image.

In the `docker-compose.yml` maps the hosts systems `/dev/bus/usb`
into the container so the cardreader can be accessed.

List cardreaders with `pcsc_scan`
```
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
```
root@a14755c4d73f:/javacard# java -jar gp.jar -list
Warning: no keys given, using default test key 404142434445464748494A4B4C4D4E4F
ISD: A000000151000000 (OP_READY)
```

# Sources

* Original project https://github.com/xoryouyou/docker-javacard
* Oracle Javacard SDKs https://github.com/martinpaljak/oracle_javacard_sdks
* GlobalPlatformPro https://github.com/martinpaljak/GlobalPlatformPro
* Ant Javacard https://github.com/martinpaljak/ant-javacard
* Gradle Template https://github.com/crocs-muni/javacard-gradle-template-edu
* jcardsim https://github.com/licel/jcardsim
* Inspiration https://github.com/MrSuicideParrot/Make-JavaCards-Great-Again
* HelloWorld Applet https://github.com/devrandom/javacard-helloworld
