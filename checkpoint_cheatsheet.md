# Check Point Firewall Professional Cheat Sheet
> **Version**: R80.40, R81, R81.10, R81.20  
> **Last Updated**: 2025  
> **Scope**: Security Gateway, Management Server, Multi-Domain Server (MDS)

---

## Table of Contents
- [System Administration](#system-administration)
- [Cluster Operations](#cluster-operations)
- [Firewall Operations](#firewall-operations)
- [VPN Management](#vpn-management)
- [Monitoring & Debugging](#monitoring--debugging)
- [Log Management](#log-management)
- [Multi-Domain Server (MDS)](#multi-domain-server-mds)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting Scenarios](#troubleshooting-scenarios)

---

## System Administration

### Core Service Management
```bash
# Service Control
cpstart                              # Start all Check Point services
cpstop                               # Stop all Check Point services
cpstop -fwflag -proc                # Stop services but keep policy active in kernel
cprestart                            # Restart all Check Point services
cpwd_admin list                      # List all CP processes and their status
cpwd_admin stop -name <process>     # Stop specific process
cpwd_admin start -name <process>    # Start specific process

# System Information
cpinfo -y all                        # Generate comprehensive system information
cpstat fw                            # Display policy name, install time, interfaces
cpstat os -f all                     # Complete OS statistics
cpstat ha -f all                     # Detailed HA statistics
cplic print                          # Display license information
fw ver -k                            # Firewall and kernel version
```

### Configuration Management
```bash
# SIC Configuration
cpconfig                             # Main configuration utility
cp_conf sic init <password>         # Initialize SIC with new activation key
cp_conf sic state                   # Check SIC status
cp_conf admin get                   # Display admin configuration

# Expert Mode
expert                               # Enter expert mode
set expert-password                 # Set expert password (from clish)
```

### Network Configuration
```bash
# Interface Management (Clish)
show interface all                  # Display all interfaces
set interface <name> state on/off   # Enable/disable interface
set interface <name> ipv4-address <IP> mask-length <mask>

# Routing (Clish)
set static-route <network/mask> nexthop gateway address <gw-ip> on
set static-route default nexthop gateway address <gw-ip> on
show route                           # Display routing table
```

---

## Cluster Operations

### ClusterXL Status & Control
```bash
# Cluster Status
cphaprob stat                        # Display cluster status
cphaprob -a if                       # List status of cluster interfaces
cphaprob syncstat                   # Display sync status
cphaprob list                       # List cluster members and roles

# Cluster Control
clusterXL_admin down                # Set member to DOWN state
clusterXL_admin up                  # Set member to UP state
cphastart                            # Start cluster services
cphastop                             # Stop cluster services on member

# Cluster Failover
cphaprob state                       # Current state information
cphacu stat                          # ClusterXL Automatic Updates status
cphaconf set_pnote -d <device> -s <state> -t <timeout> -p register
```

### Cluster Synchronization
```bash
# Sync Operations
fw ctl pstat                         # Display sync statistics
cphaprob syncstat                    # Detailed sync status
cphaprob -reset syncstat            # Reset sync statistics

# Force Sync
cphaconf sync on                     # Enable state synchronization
cphaconf sync off                    # Disable state synchronization
```

---

## Firewall Operations

### Policy Management
```bash
# Policy Operations
fw stat                              # Display loaded policy and status
fw stat -l                           # Long format with interfaces
fw fetch <mgmt-server-ip>           # Fetch policy from management
fw unloadlocal                      # Unload security policy
fw putkey -n <host>                 # Install authentication key

# Policy Verification
fw ver                               # Display policy verification
fw ctl install                      # Install policy to kernel
```

### Connection Table Management
```bash
# Connection Table
fw tab -t connections -s            # Connection table statistics
fw tab -t connections -f            # Show connections (formatted)
fw tab -t connections -x            # Clear connection table (CAUTION!)
fw tab -s                            # Show all kernel tables statistics

# NAT Table
fw tab -t fwx_alloc -f              # Display NAT allocations
fw tab -t xlate -x                  # Clear NAT translation table (EMERGENCY)
```

### SecureXL Acceleration
```bash
# SecureXL Control
fwaccel stat                         # Display acceleration statistics
fwaccel stats -s                    # Detailed statistics
fwaccel on                          # Enable acceleration
fwaccel off                          # Disable acceleration
fwaccel cfg get                     # Display configuration

# Connection Templates
fwaccel conns                       # Show accelerated connections
fwaccel templates -s                # Display template statistics
```

---

## VPN Management

### IKE/IPsec Operations
```bash
# VPN Status
vpn tu                               # VPN Tunnel Utility (interactive)
vpn tu tlist                         # List all tunnels
vpn tu del <peer>                   # Delete tunnel with peer

# IKE Operations
vpn shell /show/tunnels/ike/peer/<peer-ip>     # Show IKE SA
vpn shell /tunnels/delete/IKE/peer/<peer-ip>   # Delete IKE SA
vpn shell /show/tunnels/ipsec/peer/<peer-ip>   # Show IPsec SA
vpn shell /tunnels/delete/IPsec/peer/<peer-ip> # Delete IPsec SA

# VPN Tables
fw tab -t IKE_SA_table -s          # IKE SA statistics
fw tab -t IPSEC_SA_table -s        # IPsec SA statistics
fw tab -t peers_count -s            # VPN peer statistics
```

### VPN Debugging
```bash
# Enable VPN Debug
vpn debug on TDERROR_ALL_ALL=5     # Maximum debug level
vpn debug ikeon                     # Enable IKE debug
vpn debug trunc                     # Truncate debug files
vpn debug off                       # Disable VPN debug
vpn debug ikeoff                    # Disable IKE debug

# VPN Debug Files
tail -f $FWDIR/log/vpnd.elg        # VPN daemon debug
tail -f $FWDIR/log/ike.elg         # IKE debug log
```

---

## Monitoring & Debugging

### FW Monitor (Packet Capture)
```bash
# Basic Capture
fw monitor -e "accept host(10.0.0.1);"
fw monitor -e "accept host(10.0.0.1) and port(443);"
fw monitor -e "accept src=10.0.0.0/24 and dst=192.168.0.0/24;"

# Advanced Capture
fw monitor -o output.cap            # Export to pcap format
fw monitor -ci 10 -co 11            # Capture specific interfaces
fw monitor -p all                   # Capture all positions (iIoO)
fw monitor -m iIoO                  # Specify capture points

# Capture Points:
# i = pre-inbound (before VM)
# I = post-inbound (after VM, before routing)
# o = pre-outbound (before VM)
# O = post-outbound (after VM)
```

### Kernel Debug
```bash
# Basic Kernel Debug
fw ctl debug 0                      # Reset all debug flags
fw ctl debug -buf 32768            # Set debug buffer size
fw ctl debug -m fw + drop          # Enable drop debugging
fw ctl debug -m fw + conn drop nat # Multiple debug flags

# Capture Debug Output
fw ctl kdebug -T -f > debug.txt    # Capture with timestamps
fw ctl kdebug -T -f | tee debug.txt & # Background capture

# Module-Specific Debug
fw ctl debug -m fw + xlate xltrc nat  # NAT debugging
fw ctl debug -m VPN all              # VPN debugging
```

### Drop Analysis
```bash
# Real-time Drop Monitoring
fw ctl zdebug drop | grep <IP>     # Monitor drops for specific IP
fw ctl zdebug drop -e              # Extended drop information

# Drop Statistics
fw ctl pstat | grep -i drop        # Kernel drop statistics
cpstat fw -f drop                  # Formatted drop statistics
```

---

## Log Management

### Log Operations
```bash
# Log File Management
fw log -n                           # Show log without name resolution
fw log -f                           # Follow log in real-time (tail)
fw log -b "<MMM DD, YYYY HH:MM:SS>" "<MMM DD, YYYY HH:MM:SS>"  # Time range
fw logswitch                        # Rotate current log file
fw lslogs                           # List all log files

# Log Export
fw logexport -n -i fw.log -o output.txt  # Export to ASCII
fw logexport -n -i fw.log -o output.csv -m csv  # Export to CSV

# SmartLog (R80+)
log show <number>                   # Display log entry
log list                            # List available logs
```

### Remote Log Fetching
```bash
# From Management Server
fw fetchlogs -f <logfile> <gateway-ip>  # Fetch logs from gateway
```

---

## Multi-Domain Server (MDS)

### MDS Management
```bash
# MDS Status
mdsstat                             # Display all domains status
mdsconfig                           # MDS configuration utility
mdsstart                            # Start MDS services
mdsstop                             # Stop MDS services

# Domain Operations
mdsenv <domain-name>                # Set environment to domain
mcd                                 # Change to domain directory
mdsstart_customer <domain>         # Start specific domain
mdsstop_customer <domain>          # Stop specific domain

# Domain Policy Operations
fwm load <policy> <gateway>        # Load policy from MDS
fwm verify <policy>                # Verify policy compilation
```

### Cross-Domain Management
```bash
# Query Across Domains
mdscmd crossdomainexec <domain> -c "fw stat"
mdscmd runcrossdomainquery -all query_rulebase -n <object>
```

---

## Performance Optimization

### CoreXL Configuration
```bash
# CoreXL Status
fw ctl multik stat                  # Display CoreXL status
fw ctl multik get_mode             # Current CoreXL mode
cpstat os -f multi_cpu              # CPU core statistics

# CoreXL Tuning
fw ctl affinity -l                  # List CPU affinity
fw ctl affinity -s                  # Set CPU affinity
cpmq get                            # Display Multi-Queue status
```

### Memory Management
```bash
# Memory Statistics
fw ctl pstat | grep -i memory      # Kernel memory usage
free -m                             # System memory (Linux)
cpstat os -f memory                # Formatted memory stats

# Clear Caches
echo 3 > /proc/sys/vm/drop_caches  # Clear page cache
```

---

## Troubleshooting Scenarios

### Common Issues Resolution

#### High CPU Usage
```bash
top -H -p $(pgrep fwd)             # Monitor firewall daemon
fw ctl pstat | grep Concurrent     # Check connection count
fwaccel stats -s | grep Templates  # Check template usage
```

#### Memory Issues
```bash
fw tab -s | sort -n -k4            # Sort kernel tables by size
fw ctl get int fwx_max_conns      # Get max connection limit
fw ctl set int fwx_max_conns <value>  # Set connection limit
```

#### SIC Issues
```bash
cp_conf sic state                  # Check SIC status
cpca_client lscert -stat Valid    # List valid certificates
cpca_client revoke_cert -n "CN"   # Revoke certificate
cpca_client create_cert -n "CN"   # Create new certificate
```

### Emergency Commands
```bash
# EMERGENCY ONLY - Use with extreme caution
fw unloadlocal                     # Remove all security enforcement
fw tab -t connections -x          # Clear all connections
fw tab -t xlate -x                 # Clear all NAT translations
cpstop; cpstart                    # Full service restart
```

---

## Best Practices

### Pre-Change Checklist
1. Create backup: `migrate export <backup-name>`
2. Verify cluster status: `cphaprob stat`
3. Check policy: `fw stat -l`
4. Document current state: `cpinfo -y all -o cpinfo.txt`

### Post-Change Verification
1. Verify services: `cpwd_admin list`
2. Check cluster sync: `cphaprob syncstat`
3. Monitor logs: `fw log -f -n`
4. Test connectivity: `tcpdump -i any host <test-ip>`

---

## Reference

### Important File Locations
```
$FWDIR/log/            # Log files location
$FWDIR/conf/           # Configuration files
$CPDIR/registry/       # Registry files
$FWDIR/database/       # Object database
/var/log/messages      # System messages
/var/log/dump/usermode # Core dumps
```

### Default Ports
- **257/tcp**: FW1 (Check Point services)
- **18190/tcp**: CPMI (Management Interface)
- **18191/tcp**: CPD (SIC communication)
- **18192/tcp**: CPD_admin
- **18264/tcp**: FW1_ica_services
- **19009/tcp**: SmartEvent

---

*Note: Always test commands in a lab environment before production use. Some commands require expert mode access and can impact service availability.*