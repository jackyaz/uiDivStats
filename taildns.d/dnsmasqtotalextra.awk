#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($7 ~ "query" && $7 !~ "dnssec"){
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
		allowed = ($7 == "config" && $10 == "NXDOMAIN") ? 0 : 1;
		print time,host,query,recordtype,allowed;
	}
}
