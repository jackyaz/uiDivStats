#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($5 ~ "query") {
		result = "allowed";
		time = mktime( \
			sprintf("%04d %02d %02d %s\n", \
				strftime("%Y", systime()), \
				(match("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, \
				$2, \
				gensub(":", " ", "g", $3) \
			) \
			);
		gsub("query|\\[|\\]", "", $5);
		recordtype = $5;
		query = $6;
		host = $8;
		getline;
		if ($5 ~ "diversion") {
			result = "blocked";
			if ($5 ~ "blockinglist_fs") {
				result = "blocked (blocking list fs)";
			}
			else if ($5 ~ "blockinglist") {
				result = "blocked (blocking list)";
			}
			else if ($5 ~ "yt_blacklist") {
				result = "blocked (youtube blacklist)";
			}
			else if ($5 ~ "wc_blacklist") {
				result = "blocked (wildcard blacklist)";
			}
			else if ($5 ~ "blacklist") {
				result = "blocked (blacklist)";
			}
		}
		print time,host,query,recordtype,result;
	}
}
