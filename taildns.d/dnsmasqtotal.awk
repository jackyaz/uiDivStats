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
		}
		print time,host,query,recordtype,result;
	}
}
