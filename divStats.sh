#!/bin/sh

######################################################
##                                                  ##
##       _  _          _____  _          _          ##
##      | |(_)        / ____|| |        | |         ##
##    __| | _ __   __| (___  | |_  __ _ | |_  ___   ##
##   / _` || |\ \ / / \___ \ | __|/ _` || __|/ __|  ##
##  | (_| || | \ V /  ____) || |_| (_| || |_ \__ \  ##
##   \__,_||_|  \_/  |_____/  \__|\__,_| \__||___/  ##
##                                                  ##
##       https://github.com/jackyaz/divStats        ##
##                                                  ##
######################################################

### Start of script variables ###
readonly SCRIPT_NAME="divStats"
readonly SCRIPT_VERSION="v0.1.0"
readonly SCRIPT_BRANCH="master"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/""$SCRIPT_NAME""/""$SCRIPT_BRANCH"
readonly SCRIPT_CONF="/jffs/configs/$SCRIPT_NAME.config"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	fi
}

### Code for this function courtesy of https://github.com/decoderman- credit to @thelonelycoder ###
Firmware_Version_Check(){
	echo "$1" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}
############################################################################

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 300 ]; then
			Print_Output "true" "Stale lock file found (>300 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output "true" "Lock file found (age: $ageoflock seconds) - statistic generation likely currently in progress" "$ERR"
			if [ -z "$1" ]; then
				exit 1
			else
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}

Update_Version(){
	if [ -z "$1" ]; then
		doupdate="false"
		localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		if [ "$localver" != "$serverver" ]; then
			doupdate="version"
		else
			localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
			remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
			if [ "$localmd5" != "$remotemd5" ]; then
				doupdate="md5"
			fi
		fi
		
		if [ "$doupdate" = "version" ]; then
			Print_Output "true" "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$doupdate" = "md5" ]; then
			Print_Output "true" "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File "divstats_www.asp"
		Modify_WebUI_File
		
		if [ "$doupdate" != "false" ]; then
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			exit 0
		else
			Print_Output "true" "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	case "$1" in
		force)
			serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
			Print_Output "true" "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
			Update_File "divstats_www.asp"
			Modify_WebUI_File
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			exit 0
		;;
	esac
}
############################################################################

Update_File(){
	if [ "$1" = "divstats_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/jffs/scripts/$1" >/dev/null 2>&1; then
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			rm -f "/jffs/scripts/$1"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$SCRIPT_NAME generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup"' # '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/services-start
				echo "" >> /jffs/scripts/services-start
				echo "/jffs/scripts/$SCRIPT_NAME startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
				chmod 0755 /jffs/scripts/services-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
		;;
	esac
}

Auto_Cron(){
	case $1 in
		create)
			Auto_Cron delete 2>/dev/null
			cru a "$SCRIPT_NAME" "*/30 * * * * /jffs/scripts/$SCRIPT_NAME generate"
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

RRD_Initialise(){
	if [ ! -f /jffs/scripts/divstats_rrd.rrd ]; then
		Download_File "$SCRIPT_REPO/divstats_xml.xml" "/jffs/scripts/divstats_xml.xml"
		rrdtool restore -f /jffs/scripts/divstats_xml.xml /jffs/scripts/divstats_rrd.rrd
		rm -f /jffs/scripts/divstats_xml.xml
	fi
}

Get_CONNMON_UI(){
	if [ -f /www/AdaptiveQoS_ROG.asp ]; then
		echo "AdaptiveQoS_ROG.asp"
	else
		echo "AiMesh_Node_FirmwareUpgrade.asp"
	fi
}

Mount_WebUI(){
	umount /www/Advanced_MultiSubnet_Content.asp 2>/dev/null
	if [ ! -f /jffs/scripts/divstats_www.asp ]; then
		Download_File "$SCRIPT_REPO/divstats_www.asp" "/jffs/scripts/divstats_www.asp"
	fi
	
	mount -o bind /jffs/scripts/divstats_www.asp "/www/Advanced_MultiSubnet_Content.asp"
}

Modify_WebUI_File(){
	### menuTree.js ###
	umount /www/require/modules/menuTree.js 2>/dev/null
	tmpfile=/tmp/menuTree.js
	cp "/www/require/modules/menuTree.js" "$tmpfile"
	
	sed -i '/{url: "Advanced_MultiSubnet_Content.asp", tabName: /d' "$tmpfile"
	sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_MultiSubnet_Content.asp", tabName: "Diversion Statistics"},' "$tmpfile"
	sed -i '/retArray.push("Advanced_MultiSubnet_Content.asp");/d' "$tmpfile"
	
	if [ -f "/jffs/scripts/connmon" ]; then
		sed -i '/{url: "'"$(Get_CONNMON_UI)"'", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "'"$(Get_CONNMON_UI)"'", tabName: "Uptime Monitoring"},' "$tmpfile"
		sed -i '/retArray.push("'"$(Get_CONNMON_UI)"'");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/spdmerlin" ]; then
		sed -i '/{url: "Advanced_Feedback.asp", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_Feedback.asp", tabName: "SpeedTest"},' "$tmpfile"
		sed -i '/retArray.push("Advanced_Feedback.asp");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/ntpmerlin" ]; then
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Feedback_Info.asp", tabName: "NTP Daemon"},' "$tmpfile"
	fi
	
	if ! diff -q "$tmpfile" "/jffs/scripts/custom_menuTree.js" >/dev/null 2>&1; then
		cp "$tmpfile" "/jffs/scripts/custom_menuTree.js"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind "/jffs/scripts/custom_menuTree.js" "/www/require/modules/menuTree.js"
	### ###
	
	### start_apply.htm ###
	umount /www/start_apply.htm 2>/dev/null
	tmpfile=/tmp/start_apply.htm
	cp "/www/start_apply.htm" "$tmpfile"
	if [ -f "/jffs/scripts/ntpmerlin" ] || [ -f "/jffs/scripts/spdmerlin" ]; then
		sed -i -e 's/setTimeout("parent.redirect();", action_wait\*1000);/parent.showLoading(restart_time, "waiting");'"\\r\\n"'setTimeout(function(){ getXMLAndRedirect(); alert("Please force-reload this page (e.g. Ctrl+F5)");}, restart_time\*1000);/' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/connmon" ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("'"$(Get_CONNMON_UI)"'") != -1){'"\\r\\n"'parent.showLoading(restart_time, "waiting");'"\\r\\n"'setTimeout(function(){ getXMLAndRedirect(); alert("Please force-reload this page (e.g. Ctrl+F5)");}, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Advanced_MultiSubnet_Content.asp") != -1){'"\\r\\n"'parent.showLoading(restart_time, "waiting");'"\\r\\n"'setTimeout(function(){ getXMLAndRedirect(); alert("Please force-reload this page (e.g. Ctrl+F5)");}, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	
	if [ ! -f /jffs/scripts/custom_start_apply.htm ]; then
		cp "/www/start_apply.htm" "/jffs/scripts/custom_start_apply.htm"
	fi
	
	if ! diff -q "$tmpfile" "/jffs/scripts/custom_start_apply.htm" >/dev/null 2>&1; then
		cp "$tmpfile" "/jffs/scripts/custom_start_apply.htm"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind /jffs/scripts/custom_start_apply.htm /www/start_apply.htm
	### ###
}

WriteStats_ToJS(){
	html='document.getElementById("divstats").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="$html""$line""\\r\\n"
	done < "$1"
	html="$html"'"'
	echo "$html" > "$2"
}

# shellcheck disable=SC1090
# shellcheck disable=SC2154
# shellcheck disable=SC2034
# shellcheck disable=SC2188
# shellcheck disable=SC2167
# shellcheck disable=SC2165
# shellcheck disable=SC2059
# shellcheck disable=SC2129
# shellcheck disable=SC2126
# shellcheck disable=SC2086
# shellcheck disable=SC2005
# shellcheck disable=SC2013
# shellcheck disable=SC2002
# shellcheck disable=SC2004
# shellcheck disable=SC1003
Generate_Stats_Diversion(){
	# Diversion is free to use under the GNU General Public License version 3 (GPL-3.0)
	# https://opensource.org/licenses/GPL-3.0
	
	# Proudly coded by thelonelycoder
	# Copyright (C) 2016-2019 thelonelycoder - All Rights Reserved
	# https://www.snbforums.com/members/thelonelycoder.25480/
	# https://diversion.ch
	
	# Script Version 4.0.7
	
	# set environment PATH to system binaries
	export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH
	
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	mkdir -p "$(readlink /www/ext)"
	
	Print_Output "true" "Starting Diversion statistic generation..." "$PASS"
	
	DIVERSION_DIR=/opt/share/diversion
	
	if [ -f "${DIVERSION_DIR}/.conf/diversion.conf" ]; then
		#startCount=$(date +%s)
		diversion count_ads
		. "${DIVERSION_DIR}/.conf/diversion.conf"
		wsTopHosts=10
		wsTopClients=5
		
		case "$EDITION" in
			Lite)		this_blockingIP=0.0.0.0;;
			Standard)	this_blockingIP=$psIP;;
		esac
		
		lanIPaddr=$(nvram get lan_ipaddr | sed 's/\.[0-9]*$/./')
		human_number(){	sed -re " :restart ; s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/ ; t restart ";}
		LINE=" --------------------------------------------------------\\n"
		[ -z "$(nvram get odmpid)" ] && routerModel=$(nvram get productid) || routerModel=$(nvram get odmpid)
		[ -z "$FRIENDLY_ROUTER_NAME" ] && FRIENDLY_ROUTER_NAME=$routerModel
		statsFile="/tmp/stats.txt"
		
		# start of the output for the stats
		printf "\\n Router Stats $(date +"%c")\\n$LINE" >${statsFile}
		printf " $FRIENDLY_ROUTER_NAME ($routerModel) Firmware-$(nvram get buildno) @ $(nvram get lan_ipaddr)\\n" >>${statsFile}
		[ "$thisM_VERSION" ] && THIS_VERSION="${thisVERSION}.$thisM_VERSION" || THIS_VERSION=$thisVERSION
		printf " Compiled by $NAME $THIS_VERSION\\n$LINE" >>${statsFile}
		printf "\\n Ad-Blocking stats:" >>${statsFile}
		printf "\\n$LINE" >>${statsFile}
		
		BD=$(grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" "${DIVERSION_DIR}/list/blacklist" "${DIVERSION_DIR}/list/wc_blacklist" | wc -l)
		printf "%-13s%s\\n" " $(echo $BD | human_number)" "domains in total are blocked" >>${statsFile}
		BL=$(grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -l)
		if [ "$bfFs" = "on" ]; then
			BLfs=$(grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist_fs" | wc -l)
			if [ "$bfTypeinUse" = "primary" ]; then
				printf "%-13s%s\\n" " $(echo $BL | human_number)" "blocked by primary blocking list in use" >>${statsFile}
				printf "%-13s%s\\n" " $(echo $BLfs | human_number)" "(blocked by secondary blocking list)" >>${statsFile}
			else
				printf "%-13s%s\\n" " $(echo $BLfs | human_number)" "blocked by secondary blocking list in use" >>${statsFile}
				printf "%-13s%s\\n" " $(echo $BL | human_number)" "(blocked by primary blocking list)" >>${statsFile}
			fi
		else
			printf "%-13s%s\\n" " $(echo $BL | human_number)" "blocked by blocking list" >>${statsFile}
		fi
		
		printf "%-13s%s\\n" " $(grep "^[^#]" "${DIVERSION_DIR}/list/blacklist" | wc -l)" "blocked by blacklist" >>${statsFile}
		printf "%-13s%s\\n" " $(grep "^[^#]" "${DIVERSION_DIR}/list/wc_blacklist" | wc -l)" "blocked by wildcard blacklist" >>${statsFile}
		printf "\\n" >>${statsFile}
		if [ "$bfFs" = "on" ] && [ "$alternateBF" = "on" ]; then
			printf " Primary ad-blocking:\\n" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsBlocked | human_number)" "ads in total blocked" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsWeek | human_number)" "ads this week, since last $bfUpdateDay" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsNew | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
			printf " Alternate ad-blocking:\\n" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsBlockedAlt | human_number)" "ads in total blocked" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsWeekAlt | human_number)" "ads this week, since last $bfUpdateDay" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsNewAlt | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
			printf " Combined ad-blocking totals:\\n" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $(($adsBlocked+$adsBlockedAlt)) | human_number)" "ads in total blocked" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $(($adsWeek+$adsWeekAlt)) | human_number)" "ads this week, since last $bfUpdateDay" >>${statsFile}
			printf "%-13s%s\\n$LINE" " $(echo $(($adsNew+$adsNewAlt)) | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
		else
			printf "%-13s%s\\n" " $(echo $adsBlocked | human_number)" "ads in total blocked" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsWeek | human_number)" "ads this week, since last $bfUpdateDay" >>${statsFile}
			printf "%-13s%s\\n$LINE" " $(echo $adsNew | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
		fi
		
		[ -d /tmp/divstats ] && rm -rf /tmp/divstats
		mkdir /tmp/divstats
		
		# make copies of files to count on to /tmp
		grep "^[^#]" "${DIVERSION_DIR}/list/whitelist" | awk '{print $1}' > /tmp/divstats/div-whitelist
		grep "^[^#]" "${DIVERSION_DIR}/list/blacklist" | awk '{print " "$2}' > /tmp/divstats/div-blacklist
		grep "^[^#]" "${DIVERSION_DIR}/list/wc_blacklist" | awk '{print $1}' > /tmp/divstats/div-wc_blacklist
		
		# create local client names lists for name resolution and, if wsFilterLN enabled, for more accurate stats results
		# from hosts.dnsmasq
		[ -s /etc/hosts.dnsmasq ] && awk '{print $1}' /etc/hosts.dnsmasq >>/tmp/divstats/div-allips.tmp
		# from dnsmasq.leases
		[ -s /var/lib/misc/dnsmasq.leases ] && awk '{print $3}' /var/lib/misc/dnsmasq.leases >>/tmp/divstats/div-allips.tmp
		# remove duplicates, sort by last octet
		cat /tmp/divstats/div-allips.tmp | sort -t . -k 4,4n -u > /tmp/divstats/div-allips
		
		# add reverse router IP
		echo "$lanIPaddr" | awk -F. '{print "."$3"." $2"."$1}' >>/tmp/divstats/div-ipleases
		
		# create local client files
		for i in $(awk '{print $1}' /tmp/divstats/div-allips); do
			if [ -s /etc/hosts.dnsmasq ] && grep -wq $i /etc/hosts.dnsmasq; then
				echo "$(awk -v var="$i" -F' ' '$1 == var{print $2}' /etc/hosts.dnsmasq)" >>/tmp/divstats/div-hostleases
				echo "$(awk -v var="$i" -F' ' '$1 == var{print $1, $2}' /etc/hosts.dnsmasq)" >>/tmp/divstats/div-iphostleases
				echo "$(awk -v var="$i" -F' ' '$1 == var{print $1}' /etc/hosts.dnsmasq)" >>/tmp/divstats/div-ipleases
				# add the reverse client IP addresses
				echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/divstats/div-ipleases
			elif grep -wq "$i *" /var/lib/misc/dnsmasq.leases; then
				echo "$i Name-N/A" >>/tmp/divstats/div-iphostleases
				echo "$i" >>/tmp/divstats/div-ipleases
				# add the reverse client IP addresses
				echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/divstats/div-ipleases
			else
				echo "$(awk -v var="$i" -F' ' '$3 == var{print $4}' /var/lib/misc/dnsmasq.leases)" >>/tmp/divstats/div-hostleases
				echo "$(awk -v var="$i" -F' ' '$3 == var{print $3, $4}' /var/lib/misc/dnsmasq.leases)" >>/tmp/divstats/div-iphostleases
				echo "$(awk -v var="$i" -F' ' '$3 == var{print $3}' /var/lib/misc/dnsmasq.leases)" >>/tmp/divstats/div-ipleases
				# add the reverse client IP addresses
				echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/divstats/div-ipleases
			fi
		done
		
		# overwrite with empty files if filtering is off
		[ "$wsFilterLN" = "off" ] && >/tmp/divstats/div-hostleases >/tmp/divstats/div-ipleases
		
		# write empty backup file if not found for [Client Name*] list
		[ ! -f "${DIVERSION_DIR}/backup/diversion_stats-iphostleases" ] && > "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"
		
		# show what settings were used to compile
		#printf "\\n Stats settings applied:\\n$LINE" >>${statsFile}
		#[ "$bfFs" = "on" ] && printf " Info: blocking list fast switch (fs) is enabled.\\n Stats are always run towards the primary blocking list.\\n\\n" >>${statsFile}
		#printf " Filter local client names set to: $wsFilterLN\\n" >>${statsFile}
		#printf " Compiling top $wsTopHosts domains for $wsTopClients clients\\n" >>${statsFile}
		#if [ "$domainNeeded" = "on" ]; then
		#	printf " Domain needed (set in [ds]): $domainNeeded\\n" >>${statsFile}
		#fi
		#printf "$LINE" >>${statsFile}
		
		# lists key for the listing
		#printf "\\n Lists key:\\n$LINE client names resolved at stats creation time\\n\\n" >>${statsFile}
		#printf "%-17s%s\\n" " Name-N/A" "= name could not be resolved" >>${statsFile}
		#printf "%-17s%s\\n" " Client Name*" "= name resolved from saved file, may not be accurate" >>${statsFile}
		#printf "%-17s%s\\n" " blocked" "= blocked by blockinglist" >>${statsFile}
		#printf "%-17s%s\\n" " blacklisted" "= blocked by blacklist" >>${statsFile}
		#printf "%-17s%s\\n" " wc_blacklisted" "= blocked by wildcard blacklist" >>${statsFile}
		#printf "%-17s%s\\n$LINE" " whitelisted" "= whitelisted by whitelist" >>${statsFile}
		
		# begin of stats computing
		startCountwsTopHosts=$(date +%s)
		printf "\\n\\n The top $wsTopHosts requested domains were:\\n$LINE" >>${statsFile}
		awk '/query\[AAAA]|query\[A]/ {print $(NF-2)}' /opt/var/log/dnsmasq.log* |
		awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
		grep -viF -f /tmp/divstats/div-hostleases | grep -viF -f /tmp/divstats/div-ipleases | head -$wsTopHosts >>/tmp/divstats/div-th
		# show if found in any of these lists
		for i in $(awk '{print $2}' /tmp/divstats/div-th); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if grep -q " $i$" "${DIVERSION_DIR}/list/blockinglist"; then
				echo "blocked" >>/tmp/divstats/div-bwl
			elif grep -q " $i$" /tmp/divstats/div-blacklist; then
				echo "blacklisted" >>/tmp/divstats/div-bwl
			elif grep -q "$i$" /tmp/divstats/div-wc_blacklist; then
				echo "wc_blacklisted" >>/tmp/divstats/div-bwl
			elif grep -q "$i$" /tmp/divstats/div-whitelist; then
				echo "whitelisted" >>/tmp/divstats/div-bwl
			else
				echo >>/tmp/divstats/div-bwl
			fi
		done
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div-th /tmp/divstats/div-bwl >>${statsFile}
		
		startCountTopAdHosts=$(date +%s)
		printf "\\n\\n The top $wsTopHosts blocked ad domains were:\\n$LINE" >>${statsFile}
		awk '/is '$this_blockingIP'|is 0.0.0.0/ {print $(NF-2)}' /opt/var/log/dnsmasq.log* |
		awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
		head -$wsTopHosts >>/tmp/divstats/div-tah
		
		# show if found in any of these lists
		for i in $(awk '{print $2}' /tmp/divstats/div-tah); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if grep -q " $i$" "${DIVERSION_DIR}/list/blockinglist"; then
				echo "blocked" >>/tmp/divstats/div-bw
			elif grep -q " $i$" /tmp/divstats/div-blacklist; then
				echo "blacklisted" >>/tmp/divstats/div-bw
			elif grep -q "$i$" /tmp/divstats/div-wc_blacklist; then
				echo "wc_blacklisted" >>/tmp/divstats/div-bw
			fi
		done
		[ ! -f /tmp/divstats/div-bw ] && >/tmp/divstats/div-bw
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div-tah /tmp/divstats/div-bw >>${statsFile}
		
		AL=1 # prevent divide by zero
		startCountNoisyClients=$(date +%s)
		printf "\\n\\n The top $wsTopClients noisiest name clients:\\n$LINE\\n" >>${statsFile}
		printf " count for IP, client name: count for domain - percentage\\n$LINE" >>${statsFile}
		awk -F " " '/from '$lanIPaddr'/ {print $NF}' /opt/var/log/dnsmasq.log* |
		awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-15s""%s %s",a[o],o}' | sort -nr |
		head -$wsTopClients >/tmp/divstats/div1
		for i in $(awk '{print $2}' /tmp/divstats/div1); do
			i=$(echo $i | sed -e 's/\./\\./g')
			grep -w $i /opt/var/log/dnsmasq.log* | awk '{print $(NF-2)}' |
			awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
			grep -viF -f /tmp/divstats/div-hostleases | grep -viF -f /tmp/divstats/div-ipleases |
			head -1 >>/tmp/divstats/div2
			CH="$(awk 'END{print $1}' /tmp/divstats/div2)"
			TH="$(awk -v AL="$AL" 'FNR==AL{print $1}' /tmp/divstats/div1)"
			AL=$(( AL + 1))
			awk -v CH="$CH" -v TH="$TH" 'BEGIN{printf "%-5.2f%s\n", ((CH * 100)/TH), "%"}' >>/tmp/divstats/div3
		done
		
		# add client names
		for i in $(awk '{print $2}' /tmp/divstats/div1); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if grep -wq $i /tmp/divstats/div-iphostleases; then
				printf "%-26s\\n" "$(awk -v var="$i" -F' ' '$1 == var{print $2}' /tmp/divstats/div-iphostleases):" >>/tmp/divstats/div5
			elif grep -wq $i "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"; then
				printf "%-26s\\n" "$(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)*:" >>/tmp/divstats/div5
			else
				printf "%-26s\\n" "Name-N/A:" >>/tmp/divstats/div5
			fi
		done
		
		# show if found in any of these lists
		for i in $(awk '{print $2}' /tmp/divstats/div2); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if grep -q " $i$" "${DIVERSION_DIR}/list/blockinglist"; then
				echo "blocked" >>/tmp/divstats/div-noisy
			elif grep -q " $i$" /tmp/divstats/div-blacklist; then
				echo "blacklisted" >>/tmp/divstats/div-noisy
			elif grep -q "$i$" /tmp/divstats/div-wc_blacklist; then
				echo "wc_blacklisted" >>/tmp/divstats/div-noisy
			elif grep -q "$i$" /tmp/divstats/div-whitelist; then
				echo "whitelisted" >>/tmp/divstats/div-noisy
			else
				echo >>/tmp/divstats/div-noisy
			fi
		done
		
		# assemble the tables and print
		awk 'NR==FNR{a[FNR]=$0 "-";next} {print a[FNR],$0}' /tmp/divstats/div2 /tmp/divstats/div3 >/tmp/divstats/div4
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div4 /tmp/divstats/div-noisy >/tmp/divstats/div7
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div1 /tmp/divstats/div5 >/tmp/divstats/div6
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div6 /tmp/divstats/div7 >>${statsFile}
		
		startCountwsTopHostsClients=$(date +%s)
		printf "\\n\\n Top $wsTopHosts domains for top $wsTopClients clients:\\n$LINE" >>${statsFile}
		for i in $(awk '{print $2}' /tmp/divstats/div1); do
			if grep -wq $i /tmp/divstats/div-iphostleases; then
				printf "\\n $i, $(awk -v var="$i" -F' ' '$1 == var{print $2}' /tmp/divstats/div-iphostleases):\\n$LINE" >>${statsFile}
			elif grep -wq $i "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"; then
				printf "\\n $i, $(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)*:\\n$LINE" >>${statsFile}
			else
				printf "\\n $i, Name-N/A:\\n$LINE" >>${statsFile}
			fi
			# remove files for next client compiling run
			rm -f /tmp/divstats/div-thtc /tmp/divstats/div-toptop
			grep -w $i /opt/var/log/dnsmasq.log* | awk '{print $(NF-2)}'|
			awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
			grep -viF -f /tmp/divstats/div-hostleases | grep -viF -f /tmp/divstats/div-ipleases | head -$wsTopHosts >>/tmp/divstats/div-thtc
			# show if found in any of these lists
			for i in $(awk '{print $2}' /tmp/divstats/div-thtc); do
				i=$(echo $i | sed -e 's/\./\\./g')
				if grep -q " $i$" "${DIVERSION_DIR}/list/blockinglist"; then
					echo "blocked" >>/tmp/divstats/div-toptop
				elif grep -q " $i$" /tmp/divstats/div-blacklist; then
					echo "blacklisted" >>/tmp/divstats/div-toptop
				elif grep -q "$i$" /tmp/divstats/div-wc_blacklist; then
					echo "wc_blacklisted" >>/tmp/divstats/div-toptop
				elif grep -q "$i$" /tmp/divstats/div-whitelist; then
					echo "whitelisted" >>/tmp/divstats/div-toptop
				else
					echo >>/tmp/divstats/div-toptop
				fi
			done
			awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/divstats/div-thtc /tmp/divstats/div-toptop  >>${statsFile}
		done
		
		# preserve /tmp/divstats/div-iphostleases for next run for [Client Name*] list
		# remove unknown ip to name resolves, add empty line
		sed -i '/Name-N/d; $a\' /tmp/divstats/div-iphostleases
		# combine new and backup, sort by ip, remove dupes and empty lines
		cat /tmp/divstats/div-iphostleases "${DIVERSION_DIR}/backup/diversion_stats-iphostleases" > /tmp/divstats/div-iphostleases.tmp
		sed -i '/^\s*$/d' /tmp/divstats/div-iphostleases.tmp
		cat /tmp/divstats/div-iphostleases.tmp | sort -t . -k 4,4n -u > "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"
		
		Generate_GNUPLOT_Graphs /tmp/divstats/div-tah /www/ext/divstats-blockeddomains.png
		
		rm -rf /tmp/divstats
		
		# show file sizes
		#printf "\\n\\n File sizes:\\n$LINE" >>${statsFile}
		#file_size(){ [ "$1" -lt "1024" ] && echo $1 bytes || echo $1 | awk '{ sum=$1 ; hum[1024**3]="GB";hum[1024**2]="MB";hum[1024]="KB"; for (x=1024**3; x>=1024; x/=1024){ if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x];break } }}';}
		#if [ "$bfFs" = "on" ]; then
		#	printf "%-20s%s\\n" " blockinglist" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/blockinglist))" >>${statsFile}
		#	printf "%-20s%s\\n" " blockinglist_fs" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/blockinglist_fs))" >>${statsFile}
		#else
		#	printf "%-20s%s\\n" " blockinglist" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/blockinglist))" >>${statsFile}
		#fi
		#printf "%-20s%s\\n" " blacklist" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/blacklist))" >>${statsFile}
		#printf "%-20s%s\\n" " wildcard blacklist" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/wc_blacklist))" >>${statsFile}
		#printf "%-20s%s\\n" " whitelist" "$(file_size $(wc -c < ${DIVERSION_DIR}/list/whitelist))" >>${statsFile}
		#for file in $(find /opt/var/log/ -name "dnsmasq.log*"); do
		#	printf "%-20s%s\\n" " $(basename $file)" "$(file_size $(wc -c < $file))" >>${statsFile}
		#done
		#[ "$bfFs" = "on" ] && [ "$alternateBF" = "on" ] && printf "\\n *.log - *.log2  are primary ad-blocking log files\\n" >>${statsFile}
		#[ "$bfFs" = "on" ] && [ "$alternateBF" = "on" ] && printf " *.log3 - *.log4 are alternate ad-blocking log files\\n" >>${statsFile}
		#printf "$LINE" >>${statsFile}
		
		# stats about the stats
		#endCount=$(date +%s)
		#printf "\\n Stats compiling times, in seconds:\\n$LINE" >>${statsFile}
		#printf "%-37s%s\\n" " Ad-Blocking stats:" "$(($startCountwsTopHosts-$startCount))" >>${statsFile}
		#printf "%-37s%s\\n" " The top $wsTopHosts requested domains:" "$(($startCountTopAdHosts-$startCountwsTopHosts))" >>${statsFile}
		#printf "%-37s%s\\n" " The top $wsTopHosts blocked ad domains:" "$(($startCountNoisyClients-$startCountTopAdHosts))" >>${statsFile}
		#printf "%-37s%s\\n" " The top $wsTopClients noisiest name clients:" "$(($startCountwsTopHostsClients-$startCountNoisyClients))" >>${statsFile}
		#printf "%-37s%s\\n" " Top $wsTopHosts domains for top $wsTopClients clients:" "$(($endCount-$startCountwsTopHostsClients))" >>${statsFile}
		#printf "\\n%-37s%s\\n$LINE" " Total time to compile stats:" "$(($endCount-$startCount))" >>${statsFile}
		
		printf "$LINE\\n End of stats report\\n\\n$LINE\\n" >>${statsFile}
		WriteStats_ToJS "/tmp/stats.txt" "/www/ext/divstats.js"
		rm -f $statsFile
		Print_Output "true" "Diversion statistic generation completed successfully!" "$PASS"
	else
		Print_Output "true" "Diversion configuration not found, exiting!" "$ERR"
	fi
}

# shellcheck disable=SC2016
Generate_GNUPLOT_Graphs(){
	{ echo 'set terminal png nocrop enhanced large size 800,600 background rgb "#475A5F"'
echo 'set output "'"$2"'"'
echo 'set boxwidth 0.5'
echo 'set style fill solid 1.0 border -1'
echo 'unset grid'
echo 'set ytics 100 nomirror'
echo 'set ylabel "Number of blocks"'
echo 'set yrange [0:*]'
echo 'set xtics rotate'
echo 'set border lc rgb "white"'
echo 'set xtics textcolor rgb "white"'
echo 'set ytics textcolor rgb "white"'
echo 'set xlabel "X" textcolor rgb "white"'
echo 'set ylabel "Y" textcolor rgb "white"'
echo 'plot "'"$1"'" using 0:1:xtic(2) notitle with boxes lc rgb "white" , "'"$1"'" using 0:($1-25):1 notitle with labels lc rgb "black"'; } > /tmp/gnuplot.script
	gnuplot /tmp/gnuplot.script
	#cp "$1" /tmp/bak.dat
	rm -f /tmp/gnuplot.script
}

Generate_RRD_Graphs(){
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	mkdir -p "$(readlink /www/ext)"
	
	#Print_Output "false" "30 second ping test to $(ShowPingServer) starting..." "$PASS"
	WriteStats_ToJS "/tmp/stats.txt" "/www/ext/divstats.js"
	TZ=$(cat /etc/TZ)
	export TZ
	DATE=$(date "+%a %b %e %H:%M %Y")
	
	#Print_Output "false" "Test results - Ping $ping ms - Jitter - $jitter ms - Line Quality $pktloss %%" "$PASS"
	
	RDB=/jffs/scripts/divstats_rrd.rrd
	#rrdtool update $RDB N:"$ping":"$jitter":"$pktloss"
	
	COMMON="-c SHADEA#475A5F -c SHADEB#475A5F -c BACK#475A5F -c CANVAS#92A0A520 -c AXIS#92a0a520 -c FONT#ffffff -c ARROW#475A5F -n TITLE:9 -n AXIS:8 -n LEGEND:9 -w 650 -h 200"
	
	D_COMMON='--start -86400 --x-grid MINUTE:20:HOUR:2:HOUR:2:0:%H:%M'
	W_COMMON='--start -604800 --x-grid HOUR:3:DAY:1:DAY:1:0:%Y-%m-%d'
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-divstats-ping.png \
		$COMMON $D_COMMON \
		--title "Ping - $DATE" \
		--vertical-label "Milliseconds" \
		DEF:ping="$RDB":ping:LAST \
		CDEF:nping=ping,1000,/ \
		LINE1.5:ping#fc8500:"ping (ms)" \
		GPRINT:ping:MIN:"Min\: %3.3lf" \
		GPRINT:ping:MAX:"Max\: %3.3lf" \
		GPRINT:ping:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:ping:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-divstats-jitter.png \
		$COMMON $D_COMMON \
		--title "Jitter - $DATE" \
		--vertical-label "Milliseconds" \
		DEF:jitter="$RDB":jitter:LAST \
		CDEF:njitter=jitter,1000,/ \
		LINE1.5:jitter#c4fd3d:"jitter (ms)" \
		GPRINT:jitter:MIN:"Min\: %3.3lf" \
		GPRINT:jitter:MAX:"Max\: %3.3lf" \
		GPRINT:jitter:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:jitter:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-divstats-pktloss.png \
		$COMMON $D_COMMON \
		--title "Line Quality - $DATE" \
		--vertical-label "%" \
		DEF:pktloss="$RDB":pktloss:LAST \
		CDEF:npktloss=pktloss,1000,/ \
		AREA:pktloss#778787:"line quality (%)" \
		GPRINT:pktloss:MIN:"Min\: %3.3lf" \
		GPRINT:pktloss:MAX:"Max\: %3.3lf" \
		GPRINT:pktloss:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:pktloss:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-week-divstats-ping.png \
		$COMMON $W_COMMON \
		--title "Ping - $DATE" \
		--vertical-label "Milliseconds" \
		DEF:ping="$RDB":ping:LAST \
		CDEF:nping=ping,1000,/ \
		LINE1.5:nping#fc8500:"ping (ms)" \
		GPRINT:ping:MIN:"Min\: %3.3lf" \
		GPRINT:ping:MAX:"Max\: %3.3lf" \
		GPRINT:ping:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:ping:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-week-divstats-jitter.png \
		$COMMON $W_COMMON \
		--title "Jitter - $DATE" \
		--vertical-label "Milliseconds" \
		DEF:jitter="$RDB":jitter:LAST \
		CDEF:njitter=jitter,1000,/ \
		LINE1.5:njitter#c4fd3d:"ping (ms)" \
		GPRINT:jitter:MIN:"Min\: %3.3lf" \
		GPRINT:jitter:MAX:"Max\: %3.3lf" \
		GPRINT:jitter:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:jitter:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/nstats-week-divstats-pktloss.png \
		$COMMON $W_COMMON --alt-autoscale-max \
		--title "Line Quality - $DATE" \
		--vertical-label "%" \
		DEF:pktloss="$RDB":pktloss:LAST \
		CDEF:npktloss=pktloss,1000,/ \
		AREA:pktloss#778787:"line quality (ms)" \
		GPRINT:pktloss:MIN:"Min\: %3.3lf" \
		GPRINT:pktloss:MAX:"Max\: %3.3lf" \
		GPRINT:pktloss:AVERAGE:"Avg\: %3.3lf" \
		GPRINT:pktloss:LAST:"Curr\: %3.3lf\n" >/dev/null 2>&1
		
	Clear_Lock
}

Shortcut_script(){
	case $1 in
		create)
			if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]; then
				ln -s /jffs/scripts/"$SCRIPT_NAME" /opt/bin
				chmod 0755 /opt/bin/"$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f /opt/bin/"$SCRIPT_NAME"
			fi
		;;
	esac
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r "key"
		case "$key" in
			*)
				break
			;;
		esac
	done
	return 0
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##       _  _          _____  _          _          ##\\e[0m\\n"
	printf "\\e[1m##      | |(_)        / ____|| |        | |         ##\\e[0m\\n"
	printf "\\e[1m##    __| | _ __   __| (___  | |_  __ _ | |_  ___   ##\\e[0m\\n"
	printf "\\e[1m##   / _  || |\ \ / / \___ \ | __|/ _  || __|/ __|  ##\\e[0m\\n"
	printf "\\e[1m##  | (_| || | \ V /  ____) || |_| (_| || |_ \__ \  ##\\e[0m\\n"
	printf "\\e[1m##   \__,_||_|  \_/  |_____/  \__|\__,_| \__||___/  ##\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##              %s on %-9s                 ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##       https://github.com/jackyaz/divStats        ##\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    Generate Diversion Statistics now\\n\\n"
	#printf "2.    Set preferred ping server\\n      Currently: %s\\n\\n" ""
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_GenerateStats
				fi
				PressEnter
				break
			;;
			u)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_ForceUpdate
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
					read -r "confirm"
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	ScriptHeader
	MainMenu
}

Check_Requirements(){
	CHECKSFAILED="false"
	
	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output "true" "Custom JFFS Scripts enabled" "$WARN"
	fi
	
	if [ ! -f "/opt/bin/opkg" ]; then
		Print_Output "true" "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ ! -f "/opt/bin/diversion" ]; then
		Print_Output "true" "Diversion not installed!" "$ERR"
		CHECKSFAILED="true"
	else
		# shellcheck disable=SC1091
		. /opt/share/diversion/.conf/diversion.conf
		#shellcheck disable=SC2154
		if [ "$weeklyStats" != "on" ]; then
			Print_Output "true" "Diversion weekly stats not enabled!" "$ERR"
			Print_Output "true" "Open Diversion, use option c and then enable using 2,1,1" ""
			CHECKSFAILED="true"
		fi
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output "true" "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz"
	sleep 1
	
	Print_Output "true" "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output "true" "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		exit 1
	fi
	
	opkg update
	opkg install rrdtool
	opkg install gnuplot
	
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Mount_WebUI
	Modify_WebUI_File
	RRD_Initialise
	Menu_GenerateStats
	
	Clear_Lock
}

Menu_Startup(){
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Mount_WebUI
	Modify_WebUI_File
	RRD_Initialise
	Clear_Lock
}

Menu_GenerateStats(){
	Generate_Stats_Diversion
	Clear_Lock
}

Menu_Update(){
	Update_Version
	Clear_Lock
}

Menu_ForceUpdate(){
	Update_Version force
	Clear_Lock
}

Menu_Uninstall(){
	Print_Output "true" "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	while true; do
		printf "\\n\\e[1mDo you want to delete %s stats? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
		read -r "confirm"
		case "$confirm" in
			y|Y)
				rm -f "/jffs/scripts/divstats_rrd.rrd" 2>/dev/null
				break
			;;
			*)
				break
			;;
		esac
	done
	Shortcut_script delete
	umount /www/Advanced_MultiSubnet_Content.asp 2>/dev/null
	sed -i '/{url: "Advanced_MultiSubnet_Content.asp", tabName: "Diversion Statistics"}/d' "/jffs/scripts/custom_menuTree.js"
	umount /www/require/modules/menuTree.js 2>/dev/null
	
	if [ ! -f "/jffs/scripts/ntpmerlin" ] && [ ! -f "/jffs/scripts/spdmerlin" ] && [ ! -f "/jffs/scripts/connmon" ]; then
		opkg remove --autoremove rrdtool
		rm -f "/jffs/scripts/custom_menuTree.js" 2>/dev/null
	else
		mount -o bind "/jffs/scripts/custom_menuTree.js" "/www/require/modules/menuTree.js"
	fi
	rm -f "/jffs/scripts/divstats_www.asp" 2>/dev/null
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

if [ -z "$1" ]; then
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		Check_Lock
		Menu_Startup
		exit 0
	;;
	generate)
		if [ -z "$2" ] && [ -z "$3" ]; then
			Check_Lock
			Menu_GenerateStats
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Check_Lock
			Menu_GenerateStats
		fi
		exit 0
	;;
	update)
		Check_Lock
		Menu_Update
		exit 0
	;;
	forceupdate)
		Check_Lock
		Menu_ForceUpdate
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	*)
		Check_Lock
		echo "Command not recognised, please try again"
		Clear_Lock
		exit 1
	;;
esac
