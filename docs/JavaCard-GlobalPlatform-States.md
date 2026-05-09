# Specification

I have taken my information from the _GlobalPlatform Card Specification v2.3.1_.
I am fairly new to this topic, so this overview might be wrong in some points.
Please double-check, if unsure.

# States

There are five states for a GlobalPlatform card.
Please compare to the spec _GPC_CardSpecification_v2.3.1_PublicRelease_CC.pdf_ chapter 5.1.1, page 51.

- `OP_READY`
- `INITIALIZED`
- `SECURED`
- `CARD_LOCKED`
- `TERMINATED`

Note: Applets and Security Domains have their own life cycle states.
I am not covering them here.

# Initial state of a fresh card

When you order a fresh JavaCard, it should come in `OP_READY` state.
However, I have also received one in `INITIALIZED`.
I still really don't understand the difference, but the spec (page 52) says:

> This state may be used to indicate that some initial data has been populated
> (e.g. Issuer Security Domain keys and/or data) but that the card is
> not yet ready to be issued to the Cardholder.

# State changes

- `OP_READY` -> `INITIALIZED`: **irreversible**
- `INITIALIZED` -> `SECURED`: **irreversible**
- `SECURED` -> `CARD_LOCKED`: reversible

You can also go to `TERMINATED` from any state, but this is a final
change which makes the card unusable and the state change is **irreversible**.

See page 54 of the spec.

# Privileges

Some state transitions require specific privileges assigned to the Security Domain or applet:

- **Card Lock privilege**: Required to lock (`SECURED` → `CARD_LOCKED`) and unlock (`CARD_LOCKED` → `SECURED`) the card.
- **Card Terminate privilege**: Required to transition to `TERMINATED` from any state.

The Issuer Security Domain (ISD) always has these privileges. Supplementary Security Domains (SSDs) and applets can have them if assigned at install time.

# Allowed actions per state

Compare to _Table 11-1: Authorized GlobalPlatform Commands per Card Life Cycle State_, page 142.

| **Action**                  | **OP_READY**   | **INITIALIZED** | **SECURED** | **CARD_LOCKED** | **TERMINATED** | **Keys required?** |
|-----------------------------|----------------|-----------------|-------------|-----------------|----------------|--------------------|
| **Personalization (CPLC)**  | ✅ (only once!) | ❌               | ❌           | ❌               | ❌              | 🔑                 |
| **Change keys**             | ✅              | ✅               | ✅           | ❌               | ❌              | 🔑                 |
| **Install applet**          | ✅              | ✅               | ✅           | ❌               | ❌              | 🔑                 |
| **Select default applet**   | ✅              | ✅               | ✅           | ❌               | ❌              | 🆓                 |
| **Delete applet**           | ✅              | ✅               | ✅           | ❌               | ❌              | 🔑                 |
| **Use applet**              | ✅              | ✅               | ✅           | ❌               | ❌              | 🆓                 |
| **Switch to** `INITIALIZED` | ✅              | -               | ❌           | ❌               | ❌              | 🔑                 |
| **Switch to** `SECURED`     | ❌              | ✅               | -           | ✅               | ❌              | 🔑                 |
| **Switch to** `CARD_LOCKED` | ❌              | ❌               | ✅           | -               | ❌              | 🔑                 |
| **Switch to** `TERMINATED`  | ✅              | ✅               | ✅           | ✅               | -              | 🔑                 |
| **Lock applet**             | ✅              | ✅               | ✅           | ❌               | ❌              | 🔑                 |
| **Unlock applet**           | ✅              | ✅               | ✅           | ❌               | ❌              | 🔑                 |

If the applet allows itself to be reset, like for example in SmartPGP you can set new keys,
this is part of the _Use applet_ action.
