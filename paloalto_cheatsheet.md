# Palo Alto Networks Professional Cheat Sheet
> **Version**: PAN-OS 10.x, 11.x  
> **Last Updated**: 2025  
> **Scope**: PA-Series, VM-Series, Panorama Management

---

## Table of Contents
- [System Administration](#system-administration)
- [High Availability](#high-availability)
- [Network Configuration](#network-configuration)
- [Security Policies](#security-policies)
- [NAT Configuration](#nat-configuration)
- [VPN Configuration](#vpn-configuration)
- [User-ID & GlobalProtect](#user-id--globalprotect)
- [Monitoring & Diagnostics](#monitoring--diagnostics)
- [Debugging & Troubleshooting](#debugging--troubleshooting)
- [Panorama Management](#panorama-management)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)

---

## System Administration

### System Information & Status
```bash
# System Information
show system info                    # Complete system information
show system resources               # CPU and memory usage
show system disk-space              # Disk utilization
show system software status         # Software version status
show system state                   # Detailed system state
show system environmentals          # Hardware sensors status

# License Management
request license info                # Display license information
request license fetch               # Fetch licenses from server
show system info | match serial     # Get serial number
request support check               # Verify support status
```

### Configuration Management
```bash
# Configuration Operations
show config running                 # Show running configuration
show config candidate              # Show candidate configuration
show config diff                   # Difference between candidate and running
configure                          # Enter configuration mode
commit                             # Commit configuration changes
commit force                       # Force commit (override warnings)
commit partial                     # Partial commit (admin-level)

# Configuration Backup/Restore
save config to <filename>          # Save configuration
load config from <filename>        # Load configuration
load config partial from <file>    # Load partial configuration
scp export configuration to <user>@<host>:<path>

# Configuration Rollback
load config last-saved             # Load last saved config
rollback config <number>           # Rollback to previous version
show config list                   # List configuration versions
```

### Administrative Tasks
```bash
# User Management
configure
set mgt-config users <username> password
set mgt-config users <username> permissions role-based superuser yes
commit

# System Management
request restart system             # Reboot system
request shutdown system            # Shutdown system
request system private-data-reset # Factory reset
debug software restart process <process-name>  # Restart specific process

# Software Management
request system software check      # Check for updates
request system software download version <version>
request system software install version <version>
show system software status        # Installation status
```

### Log Management
```bash
# System Logs
show log system                    # System logs
tail follow yes mp-log <logfile>  # Tail logs
show log config                    # Configuration logs
less mp-log <logfile>             # View management plane logs
grep pattern <pattern> mp-log <logfile>

# Traffic Logs
show log traffic                   # Traffic logs
show log traffic direction equal backward  # Response traffic
show log traffic app equal ssl    # SSL traffic logs
show log threat                    # Threat logs
show log url                       # URL filtering logs
```

---

## High Availability

### HA Configuration & Status
```bash
# HA Status
show high-availability all         # Complete HA status
show high-availability state       # Current HA state
show high-availability interface ha1  # HA1 interface status
show high-availability interface ha2  # HA2 interface status
show high-availability transitions # State transitions
show high-availability control-link statistics  # Control link stats

# HA Operations
request high-availability state suspend  # Suspend HA (become passive)
request high-availability state functional  # Resume HA
request high-availability state force-suspend  # Force suspend
request high-availability sync-to-remote running-config  # Force config sync

# HA Monitoring
show high-availability flap-statistics  # Link flap statistics
show high-availability path-monitoring  # Path monitoring status
show high-availability virtual-address  # Virtual IP status
```

### HA Troubleshooting
```bash
# Debug HA
debug high-availability-agent on debug  # Enable HA debug
tail follow yes mp-log ha_agent.log    # Monitor HA logs
show high-availability control-link statistics  # Control link statistics

# Session Sync
show session info                  # Session statistics
show high-availability state-synchronization  # Sync statistics
debug device-server reset ha peer  # Reset HA peer connection
```

---

## Network Configuration

### Interface Management
```bash
# Interface Configuration
configure
set network interface ethernet <n> layer3 ip <IP/mask>
set network interface ethernet <n> link-state up
set network interface ethernet <n> link-speed auto
set network interface ethernet <n> link-duplex auto
commit

# Interface Status
show interface all                 # All interfaces
show interface <n>              # Specific interface
show interface logical             # Logical interfaces
test interface <n>              # Test interface connectivity

# VLAN Configuration
set network interface ethernet <n> layer2 units <n> tag <VLAN-ID>
set network vlan <n> interface <n>
set network virtual-router <n> interface <n>
```

### Routing Configuration
```bash
# Static Routes
set network virtual-router <n> routing-table ip static-route <n> destination <network/mask> nexthop ip-address <gateway>
set network virtual-router <n> routing-table ip static-route <n> interface <n>
set network virtual-router <n> routing-table ip static-route <n> metric <metric>

# Routing Table
show routing route                 # Routing table
show routing fib                   # Forwarding table
show routing protocol bgp summary  # BGP summary
show routing protocol ospf neighbor # OSPF neighbors
test routing fib-lookup ip <IP> virtual-router <n>  # Route lookup
```

### Zones Configuration
```bash
# Security Zones
set zone <n> network layer3 <n>
set zone <n> network layer2 <n>
set zone <n> enable-user-identification yes
set zone <n> enable-packet-buffer-protection yes

# Zone Protection
set zone-protection-profile <n> flood tcp-syn enable yes
set zone-protection-profile <n> flood icmp enable yes
set zone-protection-profile <n> scan <port-scan-type> action block-ip
```

---

## Security Policies

### Security Rules
```bash
# Policy Configuration
set rulebase security rules <n> from <source-zone>
set rulebase security rules <n> to <destination-zone>
set rulebase security rules <n> source <IP/network>
set rulebase security rules <n> destination <IP/network>
set rulebase security rules <n> application <app>
set rulebase security rules <n> service <service>
set rulebase security rules <n> action <allow|deny>
set rulebase security rules <n> log-end yes

# Policy Operations
show running security-policy        # Active security policy
test security-policy-match from <zone> to <zone> source <IP> destination <IP> protocol <n> destination-port <port>
move rulebase security rules <n> <top|bottom|before|after> <n>
delete rulebase security rules <n>
```

### Application & URL Filtering
```bash
# Application Control
show application <n>              # Application details
show predefined application       # List all applications
set rulebase security rules <n> application [ facebook ssl ]

# URL Filtering
show url-cloud status              # URL cloud status
test url <URL>                     # Test URL category
set profiles url-filtering <n> block <category>
set profiles url-filtering <n> alert <category>
```

### Threat Prevention
```bash
# Security Profiles
set profiles virus <n> decoder <protocol> action reset-both
set profiles spyware <n> rules <n> threat-name <n> action reset-both
set profiles vulnerability <n> rules <n> threat-name <n> action reset-both

# WildFire
show wildfire status               # WildFire status
show wildfire statistics           # WildFire statistics
test wildfire registration         # Test WildFire connectivity
```

---

## NAT Configuration

### Source NAT
```bash
# Dynamic IP and Port (PAT)
set rulebase nat rules <n> source-translation dynamic-ip-and-port interface-address interface <n>
set rulebase nat rules <n> from <zone>
set rulebase nat rules <n> to <zone>
set rulebase nat rules <n> source <network>
set rulebase nat rules <n> destination any

# Dynamic IP Pool
set address <pool-name> ip-range <start-IP>-<end-IP>
set rulebase nat rules <n> source-translation dynamic-ip-and-port translated-address <pool-name>
```

### Destination NAT
```bash
# Static NAT
set rulebase nat rules <n> destination-translation translated-address <internal-IP>
set rulebase nat rules <n> destination-translation translated-port <port>
set rulebase nat rules <n> from <zone>
set rulebase nat rules <n> to <zone>
set rulebase nat rules <n> destination <external-IP>
set rulebase nat rules <n> service <service>
```

### NAT Troubleshooting
```bash
# NAT Operations
show running nat-policy            # Active NAT policy
show session all filter nat <source|destination|both>
test nat-policy-match from <zone> to <zone> source <IP> destination <IP> protocol <n>
```

---

## VPN Configuration

### IPSec VPN
```bash
# IKE Gateway
set network ike gateway <n> authentication pre-shared-key key <key>
set network ike gateway <n> protocol ikev1 dpd enable yes
set network ike gateway <n> peer-address ip <peer-IP>
set network ike gateway <n> local-address interface <n>

# IPSec Tunnel
set network tunnel ipsec <n> auto-key ike-gateway <n>
set network tunnel ipsec <n> auto-key proxy-id <n> local <network>
set network tunnel ipsec <n> auto-key proxy-id <n> remote <network>
set network tunnel ipsec <n> tunnel-monitor enable yes

# VPN Status
show vpn flow name <n>           # VPN tunnel status
show vpn ike-sa                   # IKE SA status
show vpn ipsec-sa                 # IPSec SA status
show vpn tunnel                   # All VPN tunnels
```

### GlobalProtect VPN
```bash
# GlobalProtect Portal
show global-protect-portal statistics  # Portal statistics
show global-protect-portal current-user  # Connected users
show global-protect-portal client-config  # Client configuration

# GlobalProtect Gateway
show global-protect-gateway statistics  # Gateway statistics
show global-protect-gateway current-user  # Current users
show global-protect-gateway current-user user <username>  # Specific user
```

### VPN Troubleshooting
```bash
# Debug VPN
debug ike global on debug          # Enable IKE debug
less mp-log ikemgr.log            # IKE manager logs
clear vpn ike-sa                  # Clear IKE SAs
clear vpn ipsec-sa                # Clear IPSec SAs
test vpn ike-sa gateway <n>      # Test IKE gateway
test vpn ipsec-sa tunnel <n>     # Test IPSec tunnel
```

---

## User-ID & GlobalProtect

### User-ID Configuration
```bash
# User Mapping
show user ip-user-mapping all     # All user mappings
show user ip-user-mapping ip <IP> # Specific IP mapping
show user group list              # User groups
show user group name <group>      # Group members

# User-ID Agent
show user user-id-agent state all # Agent status
show user user-id-agent statistics # Agent statistics
clear user-cache all              # Clear user cache
```

### Authentication
```bash
# Authentication Profiles
test authentication authentication-profile <n> username <user> password <pass>
show authentication global-protect-portal-auth
debug user-id on debug            # Enable User-ID debug
```

---

## Monitoring & Diagnostics

### Session Management
```bash
# Session Information
show session info                  # Session statistics
show session all                   # All sessions
show session all filter application <app>
show session all filter source <IP>
show session all filter destination <IP>
show session all filter state <active|closed|discard>
show session id <session-id>      # Specific session

# Clear Sessions
clear session all                  # Clear all sessions
clear session all filter source <IP>
clear session id <session-id>
```

### Performance Monitoring
```bash
# System Performance
show system resources               # Resource utilization
show system statistics session     # Session statistics
show running resource-monitor      # Resource monitoring
show chassis status                # Hardware status

# Data Plane
show counter global                # Global counters
show counter global filter packet-filter yes
show counter interface all         # Interface counters
debug dataplane show session distribution  # Session distribution
```

### Connection Troubleshooting
```bash
# Packet Diagnostics
ping source <IP> host <destination>
traceroute source <IP> host <destination>
show arp all                       # ARP table
show neighbor all                  # IPv6 neighbors

# Flow Basic
test security-policy-match from <zone> to <zone> source <IP> destination <IP> protocol <n> destination-port <port>
show session all filter from <zone> to <zone> source <IP> destination <IP>
```

---

## Debugging & Troubleshooting

### Packet Capture
```bash
# Packet Capture Setup
debug dataplane packet-diag set capture stage <firewall|drop|transmit|receive>
debug dataplane packet-diag set capture byte-count <bytes>
debug dataplane packet-diag set filter match source <IP> destination <IP>

# Capture Operations
debug dataplane packet-diag set capture on  # Start capture
debug dataplane packet-diag set capture off # Stop capture
debug dataplane packet-diag show setting    # Show settings
debug dataplane packet-diag aggregate-logs  # Aggregate logs

# View Captures
view-pcap follow yes filter-pcap <pcap-file>
scp export filter-pcap from <file> to <user>@<host>:<path>
tftp export filter-pcap from <file> to <tftp-server>
```

### Debug Commands
```bash
# System Debug
debug software logging-level set level <level> service <service>
debug management-server on debug   # Management debug
debug device-server on debug       # Device server debug
debug user-id on debug             # User-ID debug

# Application Debug
debug application <app> on debug
tail follow yes mp-log <n>.log

# Disable Debug
debug software logging-level set level default service all
debug <service> off
```

### Log Analysis
```bash
# Traffic Analysis
show log traffic query "( addr.src in <IP> )"
show log traffic query "( addr.dst in <IP> ) and ( app eq ssl )"
show log traffic query "( zone.src eq <zone> ) and ( action eq deny )"

# Threat Analysis
show log threat query "( severity geq high )"
show log threat query "( threatid eq <ID> )"
```

---

## Panorama Management

### Panorama Configuration
```bash
# Device Management
show devices connected             # Connected devices
show devices all                   # All managed devices
request devices check              # Check device connectivity

# Template & Device Groups
show devicegroups                  # Device groups
show templates                     # Templates
show template-stack                # Template stacks

# Panorama Operations
commit-all                         # Commit to all devices
commit-all device-group <n>       # Commit to device group
commit-all template <n>           # Commit template
validate all                       # Validate all configurations
```

### Log Collection
```bash
# Log Collectors
show log-collector connected       # Connected collectors
show log-collector-group all      # Collector groups
show logging-status                # Logging status

# Log Queries
show log traffic direction panorama-based
show log threat direction panorama-based
```

---

## Performance Optimization

### Resource Optimization
```bash
# Session Capacity
set deviceconfig setting session tcp-reject-non-syn no
set deviceconfig setting session offload yes
set deviceconfig setting session accelerated-aging enable yes

# TCP Settings
set deviceconfig setting session tcp-non-syn-reject no
set deviceconfig setting tcp asymmetric-path bypass
set deviceconfig setting tcp urgent-data clear

# Application Optimization
set deviceconfig setting application bypass-exceed-queue yes
set deviceconfig setting application group-mapping-timeout <seconds>
```

### Hardware Acceleration
```bash
# Offload Settings
show running offload               # Offload status
set deviceconfig setting offload ssl-decrypt yes
set deviceconfig setting offload ipsec-decrypt yes

# Buffer Protection
set zone <n> enable-packet-buffer-protection yes
set deviceconfig setting packet-buffer-protection enable yes
```

---

## Best Practices

### Pre-Change Checklist
1. **Backup Configuration**: `save config to <backup_name>`
2. **Verify HA Status**: `show high-availability all`
3. **Check Commit Queue**: `show jobs all`
4. **Document Current State**: `show system info`

### Change Management Process
```bash
# Safe Change Process
configure                          # Enter config mode
                                  # Make changes
validate                          # Validate configuration
show config diff                  # Review changes
commit description "<desc>"       # Commit with description
```

### Post-Change Validation
1. **Verify Commit**: `show jobs id <job-id>`
2. **Check System Logs**: `show log system`
3. **Monitor Traffic**: `show log traffic`
4. **Test Connectivity**: `test security-policy-match`

### Maintenance Tasks
```bash
# Regular Maintenance
request system disk-usage cleanup  # Clean disk
request system resources check     # Check resources
show system logdb-quota            # Check log storage
delete config saved <old-config>   # Delete old configs
```

---

## Emergency Procedures

### Recovery Commands
```bash
# EMERGENCY USE ONLY
debug software restart            # Restart all software
request restart system            # System reboot
request high-availability state force-suspend  # Force HA suspend
clear session all                 # Clear all sessions
debug dataplane reset all        # Reset dataplane
```

### System Recovery
```bash
# Configuration Recovery
load config last-saved            # Load last known good
rollback config <version>         # Rollback to version
load config from <backup>         # Load from backup

# Factory Reset
request system private-data-reset # Full factory reset
maint                            # Enter maintenance mode (console)
```

---

## Reference

### Important File Locations
```
/opt/pancfg/mgmt/saved-configs/    # Saved configurations
/var/log/pan/                      # PAN-OS logs
/opt/panlogs/                      # Traffic logs
/opt/pancfg/mgmt/licenses/         # License files
```

### Management Ports
- **443/tcp**: Web GUI (HTTPS)
- **22/tcp**: SSH
- **3978/tcp**: Panorama management
- **28443/tcp**: Panorama log collection
- **123/udp**: NTP
- **514/udp**: Syslog

### CLI Modes
- **Operational**: Default mode for monitoring
- **Configure**: Configuration mode (type `configure`)
- **Debug**: Debug mode (various debug commands)

---

*Note: Commands may vary between PAN-OS versions. Always consult official documentation for your specific version. Test changes in a lab environment before production deployment.*