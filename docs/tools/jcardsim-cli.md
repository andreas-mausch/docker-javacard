# jCardSim CLI PC/SC with vsmartcard

Download latest jcardsim.jar, put it into `external/libs`:
<https://github.com/licel/jcardsim/packages/1650016>

## Direct Simulation using an apdu.script file

```bash
java --class-path=../external/libs/jcardsim-3.0.5-20230313.131323-6.jar:../examples/gradle/helloworld/build/classes/java/main/ com.licel.jcardsim.utils.APDUScriptTool ./jcardsim.properties ./apdu.script
```

## Use with PC/SC support

See [../../jcardsim-cli-pcsc/README.md](../../jcardsim-cli-pcsc/README.md).

## Use GlobalPlatformPro with a simulator?

Unfortunately, using GlobalPlatformPro (`gp`) won't wort directly, because jCardSim
does not have the GlobalPlatform Manager applet installed.

They do offer their extension [jCardSim GP](https://jcardsim.org/blogs/jcardsim-gp-global-platform-module-jcardsim)
which does exactly that, but it is not open source and they charge a whopping 4.378,85 EUR for it.
