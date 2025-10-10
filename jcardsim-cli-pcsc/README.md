# Use jCardSim CLI with PC/SC support

I think it is much better to use a real PC/SC connection to test the applet.
Then, you can use a whole bunch tools using PC/SC, for example `pcsc_scan` or `scriptor`.
In best case, you can use the same script files for your software tests and your production cards.

<https://github.com/OpenSC/OpenSC/wiki/Smart-Card-Simulation>

We need [vsmartcard](https://github.com/frankmorgner/vsmartcard) and a special version
of jCardSim for this:
[Fork of jcardsim with support for connecting to vsmartcard/vpcd over TCP](https://github.com/arekinath/jcardsim)

On Arch or Manjaro Linux you can use this package for vsmartcard:
<https://aur.archlinux.org/packages/virtualsmartcard>

To test vsmartcard, you can run the CLI tool `vicc`. It will present a smartcard which
you can then see if you run `pcsc_scan`. Stop `vicc` again to continue here.

```bash
java --class-path=../external/libs/jcardsim-3.0.5-SNAPSHOT-arekinath-vpcd.jar:../examples/gradle/helloworld/build/classes/java/main/ com.licel.jcardsim.remote.VSmartCard ./jcardsim.properties
```

Notes:

- The `pcscd` daemon must be running.
- The properties `com.licel.jcardsim.vsmartcard.*` in `jcardsim.cfg` must be configured.

This won't print any output, but now you can use for example `gpshell` like this,
and it should return the "Hello" string from the applet:

```bash
gpshell ./gpshell
```

I couldn't find a way to avoid the `CREATE APPLET` instruction inside the file.
It is the only command in the file which cannot be run on a real JavaCard,
but it is required for jCardSim to work.

# Configuration file

Check `/etc/reader.conf.d/vpcd`.

# Use GlobalPlatformPro with a simulator?

Unfortunately, using GlobalPlatformPro (`gp`) won't wort directly, because jCardSim
does not have the GlobalPlatform Manager applet installed.

They do offer their extension [jCardSim GP](https://jcardsim.org/blogs/jcardsim-gp-global-platform-module-jcardsim)
which does exactly that, but it is not open source and they charge a whopping 4.378,85 EUR for it.
