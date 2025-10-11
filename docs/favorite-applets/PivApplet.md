# PivApplet, PKCS#11

<https://github.com/arekinath/PivApplet>

Can be used to store a Root CA certificate, for example.
Can be used in conjunction with `openssl` and PKCS#11.

AID: A000000308000010000100

Slot `0x9C` is for *Digital Signature*.

In this example, we will generate a X.509 Root Certificate,
and sign an intermediate certificate with it.

## Verify openssl supports PKCS#11

```bash
openssl engine pkcs11 -t
```

If you get this error message, you might be missing `pkcs11-provider` or `libengine-pkcs11-openssl`:

```
/usr/lib/x86_64-linux-gnu/engines-3/pkcs11.so: cannot open shared object file: No such file or directory
```

## Install applet

```bash
unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
gp --install /javacard/applets/PivApplet-0.9.0-jc304-REePAxaD.cap
```

## Find card/applet

```bash
pkcs11-tool --list-slots
pkcs11-tool --list-objects
yubico-piv-tool -r '' -a list-readers
yubico-piv-tool -r Oracle -a status
```

## Create the Root CA certificate

```bash
openssl ecparam -name secp384r1 -genkey -noout -out root_ca.key

  # The 2.5.29.32.0 OID is the "anyPolicy" identifier — some apps like Java or Windows might expect this.
openssl req -x509 -new -nodes -key root_ca.key -sha384 -days 3650 \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=MyHomeRootCA" \
  -addext "basicConstraints = critical,CA:true" \
  -addext "keyUsage = critical, cRLSign, keyCertSign" \
  -addext "subjectKeyIdentifier = hash" \
  -addext "authorityKeyIdentifier = keyid:always" \
  -addext "certificatePolicies = 2.5.29.32.0" \
  -out root_ca.crt

openssl x509 -in root_ca.crt -noout -text
```

## Create the Intermediate CA .csr

```bash
openssl ecparam -name secp256r1 -genkey -noout -out intermediate_web.key

# pathlen:0 means no further subordinate CAs under this intermediate
openssl req -new -key intermediate_web.key -out intermediate_web.csr \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=MyIntermediateWebCA" \
  -addext "basicConstraints = critical,CA:true,pathlen:0" \
  -addext "keyUsage = critical, keyCertSign, cRLSign" \
  -addext "subjectKeyIdentifier = hash"
```

## Import existing key

I my example I try to upload a Root CA key into the PivApplet.
Warning: ChatGPT says this is a very bad idea.
Do not do it with your production keys.

```bash
yubico-piv-tool -r Oracle -s 9c -a import-key --key-format PEM --algorithm ECCP384 -i ./root_ca.key
yubico-piv-tool -r Oracle -a import-certificate -s 9c -i ./root_ca.crt
```

## Verify / List tokens

```bash
pkcs11-tool --login --list-objects --type privkey
p11tool --list-tokens
```

## Sign the .csr

```bash
openssl x509 -req \
  -in intermediate_web.csr \
  -sha384 \
  -days 365 \
  -copy_extensions=copyall \
  -CAkeyform engine \
  -engine pkcs11 \
  -CA root_ca.crt \
  -CAkey "pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=0000000000000000;token=MyHomeRootCA;id=%02;object=SIGN%20key;type=private" \
  -out intermediate_web.crt
```

Note: We do not provide a serial number, but let OpenSSL generate it for us.

This one works, but I have struggled to build the right command here.

I need to use `-CAkeyform` (there is also `-keyform`).
I need to use `-CAkey` (there is also `-signkey`).

Tested using `openssl version`:
`OpenSSL 3.5.1 1 Jul 2025 (Library: OpenSSL 3.5.1 1 Jul 2025)`.

Verify:

```bash
openssl verify -verbose -CAfile root_ca.crt intermediate_web.crt
```

## Issues

### Problem solved: Wrong key slot

At first, I have uploaded the key to slot `9c` (correct), but the certificate to slot `9e` (incorrect).
It must be `9c` in both cases.

This resulted in this error from `openssl`:

```
Engine "pkcs11" set.
Certificate request self-signature ok
subject=C=US, ST=State, L=City, O=MyOrg, OU=IT, CN=MyIntermediateWebCA
4077047EA57F0000:error:41800020:PKCS#11 module:ERR_CKR_error:Data invalid:p11_ec.c:438:
4077047EA57F0000:error:06880006:asn1 encoding routines:ASN1_item_sign_ctx:EVP lib:../crypto/asn1/a_sign.c:277:
```

### Alternative to upload the key without yubico-piv-tool? Didn't work.

<https://github.com/OpenSC/OpenSC/wiki/Using-pkcs11-tool-and-OpenSSL#generate-keys>

```bash
openssl genpkey -out EC_private.der -outform DER -algorithm EC -pkeyopt ec_paramgen_curve:P-521
pkcs11-tool --write-object EC_private.der --id "$ID" --type privkey --label "EC private key" -p "$PIN"
openssl pkey -in EC_private.der -out EC_public.der -pubout -inform DER -outform DER
pkcs11-tool --write-object EC_public.der --id "$ID" --type pubkey  --label "EC public key" -p $PIN
```

In my case it gave:

```
error: PKCS11 function C_CreateObject failed: rv = CKR_FUNCTION_NOT_SUPPORTED (0x54)
```

## Links

- <https://github.com/nmrr/nitrokeyhsm-cheatsheet>
