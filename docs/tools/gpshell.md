# Example script

I have run the following commands successfully on my own card (J3R180).

Taken from here:
<https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/listSCP03.txt>

Use the docker usb image to try it:

```bash
docker run -it --rm --device /dev/bus/usb javacard-usb bash -c 'pcscd --disable-polkit && gpshell'
```

```
# Set protocol mode to GlobalPlatform 2.1.1 and later
mode_211

enable_trace
establish_context
card_connect
select -AID A000000151000000
get_key_information_templates -noStop
open_sc -security 3 -keyind 0 -keyver 0 -enc_key 404142434445464748494a4b4c4d4e4f -mac_key 404142434445464748494a4b4c4d4e4f -kek_key 404142434445464748494a4b4c4d4e4f

# List packages
get_status -element 20 -noStop

#  List applications (and Security Domains only in GP211 and later)
get_status -element 40 -noStop

# List Card Manager / Security Issuer Domain
get_status -element 80 -noStop

# List Executable Load Files and their Executable Modules only (Only GP211 and later)
get_status -element 10 -noStop

card_disconnect
release_context
```

# Segmentation fault

During my first tests I encountered a segmentation fault:

```shell-session
root@4f47eadef78e:/# gpshell
card_connect
card_connect
Segmentation fault (core dumped)
root@4f47eadef78e:/#
```

The reason is: You **must** execute `establish_context` as the first command.
I think this should be handled more gracefully by `gpshell` though, if missed.

# Other commands (not tested)

<https://github.com/kaoh/globalplatform/blob/master/gpshell/src/gpshell.1.md>

```
# Connect to card in the reader with readerName. By default protocol is 0 = T0.
# Protocol, 0:T=0, 1:T=1 Should not be necessary to be stated explicitly.
card_connect -reader readerName -protocol 1

# A GET DATA command returning the secure channel protocol details and remembering them for a later open_sc. NOTE: The security domain must be selected and this only works outside of a secure channel.
get_secure_channel_protocol_details

# List applets and packages and security domains
get_status -element e0

open_sc -scp 02 -key 404142434445464748494A4B4C4D4E4F

select -aid A000000151000000

send_apdu <command>

install -file helloworld.cap -sdAID A000000003000000 -pkgAID A000000003000000 -instAID A000000003000000

card_disconnect
```

- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/list.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/listSCP03.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/get_data.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloInstall.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloInstallSCP03.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/helloDelete.txt>
- <https://github.com/kaoh/globalplatform/blob/2.4.0/gpshell/putKeysSCP03.txt>
