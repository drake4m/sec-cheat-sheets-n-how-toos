# Fortinet FortiGate Professional Cheat Sheet - Enhanced Edition
> **Version**: FortiOS 7.0, 7.2, 7.4, 7.6  
> **Last Updated**: 2025  
> **Scope**: FortiGate NGFW, FortiManager, FortiAnalyzer, Advanced Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    FORTIGATE ENTERPRISE ARCHITECTURE                       │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐            │
│  │ FortiManager │◄─────►│  FortiGate   │◄─────►│  FortiGate   │            │
│  │   Central    │  541  │   Primary    │  HA   │  Secondary   │            │
│  │  Management  │  TCP  │   Active     │Sync   │   Standby    │            │
│  └──────┬───────┘       └──────┬───────┘       └──────┬───────┘            │
│         │                      │                      │                    │
│    ┌────▼────┐          ┌──────▼───┐            ┌──────▼───┐               │
│    │ FortiView│         │   NPU    │            │   NPU    │               │
│    │Analytics │         │ NP6/NP7  │            │ NP6/NP7  │               │
│    └─────────┘          └──────────┘            └──────────┘               │
│                                │                        │                  │
│                          ┌──────▼───┐            ┌──────▼───┐              │
│                          │   SPU    │            │   SPU    │              │
│                          │  CP9/CP10│            │  CP9/CP10│              │
│                          └──────────┘            └──────────┘              │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Table of Contents
- [System Architecture & Packet Flow](#system-architecture--packet-flow)
- [System Administration](#system-administration)
- [High Availability Architecture](#high-availability-architecture)
- [Network Configuration & VDOMs](#network-configuration--vdoms)
- [Security Policy Chains](#security-policy-chains)
- [Advanced NAT & Central SNAT](#advanced-nat--central-snat)
- [VPN Infrastructure](#vpn-infrastructure)
- [Deep Packet Inspection & UTM](#deep-packet-inspection--utm)
- [NPU/SPU Hardware Acceleration](#npuspu-hardware-acceleration)
- [Advanced Monitoring & Diagnostics](#advanced-monitoring--diagnostics)
- [FortiManager & Central Management](#fortimanager--central-management)
- [Protocol & Port Reference](#protocol--port-reference)
- [Performance Optimization](#performance-optimization)
- [Advanced Troubleshooting Matrix](#advanced-troubleshooting-matrix)

---

## System Architecture & Packet Flow

### FortiGate Packet Processing Chain
```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        FORTIGATE PACKET FLOW CHAIN                           │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  INGRESS PACKET                                                              │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────┐    Stage 1: NPU Offload Check                               │
│  │  NPU Engine │    Function: FastPath Decision                              │
│  │  (NP6/NP7)  │    Bypass Kernel for Known Sessions                         │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 2: DoS Protection                                  │
│  │ DoS Policy  │    Function: Rate Limiting                                  │
│  │   Engine    │    SYN Flood, ICMP Flood Protection                         │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 3: IP Integrity                                    │
│  │  IP Header  │    Function: Header Validation                              │
│  │  Validation │    TTL, Checksum, Fragment Assembly                         │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 4: IPSec Decryption                                │
│  │VPN Processor│    Function: Tunnel Termination                             │
│  │  (SPU/CPU)  │    IPSec/SSL VPN Processing                                 │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 5: DNAT (VIP)                                      │
│  │ Destination │    Function: Virtual IP Translation                         │
│  │     NAT     │    Port Forwarding                                          │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 6: Routing Decision                                │
│  │   Routing   │    Function: Route/Policy Route                             │
│  │   Engine    │    ECMP, SD-WAN Selection                                   │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 7: Policy Lookup                                   │
│  │  Firewall   │    Function: Security Policy Match                          │
│  │   Policy    │    Source/Dest/Service/App Control                          │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 8: Session Creation                                │
│  │   Session   │    Function: State Table Entry                              │
│  │   Helper    │    ALG Processing                                           │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 9: UTM Inspection                                  │
│  │UTM Processor│    Function: AV/IPS/AppCtrl/WebFilter                       │
│  │ (Proxy/Flow)│    DLP/Email Filter/File Filter                             │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 10: SNAT (IP Pool)                                 │
│  │   Source    │    Function: Outbound NAT                                   │
│  │     NAT     │    Dynamic/Static Pool                                      │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 11: IPSec Encryption                               │
│  │VPN Processor│    Function: Tunnel Encapsulation                           │
│  │  (SPU/CPU)  │    Policy-based/Route-based VPN                             │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Stage 12: Egress Shaping                                 │
│  │Traffic Shaper│   Function: QoS/Bandwidth Management                       │
│  │   Engine    │    Priority Queuing                                         │
│  └──────┬──────┘                                                             │
│         │                                                                    │
│         ▼                                                                    │
│  EGRESS PACKET                                                               │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Packet Flow Debug Commands
```bash
# Flow Debug Configuration
diagnose debug reset                         # Reset all debug
diagnose debug enable                        # Enable debug output
diagnose debug flow filter clear            # Clear all filters
diagnose debug flow filter saddr 10.0.0.1   # Source address filter
diagnose debug flow filter daddr 192.168.1.1 # Destination filter
diagnose debug flow filter port 443         # Port filter
diagnose debug flow filter proto 6          # Protocol filter (6=TCP)
diagnose debug flow show function-name enable # Show function names
diagnose debug flow show iprope enable      # Show IP rope info
diagnose debug flow trace start 100         # Start trace (100 packets)

# NPU Flow Analysis
diagnose npu np6 dce-info                   # DCE information
diagnose npu np6 session-stats              # Session statistics
diagnose npu np6 sse-stats                  # SSE statistics
diagnose npu np6 synproxy-stats            # SYN proxy stats

# Session Analysis
diagnose sys session filter clear
diagnose sys session filter src 10.0.0.1
diagnose sys session filter dst 192.168.1.1
diagnose sys session filter dport 443
diagnose sys session list                   # List filtered sessions
diagnose sys session clear                  # Clear sessions
```

---

## Advanced NAT & Central SNAT

### NAT Architecture
```
┌────────────────────────────────────────────────────────────────────────┐
│                     FORTIGATE NAT PROCESSING                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  NAT ORDER OF OPERATIONS:                                              │
│  1. DNAT (VIP) - Inbound                                               │
│  2. Central SNAT - After routing                                       │
│  3. Policy NAT - Per firewall policy                                   │
│                                                                        │
│  ┌──────────────────────────────────────────────────────┐              │
│  │                  DNAT FLOW (VIP)                     │              │
│  ├──────────────────────────────────────────────────────┤              │
│  │                                                      │              │
│  │External: 203.0.113.10:443 ──► Internal: 10.1.1.10:443│              │
│  │                                                      │              │
│  │  config firewall vip                                 │              │
│  │      edit "WebServer-VIP"                            │              │
│  │      set extip 203.0.113.10                          │              │
│  │      set mappedip 10.1.1.10                          │              │
│  │      set extintf "wan1"                              │              │
│  │      set portforward enable                          │              │
│  │      set extport 443                                 │              │
│  │      set mappedport 443                              │              │
│  │  end                                                 │              │
│  └──────────────────────────────────────────────────────┘              │
│                                                                        │
│  ┌──────────────────────────────────────────────────────┐              │
│  │                CENTRAL SNAT TABLE                    │              │
│  ├──────────────────────────────────────────────────────┤              │
│  │                                                      │              │
│  │  Priority │ Source      │ Destination│ NAT Pool      │              │
│  │  ─────────┼─────────────┼────────────┼───────────────│              │
│  │     1     │ 10.1.0.0/24 │ 0.0.0.0/0  │ Pool-Internet │              │
│  │     2     │ 10.2.0.0/24 │ 8.8.8.8/32 │ Pool-DNS      │              │
│  │     3     │ 192.168.0.0/16│ Any      │ Outgoing-IP   │              │
│  │                                                      │              │
│  └──────────────────────────────────────────────────────┘              │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Central SNAT Configuration
```bash
# Central SNAT Table Configuration
config firewall central-snat-map
    edit 1
        set orig-addr "Internal-Subnet"
        set dst-addr "all"
        set nat-ippool "NAT-Pool-1"
        set protocol 0
        set orig-port 0
        set nat-port 0
    next
end

# IP Pool Configuration
config firewall ippool
    edit "NAT-Pool-1"
        set type overload
        set startip 203.0.113.100
        set endip 203.0.113.200
        set arp-reply enable
        set nat64 disable
        set comments "Primary NAT Pool"
    next
end

# Advanced NAT Options
config system settings
    set snat-route-change enable            # SNAT on route change
    set central-nat enable                  # Enable Central NAT
end

# NAT Session Monitoring
diagnose sys session filter clear
diagnose sys session filter nat both
diagnose sys session list
```

### NAT Troubleshooting Commands
```bash
# NAT Debug
diagnose debug reset
diagnose debug enable
diagnose debug application dnsproxy -1      # DNS proxy debug
diagnose debug flow filter saddr 10.0.0.1
diagnose debug flow filter daddr 8.8.8.8
diagnose debug flow trace start 10

# NAT Statistics
diagnose firewall ippool list              # List IP pools
diagnose firewall ippool stats             # IP pool statistics
get system session status                  # Session statistics
diagnose sys session stat                  # Detailed session stats

# NAT Table Analysis
diagnose sys session filter nat src
diagnose sys session filter nat dst
diagnose sys session filter nat both
diagnose sys session list
```

---

## High Availability Architecture

### HA Cluster Architecture
```
┌────────────────────────────────────────────────────────────────────────┐
│                      FORTIGATE HA ARCHITECTURE                         │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   Primary Unit                         Secondary Unit                  │
│  ┌──────────────┐     Heartbeat      ┌──────────────┐                  │
│  │              │◄──────────────────►│              │                  │
│  │  FortiGate   │     HA Interface   │  FortiGate   │                  │
│  │   Active     │     (Port3/Port4)  │   Standby    │                  │
│  │              │                    │              │                  │
│  └──────┬───────┘                    └──────┬───────┘                  │
│         │                                   │                          │
│         │ Session Sync                      │                          │
│         └───────────────────────────────────┘                          │
│                                                                        │
│  HA Synchronization Items:                                             │
│  ├─ Configuration Files                                                │
│  ├─ Session Table                                                      │
│  ├─ IPSec SA                                                           │
│  ├─ Routing Table (if enabled)                                         │
│  ├─ DHCP Leases                                                        │
│  └─ User Authentication States                                         │
│                                                                        │
│  HA Split-Brain Prevention:                                            │
│  ├─ Priority (0-255)                                                   │
│  ├─ Override Enable/Disable                                            │
│  ├─ Monitor Interfaces                                                 │
│  └─ Uptime Difference                                                  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Advanced HA Configuration
```bash
# HA Configuration with Advanced Options
config system ha
    set mode a-p                           # Active-Passive
    set group-name "FGT-HA-CLUSTER"
    set password ENC <encrypted>
    set hbdev "port3" 50 "port4" 50       # Dual heartbeat
    set session-pickup enable               # Session failover
    set session-pickup-delay enable        # Delay pickup
    set session-pickup-connectionless enable
    set session-sync-dev "port3" "port4"   # Session sync interfaces
    set priority 200                       # Higher = preferred
    set override enable                     # Force priority
    set monitor "port1" "port2"           # Monitor interfaces
    set pingserver-monitor-interface "port1"
    set pingserver-failover-threshold 3
    set pingserver-flip-timeout 60
    set gratuitous-arps enable
    set arps 5
    set arps-interval 1
    set cpu-threshold "5 0 0"             # CPU thresholds
    set memory-threshold "5 0 0"          # Memory thresholds
    set standalone-config-sync enable      # Config sync in standalone
end

# HA Debugging
diagnose debug reset
diagnose debug enable
diagnose debug application hasync -1
diagnose debug application hatalk -1
diagnose debug console timestamp enable

# HA Monitoring Commands
get system ha status                       # Detailed HA status
diagnose sys ha status                     # HA state information
diagnose sys ha checksum cluster          # Config checksums
diagnose sys ha reset-uptime              # Reset uptime counters
execute ha manage <id>                    # Connect to cluster member
diagnose sys ha dump-by vcluster
```

---

## NPU/SPU Hardware Acceleration

### NPU Architecture & Commands
```bash
# NPU Information
get hardware npu np6 port-list            # NP6 port mapping
diagnose npu np6 port-list                # Detailed port info
diagnose npu np6 dce-info                 # DCE information
diagnose npu np6 sse-stats                # SSE statistics
diagnose npu np6 synproxy-stats          # SYN proxy stats

# NPU Session Offloading
diagnose npu np6 session-stats           # Offloaded sessions
diagnose npu np6 session-clear           # Clear NPU sessions
diagnose sys npu-session list            # List NPU sessions

# SPU (CP9/CP10) Commands
diagnose vpn ipsec stats crypto          # Crypto acceleration stats
diagnose npu cp9 stats                   # CP9 statistics
get system npu                           # NPU configuration

# NPU Configuration
config system npu
    set capwap-offload enable
    set gre-offload enable
    set ipsec-offload enable
    set ssl-offload enable
    set ueip-offload enable
    set np-accel-mode basic              # Acceleration mode
    set strip-esp-padding enable
    set strip-clear-text-padding enable
end

# NPU Troubleshooting
diagnose npu np6 ipsec-stats            # IPSec offload stats
diagnose npu np6 spm-stats              # SPM statistics
diagnose npu np6 xfrm-stats             # Transform stats
```

---

## Protocol & Port Reference

### FortiGate Service Ports
```
┌───────────────────────────────────────────────────────────────────┐
│                     FORTIGATE PORT MATRIX                         │
├─────────────────┬──────────┬──────────────────────────────────────┤
│ Service         │ Port     │ Description                          │
├─────────────────┼──────────┼──────────────────────────────────────┤
│ HTTPS Admin     │ 443/tcp  │ Web GUI Management                   │
│ SSH             │ 22/tcp   │ CLI Management                       │
│ TELNET          │ 23/tcp   │ CLI (disabled by default)            │
│ FortiManager    │ 541/tcp  │ Central Management                   │
│ FGFM            │ 703/tcp  │ FortiGate-FortiManager Protocol      │
│ FortiAnalyzer   │ 514/udp  │ Log forwarding (OFTP/Syslog)         │
│ OFTP-SSL        │ 514/tcp  │ Encrypted log forwarding             │
│ FortiGuard      │ 443/tcp  │ Updates and Web Filter               │
│                 │ 8888/tcp │ FortiGuard backup                    │
│                 │ 53/udp   │ FortiGuard DNS                       │
│ FSSO            │ 8000/tcp │ Fortinet Single Sign-On              │
│ FSSO-Polling    │ 445/tcp  │ DC Agent polling                     │
│ FortiClient     │ 8013/tcp │ FortiClient registration             │
│ CAPWAP          │ 5246/udp │ FortiAP control                      │
│ HA Heartbeat    │ Protocol │ Proprietary L2 protocol              │
│                 │ 23      │ (IP Protocol 23)                      │
│ HA Sync         │ 703/tcp  │ Configuration sync                   │
│ Session Sync    │ 707/tcp  │ Session synchronization              │
│ IPSec           │ 500/udp  │ IKE                                  │
│                 │ 4500/udp │ NAT-T                                │
│ ESP             │ Protocol │ IPSec payload                        │
│                 │ 50       │                                      │
│ SSL VPN         │ 443/tcp  │ SSL VPN portal                       │
│                 │ 10443/tcp│ SSL VPN alternate                    │
│ RADIUS          │ 1812/udp │ Authentication                       │
│                 │ 1813/udp │ Accounting                           │
│ LDAP            │ 389/tcp  │ Directory services                   │
│ LDAPS           │ 636/tcp  │ Secure LDAP                          │
│ NTP             │ 123/udp  │ Time synchronization                 │
│ DNS             │ 53/udp   │ DNS queries                          │
│ SNMP            │ 161/udp  │ SNMP polling                         │
│                 │ 162/udp  │ SNMP traps                           │
│ NetFlow         │ 2055/udp │ Flow export                          │
│ sFlow           │ 6343/udp │ sFlow export                         │
└─────────────────┴──────────┴──────────────────────────────────────┘
```

### Protocol Inspection Configuration
```bash
# Application Control Protocols
config application list
    edit "default"
        config entries
            edit 1
                set application 1234 5678    # Application IDs
                set action block
                set log enable
            next
        end
    next
end

# Protocol Options
config firewall profile-protocol-options
    edit "default"
        config http
            set options clientcomfort no-content-summary
            set post-lang jisx0201 jisx0208 jisx0212
        end
        config ftp
            set options clientcomfort no-content-summary
            set comfort-interval 10
            set comfort-amount 1
        end
    next
end
```

---

## Advanced Monitoring & Diagnostics

### System Performance Analysis
```bash
# Real-time Performance Monitoring
diagnose sys top                          # Process CPU usage
diagnose sys top-all                      # All processes
diagnose sys top-mem                      # Memory usage
diagnose sys top-summary                  # CPU summary

# Memory Analysis
diagnose hardware sysinfo memory          # Memory details
diagnose sys memory                       # Memory statistics
diagnose sys slab                         # Kernel slab info
get system performance status             # Overall performance

# CPU Analysis
diagnose sys mpstat 1 10                  # Multi-processor stats
diagnose sys cpu-info                     # CPU information
diagnose sys process stat                 # Process statistics

# Disk I/O Analysis
diagnose sys iostat                       # I/O statistics
diagnose sys disk usage                   # Disk usage
diagnose sys flash list                   # Flash partitions
```

### Advanced Session Diagnostics
```bash
# Session Table Analysis
diagnose sys session stat                 # Session statistics
diagnose sys session full-stat           # Detailed statistics
diagnose sys session exp-stat            # Expectation stats
diagnose sys session sync-stat           # Sync statistics

# Session Filtering and Display
diagnose sys session filter clear
diagnose sys session filter vd 0         # VDOM filter
diagnose sys session filter sintf port1  # Source interface
diagnose sys session filter dintf port2  # Destination interface
diagnose sys session filter proto 6      # Protocol (6=TCP, 17=UDP)
diagnose sys session filter sport 1024 65535  # Source port range
diagnose sys session filter dport 443    # Destination port
diagnose sys session list               # List filtered sessions

# Session Table Management
diagnose sys session clear              # Clear all sessions
execute session-table flush            # Flush session table
diagnose sys session del-stat         # Deletion statistics
```

### Network Diagnostics
```bash
# Advanced Ping Options
execute ping-options source 10.0.0.1
execute ping-options data-size 1400
execute ping-options df-bit yes
execute ping-options pattern 00ff
execute ping-options timeout 5
execute ping-options view-settings
execute ping 8.8.8.8

# Advanced Traceroute
execute traceroute-options source 10.0.0.1
execute traceroute-options ttl 5 30
execute traceroute-options queries 3
execute traceroute 8.8.8.8

# ARP/NDP Tables
get system arp                          # ARP table
diagnose ip arp list                    # Detailed ARP
diagnose ipv6 neighbor list            # IPv6 neighbors
diagnose netlink neighbor list         # Netlink neighbors
```

---

## Advanced Troubleshooting Matrix

### Troubleshooting Decision Tree
```
┌────────────────────────────────────────────────────────────────────────┐
│                  FORTIGATE TROUBLESHOOTING FLOWCHART                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  SYMPTOM: Traffic Not Passing                                          │
│                                                                        │
│  1. Check Interfaces                                                   │
│     └─► diagnose netlink interface list                                │
│                                                                        │
│  2. Check Routing                                                      │
│     ├─► get router info routing-table all                              │
│     └─► diagnose ip route list                                         │
│                                                                        │
│  3. Check Security Policy                                              │
│     ├─► diagnose firewall iprope lookup <src> <dst> <port>             │
│     └─► diagnose debug flow trace                                      │
│                                                                        │
│  4. Check NAT                                                          │
│     ├─► diagnose sys session filter nat                                │
│     └─► diagnose firewall ippool list                                  │
│                                                                        │
│  5. Check Sessions                                                     │
│     ├─► diagnose sys session filter <criteria>                         │
│     └─► diagnose sys session list                                      │
│                                                                        │
│  6. Check UTM                                                          │
│     ├─► diagnose debug application ips -1                              │
│     └─► diagnose wad debug enable all                                  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Complex Issue Resolution
```bash
# High CPU Troubleshooting
#!/bin/bash
echo "=== FortiGate High CPU Analysis ==="
while true; do
    date
    diagnose sys top-summary
    diagnose sys process stat | head -20
    diagnose hardware sysinfo memory
    diagnose sys session stat
    get system performance status
    sleep 5
done

# Memory Leak Detection
diagnose sys memory
diagnose sys slab | grep -E "(size|objsize)"
diagnose hardware sysinfo memory
diagnose sys process stat | sort -nrk 4 | head

# Session Table Exhaustion
diagnose sys session stat
diagnose sys session full-stat
config system global
    set tcp-halfclose-timer 30
    set tcp-halfopen-timer 30
    set tcp-timewait-timer 0
    set udp-idle-timer 60
end

# VPN Troubleshooting Matrix
# Phase 1 Issues
diagnose vpn ike config
diagnose vpn ike gateway list
diagnose vpn ike stats

# Phase 2 Issues
diagnose vpn tunnel list
diagnose vpn ipsec stats
diagnose vpn ipsec sa

# Debug VPN
diagnose debug reset
diagnose debug application ike -1
diagnose debug enable
```

### Performance Optimization Scripts
```bash
# NPU Optimization Check
#!/bin/bash
echo "=== NPU Optimization Analysis ==="
get hardware npu np6 port-list
diagnose npu np6 session-stats
diagnose npu np6 sse-stats
diagnose npu np6 synproxy-stats
config system npu
    show
end

# TCP Optimization
config system global
    set tcp-mss-sender 0
    set tcp-mss-receiver 0
    set anti-replay loose
    set tcp-option enable
    set lldp-reception enable
    set lldp-transmission enable
end

# Session Helper Optimization
config system session-helper
    show
    # Delete unnecessary helpers
    delete 1  # Delete H323
    delete 2  # Delete RAS
    delete 3  # Delete TNS
end
```

---

## Security Hardening

### System Hardening Commands
```bash
# Administrative Security
config system admin
    edit admin
        set two-factor enable
        set two-factor-authentication fortitoken
        set gui-ip-trusthost1 10.0.0.0/24
        set gui-ip-trusthost2 192.168.1.0/24
        set accprofile super_admin_readonly
    next
end

# Global Security Settings
config system global
    set admin-lockout-threshold 3
    set admin-lockout-duration 300
    set pre-login-banner enable
    set post-login-banner enable
    set admin-https-ssl-versions tlsv1-2 tlsv1-3
    set strong-crypto enable
    set ssh-cbc-cipher disable
    set ssh-hmac-md5 disable
    set ssh-kex-sha1 disable
end

# DoS Protection
config system dos-protection
    set syn-flood enable
    set syn-flood-rate-limit 10000
    set icmp-flood enable
    set icmp-flood-rate-limit 1000
    set udp-flood enable
    set udp-flood-rate-limit 10000
end

# Interface Hardening
config system interface
    edit port1
        set allowaccess ping https ssh
        set fail-detect enable
        set fail-detect-option detectserver
        set fail-alert-interfaces port2
    next
end
```

---

## Best Practices & Validation

### Pre-Production Checklist
```bash
# System Backup
execute backup config tftp config.conf 10.0.0.100
execute backup full-config tftp full-config.conf 10.0.0.100

# Current State Documentation
get system status
get system ha status
diagnose sys session stat
get system performance status
diagnose hardware sysinfo memory

# Configuration Validation
diagnose debug config-check enable
diagnose debug config-error-log read
```

### Post-Change Validation
```bash
#!/bin/bash
# Post-Change Validation Script
echo "=== FortiGate Post-Change Validation ==="
echo "1. System Status:"
get system status | grep -E "(Version|Serial|Hostname)"

echo -e "\n2. HA Status:"
get system ha status | grep -E "(Mode|State|Priority)"

echo -e "\n3. Interface Status:"
diagnose netlink interface list | grep -E "(port[0-9]|wan|lan)"

echo -e "\n4. Session Count:"
diagnose sys session stat | grep "session count"

echo -e "\n5. CPU/Memory:"
get system performance status | grep -E "(CPU|Memory)"

echo -e "\n6. Critical Services:"
diagnose test application ipsmonitor 1
diagnose test application urlfilter 1
```

---

## Emergency Recovery Procedures

### Critical Recovery Commands
```bash
# EMERGENCY USE ONLY - UNDERSTAND IMPACT
diagnose sys session clear              # Clear all sessions
execute factoryreset                    # Factory reset
execute reboot                          # System reboot
diagnose debug crashlog clear          # Clear crash logs
diagnose hardware deviceinfo disk      # Check disk health
execute disk scan <ref>                # Scan disk for errors
execute formatlogdisk                  # Format log disk

# Recovery Mode (Console)
# Press any key during boot to enter menu
# Select 'F' for Format boot device
# Select 'R' for Reset to factory defaults
# Select 'B' for Backup/Restore configuration
```

---

*Note: This enhanced edition includes comprehensive architectural analysis and advanced operational procedures. Always validate commands in a controlled environment before production deployment. Some operations will cause service disruption.*
