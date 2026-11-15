# What's on a JavaCard?

An overview of the different kinds of objects that live on a JavaCard,
what they mean, and how the tools in this image let you list them.
Concepts follow the *GlobalPlatform Card Specification* (2.1.1/2.2.1/2.3)
and the *Java Card Virtual Machine Specification*.

## Mental model

Think of a JavaCard as a tiny phone OS:

- The **Issuer Security Domain (ISD)** is `root`/Administrator:
  it holds the card management keys and decides what may be installed.
- A **Load File** (loaded CAP) is like an installed `.apk`/`.deb` package.
- An **Applet instance** is an installed app with its own icon —
  reachable by its own **Instance AID** (that's what you `SELECT`).
- **Keys** and small pieces of **card data** are the credentials and config.

```text
Card (lifecycle: OP_READY → INITIALIZED → SECURED → …, see States below)
├── ISD – Issuer Security Domain          ← SCP keys, card lifecycle, "root"
│   └── (optional SSDs – delegated sub-admins)
├── Load Files (from .cap files)
│   └── Package (Package AID)             ← namespace provided, e.g. "GP SP"
│       └── Executable Module (a class)   ← installable unit
│           └── Applet instance(s)        ← Instance AID, selectable, own state
├── Key sets (KVN → ENC / MAC / DEK, or AES)
└── Card data (IIN, CIN, CPLC, Card Recognition Data, …)
```

## The objects

| Object | What it is | Analogy | How it gets there |
|---|---|---|---|
| **Issuer Security Domain (ISD)** | Built-in management entity present on every GlobalPlatform card (AID initially `A000000151000000` per the GP 2.1.1→2.2.1 mapping guideline). Holds the SCP keys, and the *card* lifecycle state is reported through it; authorizes install/delete/PUT KEY. "Security Domain" = an applet-like entity whose job is security management. | `root` / Administrator account | Factory (always there) |
| **Supplementary Security Domain (SSD)** | An optional, additional Security Domain installed by the ISD — a delegated administrator (e.g. for a tenant or Application Provider). Listed together with applications (`GET STATUS P1=0x40`); told apart via privileges. | Delegated admin group | `install-sd` / INSTALL with SD privileges |
| **Load File (LF)** | The on-card container of one or more Executable Modules — what a `.cap` file becomes after `LOAD`. Identified by a Load File AID. GP 2.2.1 §5.2.1: its life cycle has exactly **one** state, `LOADED`. | Downloaded `.apk` file on disk | `gp --install` / LOAD command |
| **Package** | The namespace one or more Load Modules *provide*; identified by a Package AID. Applets can only link against packages present on the card. Java Card *package* lifecycle: `LOADED → INSTALL → SELECTABLE`. | Installed library/package | Delivered inside the CAP |
| **Executable Module** | A concrete class inside a Package (installable unit; implements `Applet` or `SecurityDomain`). Its life cycle is linked to its load file (GP 2.2.1 §5.2.2); visible only via `GET STATUS P1=0x10`. | The program binary inside a package | With the Load File |
| **Applet instance** | An instantiated applet, made selectable under its own **Instance AID**. GP lifecycle (§5.3.1): `INSTALLED → SELECTABLE`, plus `LOCKED` (management lock) and free app-specific states; `PERSONALIZED` is a **Security Domain** state, not an applet one. (`BLOCKED` you may know from Java Card is the applet's own PIN-retry state, not a GP registry state.) | Installed app with its own icon | INSTALL [for install] / [for make selectable] |
| **Application** | Umbrella term for any selectable software on the card: applet instances *and* Security Domains (`GET STATUS P1=0x40` returns both). | "App" | — |
| **Key set** | One version-numbered set of card management keys: `KVN` → S-ENC / S-MAC / DEK (SCP02, 3DES) or ENC/MAC/DEK (SCP03, AES). Your `--kv`/`--keyver` selects it. | Password entries in a vault, numbered | PUT KEY (`put-auth`, `put_sc_key`) |
| **Card data** | Small data objects readable with `GET DATA`: IIN (tag `42`), CIN (Card Image Number, tag `45`), CPLC (chip production data, ISO/IEC 7816-6, tag `9F7F`), Card Recognition Data (ISO/IEC 7816-6 `66` → `73`). | Serial number + config files | Factory / `STORE DATA` |

### Is there a "global directory"?

No — despite the name sounding official, **"Global Directory" is not a
GlobalPlatform spec term** (it appears nowhere in GP 2.1.1/2.2.1/2.3.1,
and neither `gp` nor `gpshell` queries such a thing). What people
usually mean is one of:

- **`GET DATA P1-P2=2F00`** (GP 2.2.1 §11.3.2.1, from ISO/IEC 7816-4):
  a directory of the AIDs of the applications on the card
  (tag list `5C 00` in the data field).
- **ISO 7816-4 SELECT enumeration**: `00 A4 04 00 00`, then
  `00 A4 04 02 00` for the next AID until `6A82`.
- The **bit-combined `GET STATUS P1=0xB0`** (`0x80|0x20|0x10` =
  ISD + load files + modules in one query): legal only if the card
  supports P1 bit combinations (GP 2.2+ encodes P1 as bits; the four
  values `80`/`40`/`20`/`10` are the ones that *shall* be supported).
- In legacy **Open Platform 2.0.1'** mode, `gpshell`
  `get_status -element e0` lists everything — a different, older scheme.

If a document or tool calls any of these a "global directory",
it is using informal vocabulary, not a spec concept.

### What about "files" (MF/DF/EF)?

JavaCards are *applet-centric*, not file-system-centric. The classic
ISO 7816-4 file structure (Master File, Dedicated Files, Elementary
Files) is **not part of the Java Card API** — if you see it, it is
provided *by an applet* (e.g. an ISO 7816 or eID/UICC applet emulating
a file system), not by the platform.

## Seeing it with the tools: GET STATUS element types

All three tools enumerate the card via `GET STATUS` with different `P1`
"element" types (`GP 2.1.1 §9.4.2.1` / `GP 2.2.1 Table 11-32`) — and
they differ in how tolerant they are (see also
[tools/gpshell.md](./tools/gpshell.md)):

| `GET STATUS` P1 | Returns | In `gp --list` output | In legacy `gpshell` script |
|---|---|---|---|
| `0x80` | Issuer Security Domain — **includes the card lifecycle state** (`OP_READY` etc.) | `ISD: … (OP_READY)` row | `get_status -element 80` |
| `0x40` | Applications *and* Security Domains | `APP:` rows | `get_status -element 40` |
| `0x10` | Load files **with** their executable modules | `PKG:` rows incl. `Applet:` children | `get_status -element 10` |
| `0x20` | Load files | `PKG:` rows | `get_status -element 20` |

Notes:

- `gp` queries all four and only *warns* per failing element, which
  is why it can still produce a listing on old cards that answer some
  element types with `6A88` (`gp --verbose --list` shows the warnings).
- `gpshell3 list-apps` insists on `0x40` first and is fatal on errors;
  use `gpshell3 … apdu --auth 80F2<p1>00024F0000` to query elements
  manually (on `6310` "more data", repeat with P2 bit 0 set).
- Keys are *not* part of GET STATUS: list them with
  `gpshell3 list-keys` (legacy: `get_key_information_templates`,
  `GET DATA` tag `E0`) or look at `gp --info` output; certificates
  come from `GET CERTIFICATE`.

## Lifecycle state values

For reference, the byte values `gp` and `gpshell` decode
(GP 2.2.1 §5, Tables 11-3ff):

| Kind | States |
|---|---|
| Card (via ISD) | `01 OP_READY`, `07 INITIALIZED`, `0F SECURED`, `7F CARD_LOCKED`, `FF TERMINATED` |
| Load file | `01 LOADED` |
| Application | `03 INSTALLED`, `07 SELECTABLE`, `83 LOCKED` (+ app-specific) |
| Security Domain | `03 INSTALLED`, `07 SELECTABLE`, `0F PERSONALIZED`, `83 LOCKED` |

The card-level states are explained in more depth in
[JavaCard-GlobalPlatform-States.md](./JavaCard-GlobalPlatform-States.md).
