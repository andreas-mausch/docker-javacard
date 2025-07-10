# gp --list

```shell-session
root@7e8e5fc83881:/# gp --list
Warning: no keys given, using default test key 404142434445464748494A4B4C4D4E4F
ISD: A000000151000000 (INITIALIZED)
     Parent:  A000000151000000
     From:    A0000001515350
     Privs:   SecurityDomain, CardLock, CardTerminate, CardReset, CVMManagement, TrustedPath, AuthorizedManagement, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration

PKG: A0000001515350 (LOADED)
     Parent:  A000000151000000
     Version: -1.-1
     Applet:  A000000151535041

PKG: A00000016443446F634C697465 (LOADED)
     Parent:  A000000151000000
     Version: 1.0
     Applet:  A00000016443446F634C69746501

PKG: A0000000620204 (LOADED)
     Parent:  A000000151000000
     Version: 1.0

PKG: A0000000620202 (LOADED)
     Parent:  A000000151000000
     Version: 1.3
```

# gp --info

```shell-session
root@dd68999c35ea:/# gp --info
GlobalPlatformPro v20.01.23-0-g5ad373b
Running on Linux 6.15.3-1-MANJARO amd64, Java 1.8.0_452 by Private Build
Reader: Alcor Link AK9567 [Contactless Card Reader] 01 00
ATR: 3B8A800150564A434F503453494471
More information about your card:
    http://smartcard-atr.appspot.com/parse?ATR=3B8A800150564A434F503453494471

[WARN] GPData - Invalid CPLC date: 9738
CPLC: ICFabricator=4790
      ICType=D321
      OperatingSystemID=4700
      OperatingSystemReleaseDate=0000 (2010-01-01)
      OperatingSystemReleaseLevel=0000
      ICFabricationDate=2345 (2012-12-10)
      ICSerialNumber=11111111 <redacted>
      ICBatchIdentifier=2222 <redacted>
      ICModuleFabricator=0000
      ICModulePackagingDate=0000 (2010-01-01)
      ICCManufacturer=0000
      ICEmbeddingDate=0000 (2010-01-01)
      ICPrePersonalizer=1939
      ICPrePersonalizationEquipmentDate=9738 (invalid date format)
      ICPrePersonalizationEquipmentID=11111111 <redacted>
      ICPersonalizer=0000
      ICPersonalizationDate=0000 (2010-01-01)
      ICPersonalizationEquipmentID=00000000

Card Data: 
Tag 6: 1.2.840.114283.1
-> Global Platform card
Tag 60: 1.2.840.114283.2.2.3
-> GP Version: 2.3
Tag 63: 1.2.840.114283.3
Tag 64: 1.2.840.114283.4.2.85
-> GP SCP02 i=55
Tag 65: 1.2.840.114283.5.7.2.0.0
Tag 66: 1.3.6.1.4.1.42.2.110.1.3
-> JavaCard v3
Card Capabilities: 
Supports: SCP02 i=15 i=35 i=55 i=75
Supported DOM privileges: SecurityDomain, DelegatedManagement, CardReset, MandatedDAPVerification, TrustedPath, TokenVerification, GlobalDelete, GlobalLock, GlobalRegistry, FinalApplication, ReceiptGeneration, CipheredLoadFileDataBlock
Supported APP privileges: CardLock, CardTerminate, CardReset, CVMManagement, FinalApplication, GlobalService
Supported LFDB hash: 02
Supported Token Verification ciphers: 7B
Supported Receipt Generation ciphers: 0C
Supported DAP Verification ciphers: 7B
Version:   1 (0x01) ID:   1 (0x01) type: DES3 length:  16 
Version:   1 (0x01) ID:   2 (0x02) type: DES3 length:  16 
Version:   1 (0x01) ID:   3 (0x03) type: DES3 length:  16 
```
