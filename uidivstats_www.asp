<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Diversion Statistics</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{
font-weight: bolder;
}

.collapsible {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

.keystatscell {
  background-color:#1F2D35 !important;
  background:#2F3A3E !important;
  border-bottom:none !important;
  border-top:none !important;
}

.keystatsnumber {
  font-size: 20px !important;
  font-weight: bolder !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/chart.min.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/uiDivStats/uidivstats.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/uiDivStats/uidivstatstext.js"></script>

<script>
var BarChartBlockedAds,BarChartReqDomains;
var charttypead, charttypedomain;
Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
  return coordinates;
};

function Draw_Chart_NoData(txtchartname){
	document.getElementById(txtchartname).width="735";
	document.getElementById(txtchartname).height="360";
	document.getElementById(txtchartname).style.width="735px";
	document.getElementById(txtchartname).style.height="360px";
	var ctx = document.getElementById(txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white'
	ctx.fillText('No data to display', 375, 180);
	ctx.restore();
}

function Draw_Ad_Chart() {
	if(typeof barLabelsBlockedAds === 'undefined' || barLabelsBlockedAds === null) { Draw_Chart_NoData("ChartAds"); return; }
	if(typeof barDataBlockedAds === 'undefined' || barDataBlockedAds === null) { Draw_Chart_NoData("ChartAds"); return; }
	if (barLabelsBlockedAds.length == 0) { Draw_Chart_NoData("ChartAds"); return; }
	if (BarChartBlockedAds != undefined) BarChartBlockedAds.destroy();
	var ctx = document.getElementById("ChartAds").getContext("2d");
	var barOptionsAds = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: false },
		tooltips: {
			callbacks: {
				title: function (tooltipItem, data) { return data.labels[tooltipItem[0].index]; },
				label: function (tooltipItem, data) { return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]); },
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				display: showAxis(charttypead,"x"),
				gridLines: { display: showGrid(charttypead,"x"), color: "#282828" },
				ticks: { display: showAxis(charttypead,"x"), beginAtZero: false }
			}],
			yAxes: [{
				display: showAxis(charttypead,"y"),
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: "Blocks" },
				ticks: { display: showAxis(charttypead,"y"), beginAtZero: false }
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: true,
					mode: ZoomPanEnabled(charttypead),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttypead,"x",barDataBlockedAds),
						y: ZoomPanMax(charttypead,"y",barDataBlockedAds)
					},
				},
				zoom: {
					enabled: true,
					mode: ZoomPanEnabled(charttypead),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttypead,"x",barDataBlockedAds),
						y: ZoomPanMax(charttypead,"y",barDataBlockedAds)
					},
					speed: 0.1,
				}
			}
		}
	};
	var barDatasetAds = {
		labels: barLabelsBlockedAds,
		datasets: [{data: barDataBlockedAds,
			borderWidth: 1,
			backgroundColor: poolColors(barDataBlockedAds.length),
			borderColor: "#000000",
		}]
	};
	BarChartBlockedAds = new Chart(ctx, {
		type: getChartType(charttypead),
		options: barOptionsAds,
		data: barDatasetAds
	});
	changeColour(E('colourads'),BarChartBlockedAds,barDataBlockedAds,"colourads")
}

function Draw_Domain_Chart() {
	if(typeof window["barLabelsDomains"+document.getElementById("clientdomains").value] === 'undefined' || window["barLabelsDomains"+document.getElementById("clientdomains").value] === null) { Draw_Chart_NoData("ChartDomains"); return; }
	if(typeof window["barDataDomains"+document.getElementById("clientdomains").value] === 'undefined' || window["barDataDomains"+document.getElementById("clientdomains").value] === null) { Draw_Chart_NoData("ChartDomains"); return; }
	if (window["barLabelsDomains"+document.getElementById("clientdomains").value].length == 0) { Draw_Chart_NoData("ChartDomains"); return; }
	if (BarChartReqDomains != undefined) BarChartReqDomains.destroy();
	var ctx = document.getElementById("ChartDomains").getContext("2d");
	var barOptionsDomains = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: false },
		tooltips: {
			callbacks: {
				title: function (tooltipItem, data) {
				if (window["barLabelsDomainsType"+document.getElementById("clientdomains").value][tooltipItem[0].index].length > 1){
				return data.labels[tooltipItem[0].index] + " - " + window["barLabelsDomainsType"+document.getElementById("clientdomains").value][tooltipItem[0].index];
				}
				else {
				return data.labels[tooltipItem[0].index];
				}
				},
				label: function (tooltipItem, data) { return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]); },
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				display: showAxis(charttypedomain,"x"),
				gridLines: { display: showGrid(charttypedomain,"x"), color: "#282828" },
				ticks: { display: showAxis(charttypedomain,"x"), beginAtZero: false }
			}],
			yAxes: [{
				display: showAxis(charttypedomain,"y"),
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: "Domains" },
				ticks: { display: showAxis(charttypedomain,"y"), beginAtZero: false }
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: true,
					mode: ZoomPanEnabled(charttypedomain),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttypedomain,"x",window["barDataDomains"+document.getElementById("clientdomains").value]),
						y: ZoomPanMax(charttypedomain,"y",window["barDataDomains"+document.getElementById("clientdomains").value])
					},
				},
				zoom: {
					enabled: true,
					mode: ZoomPanEnabled(charttypedomain),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttypedomain,"x",window["barDataDomains"+document.getElementById("clientdomains").value]),
						y: ZoomPanMax(charttypedomain,"y",window["barDataDomains"+document.getElementById("clientdomains").value])
					},
					speed: 0.1,
				}
			}
		}
	};
	var barDatasetDomains = {
		labels: window["barLabelsDomains"+document.getElementById("clientdomains").value],
		datasets: [{data: window["barDataDomains"+document.getElementById("clientdomains").value],
			borderWidth: 1,
			backgroundColor: poolColors(window["barDataDomains"+document.getElementById("clientdomains").value].length),
			borderColor: "#000000",
		}]
	};
	BarChartReqDomains = new Chart(ctx, {
		type: getChartType(charttypedomain),
		options: barOptionsDomains,
		data: barDatasetDomains
	});
	changeColour(E('colourdomains'),BarChartReqDomains,window["barDataDomains"+document.getElementById("clientdomains").value],"colourdomains")
}

function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get(cookiename)) != null) {
			if (s.match(/^([0-2])$/)) {
				E(cookiename).value = cookie.get(cookiename) * 1;
			}
	}
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	GetCookie("colourads");
	GetCookie("charttypeads");
	GetCookie("colourdomains");
	GetCookie("colourdomains");
	
	show_menu();
	loadDivStats();
	Draw_Ad_Chart();
	changeLayout(E('charttypeads'),"BarChartBlockedAds","charttypeads");
	Draw_Domain_Chart();
	changeLayout(E('charttypedomains'),"BarChartReqDomains","charttypedomains");
	
	SetDivStatsTitle();
	SetKeyStatsReq();
	SetKeyStatsBlocked();
	SetKeyStatsPercent();
	SetKeyStatsDomains();
	SetTopBlockedTitle();
	SetTopRequestedTitle();
	SetClients();
	GetCookie("clientdomains");
	
	$("thead").click(function(){
		$(this).siblings().toggle("fast");
	})
	
	$(".default-collapsed").trigger("click");
}

function reload() {
	location.reload(true);
}

function applyRule() {
	var action_script_tmp = "start_uiDivStats";
	document.form.action_script.value = action_script_tmp;
	var restart_time = document.form.action_wait.value*1;
	parent.showLoading(restart_time, "waiting");
	document.form.submit();
}

function getSDev(datasetname){
	var avg = getAvg(datasetname);
	
	var squareDiffs = datasetname.map(function(value){
		var diff = value - avg;
		var sqrDiff = diff * diff;
		return sqrDiff;
	});
	
	var avgSquareDiff = getAvg(squareDiffs);
	var stdDev = Math.sqrt(avgSquareDiff);
	return stdDev;
}

function getMax(datasetname) {
	max = Math.max(...datasetname)
	return max + (max*0.1);
}

function getAvg(datasetname) {
	var sum, avg = 0;
	
	if (datasetname.length) {
		sum = datasetname.reduce(function(a, b) { return a*1 + b*1; });
		avg = sum / datasetname.length;
	}
	
	return avg;
}

function getRandomColor() {
	var r = Math.floor(Math.random() * 255);
	var g = Math.floor(Math.random() * 255);
	var b = Math.floor(Math.random() * 255);
	return "rgba(" + r + "," + g + "," + b + ", 1)";
}

function poolColors(a) {
	var pool = [];
	for(i = 0; i < a; i++) {
		pool.push(getRandomColor());
	}
	return pool;
}

function getChartType(e) {
	if (e == null) {
		return 'horizontalBar';
	}
	else {
		return e;
	}
}

function ZoomPanEnabled(charttype) {
	if (charttype == "bar") {
		return 'y';
	}
	else if (charttype == "horizontalBar") {
		return 'x';
	}
}

function ZoomPanMax(charttype, axis, datasetname) {
	if (axis == "x") {
		if (charttype == "bar") {
			return null;
		}
		else if (charttype == "horizontalBar") {
			return getMax(datasetname);
		}
	}
	else if (axis == "y") {
		if (charttype == "bar") {
			return getMax(datasetname);
		}
		else if (charttype == "horizontalBar") {
			return null;
		}
	}
}

function showGrid(e,axis) {
	if (e == null) {
		return true;
	}
	else if (e == "pie") {
		return false;
	}
	else {
		return true;
	}
}

function showAxis(e,axis) {
	if (e == "bar" && axis == "x") {
		return false;
	}
	else {
		if (e == null) {
			return true;
		}
		else if (e == "pie") {
			return false;
		}
		else {
			return true;
		}
	}
}

function changeClient(e,chartname,cookiename) {
	index = e.value * 1;
	cookie.set(cookiename, index, 31);
	Draw_Domain_Chart();
}

function changeColour(e,chartname,datasetname,cookiename) {
	colour = e.value * 1;
	if ( colour == 0 ) {
		chartname.config.data.datasets[0].backgroundColor = poolColors(datasetname.length);
	}
	else {
		chartname.config.data.datasets[0].backgroundColor = "rgba(2, 53, 135, 1)";
	}
	cookie.set(cookiename, colour, 31);
	chartname.update();
}

function changeLayout(e,chartname,cookiename) {
	layout = e.value * 1;
	if ( layout == 0 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "horizontalBar"
		}
		else {
			charttypedomain = "horizontalBar"
		}
	}
	else if ( layout == 1 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "bar"
		}
		else {
			charttypedomain = "bar"
		}
	}
	else if ( layout == 2 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "pie"
		}
		else {
			charttypedomain = "pie"
		}
	}
	cookie.set(cookiename, layout, 31);
	if ( chartname == "BarChartBlockedAds" ) {
		Draw_Ad_Chart();
	}
	else if ( chartname == "BarChartReqDomains" ) {
		Draw_Domain_Chart();
	}
}

function loadDivStats() {
	$.ajax({
		url: '/ext/uiDivStats/uidivstatstext.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout("loadDivStats();", 5000);
		},
		success: function(data){
			document.getElementById("divstats").innerHTML=data;
		}
	});
}
</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="action_script" value="start_uiDivStats">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="60">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div></td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tbody>
<tr bgcolor="#4D595D">
<td valign="top">
<div style="line-height:10px;">&nbsp;</div>
<div class="formfonttitle" style="margin-bottom:0px;" id="statstitle">Diversion Statistics</div>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable">
<thead class="collapsible default-collapsed" >
<tr>
<td colspan="2">Diversion Statistics Report (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td style="padding: 0px;">
<textarea cols="75" rows="35" wrap="off" readonly="readonly" id="divstats" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;border: none;padding: 0px;">"Stats will show here"</textarea>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable">
<thead class="collapsible default-collapsed" >
<tr>
<td colspan="2">Pixelserv Statistics Report (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td style="padding: 0px;">
<iframe src="/ext/uiDivStats/psstats.htm" style="width:99%;height:420px;"></iframe>
</td>
</tr>
</table><div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible">
<tr>
<td colspan="4" id="keystats">Key Stats (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even" style="text-align:center;">
<td width="25%" class="keystatscell">Total Queries</td>
<td width="25%" class="keystatscell">Queries Blocked</td>
<td width="25%" class="keystatscell">Percent Blocked</td>
<td width="25%" class="keystatscell">Domains on Blocklist</td>
</tr>
<tr class="even" style="text-align:center;">
<td width="25%" class="keystatscell keystatsnumber" id="keystatstotal">Total</td>
<td width="25%" class="keystatscell keystatsnumber" id="keystatsblocked">Blocked</td>
<td width="25%" class="keystatscell keystatsnumber" id="keystatspercent">Percent</td>
<td width="25%" class="keystatscell keystatsnumber" id="keystatsdomains">Domains</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible">
<tr>
<td colspan="2" id="topblocked">Top X blocked domains (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Style for charts</th>
<td>
<select style="width:100px" class="input_option" onchange="changeColour(this,BarChartBlockedAds,barDataBlockedAds,'colourads')" id="colourads">
<option value="0">Colour</option>
<option value="1">Plain</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Layout for charts</th>
<td>
<select style="width:100px" class="input_option" onchange="changeLayout(this,'BarChartBlockedAds','charttypeads')" id="charttypeads">
<option value="0">Horizontal</option>
<option value="1">Vertical</option>
<option value="2">Pie</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" style="padding: 2px;">
<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;"><canvas id="ChartAds" height="360" /></div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible">
<tr>
<td colspan="2" id="toprequested">Top X requested domains (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Client to display</th>
<td>
<select style="width:300px" class="input_option" onchange="changeClient(this,BarChartReqDomains,'clientdomains')" id="clientdomains">
<option value="0">All Clients</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Style for charts</th>
<td>
<select style="width:100px" class="input_option" onchange="changeColour(this,BarChartReqDomains,window['barDataDomains'+document.getElementById('clientdomains').value],'colourdomains')" id="colourdomains">
<option value="0">Colour</option>
<option value="1">Plain</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Layout for charts</th>
<td>
<select style="width:100px" class="input_option" onchange="changeLayout(this,'BarChartReqDomains','charttypedomains')" id="charttypedomains">
<option value="0">Horizontal</option>
<option value="1">Vertical</option>
<option value="2">Pie</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" style="padding: 2px;">
<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;"><canvas id="ChartDomains" height="360" /></div>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
</td>
</tr>
</tbody>
</table></td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<div id="footer">
</div>
</body>
</html>
