#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($(NF-3) ~ "query") {
		result = "allowed";
		time = mktime( \
			sprintf("%04d %02d %02d %s\n", \
				strftime("%Y", systime()), \
				(match("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, \
				$2, \
				gensub(":", " ", "g", $3) \
			) \
			);
		gsub("query|\\[|\\]", "", $(NF-3));
		recordtype = $(NF-3);
		query = $(NF-2);
		host = $NF;
		getline;
		if ($(NF-3) ~ "diversion") {
			result = "blocked";
			if ($(NF-3) ~ "blockinglist_fs") {
				result = "blocked (blocking list fs)";
			}
			else if ($(NF-3) ~ "blockinglist") {
				result = "blocked (blocking list)";
			}
			else if ($(NF-3) ~ "yt_blacklist") {
				result = "blocked (youtube blacklist)";
			}
			else if ($(NF-3) ~ "wc_blacklist") {
				result = "blocked (wildcard blacklist)";
			}
			else if ($(NF-3) ~ "blacklist") {
				result = "blocked (blacklist)";
			}
		}
		print time,host,query,recordtype,result;
	}
}
