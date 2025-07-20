#!/usr/bin/env -S sh -e

# We need this entrypoint script to allow
# variable user commands.

# We need to `pcscd --disable-polkit` instead of `service pcscd start`,
# otherwise we see permission errors:
# https://github.com/LudovicRousseau/PCSC/issues/59
pcscd --disable-polkit

exec "$@"
