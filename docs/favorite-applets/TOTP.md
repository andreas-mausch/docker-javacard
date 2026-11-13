# TOTP with Yubico Authenticator (2FA codes)

An applet which works great in combination with the
Android App [Yubico Authenticator](https://www.yubico.com/products/yubico-authenticator/).

F-Droid: <https://f-droid.org/packages/com.yubico.yubioath/>

<https://developers.yubico.com/ykneo-oath/Releases/>

<https://github.com/Yubico/ykneo-oath>

AID: `A0000005272101`

The applet is in *maintenance mode*, but has been tested successfully with Android app version 7.2.3.

## CLI

I recommend setting an OATH password to protect access to the stored accounts.
You can set it using Yubico Authenticator or the CLI command below.

```bash
sudo pacman -S yubikey-manager

# Get reader name
pcsc_scan

ykman --reader='ACS' info

# Log traffic, including AIDs
ykman --reader='ACS' --log-level=traffic info

# Set OATH password
ykman --reader='ACS' oath access change

# List accounts
ykman --reader='ACS' oath accounts list

# Add a TOTP account; enter the Base32 secret when prompted
ykman --reader='ACS' oath accounts add --oath-type=totp --digits=6 --algorithm=sha1 --issuer=Google account@google.com

# Get codes for all accounts, or filter by a case-insensitive substring (no wildcards or regex)
# Example queries: `google` or `@google.com`
ykman --reader='ACS' oath accounts code [query]
```

## Provisioning via `otpauth://` URI

Authenticator QR codes usually contain an `otpauth://` URI with the credential's
secret and settings, not a generated one-time code:

```text
otpauth://totp/Example:alice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30
```

This example uses a public test secret. Never use it for a real account.

The general format is `otpauth://TYPE/LABEL?PARAMETERS`:

- `TYPE`: `totp` for time-based codes or `hotp` for counter-based codes.
- `LABEL`: account name, preferably prefixed with the issuer as `Issuer:Account`.
  URI-encode the issuer and account name; neither should itself contain a colon.
- `secret`: required shared secret, encoded in Base32 without trailing `=` padding.
- `issuer`: recommended provider/service name, URI-encoded. It should match the
  issuer prefix in the label.
- `algorithm`: hash algorithm (`SHA1`, `SHA256`, or `SHA512`); default is `SHA1`.
- `digits`: number of digits in the generated code: 6 or 8 (Google's documentation),
  or 6, 7, or 8 (Yubico's SDK documentation); default is 6.
- `period`: TOTP time step in seconds; Yubico's SDK documentation lists 15, 30,
  or 60. Default is 30. Only applies to TOTP.
- `counter`: required initial counter for HOTP. Only applies to HOTP.

**Security:** The URI and QR code contain the shared secret and allow anyone with
access to generate codes. Do not publish real credentials, commit them to Git,
or enter them into online tools. Use public test secrets for examples and testing.

References:

- [Google Authenticator: Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
- [Yubico SDK: URI string format](https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html)

## Software alternative: `pass-otp`

The password manager [`pass`](https://www.passwordstore.org/) supports OTP codes
through the [`pass-otp`](https://github.com/tadfisher/pass-otp) extension. It stores
`otpauth://` URIs encrypted with GPG in the password store and generates codes locally.
Unlike the JavaCard applet, the secret is stored on the computer, not on the card.

On Arch Linux:

```bash
sudo pacman -S pass pass-otp

# Initialize the password store if not already configured
# Replace YOUR-GPG-KEY-ID with the ID or fingerprint of your own GPG key
pass init 'YOUR-GPG-KEY-ID'

# Enter the otpauth:// URI interactively
pass otp insert Google/account@google.com

# Generate the current OTP code
pass otp Google/account@google.com

# Copy the code to the clipboard
pass otp -c Google/account@google.com
```

Use interactive input rather than putting a real URI in a shell command, where
the secret could end up in shell history.

Storing both an account's password and its OTP secret in the same password store
means the factors are not stored independently: access to the decrypted store can
expose both.

## Time synchronization

TOTP requires an accurate clock on the computer or phone generating the codes.
Keep its system time synchronized, for example using NTP. The JavaCard applet
receives the time-based challenge from the authenticator; it does not maintain
its own clock.

## Testing

Use <https://www.token2.com/shop/page/totp-toolset> for generating test keys.

Example secrets:

- `JBSWY3DPEHPK3PXP` (10 bytes, which is hex `48656C6C6F21DEADBEEF` and ASCII `Hello!....`)
- `JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP` (20 bytes)

### Generate a new secret

`oathtool` does not generate secrets. To create a cryptographically random secret
of 20 bytes (160 bits), encoded in Base32 without padding:

```bash
openssl rand 20 | base32 -w 0 | tr -d '='
```

The command prints the secret to the terminal; treat the output as sensitive.
For an existing service, use the secret provided by that service instead. A
self-generated secret only works if you also configure it on the verifying server.

### Generate test codes with `oathtool`

[`oathtool`](https://oath-toolkit.codeberg.page/) can generate HOTP and TOTP codes
directly from a secret, without a card or password store. On Arch Linux:

```bash
sudo pacman -S oath-toolkit

# Generate a TOTP code using the public Base32 test secret (SHA1, 6 digits, 30 seconds)
oathtool --totp --base32 JBSWY3DPEHPK3PXP

# Generate an HOTP code with initial counter 0 using the same test secret
oathtool --hotp --counter=0 --base32 JBSWY3DPEHPK3PXP
```

These examples use a public test secret. Do not pass real secrets as command-line
arguments: they may be exposed in shell history and process listings. Unlike
`pass-otp`, `oathtool` does not manage an encrypted credential store.
