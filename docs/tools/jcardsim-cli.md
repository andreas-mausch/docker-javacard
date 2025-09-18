# jCardSim CLI PC/SC with vsmartcard

Download latest jcardsim.jar, put it into `external/libs`:
<https://github.com/licel/jcardsim/packages/1650016>

Install these dependencies (on Arch Linux):

```bash
paru -S globalplatform gpshell gppcscconnectionplugin virtualsmartcard
```

## Direct Simulation using an apdu.script file

```bash
java --class-path=../external/libs/jcardsim-3.0.5-20230313.131323-6.jar:../examples/gradle/helloworld/build/classes/java/main/ com.licel.jcardsim.utils.APDUScriptTool ./jcardsim.properties ./apdu.script
```

## Use with PC/SC support

See [../../jcardsim-cli-pcsc/README.md](../../jcardsim-cli-pcsc/README.md).
