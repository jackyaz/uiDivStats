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

#################        Shellcheck directives      ###############
# shellcheck disable=SC2009
# shellcheck disable=SC2012
# shellcheck disable=SC2016
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2059
# shellcheck disable=SC2086
# shellcheck disable=SC2155
###################################################################

### Start of script variables ###
readonly SCRIPT_NAME="uiDivStats"
readonly SCRIPT_VERSION="v3.1.0"
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
SQLITE3_PATH="/opt/bin/sqlite3"
readonly DIVERSION_DIR="/opt/share/diversion"
readonly STATSEXCLUDE_LIST_FILE="$SCRIPT_DIR/statsexcludelist"
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
readonly BOLD="\\e[1m"
readonly SETTING="${BOLD}\\e[36m"
readonly CLEARFORMAT="\\e[0m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
	fi
	printf "${BOLD}${3}%s${CLEARFORMAT}\\n\\n" "$2"
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
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "uidivstats_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "uidivstats_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/uidivstats_version_local.*/uidivstats_version_local $2/" "$SETTINGSFILE"
					fi
				else
					echo "uidivstats_version_local $2" >> "$SETTINGSFILE"
				fi
			else
				echo "uidivstats_version_local $2" >> "$SETTINGSFILE"
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
	localver=$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
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
	if [ -z "$1" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"

		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - hotfix available - $serverver" "$PASS"
		fi


		if [ "$isupdate" != "false" ]; then
			printf "\\n${BOLD}Do you want to continue with the update? (y/n)${CLEARFORMAT}  "
			read -r confirm
			case "$confirm" in
				y|Y)
					printf "\\n"
					Update_File uidivstats_www.asp
					Update_File taildns.tar.gz
					Update_File shared-jy.tar.gz

					/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
					chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
					Set_Version_Custom_Settings local "$serverver"
					Set_Version_Custom_Settings server "$serverver"
					Clear_Lock
					PressEnter
					exec "$0"
					exit 0
				;;
				*)
					printf "\\n"
					Clear_Lock
					return 1
				;;
			esac
		else
			Print_Output true "No updates available - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi

	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File uidivstats_www.asp
		Update_File taildns.tar.gz
		Update_File shared-jy.tar.gz
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
		chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
		Set_Version_Custom_Settings local "$serverver"
		Set_Version_Custom_Settings server "$serverver"
		Clear_Lock
		if [ -z "$2" ]; then
			PressEnter
			exec "$0"
		elif [ "$2" = "unattended" ]; then
			exec "$0" postupdate
		fi
		exit 0
	fi
}

Update_File(){
	if [ "$1" = "uidivstats_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if [ -f "$SCRIPT_DIR/$1" ]; then
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyPage~d" /tmp/menuTree.js
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage" 2>/dev/null
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
				Mount_WebUI
			fi
		else
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
				sleep 3
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
					sleep 3
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
				if [ "$SETTINGNAME" = "DOMAINSTOEXCLUDE" ]; then
					echo "$SETTINGVALUE" | sed 's~||||~\n~g' > "$STATSEXCLUDE_LIST_FILE"
					awk 'NF' "$STATSEXCLUDE_LIST_FILE" > "$STATSEXCLUDE_LIST_FILE.tmp"
					mv "$STATSEXCLUDE_LIST_FILE.tmp" "$STATSEXCLUDE_LIST_FILE"
				else
					sed -i "s/$SETTINGNAME=.*/$SETTINGNAME=$SETTINGVALUE/" "$SCRIPT_CONF"
				fi
			done < "$TMPFILE"
			grep 'uidivstats_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~uidivstats_~d" "$SETTINGSFILE"
			mv "$SETTINGSFILE" "$SETTINGSFILE.bak"
			cat "$SETTINGSFILE.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "$SETTINGSFILE.bak"

			QueryMode "$(QueryMode check)"
			sleep 3
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

	if [ ! -f "$STATSEXCLUDE_LIST_FILE" ]; then
		touch "$STATSEXCLUDE_LIST_FILE"
	fi
}

Create_Symlinks(){
	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null

	ln -s /tmp/detect_uidivstats.js "$SCRIPT_WEB_DIR/detect_uidivstats.js" 2>/dev/null
	ln -s "$SCRIPT_USB_DIR/SQLData.js" "$SCRIPT_WEB_DIR/SQLData.js" 2>/dev/null
	ln -s "$SCRIPT_CONF" "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	ln -s "$STATSEXCLUDE_LIST_FILE" "$SCRIPT_WEB_DIR/domainstoexclude.htm"

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
		if ! grep -q "DAYSTOKEEP" "$SCRIPT_CONF"; then
			echo "DAYSTOKEEP=30" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "LASTXQUERIES" "$SCRIPT_CONF"; then
			echo "LASTXQUERIES=5000" >> "$SCRIPT_CONF"
		fi
		sed -i -e 's/QUERYMODE=A+AAAA$/QUERYMODE=A+AAAA+HTTPS/g' "$SCRIPT_CONF"
		return 0
	else
		{ echo "QUERYMODE=all"; echo "CACHEMODE=tmp"; echo "DAYSTOKEEP=30"; echo "LASTXQUERIES=5000"; } > "$SCRIPT_CONF"
		return 1
	fi
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				STARTUPLINECOUNTEX=$(grep -cx 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { /jffs/scripts/'"$SCRIPT_NAME"' service_event "$@" & }; fi # '"$SCRIPT_NAME" /jffs/scripts/service-event)

				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi

				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { /jffs/scripts/'"$SCRIPT_NAME"' service_event "$@" & }; fi # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME"'"; then { /jffs/scripts/'"$SCRIPT_NAME"' service_event "$@" & }; fi # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
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

			STARTUPLINECOUNTEXGENERATE=$(cru l | grep "${SCRIPT_NAME}_generate" | grep -c "1-23" )
			if [ "$STARTUPLINECOUNTGENERATE" -ne 0 ] && [ "$STARTUPLINECOUNTEXGENERATE" -eq 0 ]; then
				cru d "${SCRIPT_NAME}_generate"
			fi

			STARTUPLINECOUNTEXTRIM=$(cru l | grep "${SCRIPT_NAME}_trim" | grep -c "1" )
			if [ "$STARTUPLINECOUNTTRIM" -ne 0 ] && [ "$STARTUPLINECOUNTEXTRIM" -eq 0 ]; then
				cru d "${SCRIPT_NAME}_trim"
			fi

			STARTUPLINECOUNTEXFLUSHTODB=$(cru l | grep "${SCRIPT_NAME}_flushtodb" | grep -c "4-59/5" )
			if [ "$STARTUPLINECOUNTFLUSHTODB" -ne 0 ] && [ "$STARTUPLINECOUNTEXFLUSHTODB" -eq 0 ]; then
				cru d "${SCRIPT_NAME}_flushtodb"
			fi

			if [ "$STARTUPLINECOUNTGENERATE" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_generate" "0 1-23 * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_trim" "1 0 * * * /jffs/scripts/$SCRIPT_NAME trimdb"
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
			if [ "$STARTUPLINECOUNTFLUSHTODB" -gt 0 ]; then
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

### function based on @dave14305's FlexQoS webconfigpage function ###
Get_WebUI_URL(){
	urlpage=""
	urlproto=""
	urldomain=""
	urlport=""

	urlpage="$(sed -nE "/$SCRIPT_NAME/ s/.*url\: \"(user[0-9]+\.asp)\".*/\1/p" /tmp/menuTree.js)"
	if [ "$(nvram get http_enable)" -eq 1 ]; then
		urlproto="https"
	else
		urlproto="http"
	fi
	if [ -n "$(nvram get lan_domain)" ]; then
		urldomain="$(nvram get lan_hostname).$(nvram get lan_domain)"
	else
		urldomain="$(nvram get lan_ipaddr)"
	fi
	if [ "$(nvram get ${urlproto}_lanport)" -eq 80 ] || [ "$(nvram get ${urlproto}_lanport)" -eq 443 ]; then
		urlport=""
	else
		urlport=":$(nvram get ${urlproto}_lanport)"
	fi

	if echo "$urlpage" | grep -qE "user[0-9]+\.asp"; then
		echo "${urlproto}://${urldomain}${urlport}/${urlpage}" | tr "A-Z" "a-z"
	else
		echo "WebUI page not found"
	fi
}
### ###

Mount_WebUI(){
	Print_Output true "Mounting WebUI tab for $SCRIPT_NAME" "$PASS"
	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"
	Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output true "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		Clear_Lock
		exit 1
	fi
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
	flock -u "$FD"
	Print_Output true "Mounted $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
}

QueryMode(){
	case "$1" in
		all)
			sed -i 's/^QUERYMODE.*$/QUERYMODE=all/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 3
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		A+AAAA+HTTPS)
			sed -i 's/^QUERYMODE.*$/QUERYMODE=A+AAAA+HTTPS/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 3
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
			sleep 3
			Flush_Cache_To_DB
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		tmp)
			sed -i 's/^CACHEMODE.*$/CACHEMODE=tmp/' "$SCRIPT_CONF"
			/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
			sleep 3
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		;;
		check)
			CACHEMODE="$(grep "CACHEMODE" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "$CACHEMODE"
		;;
	esac
}

DaysToKeep(){
	case "$1" in
		update)
			daystokeep=30
			exitmenu=""
			ScriptHeader
			while true; do
				printf "\\n${BOLD}Please enter the desired number of days\\nto keep data for (1-365 days):${CLEARFORMAT}  "
				read -r daystokeep_choice

				if [ "$daystokeep_choice" = "e" ]; then
					exitmenu="exit"
					break
				elif ! Validate_Number "$daystokeep_choice"; then
					printf "\\n${ERR}Please enter a valid number (1-365)${CLEARFORMAT}\\n"
				elif [ "$daystokeep_choice" -lt 1 ] || [ "$daystokeep_choice" -gt 365 ]; then
						printf "\\n${ERR}Please enter a number between 1 and 365${CLEARFORMAT}\\n"
				else
					daystokeep="$daystokeep_choice"
					printf "\\n"
					break
				fi
			done

			if [ "$exitmenu" != "exit" ]; then
				sed -i 's/^DAYSTOKEEP.*$/DAYSTOKEEP='"$daystokeep"'/' "$SCRIPT_CONF"
				return 0
			else
				printf "\\n"
				return 1
			fi
		;;
		check)
			DAYSTOKEEP=$(grep "DAYSTOKEEP" "$SCRIPT_CONF" | cut -f2 -d"=")
			echo "$DAYSTOKEEP"
		;;
	esac
}

LastXQueries(){
	case "$1" in
		update)
			lastxquerieds=10
			exitmenu=""
			ScriptHeader
			while true; do
				printf "\\n${BOLD}Please enter the desired number of queries\\nto display in the WebUI (10-10000):${CLEARFORMAT}  "
				read -r lastx_choice

				if [ "$lastx_choice" = "e" ]; then
					exitmenu="exit"
					break
				elif ! Validate_Number "$lastx_choice"; then
					printf "\\n${ERR}Please enter a valid number (10-10000)${CLEARFORMAT}\\n"
				elif [ "$lastx_choice" -lt 10 ] || [ "$lastx_choice" -gt 10000 ]; then
						printf "\\n${ERR}Please enter a number between 10 and 10000${CLEARFORMAT}\\n"
				else
					lastxquerieds="$lastx_choice"
					printf "\\n"
					break
				fi
			done

			if [ "$exitmenu" != "exit" ]; then
				sed -i 's/^LASTXQUERIES.*$/LASTXQUERIES='"$lastxquerieds"'/' "$SCRIPT_CONF"
				Generate_Query_Log
				return 0
			else
				printf "\\n"
				return 1
			fi
		;;
		check)
			LASTXQUERIES=$(grep "LASTXQUERIES" "$SCRIPT_CONF" | cut -f2 -d"=")
			echo "$LASTXQUERIES"
		;;
	esac
}

UpdateDiversionWeeklyStatsFile(){
	rm -f "$SCRIPT_WEB_DIR/DiversionStats.htm" 2>/dev/null
	diversionstatsfile="$(/opt/bin/find /opt/share/diversion/stats -name "Diversion_Stats*" -printf "%C@ %p\n"| sort | tail -n 1 | cut -f2 -d' ')"
	ln -s "$diversionstatsfile" "$SCRIPT_WEB_DIR/DiversionStats.htm" 2>/dev/null
}

WriteStats_ToJS(){
	sed -i -e '/}/d;/function/d;/document.getElementById/d;' "$2"
	awk 'NF' "$2" > "$2.tmp"
	mv "$2.tmp" "$2"
	printf "\\r\\nfunction %s(){" "$3" >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="${html}${line}"
	done < "$1"
	html="$html"'"'
	printf "%s;}\\r\\n" "$html" >> "$2"
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

Table_Indexes(){
	case "$1" in
		create)
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_clients ON dnsqueries (SrcIP);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_time_clients ON dnsqueries (Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_allowed_time_clients ON dnsqueries (Allowed,Timestamp,SrcIP);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_clients_time_domains ON dnsqueries (SrcIP,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_clients_allowed_time_domains ON dnsqueries (SrcIP,Allowed,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_time_domains ON dnsqueries (Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_allowed_time_domains ON dnsqueries (Allowed,Timestamp,ReqDmn);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_allowed_time ON dnsqueries (Allowed,Timestamp);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
			echo "PRAGMA cache_size=-20000; CREATE INDEX IF NOT EXISTS idx_time_allowed ON dnsqueries (Timestamp,Allowed);" > /tmp/uidivstats-upgrade.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
				sleep 1
			done
		;;
		drop)
			true;
		;;
	esac
}

# $1 create/drop $2 tablename $3 frequency (hours) $4 outputfrequency
TempTime_Table(){
	case "$1" in
		create)
			multiplier="$(echo "$3" | awk '{printf (60*60*$1)}')"

			{
				echo ".headers off"
				echo ".output /tmp/timesmin"
				echo "SELECT CAST(MIN([Timestamp])/$multiplier AS INT)*$multiplier FROM ${2}${4};"
				echo ".headers off"
				echo ".output /tmp/timesmax"
				echo "SELECT CAST(MAX([Timestamp])/$multiplier AS INT)*$multiplier FROM ${2}${4};"
			} > /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done

			timesmin="$(cat /tmp/timesmin)"
			timesmax="$(cat /tmp/timesmax)"
			rm -f /tmp/timesmin
			rm -f /tmp/timesmax

			if ! Validate_Number "$timesmin"; then timesmin=0; fi
			if ! Validate_Number "$timesmax"; then timesmax=0; fi

			{
				echo "CREATE TABLE IF NOT EXISTS temp_timerange_$4 AS"
				echo "WITH RECURSIVE c(x) AS("
				echo "VALUES($timesmin)"
				echo "UNION ALL"
				echo "SELECT x+$multiplier FROM c WHERE x<$timesmax"
				echo ") SELECT x FROM c;"
			} > /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			rm -f /tmp/uidivstats.sql
			;;
		drop)
			echo "DROP TABLE IF EXISTS temp_timerange_$2;" > /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			rm -f /tmp/uidivstats.sql
		;;
	esac
}

Write_View_Sql_ToFile(){
	if [ "$1" = "create" ]; then
		timenow="$6"
		echo "CREATE VIEW IF NOT EXISTS ${2}${3} AS SELECT * FROM $2 WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-$4 day'))) AND ([Timestamp] <= $timenow);" > "$5"
	elif [ "$1" = "drop" ]; then
		echo "DROP VIEW IF EXISTS ${2}${3};" > "$4"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile
Write_Count_Sql_ToFile(){
	{
		echo ".mode csv"
		echo ".headers on"
		echo ".output ${4}${5}.htm"
	} > "$6"

	wherestring=""
	while IFS='' read -r line || [ -n "$line" ]; do
		if [ -n "$line" ]; then
			domain="$(echo "$line" | sed 's/\*/%/g')"
			wherestring="$wherestring AND [ReqDmn] NOT LIKE '$domain'"
		fi
	done < "$STATSEXCLUDE_LIST_FILE"

	if [ "$1" = "Total" ]; then
		wherestring="$(echo "$wherestring" | sed 's/AND/WHERE/')"
	fi

	if [ "$1" = "Total" ]; then
		echo "SELECT '$1' Fieldname,[ReqDmn] ReqDmn,Count([ReqDmn]) Count FROM ${2}${5} $wherestring GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT '$1' Fieldname,[ReqDmn] ReqDmn,Count([ReqDmn]) Count FROM ${2}${5} WHERE NOT [Allowed] $wherestring GROUP BY [ReqDmn] ORDER BY COUNT([ReqDmn]) DESC LIMIT 20;" >> "$6"
	fi
}

#$1 fieldname $2 tablename $3 length (days) $4 outputfile $5 outputfrequency $6 sqlfile
Write_Count_PerClient_Sql_ToFile(){
	{
		echo ".mode csv"
		echo ".headers off"
		echo ".output ${4}${5}clients.htm"
	} > "$6"

	wherestring=""
	while IFS='' read -r line || [ -n "$line" ]; do
		if [ -n "$line" ]; then
			domain="$(echo "$line" | sed 's/\*/%/g')"
			wherestring="$wherestring AND [ReqDmn] NOT LIKE '$domain'"
		fi
	done < "$STATSEXCLUDE_LIST_FILE"

	if [ "$1" = "Total" ]; then
		{
			echo "SELECT '$1' Fieldname,SrcIP,ReqDmn,Count FROM"
			echo "(SELECT [SrcIP] SrcIP,[ReqDmn] ReqDmn,Count([ReqDmn]) Count,ROW_NUMBER() OVER (PARTITION BY [SrcIP] ORDER BY Count(*) DESC) rn"
			echo "FROM ${2}${5} WHERE [SrcIP] IN (SELECT DISTINCT [SrcIP] SrcIP FROM ${2}${5}) $wherestring"
			echo "GROUP BY [SrcIP],[ReqDmn]) WHERE rn <=20 ORDER BY SrcIP,Count DESC;"
		} >> "$6"
	elif [ "$1" = "Blocked" ]; then
		{
			echo "SELECT '$1' Fieldname,SrcIP,ReqDmn,Count FROM"
			echo "(SELECT [SrcIP] SrcIP,[ReqDmn] ReqDmn,Count([ReqDmn]) Count,ROW_NUMBER() OVER (PARTITION BY [SrcIP] ORDER BY Count(*) DESC) rn"
			echo "FROM ${2}${5} WHERE [SrcIP] IN (SELECT DISTINCT [SrcIP] SrcIP FROM ${2}${5}) AND NOT [Allowed] $wherestring"
			echo "GROUP BY [SrcIP],[ReqDmn]) WHERE rn <=20 ORDER BY SrcIP,Count DESC;"
		} >> "$6"
	fi
}

#$1 fieldname $2 tablename $3 frequency (hours) $4 length (days) $5 outputfile $6 outputfrequency $7 sqlfile
Write_Time_Sql_ToFile(){
	multiplier="$(echo "$3" | awk '{printf (60*60*$1)}')"

	{
		echo ".mode csv"
		echo ".headers off"
		echo ".output ${5}${6}time.htm"
	} > "$7"

	if [ "$1" = "Total" ]; then
		echo "SELECT '$1' Fieldname,series.x Time,IFNULL(data.QueryCount2,0) QueryCount FROM (SELECT x FROM temp_timerange_$6) series LEFT JOIN (SELECT '$1' Fieldname,CAST([Timestamp]/$multiplier AS INT)*$multiplier Time2,COUNT([QueryID]) QueryCount2 FROM ${2}${6} GROUP BY Time2) data on series.x = data.Time2;" >> "$7"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT '$1' Fieldname,series.x Time,IFNULL(data.QueryCount2,0) QueryCount FROM (SELECT x FROM temp_timerange_$6) series LEFT JOIN (SELECT '$1' Fieldname,CAST([Timestamp]/$multiplier AS INT)*$multiplier Time2,COUNT([QueryID]) QueryCount2 FROM ${2}${6} WHERE NOT [Allowed] GROUP BY Time2) data on series.x = data.Time2;" >> "$7"
	fi
}

Write_KeyStats_Sql_ToFile(){
	{
		echo ".headers off"
		echo ".output /tmp/queries${1}${3}"
	} > "$4"

	if [ "$1" = "Total" ]; then
		echo "SELECT COUNT([QueryID]) QueryCount FROM ${2}${3};" >> "$4"
	elif [ "$1" = "Blocked" ]; then
		echo "SELECT COUNT([QueryID]) QueryCount FROM ${2}${3} WHERE NOT [Allowed];" >> "$4"
	fi
}

Generate_NG(){
	TZ=$(cat /etc/TZ)
	export TZ

	timenow=$(date +"%s")
	timenowfriendly=$(date +"%c")

	rm -f /tmp/uidivstats.sql

	{
		echo "PRAGMA cache_size=-20000; BEGIN TRANSACTION;"
		echo "DELETE FROM [dnsqueries] WHERE [Timestamp] > $timenow;"
		echo "DELETE FROM [dnsqueries] WHERE [SrcIP] = 'from';"
		echo "END TRANSACTION;"
	} > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql

	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Write_View_Sql_ToFile drop dnsqueries daily /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_View_Sql_ToFile drop dnsqueries weekly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_View_Sql_ToFile drop dnsqueries monthly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql
	fi

	Write_View_Sql_ToFile create dnsqueries daily 1 /tmp/uidivstats.sql "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile create dnsqueries weekly 7 /tmp/uidivstats.sql "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile create dnsqueries monthly 30 /tmp/uidivstats.sql "$timenow"
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql

	TempTime_Table create dnsqueries 0.25 daily
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		TempTime_Table create dnsqueries 1 weekly
		TempTime_Table create dnsqueries 3 monthly
	fi

	Generate_Count_Blocklist_Domains

	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		Generate_KeyStats "$timenow" fullrefresh
		Generate_Stats_From_SQLite "$timenow" fullrefresh
	else
		Generate_KeyStats "$timenow"
		Generate_Stats_From_SQLite "$timenow"
	fi

	TempTime_Table drop daily
	if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
		TempTime_Table drop weekly
		TempTime_Table drop monthly
	fi

	echo "Stats last updated: $timenowfriendly" > /tmp/uidivstatstitle.txt
	WriteStats_ToJS /tmp/uidivstatstitle.txt "$SCRIPT_USB_DIR/SQLData.js" SetuiDivStatsTitle statstitle
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

	recordcount="$(LastXQueries check)"
	if [ "$(CacheMode check)" = "tmp" ]; then
		if [ -f /tmp/cache-uiDivStats-SQL.tmp ]; then
			tail -n "$recordcount" /tmp/cache-uiDivStats-SQL.tmp | sort -s -k 1,1 -n -r | sed 's/,/|/g' | awk 'BEGIN{FS=OFS="|"} {t=$2; $2=$3; $3=t; print}' > /tmp/cache-uiDivStats-SQL.tmp.ordered
			recordcount="$((recordcount - $(wc -l < /tmp/cache-uiDivStats-SQL.tmp.ordered)))"
			if [ "$(echo "$recordcount 0" | awk '{print ($1 < $2)}')" -eq 1 ]; then
				recordcount=0
			fi
		fi
	fi

	if [ "$recordcount" -gt 0 ]; then
		{
			echo ".mode csv"
			echo ".headers off"
			echo ".separator '|'"
			echo ".output $CSV_OUTPUT_DIR/SQLQueryLog.tmp"
			echo "SELECT [Timestamp] Time,[ReqDmn] ReqDmn,[SrcIP] SrcIP,[QryType] QryType,[Allowed] Allowed FROM [dnsqueries] ORDER BY [Timestamp] DESC LIMIT $recordcount;"
		} > /tmp/uidivstats-query.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-query.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats-query.sql

		cat /tmp/cache-uiDivStats-SQL.tmp.ordered "$CSV_OUTPUT_DIR/SQLQueryLog.tmp" > "$CSV_OUTPUT_DIR/SQLQueryLog.htm" 2> /dev/null
	else
		mv /tmp/cache-uiDivStats-SQL.tmp.ordered "$CSV_OUTPUT_DIR/SQLQueryLog.htm"
	fi
	rm -f /tmp/cache-uiDivStats-SQL.tmp.ordered
	rm -f "$CSV_OUTPUT_DIR/SQLQueryLog.tmp"
}

Generate_KeyStats(){
	timenow="$1"

	#daily
	Write_KeyStats_Sql_ToFile Total dnsqueries daily /tmp/uidivstats.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_KeyStats_Sql_ToFile Blocked dnsqueries daily /tmp/uidivstats.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql

	queriesTotaldaily="$(cat /tmp/queriesTotaldaily)"
	queriesBlockeddaily="$(cat /tmp/queriesBlockeddaily)"

	if ! Validate_Number "$queriesTotaldaily"; then queriesTotaldaily=0; fi
	if ! Validate_Number "$queriesBlockeddaily"; then queriesBlockeddaily=0; fi
	if [ "$queriesTotaldaily" -eq 0 ]; then
		queriesPercentagedaily=0
	else
		queriesPercentagedaily="$(echo "$queriesBlockeddaily" "$queriesTotaldaily" | awk '{printf "%3.2f\n",$1/$2*100}')"
	fi

	WritePlainData_ToJS "$SCRIPT_USB_DIR/SQLData.js" "QueriesTotaldaily,$queriesTotaldaily" "QueriesBlockeddaily,$queriesBlockeddaily" "BlockedPercentagedaily,$queriesPercentagedaily"

	if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
		#weekly
		Write_KeyStats_Sql_ToFile Total dnsqueries weekly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_KeyStats_Sql_ToFile Blocked dnsqueries weekly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql

		queriesTotalweekly="$(cat /tmp/queriesTotalweekly)"
		queriesBlockedweekly="$(cat /tmp/queriesBlockedweekly)"

		if ! Validate_Number "$queriesTotalweekly"; then queriesTotalweekly=0; fi
		if ! Validate_Number "$queriesBlockedweekly"; then queriesBlockedweekly=0; fi
		if [ "$queriesTotalweekly" -eq 0 ]; then
			queriesPercentageweekly=0
		else
			queriesPercentageweekly="$(echo "$queriesBlockedweekly" "$queriesTotalweekly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		fi

		WritePlainData_ToJS "$SCRIPT_USB_DIR/SQLData.js" "QueriesTotalweekly,$queriesTotalweekly" "QueriesBlockedweekly,$queriesBlockedweekly" "BlockedPercentageweekly,$queriesPercentageweekly"

		#monthly
		Write_KeyStats_Sql_ToFile Total dnsqueries monthly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_KeyStats_Sql_ToFile Blocked dnsqueries monthly /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql

		queriesTotalmonthly="$(cat /tmp/queriesTotalmonthly)"
		queriesBlockedmonthly="$(cat /tmp/queriesBlockedmonthly)"

		if ! Validate_Number "$queriesTotalmonthly"; then queriesTotalmonthly=0; fi
		if ! Validate_Number "$queriesBlockedmonthly"; then queriesBlockedmonthly=0; fi
		if [ "$queriesTotalmonthly" -eq 0 ]; then
			queriesPercentagemonthly=0
		else
			queriesPercentagemonthly="$(echo "$queriesBlockedmonthly" "$queriesTotalmonthly" | awk '{printf "%3.2f\n",$1/$2*100}')"
		fi

		WritePlainData_ToJS "$SCRIPT_USB_DIR/SQLData.js" "QueriesTotalmonthly,$queriesTotalmonthly" "QueriesBlockedmonthly,$queriesBlockedmonthly" "BlockedPercentagemonthly,$queriesPercentagemonthly"
	fi

	rm -f /tmp/queriesTotal*
	rm -f /tmp/queriesBlocked*
}

Generate_Count_Blocklist_Domains(){
	blockinglistfile="$DIVERSION_DIR/list/blockinglist.conf"

	blocklistdomains="$(cat $blockinglistfile | wc -l)"

	if ! Validate_Number "$blocklistdomains"; then blocklistdomains=0; fi

	WritePlainData_ToJS "$SCRIPT_USB_DIR/SQLData.js" "BlockedDomains,$blocklistdomains"
}

Generate_Stats_From_SQLite(){
	timenow="$1"

	metriclist="Total Blocked"

	for metric in $metriclist; do
		#daily
		Write_Time_Sql_ToFile "$metric" dnsqueries 0.25 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_Count_Sql_ToFile "$metric" dnsqueries 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 1 "$CSV_OUTPUT_DIR/$metric" daily /tmp/uidivstats.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats.sql

		sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}dailyclients.htm"
		cat "$CSV_OUTPUT_DIR/Totaldailytime.htm" "$CSV_OUTPUT_DIR/Blockeddailytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm" 2> /dev/null
		sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockeddailytime.htm"

		#weekly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" dnsqueries 1 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_Sql_ToFile "$metric" dnsqueries 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 7 "$CSV_OUTPUT_DIR/$metric" weekly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			rm -f /tmp/uidivstats.sql

			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}weeklyclients.htm"
			cat "$CSV_OUTPUT_DIR/Totalweeklytime.htm" "$CSV_OUTPUT_DIR/Blockedweeklytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedweeklytime.htm"
		fi

		#monthly
		if [ -n "$2" ] && [ "$2" = "fullrefresh" ]; then
			Write_Time_Sql_ToFile "$metric" dnsqueries 3 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_Sql_ToFile "$metric" dnsqueries 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			Write_Count_PerClient_Sql_ToFile "$metric" dnsqueries 30 "$CSV_OUTPUT_DIR/$metric" monthly /tmp/uidivstats.sql
			while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
				sleep 1
			done
			rm -f /tmp/uidivstats.sql

			sed -i '1i Fieldname,SrcIP,ReqDmn,Count' "$CSV_OUTPUT_DIR/${metric}monthlyclients.htm"
			cat "$CSV_OUTPUT_DIR/Totalmonthlytime.htm" "$CSV_OUTPUT_DIR/Blockedmonthlytime.htm" > "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm" 2> /dev/null
			sed -i '1i Fieldname,Time,QueryCount' "$CSV_OUTPUT_DIR/TotalBlockedmonthlytime.htm"
		fi
	done

	Write_View_Sql_ToFile drop dnsqueries daily /tmp/uidivstats.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats.sql

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
	ARPDUMP="$(arp -an)"
	for ipclient in $ipclients; do
		ARPINFO="$(echo "$ARPDUMP" | grep "$ipclient)")"
		MACADDR="$(echo "$ARPINFO" | awk '{print $4}' | cut -f1 -d ".")"

		HOST="$(arp "$ipclient" | awk '{if (NR==1) {print $1}}' | cut -f1 -d ".")"
		if [ "$HOST" = "?" ] || [ "$HOST" = "No" ]; then
			HOST="$(grep "$ipclient " /var/lib/misc/dnsmasq.leases | grep -v "\*" | awk '{print $4}')"
		fi

		if [ "$HOST" = "?" ] || [ "$HOST" = "No" ] || [ "$(printf "%s" "$HOST" | wc -m)" -le 1 ]; then
			HOST="$(nvram get custom_clientlist | grep -ioE "<.*>$MACADDR" | awk -F ">" '{print $(NF-1)}' | tr -d '<')" #thanks Adamm00
		fi

		if Validate_IP "$ipclient" >/dev/null 2>&1; then
			if [ -z "$HOST" ]; then
				HOST="$(dig +short +answer -x "$ipclient" '@'"$(nvram get lan_ipaddr)" | cut -f1 -d'.')"
			fi
		else
			HOST="IPv6"
		fi

		if [ -z "$HOST" ]; then
			HOST="Unknown"
		fi

		HOST="$(echo "$HOST" | tr -d '\n')"

		echo '["'"$ipclient"'","'"$HOST"'"],' >> "$CSV_OUTPUT_DIR/ipdistinctclients.js"
	done
	sed -i '$ s/,$//' "$CSV_OUTPUT_DIR/ipdistinctclients.js"
	echo "];" >> "$CSV_OUTPUT_DIR/ipdistinctclients.js"
}

Optimise_DNS_DB(){
	renice 15 $$
	Print_Output true "Running nightly database analysis and optimisation..." "$PASS"
	{
		echo "PRAGMA analysis_limit=0;"
		echo "PRAGMA cache_size=-20000;"
		echo "ANALYZE dnsqueries;"
	}  > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql
	Print_Output true "Database analysis and optimisation complete" "$PASS"
	renice 0 $$
}

Trim_DNS_DB(){
	renice 15 $$
	TZ=$(cat /etc/TZ)
	export TZ
	timenow=$(date +"%s")

	Print_Output true "Trimming records entries from database..." "$PASS"

	{
		echo "PRAGMA cache_size=-20000; BEGIN TRANSACTION;"
		echo "DELETE FROM [dnsqueries] WHERE ([Timestamp] < strftime('%s',datetime($timenow,'unixepoch','-$(DaysToKeep check) day')));"
		echo "DELETE FROM [dnsqueries] WHERE [Timestamp] > $timenow;"
		echo "DELETE FROM [dnsqueries] WHERE [SrcIP] = 'from';"
		echo "END TRANSACTION;"
	} > /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done

	Write_View_Sql_ToFile drop dnsqueries weekly /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	Write_View_Sql_ToFile drop dnsqueries monthly /tmp/uidivstats-trim.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-trim.sql >/dev/null 2>&1; do
		sleep 1
	done
	rm -f /tmp/uidivstats-trim.sql

	Print_Output true "Record trimming complete" "$PASS"

	renice 0 $$
}

Flush_Cache_To_DB(){
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	renice 15 $$
	if [ -f /tmp/cache-uiDivStats-SQL.tmp ]; then
		{
			echo "PRAGMA synchronous = normal; PRAGMA cache_size=-20000;"
			echo "BEGIN TRANSACTION;"
			echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Allowed] INTEGER NOT NULL);"
			echo "CREATE TABLE IF NOT EXISTS [dnsqueries_tmp] ([Timestamp] NUMERIC NOT NULL,[SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Allowed] INTEGER NOT NULL);"
			echo ".mode csv"
			echo ".import /tmp/cache-uiDivStats-SQL.tmp dnsqueries_tmp"
			echo "INSERT INTO dnsqueries SELECT NULL,* FROM dnsqueries_tmp;"
			echo "DROP TABLE IF EXISTS dnsqueries_tmp;"
			echo "END TRANSACTION;"
		} > /tmp/cache-uiDivStats-SQL.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/cache-uiDivStats-SQL.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/cache-uiDivStats-SQL.sql
		rm -f /tmp/cache-uiDivStats-SQL.tmp
	fi
	renice 0 $$
}

Reset_DB(){
	/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
	sleep 3
	Auto_Cron delete 2>/dev/null

	if ! mv "$DNS_DB" "$DNS_DB$1"; then
		Print_Output true "Database backup failed, please check storage device" "$WARN"
	fi

	Print_Output false "Creating database table and enabling write-ahead logging..." "$PASS"
	{
		echo "PRAGMA journal_mode=WAL;"
		echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Allowed] INTEGER NOT NULL);"
	}  > /tmp/uidivstats-upgrade.sql
	"$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql

	Print_Output false "Creating database table indexes..." "$PASS"
	Table_Indexes drop
	Table_Indexes create

	rm -f /tmp/uidivstats-upgrade.sql
	Print_Output false "Database ready, starting services..." "$PASS"
	renice 0 $$

	Auto_Cron create 2>/dev/null
	/opt/etc/init.d/S90taildns start >/dev/null 2>&1

	Print_Output true "Database reset complete" "$WARN"
}

Process_Upgrade(){
	if [ -f "$SCRIPT_DIR/.upgraded" ] || [ -f "$SCRIPT_DIR/.upgraded2" ] || [ -f "$SCRIPT_DIR/.upgraded3" ]; then
		Print_Output true "Unable to upgrade from older versions than 3.0.0" "$CRIT"
		exit 1
	fi

	rm -f "$SCRIPT_DIR/.newindexes"

	if echo "SELECT [Result] FROM [dnsqueries] LIMIT 0" | "$SQLITE3_PATH" "$DNS_DB" >/dev/null 2>&1; then
		Print_Output true "Upgrade database schema." "$WARN"
		Print_Output false "Existing data will be migrated overnight, or you can run 'uiDivStats trimdb' manually." "$WARN"
		Reset_DB .old
	fi
}

Migrate_Old_Data(){
	if [ -f "$DNS_DB.old" ]; then
		Print_Output true "Migrating old data. This can take a while!" "$PASS"
		Auto_Cron delete 2>/dev/null
		renice 15 $$

		TZ=$(cat /etc/TZ)
		export TZ
		timenow=$(date +"%s")

		{
			echo "ATTACH DATABASE '$DNS_DB.old' AS OLD;"
			echo "INSERT INTO [dnsqueries] ([Timestamp], [SrcIP], [ReqDmn], [QryType], [Allowed]) SELECT [Timestamp], [SrcIP], [ReqDmn], CASE [QryType] WHEN 'type=65' THEN 'HTTPS' ELSE [QryType] END, [Result] == 'allowed' FROM OLD.[dnsqueries] WHERE [Timestamp] > strftime('%s',datetime($timenow,'unixepoch','-$(DaysToKeep check) day'));"
		} > /tmp/uidivstats-upgrade.sql
		while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
			sleep 1
		done
		rm -f /tmp/uidivstats-upgrade.sql

		rm -f "$DNS_DB.old"

		Print_Output true "Data migration complete" "$PASS"
		Auto_Cron create 2>/dev/null
		renice 0 $$
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
	printf "${BOLD}###################################################################${CLEARFORMAT}\\n"
	printf "${BOLD}##                                                               ##${CLEARFORMAT}\\n"
	printf "${BOLD}##           _  _____   _          _____  _          _           ##${CLEARFORMAT}\\n"
	printf "${BOLD}##          (_)|  __ \ (_)        / ____|| |        | |          ##${CLEARFORMAT}\\n"
	printf "${BOLD}##    _   _  _ | |  | | _ __   __| (___  | |_  __ _ | |_  ___    ##${CLEARFORMAT}\\n"
	printf "${BOLD}##   | | | || || |  | || |\ \ / / \___ \ | __|/ _  || __|/ __|   ##${CLEARFORMAT}\\n"
	printf "${BOLD}##   | |_| || || |__| || | \ V /  ____) || |_| (_| || |_ \__ \   ##${CLEARFORMAT}\\n"
	printf "${BOLD}##    \__,_||_||_____/ |_|  \_/  |_____/  \__|\__,_| \__||___/   ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                                                               ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                       %s on %-11s                   ##${CLEARFORMAT}\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "${BOLD}##                                                               ##${CLEARFORMAT}\\n"
	printf "${BOLD}##              https://github.com/jackyaz/uiDivStats            ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                                                               ##${CLEARFORMAT}\\n"
	printf "${BOLD}###################################################################${CLEARFORMAT}\\n"
	printf "\\n"
}

MainMenu(){
	printf "WebUI for %s is available at:\\n${SETTING}%s${CLEARFORMAT}\\n\\n" "$SCRIPT_NAME" "$(Get_WebUI_URL)"
	printf "1.    Update Diversion Statistics (daily only)\\n\\n"
	printf "2.    Update Diversion Statistics (daily, weekly and monthly)\\n"
	printf "      WARNING: THIS MAY TAKE A WHILE (>5 minutes)\\n\\n"
	printf "3.    Edit list of domains to exclude from %s statistics\\n\\n" "$SCRIPT_NAME"
	printf "4.    Set number of recent DNS queries to show in WebUI\\n      Currently: ${SETTING}%s queries will be shown${CLEARFORMAT}\\n\\n" "$(LastXQueries check)"
	printf "5.    Set number of days data to keep in database\\n      Currently: ${SETTING}%s days data will be kept${CLEARFORMAT}\\n\\n" "$(DaysToKeep check)"
	printf "q.    Toggle query mode\\n      Currently ${SETTING}%s${CLEARFORMAT} query types will be logged\\n\\n" "$(QueryMode check)"
	printf "c.    Toggle cache mode\\n      Currently ${SETTING}%s${CLEARFORMAT} being used to cache query records\\n\\n" "$(CacheMode check)"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "r.    Reset %s database / delete all data\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "${BOLD}###################################################################${CLEARFORMAT}\\n"
	printf "\\n"

	while true; do
		printf "Choose an option:  "
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
			3)
				printf "\\n"
				if Check_Lock menu; then
					Menu_EditExcludeList
				fi
				printf "\\n"
				PressEnter
				break
			;;
			4)
				printf "\\n"
				LastXQueries update
				PressEnter
				break
			;;
			5)
				printf "\\n"
				DaysToKeep update
				PressEnter
				break
			;;
			q)
				printf "\\n"
				if Check_Lock menu; then
					if [ "$(QueryMode check)" = "all" ]; then
						QueryMode "A+AAAA+HTTPS"
					elif [ "$(QueryMode check)" = "A+AAAA+HTTPS" ]; then
						QueryMode all
					fi
					Clear_Lock
				fi
				break
			;;
			c)
				printf "\\n"
				if Check_Lock menu; then
					if [ "$(CacheMode check)" = "none" ]; then
						CacheMode tmp
					elif [ "$(CacheMode check)" = "tmp" ]; then
						CacheMode none
					fi
					Clear_Lock
				fi
				break
			;;
			u)
				printf "\\n"
				if Check_Lock menu; then
					Update_Version
					Clear_Lock
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock menu; then
					Update_Version force
					Clear_Lock
				fi
				PressEnter
				break
			;;
			r)
				printf "\\n"
				if Check_Lock menu; then
					Menu_ResetDB
					Clear_Lock
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n${BOLD}Thanks for using %s!${CLEARFORMAT}\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n${BOLD}Are you sure you want to uninstall %s? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
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
		Print_Output false "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ ! -f /opt/bin/diversion ]; then
		Print_Output false "Diversion not installed!" "$ERR"
		CHECKSFAILED="true"
	else
		if ! /opt/bin/grep -qm1 'div_lock_ac' /opt/bin/diversion; then
			Print_Output false "Diversion update required!" "$ERR"
			Print_Output false "Open Diversion and use option u to update"
			CHECKSFAILED="true"
		fi

		if ! /opt/bin/grep -q 'log-facility=/opt/var/log/dnsmasq.log' /etc/dnsmasq.conf; then
			Print_Output false "Diversion logging not enabled!" "$ERR"
			Print_Output false "Open Diversion and use option l to enable logging"
			CHECKSFAILED="true"
		fi
	fi

	if ! Firmware_Version_Check; then
		Print_Output false "Unsupported firmware version detected, 384.XX required" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ "$CHECKSFAILED" = "false" ]; then
		opkg update
		opkg install grep
		opkg install sqlite3-cli
		opkg install procps-ng-pkill
		opkg install findutils
		opkg install bind-dig
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	ScriptHeader
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz"
	sleep 1

	Print_Output false "Checking your router meets the requirements for $SCRIPT_NAME"

	if ! Check_Requirements; then
		Print_Output false "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi

	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
	Set_Version_Custom_Settings server "$SCRIPT_VERSION"
	Create_Symlinks

	Update_File uidivstats_www.asp
	Update_File shared-jy.tar.gz
	Update_File taildns.tar.gz

	/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
	sleep 3
	Auto_Cron delete 2>/dev/null

	Process_Upgrade

	renice 15 $$
	Print_Output false "Creating database table and enabling write-ahead logging..." "$PASS"
	{
		echo "PRAGMA journal_mode=WAL;"
		echo "CREATE TABLE IF NOT EXISTS [dnsqueries] ([QueryID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[SrcIP] TEXT NOT NULL,[ReqDmn] TEXT NOT NULL,[QryType] Text NOT NULL,[Allowed] INTEGER NOT NULL);"
	}  > /tmp/uidivstats-upgrade.sql
	while ! "$SQLITE3_PATH" "$DNS_DB" < /tmp/uidivstats-upgrade.sql >/dev/null 2>&1; do
		sleep 1
	done

	Print_Output false "Creating database table indexes..." "$PASS"
	Table_Indexes drop
	Table_Indexes create

	rm -f /tmp/uidivstats-upgrade.sql
	Print_Output false "Database ready, starting services..." "$PASS"
	renice 0 $$

	Auto_Startup create 2>/dev/null
	Auto_DNSMASQ_Postconf create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	/opt/etc/init.d/S90taildns start >/dev/null 2>&1

	dig +short +answer snbforums.com '@'"$(nvram get lan_ipaddr)" >/dev/null 2>&1
	sleep 1
	dig +short +answer diversion-adblocking-ip.address '@'"$(nvram get lan_ipaddr)" >/dev/null 2>&1
	sleep 1

	Flush_Cache_To_DB
	sleep 1
	Generate_Query_Log
	sleep 1

	Menu_GenerateStats fullrefresh

	Clear_Lock
	ScriptHeader
	MainMenu
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
		echo 'var uidivstatsstatus = "InProgress";' > /tmp/detect_uidivstats.js
		renice 15 $$
		if [ -n "$1" ] && [ "$1" = "fullrefresh" ]; then
			Print_Output true "Starting stat full refresh" "$PASS"
		else
			Print_Output true "Starting stat update" "$PASS"
		fi
		UpdateDiversionWeeklyStatsFile
		Generate_NG "$1"
		renice 0 $$
	else
		Print_Output true "Diversion logging not enabled!" "$ERR"
		Print_Output true "Open Diversion and use option l to enable logging"
	fi
	Clear_Lock
}

Menu_EditExcludeList(){
	ScriptHeader
	texteditor=""
	exitmenu="false"

	printf "${BOLD}${WARN}Enter one domain per line${CLEARFORMAT}\\n" "$SCRIPT_NAME"
	printf "\\nThis file is located here: %s\\n" "$STATSEXCLUDE_LIST_FILE"
	printf "\\n\\n${BOLD}A choice of text editors is available:${CLEARFORMAT}\\n"
	printf "1.    nano (recommended for beginners)\\n"
	printf "2.    vi\\n"
	printf "\\ne.    Exit to main menu\\n"

	while true; do
		printf "\\n${BOLD}Choose an option:${CLEARFORMAT}  "
		read -r editor
		case "$editor" in
			1)
				texteditor="nano -K"
				break
			;;
			2)
				texteditor="vi"
				break
			;;
			e)
				exitmenu="true"
				break
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done

	if [ "$exitmenu" != "true" ]; then
		oldmd5="$(md5sum "$STATSEXCLUDE_LIST_FILE" | awk '{print $1}')"
		$texteditor "$STATSEXCLUDE_LIST_FILE"
		newmd5="$(md5sum "$STATSEXCLUDE_LIST_FILE" | awk '{print $1}')"
		if [ "$oldmd5" != "$newmd5" ]; then
			ScriptHeader
			printf "\\n${BOLD}${WARN}Changes detected, would you like to regenerate stats?${CLEARFORMAT}\\n\\n"
			printf "1.    Daily stats only\\n"
			printf "2.    Daily, weekly and monthly (may take a while, >5 mins)\\n"
			printf "\\ne.    Exit to main menu\\n"

			while true; do
				printf "\\n${BOLD}Choose an option:${CLEARFORMAT}  "
				read -r editor
				case "$editor" in
					1)
						printf "\\n"
						Menu_GenerateStats
						break
					;;
					2)
						printf "\\n"
						Menu_GenerateStats fullrefresh
						break
					;;
					e)
						break
					;;
					*)
						printf "\\nPlease choose a valid option\\n\\n"
					;;
				esac
			done
		fi
	fi
	Clear_Lock
}

Menu_ResetDB(){
	printf "${BOLD}\\e[33mWARNING: This will reset the %s database by deleting all database records.\\n" "$SCRIPT_NAME"
	printf "A backup of the database will be created if you change your mind.${CLEARFORMAT}\\n"
	printf "\\n${BOLD}Do you want to continue? (y/n)${CLEARFORMAT}  "
	read -r confirm
	case "$confirm" in
		y|Y)
			printf "\\n"
			Reset_DB .bak
		;;
		*)
			printf "\\n${BOLD}\\e[33mDatabase reset cancelled${CLEARFORMAT}\\n\\n"
		;;
	esac
}

Menu_Uninstall(){
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep querylog | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep querylog | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep flushtodb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep trimdb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep trimdb | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_DNSMASQ_Postconf delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null

	Shortcut_Script delete

	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"
	Get_WebUI_Page "$SCRIPT_DIR/uidivstats_www.asp"
	if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		umount /www/require/modules/menuTree.js
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
		rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage"
		rm -f "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	fi
	flock -u "$FD"
	rm -f "$SCRIPT_DIR/uidivstats_www.asp" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null

	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	sed -i '/uidivstats_version_local/d' "$SETTINGSFILE"
	sed -i '/uidivstats_version_server/d' "$SETTINGSFILE"

	/opt/etc/init.d/S90taildns stop >/dev/null 2>&1
	sleep 3
	rm -f /opt/etc/init.d/S90taildns 2>/dev/null
	rm -rf "$SCRIPT_DIR/taildns.d" 2>/dev/null
	rm -f "$SCRIPT_DIR/taildns.tar.gz.md5" 2>/dev/null
	rm -f /tmp/cache-uiDivStats-SQL.tmp*

	printf "\\n\\e[1mDo you want to delete %s stats and config? (y/n)\\e[0m  " "$SCRIPT_NAME"
	read -r confirm
	case "$confirm" in
		y|Y)
			rm -rf "$SCRIPT_DIR" 2>/dev/null
			rm -rf "$SCRIPT_USB_DIR" 2>/dev/null
		;;
		*)
			:
		;;
	esac

	rm -rf "$CSV_OUTPUT_DIR"
	rm -f "$SCRIPT_USB_DIR/SQLData.js"
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$(nvram get ntp_ready)" -eq 0 ]; then
		Check_Lock
		ntpwaitcount=0
		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpwaitcount" -lt 600 ]; do
			ntpwaitcount="$((ntpwaitcount + 30))"
			Print_Output true "Waiting for NTP to sync..." "$WARN"
			sleep 30
		done
		if [ "$ntpwaitcount" -ge 600 ]; then
			Print_Output true "NTP failed to sync after 10 minutes. Please resolve!" "$CRIT"
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

Show_About(){
	cat <<EOF
About
  $SCRIPT_NAME provides a graphical representation of domain
  blocking performed by Diversion.
License
  $SCRIPT_NAME is free to use under the GNU General Public License
  version 3 (GPL-3.0) https://opensource.org/licenses/GPL-3.0
Help & Support
  https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=15
Source code
  https://github.com/jackyaz/$SCRIPT_NAME
EOF
	printf "\\n"
}
### ###

### function based on @dave14305's FlexQoS show_help function ###
Show_Help(){
	cat <<EOF
Available commands:
  $SCRIPT_NAME about              explains functionality
  $SCRIPT_NAME update             checks for updates
  $SCRIPT_NAME forceupdate        updates to latest version (force update)
  $SCRIPT_NAME startup force      runs startup actions such as mount WebUI tab
  $SCRIPT_NAME install            installs script
  $SCRIPT_NAME uninstall          uninstalls script
  $SCRIPT_NAME generate           update daily statistics and charts
  $SCRIPT_NAME fullrefresh        update daily, weekly and monthly statistics and charts
  $SCRIPT_NAME querylog           retrieve last 5000 records to show in WebUI
  $SCRIPT_NAME flushtodb          flush contents of cache to database
  $SCRIPT_NAME trimdb             run maintenance on database (this runs automatically every night)
  $SCRIPT_NAME develop            switch to development branch
  $SCRIPT_NAME stable             switch to stable branch
EOF
	printf "\\n"
}
### ###

if [ -z "$1" ]; then
	NTP_Ready
	Entware_Ready
	Create_Dirs
	if [ -f "$SCRIPT_DIR/SQLData.js" ]; then
		mv "$SCRIPT_DIR/SQLData.js" "$SCRIPT_USB_DIR/SQLData.js"
	fi
	Conf_Exists
	Create_Symlinks
	Process_Upgrade
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
	fullrefresh)
		NTP_Ready
		Entware_Ready
		Check_Lock
		Menu_GenerateStats fullrefresh
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			rm -f /tmp/detect_uidivstats.js
			Check_Lock webui
			Menu_GenerateStats
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}querylog" ]; then
			Generate_Query_Log
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
			sleep 3
			/opt/etc/init.d/S90taildns start >/dev/null 2>&1
		fi
		exit 0
	;;
	querylog)
		NTP_Ready
		Entware_Ready
		Generate_Query_Log
		exit 0
	;;
	flushtodb)
		NTP_Ready
		Entware_Ready
		Flush_Cache_To_DB
		exit 0
	;;
	trimdb)
		NTP_Ready
		Entware_Ready
		Trim_DNS_DB
		Check_Lock
		Migrate_Old_Data
		Optimise_DNS_DB
		Menu_GenerateStats fullrefresh
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
		Set_Version_Custom_Settings local "$SCRIPT_VERSION"
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		if [ -f "$SCRIPT_DIR/SQLData.js" ]; then
			mv "$SCRIPT_DIR/SQLData.js" "$SCRIPT_USB_DIR/SQLData.js"
		fi
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	postupdate)
		Create_Dirs
		if [ -f "$SCRIPT_DIR/SQLData.js" ]; then
			mv "$SCRIPT_DIR/SQLData.js" "$SCRIPT_USB_DIR/SQLData.js"
		fi
		Conf_Exists
		Create_Symlinks
		Process_Upgrade
		Auto_Startup create 2>/dev/null
		Auto_DNSMASQ_Postconf create 2>/dev/null
		Auto_Cron create 2>/dev/null
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
	;;
	about)
		ScriptHeader
		Show_About
		exit 0
	;;
	help)
		ScriptHeader
		Show_Help
		exit 0
	;;
	uninstall)
		Menu_Uninstall
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
	*)
		ScriptHeader
		Print_Output false "Command not recognised." "$ERR"
		Print_Output false "For a list of available commands run: $SCRIPT_NAME help"
		exit 1
	;;
esac
