#!/usr/bin/env -S sh -e

# We need this entrypoint script to allow
# variable user commands with more than one argument.

# We need to `pcscd --disable-polkit` instead of `service pcscd start`,
# otherwise we see permission errors:
# https://github.com/LudovicRousseau/PCSC/issues/59
pcscd --disable-polkit

# Run the Oracle JavaCard Simulator, if present
if [ -f /opt/javacard/simulator/runtime/bin/jcsl ] && [ -n "$START_JAVACARD_SIMULATOR" ]; then
  LD_LIBRARY_PATH=/opt/javacard/simulator/runtime/bin/ /opt/javacard/simulator/runtime/bin/jcsl -p=9025 -log_level=finest 2>&1 > /var/log/jcsl.log &
fi

exec "$@"
