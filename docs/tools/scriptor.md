Tested with a NTAG216.

```shell-session
$ scriptor -r 'Alcor Link AK9567 [Contactless Card Reader] 01 00'
Using given card reader: Alcor Link AK9567 [Contactless Card Reader] 01 00
Using T=1 protocol
Reading commands from STDIN
reset
> RESET
< OK: 3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 03 00 00 00 00 68
FF CA 00 00 00
> FF CA 00 00 00
< 04 BD 0F 8A CD 11 90 90 00 : Normal processing.
```
