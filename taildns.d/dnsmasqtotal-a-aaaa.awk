#!/usr/bin/awk -f

BEGIN {
	OFS = ",";
}
{
	if ($5 ~ "query\\[(A|AAAA|HTTPS)\\]" && $5 !~ "dnssec"){
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
		allowed = ($5 == "config" && $8 == "NXDOMAIN") ? 0 : 1;
		print time,host,query,recordtype,allowed;
	}
}
