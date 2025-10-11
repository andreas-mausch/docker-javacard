# FIDO2

<https://github.com/BryanJacobs/FIDO2Applet>

FIDO2 can be used to authenticate on the internet.
It is closely connected to *WebAuthn*.

The JavaCard applet is available over the usual PC/SC interface.

However, tools like `fido2-token` expect a USB HID interface.

Therefore, you need to install a HID to PC/SC bridge.

I have included <https://github.com/BryanJacobs/fido2-hid-bridge> in the Dockerfile.

## Run the docker container

You need to start the docker container in `--privileged` mode
and pass the `/dev/uhid` and map the volume `/dev`.

This is required, because the USB HID bridge (see below) will create
a new virtual USB device.

I also test with the simulator, so I start it as well.

```bash
docker run -it --rm --privileged --device /dev/uhid -v /dev:/dev -e START_JAVACARD_SIMULATOR=y javacard
```

## USB HID bridge

Run this:

```bash
fido2-hid-bridge > /var/log/fido2-hid-bridge.log 2>&1 &
```

## Installation

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --install /javacard/applets/FIDO2.cap
```

I don't provide any installation parameters here for simplicity.

Check the instructions if you want to get into more detail:
<https://github.com/BryanJacobs/FIDO2Applet/blob/v2.0.5/docs/installation.md>

## Verify the device and applet can communicate

```bash
fido2-token -L
fido2-token -I /dev/hidraw2
```

Replace **hidraw2** with your device.

This should return something like this:

```
/dev/hidraw2: vendor=0x9999, product=0x9999 ( FIDO2 Virtual USB Device)
```

## Create a new credential and verify it

Source:
<https://developers.yubico.com/libfido2/Manuals/fido2-cred.html>

Create a new es256 credential on /dev/hidraw2,
verify it, and save the id and the public key of the credential in cred:

```bash
echo credential challenge | openssl sha256 -binary | base64 > cred_param
echo relying party >> cred_param
echo user name >> cred_param
dd if=/dev/urandom bs=1 count=32 | base64 >> cred_param
fido2-cred -M -i cred_param /dev/hidraw2 | fido2-cred -V -o cred
```

To my surprise, it worked without entering a PIN.

## Problem to list credentials

```bash
fido2-token [-d] -L -r /dev/hidraw2
```

fails with `fido2-token: fido_credman_get_dev_rp: FIDO_ERR_PIN_REQUIRED`.
I don't understand it, because the man page says I should be queries for the PIN.

## CTAP? I am confused

My device does not show `U2F` when running `fido2-token -I /dev/hidraw2`.

This is expected, because I have not set up any *attestation certificates*:
<https://github.com/BryanJacobs/FIDO2Applet/blob/main/docs/certs.md>

Therefore, some functionality doesn't work yet.
