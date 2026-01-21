# Cisco ACI – SNMPv3 Polling Configuration

## Key principles (read first)

* SNMP is **configured only on APIC**
* Leaf/spine switches **inherit SNMP config**
* SNMPv3 **requires**:

  * SNMPv3 user
  * SNMP policy
  * SNMP client group (this is where the monitoring server is allowed)
  * Policy attachment to the fabric
* Switch CLI is not used**

---

## STEP 1 – Decide management connectivity

Determine how your monitoring server will reach the switches:

### Option A – Out-of-Band (OOB) management

* Uses **mgmt0 IP** on the switches
* Recommended
* No contracts required

### Option B – In-Band management

* Uses **in-band SVI**
* Requires contracts
* More complex

> The steps below apply to **both**; contract notes are marked where needed.

---

## STEP 2 – Verify management IPs exist

Ensure switches already have management IPs.

### OOB:

```
Tenants → mgmt → Node Management EPGs → OOB
```

### In-Band:

```
Tenants → mgmt → Node Management EPGs → InB
```

Each leaf/spine must have:

* An IP address
* Correct gateway
* Reachability from the monitoring server

---

## STEP 3 – Create SNMP Policy (SNMPv3 user is defined here)

### Path:

```
Fabric
 → Fabric Policies
  → Pod Policies
   → Policies
    → SNMP
```

### Actions:

1. Click **Create SNMP Policy**
2. Set:

   * **Admin State** → Enabled

### Configure SNMPv3 User:

* Click **+** under *SNMPv3 Users*
* Configure:

  * Username
  * Security Level (authPriv recommended)
  * Auth Type (SHA / SHA-256)
  * Auth Password
  * Privacy Type (AES-128 / AES-256)
  * Privacy Password

> 🔹 This creates the SNMPv3 user on all switches once applied.

---

## STEP 4 – Allow the SNMP monitoring server IP

### THIS IS WHERE THE POLLING SERVER IP IS ALLOWED
> Note: When an SNMP management station connects with APIC using SNMPv3, APIC does not enforce the client IP address specified in the SNMP client group profile. For SNMPv3, the management station must exist in the Client Entries list, but the IP address need not match, as the SNMPv3 credentials alone are sufficient for access.

In the **same SNMP Policy**:

### Path inside policy:

**Client Group Policies**

### Actions:

1. Click **+ Create SNMP Client Group**

2. Enter:

   * **Name** (example: `NMS-SNMPv3`)
   * **Associated Management EPG**

     * OOB → `mgmt` / `OOB`
     * In-Band → `mgmt` / `InB`

3. Under **Client Entries**:

   * Click **+**
   * Enter:

     * Name (example: `Monitoring-Server`)
     * **IP Address of SNMP monitoring server**

> ✅ This is the **only place** where the SNMP poller IP is allowed

> ✅ Required even for SNMPv3

> ⚠ For SNMPv3, the IP does **not have to match**, but **an entry must exist**

---

## STEP 5 – (Optional) Ignore traps

Since you are **not using traps**:

* Do **not** configure Trap Forward Servers
* This does **not** affect polling

---

## STEP 6 – Attach SNMP Policy to a Pod Policy Group

Without this, **SNMP will never activate**.

### Path:

```
Fabric
 → Fabric Policies
  → Pod Policies
   → Policy Groups
```

### Actions:

1. Create or edit a **Pod Policy Group**
2. Set:

   * **SNMP Policy** → select your SNMP policy
3. Submit

---

## STEP 7 – Apply Pod Policy Group to Fabric Profile

### Path:

```
Fabric
 → Fabric Policies
  → Pod Policies
   → Profiles
    → default
```

### Actions:

* Select the **Pod Policy Group** you just created
* Submit

> 🔹 This step pushes SNMP config to all nodes in the pod

---

## STEP 8 – (In-Band ONLY) Configure contract

**Skip this if using OOB management**

### Required contract:

* UDP 161
* Provided by `mgmt` EPG
* Consumed by monitoring server EPG

Without this:
❌ SNMP polling will fail

---

## STEP 9 – Verify on the switch (read-only)

On a leaf or spine:

```bash
show snmp user
show snmp group
show snmp host
```

You should see:

* SNMPv3 user
* SNMP group
* Client group association

If empty → policy not applied

---

## STEP 10 – Test from monitoring server

Example Linux test:

```bash
snmpwalk -v3 \
 -u <username> \
 -l authPriv \
 -a SHA \
 -A <auth-pass> \
 -x AES \
 -X <priv-pass> \
 <switch-mgmt-ip> 1.3.6.1.2.1.1
```

---
