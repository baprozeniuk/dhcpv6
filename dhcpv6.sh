#!/bin/bash

hostname=$(hostname -s)
suffix=".home.cookiesnbeer.com"
fqdn=$hostname$suffix

if [ -f /etc/redhat-release ] && [ "$( rpm -qa redhat-lsb-core )" == "" ]; then 
	echo hi
	yum -y install redhat-lsb-core
fi

linuxDistro=$(lsb_release -i | awk  '{print $3}')


if [ "$linuxDistro" == "Ubuntu" ]; then
	echo $linuxDistro" Detected"
	ubuntuCodename=$(lsb_release -c | awk '{print $2}')
	if [ "$ubuntuCodename" == "xenial" ]|| [ "$ubuntuCodename" == "precise" ] || [ "$ubuntuCodename" == "trusty" ]; then
		sed -e '/send host-name = gethostname();/ s/^#*/#/'  -i /etc/dhcp/dhclient.conf	
		sed -e '/send host-name = "<hostname>";/ s/^#*/#/'  -i /etc/dhcp/dhclient.conf	
		
		if ! grep -iq 'send host-name = "'$fqdn'";' /etc/dhcp/dhclient.conf; then
			echo 'send host-name = "'$fqdn'";' >> /etc/dhcp/dhclient.conf	
		fi
		if ! grep -iq 'send fqdn.fqdn = "'$fqdn.'";' /etc/dhcp/dhclient.conf; then
			echo 'send fqdn.fqdn = "'$fqdn.'";' >> /etc/dhcp/dhclient.conf	
		fi		
		if ! grep -iq 'send fqdn.encoded on;' /etc/dhcp/dhclient.conf; then
			echo 'send fqdn.encoded on;' >> /etc/dhcp/dhclient.conf	
		fi				
		if ! grep -iq 'send fqdn.server-update on;' /etc/dhcp/dhclient.conf; then
			echo 'send fqdn.server-update on;' >> /etc/dhcp/dhclient.conf	
		fi	
	fi

	for adapter in $(cat /etc/network/interfaces | grep iface | grep -v loopback | awk '{print $2}' | uniq)
	do
		if ! $(grep -i $adapter /etc/network/interfaces | grep -iq inet6); then
			echo "iface "$adapter" inet6 dhcp" >> /etc/network/interfaces
			echo "accept_ra 1" >> /etc/network/interfaces
		else
			echo "IPV6 config already exists for "$adapter" skipping configuration"
		fi
	done
	
	exit 0
fi



if [ "$linuxDistro" == "CentOS" ] || [ "$linuxDistro" == "RedHatEnterpriseServer" ];  then
	echo $linuxDistro" Detected"
	RHRelease=$(lsb_release -r | awk '{print $2}')
	RHMajor=$(lsb_release -r | awk '{print $2}' | awk -F '.' '{print $1}')
	if [ "$RHMajor" -eq "6" ]; then
		for adapter in $(ls /etc/sysconfig/network-scripts/ | grep ifcfg-eth | awk -F "-" '{print $2}')
		do
			if [ ! -f "/etc/dhcp/dhclient6-$adapter.conf" ]; then
				echo 'send host-name = "'$fqdn'";'  >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.fqdn = "'$fqdn.'";' >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.encoded on;' >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.server-update on;' >> /etc/dhcp/dhclient6-$adapter.conf
			else
				echo "Error: DHCP config already exists"
			fi
			if [ -f "/etc/sysconfig/network-scripts/ifcfg-$adapter" ]; then
				if ! grep -iq 'DHCPV6C="yes"' /etc/sysconfig/network-scripts/ifcfg-$adapter; then
					echo 'DHCPV6C="yes"' >> /etc/sysconfig/network-scripts/ifcfg-$adapter
				fi
			fi
		done
		exit 0
	elif [ "$RHMajor" -eq "7" ]; then
		for adapter in $(ls /etc/sysconfig/network-scripts/ | grep ifcfg-eth | awk -F "-" '{print $2}')
		do
			if [ ! -f "/etc/dhcp/dhclient6-$adapter.conf" ]; then
				echo 'send host-name = "'$fqdn'";'  >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.fqdn = "'$fqdn.'";' >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.encoded on;' >> /etc/dhcp/dhclient6-$adapter.conf
				echo 'send fqdn.server-update on;' >> /etc/dhcp/dhclient6-$adapter.conf
			else
				echo "Error: DHCP config already exists"
			fi
			if [ -f "/etc/sysconfig/network-scripts/ifcfg-$adapter" ]; then
				if ! grep -iq 'DHCPV6C="yes"' /etc/sysconfig/network-scripts/ifcfg-$adapter; then
					echo 'DHCPV6C="yes"' >> /etc/sysconfig/network-scripts/ifcfg-$adapter
				fi
			fi
		done
		exit 0
	fi
fi

exit 1