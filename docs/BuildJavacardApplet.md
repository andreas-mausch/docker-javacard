# ant

Commands are `ant test` and `ant applet`.

<details>

<summary>ant test</summary>

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
```

</details>
<details>

<summary>ant applet</summary>

```shell-session
$ docker run -it --rm -v ./examples/ant/helloworld:/applet javacard
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
```

</details>

Select your JavaCard SDK in the variables `jc.sdk` and `<javacard jckit="..">` values
in the [./examples/ant/helloworld/build.xml](./examples/ant/helloworld/build.xml).

You can adjust the AID in the `examples/ant/helloworld/build.xml` for
the `.cap` and the java class to your needs.

# gradle

Commands are `gradle buildJavaCard` and `gradle test`.

The Gradle version used is `8.14.3` and specified in the Dockerfile.
I explicitly do not use the Gradle wrapper because I think it is a bad concept.
This is controversial though and you might disagree.

<details>

<summary>gradle --version</summary>

```shell-session
$ docker run -it --rm -v ./examples/gradle/helloworld:/applet javacard
root@6a37b06cb9b1:/applet# gradle --version

Welcome to Gradle 8.14.3!

Here are the highlights of this release:
 - Java 24 support
 - GraalVM Native Image toolchain selection
 - Enhancements to test reporting
 - Build Authoring improvements

For more details see https://docs.gradle.org/8.14.3/release-notes.html


------------------------------------------------------------
Gradle 8.14.3
------------------------------------------------------------

Build time:    2025-07-04 13:15:44 UTC
Revision:      e5ee1df3d88b8ca3a8074787a94f373e3090e1db

Kotlin:        2.0.21
Groovy:        3.0.24
Ant:           Apache Ant(TM) version 1.10.15 compiled on August 25 2024
Launcher JVM:  11.0.27 (Eclipse Adoptium 11.0.27+6)
Daemon JVM:    /opt/java/openjdk (no JDK specified, using current Java home)
OS:            Linux 6.15.7-1-MANJARO amd64
```

</details>

<details>

<summary>gradle clean buildJavaCard test</summary>

```shell-session
$ docker run -it --rm -v ./examples/gradle/helloworld:/applet javacard
root@6a37b06cb9b1:/applet# gradle clean buildJavaCard test
Starting a Gradle Daemon (subsequent builds will be faster)
[ant:convert] [ INFO: ] Converter [v3.0.5]
[ant:convert] [ INFO: ]     Copyright (c) 1998, 2020, Oracle and/or its affiliates. All rights reserved.warning: You did not supply export file for the previous minor version of the package
[ant:convert]     
[ant:convert] 
[ant:convert]     
[ant:convert] [ INFO: ] conversion completed with 0 errors and 1 warnings.

> Task :buildJavaCard
[ant:cap] INFO: using JavaCard 3.0.5 SDK in /javacard/oracle_javacard_sdks/jc305u4_kit
[ant:cap] INFO: targeting JavaCard 3.0.5 SDK in /javacard/oracle_javacard_sdks/jc305u4_kit
[ant:cap] Building CAP with 1 applet from package helloworld (AID: 01FFFF040506070809)
[ant:cap] helloworld.HelloWorldApplet 01FFFF0405060708090102
[ant:compile] Compiling files from /applet/src
[ant:compile] Compiling 1 source file to /tmp/jccpro11955558934349392609
[ant:verify] Verification passed
[ant:cap] CAP saved to /applet/build/javacard/applet.cap
[ant:exp] EXP saved to /applet/build/javacard/applet.exp/helloworld/javacard/helloworld.exp
[ant:jca] JCA saved to /applet/build/javacard/applet.jca
[ant:jar] Building jar: /applet/build/javacard/applet.exp/helloworld.jar
[ant:jar] JAR saved to /applet/build/javacard/applet.exp/helloworld.jar

> Task :test

HelloWorldAppletTest > testPing() PASSED

[Incubating] Problems report is available at: file:///applet/build/reports/problems/problems-report.html

Deprecated Gradle features were used in this build, making it incompatible with Gradle 9.0.

You can use '--warning-mode all' to show the individual deprecation warnings and determine if they come from your own scripts or plugins.

For more on this, please refer to https://docs.gradle.org/8.14.3/userguide/command_line_interface.html#sec:command_line_warnings in the Gradle documentation.

BUILD SUCCESSFUL in 22s
5 actionable tasks: 5 executed
```

</details>

Select your JavaCard SDK in the variables `JC_SELECTED` and `config.cap.targetsdk` values
in the [./examples/gradle/helloworld/build.gradle](./examples/gradle/helloworld/build.gradle).

You can adjust the AID in the `config.cap.applet.aid` for the `.cap`.
