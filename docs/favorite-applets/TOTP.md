# TOTP with Yubico Authenticator (2FA codes)

An applet which works great in combination with the
Android App [Yubico Authenticator](https://www.yubico.com/products/yubico-authenticator/).

<https://developers.yubico.com/ykneo-oath/Releases/>

<https://github.com/Yubico/ykneo-oath>

AID: `A0000005272101`

The applet is in *maintenance mode*, but it works fine with the current Android app version (7.2.3).

Use <https://www.token2.com/shop/page/totp-toolset> for testing.

Example secrets:

- `JBSWY3DPEHPK3PXP` (10 bytes, which is hex `48656C6C6F21DEADBEEF` and ASCII `Hello!....`
- `JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP` (20 bytes)

I suggest to set an authentication code (password) for the card.
You can set it inside the app.
