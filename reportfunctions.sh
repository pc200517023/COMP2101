#!/bin/bash

# This function will send an error message to stderr
# Usage: error-message ["some text to print to stderr"]
function error-message {
    local prog=`basename $0`
    echo "${prog}: ${1:-Unknown Error - a moose bit my sister once...}" >&2
}

# This function will send a message to stderr and exit with a failure status
# Usage: error-exit ["some text to print to stderr" [exit-status]]
function error-exit {
    error-message "$1"
    exit "${2:-1}"
}

# This function will remove all the temp files created by the script
# The temp files are all named similarly, "/tmp/somethinginfo.$$"
cleanup(){
  rm -f /tmp/*.$$
}

# A trap command is used after the function definition to specify this function is to be run if we get a ^C while running
trap cleanup EXIT

# gather data into temporary files to reduce time spent running lshw
sudo lshw -class system >/tmp/sysinfo.$$ 2>/dev/null
sudo lshw -class memory >/tmp/memoryinfo.$$ 2>/dev/null
sudo lshw -class bus >/tmp/businfo.$$ 2>/dev/null
sudo lshw -class cpu >/tmp/cpuinfo.$$ 2>/dev/null

# extract the specific data items into variables
systemproduct=`sed -n '0,/product:/s/ *product: //p' /tmp/sysinfo.$$`
systemwidth=`sed -n '/width:/s/ *width: //p' /tmp/sysinfo.$$`
systemmotherboard=`sed -n '/product:/s/ *product: //p' /tmp/businfo.$$|head -1`
systembiosvendor=`sed -n '/vendor:/s/ *vendor: //p' /tmp/memoryinfo.$$|head -1`
systembiosversion=`sed -n '/version:/s/ *version: //p' /tmp/memoryinfo.$$|head -1`
systemcpuvendor=`sed -n '/vendor:/s/ *vendor: //p' /tmp/cpuinfo.$$|head -1`
systemcpuproduct=`sed -n '/product:/s/ *product: //p' /tmp/cpuinfo.$$|head -1`
systemcpuspeed=`sed -n '/size:/s/ *size: //p' /tmp/cpuinfo.$$|head -1`
systemcpucores=`sed -n '/configuration:/s/ *configuration:.*cores=//p' /tmp/cpuinfo.$$|head -1`

systemvendor=`sed -n '0,/vendor:/s/ *vendor: //p' /tmp/sysinfo.$$`
systemdesc=`sed -n '0,/description:/s/ *description: //p' /tmp/sysinfo.$$`
systemserial=`sed -n '0,/serial:/s/ *serial: //p' /tmp/sysinfo.$$`

sysram=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
ramsize=$(echo "scale=2; $sysram/(1024*1024)" | bc)


checkvars(){
  echo "Hii"
  
}

systemcpucachel1=$(sudo lscpu | grep -i 'cache')

# gather the remaining data needed
sysname=`hostname`
domainname=`hostname -d`
osname=`sed -n -e '/^NAME=/s/^NAME="\(.*\)"$/\1/p' /etc/os-release`
osversion=`sed -n -e '/^VERSION=/s/^VERSION="\(.*\)"$/\1/p' /etc/os-release`
memoryinfo=`sudo lshw -class memory|sed -e 1,/bank/d -e '/cache/,$d' |egrep 'size|description'|grep -v empty`
#ipinfo=`getipinfo`
ipinfo="hi"
diskusage=`df -h -t ext4`
    
systemcpuvendor=`sed -n '/vendor:/s/ *vendor: //p' /tmp/cpuinfo.$$|head -1`
systemcpuproduct=`sed -n '/product:/s/ *product: //p' /tmp/cpuinfo.$$|head -1`

#VGA details from lspci 
vga=$(lspci | grep -i vga | awk -F': ' '{print $2}')
model=$(lspci | grep -i vga | awk -F': ' '{print $0}' | awk '{for (i=1; i<=3; i++) printf $i " "; print ""}')


#done
cpureport() {
cat <<EOF

CPU Summary
=============================
CPU manufacturer and model : $systemcpuproduct from $systemcpuvendor
CPU architecture: $systemwidth
CPU core Count   : $systemcpucores
CPU maximum speed   : $systemcpuspeed
Size of L1, L2, L3 cache : $systemcpucachel1

EOF
}


#done
computerreport() {
cat <<EOF

Computer Summary
=============================
Computer Manufacturer : $systemvendor
Computer description : $systemdesc
Serial Number  : $systemserial

EOF
}


#done
osreport() {
cat <<EOF

OS Summary
=============================
Linux distro : $osname
Distro version : $osversion

EOF
}


#done
ramreport() {
cat <<EOF

RAM Summary
=============================
RAM Manufacturer : $systembiosvendor
RAM Model: Unknown
RAM Size  : $ramsize GB
RAM Speed  : Unknown
RAM Physical location: Unknown

EOF
}


#done
videoreport(){
cat <<EOF

Video Card Summary
=============================
Manufacturer : $vga
Model: $model

EOF
}


#done
diskreport() {

echo "Disk Summary"
echo "================================="

# Get list of disk devices
disks=$(lsblk -dlo NAME,VENDOR,MODEL,SIZE,UUID,MOUNTPOINT,FSSIZE,FSAVAIL)

namepat="sd*"
printf "%-5s %-10s %-20s %-5s %-10s %-10s %-5s %-5s\n" "Name" "Vendor" "Model" "Disk-Size" "UUID" "Mount Point" "Size" "free"
# Iterate over disks
while read -r name vendor model size uuid mountpoint fssize fsavail; do
    # Skip non-disk devices
    if [[ $name != $namepat ]]; then
        continue
    fi
    # Print disk information

    printf "%-5s %-10s %-20s %-5s %-10s %-10s %-5s %-5s\n" "$name" "$vendor" "$model" "$size" "$uuid" "$mountpoint" "$fssize" "$fsavail"
    
done <<< "$disks"
}


# Function to get network interface details
get_interface_detail_helper() {
    interface=$1

    ipv4_address=$(ip a s $interface|awk -F '[/ ]+' '/inet /{print $3}')
       
    # Get link state and current speed using ip
    link_state=$(ip link show $interface | awk '/state/{print $9}')
    
    # Get IP address in CIDR format using ip
    ip_address=$(ip -o -4 addr show $interface | awk '{split($4,a,"/"); print a[1]}')

    # Get bridge master using brctl
    bridge_master=$(brctl show $interface 2>/dev/null | awk 'NR==2{print $4}')

    # Get DNS server using resolv.conf
    dns_server=$(grep -E "^nameserver" /etc/resolv.conf | awk '{print $2}' | paste -s -d',')

    # Print the interface details in tabulated format
    printf "%-10s %-15s %-10s %-10s %-5s %-15s %-15s %-20s\n" "$interface" "$manufacturer" "$description" "$link_state" "$current_speed" "$ip_address" "$bridge_master" "$dns_server"
}

#done
networkreport() {

    echo "Network Summary"
    echo "================================="
    # Print the header row of the table
    printf "%-10s %-15s %-10s %-10s %-5s %-15s %-15s %-20s\n" "Interface" "Manufacturer" "Description" "Link-State" "Speed" "IP Address" "Bridge Master" "DNS Server"

    # Get a list of network interfaces
    interfaces=$(ip -o link show | awk '{print $2}' | awk -F: '{print $1}')

    # Iterate over each interface and retrieve its details
    for interface in $interfaces; do
        get_interface_detail_helper $interface
    done
}



