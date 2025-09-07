# Self-Healing-SIP-Service

**Self-Healing SIP Service with Kamailio and Asterisk**
**Project Overview**

This project implements a self-healing SIP infrastructure using Kamailio as the SIP load balancer and dispatcher and Asterisk as the SIP backend PBX. The system ensures high availability, automatic failover, and self-recovery of SIP services in case of backend failures.

The key innovation is that when a backend Asterisk server goes down, Kamailio detects the failure via SIP OPTIONS probing, automatically routes traffic to available backends, and triggers a restart script to recover the failed Asterisk server.

This setup is ideal for highly available VoIP deployments, call centers, UCaaS platforms, and telecom observability labs.

**Architecture Diagram**
               +-------------------+
               |    SIP Clients    |
               |  (softphones,     |
               |   SIPp for testing)|
               +---------+---------+
                         |
                         v
               +-------------------+
               |      Kamailio     |
               |  (Load Balancer & |
               |   Dispatcher)     |
               +---------+---------+
                         |
            +------------+------------+
            |                         |
            v                         v
  +-------------------+       +-------------------+
  |   Asterisk PBX 1  |       |   Asterisk PBX 2  |
  | (Local: 13.220.90.70)     | (Remote: 54.80.246.87) |
  +-------------------+       +-------------------+
            ^
            | Self-Healing Script (restart_asterisk.sh)
            +------------------------------------------------+


    
<img width="1024" height="1024" alt="Astersik_DIAGRAM" src="https://github.com/user-attachments/assets/94cbfeb9-bbc3-4ec3-a362-4aa1ba66b3a2" />

**Components Used**
Component	Role
Kamailio	SIP load balancer, dispatcher, and self-healing event handler.
Asterisk	SIP PBX backend handling INVITE, REGISTER, and call logic.
SIPp	SIP traffic generator for testing load, OPTIONS, and call flows.
Systemd	Manages Asterisk services locally and remotely.
SSH	Remote access to restart Asterisk servers automatically.
restart_asterisk.sh	Custom script triggered by Kamailio to restart failed Asterisk instances.
Features

**Load Balancing**: Kamailio distributes SIP INVITE requests among multiple Asterisk backends using round-robin dispatching.

**Health Monitoring**: Kamailio uses SIP OPTIONS to probe backend health every 10 seconds.

**Self-Healing**: When a backend goes DOWN:

**Kamailio trigger**s event_route[dispatcher:dst-down].

Executes restart_asterisk.sh to recover the failed backend.

Failover Routing: Traffic is immediately rerouted to healthy Asterisk servers if one backend fails.

Centralized Logging: Logs all restarts in /tmp/asterisk_restart.log with timestamps.

Remote Recovery: Can restart remote Asterisk servers over SSH if needed.

**Installation & Setup**
**1. Install Kamailio**
sudo apt update
sudo apt install kamailio kamailio-extra-modules

**2. Install Asterisk**
sudo apt install asterisk

**3. Configure Dispatcher in Kamailio**

File: /etc/kamailio/dispatcher.list

# group 1 - Asterisk backends
1 sip:13.220.90.70:5060
1 sip:54.80.246.87:5060

**4. Configure Kamailio Routes**

/etc/kamailio/kamailio.cfg contains routing logic, dispatcher configuration, and self-healing event_routes.

Ensure exec("/usr/local/bin/restart_asterisk.sh $var(dest)"); is used for dst-down events.

**5.** Create Self-Healing Script****

/usr/local/bin/restart_asterisk.sh

#!/bin/bash
DEST="$1"
IP=$(echo "$DEST" | sed -E 's|sip:([^:]+):[0-9]+.*|\1|')
LOGFILE="/tmp/asterisk_restart.log"
timestamp() { date "+%Y-%m-%d %H:%M:%S"; }
LOCAL_IPS=("127.0.0.1" "13.220.90.70" "172.31.17.9")
if [[ " ${LOCAL_IPS[@]} " =~ " $IP " ]]; then
    echo "$(timestamp) Restarting LOCAL Asterisk on $IP" >> $LOGFILE
    systemctl restart asterisk
    STATUS=$?
else
    echo "$(timestamp) Restart triggered for REMOTE Asterisk $IP ($DEST)" >> $LOGFILE
    ssh -o StrictHostKeyChecking=no root@$IP "systemctl restart asterisk" &
    STATUS=$?
fi
if [[ $STATUS -eq 0 ]]; then
    echo "$(timestamp) Restart SUCCESS for $IP" >> $LOGFILE
else
    echo "$(timestamp) Restart FAILED for $IP" >> $LOGFILE
fi

**6. Make Script Executable**
sudo chmod +x /usr/local/bin/restart_asterisk.sh

**7. Start Kamailio & Asterisk**
sudo systemctl restart kamailio
sudo systemctl restart asterisk

**How It Works**:-

SIP clients send REGISTER and INVITE requests to Kamailio.

Kamailio uses the dispatcher module to forward INVITE to one of the available Asterisk servers.

Kamailio periodically sends OPTIONS requests to check server health.

If a backend fails (no OPTIONS response), Kamailio triggers the restart script.

Traffic is automatically rerouted to remaining healthy Asterisk servers.

Once the failed backend comes back up, it is added back to the dispatcher pool.

**Benefits**

High Availability VoIP setup

Automated recovery of failed backends

Centralized logging and monitoring

Minimal downtime for SIP services

**Testing**

Use SIPp to simulate SIP clients and call flows:

sipp -sf uac.xml 13.220.90.70:5060 -s 1000 -p 5060 -m 1 -trace_msg


Stop one Asterisk server and watch /tmp/asterisk_restart.log for automatic restart events.

References

Kamailio Official Documentation

Asterisk Official Documentation

SIPp Documentation
