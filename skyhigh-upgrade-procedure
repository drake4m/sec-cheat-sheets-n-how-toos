# Skyhigh Secure Web Gateway – Upgrade to 12.2.20 (Virtual Appliances, Sticky Repo)

> **Goal**
> Perform a controlled, production-grade upgrade of **Skyhigh Secure Web Gateway (SWG) on-prem** virtual appliances to **version 12.2.20**, using:
>
> * `mwg-switch-repo --sticky 12.2.20`
> * `yum upgrade yum`
> * `yum upgrade`
> * `reboot`
>
> …with **VM snapshots** as the main rollback mechanism and **rolling upgrade** across all cluster members. ([Skyhigh Security][1])

---

## 1. Scope & Assumptions

* Product: **Skyhigh Secure Web Gateway (On-Prem)**, previously McAfee Web Gateway. ([docs.sekoia.io][2])
* Platform: **Virtual machines** (VMware/Hyper-V/KVM/etc.).
* Target version: **12.2.20 main release, sticky**.
* Deployment:

  * Appliances are in **Central Management**.
  * Possibly behind **load balancer / ProxyHA / routing** (covered generically).
* Upgrade mode: **Online upgrade via Skyhigh repo**.
* Rollback: **Hypervisor VM snapshots** (per node).

If any of these are false in your environment, you adapt the wording but keep the structure.

---

## 2. Change Overview

### 2.1 High-Level Steps

For **each SWG node** (one at a time):

1. Drain traffic from node (LB / routing / PAC).
2. Take **VM snapshot**.
3. On SWG CLI (as `root`):

   ```bash
   mwg-switch-repo --sticky 12.2.20
   yum upgrade yum
   yum upgrade
   reboot
   ```
4. Verify version and health:

   * CLI: `mwg-info version`
   * GUI: `Configuration → Appliances` (version & status). ([Skyhigh Security][3])
5. Put node back in service.
6. Repeat on **next node**.

---

## 3. Safety & Rollback

### 3.1 Backups

Before any upgrade:

* From GUI (**per Skyhigh prerequisites**): ([Skyhigh Security][4])

  1. Log in to SWG Web UI.
  2. Go to: `Troubleshooting → <appliance name> → Backup/Restore`.
  3. Check **“SSO Credentials”** if used.
  4. Click **“Back up to file…”** and download.
* Store backups in a **central, backed-up location**, not only on your workstation.

> Note: In a Central Management cluster, the backup contains policy for the **entire cluster**; device-specific settings are separated internally (UUID-based). ([Skyhigh Security][5])

### 3.2 VM Snapshots (Main Rollback)

For every node, right before upgrade:

* **Power state**: Node stays ON, but traffic is drained.
* Take a **snapshot**:

  * Name example: `SWG-<hostname>-before-12.2.20`.
  * Include disk. RAM snapshot is optional and generally not needed.
* Confirm snapshot succeeded in hypervisor UI.

### 3.3 Last-Resort Rollback

If snapshot cannot be used or is lost:

* **Reimage** the VM with an older ISO, then **restore configuration backup** with correct UUID. ([Skyhigh Security][5])
* This is slower (and more manual) than snapshot revert → so snapshot is your primary strategy.

---

## 4. Pre-Upgrade Checklist

Do this **once** for the whole upgrade.

### 4.1 Version & Release Planning

1. Record current versions from GUI:

   * `Configuration → Appliances` – note **version** for every node. ([Skyhigh Security][6])
2. Confirm **12.2.20** is a valid **main/sticky** release in your repo.

   * From one node:

     ```bash
     mwg-switch-repo -l
     ```
   * Check that `12.2.20` is listed as a valid version. ([Skyhigh Security][1])

### 4.2 Health & Capacity Check

On each node (GUI & CLI): ([Skyhigh Security][4])

* Dashboard:

  * No critical **alerts** (disk nearly full, memory issues, constant high CPU).
* Logs:

  * No persistent errors in core logs (`mwg-core.errors.log`, `mwg-coordinator.errors.log`).
* Disk:

  * `/opt` and other relevant partitions have comfortable free space.

If a node is already unhealthy, **fix it first**. Upgrading a half-broken box is how you turn it into a fully broken box.

### 4.3 Central Management State

From GUI: ([Skyhigh Security][6])

* `Configuration → Appliances`:

  * All nodes are **online** and **synchronized**.
* Confirm **network groups** and **update groups** are correctly defined, so you know which nodes are related.

### 4.4 Connectivity to Repositories

Ensure nodes can reach Skyhigh repo endpoints (via direct or next-hop proxy as configured). ([Skyhigh Security][3])

* From a node:

  ```bash
  yum clean all
  yum repolist
  ```
* If repos are unreachable, fix routing/proxy/DNS before scheduling the upgrade.

---

## 5. Upgrade Strategy in a Cluster

### 5.1 Rolling Upgrade Pattern

You **never** upgrade all nodes at once.

1. Pick **one node** (non-critical / low traffic if possible).
2. Drain traffic from this node.
3. Upgrade & validate.
4. Put back in service.
5. Move on to next node.

For Central Management, vendor guidance is to update all nodes in a cluster to the same version; typically you upgrade cluster nodes from the interface or CLI in a controlled sequence. ([Skyhigh Security][1])

### 5.2 Traffic Handling

Depending on deployment:

* **Load balancer front-end**:

  * Disable node in the pool (mark as “drain” / “out of service”).
  * Wait for active sessions to drain (or force a cutover at window start).
* **ProxyHA / routing**:

  * Adjust WCCP / routing / firewall rules or HA config so that traffic no longer uses this node.
* **Standalone**:

  * Accept that this node’s users are impacted, or temporarily redirect them to another proxy.

Keep the node **reachable for SSH/GUI**, but **out of production traffic** during upgrade.

---

## 6. Detailed Procedure – Per Node

This section is repeated for **each cluster member**, one at a time.

### 6.1 Node Pre-Checks

On **target node**:

1. Confirm it is currently not handling production traffic (LB / routing drained).
2. Confirm:

   * Config backup exists centrally.
   * Hypervisor snapshot is possible (enough disk space).
3. Optionally, note current version via CLI:

   ```bash
   mwg-info version
   ```

   ([Skyhigh Security][5])

### 6.2 Create VM Snapshot

In your hypervisor:

* Snapshot **before** touching the repo or running `yum`.
* Snapshot name example:

  * `SWG-node1-pre-12.2.20-<YYYYMMDD>`.

---

### 6.3 Set Sticky Repository to 12.2.20

On the node (SSH or console, as `root`):

1. Start a **tmux** session to avoid upgrade breaking due to SSH disconnects: ([Skyhigh Security][3])

   ```bash
   tmux
   ```
2. Check current repo configuration:

   ```bash
   mwg-switch-repo -l
   ```
3. Set sticky to **12.2.20**:

   ```bash
   mwg-switch-repo --sticky 12.2.20
   ```

   * This pins SWG to **exactly 12.2.20**.
   * While sticky is set, **you cannot upgrade via Manager**; CLI only. ([Skyhigh Security][1])

---

### 6.4 Run `yum upgrade yum`

Vendor documentation recommends upgrading `yum` first before doing the full upgrade from console. ([Skyhigh Security][3])

```bash
yum upgrade yum
```

* Accept the proposed upgrades (`y`).
* Wait for completion; check for **no errors**.

---

### 6.5 Run `yum upgrade`

Now perform the full package upgrade:

```bash
yum upgrade
```

* Confirm that the packages list includes the SWG components.
* When prompted:

  * Review briefly (sanity check).
  * Answer `y` to proceed.

When the command finishes, ensure:

* No “failed” transactions.
* No unresolved dependency errors.

> Note: For sticky release upgrades, Skyhigh explicitly documents `mwg-switch-repo --sticky <version>` then `yum upgrade`. Your extra `yum upgrade yum` step is fine and aligns with generic best practice for console upgrades. ([Skyhigh Security][1])

---

### 6.6 Reboot the Node

Even if the upgrade doesn’t explicitly force a reboot, **always reboot** after a SWG software upgrade. ([Skyhigh Security][3])

```bash
reboot
```

* Keep the node **out of production traffic** until validation is done.

Wait until:

* VM boots,
* Login prompt appears on console,
* SSH becomes available.

---

## 7. Post-Upgrade Verification (Per Node)

### 7.1 CLI Version & Basic Health

1. SSH back to the node; run:

   ```bash
   mwg-info version
   ```

   Confirm the installed version is **12.2.20** (exact match, including build if shown). ([Skyhigh Security][5])

2. Basic system checks (optional but useful):

   ```bash
   df -h
   free -m
   uptime
   ```

   Ensure no partitions are dangerously full and load is reasonable.

### 7.2 GUI Checks

From the SWG Web UI:

1. Go to `Configuration → Appliances`.
2. Select the upgraded node.
3. Check:

   * **Version** shows 12.2.20.
   * Node status is **Online / OK** (no error icons). ([Skyhigh Security][6])
4. Check `Dashboard`:

   * No new critical alerts after reboot.

If node is in Central Management, confirm:

* Policy sync is fine (no sync errors).
* Node is in correct **network group** / **update group**. ([Skyhigh Security][6])

---

## 8. Functional & Cluster-Level Tests

### 8.1 Node-Level Functional Tests

Temporarily send **only test traffic** to this node (via LB or direct proxy config) and validate:

1. **Explicit HTTP/HTTPS**:

   * Browse `http://example.com` and a few HTTPS sites.
2. **Category enforcement**:

   * Hit a known-blocked category (e.g. gambling/social) → block page.
   * Hit a known-allowed site → allowed.
3. **Authentication (if used)**:

   * Test user login (AD/LDAP/NTLM/Kerberos/SAML).
   * Confirm username & group in logs.
4. **Malware / content filtering**:

   * EICAR test file → must be blocked.
5. **SSL inspection**:

   * Test with a site that is normally inspected.
   * Verify no unexpected cert errors (assuming root CA is already trusted).

If these fail **only on upgraded node** and not on others, you have a regression → see rollback section.

### 8.2 Cluster Consistency

After you’ve upgraded several nodes:

* `Configuration → Appliances`:

  * Ensure **all upgraded nodes** show **exact same version** 12.2.20.
* If Central Management:

  * Confirm no **version mismatch** warnings in CM. ([Skyhigh Security][1])

---

## 9. Put Node Back in Service

When a node passes verification:

1. Re-enable it in LB pool / routing / ProxyHA.
2. Monitor:

   * Connections count
   * CPU / memory
   * Error logs

If everything is stable for 10–30 min, proceed to the **next node** and repeat sections **6–9**.

---

## 10. Rollback Procedure

### 10.1 Fast Rollback – VM Snapshot Revert

If an upgraded node is broken and you cannot fix it quickly:

1. Drain traffic away again (LB / routing).
2. In hypervisor:

   * Revert to the **pre-upgrade snapshot**.
3. Boot and verify:

   * Version is back to pre-12.2.20,
   * Node behaves as before.

> Reminder: Any **configuration changes or logs** after snapshot time are lost on that node. Policy changes should be covered by CM though.

### 10.2 Slow Rollback – Reimage + Restore

If snapshot is not usable, or you need to fall back to an older baseline:

1. Deploy SWG from the older ISO (reimage). ([Skyhigh Security][7])
2. Restore configuration backup:

   * Use the documented process ensuring the **UUID mapping** is correct when restoring policy to replacement appliance. ([Skyhigh Security][5])
3. Rejoin Central Management and LB/HA as previously configured.

---

## 11. Housekeeping After All Nodes Are Upgraded

When **all SWG nodes** are on 12.2.20 and stable:

1. **Clean up snapshots** after a defined soak period (e.g. 1–2 weeks) to free storage.
2. Update documentation:

   * CMDB / inventory version for each appliance.
   * Internal runbooks to reference **“Upgrade to 12.2.20 via mwg-switch-repo --sticky + yum”** process.
3. Consider switching back to **main** repo if you don’t want to remain permanently sticky:

   ```bash
   mwg-switch-repo main
   ```

   ([Skyhigh Security][1])

---

## 12. Example Command Sequence (Node Cheat Sheet)

You can drop this in a separate `UPGRADE-12.2.20.md` or `RUNBOOK.md` section.

```bash
# 1) Start safe session
tmux

# 2) Check current repo config
mwg-switch-repo -l

# 3) Set sticky to target version
mwg-switch-repo --sticky 12.2.20

# 4) Upgrade yum itself
yum upgrade yum

# 5) Upgrade all packages (including SWG)
yum upgrade

# 6) Reboot to activate new version and kernel
reboot
```

After reboot:

```bash
# Check installed version
mwg-info version
```

Then verify in GUI: `Configuration → Appliances` → select node → confirm **12.2.20** and healthy state.
