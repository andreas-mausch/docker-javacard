#!/usr/bin/env -S sh -e

# We need this entrypoint script to allow
# variable user commands with more than one argument.

# We need to `pcscd --disable-polkit` instead of `service pcscd start`,
# otherwise we see permission errors:
# https://github.com/LudovicRousseau/PCSC/issues/59
pcscd --disable-polkit

# Run the Oracle JavaCard Simulator, if present
if [ -f /opt/javacard/simulator/runtime/bin/jcsl ] && [ -n "$START_JAVACARD_SIMULATOR" ]; then
  # Note: redirect stdout *then* stderr into the log file.
  # (`2>&1 > file` would send stderr to the console instead.)
  LD_LIBRARY_PATH=/opt/javacard/simulator/runtime/bin/ /opt/javacard/simulator/runtime/bin/jcsl -p=9025 -log_level=finest > /var/log/jcsl.log 2>&1 &

  # Run until at least one card is found, but fail fast with diagnostics
  # after 60 seconds instead of hanging forever (see CI "Run .cap file"):
  card_found=""
  for _ in $(seq 1 120); do
    if pcsc_scan -c | grep -qiE 'card present|card inserted|card state:.*present|atr:'; then
      card_found=y
      break
    fi
    sleep 0.5
  done
  if [ -z "$card_found" ]; then
    echo "ERROR: No card appeared within 60 seconds." >&2
    echo "--- /var/log/jcsl.log ---" >&2
    cat /var/log/jcsl.log >&2 || true
    echo "--- ps aux ---" >&2
    ps aux >&2 || true
    echo "--- pcsc_scan -c ---" >&2
    pcsc_scan -c >&2 || true
    exit 1
  fi
fi

exec "$@"
