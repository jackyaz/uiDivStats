<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Diversion Statistics</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{
font-weight: bolder;
}
</style>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/chart.min.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/uidivstats.js"></script>

<script>
var barDataBlockedAds, barLabelsBlockedAds, barDataReqDomains, barLabelsReqDomains;
var BarChartBlockedAds, BarChartReqDomains;
var charttype;
Chart.defaults.global.defaultFontColor = "#CCC";

function Redraw_Ad_Chart() {
	barDataBlockedAds = [];
	barLabelsBlockedAds = [];
	GenChartDataAds();
	Draw_Ad_Chart();
}

function Redraw_Domain_Chart() {
	barDataReqDomains = [];
	barLabelsReqDomains = [];
	GenChartDataDomains();
	Draw_Domain_Chart();
}

function Draw_Ad_Chart() {
	if (barLabelsBlockedAds.length == 0) return;
	if (BarChartBlockedAds != undefined) BarChartBlockedAds.destroy();
	var ctx = document.getElementById("ChartAds").getContext("2d");
	var barOptionsAds = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		animateScale : true,
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: false },
		tooltips: {
			callbacks: {
				title: function (tooltipItem, data) { return data.labels[tooltipItem[0].index]; },
				label: function (tooltipItem, data) { return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]); },
			}
		},
		scales: {
			xAxes: [{
				gridLines: { display: true, color: "#282828" },
				ticks: { display: showXAxis(), beginAtZero: true}
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: "Blocks" },
				ticks: { beginAtZero: true}
			}]
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
		type: getChartType(),
		options: barOptionsAds,
		data: barDatasetAds
	});
	changeColour(E('colourads'),BarChartBlockedAds,barDataBlockedAds,colourads)
}

function initial(){
	var s;
	if ((s = cookie.get('colourads')) != null) {
			if (s.match(/^([0-1])$/)) {
				E('colourads').value = cookie.get('colourads') * 1;
			}
	}

	var t;
	if ((t = cookie.get('charttype')) != null) {
			if (t.match(/^([0-1])$/)) {
				E('charttypeads').value = cookie.get('charttypeads') * 1;
			}
	}

	show_menu();
	Redraw_Ad_Chart();
	changeLayout(E('charttypeads'),BarChartReqDomains,charttypedomains);
}

function reload() {
	location.reload(true);
}

function applyRule() {
	var action_script_tmp = "start_uiDivStats";
	document.form.action_script.value = action_script_tmp;
	document.form.submit();
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

function getChartType() {
	if (charttype == null)
	{
		return 'horizontalBar';
	}
	else
	{
		return charttype;
	}
}

function showXAxis() {
	if (charttype == null)
	{
		return true;
	}
	else if (charttype == "bar")
	{
		return false;
	}
	else
	{
		return true;
	}
}

function changeColour(e,chartname,datasetname,cookiename) {
	colour = e.value * 1;
	if ( colour == 0 )
	{
		chartname.config.data.datasets[0].backgroundColor = poolColors(datasetname.length);
	}
	else
	{
		chartname.config.data.datasets[0].backgroundColor = "rgba(2, 53, 135, 1)";
	}
	cookie.set(cookiename, colour, 31);
	chartname.update();
}

function changeLayout(e,chartname,cookiename) {
	layout = e.value * 1;
	if ( layout == 0 )
	{
		charttype = "horizontalBar"
	}
	else
	{
		charttype = "bar"
	}
	cookie.set(cookiename, layout, 31);
	if ( chartname == "BarChartBlockedAds" )
	{
		Redraw_Ad_Chart();
	}
	else if ( chartname == "BarChartReqDomains" )
	{
		Redraw_Domain_Chart();
	}
}
</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="action_script" value="start_uiDivStats">
<input type="hidden" name="current_page" value="Advanced_MultiSubnet_Content.asp">
<input type="hidden" name="next_page" value="Advanced_MultiSubnet_Content.asp">
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
<div class="formfonttitle" style="margin-bottom:0px;">Diversion Statistics</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D">
<!--<tr class="apply_gen" valign="top" height="35px">
<td>
<input type="button" onClick="applyRule();" value="Update Diversion Statistics" class="button_gen" name="button">
</td>
</tr>-->
<tr>
<td>
<textarea cols="63" rows="35" wrap="off" readonly="readonly" id="divstats" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;">"Stats will show here"</textarea>
<script language="JavaScript" type="text/javascript" src="/ext/uidivstatstext.js"></script>
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead>
<tr>
<td colspan="2">Top 10 blocked ad domains</td>
</tr>
</thead>
<tr class='even'>
<th width="40%">Style for charts</th>
<td>
<select style="width:100px" class="input_option" onchange='changeColour(this,BarChartBlockedAds,barDataBlockedAds,"colourads")' id='colourads'>
<option value=0>Colour</option>
<option value=1>Plain</option>
</select>
</td>
</tr>
<tr class='even'>
<th width="40%">Layout for charts</th>
<td>
<select style="width:100px" class="input_option" onchange='changeLayout(this,"BarChartBlockedAds","charttypeads")' id='charttypeads'>
<option value=0>Horizontal</option>
<option value=1>Vertical</option>
</select>
</td>
</tr>
<tr>
<td colspan="2">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="ChartAds" height="240"></div>
</td>
</tr>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead>
<tr>
<td colspan="2">Top 10 requested domains</td>
</tr>
</thead>
<tr class='even'>
<th width="40%">Style for charts</th>
<td>
<select style="width:100px" class="input_option" onchange='changeColour(this,BarChartReqDomains,barDataReqDomains,"colourdomains")' id='colourdomains'>
<option value=0>Colour</option>
<option value=1>Plain</option>
</select>
</td>
</tr>
<tr class='even'>
<th width="40%">Layout for charts</th>
<td>
<select style="width:100px" class="input_option" onchange='changeLayout(this,"BarChartReqDomains","charttypedomains")' id='charttypedomains'>
<option value=0>Horizontal</option>
<option value=1>Vertical</option>
</select>
</td>
</tr>
<tr>
<td colspan="2">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;padding-left:5px;"><canvas id="ChartDomains" height="240"></div>
</td>
</tr>
</table>
</td>
</tr>
</tbody>
</table>
</form>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
<div id="footer">
</div>
</body>
</html>
