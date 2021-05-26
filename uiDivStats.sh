#!/bin/sh

###################################################################
##                                                               ##
##           _  _____   _          _____  _          _           ##
##          (_)|  __ \ (_)        / ____|| |        | |          ##
##    _   _  _ | |  | | _ __   __| (___  | |_  __ _ | |_  ___    ##
##   | | | || || |  | || |\ \ / / \___ \ | __|/ _  || __|/ __|   ##
##   | |_| || || |__| || | \ V /  ____) || |_| (_| || |_ \__ \   ##
##    \__,_||_||_____/ |_|  \_/  |_____/  \__|\__,_| \__||___/   ##
##                                                               ##
##             https://github.com/jackyaz/uiDivStats             ##
##                                                               ##
###################################################################

##############        Shellcheck directives      #############
# shellcheck disable=SC2009
# shellcheck disable=SC2012
# shellcheck disable=SC2016
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2059
# shellcheck disable=SC2086
##############################################################

### Start of script variables ###
readonly SCRIPT_NAME="uiDivStats"
readonly SCRIPT_VERSION="v2.3.1"
SCRIPT_BRANCH="develop"
SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/$SCRIPT_NAME/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_CONF="$SCRIPT_DIR/config"
readonly SCRIPT_USB_DIR="/opt/share/uiDivStats.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly DNS_DB="$SCRIPT_USB_DIR/dnsqueries.db"
readonly CSV_OUTPUT_DIR="$SCRIPT_USB_DIR/csv"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
SQLITE3_PATH=/opt/bin/sqlite3
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

Validate_Number(){
	if [ "$1" -eq "$1" ] 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

Validate_IP(){
	if expr "$1" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
		for i in 1 2 3 4; do
			if [ "$(echo "$1" | cut -d. -f$i)" -gt 255 ]; then
				Print_Output false "Octet $i ($(echo "$1" | cut -d. -f$i)) - is invalid, must be less than 255" "$ERR"
				return 1
			fi
		done
	else
		Print_Output false "$1 - is not a valid IPv4 address, valid format is 1.2.3.4" "$ERR"
		return 1
	fi
}

Firmware_Version_Check(){
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]; then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds) - statistic generation likely currently in progress" "$ERR"
			if [ -z "$1" ]; then
				exit 1
			else
				if [ "$1" = "webui" ]; then
					echo 'var uidivstatsstatus = "LOCKED";' > /tmp/detect_uidivstats.js
					exit 1
				fi
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

############################################################################

Set_Version_Custom_Settings(){
	SETTINGSFILE=/jffs/addons/custom_settings.txt
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "uidivstats_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$SCRIPT_VERSION" != "$(grep "uidivstats_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/uidivstats_version_local.*/uidivstats_version_local $SCRIPT_VERSION/" "$SETTINGSFILE"
					fi
				else
					echo "uidivstats_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
				fi
			else
				echo "uidivstats_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "uidivstats_version_server" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "uidivstats_version_server" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/uidivstats_version_server.*/uidivstats_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "uidivstats_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "uidivstats_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

Update_Check(){
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || { Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]; then
			doupdate="md5"
			Set_Version_Custom_Settings server "$serverver-hotfix"
			echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
	fi
	if [ "$doupdate" = "false" ]; then
		echo 'var updatestatus = "None";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	fi
	echo "$doupdate,$localver,$serverver"
}

Update_Version(){
	if [ -z "$1" ] || [ "$1" = "unattended" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File shared-jy.tar.gz
		
		if [ "$isupdate" != "false" ]; then
			Update_File uidivstats_www.asp
			Update_File taildns.tar.gz
			
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			if [ -z "$1" ]; then
				exec "$0" setversion
			elif [ "$1" = "unattended" ]; then
				exec "$0" setversion unattended
			fi
			exit 0
		else
			Print_Output true "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File uidivstats_www.asp
		Update_File shared-jy.tar.gz
		Update_File taildns.tar.gz
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
		chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0" setversion
		elif [ "$2" = "unattended" ]; then
			exec "$0" setversion unattended
		fi
		exit 0
	fi
}

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
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "taildns.tar.gz" ]; then
		if [ ! -f "$SCRIPT_DIR/$1.md5" ]; then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Download_File "$SCRIPT_REPO/$1.md5" "$SCRIPT_DIR/$1.md5"
			tar -xzf "$SCRIPT_DIR/$1" -C "$SCRIPT_DIR"
			if [ -f /opt/etc/init.d/S90taildns ]; then
				/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
				sleep 5
			fi
			mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
			rm -f "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SCRIPT_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Download_File "$SCRIPT_REPO/$1.md5" "$SCRIPT_DIR/$1.md5"
				tar -xzf "$SCRIPT_DIR/$1" -C "$SCRIPT_DIR"
				if [ -f /opt/etc/init.d/S90taildns ]; then
					/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
					sleep 5
				fi
				mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
				/opt/etc/init.d/S90taildns start >/dev/null 2>&1
				rm -f "$SCRIPT_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	elif [ "$1" = "shared-jy.tar.gz" ]; then
		if [ ! -f "$SHARED_DIR/$1.md5" ]; then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	else
		return 1
	fi
}

Conf_FromSettings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	TMPFILE="/tmp/uidivstats_settings.txt"
	if [ -f "$SETTINGSFILE" ]; then
		if [ "$(grep "uidivstats_" $SETTINGSFILE | grep -v "version" -c)" -gt 0 ]; then
			Print_Output true "Updated settings from WebUI found, merging into $SCRIPT_CONF" "$PASS"
			cp -a "$SCRIPT_CONF" "$SCRIPT_CONF.bak"
			grep "uidivstats_" "$SETTINGSFILE" | grep -v "version" > "$TMPFILE"
			sed -i "s/uidivstats_//g;s/ /=/g" "$TMPFILE"
			while IFS='' read -r line || [ -n "$line" ]; do
				SETTINGNAME="$(echo "$line" | cut -f1 -d'=' | awk '{ print toupper($1) }')"
				SETTINGVALUE="$(echo "$line" | cut -f2 -d'=')"
				sed -i "s/$SETTINGNAME=.*/$SETTINGNAME=$SETTINGVALUE/" "$SCRIPT_CONF"
			done < "$TMPFILE"
			grep 'uidivstats_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~uidivstats_~d" "$SETTINGSFILE"
			mv "$SETTINGSFILE" "$SETTINGSFILE.bak"
			cat "$SETTINGSFILE.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "$SETTINGSFILE.bak"
			
			QueryMode "$(QueryMode check)"
			sleep 5
			CacheMode "$(CacheMode check)"
			
			Print_Output true "Merge of updated settings from WebUI completed successfully" "$PASS"
		else
			Print_Output false "No updated settings from WebUI found, no merge into $SCRIPT_CONF necessary" "$PASS"
		fi
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
	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null
	
	ln -s /tmp/detect_uidivstats.js "$SCRIPT_WEB_DIR/detect_uidivstats.js" 2>/dev/null
	ln -s "$SCRIPT_DIR/SQLData.js" "$SCRIPT_WEB_DIR/SQLData.js" 2>/dev/null
	ln -s "$SCRIPT_CONF" "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	
	if [ ! -f /opt/bin/find ]; then
		opkg update
		opkg install findutils
	fi
	
	UpdateDiversionWeeklyStatsFile
	
	ln -s "$CSV_OUTPUT_DIR" "$SCRIPT_WEB_DIR/csv" 2>/dev/null
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

Conf_Exists(){
	if [ -f "$SCRIPT_CONF" ]; then
		dos2unix "$SCRIPT_CONF"
		chmod 0644 "$SCRIPT_CONF"
		sed -i -e 's/"//g' "$SCRIPT_CONF"
		return 0
	else
		{ echo "QUERYMODE=all"; echo "CACHEMODE=tmp"; } > "$SCRIPT_CONF"
		return 1
	fi
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
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
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/post-mount
				echo "" >> /jffs/scripts/post-mount
				echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}

Auto_Cron(){
	case $1 in
		create)
			STARTUPLINECOUNTGENERATE=$(cru l | grep -c "${SCRIPT_NAME}_generate")
			STARTUPLINECOUNTTRIM=$(cru l | grep -c "${SCRIPT_NAME}_trim")
			STARTUPLINECOUNTQUERYLOG=$(cru l | grep -c "${SCRIPT_NAME}_querylog")
			STARTUPLINECOUNTFLUSHTODB=$(cru l | grep -c "${SCRIPT_NAME}_flushtodb")
			
			STARTUPLINECOUNTEXFLUSHTODB=$(cru l | grep "${SCRIPT_NAME}_flushtodb" | grep -c "4-59/5" )
			if [ "$STARTUPLINECOUNTFLUSHTODB" -ne 0 ] && [ "$STARTUPLINECOUNTEXFLUSHTODB" -eq 0 ]; then
				cru d "${SCRIPT_NAME}_flushtodb"
			fi
			
			if [ "$STARTUPLINECOUNTGENERATE" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_generate" "0 * * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_trim" "3 0 * * * /jffs/scripts/$SCRIPT_NAME trimdb"
			fi
			if [ "$STARTUPLINECOUNTQUERYLOG" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_querylog" "* * * * * /jffs/scripts/$SCRIPT_NAME querylog"
			fi
			if [ "$STARTUPLINECOUNTFLUSHTODB" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_flushtodb" "4-59/5 * * * * /jffs/scripts/$SCRIPT_NAME flushtodb"
			fi
		;;
		delete)
			STARTUPLINECOUNTGENERATE=$(cru l | grep -c "${SCRIPT_NAME}_generate")
			STARTUPLINECOUNTTRIM=$(cru l | grep -c "${SCRIPT_NAME}_trim")
			STARTUPLINECOUNTQUERYLOG=$(cru l | grep -c "${SCRIPT_NAME}_querylog")
			STARTUPLINECOUNTFLUSHTODB=$(cru l | grep -c "${SCRIPT_NAME}_flushtodb")
			
			if [ "$STARTUPLINECOUNTGENERATE" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_trim"
			fi
			if [ "$STARTUPLINECOUNTQUERYLOG" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_querylog"
			fi
			if [ "$STARTUPLINECOUNTFLUSHTODB" -eq 0 ]; then
				cru d "${SCRIPT_NAME}_flushtodb"
			fi
		;;
	esac
}

Auto_DNSMASQ_Postconf(){
	case $1 in
		create)
			if [ -f /jffs/scripts/dnsmasq.postconf ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/dnsmasq.postconf)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME dnsmasq & # $SCRIPT_NAME" /jffs/scripts/dnsmasq.postconf)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/dnsmasq.postconf
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME dnsmasq & # $SCRIPT_NAME" >> /jffs/scripts/dnsmasq.postconf
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/dnsmasq.postconf
				echo "" >> /jffs/scripts/dnsmasq.postconf
				echo "/jffs/scripts/$SCRIPT_NAME dnsmasq & # $SCRIPT_NAME" >> /jffs/scripts/dnsmasq.postconf
				chmod 0755 /jffs/scripts/dnsmasq.postconf
			fi
		;;
		delete)
			if [ -f /jffs/scripts/dnsmasq.postconf ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/dnsmasq.postconf)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/dnsmasq.postconf
				fi
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Get_WebUI_Page(){
	MyPage="none"
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
		page="/www/user/user$i.asp"
		if [ -f "$page" ] && [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		elif [ "$MyPage" = "none" ] && [ ! -f "$page" ]; then
			MyPage="user$i.asp"
		fi
	done
}

Mount_WebUI(){
	Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output true "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		Clear_Lock
		exit 1
	fi
	Print_Output true "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
	cp -f "$SCRIPT_DIR/uidivstats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
	echo "$SCRIPT_NAME" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
	if [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
		if [ ! -f /tmp/menuTree.js ]; then
			cp -f /www/require/modules/menuTree.js /tmp/
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if /bin/grep 'tabName: \"Diversion\"},' /tmp/menuTree.js >/dev/null 2>&1; then
			sed -i "/tabName: \"Diversion\"/a {url: \"$MyPage\", tabName: \"$SCRIPT_NAME\"}," /tmp/menuTree.js
		else
			sed -i "/url: \"Advanced_SwitchCtrl_Content.asp\", tabName:/a {url: \"$MyPage\", tabName: \"$SCRIPT_NAME\"}," /tmp/menuTree.js
		fi
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
}

QueryMode(){
	case "$1" in
		all)
			sed -i 's/^QUERYMODE.*$/QUERYMODE=all/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 5
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		A+AAAA)
			sed -i 's/^QUERYMODE.*$/QUERYMODE=A+AAAA/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 5
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		check)
			QUERYMODE="$(grep "QUERYMODE" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "$QUERYMODE"
		;;
	esac
}

CacheMode(){
	case "$1" in
		none)
			sed -i 's/^CACHEMODE.*$/CACHEMODE=none/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 5
			Flush_Cache_To_DB
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		tmp)
			sed -i 's/^CACHEMODE.*$/CACHEMODE=tmp/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 5
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		check)
			CACHEMODE="$(grep "CACHEMODE" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "$CACHEMODE"
		;;
	esac
}

BlockingFile(){
	case "$1" in
		check)
		DIVCONF="$DIVERSION_DIR/.conf/diversion.conf"
		BLOCKINGFILE="$DIVERSION_DIR/list/blockinglist"
		
		if [ "$(grep alternateBF "$DIVCONF" | cut -f2 -d"=")" = "on" ]; then
				BLOCKINGFILE="$DIVERSION_DIR/list/blockinglist $DIVERSION_DIR/list/blockinglist_fs"
		elif [ "$(grep "bfFs" "$DIVCONF" | cut -f2 -d"=")" = "on" ]; then
			if [ "$(grep "bfTypeinUse" "$DIVCONF" | cut -f2 -d"=")" != "primary" ]; then
				BLOCKINGFILE="$DIVERSION_DIR/list/blockinglist_fs"
			fi
		fi
		
		echo "$BLOCKINGFILE"
		;;
	esac
}

UpdateDiversionWeeklyStatsFile(){
	rm -f "$SCRIPT_WEB_DIR/DiversionStats.htm" 2>/dev/null
	diversionstatsfile="$(/opt/bin/find /opt/share/diversion/stats -name "Diversion_Stats*" -printf "%C@ %p\n"| sort | tail -n 1 | cut -f2 -d' ')"
	ln -s "$diversionstatsfile" "$SCRIPT_WEB_DIR/DiversionStats.htm" 2>/dev/null
}

WriteStats_ToJS(){
	{ echo ""; echo "function $3(){"; } >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="${html}${line}\\r\\n"
	done < "$1"
	html="$html"'"'
	printf "%s\\r\\n}\\r\\n" "$html" >> "$2"
}

WritePlainData_ToJS(){
	outputfile="$1"
	shift
	for var in "$@"; do
		varname="$(echo "$var" | cut -f1 -d',')"
		varvalue="$(echo "$var" | cut -f2 -d',')"
		if [ -f "$outputfile" ]; then
			sed -i -e '/'"$varname"'/d' "$outputfile"
		fi
		echo "var $varname = $varvalue;" >> "$outputfile"
	done
}

Write_View_Sql_ToFile(){
	if [ "$6" = "create" ]; then
		timenow="$5"
		echo "CREATE VIEW IF NOT EXISTS ${1}${2} AS SELECT * FROM $1 WHERE ([Timestamp] >= $timenow - (86400*$3)) AND ([Timestamp] <= $timenow);" > "$4"
	elif [ "$6" = "drop" ]; then
		echo "DROP VIEW IF EXISTS ${1}${2};" > "$4"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile $7 timestamp
Write_Count_Sql_ToFile(){
	timenow="$7"
	
	{
		echo ".mode csv"
		echo ".headers on"
		echo ".output ${4}${5}.htm"
	} > "$6"
	
	if [ "$1" = "Total" ]; then
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_time_domains (Timestamp>? AND Timestamp<?)
		echo "SELECT '$1' Fieldname, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM ${2}${5} GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	elif [ "$1" = "Blocked" ]; then # covering index idx_results_domains
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_results_time_domains (Result>? AND Result<?)
		echo "SELECT '$1' Fieldname, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM ${2}${5} WHERE ([Result] LIKE 'blocked%') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile $7 timestamp
Write_Count_PerClient_Sql_ToFile(){
	timenow="$7"
	echo ".mode list" > "$6"
	echo ".output /tmp/distinctclients" >> "$6"
	if [ "$1" = "Total" ]; then
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_time_clients (Timestamp>? AND Timestamp<?)
		echo "SELECT DISTINCT [SrcIP] SrcIP FROM ${2}${5};" >> "$6"
	elif [ "$1" = "Blocked" ]; then
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_results_time_clients (Result>? AND Result<?)
		echo "SELECT DISTINCT [SrcIP] SrcIP FROM ${2}${5} WHERE ([Result] LIKE 'blocked%');" >> "$6"
	fi
	while ! "$SQLITE3_PATH" "$DNS_DB" < "$6" >/dev/null 2>&1; do
		sleep 1
	done
	
	clients="$(cat /tmp/distinctclients)"
	rm -f /tmp/distinctclients
	
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".output ${4}${5}clients.htm"
	} > "$6"
	
	if [ "$1" = "Total" ]; then
		for client in $clients; do
			# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_clients_time_domains (SrcIP=? AND Timestamp>? AND Timestamp<?)
			echo "SELECT '$1' Fieldname, [SrcIP] SrcIP, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM ${2}${5} WHERE ([SrcIP] = '$client') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
		done
	elif [ "$1" = "Blocked" ]; then
		for client in $clients; do
			# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_clients_results_time_domains (SrcIP=? AND Result>? AND Result<?)
			echo "SELECT '$1' Fieldname, [SrcIP] SrcIP, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM ${2}${5} WHERE ([SrcIP] = '$client') AND ([Result] LIKE 'blocked%') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
		done
	fi
}

#$1 fieldname $2 tablename $3 frequency (hours) $4 length (days) $5 outputfile $6 outputfrequency $7 sqlfile $8 timestamp
Write_Time_Sql_ToFile(){
	timenow="$8"
	multiplier="$(echo "$3" | awk '{printf (60*60*$1)}')"
	
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".output ${5}${6}time.htm"
	} > "$7"
	
	if [ "$4" -eq 1 ]; then
		maxcount="$(echo "$multiplier" | awk '{printf (60*60*24/$1)}')"
		currentcount=0
		while [ "$currentcount" -lt "$maxcount" ]; do
			if [ "$1" = "Total" ]; then
				# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_time_results (Timestamp>? AND Timestamp<?)
				echo "SELECT '$1' Fieldname, $timenow - ($multiplier*$currentcount) Time, COUNT([QueryID]) QueryCount FROM ${2}${6} WHERE ([Timestamp] >= $timenow - ($multiplier*($currentcount+1))) AND ([Timestamp] <= $timenow - ($multiplier*$currentcount));" >> "$7"
			elif [ "$1" = "Blocked" ]; then
				# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_results_time (Result>? AND Result<?)
				echo "SELECT '$1' Fieldname, $timenow - ($multiplier*$currentcount) Time, COUNT([QueryID]) QueryCount FROM ${2}${6} WHERE ([Result] LIKE 'blocked%') AND ([Timestamp] >= $timenow - ($multiplier*($currentcount+1))) AND ([Timestamp] <= $timenow - ($multiplier*$currentcount));" >> "$7"
			fi
			currentcount="$((currentcount + 1))"
		done
	else
		if [ "$1" = "Total" ]; then
			# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_time_results (Timestamp>? AND Timestamp<?)
			echo "SELECT '$1' Fieldname, [Timestamp] Time, COUNT([QueryID]) QueryCount FROM ${2}${6} GROUP BY ([Timestamp]/($multiplier));" >> "$7"
		elif [ "$1" = "Blocked" ]; then
			# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_results_time (Result>? AND Result<?)
			echo "SELECT '$1' Fieldname, [Timestamp] Time, COUNT([QueryID]) QueryCount FROM ${2}${6} WHERE ([Result] LIKE 'blocked%') GROUP BY ([Timestamp]/($multiplier));" >> "$7"
		fi
	fi
}

Write_KeyStats_Sql_ToFile(){
	timenow="$6"
	{
		echo ".headers off"
		echo ".output /tmp/queries${1}${3}"
	} > "$5"
	
	if [ "$1" = "Total" ]; then
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_time_results (Timestamp>? AND Timestamp<?)
		echo "SELECT COUNT([QueryID]) QueryCount FROM ${2}${3} WHERE [Timestamp] >= ($timenow - (86400*$4)) AND [Timestamp] <= $timenow;" >> "$5"
	elif [ "$1" = "Blocked" ]; then
		# --SEARCH TABLE dnsqueries USING COVERING INDEX idx_results_time (Result>? AND Result<?)
		echo "SELECT COUNT([QueryID]) QueryCount FROM ${2}${3} WHERE [Timestamp] >= ($timenow - (86400*$4)) AND [Timestamp] <= $timenow AND [Result] LIKE 'blocked%';" >> "$5"
	fi
}

Generate_NG(){
	TZ=$(cat /etc/TZ)
	export TZ
	
	timenow=$(date +"%s")
	timenowfriendly=$(date +"%c")
	
	rm -f /tmp/uidivstats.sql
	
	echo 'var uidivstatsstatus = "InProgress";' > /tmp/detect_uidivstats.js
	
	echo "DELETE FROM [dnsqueries] WHERE [Timestamp] > $timenow;" > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	echo "DELETE FROM [dnsqueries] WHERE [SrcIP] = 'from';" > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql
	
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Write_View_Sql_ToFile dnsqueries daily 1 /tmp/uidivstats.sql "$timenow" drop
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_View_Sql_ToFile dnsqueries weekly 7 /tmp/uidivstats.sql "$timenow" drop
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_View_Sql_ToFile dnsqueries monthly 30 /tmp/uidivstats.sql "$timenow" drop
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql
	fi
	
	Write_View_Sql_ToFile dnsqueries daily 1 /tmp/uidivstats.sql "$timenow" create
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile dnsqueries weekly 7 /tmp/uidivstats.sql "$timenow" create
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile dnsqueries monthly 30 /tmp/uidivstats.sql "$timenow" create
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql
	
	Generate_Count_Blocklist_Domains
	
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Generate_KeyStats "$timenow" fullrefresh
		Generate_Stats_From_SQLite "$timenow" fullrefresh
	else
		Generate_KeyStats "$timenow"
		Generate_Stats_From_SQLite "$timenow"
	fi
	
	echo "Stats last updated: $timenowfriendly" > /tmp/uidivstatstitle.txt
	WriteStats_ToJS /tmp/uidivstatstitle.txt "$SCRIPT_DIR/SQLData.js" SetuiDivStatsTitle statstitle
	echo 'var uidivstatsstatus = "Done";' > /tmp/detect_uidivstats.js
	Print_Output true "Stats updated successfully" "$PASS"
	rm -f /tmpuidivstatstitle.txt
}

Generate_Query_Log(){
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep querylog | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep querylog | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	
	recordcount=5000
	if [ "$(CacheMode check)" = "tmp" ]; then
		if [ -f /tmp/cache-uiDivStats-SQL.tmp ]; then
			sort -s -k 1,1 -n -r /tmp/cache-uiDivStats-SQL.tmp | sed 's/,/|/g' | awk 'BEGIN{FS=OFS="|"} {t=$2; $2=$3; $3=t; print}' > /tmp/cache-uiDivStats-SQL.tmp.ordered
			recordcount="$((recordcount - $(wc -l < /tmp/cache-uiDivStats-SQL.tmp.ordered)))"
			if [ "$(echo "$recordcount 1" | awk '{print ($1 < $2)}')" -eq 1 ]; then
				recordcount=1
			fi
		fi
	fi
	
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".separator '|'"
		echo ".output $CSV_OUTPUT_DIR/SQLQueryLog.tmp"
		echo "SELECT [Timestamp] Time,[ReqDmn] ReqDmn,[SrcIP] SrcIP,[QryType] QryType,[Result] Result FROM [dnsqueries] ORDER BY [Timestamp] DESC LIMIT $recordcount;"
	} > /tmp/uidivstats-query.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-query.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-query.sql
	
	cat /tmp/cache-uiDivStats-SQL.tmp.ordered "$CSV_OUTPUT_DIR/SQLQueryLog.tmp" > "$CSV_OUTPUT_DIR/SQLQueryLog.htm" 2> /dev/null
	rm -f /tmp/cache-uiDivStats-SQL.tmp.ordered
	rm -f "$CSV_OUTPUT_DIR/SQLQueryLog.tmp"
}

Generate_KeyStats(){
	timenow="$1"
	
	#daily
	Write_KeyStats_Sql_ToFile Total dnsqueries daily 1 /tmp/uidivstats1.sql "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats1.sql >/dev/null 2>&1; do
		sleep 1
	done &
	Write_KeyStats_Sql_ToFile Blocked dnsqueries daily 1 /tmp/uidivstats2.sql "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats2.sql >/dev/null 2>&1; do
		sleep 1
	done &
	sleep 1
	while [ ! -f /tmp/queriesTotaldaily ] && [ ! -f /tmp/queriesBlockeddaily ]; do
		sleep 1
	done
	rm -f /tmp/uidivstats1.sql
	rm -f /tmp/uidivstats2.sql
	
	queriesTotaldaily="$(cat /tmp/queriesTotaldaily)"
	queriesBlockeddaily="$(cat /tmp/queriesBlockeddaily)"
	
	if ! Validate_Number "$queriesTotaldaily"; then queriesTotaldaily=0; fi
	if ! Validate_Number "$queriesBlockeddaily"; then queriesBlockeddaily=0; fi
	if [ "$queriesTotaldaily" -eq 0 ]; then
		queriesPercentagedaily=0
	else
		queriesPercentagedaily="$(echo "$queriesBlockeddaily" "$queriesTotaldaily" | awk '{printf "%3.2f\n",$1/$2*100}')"
	fi
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotaldaily,$queriesTotaldaily" "QueriesBlockeddaily,$queriesBlockeddaily" "BlockedPercentagedaily,$queriesPercentagedaily"
	
	#weekly
	if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
		Write_KeyStats_Sql_ToFile Total dnsqueries weekly 7 /tmp/uidivstats1.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats1.sql >/dev/null 2>&1; do
			sleep 1
		done &
		Write_KeyStats_Sql_ToFile Blocked dnsqueries weekly 7 /tmp/uidivstats2.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats2.sql >/dev/null 2>&1; do
			sleep 1
		done &
		sleep 1
		while [ ! -f /tmp/queriesTotalweekly ] && [ ! -f /tmp/queriesBlockedweekly ]; do
			sleep 1
		done
		rm -f /tmp/uidivstats1.sql
		rm -f /tmp/uidivstats2.sql
		
		queriesTotalweekly="$(cat /tmp/queriesTotalweekly)"
		queriesBlockedweekly="$(cat /tmp/queriesBlockedweekly)"
		
		if ! Validate_Number "$queriesTotalweekly"; then queriesTotalweekly=0; fi
		if ! Validate_Number "$queriesBlockedweekly"; then queriesBlockedweekly=0; fi
		if [ "$queriesTotalweekly" -eq 0 ]; then
			queriesPercentageweekly=0
		else
			queriesPercentageweekly="$(echo "$queriesBlockedweekly" "$queriesTotalweekly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		fi
		
		WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotalweekly,$queriesTotalweekly" "QueriesBlockedweekly,$queriesBlockedweekly" "BlockedPercentageweekly,$queriesPercentageweekly"
	fi

	#monthly
	if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
		Write_KeyStats_Sql_ToFile Total dnsqueries monthly 30 /tmp/uidivstats1.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats1.sql >/dev/null 2>&1; do
			sleep 1
		done &
		Write_KeyStats_Sql_ToFile Blocked dnsqueries monthly 30 /tmp/uidivstats2.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats2.sql >/dev/null 2>&1; do
			sleep 1
		done &
		sleep 1
		while [ ! -f /tmp/queriesTotalmonthly ] && [ ! -f /tmp/queriesBlockedmonthly ]; do
			sleep 1
		done
		rm -f /tmp/uidivstats1.sql
		rm -f /tmp/uidivstats2.sql
		
		queriesTotalmonthly="$(cat /tmp/queriesTotalmonthly)"
		queriesBlockedmonthly="$(cat /tmp/queriesBlockedmonthly)"
		
		if ! Validate_Number "$queriesTotalmonthly"; then queriesTotalmonthly=0; fi
		if ! Validate_Number "$queriesBlockedmonthly"; then queriesBlockedmonthly=0; fi
		if [ "$queriesTotalmonthly" -eq 0 ]; then
			queriesPercentagemonthly=0
		else
			queriesPercentagemonthly="$(echo "$queriesBlockedmonthly" "$queriesTotalmonthly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		fi
		
		WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotalmonthly,$queriesTotalmonthly" "QueriesBlockedmonthly,$queriesBlockedmonthly" "BlockedPercentagemonthly,$queriesPercentagemonthly"
	fi
	
	rm -f /tmp/queriesTotal*
	rm -f /tmp/queriesBlocked*
}

Generate_Count_Blocklist_Domains(){
	blockinglistfile="$(BlockingFile check)"
	blacklistfile="$DIVERSION_DIR/list/blacklist"
	blacklistwcfile="$DIVERSION_DIR/list/wc_blacklist"
	
	BLL="$(($(/opt/bin/grep "^[^#]" $blockinglistfile | wc -w)-$(/opt/bin/grep "^[^#]" $blockinglistfile | wc -l)))"
	[ "$(nvram get ipv6_service)" != "disabled" ] && BLL="$((BLL/2))"
	BL="$(/opt/bin/grep "^[^#]" "$blacklistfile" | wc -l)"
	[ "$(nvram get ipv6_service)" != "disabled" ] && BL="$((BL/2))"
	WCBL="$(/opt/bin/grep "^[^#]" "$blacklistwcfile" | wc -l)"
	blocklistdomains="$((BLL+BL+WCBL))"
	if ! Validate_Number "$blocklistdomains"; then blocklistdomains=0; fi
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "BlockedDomains,$blocklistdomains"
}

Generate_Stats_From_SQLite(){
	timenow="$1"
	
	metriclist="Total Blocked"
	
	for metric in $metriclist; do
		
		#daily
		Write_Time_Sql_ToFile "$metric" dnsqueries 0.25 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_Count_Sql_ToFile "$metric" dnsqueries 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}dailyclients.htm"
		
		cat "$CSV_OUTPUT_DIR/Totaldailytime.htm" "$CSV_OUTPUT_DIR/Blockeddailytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm" 2> /dev/null
		sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm"
		
		#weekly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" dnsqueries 1 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_Sql_ToFile "$metric" dnsqueries 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			
			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}weeklyclients.htm"
			cat "$CSV_OUTPUT_DIR/Totalweeklytime.htm" "$CSV_OUTPUT_DIR/Blockedweeklytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm"
		fi
		
		#monthly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" dnsqueries 3 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_Sql_ToFile "$metric" dnsqueries 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			
			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}monthlyclients.htm"
			cat "$CSV_OUTPUT_DIR/Totalmonthlytime.htm" "$CSV_OUTPUT_DIR/Blockedmonthlytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm"
		fi
	done
	
	Write_View_Sql_ToFile dnsqueries daily 1 /tmp/uidivstats.sql "$timenow" drop
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql
	
	# --SCAN TABLE dnsqueries USING COVERING INDEX idx_clients
	{
		echo ".mode list"
		echo ".output /tmp/ipdistinctclients"
		echo "SELECT DISTINCT [SrcIP] SrcIP FROM dnsqueries;"
	} > /tmp/ipdistinctclients.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/ipdistinctclients.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/ipdistinctclients.sql
	
	ipclients="$(cat /tmp/ipdistinctclients)"
	rm -f /tmp/ipdistinctclients
	
	if [ ! -f /opt/bin/dig ]; then
		opkg update
		opkg install bind-dig
	fi
	
	echo "var hostiparray =[" > "$CSV_OUTPUT_DIR/ipdistinctclients.js"
	ARPDUMP="$(arp -a)"
	for ipclient in $ipclients; do
		ARPINFO="$(echo "$ARPDUMP" | grep "$ipclient)")"
		HOST="$(echo "$ARPINFO" | awk '{print $1}' | cut -f1 -d ".")"
		MACADDR="$(echo "$ARPINFO" | awk '{print $4}' | cut -f1 -d ".")"
		if echo "$HOST" | grep -q "?"; then
			HOST="$(grep "$ipclient " /var/lib/misc/dnsmasq.leases | grep -v "\*" | awk '{print $4}')"
		fi
			
		if [ "$HOST" = "?" ] || [ "$(printf "%s" "$HOST" | wc -m)" -le 1 ]; then
			HOST="$(nvram get custom_clientlist | grep -ioE "<.*>$MACADDR" | awk -F ">" '{print $(NF-1)}' | tr -d '<')" #thanks Adamm00
		fi
			
		if Validate_IP "$ipclient" >/dev/null 2>&1; then
			if [ -z "$HOST" ]; then
				HOST="$(dig +short +answer -x "$ipclient" '@'"$(nvram get lan_ipaddr)" | cut -f1 -d'.')"
			fi
		else
			HOST="IPv6"
		fi
		
		HOST="$(echo "$HOST" | tr -d '\n')"
		
		echo '["'"$ipclient"'","'"$HOST"'"],' >> "$CSV_OUTPUT_DIR/ipdistinctclients.js"
	done
	sed -i '$ s/,$//' "$CSV_OUTPUT_DIR/ipdistinctclients.js"
	echo "];" >> "$CSV_OUTPUT_DIR/ipdistinctclients.js"
}

Trim_DNS_DB(){
	renice 15 $$
	TZ=$(cat /etc/TZ)
	export TZ
	timenow=$(date +"%s")
	
	echo "DELETE FROM [dnsqueries] WHERE [Timestamp] < ($timenow - (86400*30));" > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	echo "DELETE FROM [dnsqueries] WHERE [Timestamp] > $timenow;" > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	echo "DELETE FROM [dnsqueries] WHERE [SrcIP] = 'from';" > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile dnsqueries weekly 7 /tmp/uidivstats-trim.sql "$timenow" drop
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile dnsqueries monthly 30 /tmp/uidivstats-trim.sql "$timenow" drop
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql
	renice 0 $$
}

Flush_Cache_To_DB(){
	renice 15 $$
	if [ -f /tmp/cache-uiDivStats-SQL.tmp ]; then
		{
			echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL, [Timestamp] NUMERIC NOT NULL, [SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Result] Text NOT NULL);"
			echo "CREATE TABLE IF NOT EXISTS [dnsqueries_tmp] ([Timestamp] NUMERIC NOT NULL, [SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Result] Text NOT NULL);"
			echo ".mode csv"
			echo ".import /tmp/cache-uiDivStats-SQL.tmp dnsqueries_tmp"
			echo "INSERT INTO dnsqueries SELECT NULL,* FROM dnsqueries_tmp;"
			echo "DROP TABLE IF EXISTS dnsqueries_tmp;"
		} > /tmp/cache-uiDivStats-SQL.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/cache-uiDivStats-SQL.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/cache-uiDivStats-SQL.sql
		rm -f /tmp/cache-uiDivStats-SQL.tmp
	fi
	renice 0 $$
}

Process_Upgrade(){
	rm -f "$SCRIPT_DIR/.upgraded"
	rm -f "$SCRIPT_DIR/.upgraded2"
	rm -f "$SCRIPT_DIR/.upgraded3"
	
	if [ ! -f "$SCRIPT_DIR/.newindexes" ]; then
		/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
		sleep 5
		Auto_Cron delete 2>/dev/null
	fi
	
	renice 15 $$
	
	Print_Output true "Checking database table indexes..." "$PASS"
	echo "DROP INDEX IF EXISTS idx_dns_domains;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_dns_time;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_dns_clients;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_results_clients;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_clients_results_domains;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used in Generate_Stats_From_SQLite for unique clients and Write_Count_PerClient_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_clients ON dnsqueries (SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_time_clients ON dnsqueries (Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_results_time_clients ON dnsqueries (Result collate nocase,Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_clients_time_domains ON dnsqueries (SrcIP,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_clients_results_time_domains ON dnsqueries (SrcIP,Result collate nocase,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	 # used by Write_Count_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_time_domains ON dnsqueries (Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_results_time_domains ON dnsqueries (Result collate nocase,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used by Write_Time_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_results_time ON dnsqueries (Result collate nocase,Timestamp);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used by Write_KeyStats_Sql_ToFile and Write_Time_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_time_results ON dnsqueries (Timestamp,Result collate nocase);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	rm -f /tmp/uidivstats-upgrade.sql
	Print_Output true "Database index checks complete" "$PASS"
	
	renice 0 $$
	
	if [ ! -f "$SCRIPT_DIR/.newindexes" ]; then
		Auto_Cron create 2>/dev/null
		/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		touch "$SCRIPT_DIR/.newindexes"
	fi
}

Shortcut_Script(){
	case $1 in
		create)
			if [ -d /opt/bin ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]; then
				ln -s "/jffs/scripts/$SCRIPT_NAME" /opt/bin
				chmod 0755 "/opt/bin/$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f "/opt/bin/$SCRIPT_NAME"
			fi
		;;
	esac
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r key
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
	printf "\\e[1m##                      %s on %-11s                  ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m##             https://github.com/jackyaz/uiDivStats           ##\\e[0m\\n"
	printf "\\e[1m##                                                             ##\\e[0m\\n"
	printf "\\e[1m#################################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    Update Diversion Statistics (daily only)\\n\\n"
	printf "2.    Update Diversion Statistics (daily, weekly and monthly)\\n"
	printf "      WARNING: THIS WILL TAKE A WHILE (>10 minutes)\\n\\n"
	printf "q.    Toggle query mode\\n      Currently \\e[1m%s\\e[0m query types will be logged\\n\\n" "$(QueryMode check)"
	printf "c.    Toggle cache mode\\n      Currently \\e[1m%s\\e[0m being used to cache query records\\n\\n" "$(CacheMode check)"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m#################################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r menu
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock menu; then
					Menu_GenerateStats
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				if Check_Lock menu; then
					Menu_GenerateStats fullrefresh
				fi
				PressEnter
				break
			;;
			q)
				printf "\\n"
				if Check_Lock menu; then
					Menu_ToggleQueryMode
				fi
				break
			;;
			c)
				printf "\\n"
				if Check_Lock menu; then
					Menu_ToggleCacheMode
				fi
				break
			;;
			u)
				printf "\\n"
				if Check_Lock menu; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock menu; then
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
					read -r confirm
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
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
	fi
	
	if [ ! -f /opt/bin/opkg ]; then
		Print_Output true "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ ! -f /opt/bin/diversion ]; then
		Print_Output true "Diversion not installed!" "$ERR"
		CHECKSFAILED="true"
	else
		if ! /opt/bin/grep -qm1 'div_lock_ac' /opt/bin/diversion; then
			Print_Output true "Diversion update required!" "$ERR"
			Print_Output true "Open Diversion and use option u to update"
			CHECKSFAILED="true"
		fi
		
		if ! /opt/bin/grep -q 'log-facility=/opt/var/log/dnsmasq.log' /etc/dnsmasq.conf; then
			Print_Output true "Diversion logging not enabled!" "$ERR"
			Print_Output true "Open Diversion and use option l to enable logging"
			CHECKSFAILED="true"
		fi
	fi
	
	if ! Firmware_Version_Check; then
		Print_Output true "Unsupported firmware version detected, 384.XX required" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		opkg update
		opkg install grep
		opkg install sqlite3-cli
		opkg install procps-ng-pkill
		opkg install findutils
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz"
	sleep 1
	
	Print_Output true "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output true "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings local
	Create_Symlinks
	
	Update_File uidivstats_www.asp
	Update_File shared-jy.tar.gz
	Update_File taildns.tar.gz
	
	/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
	sleep 5
	Auto_Cron delete 2>/dev/null
	
	renice 15 $$
	Print_Output true "Creating database table and enabling write-ahead logging..." "$PASS"
	{
		echo "PRAGMA journal_mode=WAL;"
		echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Result] Text NOT NULL);"
	}  > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	Print_Output true "Creating database table indexes..." "$PASS"
	echo "DROP INDEX IF EXISTS idx_dns_domains;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_dns_time;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_dns_clients;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_results_clients;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "DROP INDEX IF EXISTS idx_clients_results_domains;" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used in Generate_Stats_From_SQLite for unique clients and Write_Count_PerClient_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_clients ON dnsqueries (SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_time_clients ON dnsqueries (Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_results_time_clients ON dnsqueries (Result collate nocase,Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_clients_time_domains ON dnsqueries (SrcIP,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_clients_results_time_domains ON dnsqueries (SrcIP,Result collate nocase,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	 # used by Write_Count_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_time_domains ON dnsqueries (Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	echo "CREATE INDEX IF NOT EXISTS idx_results_time_domains ON dnsqueries (Result collate nocase,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used by Write_Time_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_results_time ON dnsqueries (Result collate nocase,Timestamp);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	# used by Write_KeyStats_Sql_ToFile and Write_Time_Sql_ToFile
	echo "CREATE INDEX IF NOT EXISTS idx_time_results ON dnsqueries (Timestamp,Result collate nocase);" > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql
	
	rm -f /tmp/uidivstats-upgrade.sql
	Print_Output true "Database ready, starting services..." "$PASS"
	renice 0 $$
	
	Auto_Startup create 2>/dev/null
	Auto_DNSMASQ_Postconf create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	/opt/etc/init.d/S90taildns start >/dev/null 2>&1
	
	Print_Output true "Starting first run of stat generation..." "$PASS"
	Menu_GenerateStats fullrefresh
	
	Clear_Lock
}

Menu_Startup(){
	if [ -z "$1" ]; then
		Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$WARN"
		exit 1
	elif [ "$1" != "force" ]; then
		if [ ! -f "$1/entware/bin/opkg" ]; then
			Print_Output true "$1 does not contain Entware, not starting $SCRIPT_NAME" "$WARN"
			exit 1
		else
			Print_Output true "$1 contains Entware, starting $SCRIPT_NAME" "$WARN"
		fi
	fi
	
	NTP_Ready
	
	Check_Lock
	
	if [ "$1" != "force" ]; then
		sleep 20
	fi
	
	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_DNSMASQ_Postconf create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

Menu_GenerateStats(){
	if /opt/bin/grep -q 'log-facility=/opt/var/log/dnsmasq.log' /etc/dnsmasq.conf; then
		renice 15 $$
		UpdateDiversionWeeklyStatsFile
		Generate_NG "$1"
		renice 0 $$
	else
		Print_Output true "Diversion logging not enabled!" "$ERR"
		Print_Output true "Open Diversion and use option l to enable logging"
	fi
	Clear_Lock
}

Menu_ToggleQueryMode(){
	if [ "$(QueryMode check)" = "all" ]; then
		QueryMode "A+AAAA"
	elif [ "$(QueryMode check)" = "A+AAAA" ]; then
		QueryMode all
	fi
	Clear_Lock
}

Menu_ToggleCacheMode(){
	if [ "$(CacheMode check)" = "none" ]; then
		CacheMode tmp
	elif [ "$(CacheMode check)" = "tmp" ]; then
		CacheMode none
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
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_DNSMASQ_Postconf delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	
	Shortcut_Script delete
	
	Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
	if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		umount /www/require/modules/menuTree.js
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
		rm -rf "{$SCRIPT_WEBPAGE_DIR:?}/$MyPage"
	fi
	rm -f "$SCRIPT_DIR/uidivstats_www.asp" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	
	/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
	sleep 5
	rm -f /opt/etc/init.d/S90taildns 2>/dev/null
	rm -rf "$SCRIPT_DIR/taildns.d" 2>/dev/null
	
	rm -rf "$SCRIPT_DIR" 2>/dev/null
	
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$(nvram get ntp_ready)" -eq 0 ]; then
		ntpwaitcount="0"
		Check_Lock
		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpwaitcount" -lt 300 ]; do
			ntpwaitcount="$((ntpwaitcount + 1))"
			if [ "$ntpwaitcount" -eq 60 ]; then
				Print_Output true "Waiting for NTP to sync..." "$WARN"
			fi
			sleep 1
		done
		if [ "$ntpwaitcount" -ge 300 ]; then
			Print_Output true "NTP failed to sync after 5 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready(){
	if [ ! -f /opt/bin/opkg ]; then
		Check_Lock
		sleepcount=1
		while [ ! -f /opt/bin/opkg ] && [ "$sleepcount" -le 10 ]; do
			Print_Output true "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f /opt/bin/opkg ]; then
			Print_Output true "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}
### ###

if [ -z "$1" ]; then
	NTP_Ready
	Entware_Ready
	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_DNSMASQ_Postconf create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
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
		Menu_Startup "$2"
		exit 0
	;;
	generate)
		NTP_Ready
		Entware_Ready
		Check_Lock
		Menu_GenerateStats
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Check_Lock webui
			Menu_GenerateStats
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}config" ]; then
			Conf_FromSettings
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}checkupdate" ]; then
			Update_Check
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}doupdate" ]; then
			Update_Version force unattended
			exit 0
		fi
		exit 0
	;;
	dnsmasq)
		if grep -q 'log-facility' /etc/dnsmasq.conf; then
			Print_Output true "dnsmasq has restarted, restarting taildns" "$PASS"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 5
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		fi
		exit 0
	;;
	fullrefresh)
		Check_Lock
		Menu_GenerateStats fullrefresh
		exit 0
	;;
	querylog)
		Generate_Query_Log
		exit 0
	;;
	flushtodb)
		Flush_Cache_To_DB
		exit 0
	;;
	trimdb)
		Trim_DNS_DB
		Check_Lock
		Process_Upgrade
		Menu_GenerateStats fullrefresh
		Clear_Lock
		exit 0
	;;
	develop)
		SCRIPT_BRANCH="develop"
		SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	stable)
		SCRIPT_BRANCH="master"
		SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	update)
		Update_Version unattended
		exit 0
	;;
	forceupdate)
		Update_Version force unattended
		exit 0
	;;
	setversion)
		Set_Version_Custom_Settings local
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	checkupdate)
		Update_Check
		exit 0
	;;
	uninstall)
		Menu_Uninstall
		exit 0
	;;
	*)
		echo "Command not recognised, please try again"
		exit 1
	;;
esac
