Build the `.cap` JavaCard applet file first (see README).

To run this applet in the Oracle JavaCard Simulator, run this:

```shell-session
$ docker run -it --rm --volume ./examples/maven/helloworld:/applet -e START_JAVACARD_SIMULATOR=y javacard
root@70344ab77a60:/applet# unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK
root@70344ab77a60:/applet# gp --install ./target/010203040506.cap
# Warning: no keys given, defaulting to 404142434445464748494A4B4C4D4E4F
./target/010203040506.cap loaded: helloworld 0102030405
root@70344ab77a60:/applet# gpshell hello.gpshell
establish_context
enable_trace
card_connect
* reader name Virtual PCD 00 00
* reader name Virtual PCD 00 01
* reader name Oracle JCSDK PCSC Reader Demo 1 00 00
select -AID 010203040506
Command --> 00A4040006010203040506
Wrapped command --> 00A4040006010203040506
Response <-- 9000
Unwrapped response <-- 9000
send_apdu -sc 0 -APDU 8000000000
Command --> 8000000000
Wrapped command --> 8000000000
Response <-- 48656C6C6F9000
Unwrapped response <-- 48656C6C6F9000
send_APDU() returns 0x80209000 (Success)
```

Or, all in one command:

```bash
docker run --rm --volume ./examples/maven/helloworld:/applet --env START_JAVACARD_SIMULATOR=y javacard bash -c 'gp() { java -jar /javacard/gp-v24.10.15.jar "$@"; } && unset GP_KEY GP_KEY_ENC GP_KEY_MAC GP_KEY_DEK && gp --install ./target/010203040506.cap && gpshell ./hello.gpshell'
```
