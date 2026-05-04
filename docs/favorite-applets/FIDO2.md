# FIDO2

<https://github.com/BryanJacobs/FIDO2Applet>

FIDO2 can be used to authenticate on the internet.
It is closely connected to *WebAuthn*.

You can use it to let your browser store your Passkeys on the JavaCard.

A note on security:
FIDO2 tokens usually have a mechanism *user presence*.
The user needs to touch the token to prove he really wants to authenticate somewhere.
The JavaCard applet cannot do this, because there is no API to access a button on your reader.
Therefore, the "User [is] always considered present".

## Communication, PC/SC, HID bridge

The JavaCard applet is available over the usual PC/SC interface.

However, tools like `fido2-token` or your browser expect a USB HID interface.

Therefore, you need to install a HID to PC/SC bridge.

I have included <https://github.com/BryanJacobs/fido2-hid-bridge> in the Dockerfile,
which works fine for me.

The same author also has a (newer) Kotlin implementation here, which I think also does
more than only the bridging. I haven't tried it, yet.

<https://github.com/BryanJacobs/FIDOk>

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

Setting a PIN is required for passwordless login
(unless the site sets `userVerification = discouraged`).

`fido2-token` has a very bad CLI, which is not designed for humans.

Replace **hidrawX** with your device.

### Token information

```bash
# List detected FIDO2 devices
fido2-token -L

# Get device information
fido2-token -I /dev/hidrawX
```

`-L` should return something like this:

```
/dev/hidraw2: vendor=0x9999, product=0x9999 ( FIDO2 Virtual USB Device)
```

### PIN management

```bash
# Set a new PIN for your token (optional)
fido2-token -S /dev/hidrawX

# Change an already set PIN
fido2-token -C /dev/hidrawX

# Verify PIN
fido2-token -V /dev/hidrawX
```

### Credential management

```bash
# List relying parties
fido2-token -L -r /dev/hidrawX

# List resident credentials for a relying party (discoverable credentials stored on the key)
fido2-token -L -k <RELYING_PARTY_ID> /dev/hidrawX

# Delete resident credential specified by id from device, where id is the credential's base64-encoded id.
fido2-token -D -i <CREDENTIAL_ID> /dev/hidrawX
```

`-L -r` only works if a PIN is set on the device.

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

## WebAuthn testing

I like these sites:

- <https://webauthn.io>
  for a quick test
- <https://www.webauthn.me/debugger>
  for deep tech analysis

## CTAP? I am confused

My device does not show `U2F` when running `fido2-token -I /dev/hidraw2`.

This is expected, because I have not set up any *attestation certificates*:
<https://github.com/BryanJacobs/FIDO2Applet/blob/main/docs/certs.md>

Therefore, some functionality won't work.
