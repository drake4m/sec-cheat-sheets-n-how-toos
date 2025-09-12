# Fortinet FortiGate Professional Cheat Sheet
> **Version**: FortiOS 7.0, 7.2, 7.4  
> **Last Updated**: 2025  
> **Scope**: FortiGate Firewall, FortiManager, FortiAnalyzer

---

## Table of Contents
- [System Administration](#system-administration)
- [High Availability (HA)](#high-availability-ha)
- [Networking Configuration](#networking-configuration)
- [Security Policies](#security-policies)
- [VPN Configuration](#vpn-configuration)
- [Monitoring & Diagnostics](#monitoring--diagnostics)
- [Packet Capture & Debug](#packet-capture--debug)
- [FortiManager Operations](#fortimanager-operations)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting Procedures](#troubleshooting-procedures)

---

## System Administration

### System Status & Information
```bash
# System Information
get system status                   # Complete system status
get system performance status       # Real-time performance metrics
diagnose sys top                   # Process CPU usage (real-time)
diagnose sys top-summary           # CPU usage summary
diagnose hardware deviceinfo disk  # Disk information
get hardware status                # Hardware component status

# Version & License
get system fortiguard-service status  # FortiGuard status
diagnose autoupdate versions       # Firmware/signature versions
diagnose debug rating              # FortiGuard rating status
execute update-now                 # Force FortiGuard update
```

### Configuration Management
```bash
# Configuration Backup/Restore
execute backup config tftp <file> <tftp-server>
execute restore config tftp <file> <tftp-server>
execute backup full-config tftp <file> <tftp-server>

# Configuration Operations
show full-configuration            # Display complete configuration
show | grep <pattern>             # Search configuration
config global                      # Enter global configuration (VDOM)
end                               # Exit configuration mode
abort                             # Cancel configuration changes
```

### Administrative Access
```bash
# Admin Management
config system admin
    edit <admin-name>
    set password <password>
    set accprofile "super_admin"
    set vdom "root"
end

# Session Management
diagnose sys session list          # List admin sessions
diagnose sys session clear         # Clear all sessions
execute shutdown                   # Shutdown firewall
execute reboot                     # Reboot firewall
execute factoryreset              # Factory reset (CAUTION!)
```

### System Maintenance
```bash
# Disk Management
execute disk scan <ref_int>       # Scan disk for errors
diagnose sys flash list           # List flash partitions
execute formatlogdisk             # Format log disk

# Process Management
diagnose sys kill <pid>           # Kill specific process
diagnose sys process list         # List all processes
fnsysctl kill <pid>              # Force kill process
```

---

## High Availability (HA)

### HA Configuration
```bash
# Basic HA Setup
config system ha
    set mode a-p                  # Active-Passive mode
    set group-name "HA-Cluster"
    set password <password>
    set priority 200              # Higher = preferred master
    set override enable
    set hbdev "port3" 50 "port4" 50
    set session-sync enable
    set session-pickup enable
end

# HA Status Monitoring
get system ha status              # Detailed HA status
diagnose sys ha status            # HA diagnostic status
diagnose sys ha checksum cluster # Compare checksums
diagnose sys ha reset-uptime     # Reset HA uptime counters
```

### HA Synchronization
```bash
# Force Synchronization
execute ha synchronize start      # Start manual sync
diagnose sys ha sync-start       # Force configuration sync
diagnose sys ha checksum recalculate  # Recalculate checksums

# HA Management
execute ha manage <unit-id>      # Switch to specific unit
execute ha failover enable       # Enable failover
execute ha failover disable      # Disable failover
diagnose sys ha set-as-master enable  # Force unit as master
```

### HA Troubleshooting
```bash
# Debug HA Issues
diagnose debug reset
diagnose debug enable
diagnose debug application hasync -1
diagnose debug application hatalk -1

# Check HA Differences
diagnose sys ha dump-by all-vcluster
diagnose sys ha showcsum          # Show configuration checksums
execute ha ignore-hardware-revision enable  # Ignore HW revision
```

---

## Networking Configuration

### Interface Management
```bash
# Interface Configuration
config system interface
    edit <interface-name>
    set ip <IP> <mask>
    set allowaccess ping https ssh
    set role lan/wan/dmz
    set status up/down
end

# Interface Status
get system interface physical     # Physical interface status
diagnose netlink interface list   # Detailed interface info
diagnose ip address list          # IP address assignments
```

### Routing Configuration
```bash
# Static Routes
config router static
    edit <route-id>
    set dst <network> <mask>
    set gateway <gateway-ip>
    set device <interface>
    set priority <priority>
end

# Routing Table
get router info routing-table all  # Complete routing table
get router info routing-table database  # Routing database
diagnose ip route list             # Kernel routing table
get router info kernel             # Kernel routing info
```

### VLAN Configuration
```bash
# VLAN Interface
config system interface
    edit "VLAN100"
    set vdom "root"
    set interface "port1"
    set vlanid 100
    set ip <IP> <mask>
end
```

---

## Security Policies

### Firewall Policies
```bash
# Policy Configuration
config firewall policy
    edit <policy-id>
    set name "Policy-Name"
    set srcintf "port1"
    set dstintf "port2"
    set srcaddr "all"
    set dstaddr "all"
    set action accept
    set schedule "always"
    set service "ALL"
    set nat enable
    set logtraffic all
end

# Policy Verification
diagnose firewall iprope show      # Show policy routes
diagnose sys session filter clear  # Clear session filters
diagnose sys session list          # List active sessions
```

### NAT Configuration
```bash
# Source NAT (Overload)
config firewall policy
    edit <id>
    set nat enable
    set ippool enable
    set poolname <pool-name>
end

# Virtual IP (DNAT)
config firewall vip
    edit "VIP-WebServer"
    set extip <external-ip>
    set mappedip <internal-ip>
    set extintf "wan1"
    set portforward enable
    set extport 443
    set mappedport 443
end
```

---

## VPN Configuration

### IPSec VPN
```bash
# VPN Status
diagnose vpn ike status           # IKE SA status
diagnose vpn tunnel list          # List all VPN tunnels
diagnose vpn ipsec status        # IPSec SA status

# VPN Operations
diagnose vpn ike restart          # Restart IKE process
diagnose vpn tunnel up <name>    # Bring tunnel up
diagnose vpn tunnel down <name>  # Bring tunnel down
diagnose vpn tunnel flush <name> # Flush tunnel

# VPN Debugging
diagnose debug application ike -1
diagnose debug enable
diagnose vpn ike log-filter dst-addr4 <peer-ip>
```

### SSL VPN
```bash
# SSL VPN Status
get vpn ssl monitor              # SSL VPN connections
diagnose vpn ssl list            # List SSL VPN sessions
diagnose vpn ssl del-tunnel <index>  # Delete SSL tunnel

# SSL VPN Configuration
config vpn ssl settings
    set servercert <cert-name>
    set tunnel-ip-pools "SSLVPN_Pool"
    set port 443
end
```

---

## Monitoring & Diagnostics

### Real-time Monitoring
```bash
# System Performance
diagnose sys top                 # Real-time process monitor
diagnose sys top-mem             # Memory usage by process
diagnose sys mpstat             # Multi-processor statistics
diagnose sys iostat             # I/O statistics

# Session Monitoring
diagnose sys session stat       # Session statistics
diagnose sys session filter src <IP>
diagnose sys session filter dst <IP>
diagnose sys session list       # List filtered sessions
diagnose sys session clear      # Clear sessions
```

### Resource Monitoring
```bash
# CPU & Memory
get system performance status    # Overall performance
diagnose hardware sysinfo memory # Memory details
diagnose hardware sysinfo cpu   # CPU information

# Connection Tracking
diagnose sys session stat        # Session statistics
diagnose firewall statistic show # Firewall statistics
diagnose netlink aggregate list  # Aggregate statistics
```

---

## Packet Capture & Debug

### Packet Sniffer
```bash
# Basic Packet Capture
diagnose sniffer packet any 'host 10.0.0.1' 4
diagnose sniffer packet <interface> '<filter>' <verbose> <count>

# Verbose Levels:
# 1 = header
# 2 = header + data
# 3 = header + interface
# 4 = header + interface + data
# 5 = header + interface + data + ethernet
# 6 = header + interface + data + ethernet + detail

# Advanced Filters
diagnose sniffer packet any 'host 10.0.0.1 and port 443' 4
diagnose sniffer packet any 'src net 192.168.1.0/24 and dst port 80' 4
diagnose sniffer packet any 'tcp and port 22' 6 100  # Capture 100 packets

# Save to File
diagnose sniffer packet any '' 6 0 l  # Save to tmp
execute tftpput <filename> <tftp-server>
```

### Flow Debug
```bash
# Flow Debugging Setup
diagnose debug reset
diagnose debug enable
diagnose debug flow filter clear
diagnose debug flow filter addr <IP>
diagnose debug flow filter port <port>
diagnose debug flow filter proto <protocol>
diagnose debug flow show function-name enable
diagnose debug flow show iprope enable
diagnose debug flow trace start 100  # Trace 100 packets

# Disable Debug
diagnose debug disable
diagnose debug reset
```

### Application Debug
```bash
# IPS Debug
diagnose ips debug enable all
diagnose debug application ipsengine -1
diagnose debug application ipshelper -1

# Web Filter Debug
diagnose debug application urlfilter -1
diagnose debug application ftgd -1

# Authentication Debug
diagnose debug application fnbamd -1
diagnose debug application authd -1
```

---

## FortiManager Operations

### FortiManager Connection
```bash
# Configure Central Management
config system central-management
    set type fortimanager
    set fmg <FortiManager-IP>
    set include-default-servers disable
    config server-list
        edit 1
        set server-type update rating
        set server-address <FMG-IP>
    end
end

# Registration
execute central-mgmt register-device <fmg-serial> <password> <username> <password>
```

### FortiManager Commands
```bash
# Status & Sync
diagnose fmupdate dbcontract       # Database contract status
execute fgfm reclaim-dev-tunnel <device>  # Reclaim device tunnel
diagnose test application fgfmd 1  # Test FortiManager connection

# Update Operations
diagnose fmupdate updatenow fds    # Update IPS signatures
diagnose fmupdate updatenow fgd    # Update FortiGuard
diagnose fmupdate updatenow fct    # Update FortiClient
```

---

## Performance Tuning

### NP6/NP7 Processor
```bash
# NPU Status
get hardware npu np6 port-list     # NP6 port mapping
diagnose npu np6 port-list         # Detailed NPU port info
diagnose npu np6 session-stats     # NPU session statistics
diagnose npu np6 sse-stats         # NPU SSE statistics

# NPU Offloading
config system npu
    set capwap-offload enable
    set ipsec-offload enable
    set ssl-offload enable
end
```

### Session Management
```bash
# Session Limits
config system global
    set tcp-halfclose-timer 30
    set tcp-halfopen-timer 10
    set tcp-timewait-timer 1
    set udp-idle-timer 60
end

# Session Helper
config system session-helper
    show
    delete <id>  # Remove unnecessary helpers
end
```

### Resource Optimization
```bash
# Memory Management
diagnose sys kill-eldest-dhcp-client  # Free DHCP memory
diagnose hardware sysinfo shm         # Shared memory info
diagnose sys clear-session-table      # Clear session table

# CPU Optimization
config system global
    set optimize antivirus
    set av-failopen pass
end
```

---

## Troubleshooting Procedures

### Common Issues

#### High CPU Usage
```bash
# Identify CPU Usage
diagnose sys top
diagnose sys top-summary
diagnose sys process stat
diagnose sys session rate          # Session creation rate

# Mitigation
config system global
    set tcp-halfclose-timer 10
    set tcp-halfopen-timer 10
end
```

#### Memory Issues
```bash
# Memory Analysis
diagnose hardware sysinfo memory
diagnose sys top-mem
get system performance status

# Clear Memory
diagnose sys session clear
execute reboot  # Last resort
```

#### Connectivity Issues
```bash
# Connectivity Tests
execute ping <destination>
execute traceroute <destination>
diagnose sniffer packet any 'host <IP>' 4

# DNS Testing
diagnose test application dnsproxy 1
execute ping-options source <source-IP>
execute ping <destination>
```

### Log Analysis
```bash
# System Logs
execute log filter category event
execute log filter field srcip <IP>
execute log display

# Traffic Logs
execute log filter category traffic
execute log filter field dstport 443
execute log display

# Real-time Logs
diagnose log test  # Generate test log
execute log-report reset  # Reset log reports
```

### Emergency Commands
```bash
# EMERGENCY USE ONLY
execute factoryreset               # Complete factory reset
diagnose sys session clear        # Clear all sessions
diagnose debug crashlog clear    # Clear crash logs
execute shutdown                  # Immediate shutdown
diagnose sys kill-all-dhcp-clients  # Kill all DHCP clients
```

---

## Best Practices

### Pre-Change Procedures
1. Backup configuration: `execute backup config`
2. Check HA status: `get system ha status`
3. Document current state: `get system status`
4. Review active sessions: `diagnose sys session stat`

### Post-Change Validation
1. Verify configuration: `show | grep <change>`
2. Test connectivity: `execute ping <critical-host>`
3. Check logs: `execute log display`
4. Monitor performance: `diagnose sys top`

### Maintenance Windows
1. Schedule during low traffic
2. Have rollback plan ready
3. Test changes in lab first
4. Document all changes
5. Verify backups are current

---

## Reference

### Important File Locations
```
/var/log/                 # System logs
/etc/                     # Configuration files
/tmp/                     # Temporary files
/dev/shm/                 # Shared memory
```

### Default Management Ports
- **443/tcp**: HTTPS Admin GUI
- **22/tcp**: SSH
- **23/tcp**: Telnet (disabled by default)
- **541/tcp**: FortiManager
- **514/udp**: Syslog
- **161/udp**: SNMP
- **8900/tcp**: FortiClient
- **8013/tcp**: FortiAnalyzer

---

*Note: Commands may vary slightly between FortiOS versions. Always verify syntax in documentation for your specific version. Test all changes in a non-production environment first.*