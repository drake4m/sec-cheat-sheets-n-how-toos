# Check Point Firewall Professional Cheat Sheet - Enhanced Edition
> **Version**: R80.40, R81, R81.10, R81.20  
> **Last Updated**: 2025  
> **Scope**: Security Gateway, Management Server, Multi-Domain Server (MDS), Advanced Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CHECK POINT ENTERPRISE ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐            │
│  │  SmartCenter │◄─────►│   Gateway    │◄─────►│   Gateway    │            │
│  │  Management  │  SIC  │   Active     │  Sync │   Standby    │            │
│  │   (R81.20)   │ 18191 │   Member     │ CCP  │   Member     │            │
│  └──────┬───────┘       └──────┬───────┘       └──────┬───────┘            │
│         │                      │                        │                    │
│    ┌────▼────┐          ┌──────▼───┐            ┌──────▼───┐               │
│    │ Smart   │          │  CoreXL  │            │  CoreXL  │               │
│    │Dashboard│          │ Workers  │            │ Workers  │               │
│    └─────────┘          └──────────┘            └──────────┘               │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Table of Contents
- [System Architecture & Packet Flow](#system-architecture--packet-flow)
- [System Administration](#system-administration)
- [Cluster Operations & High Availability](#cluster-operations--high-availability)
- [Firewall Operations & Chains](#firewall-operations--chains)
- [Advanced NAT Architecture](#advanced-nat-architecture)
- [VPN Infrastructure](#vpn-infrastructure)
- [Advanced Monitoring & Debugging](#advanced-monitoring--debugging)
- [Deep Packet Inspection](#deep-packet-inspection)
- [Log Management & Analytics](#log-management--analytics)
- [Multi-Domain Server (MDS)](#multi-domain-server-mds)
- [Performance Optimization & Tuning](#performance-optimization--tuning)
- [Protocol & Port Reference](#protocol--port-reference)
- [Security Hardening](#security-hardening)
- [Advanced Troubleshooting Procedures](#advanced-troubleshooting-procedures)

---

## System Architecture & Packet Flow

### Check Point Kernel Chain Architecture
```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         KERNEL PROCESSING CHAIN                               │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  INGRESS PACKET                                                              │
│       │                                                                       │
│       ▼                                                                       │
│  ┌─────────────┐    Chain Module: -100                                      │
│  │  SecureXL   │    Position: First                                         │
│  │Acceleration │    Function: Connection Templates                          │
│  └──────┬──────┘                                                            │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────┐    Chain Module: 0                                        │
│  │   fw VM     │    Position: i (Pre-Inbound)                             │
│  │  Pre-Match  │    Function: Anti-Spoofing                               │
│  └──────┬──────┘                                                           │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐    Chain Module: 10                                      │
│  │Policy Engine│    Position: I (Post-Inbound)                            │
│  │  (INSPECT)  │    Function: Security Policy                             │
│  └──────┬──────┘                                                          │
│         │                                                                  │
│         ▼                                                                  │
│  ┌─────────────┐    Chain Module: 20                                     │
│  │    NAT      │    Function: Translation                                │
│  │   Engine    │    Operations: Hide/Static/Automatic                    │
│  └──────┬──────┘                                                         │
│         │                                                                 │
│         ▼                                                                 │
│  ┌─────────────┐    Chain Module: 30                                    │
│  │   Routing   │    Function: Route Lookup                              │
│  │   Decision  │    FIB Consultation                                    │
│  └──────┬──────┘                                                        │
│         │                                                                │
│         ▼                                                                │
│  ┌─────────────┐    Chain Module: 40                                   │
│  │   QoS/BWM   │    Function: Traffic Shaping                          │
│  │   Engine    │    Bandwidth Management                               │
│  └──────┬──────┘                                                       │
│         │                                                               │
│         ▼                                                               │
│  ┌─────────────┐    Chain Module: 50                                  │
│  │  Post NAT   │    Position: o (Pre-Outbound)                       │
│  │  Processing │    Function: Egress Rules                            │
│  └──────┬──────┘                                                      │
│         │                                                              │
│         ▼                                                              │
│  ┌─────────────┐    Chain Module: 100                                │
│  │   SecureXL  │    Position: O (Post-Outbound)                      │
│  │   Offload   │    Function: Fast Path                              │
│  └──────┬──────┘                                                     │
│         │                                                             │
│         ▼                                                             │
│  EGRESS PACKET                                                        │
│                                                                        │
└──────────────────────────────────────────────────────────────────────┘
```

### Chain Inspection Commands
```bash
# Chain Analysis and Management
fw ctl chain                                  # Display complete chain
fw ctl chain -a <module> <priority>          # Add module to chain
fw ctl chain -d <module>                     # Delete module from chain
fw ctl chain -s <module> <priority>          # Set module priority

# Chain Debugging
fw ctl set int fwchain_debug 1               # Enable chain debug
fw ctl debug -m fw + chain                   # Debug chain processing
fw monitor -m iIoO -e "accept;"              # Monitor all chain positions

# Chain Module Registration
fw ctl get int fwmod_chain_reg_<module>      # Get module registration
fw ctl set int fwmod_chain_enabled_<module> 1 # Enable specific module
```

### CoreXL Multi-Threading Architecture
```
┌────────────────────────────────────────────────────────────────────┐
│                    CoreXL CPU DISTRIBUTION                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   CPU 0         CPU 1         CPU 2         CPU 3         CPU 4    │
│  ┌──────┐     ┌──────┐     ┌──────┐     ┌──────┐     ┌──────┐   │
│  │ SND  │     │ FWK0 │     │ FWK1 │     │ FWK2 │     │ FWK3 │   │
│  │Core  │     │Worker│     │Worker│     │Worker│     │Worker│   │
│  └───┬──┘     └───┬──┘     └───┬──┘     └───┬──┘     └───┬──┘   │
│      │            │            │            │            │        │
│      └────────────┴────────────┴────────────┴────────────┘        │
│                              │                                     │
│                    ┌─────────▼──────────┐                         │
│                    │  Connections Table  │                        │
│                    │   (Synchronized)    │                        │
│                    └────────────────────┘                         │
│                                                                     │
│  Distribution Algorithm:                                           │
│  ├─ Source IP: 5-tuple hash                                       │
│  ├─ SND Core: IRQ handling, distribution                          │
│  └─ FW Workers: Policy enforcement, NAT, VPN                      │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### CoreXL Advanced Configuration
```bash
# CoreXL Optimization
cpconfig                                      # Option 8 for CoreXL
cpmq set                                      # Configure Multi-Queue
fw ctl affinity -l -r -v                     # List detailed affinity
fw ctl affinity -s -d -fwkall 0 default      # Set affinity

# Dynamic Dispatcher Configuration
dynamic_split -s                             # Show split status
dynamic_split -o                             # Enable dynamic split
dynamic_split -O                             # Disable dynamic split

# CoreXL Performance Metrics
fw ctl multik stat                           # Real-time statistics
fw ctl multik get_mode                       # Current mode
fw ctl multik set_mode 1                     # Set to specific mode
cpstat os -f multi_cpu                       # CPU distribution stats

# Advanced CoreXL Tuning
fw ctl set int fwmultik_stats 1              # Enable statistics
fw ctl set int fwmultik_sync_freq 1000       # Sync frequency (ms)
fw ctl set int fwmultik_worker_heavy_conn_num 1000  # Heavy connections
```

---

## Advanced NAT Architecture

### NAT Processing Chains
```
┌────────────────────────────────────────────────────────────────────────┐
│                       NAT TRANSLATION FLOW                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  CLIENT INITIATED CONNECTION                                            │
│  ─────────────────────────────                                         │
│                                                                          │
│  Original:     192.168.1.10:45678 → 8.8.8.8:53                        │
│                         │                                               │
│                         ▼                                               │
│              ┌──────────────────┐                                      │
│              │ Connection Table │                                      │
│              │   Lookup/Create  │                                      │
│              └────────┬─────────┘                                      │
│                       │                                                 │
│                       ▼                                                 │
│              ┌──────────────────┐                                      │
│              │   NAT Policy     │                                      │
│              │   Evaluation     │                                      │
│              └────────┬─────────┘                                      │
│                       │                                                 │
│                       ▼                                                 │
│              ┌──────────────────┐                                      │
│              │  Translation     │                                      │
│              │  Allocation      │                                      │
│              └────────┬─────────┘                                      │
│                       │                                                 │
│  Translated:  203.0.113.1:45678 → 8.8.8.8:53                         │
│                                                                          │
│  RETURN TRAFFIC FLOW                                                   │
│  ────────────────────                                                  │
│                                                                          │
│  Return:      8.8.8.8:53 → 203.0.113.1:45678                         │
│                       │                                                 │
│                       ▼                                                 │
│              ┌──────────────────┐                                      │
│              │ Connection Table │                                      │
│              │   Match Found    │                                      │
│              └────────┬─────────┘                                      │
│                       │                                                 │
│                       ▼                                                 │
│              ┌──────────────────┐                                      │
│              │Reverse Translation│                                     │
│              │   Application    │                                      │
│              └────────┬─────────┘                                      │
│                       │                                                 │
│  Original:    8.8.8.8:53 → 192.168.1.10:45678                        │
│                                                                          │
└────────────────────────────────────────────────────────────────────────┘
```

### Advanced NAT Commands
```bash
# NAT Table Analysis
fw tab -t connections -u -f | grep NAT       # NAT connections
fw tab -t fwx_alloc -f                       # NAT allocations
fw tab -t fwx_cache -f                       # NAT cache
fw tab -t sam_blocked_ips -f                 # Blocked IPs

# NAT Pool Management
fw ctl set int fwx_nat_pool_size 50000       # Set pool size
fw ctl set int fwx_max_nat_conns_per_addr 10000  # Max per address
fw ctl set int fwx_nat_ports_per_chunk 500   # Port chunk size

# NAT Debug Deep Dive
fw ctl debug -buf 8192
fw ctl debug -m fw + xlate xltrc nat conn drop
fw ctl debug -m nat + all
fw ctl kdebug -T -f > /tmp/nat_debug.txt &
tcpdump -nni any -w /tmp/nat.pcap &
# Reproduce issue
fw ctl debug 0

# Complex NAT Scenarios
# 1. Double NAT (user.def method)
echo "<src>,<hide>,<static>" >> $FWDIR/conf/user.def
# Example: 10.0.0.0/8,192.168.1.1,203.0.113.100

# 2. Port-based NAT exclusion
fw ctl set int fwx_nat_exclude_ports "22,443,3389"

# 3. NAT pool exhaustion monitoring
watch -n 1 'fw tab -t fwx_alloc -s | grep limit'
```

### NAT Troubleshooting Matrix
```bash
# Symptom: NAT not working
fw monitor -e "accept host(x.x.x.x);" -o nat.pcap
fw ctl zdebug + xlate drop
fw log -n -ft | grep "NAT"

# Symptom: Port exhaustion
fw tab -t fwx_alloc -s
fw ctl pstat | grep nat
netstat -an | grep TIME_WAIT | wc -l

# Symptom: Asymmetric NAT
fw ctl set int fw_allow_simultaneous_ping 1
fw ctl set int fwconn_sent_syn_before_syn_ack 0
```

---

## Protocol & Port Reference

### Check Point Service Ports
```
┌──────────────────────────────────────────────────────────────────────┐
│                     CHECK POINT PORT MATRIX                           │
├─────────────────┬──────────┬────────────────────────────────────────┤
│ Service         │ Port     │ Description                            │
├─────────────────┼──────────┼────────────────────────────────────────┤
│ FW1            │ 256/tcp  │ Firewall management                   │
│ FW1_key        │ 257/tcp  │ Key exchange                          │
│ FW1_ica_pull   │ 18190/tcp│ Certificate Authority                 │
│ CPMI           │ 18190/tcp│ Management Interface                  │
│ CPD            │ 18191/tcp│ SIC (Secure Internal Comm)           │
│ CPD_amon       │ 18192/tcp│ CPD Application Monitoring           │
│ CPD_admin      │ 18193/tcp│ CPD Administrator                    │
│ FW1_sam        │ 18183/tcp│ SAM (Suspicious Activity Monitor)    │
│ FW1_ela        │ 18187/tcp│ Event Logging API                    │
│ FW1_ica_services│18264/tcp│ ICA services                         │
│ FW1_ica_push   │ 18265/tcp│ Certificate push                     │
│ CP_rtm         │ 18266/tcp│ Real Time Monitor                    │
│ FW1_netso      │ 19191/tcp│ Cluster sync (CCP)                   │
│ Identity_Agent │ 443/tcp  │ Identity Awareness Agent             │
│ SmartDashboard │ 18190/tcp│ Management client connection         │
│ SmartView      │ 18190/tcp│ SmartView connection                 │
│ VPN            │ 500/udp  │ IKE (Phase 1)                        │
│ VPN-NAT-T      │ 4500/udp │ NAT Traversal                        │
│ ESP            │ Protocol 50│ Encapsulated Security Payload      │
│ AH             │ Protocol 51│ Authentication Header              │
│ ClusterXL CCP  │ 8116/tcp │ State Synchronization                │
│ ClusterXL Probe│ Protocol 103│ Cluster Control Protocol          │
└─────────────────┴──────────┴────────────────────────────────────────┘
```

### Protocol Handler Configuration
```bash
# Protocol Inspection Settings
fw ctl set int fw_allow_tcp_out_of_state 1  # Allow out-of-state TCP
fw ctl set int fw_tcp_mss_value 1460         # Set TCP MSS
fw ctl set int fw_icmp_redirects_accept 0    # Disable ICMP redirects
fw ctl set int fw_allow_udp_reply 1          # Allow UDP replies

# Protocol Anomaly Detection
fw ctl set int fw_tcp_detect_scan 1          # TCP scan detection
fw ctl set int fw_udp_detect_scan 1          # UDP scan detection
fw ctl set int fw_icmp_flood_threshold 1000  # ICMP flood threshold
```

---

## Advanced Monitoring & Debugging

### Deep Packet Analysis
```bash
# Advanced FW Monitor Expressions
fw monitor -e "accept 
    [9:1]=6 and 
    ((src=10.0.0.0/8 and dst=192.168.0.0/16) or 
     (src=192.168.0.0/16 and dst=10.0.0.0/8)) and 
    (th_sport>1024 or th_dport>1024);"

# Protocol-specific monitoring
fw monitor -e "accept ip_p=1;"               # ICMP only
fw monitor -e "accept ip_p=6 and th_flags=2;" # TCP SYN only
fw monitor -e "accept ip_p=17 and udp_dport=53;" # DNS queries

# Advanced capture with filters
fw monitor -ci 10 -co 11 -vs 0 -vt 3 -vcx 4 \
    -e "accept ([20:2,b]=80 or [22:2,b]=80);" \
    -o /tmp/http.cap

# Inline packet modification (DANGEROUS)
fw monitor -e "if ([20:2,b]=80) {[12:4,b]=0x0a0a0a0a; accept;}"
```

### Kernel Debug Matrix
```bash
# Debug Categories and Levels
┌──────────────┬─────────────────────────────────┐
│ Module       │ Debug Flags                     │
├──────────────┼─────────────────────────────────┤
│ fw           │ drop, conn, xlate, nat, route  │
│ vpn          │ driver, packet, sas, ike       │
│ cluster      │ sync, state, ccp, probe        │
│ pnote        │ all, trap, monitor             │
│ sam          │ quota, block, alert            │
│ dlp          │ scan, match, policy            │
│ appi         │ classify, cache, update        │
└──────────────┴─────────────────────────────────┘

# Complex Debug Session
fw ctl debug 0                               # Reset all flags
fw ctl debug -buf 32768                      # Set buffer size
fw ctl debug -m fw + drop conn xlate nat     # Multiple modules
fw ctl debug -m cluster + all                # Cluster debug
fw ctl kdebug -T -f -o /tmp/debug.txt &      # Output to file
# Reproduce issue
kill %1                                      # Stop debug
fw ctl debug 0                               # Clear flags
```

### Performance Profiling
```bash
# CPU Profiling
cpstat os -f perf_stats                      # Performance statistics
sar -P ALL 1 10                              # Per-CPU stats
mpstat -P ALL 1                              # Processor statistics

# Memory Analysis
free -m
slabtop -o                                   # Kernel slab cache
vmstat 1 10                                  # Virtual memory stats
cat /proc/meminfo | grep -E "(Active|Inactive|Cached)"

# I/O Analysis
iostat -x 1 10                               # Extended I/O stats
iotop -b -n 5                                # I/O by process
dstat -cdnm                                  # Combined stats
```

---

## Security Hardening

### Kernel Security Parameters
```bash
# Anti-Spoofing Configuration
fw ctl set int fw_antispoofing_enabled 1
fw ctl set int fw_local_interface_anti_spoofing 1
fw ctl set int fw_allow_out_of_state_icmp 0

# DDoS Protection
fw ctl set int fw_syn_attack_threshold 10000
fw ctl set int fw_conn_rate_limit 1000
fw ctl set int fw_icmp_rate_limit 100
fw ctl set int fw_rst_attack_threshold 500

# Connection Limits
fw ctl set int fwx_max_conns 500000
fw ctl set int fwconn_max_in_dup_queue 100
fw ctl set int fwconn_max_in_syn_queue 50000

# Fragment Protection
fw ctl set int fw_ipfrag_timeout 15
fw ctl set int fw_ipfrag_maxbytes 256000
fw ctl set int fw_ipfrag_maxpackets 128
```

### IPS/IDS Tuning
```bash
# IPS Engine Configuration
ips_update_attack_db                        # Update IPS database
ips stat                                    # IPS statistics
ips bypass on                               # Enable bypass mode
ips debug -m                               # IPS debug menu

# Threat Prevention
tpm show status                             # Threat prevention status
tecli show threats all                      # Show all threats
tecli show ips stats                        # IPS statistics
```

---

## Advanced Troubleshooting Procedures

### Connection State Analysis
```bash
# Connection Debugging Workflow
1. Identify problematic connection:
   fw tab -t connections -u -f | grep <IP>

2. Enable targeted debug:
   fw ctl debug -buf 8192
   fw ctl debug -m fw + conn drop
   fw ctl debug -m fw + xlate
   
3. Monitor specific traffic:
   fw monitor -e "accept host(<IP>);" -o debug.cap
   
4. Analyze kernel tables:
   fw tab -t connections -t xlate -t fwx_alloc -f
   
5. Check policy evaluation:
   fw log -n -ft | tail -f | grep <IP>
```

### Memory Leak Detection
```bash
# Memory Analysis Procedure
while true; do
    date
    free -m
    fw tab -s | head -20
    fw ctl pstat | grep -E "(memory|allocations)"
    sleep 60
done > /tmp/memory_monitor.log &

# Analyze growth patterns
grep "connections" /tmp/memory_monitor.log | awk '{print $4}'
```

### Cluster Split-Brain Resolution
```bash
# Split-Brain Detection and Resolution
1. Identify split-brain:
   cphaprob stat
   cphaprob -a if
   
2. Check sync status:
   cphaprob syncstat
   fw ctl pstat | grep sync
   
3. Force member to standby:
   clusterXL_admin down
   
4. Clear problematic states:
   fw tab -t connections -x
   
5. Restore cluster:
   clusterXL_admin up
   cphaprob stat
```

### VPN Troubleshooting Matrix
```bash
# Phase 1 (IKE) Issues
vpn debug on TDERROR_ALL_ALL=5
vpn debug ikeon
tail -f $FWDIR/log/ike.elg

# Phase 2 (IPSec) Issues
fw tab -t IKE_SA_table -f
fw tab -t IPSEC_SA_table -f
vpn tu tlist

# NAT-T Issues
fw ctl set int vpn_nat_traversal 1
fw ctl set int vpn_ipsec_dont_fragment 1
fw ctl set int vpn_mtu_discovery 1
```

### Performance Crisis Response
```bash
# Emergency Performance Recovery
1. Identify bottleneck:
   top -H
   fw ctl multik stat
   cpstat fw -f all
   
2. Temporary mitigation:
   fwaccel off                              # Disable acceleration
   dynamic_split -O                         # Disable dynamic split
   fw ctl set int fwconn_tcp_state_logging 0
   
3. Clear states:
   fw tab -t connections -x -y
   fw tab -t xlate -x -y
   
4. Gradual recovery:
   fwaccel on
   dynamic_split -o
```

---

## Best Practices & Optimization

### Pre-Production Checklist
```bash
# System Validation
cpinfo -y all -o /tmp/cpinfo_pre.txt
fw stat -l
cphaprob stat
cplic print
fw ver -k

# Configuration Backup
cd $FWDIR/conf
tar czf /tmp/conf_backup_$(date +%Y%m%d).tgz *
migrate export /tmp/migrate_$(date +%Y%m%d).tgz

# Performance Baseline
fw ctl pstat > /tmp/baseline_pstat.txt
netstat -s > /tmp/baseline_netstat.txt
fw tab -s > /tmp/baseline_tables.txt
```

### Post-Change Validation
```bash
# Verification Script
#!/bin/bash
echo "=== Post-Change Validation ==="
echo "Policy Status:"
fw stat -l
echo -e "\nCluster Status:"
cphaprob stat
echo -e "\nServices Status:"
cpwd_admin list
echo -e "\nConnection Count:"
fw tab -t connections -s
echo -e "\nCoreXL Status:"
fw ctl multik stat
echo -e "\nNAT Allocations:"
fw tab -t fwx_alloc -s
```

---

## Emergency Recovery Procedures

### Critical Commands Reference
```bash
# EMERGENCY USE ONLY - UNDERSTAND IMPACT BEFORE USE
fw unloadlocal                              # Remove all security
fw tab -t connections -x -y                 # Clear ALL connections
fw tab -t xlate -x -y                       # Clear ALL NAT
cpstop; cpstart                             # Full service restart
fw ctl zdebug drop                          # Real-time drop analysis
```

---

*Note: This enhanced edition includes advanced architectural concepts and procedures. Always test commands in a lab environment before production deployment. Some operations may cause service disruption.*