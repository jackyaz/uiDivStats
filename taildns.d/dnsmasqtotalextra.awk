#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($6 ~ "query") {
		result = "allowed";
		time = mktime( \
			sprintf("%04d %02d %02d %s\n", \
				strftime("%Y", systime()), \
				(match("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, \
				$2, \
				gensub(":", " ", "g", $3) \
			) \
			);
		gsub("query|\\[|\\]", "", $6);
		recordtype = $6;
		query = $7;
		host = $9;
		getline;
		if ($6 ~ "diversion") {
			result = "blocked";
			if ($6 ~ "blockinglist_fs") {
				result = "blocked (blocking list fs)";
			}
			else if ($6 ~ "blockinglist") {
				result = "blocked (blocking list)";
			}
			else if ($6 ~ "yt_blacklist") {
				result = "blocked (youtube blacklist)";
			}
			else if ($6 ~ "wc_blacklist") {
				result = "blocked (wildcard blacklist)";
			}
			else if ($6 ~ "blacklist") {
				result = "blocked (blacklist)";
			}
		}
		print time,host,query,recordtype,result;
	}
}
