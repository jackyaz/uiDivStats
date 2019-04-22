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
#<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="textarea" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;">
### Start of script variables ###
readonly SCRIPT_NAME="divStats"
readonly SCRIPT_VERSION="v1.0.0"
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
		if [ "$ageoflock" -gt 60 ]; then
			Print_Output "true" "Stale lock file found (>60 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output "true" "Lock file found (age: $ageoflock seconds) - ping test likely currently running" "$ERR"
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
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$SCRIPT_NAME" "*/15 * * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
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

Script_gnuplot(){
	{ echo 'set terminal png nocrop enhanced large size 800,600 background rgb "#475A5F"'; /
echo 'set output "plot.png"'; /
echo 'set boxwidth 0.5'; /
echo 'set style fill solid 1.0 border -1'; /
echo 'unset grid'; /
echo 'set ytics 5 nomirror'; /
echo 'set ylabel "Number of blocks"'; /
echo 'set yrange [0:*]'; /
echo 'set xtics rotate'; /
echo 'plot "data.dat" using 0:2:xtic(1) notitle with boxes , "data.dat" using 0:($2+5):2 notitle with labels'; } > /tmp/gnuplot.script
#lc rgb var
}

Generate_Stats(){
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
	printf "1.    Check connection now\\n\\n"
	printf "2.    Set preferred ping server\\n      Currently: %s\\n\\n" ""
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m############################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock "menu"; then
					Script_gnuplot
					#Menu_GenerateStats
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				#Menu_SetPingServer
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
	Generate_Stats
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
