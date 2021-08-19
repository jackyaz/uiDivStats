#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($7 ~ "query" && $7 !~ "dnssec"){
		result = "allowed";
		time = mktime( \
			sprintf("%04d %02d %02d %s\n", \
				strftime("%Y", systime()), \
				(match("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, \
				$2, \
				gensub(":", " ", "g", $3) \
			) \
			);
		gsub("query|\\[|\\]", "", $7);
		recordtype = $7;
		query = $8;
		host = $10;
		getline;
		if ($10 == blockingIP || $10 == "::"){
			result = "blocked";
			if ($7 ~ "blockinglist_fs"){
				result = "blocked (blocking list fs)";
			}
			else if ($7 ~ "blockinglist"){
				result = "blocked (blocking list)";
			}
			else if ($7 ~ "yt_blacklist"){
				result = "blocked (youtube blacklist)";
			}
			else if ($7 ~ "blacklist"){
				result = "blocked (blacklist)";
			}
			else{
				result = "blocked (wildcard blacklist)";
			}
		}
		print time,host,query,recordtype,result;
	}
}
