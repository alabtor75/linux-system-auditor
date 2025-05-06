#!/bin/bash
# Auteur : Soufianne Said NASSIBI
# Version : 1.0
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT_FILE="rapport_audit_$(hostname)_$(date +%Y%m%d).txt"
RECOMMENDATIONS=""
SILENT_MODE=0
[[ "$1" == "--silent" || "$1" == "-s" ]] && SILENT_MODE=1

banner() {
  clear
  echo -e "${CYAN}"
  cat << "EOF"
.____    .__                                              __                                    .___.__  __                
|    |   |__| ____  __ _____  ___   _________.__. _______/  |_  ____   _____   _____   __ __  __| _/|__|/  |_  ___________ 
|    |   |  |/    \|  |  \  \/  /  /  ___<   |  |/  ___/\   __\/ __ \ /     \  \__  \ |  |  \/ __ | |  \   __\/  _ \_  __ \
|    |___|  |   |  \  |  />    <   \___ \ \___  |\___ \  |  | \  ___/|  Y Y  \  / __ \|  |  / /_/ | |  ||  | (  <_> )  | \/
|_______ \__|___|  /____//__/\_ \ /____  >/ ____/____  > |__|  \___  >__|_|  / (____  /____/\____ | |__||__|  \____/|__|   
        \/       \/            \/      \/ \/         \/            \/      \/       \/           \/                        

EOF
  echo -e "${YELLOW}Linux System Auditor v1.0 ${NC}"
}


menu() {
  echo -e "${RED}"
             echo "┌────────────────────────────────────────────┐"
             echo "│              MAIN MENU - AUDIT             │"
             echo "├────────────────────────────────────────────┤"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "1" "System Information"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "2" "CPU, RAM and Processes"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "3" "Network Overview"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "4" "Disks and Storage"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "5" "Services & Open Ports"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "6" "Security Audit"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "7" "Full Export + Recommendations"
  printf "${YELLOW}│ %-2s ${NC}%-37s│\n" "0" "Exit"
   echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
  echo -n "Your choice > "
}


audit_system() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║          System Information        ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  local KERNEL ARCH HOST OS UPTIME DATE
  KERNEL=$(uname -r)
  ARCH=$(uname -m)
  HOST=$(hostname)
  OS=$(grep -oP '(?<=^PRETTY_NAME=).*' /etc/os-release | tr -d '"')
  UPTIME=$(uptime -p)
  DATE=$(date)

  printf "%-25s : %s\n" "Hostname" "$HOST"
  printf "%-25s : %s\n" "Operating System" "$OS"
  printf "%-25s : %s\n" "Kernel Version" "$KERNEL"
  printf "%-25s : %s\n" "Architecture" "$ARCH"
  printf "%-25s : %s\n" "Uptime" "$UPTIME"
  printf "%-25s : %s\n" "System Date" "$DATE"
  echo
}




audit_cpu_ram() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║          CPU / RAM / Processes     ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  CPU_MODEL=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
  CPU_CORES=$(nproc)
  LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
  RAM_LINE=$(free -m | awk '/Mem:/')
  TOTAL_RAM=$(echo $RAM_LINE | awk '{print $2}')
  USED_RAM=$(echo $RAM_LINE | awk '{print $3}')

  printf "%-25s : %s\n" "CPU Model" "$CPU_MODEL"
  printf "%-25s : %s\n" "Number of Cores" "$CPU_CORES"
  printf "%-25s : %s\n" "System Load" "$LOAD"
  printf "%-25s : %s MB\n\n" "RAM Used / Total" "${USED_RAM}/${TOTAL_RAM}"

  echo -e "Top 5 Processes by Memory Usage:"
  printf "%-8s %-20s %-8s %-8s\n" "PID" "Command" "%MEM" "%CPU"
  ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 6 | awk '{ printf "%-8s %-20s %-8s %-8s\n", $1, $2, $3, $4 }'

  if (( $(echo "$LOAD > $CPU_CORES" | bc -l) )); then
    RECOMMENDATIONS+="• High CPU load: consider load balancing or hardware upgrade.\n"
  fi
  if [ "$TOTAL_RAM" -lt 1024 ]; then
    RECOMMENDATIONS+="• Low RAM (<1GB): potential performance issues.\n"
  fi
  echo
}



audit_network() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║         Network and Connectivity   ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  echo -e "\nNetwork Interfaces:"
  printf "%-10s %-20s %-20s\n" "Name" "IP Address" "Status"
  ip -br addr | awk '{printf "%-10s %-20s %-20s\n", $1, $3, $2}'

  echo -e "\nTemporary Routes:"
  ip route | awk '{print " -", $0}'

  echo -e "\nPersistent Routes (configuration):"
  grep -Hr "IPADDR\|GATEWAY\|NETMASK\|PREFIX" /etc/sysconfig/network-scripts 2>/dev/null | sed 's/^/ - /'
  grep -Hr "gateway\|address" /etc/netplan 2>/dev/null | sed 's/^/ - /'

  echo -e "\nDetected DNS Servers:"
  grep "^nameserver" /etc/resolv.conf | awk '{print " - " $2}'

  echo -e "\nDNS Resolution Test:"
  DNS_TEST_DOMAIN="google.com"
  if getent hosts $DNS_TEST_DOMAIN >/dev/null 2>&1; then
    echo " ✔ DNS resolution successful via $DNS_TEST_DOMAIN"
  else
    echo " ✖ DNS resolution failed"
    RECOMMENDATIONS+="• DNS resolution failed for '$DNS_TEST_DOMAIN': check /etc/resolv.conf or DNS connectivity.\n"
  fi

  echo
}



audit_disks() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║          Storage Analysis          ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  echo -e "\n Disk usage (excluding tmpfs):"
  printf "%-20s %-8s %-8s %-8s %-8s %-8s %-10s\n" "Filesystem" "Type" "Size" "Used" "Avail" "Use%" "Mounted on"
  df -hT | awk '$2 !~ /tmpfs|devtmpfs/ {printf "%-20s %-8s %-8s %-8s %-8s %-8s %-10s\n", $1, $2, $3, $4, $5, $6, $7}'

  echo -e "\n Inode usage:"
  printf "%-20s %-10s %-10s %-10s %-10s %-10s\n" "Filesystem" "Inodes" "Used" "Free" "Use%" "Mounted on"
  df -i | awk '$1 !~ /tmpfs|devtmpfs/ {printf "%-20s %-10s %-10s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5, $6}'

  # Alert on /
  DISK_USAGE=$(df / | awk 'NR==2 {print $(NF-1)}' | tr -d '%')
  if [ "$DISK_USAGE" -gt 80 ]; then
    RECOMMENDATIONS+="• Root partition (/) is over 80% full: consider cleanup or resizing.\n"
  fi

  echo -e "\n  Detected volumes (mounted and unmounted):"
  lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL | grep -v "loop" | sed 's/^/ - /'

  echo -e "\n LVM volumes (if any):"
  if command -v lvs >/dev/null 2>&1; then
    lvs | sed 's/^/ - /'
  else
    echo " - LVM not available on this system."
  fi

  echo -e "\n  SMART status of disks (if available):"
  if command -v smartctl >/dev/null 2>&1; then
    for disk in /dev/sd?; do
      STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" || echo "Not available")
      echo " - $disk : $STATUS"
    done
  else
    echo " - smartctl not installed (install 'smartmontools')"
  fi

  echo
}



audit_services_ports() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║       Services & Open Ports        ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  # Running services
  echo -e "\n Active services (Top 10):"
  printf "%-40s %-10s\n" "Service Name" "Status"
  systemctl list-units --type=service --state=running 2>/dev/null | \
    awk 'NR>1 && NR<=11 {printf " %-40s %-10s\n", $1, $4}'

  # Enabled at startup
  echo -e "\n Enabled on boot (Top 10):"
  systemctl list-unit-files --type=service 2>/dev/null | grep enabled | \
    awk 'NR<=10 {printf " %-40s %s\n", $1, $2}'

  # Listening ports (IPv4)
  echo -e "\n🔌 Listening ports (IPv4 - Top 10):"
  printf "%-8s %-25s %-25s %-20s\n" "Proto" "Local Address" "Remote Address" "Program"
  ss -tulnp 2>/dev/null | grep LISTEN | head -n 10 | \
    awk '{split($NF, prog, "="); printf "%-8s %-25s %-25s %-20s\n", $1, $5, $6, (prog[2] ? prog[2] : "-")}'

  # Listening ports (IPv6)
  echo -e "\n Listening ports (IPv6 - Top 5):"
  ss -tulnp 'ip6' 2>/dev/null | grep LISTEN | head -n 5 | \
    awk '{split($NF, prog, "="); printf " %-8s %-25s %-25s %-20s\n", $1, $5, $6, (prog[2] ? prog[2] : "-")}'

  # Open ports without systemd service
  echo -e "\n Open ports without a systemd service (via lsof):"
  if command -v lsof >/dev/null 2>&1; then
    lsof -i -P -n | grep LISTEN | grep -vE "systemd|sshd|nginx|apache|mysql" | \
      awk '{print " - " $1 " PID:" $2 " Port:" $9}' | head -n 5
  else
    echo " - lsof not available"
  fi

  # Check common services
  echo -e "\n Checking common services:"
  for svc in sshd apache2 httpd nginx snmpd mysqld mariadb docker; do
    systemctl is-active --quiet $svc && \
      echo " - $svc: active" || \
      echo " - $svc: inactive"
  done

  echo
}



audit_security() {
  echo -e "${GREEN}╔════════════════════════════════════╗"
          echo -e "║        System Security Audit       ║"
          echo -e "╚════════════════════════════════════╝${NC}"

  # SSH root
  ROOT_SSH=$(grep PermitRootLogin /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
  echo -e "\n SSH Root Access: $ROOT_SSH"
  if [ "$ROOT_SSH" == "yes" ]; then
    RECOMMENDATIONS+="• SSH root access is enabled: consider disabling it to reduce risk.\n"
  fi

  # Firewall
  echo -n "  Active Firewall: "
  if systemctl is-active --quiet ufw; then
    echo "ufw (active)"
  elif systemctl is-active --quiet firewalld; then
    echo "firewalld (active)"
  else
    echo "none"
    RECOMMENDATIONS+="• No active firewall detected.\n"
  fi

  # SUID files
  echo -e "\n SUID Files (privileged binaries):"
  find /bin /sbin /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null | while read file; do
    echo " - $file"
  done | head -n 10

  # Accounts without password
  echo -e "\n Accounts without password:"
  awk -F: '($2=="" && $1!="") { print " - " $1 }' /etc/shadow 2>/dev/null

  # System users
  echo -e "\n👥 System Users (/etc/passwd):"
  printf "%-20s %-10s %-15s\n" "Username" "UID" "Shell"
  awk -F: '
  {
    user=$1; uid=$3; shell=$7;
    if (uid >= 1000 && shell ~ /bash|sh/) {
      printf "  %-20s %-10s %-15s\n", user, uid, shell
    } else if (uid >= 1000 && shell ~ /nologin|false/) {
      printf "  %-20s %-10s %-15s\n", user " (disabled)", uid, shell
    } else if (uid < 1000) {
      printf "  %-20s %-10s %-15s\n", user " (system)", uid, shell
    }
  }' /etc/passwd

  # Sudo group users
  echo -e "\n Users in sudo group:"
  getent group sudo | awk -F: '{print $4}' | tr ',' '\n' | while read user; do
    [ -n "$user" ] && echo " - $user"
  done

  echo -e "\n Explicit sudo rights (sudoers files):"
  grep -E '^[^#].*ALL' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sed 's/^/ - /'

  echo -e "\n Users with NOPASSWD sudo access:"
  grep -r 'NOPASSWD' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sed 's/^/ - /' | while read line; do
    echo "$line"
    RECOMMENDATIONS+="• One or more users have passwordless sudo access.\n"
  done

  echo
}


export_all() {
  banner
  audit_system
  audit_cpu_ram
  audit_network
  audit_disks
  audit_services_ports
  audit_security
  echo -e "\n${CYAN}==== Recommendations ====${NC}"
  echo -e "${RECOMMENDATIONS:-No specific recommendations.}"

  {
    banner
    audit_system
    audit_cpu_ram
    audit_network
    audit_disks
    audit_services_ports
    audit_security
    echo -e "\n${CYAN}==== Recommendations ====${NC}"
    echo -e "${RECOMMENDATIONS:-No specific recommendations.}"
  } > "$REPORT_FILE"

  if [ "$SILENT_MODE" -ne 1 ]; then
    echo -e "\n${CYAN}Report saved to: $REPORT_FILE${NC}"
  fi
}

while true; do
  banner
  menu
  read choice
  case $choice in
    1) audit_system; read -p "Press Enter to continue..." ;;
    2) audit_cpu_ram; read -p "Press Enter to continue..." ;;
    3) audit_network; read -p "Press Enter to continue..." ;;
    4) audit_disks; read -p "Press Enter to continue..." ;;
    5) audit_services_ports; read -p "Press Enter to continue..." ;;
    6) audit_security; read -p "Press Enter to continue..." ;;
    7) export_all; read -p "Press Enter to continue..." ;;
    0) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice."; sleep 1 ;;
  esac
done
