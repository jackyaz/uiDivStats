#!/bin/sh

#################################################################
##                                                             ##
##          _  _____   _          _____  _          _          ##
##         (_)|  __ \ (_)        / ____|| |        | |         ##
##   _   _  _ | |  | | _ __   __| (___  | |_  __ _ | |_  ___   ##
##  | | | || || |  | || |\ \ / / \___ \ | __|/ _  || __|/ __|  ##
##  | |_| || || |__| || | \ V /  ____) || |_| (_| || |_ \__ \  ##
##   \__,_||_||_____/ |_|  \_/  |_____/  \__|\__,_| \__||___/  ##
##                                                             ##
##            https://github.com/jackyaz/uiDivStats            ##
##                                                             ##
#################################################################

### Start of script variables ###
readonly SCRIPT_NAME="uiDivStats"
readonly SCRIPT_VERSION="v2.0.0"
readonly SCRIPT_BRANCH="develop"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/""$SCRIPT_NAME""/""$SCRIPT_BRANCH"
readonly OLD_SCRIPT_DIR="/jffs/scripts/$SCRIPT_NAME.d"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly OLD_SHARED_DIR="/jffs/scripts/shared-jy"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly DNS_DB="/opt/share/uiDivStats.d/dnsqueries.db"
readonly CSV_OUTPUT_DIR="/opt/share/uiDivStats.d/csv"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
[ -f /opt/bin/sqlite3 ] && SQLITE3_PATH=/opt/bin/sqlite3 || SQLITE3_PATH=/usr/sbin/sqlite3
readonly DIVERSION_DIR="/opt/share/diversion"
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

Firmware_Version_Check(){
	if [ "$1" = "install" ]; then
		if [ "$(uname -o)" = "ASUSWRT-Merlin" ] && [ "$(nvram get buildno | cut -f1 -d'.')" -ge "384" ]; then
			return 0
		else
			return 1
		fi
	elif [ "$1" = "webui" ]; then
		if nvram get rc_support | grep -qF "am_addons"; then
			return 0
		else
			return 1
		fi
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]; then
			Print_Output "true" "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
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
		
		Update_File "uidivstats_www.asp"
		Update_File "shared-jy.tar.gz"
		Update_File "taildns.tar.gz"
		
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
			Update_File "uidivstats_www.asp"
			Update_File "shared-jy.tar.gz"
			Update_File "taildns.tar.gz"
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			exit 0
		;;
	esac
}
############################################################################

Update_File(){
	if [ "$1" = "uidivstats_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			if [ -f "$SCRIPT_DIR/$1" ]; then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyPage~d" /tmp/menuTree.js
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage" 2>/dev/null
			fi
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "taildns.tar.gz" ]; then
		if [ ! -f "$SCRIPT_DIR/$1.md5" ]; then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Download_File "$SCRIPT_REPO/$1.md5" "$SCRIPT_DIR/$1.md5"
			tar -xzf "$SCRIPT_DIR/$1" -C "$SCRIPT_DIR"
			if [ -f /opt/etc/init.d/S90taildns ]; then
				/opt/etc/init.d/S90taildns stop
			fi
			mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
			/opt/etc/init.d/S90taildns start
			rm -f "$SCRIPT_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SCRIPT_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Download_File "$SCRIPT_REPO/$1.md5" "$SCRIPT_DIR/$1.md5"
				tar -xzf "$SCRIPT_DIR/$1" -C "$SCRIPT_DIR"
				if [ -f /opt/etc/init.d/S90taildns ]; then
					/opt/etc/init.d/S90taildns stop
				fi
				mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
				/opt/etc/init.d/S90taildns start
				rm -f "$SCRIPT_DIR/$1"
				Print_Output "true" "New version of $1 downloaded" "$PASS"
			fi
		fi
	elif [ "$1" = "shared-jy.tar.gz" ]; then
		if [ ! -f "$SHARED_DIR/$1.md5" ]; then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output "true" "New version of $1 downloaded" "$PASS"
			fi
		fi
	else
		return 1
	fi
}

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
	
	if [ ! -d "$CSV_OUTPUT_DIR" ]; then
		mkdir -p "$CSV_OUTPUT_DIR"
	fi
}

Create_Symlinks(){
	rm -f "$SCRIPT_WEB_DIR/"* 2>/dev/null
	
	ln -s "$SCRIPT_DIR/uidivstats.js" "$SCRIPT_WEB_DIR/uidivstats.js" 2>/dev/null
	ln -s "$SCRIPT_DIR/SQLData.js" "$SCRIPT_WEB_DIR/SQLData.js" 2>/dev/null
	ln -s "$SCRIPT_DIR/uidivstatsclients.js" "$SCRIPT_WEB_DIR/uidivstatsclients.js" 2>/dev/null
	
	ln -s "$SCRIPT_DIR/uidivstatstext.js" "$SCRIPT_WEB_DIR/uidivstatstext.js" 2>/dev/null
	ln -s "$SCRIPT_DIR/uidivstats.txt" "$SCRIPT_WEB_DIR/uidivstatstext.htm" 2>/dev/null
	ln -s "$SCRIPT_DIR/psstats.htm" "$SCRIPT_WEB_DIR/psstats.htm" 2>/dev/null
	
	if [ ! -d "$SCRIPT_WEB_DIR/csv" ]; then
		ln -s "$CSV_OUTPUT_DIR" "$SCRIPT_WEB_DIR/csv" 2>/dev/null
	fi
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
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
			STARTUPLINECOUNT=$(cru l | grep -cx "0 \* \* \* \* /jffs/scripts/$SCRIPT_NAME generate #uiDivStats#")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
			
			STARTUPLINECOUNTGENERATE=$(cru l | grep -c "$SCRIPT_NAME""_generate")
			STARTUPLINECOUNTTRIM=$(cru l | grep -c "$SCRIPT_NAME""_trim")
			
			if [ "$STARTUPLINECOUNTGENERATE" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_generate" "0 * * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_trim" "3 3 * * * /jffs/scripts/$SCRIPT_NAME trimdb"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -cx "0 \* \* \* \* /jffs/scripts/$SCRIPT_NAME generate #uiDivStats#")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
			
			STARTUPLINECOUNTGENERATE=$(cru l | grep -c "$SCRIPT_NAME""_generate")
			STARTUPLINECOUNTTRIM=$(cru l | grep -c "$SCRIPT_NAME""_trim")
			
			if [ "$STARTUPLINECOUNTGENERATE" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_trim"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Get_spdMerlin_UI(){
	if [ -f /www/AdaptiveQoS_ROG.asp ]; then
		echo "AdaptiveQoS_ROG.asp"
	else
		echo "AiMesh_Node_FirmwareUpgrade.asp"
	fi
}

Get_WebUI_Page () {
	for i in 1 2 3 4 5 6 7 8 9 10; do
		page="$SCRIPT_WEBPAGE_DIR/user$i.asp"
		if [ ! -f "$page" ] || [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		fi
	done
	MyPage="none"
}

Mount_WebUI(){
	if Firmware_Version_Check "webui" ; then
		Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
		if [ "$MyPage" = "none" ]; then
			Print_Output "true" "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
			exit 1
		fi
		Print_Output "true" "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
		cp -f "$SCRIPT_DIR/uidivstats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
		
		if [ ! -f "/tmp/index_style.css" ]; then
			cp -f "/www/index_style.css" "/tmp/"
		fi
		
		if ! grep -q '.menu_Addons' /tmp/index_style.css ; then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi
		
		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css
		
		if [ ! -f "/tmp/menuTree.js" ]; then
			cp -f "/www/require/modules/menuTree.js" "/tmp/"
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if ! grep -q 'menuName: "Addons"' /tmp/menuTree.js ; then
			lineinsbefore="$(( $(grep -n "exclude:" /tmp/menuTree.js | cut -f1 -d':') - 1))"
			sed -i "$lineinsbefore"'i,\n{\nmenuName: "Addons",\nindex: "menu_Addons",\ntab: [\n{url: "ext/shared-jy/redirect.htm", tabName: "Help & Support"},\n{url: "NULL", tabName: "__INHERIT__"}\n]\n}' /tmp/menuTree.js
		fi
		
		if ! grep -q "javascript:window.open('/ext/shared-jy/redirect.htm'" /tmp/menuTree.js ; then
			sed -i "s~ext/shared-jy/redirect.htm~javascript:window.open('/ext/shared-jy/redirect.htm','_blank')~" /tmp/menuTree.js
		fi
		sed -i "/url: \"javascript:window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"Diversion Stats\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	else
		Mount_WebUI_Old
		Modify_WebUI_File
	fi
}

Mount_WebUI_Old(){
	umount /www/Advanced_MultiSubnet_Content.asp 2>/dev/null
	
	mount -o bind "$SCRIPT_DIR/uidivstats_www.asp" "/www/Advanced_MultiSubnet_Content.asp"
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
		sed -i '/{url: "Advanced_Feedback.asp", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_Feedback.asp", tabName: "Uptime Monitoring"},' "$tmpfile"
		sed -i '/retArray.push("Advanced_Feedback.asp");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/spdmerlin" ]; then
		sed -i '/{url: "'"$(Get_spdMerlin_UI)"'", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "'"$(Get_spdMerlin_UI)"'", tabName: "SpeedTest"},' "$tmpfile"
		sed -i '/retArray.push("'"$(Get_spdMerlin_UI)"'");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/ntpmerlin" ]; then
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Feedback_Info.asp", tabName: "NTP Daemon"},' "$tmpfile"
	fi
	
	if [ -f /jffs/scripts/custom_menuTree.js ]; then
		mv /jffs/scripts/custom_menuTree.js "$SHARED_DIR/custom_menuTree.js"
	fi
	
	if [ ! -f "$SHARED_DIR/custom_menuTree.js" ]; then
		cp "$tmpfile" "$SHARED_DIR/custom_menuTree.js"
	fi
	
	if ! diff -q "$tmpfile" "$SHARED_DIR/custom_menuTree.js" >/dev/null 2>&1; then
		cp "$tmpfile" "$SHARED_DIR/custom_menuTree.js"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind "$SHARED_DIR/custom_menuTree.js" "/www/require/modules/menuTree.js"
	### ###
	
	### start_apply.htm ###
	umount /www/start_apply.htm 2>/dev/null
	tmpfile=/tmp/start_apply.htm
	cp "/www/start_apply.htm" "$tmpfile"
	
	if [ -f /jffs/scripts/spdmerlin ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Advanced_Feedback.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	if [ -f /jffs/scripts/ntpmerlin ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Feedback_Info.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	if [ -f /jffs/scripts/connmon ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("'"$(Get_spdMerlin_UI)"'") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Advanced_MultiSubnet_Content.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	
	if [ -f /jffs/scripts/custom_start_apply.htm ]; then
		mv /jffs/scripts/custom_start_apply.htm "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	if [ ! -f "$SHARED_DIR/custom_start_apply.htm" ]; then
		cp "/www/start_apply.htm" "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	if ! diff -q "$tmpfile" "$SHARED_DIR/custom_start_apply.htm" >/dev/null 2>&1; then
		cp "$tmpfile" "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind "$SHARED_DIR/custom_start_apply.htm" /www/start_apply.htm
	### ###
}

WriteOptions_ToJS(){
	{
	echo "var clients;"
	echo "clients = [];"; } > "$2"
	contents=""
	contents="$contents""clients.unshift("
	while IFS='' read -r line || [ -n "$line" ]; do
		contents="$contents""'""$(echo "$line" | awk '{$1=$1};1' | awk 'BEGIN{FS="  *"}{ print $2" ("$1")"}')""'"","
	done < "$1"
	contents=$(echo "$contents" | sed 's/.$//')
	contents="$contents"");"
	echo "$contents" >> "$2"
	
	{
	echo "function SetClients(){"
	echo "selectField = document.getElementById(\"clientdomains\");"
	echo "selectField.options.length = 0;"
	echo "for (i=0; i<clients.length; i++)"
	echo "{"
	echo "selectField.options[selectField.length] = new Option(clients[i], i);"
	echo "}"
	echo "}" ; } >> "$2"
}

WriteStats_ToJS(){
	echo "function $3(){" >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="$html""$line""\\r\\n"
	done < "$1"
	html="$html"'"'
	printf "%s\\r\\n}\\r\\n" "$html" >> "$2"
}

WriteData_ToJS(){
	inputfile="$1"
	outputfile="$2"
	shift;shift
	i="0"
	for var in "$@"; do
		i=$((i+1))
		{ echo "var $var;"
			echo "$var = [];"
			echo "${var}.unshift('$(awk -v i=$i '{printf t $i} {t=","}' "$inputfile" | sed "s~,~\\',\\'~g")');"
			echo; } >> "$outputfile"
	done
}

WritePlainData_ToJS(){
	outputfile="$1"
	shift
	for var in "$@"; do
		varname="$(echo $var | cut -f1 -d',')"
		varvalue="$(echo $var | cut -f2 -d',')"
		echo "var $varname = $varvalue;" >> "$outputfile"
	done
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
	### Code for this function courtesy of https://github.com/decoderman - credit to @thelonelycoder ###
	
	# set environment PATH to system binaries
	export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH
	
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Create_Dirs
	Create_Symlinks
	
	Print_Output "true" "Starting Diversion statistic generation..." "$PASS"
	
	if [ -f "${DIVERSION_DIR}/.conf/diversion.conf" ] && [ -s /opt/var/log/dnsmasq.log ]; then
		diversion count_ads
		. "${DIVERSION_DIR}/.conf/diversion.conf"
		
		[ -z "$wsTopHosts" ] && wsTopHosts=15
		[ "$wsTopHosts" -gt 30 ] && wsTopHosts=30
		[ -z "$wsTopClients" ] && wsTopClients=10
		[ "$wsTopClients" -gt 30 ] && wsTopClients=30
		
		wsFilterLN=on
		
		lanIPaddr=$(nvram get lan_ipaddr | sed 's/\.[0-9]*$/./')
		human_number(){	sed -re " :restart ; s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/ ; t restart ";}
		LINE=" --------------------------------------------------------\\n"
		statsFile="/tmp/uidivstats.txt"
		clientsFile="/tmp/uidivclients.txt"
		
		# start of the output for the stats
		printf "\\n Diversion Statistics $(date +"%c")\\n$LINE" >${statsFile}
		[ "$thisM_VERSION" ] && THIS_VERSION="${thisVERSION}.$thisM_VERSION" || THIS_VERSION=$thisVERSION
		printf " Compiled by $NAME $THIS_VERSION\\n" >>${statsFile}
		printf "\\n Ad-Blocking stats:" >>${statsFile}
		printf "\\n$LINE" >>${statsFile}
		
		if /opt/bin/grep -qm1 'devEnv' /opt/bin/diversion; then
			BD="$(($(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -w)-$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -l)))"
			BD="$(($BD+$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blacklist" "${DIVERSION_DIR}/list/wc_blacklist" | wc -l)))"
			BL="$(($(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -w)-$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -l)))"
			[ "$bfFs" = "on" ] && BLfs="$(($(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist_fs" | wc -w)-$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist_fs" | wc -l)))"
		else
			BD=$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" "${DIVERSION_DIR}/list/blacklist" "${DIVERSION_DIR}/list/wc_blacklist" | wc -l)
			BL=$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist" | wc -l)
			[ "$bfFs" = "on" ] && BLfs=$(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blockinglist_fs" | wc -l)
		fi
		
		printf "%-13s%s\\n" " $(echo $BD | human_number)" "domains in total are blocked" >>${statsFile}
		
		if [ "$bfFs" = "on" ]; then
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
		
		printf "%-13s%s\\n" " $(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blacklist" | wc -l)" "blocked by blacklist" >>${statsFile}
		printf "%-13s%s\\n" " $(/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/wc_blacklist" | wc -l)" "blocked by wildcard blacklist" >>${statsFile}
		printf "\\n" >>${statsFile}
		
		if [ "$bfFs" = "on" ] && [ "$alternateBF" = "on" ]; then
			if [ "$excludeIP" = "on" ]; then
				sed -ri "/$(echo $excludeIPlist | sed 's/ /|/g')/d" /opt/var/log/dnsmasq.log*
				kill -USR2 "$(pidof dnsmasq)"
			fi
			dnsmasqLog="/opt/var/log/dnsmasq.log*"
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
			printf "%-13s%s\\n" " $(echo $(($adsNew+$adsNewAlt)) | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
		else
			if [ "$excludeIP" = "on" ]; then
				sed -ri "/$(echo $excludeIPlist | sed 's/ /|/g')/d" /opt/var/log/dnsmasq.log /opt/var/log/dnsmasq.log1 /opt/var/log/dnsmasq.log2
				kill -USR2 "$(pidof dnsmasq)"
			fi
			dnsmasqLog="/opt/var/log/dnsmasq.log /opt/var/log/dnsmasq.log1 /opt/var/log/dnsmasq.log2"
			printf "%-13s%s\\n" " $(echo $adsBlocked | human_number)" "ads in total blocked" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsWeek | human_number)" "ads this week, since last $bfUpdateDay" >>${statsFile}
			printf "%-13s%s\\n" " $(echo $adsNew | human_number)" "new ads, since $adsPrevCount" >>${statsFile}
		fi
		
		[ -d /tmp/uidivstats ] && rm -rf /tmp/uidivstats
		mkdir /tmp/uidivstats
		
		# make copies of files to count on to /tmp
		/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/whitelist" | awk '{print $1}' > /tmp/uidivstats/div-whitelist
		/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/blacklist" | awk '{print " "$2}' > /tmp/uidivstats/div-blacklist
		/opt/bin/grep "^[^#]" "${DIVERSION_DIR}/list/wc_blacklist" | awk '{print $1}' > /tmp/uidivstats/div-wc_blacklist
		
		# create local client names lists for name resolution and, if wsFilterLN enabled, for more accurate stats results
		# from hosts.dnsmasq
		[ -s /etc/hosts.dnsmasq ] && awk '{print $1}' /etc/hosts.dnsmasq >>/tmp/uidivstats/div-allips.tmp
		# from dnsmasq.leases
		[ -s /var/lib/misc/dnsmasq.leases ] && awk '{print $3}' /var/lib/misc/dnsmasq.leases >>/tmp/uidivstats/div-allips.tmp
		# don't run the clients specific code if none are found
		if [ -s /tmp/uidivstats/div-allips.tmp ]; then
			# remove duplicates, sort by last octet
			cat /tmp/uidivstats/div-allips.tmp | sort -t . -k 4,4n -u > /tmp/uidivstats/div-allips
			foundClients=1
		else
			wsFilterLN=off
		fi
		
		# add reverse router IP
		echo "$lanIPaddr" | awk -F. '{print "."$3"." $2"."$1}' >>/tmp/uidivstats/div-ipleases
		
		# create local client files if any were found
		if [ "$foundClients" ]; then
			for i in $(awk '{print $1}' /tmp/uidivstats/div-allips); do
				if [ -s /etc/hosts.dnsmasq ] && /opt/bin/grep -wq $i /etc/hosts.dnsmasq; then
					echo "$(awk -v var="$i" -F' ' '$1 == var{print $2}' /etc/hosts.dnsmasq)" >>/tmp/uidivstats/div-hostleases
					echo "$(awk -v var="$i" -F' ' '$1 == var{print $1, $2}' /etc/hosts.dnsmasq)" >>/tmp/uidivstats/div-iphostleases
					echo "$(awk -v var="$i" -F' ' '$1 == var{print $1}' /etc/hosts.dnsmasq)" >>/tmp/uidivstats/div-ipleases
					# add the reverse client IP addresses
					echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/uidivstats/div-ipleases
				elif /opt/bin/grep -Fq "$i * " /var/lib/misc/dnsmasq.leases; then
					echo "$i Name-N/A" >>/tmp/uidivstats/div-iphostleases
					echo "$i" >>/tmp/uidivstats/div-ipleases
					# add the reverse client IP addresses
					echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/uidivstats/div-ipleases
				else
					echo "$(awk -v var="$i" -F' ' '$3 == var{print $4}' /var/lib/misc/dnsmasq.leases)" >>/tmp/uidivstats/div-hostleases
					echo "$(awk -v var="$i" -F' ' '$3 == var{print $3, $4}' /var/lib/misc/dnsmasq.leases)" >>/tmp/uidivstats/div-iphostleases
					echo "$(awk -v var="$i" -F' ' '$3 == var{print $3}' /var/lib/misc/dnsmasq.leases)" >>/tmp/uidivstats/div-ipleases
					# add the reverse client IP addresses
					echo "$i" | awk -F. '{print $4"."$3"." $2"."$1}' >>/tmp/uidivstats/div-ipleases
				fi
			done
		fi
		
		# overwrite with empty files if filtering is off
		[ "$wsFilterLN" = "off" ] && >/tmp/uidivstats/div-hostleases >/tmp/uidivstats/div-ipleases
		
		# write empty backup file if not found for [Client Name*] list
		[ ! -f "${DIVERSION_DIR}/backup/diversion_stats-iphostleases" ] && > "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"
		
		# begin of stats computing
		printf "\\n The top $wsTopHosts requested domains were:\\n$LINE" >>${statsFile}
		awk '/query\[AAAA]|query\[A]/ {print $(NF-2)}' $dnsmasqLog |
		awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
		
		/opt/bin/grep -viF -f /tmp/uidivstats/div-hostleases | /opt/bin/grep -viF -f /tmp/uidivstats/div-ipleases >>/tmp/uidivstats/div-th-all
		awk '{$1=$1};1' /tmp/uidivstats/div-th-all  | cut -d ' ' -f1 >>/tmp/uidivstats/div-th-all-count
		reqdomains=0
		while IFS='' read -r line || [ -n "$line" ]; do
			reqdomains=$((reqdomains+line))
		done < /tmp/uidivstats/div-th-all-count
		
		head -$wsTopHosts /tmp/uidivstats/div-th-all >>/tmp/uidivstats/div-th
		# show if found in any of these lists
		for i in $(awk '{print $2}' /tmp/uidivstats/div-th); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if /opt/bin/grep -q " $i$\| $i " "${DIVERSION_DIR}/list/blockinglist"; then
				echo "blocked" >>/tmp/uidivstats/div-bwl
			elif /opt/bin/grep -q " $i$" /tmp/uidivstats/div-blacklist; then
				echo "blacklisted" >>/tmp/uidivstats/div-bwl
			elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-wc_blacklist; then
				echo "wc_blacklisted" >>/tmp/uidivstats/div-bwl
			elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-whitelist; then
				echo "whitelisted" >>/tmp/uidivstats/div-bwl
			else
				echo >>/tmp/uidivstats/div-bwl
			fi
		done
		
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div-th /tmp/uidivstats/div-bwl >>${statsFile}
		
		printf "\\n The top $wsTopHosts blocked ad domains were:\\n$LINE" >>${statsFile}
		
		case "$EDITION" in
			Lite)		awk '/is '$blockingIP'|is 0.0.0.0/ {print $(NF-2)}' $dnsmasqLog |
						awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
						head -$wsTopHosts >>/tmp/uidivstats/div-tah
						;;
			Standard)	if [ "$LANblockingIP" ]; then
							awk '/is '$lanBIP'|is '$psIP'|is 0.0.0.0/ {print $(NF-2)}' $dnsmasqLog |
							awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
							head -$wsTopHosts >>/tmp/uidivstats/div-tah
						else
							awk '/is '$psIP'|is 0.0.0.0/ {print $(NF-2)}' $dnsmasqLog |
							awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
							head -$wsTopHosts >>/tmp/uidivstats/div-tah
						fi
						;;
		esac
		
		# show if found in any of these lists
		for i in $(awk '{print $2}' /tmp/uidivstats/div-tah); do
			i=$(echo $i | sed -e 's/\./\\./g')
			if /opt/bin/grep -q " $i$\| $i " "${DIVERSION_DIR}/list/blockinglist"; then
				echo "blocked" >>/tmp/uidivstats/div-bw
			elif /opt/bin/grep -q " $i$" /tmp/uidivstats/div-blacklist; then
				echo "blacklisted" >>/tmp/uidivstats/div-bw
			elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-wc_blacklist; then
				echo "wc_blacklisted" >>/tmp/uidivstats/div-bw
			fi
		done
		[ ! -f /tmp/uidivstats/div-bw ] && >/tmp/uidivstats/div-bw
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div-tah /tmp/uidivstats/div-bw >>${statsFile}
		
		# compile client stats if any were found
		if [ "$foundClients" ]; then
			AL=1 # prevent divide by zero
			printf "\\n The top $wsTopClients noisiest name clients:\\n$LINE\\n" >>${statsFile}
			printf " count for IP, client name: count for domain - percentage\\n$LINE" >>${statsFile}
			awk -F " " '/from '$lanIPaddr'/ {print $NF}' $dnsmasqLog |
			awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-15s""%s %s",a[o],o}' | sort -nr | head -$wsTopClients >/tmp/uidivstats/div1
			for i in $(awk '{print $2}' /tmp/uidivstats/div1); do
				i=$(echo $i | sed -e 's/\./\\./g')
				/opt/bin/grep -a " query\[A.* from $i$" $dnsmasqLog | awk '{print $(NF-2)}' |
				awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
				/opt/bin/grep -viF -f /tmp/uidivstats/div-hostleases | /opt/bin/grep -viF -f /tmp/uidivstats/div-ipleases | head -1 >>/tmp/uidivstats/div2
				CH="$(awk 'END{print $1}' /tmp/uidivstats/div2)"
				TH="$(awk -v AL="$AL" 'FNR==AL{print $1}' /tmp/uidivstats/div1)"
				AL=$(( AL + 1))
				awk -v CH="$CH" -v TH="$TH" 'BEGIN{printf "%-5.2f%s\n", ((CH * 100)/TH), "%"}' >>/tmp/uidivstats/div3
			done
			
			# add client names
			for i in $(awk '{print $2}' /tmp/uidivstats/div1); do
				i=$(echo $i | sed -e 's/\./\\./g')
				if /opt/bin/grep -wq $i /tmp/uidivstats/div-iphostleases; then
					printf "%-26s\\n" "$(awk -v var="$i" -F' ' '$1 == var{print $2}' /tmp/uidivstats/div-iphostleases):" >>/tmp/uidivstats/div5
				elif /opt/bin/grep -wq $i "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"; then
					if [ "$(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)" != "*" ]; then
						printf "%-26s\\n" "$(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)*:" >>/tmp/uidivstats/div5
					else
						printf "%-26s\\n" "Name-N/A*:" >>/tmp/uidivstats/div5
					fi
				else
					printf "%-26s\\n" "Name-N/A:" >>/tmp/uidivstats/div5
				fi
			done
			
			# show if found in any of these lists
			for i in $(awk '{print $2}' /tmp/uidivstats/div2); do
				i=$(echo $i | sed -e 's/\./\\./g')
				if /opt/bin/grep -q " $i$\| $i " "${DIVERSION_DIR}/list/blockinglist"; then
					echo "blocked" >>/tmp/uidivstats/div-noisy
				elif /opt/bin/grep -q " $i$" /tmp/uidivstats/div-blacklist; then
					echo "blacklisted" >>/tmp/uidivstats/div-noisy
				elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-wc_blacklist; then
					echo "wc_blacklisted" >>/tmp/uidivstats/div-noisy
				elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-whitelist; then
					echo "whitelisted" >>/tmp/uidivstats/div-noisy
				else
					echo >>/tmp/uidivstats/div-noisy
				fi
			done
			
			# assemble the tables and print
			awk 'NR==FNR{a[FNR]=$0 "-";next} {print a[FNR],$0}' /tmp/uidivstats/div2 /tmp/uidivstats/div3 >/tmp/uidivstats/div4
			awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div4 /tmp/uidivstats/div-noisy >/tmp/uidivstats/div7
			awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div1 /tmp/uidivstats/div5 >/tmp/uidivstats/div6
			awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div6 /tmp/uidivstats/div7 >>${statsFile}
			
			printf "\\n\\n Top $wsTopHosts domains for top $wsTopClients clients:\\n$LINE" >>${statsFile}
			printf "%s\\n" "*    All Clients" >> "$clientsFile"
			COUNTER=1
			for i in $(awk '{print $2}' /tmp/uidivstats/div1); do
				if /opt/bin/grep -wq $i /tmp/uidivstats/div-iphostleases; then
					printf "\\n $i, $(awk -v var="$i" -F' ' '$1 == var{print $2}' /tmp/uidivstats/div-iphostleases):\\n$LINE" >>${statsFile}
				elif /opt/bin/grep -wq $i "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"; then
					if [ "$(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)" != "*" ]; then
						printf "\\n $i, $(awk -v var="$i" -F' ' '$1 == var{print $2}' ${DIVERSION_DIR}/backup/diversion_stats-iphostleases)*:\\n$LINE" >>${statsFile}
					else
						printf "\\n $i, Name-N/A*:\\n$LINE" >>${statsFile}
					fi
				else
					printf "\\n $i, Name-N/A:\\n$LINE" >>${statsFile}
				fi
				
				clientname="$(tail -n 2 "$statsFile" | head -n 1 | sed 's/,/    /g' | sed 's/://g')"
				printf "%s\\n" "$clientname" >> "$clientsFile"
				
				# remove files for next client compiling run
				rm -f /tmp/uidivstats/div-thtc /tmp/uidivstats/div-toptop /tmp/uidivstats/div-thtc-toptop
				/opt/bin/grep -aw $i$ $dnsmasqLog | awk '{print $(NF-2)}' |
				awk '{for(i=1;i<=NF;i++)a[$i]++}END{for(o in a) printf "\n %-6s %-40s""%s %s",a[o],o}' | sort -nr |
				/opt/bin/grep -viF -f /tmp/uidivstats/div-hostleases | /opt/bin/grep -viF -f /tmp/uidivstats/div-ipleases | head -$wsTopHosts >>/tmp/uidivstats/div-thtc
				# show if found in any of these lists
				for i in $(awk '{print $2}' /tmp/uidivstats/div-thtc); do
					i=$(echo $i | sed -e 's/\./\\./g')
					if /opt/bin/grep -q " $i$\| $i " "${DIVERSION_DIR}/list/blockinglist"; then
						echo "blocked" >>/tmp/uidivstats/div-toptop
					elif /opt/bin/grep -q " $i$" /tmp/uidivstats/div-blacklist; then
						echo "blacklisted" >>/tmp/uidivstats/div-toptop
					elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-wc_blacklist; then
						echo "wc_blacklisted" >>/tmp/uidivstats/div-toptop
					elif /opt/bin/grep -q "$i$" /tmp/uidivstats/div-whitelist; then
						echo "whitelisted" >>/tmp/uidivstats/div-toptop
					else
						echo >>/tmp/uidivstats/div-toptop
					fi
				done
				
				awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div-thtc /tmp/uidivstats/div-toptop  >>${statsFile}
				awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div-thtc /tmp/uidivstats/div-toptop  >>/tmp/uidivstats/div-thtc-toptop
				WriteData_ToJS /tmp/uidivstats/div-thtc-toptop "/tmp/uidivstats.js" "barDataDomains$COUNTER" "barLabelsDomains$COUNTER" "barLabelsDomainsType$COUNTER"
				COUNTER=$((COUNTER + 1))
			done
			
			# preserve /tmp/uidivstats/div-iphostleases for next run for [Client Name*] list
			# remove unknown ip to name resolves, add empty line
			sed -i '/Name-N/d; $a\' /tmp/uidivstats/div-iphostleases
			# combine new and backup, sort by ip, remove dupes and empty lines
			cat /tmp/uidivstats/div-iphostleases "${DIVERSION_DIR}/backup/diversion_stats-iphostleases" > /tmp/uidivstats/div-iphostleases.tmp
			sed -i '/^\s*$/d' /tmp/uidivstats/div-iphostleases.tmp
			cat /tmp/uidivstats/div-iphostleases.tmp | sort -t . -k 4,4n -u > "${DIVERSION_DIR}/backup/diversion_stats-iphostleases"
			printf "\\n" >>${statsFile}
		else
			printf "%s\\n" "*    All Clients" >> "$clientsFile"
			printf "\\n No stats for connected clients were compiled.\\n This router provided no client list.\\n" >>${statsFile}
		fi
		
		printf "$LINE End of stats report\\n" >>${statsFile}
		
		WriteData_ToJS /tmp/uidivstats/div-tah "/tmp/uidivstats.js" "DataBlockedAds" "LabelsBlockedAds"
		awk 'NR==FNR{a[FNR]=$0 "";next} {print a[FNR],$0}' /tmp/uidivstats/div-th /tmp/uidivstats/div-bwl >>/tmp/uidivstats/div-th-bwl
		WriteData_ToJS /tmp/uidivstats/div-th-bwl "/tmp/uidivstats.js" "barDataDomains0" "barLabelsDomains0" "barLabelsDomainsType0"
		WriteOptions_ToJS "$clientsFile" "/tmp/uidivstatsclients.js"
		mv "/tmp/uidivstats.js" "$SCRIPT_DIR/uidivstats.js"
		mv "/tmp/uidivstatsclients.js" "$SCRIPT_DIR/uidivstatsclients.js"
		
		printf "$(head -n 2 "$statsFile" | tail -n 1 | sed 's/^ //' | sed 's/Stats/Stats generated on/')" > /tmp/uidivtitle.txt
		WriteStats_ToJS "/tmp/uidivtitle.txt" "/tmp/uidivstatstext.js" "SetDivStatsTitle" "statstitle"
		
		echo "Top $wsTopHosts blocked domains (click to expand/collapse)" > /tmp/uidivtitle2.txt
		echo "Top $wsTopHosts requested domains (click to expand/collapse)" > /tmp/uidivtitle3.txt
		
		WriteStats_ToJS "/tmp/uidivtitle2.txt" "/tmp/uidivstatstext.js" "SetTopBlockedTitle" "topblocked"
		WriteStats_ToJS "/tmp/uidivtitle3.txt" "/tmp/uidivstatstext.js" "SetTopRequestedTitle" "toprequested"
		
		mv "/tmp/uidivstatstext.js" "$SCRIPT_DIR/uidivstatstext.js"
		cp "$statsFile" "$SCRIPT_DIR/uidivstats.txt"
		
		psstatsFile="$SCRIPT_DIR/psstats.htm"
		
		if [ "$EDITION" = "Standard" ]; then
			if [ "$LANblockingIP" ] && [ "$LANblockingIP" = on ]; then
				/usr/sbin/curl -fs --retry 3 --connect-timeout 15 "http://$lanBIP/servstats" -o "$psstatsFile"
			else
				/usr/sbin/curl -fs --retry 3 --connect-timeout 15 "http://$psIP/servstats" -o "$psstatsFile"
			fi
		else
			echo "Pixelserv not installed" > "$psstatsFile"
		fi
		
		rm -f "$statsFile"
		rm -f "$clientsFile"
		rm -f "/tmp/uidivstats.js"
		rm -f "/tmp/uidivstatsclients.js"
		rm -f "/tmp/uidivstatstext.js"
		rm -f /tmp/uidiv*.txt
		rm -rf /tmp/uidivstats
		
		Print_Output "true" "Diversion statistic generation completed successfully!" "$PASS"
	else
		Print_Output "true" "Diversion configuration not found or empty dnsmasq.log file, exiting!" "$ERR"
	fi
}

#$1 fieldname $2 tablename $3 frequency (hours) $4 length (days) $5 outputfile $6 outputfrequency $7 sqlfile $8 timestamp
WriteSql_ToFile(){
	timenow="$8"
	maxcount="$(echo "$3" "$4" | awk '{printf ((24*$2)/$1)}')"
	multiplier="$(echo "$3" | awk '{printf (60*60*$1)}')"
	
	{
		echo ".mode csv"
		echo ".output $5$6.tmp"
	} >> "$7"
	
	echo "SELECT '$1', [Timestamp], COUNT([QueryID]) FROM $2 WHERE ([Timestamp] >= $timenow - ($multiplier*$maxcount)) GROUP BY ([Timestamp]/($multiplier));" >> "$7"
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "$1$6""size,1"
}

Aggregate_Stats(){
	metricname="$1"
	period="$2"
	sed -i '1iMetric,Time,Value' "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	head -c -2 "$CSV_OUTPUT_DIR/$metricname$period.tmp" > "$CSV_OUTPUT_DIR/$metricname$period.htm"
	dos2unix "$CSV_OUTPUT_DIR/$metricname$period.htm"
	cp "$CSV_OUTPUT_DIR/$metricname$period.htm" "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	sed -i '1d' "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	min="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | head -1)"
	max="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | tail -1)"
	avg="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | awk '{ total += $1; count++ } END { print total/count }')"
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "$metricname$period""min,$min" "$metricname$period""avg,$avg" "$metricname$period""max,$max"
}

Generate_NG(){
	rm -f "$SCRIPT_DIR/SQLData.js"
	TZ=$(cat /etc/TZ)
	export TZ
	
	timenow=$(date +"%s")
	#timenowfriendly=$(date +"%c")
	Generate_KeyStats "$timenow"
	Generate_Stats_From_SQLite "$timenow"
}

Generate_KeyStats(){
	timenow="$1"
	
	echo "SELECT COUNT(QueryID) FROM [dnsqueries] WHERE [Timestamp] >= ($timenow - (86400*7));" > /tmp/uidivstats-stats.sql
	totalqueries="$("$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql)"
	rm -f /tmp/uidivstats-stats.sql
	
	echo "SELECT COUNT(QueryID) FROM [dnsqueriesblocked] WHERE [Timestamp] >= ($timenow - (86400*7));" > /tmp/uidivstats-stats.sql
	totalqueriesblocked="$("$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql)"
	rm -f /tmp/uidivstats-stats.sql
	
	blockedpercentage="$(echo "$totalqueriesblocked" "$totalqueries" | awk '{printf "%3.2f\n",$1/$2*100}')"
	
	blockinglistfile="$DIVERSION_DIR/list/blockinglist"
	blacklistfile="$DIVERSION_DIR/list/blacklist"
	blacklistwcfile="$DIVERSION_DIR/list/wc_blacklist"
	
	if /opt/bin/grep -qm1 'devEnv' /opt/bin/diversion; then
		blocklistdomains="$(($(/opt/bin/grep "^[^#]" "$blockinglistfile" | wc -w)-$(/opt/bin/grep "^[^#]" "$blockinglistfile" | wc -l)))"
		blocklistdomains="$(($blocklistdomains+$(/opt/bin/grep "^[^#]" "$blacklistwcfile" "$blacklistfile" | wc -l)))"
	else
		blocklistdomains=$(/opt/bin/grep "^[^#]" "$blockinglistfile" "$blacklistfile" "$blacklistwcfile" | wc -l)
	fi
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotal,$totalqueries" "QueriesBlocked,$totalqueriesblocked" "BlockedPercentage,$blockedpercentage" "BlockedDomains,$blocklistdomains"
}

Generate_Stats_From_SQLite(){
	timenow="$1"
	#{
	#	echo "DELETE FROM [dnsqueries] WHERE [Timestamp] < ($timenow - (86400*30));"
	#	echo "DELETE FROM [dnsqueriesblocked] WHERE [Timestamp] < ($timenow - (86400*30));"
	#} > /tmp/uidivstats-stats.sql
	
	#"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql
	
	rm -f "$CSV_OUTPUT_DIR/"*
	rm -f /tmp/uidivstats-stats.sql
	
	metriclist="Total" # Blocked"
	
	for metric in $metriclist; do
		dbtable="dnsqueries"
		if [ "$metric" = "Blocked" ]; then
			dbtable="dnsqueriesblocked"
		fi
		
		WriteSql_ToFile "$metric" "$dbtable" 0.25 1 "$CSV_OUTPUT_DIR/$metric" "daily" "/tmp/uidivstats-stats.sql" "$timenow"
		"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql
		Aggregate_Stats "$metric" "daily"
		rm -f "$CSV_OUTPUT_DIR/$metric""daily.tmp"*
		rm -f /tmp/uidivstats-stats.sql
		
		WriteSql_ToFile "$metric" "$dbtable" 1 7 "$CSV_OUTPUT_DIR/$metric" "weekly" "/tmp/uidivstats-stats.sql" "$timenow"
		"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql
		Aggregate_Stats "$metric" "weekly"
		rm -f "$CSV_OUTPUT_DIR/$metric""weekly.tmp"
		rm -f /tmp/uidivstats-stats.sql
		
		WriteSql_ToFile "$metric" "$dbtable" 3 30 "$CSV_OUTPUT_DIR/$metric" "monthly" "/tmp/uidivstats-stats.sql" "$timenow"
		"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql
		Aggregate_Stats "$metric" "monthly"
		rm -f "$CSV_OUTPUT_DIR/$metric""monthly.tmp"
		rm -f /tmp/uidivstats-stats.sql
	done
	
	rm -f "/tmp/uidivstats-stats.sql"
}

Trim_DNS_DB(){
	/opt/etc/init.d/S90taildns stop
	
	{
		echo "DELETE FROM [dnsqueries] WHERE [Timestamp] < ($timenow - (86400*30));"
		echo "DELETE FROM [dnsqueriesblocked] WHERE [Timestamp] < ($timenow - (86400*30));"
	} > /tmp/uidivstats-stats.sql
	
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-stats.sql
	
	/opt/etc/init.d/S90taildns start
	
	rm -f /tmp/uidivstats-stats.sql
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
	printf "\\e[1m#################################################################\\e[0m\\n"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m##          _  _____   _          _____  _          _          ##\\e[0m\\n"
	printf "\\e[1m##         (_)|  __ \ (_)        / ____|| |        | |         ##\\e[0m\\n"
	printf "\\e[1m##   _   _  _ | |  | | _ __   __| (___  | |_  __ _ | |_  ___   ##\\e[0m\\n"
	printf "\\e[1m##  | | | || || |  | || |\ \ / / \___ \ | __|/ _  || __|/ __|  ##\\e[0m\\n"
	printf "\\e[1m##  | |_| || || |__| || | \ V /  ____) || |_| (_| || |_ \__ \  ##\\e[0m\\n"
	printf "\\e[1m##   \__,_||_||_____/ |_|  \_/  |_____/  \__|\__,_| \__||___/  ##\\e[0m\\n"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m##                      %s on %-9s                    ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m##             https://github.com/jackyaz/uiDivStats           ##\\e[0m\\n"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m#################################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    Generate Diversion Statistics now\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m#################################################################\\e[0m\\n"
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
				break
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
		if ! /opt/bin/grep -qm1 'div_lock_ac' /opt/bin/diversion; then
			Print_Output "true" "Diversion update required!" "$ERR"
			Print_Output "true" "Open Diversion and use option u to update" ""
			CHECKSFAILED="true"
		fi
		
		if ! /opt/bin/grep -q 'log-facility=/opt/var/log/dnsmasq.log' /etc/dnsmasq.conf; then
			Print_Output "true" "Diversion logging not enabled!" "$ERR"
			Print_Output "true" "Open Diversion and use option l to enable logging" ""
			CHECKSFAILED="true"
		fi
	fi
	
	if ! Firmware_Version_Check "install"; then
		Print_Output "true" "Unsupported firmware version detected, 384.XX required" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		opkg update
		opkg install grep
		opkg install sqlite3-cli
		opkg install opkg install procps-ng-pkill
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
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	Create_Dirs
	Create_Symlinks
	
	Update_File "uidivstats_www.asp"
	Update_File "shared-jy.tar.gz"
	Update_File "taildns.tar.gz"
	
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Menu_GenerateStats
	
	Clear_Lock
}

Menu_Startup(){
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Create_Dirs
	Create_Symlinks
	Mount_WebUI
	Clear_Lock
}

Menu_GenerateStats(){
	if /opt/bin/grep -q 'log-facility=/opt/var/log/dnsmasq.log' /etc/dnsmasq.conf; then
		Generate_Stats_Diversion
	else
		Print_Output "true" "Diversion logging not enabled!" "$ERR"
		Print_Output "true" "Open Diversion and use option l to enable logging" ""
	fi
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
	
	Shortcut_script delete
	
	if Firmware_Version_Check "webui" ; then
		Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
		if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
			sed -i "\\~$MyPage~d" /tmp/menuTree.js
			umount /www/require/modules/menuTree.js
			mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
			rm -rf "{$SCRIPT_WEBPAGE_DIR:?}/$MyPage"
		fi
	else
		umount /www/Advanced_MultiSubnet_Content.asp 2>/dev/null
		sed -i '/{url: "Advanced_MultiSubnet_Content.asp", tabName: "Diversion Statistics"}/d' "/jffs/scripts/custom_menuTree.js"
		umount /www/require/modules/menuTree.js 2>/dev/null
		
		if [ ! -f "/jffs/scripts/ntpmerlin" ] && [ ! -f "/jffs/scripts/spdmerlin" ] && [ ! -f "/jffs/scripts/connmon" ]; then
			rm -f "$SHARED_DIR/custom_menuTree.js" 2>/dev/null
		else
			mount -o bind "$SHARED_DIR/custom_menuTree.js" "/www/require/modules/menuTree.js"
		fi
	fi
	rm -f "$SCRIPT_DIR/uidivstats_www.asp" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

if [ -z "$1" ]; then
	Create_Dirs
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
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
	sql)
		Check_Lock
		Generate_NG
		Clear_Lock
		exit 0
	;;
	trimdb)
		Check_Lock
		Trim_DNS_DB
		Clear_Lock
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
