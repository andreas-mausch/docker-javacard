# Description

The Oracle JavaCard Simulator is a closed-source simulator provided by Oracle.

It can be an alternative to `jCardSim` for you.

It has one big upside:
It understands basic GlobalPlatform commands.

Therefore, it can be used with common tools like `pcsc_scan`, `gp` and so on.
It will just act as a physical JavaCard and you can issue the same commands to it.

# Download

You can find the download here:

<https://www.oracle.com/java/technologies/javacard-downloads.html?er=221886#sdk-sim>

It is free of cost, but you need to have an Oracle account.

# Usage

In order to use it with the included `Dockerfile`, you need to build it like this with the `JAVACARD_SIMULATOR` parameter:

```bash
docker build --build-arg JAVACARD_SIMULATOR="java_card_devkit_simulator-linux-bin-v25.0-b_474-23-APR-2025.tar.gz" -t javacard .
```

`java_card_devkit_simulator-linux-bin-v25.0-b_474-23-APR-2025.tar.gz` is the filename of the simulator,
and you need to place it inside the `./external/oracle_javacard_simulator/` directory.

I cannot include the binary in this repository, because it is not under a free license.

Now when running it, make sure you also start the simulator by setting the `START_JAVACARD_SIMULATOR` environment variable:

```bash
docker run -it --rm --device /dev/bus/usb -e START_JAVACARD_SIMULATOR=y javacard
```

Now run `pcsc_scan` and your virtual JavaCard should show up.

# Notes

We use the port `9025` to communicate with the simulator.
This can be changed if needed.

We log to `/var/log/jcsl.log`.
