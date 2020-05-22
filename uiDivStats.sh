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
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
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

Set_Version_Custom_Settings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
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
	doupdate="false"
	localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings "server" "$serverver"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]; then
			doupdate="md5"
			Set_Version_Custom_Settings "server" "$serverver-hotfix"
		fi
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
			Print_Output "true" "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output "true" "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File "shared-jy.tar.gz"
		
		if [ "$isupdate" != "false" ]; then
			Update_File "uidivstats_www.asp"
			Update_File "taildns.tar.gz"
			
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			if [ -z "$1" ]; then
				exec "$0" "setversion"
			elif [ "$1" = "unattended" ]; then
				exec "$0" "setversion" "unattended"
			fi
			exit 0
		else
			Print_Output "true" "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output "true" "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File "uidivstats_www.asp"
		Update_File "shared-jy.tar.gz"
		Update_File "taildns.tar.gz"
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output "true" "$SCRIPT_NAME successfully updated"
		chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0" "setversion"
		elif [ "$2" = "unattended" ]; then
			exec "$0" "setversion" "unattended"
		fi
		exit 0
	fi
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
				/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			fi
			mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
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
					/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
				fi
				mv "$SCRIPT_DIR/taildns.d/S90taildns" /opt/etc/init.d/S90taildns
				/opt/etc/init.d/S90taildns start >/dev/null 2>&1
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
	
	ln -s "$SCRIPT_DIR/SQLData.js" "$SCRIPT_WEB_DIR/SQLData.js" 2>/dev/null
	
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
				STARTUPLINECOUNTEX=$(grep -cx 'if \[ "$(echo "$2" | grep -c "'"$SCRIPT_NAME"'")" -gt 0 \]; then /jffs/scripts/'"$SCRIPT_NAME"' service_event "$1" "$2" & fi # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo 'if [ "$(echo "$2" | grep -c "'"$SCRIPT_NAME"'")" -gt 0 ]; then /jffs/scripts/'"$SCRIPT_NAME"' service_event "$1" "$2" & fi # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo 'if [ "$(echo "$2" | grep -c "'"$SCRIPT_NAME"'")" -gt 0 ]; then /jffs/scripts/'"$SCRIPT_NAME"' service_event "$1" "$2" & fi # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
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
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup &"' # '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup &"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/services-start
				echo "" >> /jffs/scripts/services-start
				echo "/jffs/scripts/$SCRIPT_NAME startup &"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
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
			STARTUPLINECOUNTQUERYLOG=$(cru l | grep -c "$SCRIPT_NAME""_querylog")
			
			if [ "$STARTUPLINECOUNTGENERATE" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_generate" "0 * * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_trim" "3 0 * * * /jffs/scripts/$SCRIPT_NAME trimdb"
			fi
			if [ "$STARTUPLINECOUNTQUERYLOG" -eq 0 ]; then
				cru a "$SCRIPT_NAME""_querylog" "* * * * * /jffs/scripts/$SCRIPT_NAME querylog"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -cx "0 \* \* \* \* /jffs/scripts/$SCRIPT_NAME generate #uiDivStats#")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
			
			STARTUPLINECOUNTGENERATE=$(cru l | grep -c "$SCRIPT_NAME""_generate")
			STARTUPLINECOUNTTRIM=$(cru l | grep -c "$SCRIPT_NAME""_trim")
			STARTUPLINECOUNTQUERYLOG=$(cru l | grep -c "$SCRIPT_NAME""_querylog")
			
			if [ "$STARTUPLINECOUNTGENERATE" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_trim"
			fi
			if [ "$STARTUPLINECOUNTQUERYLOG" -gt 0 ]; then
				cru d "$SCRIPT_NAME""_querylog"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
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
	Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output "true" "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		exit 1
	fi
	Print_Output "true" "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
	cp -f "$SCRIPT_DIR/uidivstats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
	echo "uiDivStats" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
	if [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
		
		if [ ! -f "/tmp/menuTree.js" ]; then
			cp -f "/www/require/modules/menuTree.js" "/tmp/"
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if /bin/grep 'tabName: \"Diversion\"},' /tmp/menuTree.js >/dev/null 2>&1; then
			sed -i "/tabName: \"Diversion\"/a {url: \"$MyPage\", tabName: \"uiDivStats\"}," /tmp/menuTree.js
		else
			sed -i "/url: \"Advanced_SwitchCtrl_Content.asp\", tabName:/a {url: \"$MyPage\", tabName: \"uiDivStats\"}," /tmp/menuTree.js
		fi
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
}

WriteStats_ToJS(){
	{ echo ""; echo "function $3(){"; } >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="$html""$line""\\r\\n"
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
		sed -i -e '/'"$varname"'/d' "$outputfile"
		echo "var $varname = $varvalue;" >> "$outputfile"
	done
}

Write_View_Sql_ToFile(){
	if [ "$6" = "create" ]; then
		timenow="$5"
		echo "CREATE VIEW IF NOT EXISTS [$1$2] AS SELECT * FROM $1 WHERE ([Timestamp] >= $timenow - (86400*$3)) AND ([Timestamp] <= $timenow);" >> "$4"
	elif [ "$6" = "drop" ]; then
		echo "DROP VIEW IF EXISTS [$1$2];" >> "$4"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile $7 timestamp
Write_Count_Sql_ToFile(){
	timenow="$7"
	
	{
		echo ".mode csv"
		echo ".headers on"
		echo ".output $4$5.htm"
	} > "$6"
	
	if [ "$1" = "Total" ]; then
		echo "SELECT '$1' Fieldname, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM $2$5 GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT '$1' Fieldname, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM $2$5 WHERE ([Result] LIKE 'blocked%') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile $7 timestamp
Write_Count_PerClient_Sql_ToFile(){
	timenow="$7"
	echo ".mode list" > "$6"
	echo ".output /tmp/distinctclients" >> "$6"
	if [ "$1" = "Total" ]; then
		echo "SELECT DISTINCT [SrcIP] SrcIP FROM $2$5;" >> "$6"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT DISTINCT [SrcIP] SrcIP FROM $2$5 WHERE ([Result] LIKE 'blocked%');" >> "$6"
	fi
	
	while ! "$SQLITE3_PATH" "$DNS_DB" < "$6" >/dev/null 2>&1; do
		sleep 1
	done
	clients="$(cat /tmp/distinctclients)"
	rm -f /tmp/distinctclients
	
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".output ""$4$5""clients.htm"
	} > "$6"
	
	if [ "$1" = "Total" ]; then
		for client in $clients; do
			echo "SELECT '$1' Fieldname, [SrcIP] SrcIP, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM $2$5 WHERE ([SrcIP] = '$client') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
		done
	elif [ "$1" = "Blocked" ]; then
		for client in $clients; do
			echo "SELECT '$1' Fieldname, [SrcIP] SrcIP, [ReqDmn] ReqDmn, Count([ReqDmn]) Count FROM $2$5 WHERE ([SrcIP] = '$client') AND ([Result] LIKE 'blocked%') GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
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
		echo ".output $5$6""time.htm"
	} > "$7"
	
	if [ "$1" = "Total" ]; then
		echo "SELECT '$1' Fieldname, [Timestamp] Time, COUNT([QueryID]) QueryCount FROM $2$6 GROUP BY ([Timestamp]/($multiplier));" >> "$7"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT '$1' Fieldname, [Timestamp] Time, COUNT([QueryID]) QueryCount FROM $2$6 WHERE ([Result] LIKE 'blocked%') GROUP BY ([Timestamp]/($multiplier));" >> "$7"
	fi
}

Write_KeyStats_Sql_ToFile(){
	timenow="$6"
	
	{
		echo ".headers off"
		echo ".output /tmp/queries$1$3"
	} > "$5"
	
	if [ "$1" = "Total" ]; then
		echo "SELECT COUNT(QueryID) QueryCount FROM [$2$3] WHERE [Timestamp] >= ($timenow - (86400*$4)) AND ([Timestamp] <= $timenow);" >> "$5"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT COUNT(QueryID) QueryCount FROM [$2$3] WHERE [Timestamp] >= ($timenow - (86400*$4)) AND ([Timestamp] <= $timenow) AND [Result] LIKE 'blocked%';" >> "$5"
	fi
}

Generate_NG(){
	TZ=$(cat /etc/TZ)
	export TZ
	
	timenow=$(date +"%s")
	timenowfriendly=$(date +"%c")
	
	rm -f /tmp/uidivstats.sql
	
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Write_View_Sql_ToFile "dnsqueries" "daily" 1 "/tmp/uidivstats.sql" "$timenow" "drop"
		Write_View_Sql_ToFile "dnsqueries" "weekly" 7 "/tmp/uidivstats.sql" "$timenow" "drop"
		Write_View_Sql_ToFile "dnsqueries" "monthly" 30 "/tmp/uidivstats.sql" "$timenow" "drop"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql
	fi
	
	Write_View_Sql_ToFile "dnsqueries" "daily" 1 "/tmp/uidivstats.sql" "$timenow" "create"
	Write_View_Sql_ToFile "dnsqueries" "weekly" 7 "/tmp/uidivstats.sql" "$timenow" "create"
	Write_View_Sql_ToFile "dnsqueries" "monthly" 30 "/tmp/uidivstats.sql" "$timenow" "create"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql
	
	Generate_Count_Blocklist_Domains
	
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Generate_KeyStats "$timenow" "fullrefresh"
		Generate_Stats_From_SQLite "$timenow" "fullrefresh"
	else
		Generate_KeyStats "$timenow"
		Generate_Stats_From_SQLite "$timenow"
	fi
	
	echo "Stats last updated: $timenowfriendly" > "/tmp/uidivstatstitle.txt"
	WriteStats_ToJS "/tmp/uidivstatstitle.txt" "$SCRIPT_DIR/SQLData.js" "SetuiDivStatsTitle" "statstitle"
	Print_Output "false" "Stats updated successfully" "$PASS"
	rm -f "/tmpuidivstatstitle.txt"
}

Generate_Query_Log(){
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".separator '|'"
		echo ".output $CSV_OUTPUT_DIR/SQLQueryLog.htm"
		echo "SELECT [Timestamp] Time, [ReqDmn] ReqDmn, [SrcIP] SrcIP, [QryType] QryType, [Result] Result FROM [dnsqueries] ORDER BY [Timestamp] DESC LIMIT 5000;"
	} > /tmp/uidivstats-query.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-query.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-query.sql
}

Generate_KeyStats(){
	timenow="$1"
	
	#daily
	Write_KeyStats_Sql_ToFile "Total" "dnsqueries" "daily" 1 "/tmp/uidivstats.sql" "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	
	Write_KeyStats_Sql_ToFile "Blocked" "dnsqueries" "daily" 1 "/tmp/uidivstats.sql" "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	
	queriesTotaldaily="$(cat "/tmp/queriesTotaldaily")"
	queriesBlockeddaily="$(cat "/tmp/queriesBlockeddaily")"
	queriesPercentagedaily="$(echo "$queriesBlockeddaily" "$queriesTotaldaily" | awk '{printf "%3.2f\n",$1/$2*100}')"
	
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotaldaily,$queriesTotaldaily" "QueriesBlockeddaily,$queriesBlockeddaily" "BlockedPercentagedaily,$queriesPercentagedaily"
	
	#weekly
	if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
		Write_KeyStats_Sql_ToFile "Total" "dnsqueries" "weekly" 7 "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		Write_KeyStats_Sql_ToFile "Blocked" "dnsqueries" "weekly" 7 "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		queriesTotalweekly="$(cat "/tmp/queriesTotalweekly")"
		queriesBlockedweekly="$(cat "/tmp/queriesBlockedweekly")"
		queriesPercentageweekly="$(echo "$queriesBlockedweekly" "$queriesTotalweekly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		
		WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotalweekly,$queriesTotalweekly" "QueriesBlockedweekly,$queriesBlockedweekly" "BlockedPercentageweekly,$queriesPercentageweekly"
	fi

	#monthly
	if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
		Write_KeyStats_Sql_ToFile "Total" "dnsqueries" "monthly" 30 "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		Write_KeyStats_Sql_ToFile "Blocked" "dnsqueries" "monthly" 30 "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		queriesTotalmonthly="$(cat "/tmp/queriesTotalmonthly")"
		queriesBlockedmonthly="$(cat "/tmp/queriesBlockedmonthly")"
		queriesPercentagemonthly="$(echo "$queriesBlockedmonthly" "$queriesTotalmonthly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		
		WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "QueriesTotalmonthly,$queriesTotalmonthly" "QueriesBlockedmonthly,$queriesBlockedmonthly" "BlockedPercentagemonthly,$queriesPercentagemonthly"
	fi
	
	rm -f /tmp/queriesTotal*
	rm -f /tmp/queriesBlocked*
}

Generate_Count_Blocklist_Domains(){
	blockinglistfile="$DIVERSION_DIR/list/blockinglist"
	blacklistfile="$DIVERSION_DIR/list/blacklist"
	blacklistwcfile="$DIVERSION_DIR/list/wc_blacklist"
	
	BLL="$(($(/opt/bin/grep "^[^#]" "$blockinglistfile" | wc -w)-$(/opt/bin/grep "^[^#]" "$blockinglistfile" | wc -l)))"
	[ "$(nvram get ipv6_service)" != "disabled" ] && BLL="$((BLL/2))"
	BL="$(/opt/bin/grep "^[^#]" "$blacklistfile" | wc -l)"
	[ "$(nvram get ipv6_service)" != "disabled" ] && BL="$((BL/2))"
	WCBL="$(/opt/bin/grep "^[^#]" "$blacklistwcfile" | wc -l)"
	blocklistdomains="$((BLL+BL+WCBL))"
	WritePlainData_ToJS "$SCRIPT_DIR/SQLData.js" "BlockedDomains,$blocklistdomains"
}

Generate_Stats_From_SQLite(){
	timenow="$1"
	
	metriclist="Total Blocked"
	
	for metric in $metriclist; do
		
		#daily
		Write_Time_Sql_ToFile "$metric" "dnsqueries" 0.25 1 "$CSV_OUTPUT_DIR/$metric" "daily" "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		Write_Count_Sql_ToFile "$metric" "dnsqueries" 1 "$CSV_OUTPUT_DIR/$metric" "daily" "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		
		Write_Count_PerClient_Sql_ToFile "$metric" "dnsqueries" 1 "$CSV_OUTPUT_DIR/$metric" "daily" "/tmp/uidivstats.sql" "$timenow"
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/$metric""dailyclients.htm"
		
		cat "$CSV_OUTPUT_DIR/Totaldailytime.htm" "$CSV_OUTPUT_DIR/Blockeddailytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm" 2> /dev/null
		sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm"
		
		#weekly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" "dnsqueries" 1 7 "$CSV_OUTPUT_DIR/$metric" "weekly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			
			Write_Count_Sql_ToFile "$metric" "dnsqueries" 7 "$CSV_OUTPUT_DIR/$metric" "weekly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			
			Write_Count_PerClient_Sql_ToFile "$metric" "dnsqueries" 7 "$CSV_OUTPUT_DIR/$metric" "weekly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/$metric""weeklyclients.htm"
			
			cat "$CSV_OUTPUT_DIR/Totalweeklytime.htm" "$CSV_OUTPUT_DIR/Blockedweeklytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm"
		fi
		
		#monthly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" "dnsqueries" 3 30 "$CSV_OUTPUT_DIR/$metric" "monthly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
					
			Write_Count_Sql_ToFile "$metric" "dnsqueries" 30 "$CSV_OUTPUT_DIR/$metric" "monthly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			
			Write_Count_PerClient_Sql_ToFile "$metric" "dnsqueries" 30 "$CSV_OUTPUT_DIR/$metric" "monthly" "/tmp/uidivstats.sql" "$timenow"
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/$metric""monthlyclients.htm"
			
			cat "$CSV_OUTPUT_DIR/Totalmonthlytime.htm" "$CSV_OUTPUT_DIR/Blockedmonthlytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm"
		fi
	done
	
	rm -f /tmp/uidivstats.sql
	Write_View_Sql_ToFile "dnsqueries" "daily" 1 "/tmp/uidivstats.sql" "$timenow" "drop"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql
}

Trim_DNS_DB(){
	TZ=$(cat /etc/TZ)
	export TZ
	timenow=$(date +"%s")
	
	{
		echo "DELETE FROM [dnsqueries] WHERE [Timestamp] < ($timenow - (86400*30));"
	} > /tmp/uidivstats-trim.sql
	
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql
	
	Write_View_Sql_ToFile "dnsqueries" "weekly" 7 "/tmp/uidivstats-trim.sql" "$timenow" "drop"
	Write_View_Sql_ToFile "dnsqueries" "monthly" 30 "/tmp/uidivstats-trim.sql" "$timenow" "drop"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql
}

Process_Upgrade(){
	if [ ! -f "$SCRIPT_DIR/.upgraded" ]; then
		opkg update
		opkg install grep
		opkg install sqlite3-cli
		opkg install procps-ng-pkill
		Update_File "taildns.tar.gz"
		/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
		{
			echo "PRAGMA journal_mode=WAL;"
			echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL, [Timestamp] NUMERIC NOT NULL, [SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Result] Text NOT NULL);"
			echo "create index idx_dns on dnsqueries (Timestamp,ReqDmn,Result);"
			echo "create index idx_dns_clients on dnsqueries (Timestamp,ReqDmn,SrcIP,Result);"
		}  > /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql
		/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		touch "$SCRIPT_DIR/.upgraded"
	fi
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
	printf "1.    Update Diversion Statistics (daily only)\\n\\n"
	printf "2.    Update Diversion Statistics (daily, weekly and monthly)\\n"
	printf "      WARNING: THIS WILL TAKE A WHILE\\n\\n"
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
			2)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_GenerateStats "fullrefresh"
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
		opkg install procps-ng-pkill
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
	
	Process_Upgrade
	/opt/etc/init.d/S90taildns start >/dev/null 2>&1
	
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
		Generate_NG "$1"
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
	rm -f "/opt/etc/init.d/S90taildns" 2>/dev/null
	rm -rf "$SCRIPT_DIR/taildns.d" 2>/dev/null
	
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$1" = "service_event" ]; then
		if [ -n "$2" ] && [ "$(echo "$3" | grep -c "$SCRIPT_NAME")" -eq 0 ]; then
			exit 0
		fi
	fi
	if [ "$(nvram get ntp_ready)" = "0" ]; then
		ntpwaitcount="0"
		Check_Lock
		while [ "$(nvram get ntp_ready)" = "0" ] && [ "$ntpwaitcount" -lt "300" ]; do
			ntpwaitcount="$((ntpwaitcount + 1))"
			if [ "$ntpwaitcount" = "60" ]; then
				Print_Output "true" "Waiting for NTP to sync..." "$WARN"
			fi
			sleep 1
		done
		if [ "$ntpwaitcount" -ge "300" ]; then
			Print_Output "true" "NTP failed to sync after 5 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output "true" "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready(){
	if [ "$1" = "service_event" ]; then
		if [ -n "$2" ] && [ "$(echo "$3" | grep -c "$SCRIPT_NAME")" -eq 0 ]; then
			exit 0
		fi
	fi
	
	if [ ! -f "/opt/bin/opkg" ] && ! echo "$@" | grep -wqE "(install|uninstall|update|forceupdate)"; then
		Check_Lock
		sleepcount=1
		while [ ! -f "/opt/bin/opkg" ] && [ "$sleepcount" -le 10 ]; do
			Print_Output "true" "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f "/opt/bin/opkg" ]; then
			Print_Output "true" "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output "true" "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}
### ###

NTP_Ready "$@"
Entware_Ready "$@"

if [ -z "$1" ]; then
	Create_Dirs
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Process_Upgrade
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
		sleep 4
		Menu_Startup
		exit 0
	;;
	generate)
		Check_Lock
		Menu_GenerateStats
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Check_Lock
			Menu_GenerateStats
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME""checkupdate" ]; then
			Check_Lock
			updatecheckresult="$(Update_Check)"
			Clear_Lock
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME""doupdate" ]; then
			Check_Lock
			Update_Version "force" "unattended"
			Clear_Lock
			exit 0
		fi
		exit 0
	;;
	fullrefresh)
		Check_Lock
		Menu_GenerateStats "fullrefresh"
		exit 0
	;;
	querylog)
		Generate_Query_Log
		exit 0
	;;
	trimdb)
		Trim_DNS_DB
		exit 0
	;;
	develop)
		Check_Lock
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="develop"/' "/jffs/scripts/$SCRIPT_NAME"
		Clear_Lock
		exec "$0" "update"
		exit 0
	;;
	stable)
		Check_Lock
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="master"/' "/jffs/scripts/$SCRIPT_NAME"
		Clear_Lock
		exec "$0" "update"
		exit 0
	;;
	update)
		Check_Lock
		Menu_Update
		Update_Version "unattended"
		Clear_Lock
		exit 0
	;;
	forceupdate)
		Check_Lock
		Menu_ForceUpdate
		Update_Version "force" "unattended"
		Clear_Lock
		exit 0
	;;
	setversion)
		Check_Lock
		Set_Version_Custom_Settings "local"
		Set_Version_Custom_Settings "server" "$SCRIPT_VERSION"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	checkupdate)
		Check_Lock
		#shellcheck disable=SC2034
		updatecheckresult="$(Update_Check)"
		Clear_Lock
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
