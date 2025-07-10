```shell-session
root@7e8e5fc83881:/# pcsc_scan
PC/SC device scanner
V 1.7.1 (c) 2001-2022, Ludovic Rousseau <ludovic.rousseau@free.fr>
Using reader plug'n play mechanism
Scanning present readers...
0: Alcor Link AK9567 00 00
1: Alcor Link AK9567 [Contactless Card Reader] 01 00

Mon Jul  7 14:01:38 2025
 Reader 0: Alcor Link AK9567 00 00
  Event number: 0
  Card state: Card removed,
 Reader 1: Alcor Link AK9567 [Contactless Card Reader] 01 00
  Event number: 1
  Card state: Card inserted,
  ATR: 3B 8A 80 01 50 56 4A 43 4F 50 34 53 49 44 71

ATR: 3B 8A 80 01 50 56 4A 43 4F 50 34 53 49 44 71
+ TS = 3B --> Direct Convention
+ T0 = 8A, Y(1): 1000, K: 10 (historical bytes)
  TD(1) = 80 --> Y(i+1) = 1000, Protocol T = 0
-----
  TD(2) = 01 --> Y(i+1) = 0000, Protocol T = 1
-----
+ Historical bytes: 50 56 4A 43 4F 50 34 53 49 44
  Category indicator byte: 50 (proprietary format)
+ TCK = 71 (correct checksum)

Possibly identified card (using /usr/share/pcsc/smartcard_list.txt):
3B 8A 80 01 50 56 4A 43 4F 50 34 53 49 44 71
	J3R180 via ifdnfc (JavaCard)
```
