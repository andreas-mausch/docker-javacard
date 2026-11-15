# jCardSim CLI PC/SC with vsmartcard

Download latest jcardsim.jar, put it into `external/libs`:
<https://github.com/licel/jcardsim/packages/1650016>

Install these dependencies (on Arch Linux):

```bash
paru -S globalplatform gpshell gppcscconnectionplugin virtualsmartcard
```

## Direct Simulation using an apdu.script file

```bash
java --class-path=../external/libs/jcardsim-3.0.5-20230313.131323-6.jar:<your-applet-classes-dir>/ com.licel.jcardsim.utils.APDUScriptTool ./jcardsim.properties ./apdu.script
```

For `<your-applet-classes-dir>` use the compiled applet classes of your project,
e.g. `build/classes/java/main` from a Gradle build like the frozen
[`example-gradle` tag](https://github.com/andreas-mausch/docker-javacard/tree/example-gradle/examples/gradle/helloworld).

## Use with PC/SC support

See [../../jcardsim-cli-pcsc/README.md](../../jcardsim-cli-pcsc/README.md).
