# F5 BIG-IP LTM Professional Cheat Sheet
> **Version**: TMOS 15.x, 16.x, 17.x  
> **Last Updated**: 2025  
> **Scope**: BIG-IP Local Traffic Manager (LTM), Application Services

---

## Table of Contents
- [System Administration](#system-administration)
- [Traffic Management Shell (TMSH)](#traffic-management-shell-tmsh)
- [Load Balancing Configuration](#load-balancing-configuration)
- [SSL/TLS Management](#ssltls-management)
- [High Availability](#high-availability)
- [Network Configuration](#network-configuration)
- [Monitoring & Statistics](#monitoring--statistics)
- [Packet Capture & Debugging](#packet-capture--debugging)
- [iRules Management](#irules-management)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting Procedures](#troubleshooting-procedures)

---

## System Administration

### System Information & Status
```bash
# System Information
tmsh show sys version              # Complete version information
tmsh show sys hardware             # Hardware specifications
tmsh show sys license              # License details
tmsh show sys global-settings      # Global system settings
tmsh show sys cpu                  # CPU statistics
tmsh show sys memory               # Memory utilization
tmsh show sys disk                 # Disk usage

# System Status
tmsh show sys failover             # Failover status
tmsh show sys ha-status            # HA status overview
tmsh show sys traffic-group        # Traffic group status
tmsh show sys db                   # System database variables
```

### Configuration Management
```bash
# Configuration Save/Load
tmsh save sys config               # Save running configuration
tmsh save sys config file <name>   # Save to specific file
tmsh load sys config               # Load configuration
tmsh load sys config merge         # Merge configuration
tmsh load sys config verify        # Verify configuration

# UCS Archive Management
tmsh save sys ucs <filename>       # Create full backup (UCS)
tmsh load sys ucs <filename>       # Restore from UCS
tmsh delete sys ucs <filename>     # Delete UCS file
tmsh list sys ucs                  # List UCS files

# Configuration Sync
tmsh run cm config-sync to-group <device-group>
tmsh run cm config-sync from-group <device-group>
tmsh show cm sync-status           # Sync status
```

### User & Access Management
```bash
# User Administration
tmsh create auth user <username> password <password>
tmsh modify auth user <username> password <password>
tmsh list auth user <username>
tmsh delete auth user <username>

# SSH Key Management
tmsh modify auth user <username> shell bash
tmsh modify auth user <username> partition-access add { all-partitions { role admin } }

# Password Policy
tmsh modify auth password-policy policy-enforcement enabled
tmsh modify auth password-policy minimum-length 12
```

### Service Management
```bash
# Core Services
tmsh restart sys service mcpd      # Restart MCP daemon
tmsh restart sys service tmm       # Restart TMM (traffic processing)
tmsh restart sys service httpd     # Restart web GUI
bigstart status                    # Show all service status
bigstart restart <service>         # Restart specific service
bigstart stop <service>            # Stop service
bigstart start <service>           # Start service

# Process Management
ps aux | grep tmm                  # TMM process status
kill -9 <pid>                      # Force kill process
top                                # Real-time process monitor
```

---

## Traffic Management Shell (TMSH)

### TMSH Navigation
```bash
# TMSH Basics
tmsh                               # Enter TMSH
quit                              # Exit TMSH
help                              # Show help
list                              # List configuration
show                              # Show runtime information
create                            # Create object
modify                            # Modify object
delete                            # Delete object

# Navigation
cd /ltm                           # Change context to LTM
cd /sys                           # Change context to System
cd /net                           # Change context to Network
pwd                               # Show current context

# Batch Operations
tmsh -c "command1; command2"      # Execute multiple commands
tmsh < script.txt                 # Execute from script
```

### Object Management
```bash
# List Objects
tmsh list ltm pool                # List all pools
tmsh list ltm virtual             # List all virtual servers
tmsh list ltm node                # List all nodes
tmsh list ltm monitor            # List all monitors

# Show Runtime Status
tmsh show ltm pool members        # Pool member status
tmsh show ltm virtual            # Virtual server statistics
tmsh show ltm node               # Node statistics
tmsh show ltm persistence persist-records  # Persistence records
```

---

## Load Balancing Configuration

### Virtual Servers
```bash
# Virtual Server Management
tmsh create ltm virtual VS_HTTPS destination 10.0.0.100:443 ip-protocol tcp pool POOL_WEB profiles add { tcp http clientssl }
tmsh modify ltm virtual VS_HTTPS enabled
tmsh modify ltm virtual VS_HTTPS disabled
tmsh delete ltm virtual VS_HTTPS

# Virtual Server Statistics
tmsh show ltm virtual VS_HTTPS
tmsh show ltm virtual VS_HTTPS detail
tmsh reset-stats ltm virtual VS_HTTPS
```

### Pools & Pool Members
```bash
# Pool Creation
tmsh create ltm pool POOL_WEB members add { 10.1.1.10:80 10.1.1.11:80 } monitor http

# Pool Management
tmsh modify ltm pool POOL_WEB members add { 10.1.1.12:80 }
tmsh modify ltm pool POOL_WEB members delete { 10.1.1.10:80 }
tmsh modify ltm pool POOL_WEB load-balancing-mode least-connections

# Member Management
tmsh modify ltm pool POOL_WEB members modify { 10.1.1.10:80 { session user-disabled } }
tmsh modify ltm pool POOL_WEB members modify { 10.1.1.10:80 { session user-enabled } }
tmsh modify ltm pool POOL_WEB members modify { 10.1.1.10:80 { ratio 3 } }

# Pool Statistics
tmsh show ltm pool POOL_WEB detail
tmsh show ltm pool POOL_WEB members
```

### Health Monitors
```bash
# Monitor Creation
tmsh create ltm monitor http HTTP_MON interval 5 timeout 16 send "GET /health HTTP/1.1\r\nHost: example.com\r\n\r\n" recv "200 OK"
tmsh create ltm monitor https HTTPS_MON interval 5 timeout 16
tmsh create ltm monitor tcp TCP_MON interval 5 timeout 16

# Monitor Assignment
tmsh modify ltm pool POOL_WEB monitor HTTP_MON
tmsh modify ltm pool POOL_WEB monitor "HTTP_MON and HTTPS_MON"

# Monitor Testing
tmsh run ltm monitor http HTTP_MON destination 10.1.1.10:80
```

### Persistence Profiles
```bash
# Persistence Configuration
tmsh create ltm persistence cookie PERSIST_COOKIE
tmsh create ltm persistence source-addr PERSIST_SRC timeout 1800
tmsh create ltm persistence ssl PERSIST_SSL

# Apply Persistence
tmsh modify ltm virtual VS_WEB persist add { PERSIST_COOKIE }

# Clear Persistence Records
tmsh delete ltm persistence persist-records
tmsh delete ltm persistence persist-records node-addr 10.1.1.10
```

---

## SSL/TLS Management

### SSL Certificates
```bash
# Certificate Management
tmsh list sys crypto cert
tmsh list sys crypto key
tmsh install sys crypto cert <name> from-local-file /var/tmp/cert.crt
tmsh install sys crypto key <name> from-local-file /var/tmp/key.key

# Create Self-Signed Certificate
tmsh create sys crypto key <name> gen-certificate common-name <CN> country US

# Certificate Chain
tmsh install sys crypto cert-bundle <name> from-local-file /var/tmp/chain.crt
```

### SSL Profiles
```bash
# Client SSL Profile
tmsh create ltm profile client-ssl CLIENTSSL_PROFILE cert <cert> key <key>
tmsh modify ltm profile client-ssl CLIENTSSL_PROFILE ciphers "ECDHE+RSA:!RC4:!DES"
tmsh modify ltm profile client-ssl CLIENTSSL_PROFILE options { no-sslv3 no-tlsv1 }

# Server SSL Profile
tmsh create ltm profile server-ssl SERVERSSL_PROFILE
tmsh modify ltm profile server-ssl SERVERSSL_PROFILE secure-renegotiation require
```

---

## High Availability

### Device Service Clustering
```bash
# Device Management
tmsh show cm device                # Show device information
tmsh show cm device-group          # Show device groups
tmsh show cm traffic-group         # Show traffic groups
tmsh show cm sync-status           # Synchronization status

# Failover
tmsh run sys failover standby      # Force to standby
tmsh run sys failover active       # Force to active
tmsh show sys failover             # Failover status

# Config Sync
tmsh run cm config-sync to-group <device-group>
tmsh run cm config-sync from-group <device-group>
tmsh modify cm device-group <group> devices add { <device> }
```

### Traffic Groups
```bash
# Traffic Group Management
tmsh create cm traffic-group TG_CUSTOM
tmsh modify cm traffic-group TG_CUSTOM ha-order { device1 device2 }
tmsh run cm traffic-group TG_CUSTOM failover

# Floating IP Assignment
tmsh modify ltm virtual VS_WEB traffic-group TG_CUSTOM
```

---

## Network Configuration

### Interface Configuration
```bash
# Physical Interfaces
tmsh list net interface
tmsh show net interface
tmsh modify net interface 1.1 enabled
tmsh modify net interface 1.1 disabled

# VLAN Configuration
tmsh create net vlan VLAN_100 interfaces add { 1.1 { tagged } } tag 100
tmsh modify net vlan VLAN_100 mtu 9000
tmsh delete net vlan VLAN_100

# Self-IP Configuration
tmsh create net self SELF_IP address 10.0.0.1/24 vlan VLAN_100
tmsh modify net self SELF_IP allow-service add { tcp:443 tcp:22 }
```

### Routing
```bash
# Static Routes
tmsh create net route DEFAULT network default gw 10.0.0.254
tmsh create net route ROUTE_10 network 10.0.0.0/8 gw 10.0.0.1
tmsh list net route
tmsh show net route

# Dynamic Routing
tmsh modify net route-domain 0 routing-protocol add { BGP }
tmsh create net routing bgp <config>
```

### Route Domains
```bash
# Route Domain Management
tmsh create net route-domain 1 id 1 vlans add { VLAN_100 }
tmsh modify net route-domain 1 strict enabled
tmsh list net route-domain

# Route Domain Assignment
tmsh modify ltm virtual VS_WEB destination 10.0.0.100%1:80
```

---

## Monitoring & Statistics

### Connection Management
```bash
# Connection Table
tmsh show sys connection            # All connections
tmsh show sys connection cs-server-addr 10.0.0.100 cs-server-port 443
tmsh show sys connection ss-client-addr 192.168.1.100
tmsh delete sys connection cs-server-addr 10.0.0.100
tmsh delete sys connection all      # Clear all connections

# Connection Limits
tmsh show sys connection-limit
tmsh modify sys db connection.table.size value 1000000
```

### Performance Statistics
```bash
# System Performance
tmsh show sys performance system    # System performance
tmsh show sys performance throughput # Throughput statistics
tmsh show sys performance connections # Connection statistics

# Module Statistics
tmsh show ltm virtual VS_WEB profiles statistics
tmsh show ltm pool POOL_WEB statistics
tmsh reset-stats ltm virtual       # Reset all virtual server stats
tmsh reset-stats ltm pool         # Reset all pool stats
```

### Logging & Alerts
```bash
# Log Files
tail -f /var/log/ltm                # LTM log
tail -f /var/log/tmm                # TMM log
tail -f /var/log/mcpd               # MCPD log
tail -f /var/log/audit              # Audit log

# SNMP Traps
tmsh list sys snmp
tmsh create sys snmp traps add { 10.0.0.100:162 }
```

---

## Packet Capture & Debugging

### TCPDump
```bash
# Basic Capture
tcpdump -nni 0.0 host 10.0.0.100
tcpdump -nni 0.0 host 10.0.0.100 and port 443
tcpdump -nni 0.0 src 192.168.1.0/24 and dst port 80

# Advanced Capture
tcpdump -nni 0.0:nnn -s0 -w /var/tmp/capture.pcap  # Capture all VLANs
tcpdump -nni internal -s0 -w /var/tmp/internal.pcap # Internal VLAN
tcpdump -nni 1.1 -s0 -w /var/tmp/interface.pcap    # Specific interface

# F5 Specific Options
tcpdump -nni 0.0:p -s0              # Capture only clientside
tcpdump -nni 0.0:n -s0              # Capture only serverside
tcpdump -nni 0.0:nnn -s0            # Capture with noise (all traffic)

# Filters with F5 Noise Reduction
tcpdump -nni any -s0 'not port 4353 and not port 22'  # Exclude F5 internal
```

### Debug Logging
```bash
# TMM Debug
tmsh modify sys db log.tcpconn.level value Debug
tmsh modify sys db log.ssl.level value Debug
tmsh modify sys db tmm.tcpdump.enable value true

# Module Debug
tmsh modify sys db log.ltm.level value Debug
tmsh modify sys db log.gtm.level value Debug
```

### SSL Debugging
```bash
# SSL Handshake Capture
ssldump -AdNn -i 0.0 port 443       # Decrypt SSL if keys available
tcpdump -nni 0.0 -s0 -w /var/tmp/ssl.pcap port 443 and '(tcp[13] & 2!=0)'

# SSL Session Information
tmsh show ltm profile client-ssl CLIENTSSL_PROFILE session-status
```

---

## iRules Management

### iRule Operations
```bash
# iRule Management
tmsh list ltm rule                  # List all iRules
tmsh create ltm rule RULE_NAME { <iRule code> }
tmsh modify ltm rule RULE_NAME { <iRule code> }
tmsh delete ltm rule RULE_NAME

# Apply iRule to Virtual Server
tmsh modify ltm virtual VS_WEB rules { RULE_NAME }
tmsh modify ltm virtual VS_WEB rules none  # Remove all iRules

# iRule Statistics
tmsh show ltm rule RULE_NAME stats
tmsh reset-stats ltm rule RULE_NAME
```

### iRule Examples
```tcl
# Basic Redirect iRule
when HTTP_REQUEST {
    if { [HTTP::host] equals "old.example.com" } {
        HTTP::redirect "https://new.example.com[HTTP::uri]"
    }
}

# Logging iRule
when HTTP_REQUEST {
    log local0. "Client: [IP::client_addr] requested [HTTP::host][HTTP::uri]"
}

# Header Manipulation
when HTTP_REQUEST {
    HTTP::header insert "X-Forwarded-For" [IP::client_addr]
    HTTP::header remove "Server"
}
```

---

## Performance Optimization

### TMM Optimization
```bash
# CPU Affinity
tmsh modify sys db provision.cpu.affinityset value <cpu_set>
tmsh modify sys db tmm.maxclientcontextsize value 40960

# Connection Optimization
tmsh modify sys db tm.tcpmaxsegs value 0  # Disable TCP segmentation offload
tmsh modify sys db tm.tcpnagle value disabled
tmsh modify sys db connection.vlankeyed value false

# Memory Tuning
tmsh modify sys db provision.extramb value 2048
tmsh modify sys db adaptive.reaper.high value 95
tmsh modify sys db adaptive.reaper.low value 85
```

### CMP (Clustered Multiprocessing)
```bash
# CMP Configuration
tmsh modify sys db cmp.enabled value true
tmsh show sys tmm-info             # TMM distribution info
tmsh show sys cpu                  # CPU core usage

# CMP Hashing
tmsh modify ltm profile fastl4 FASTL4_PROFILE cmp-hash src-ip,dst-ip,src-port,dst-port
```

### OneConnect Optimization
```bash
# OneConnect Profile
tmsh create ltm profile one-connect ONECONNECT_PROFILE source-mask 255.255.255.255
tmsh modify ltm virtual VS_WEB profiles add { ONECONNECT_PROFILE }
```

---

## Troubleshooting Procedures

### Common Issues

#### High CPU Usage
```bash
# Identify CPU Usage
top                                # Process CPU usage
tmsh show sys cpu                 # Per-core CPU usage
tmsh show sys tmm-info            # TMM CPU distribution

# Mitigation
tmsh modify sys db tmm.connections.sweeper.enable value false
tmsh modify ltm profile tcp TCP_PROFILE idle-timeout 300
```

#### Memory Issues
```bash
# Memory Analysis
tmsh show sys memory              # Memory statistics
free -m                          # System memory
tmsh show sys db | grep memory  # Memory-related DB variables

# Clear Memory
tmsh restart sys service tmm    # Restart TMM (causes brief outage)
sync; echo 3 > /proc/sys/vm/drop_caches  # Clear caches
```

#### Connection Issues
```bash
# Connection Troubleshooting
tmsh show sys connection cs-server-addr <VIP>
tmsh show ltm pool POOL_NAME members
tmsh show ltm persistence persist-records

# Force Pool Member Up
tmsh modify ltm pool POOL_NAME members modify { 10.1.1.10:80 { state user-up } }

# Clear Connections
tmsh delete sys connection cs-server-addr <VIP>
tmsh delete ltm persistence persist-records
```

### Debug Procedures

#### HTTP Traffic Debug
```bash
# Enable HTTP Logging
tmsh modify ltm profile http HTTP_PROFILE request-log enabled
tcpdump -nni 0.0 -s0 -A host <client-ip> and port 80

# HTTP Headers
tcpdump -nni 0.0 -s0 -A -l | grep -E "(GET|POST|Host:|User-Agent:)"
```

#### SSL/TLS Debug
```bash
# SSL Handshake Issues
tcpdump -nni 0.0 port 443 -s0 -w /var/tmp/ssl.pcap
tmsh modify sys db log.ssl.level value Debug
tail -f /var/log/ltm | grep SSL
```

### Emergency Commands
```bash
# EMERGENCY USE ONLY
bigstart restart                  # Restart all services
tmsh delete sys connection all    # Clear all connections
tmsh load sys config default      # Load default config
tmsh restart sys service mcpd     # Restart control plane
tmsh restart sys service tmm      # Restart data plane
b config sync                     # Force config sync (v11 command)
```

---

## Best Practices

### Pre-Change Checklist
1. Create UCS backup: `tmsh save sys ucs backup.ucs`
2. Verify HA status: `tmsh show sys failover`
3. Check sync status: `tmsh show cm sync-status`
4. Document config: `tmsh list ltm virtual`

### Post-Change Validation
1. Verify configuration: `tmsh list ltm virtual <name>`
2. Check statistics: `tmsh show ltm virtual <name>`
3. Test connectivity: `curl -I https://vip-address`
4. Sync configuration: `tmsh run cm config-sync to-group <device-group>`

### Maintenance Procedures
1. Schedule maintenance window
2. Force standby before changes
3. Test on standby unit first
4. Monitor logs during changes
5. Have rollback plan ready

---

## Reference

### Important File Locations
```
/config/                   # Configuration files
/var/log/                  # Log files
/var/tmp/                  # Temporary files (captures)
/shared/                   # Shared partition files
/var/local/ucs/           # UCS backup files
/config/ssl/              # SSL certificates and keys
```

### Default Management Ports
- **443/tcp**: Configuration GUI (HTTPS)
- **22/tcp**: SSH
- **161/udp**: SNMP
- **4353/tcp**: iQuery (device communication)
- **1026/udp**: Network failover
- **6699/tcp**: Centralized Management

### Common TMOS Modules
- **ltm**: Local Traffic Manager
- **gtm**: Global Traffic Manager (DNS)
- **asm**: Application Security Manager
- **apm**: Access Policy Manager
- **afm**: Advanced Firewall Manager

---

*Note: Always verify commands against your specific TMOS version documentation. Test all changes in a non-production environment. Some commands may cause service interruption.*