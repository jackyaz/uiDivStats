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
p {
  font-weight: bolder;
}

thead.collapsible {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

thead.collapsibleparent {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

td.nodata {
  font-size: 48px !important;
  font-weight: bolder !important;
  height: 65px !important;
  font-family: Arial !important;
}

.StatsTable {
  table-layout: fixed !important;
  width: 747px !important;
  text-align: center !important;
}

.StatsTable th {
  background-color: #1F2D35 !important;
  background: #2F3A3E !important;
  border-bottom: none !important;
  border-top: none !important;
  font-size: 12px !important;
  color: white !important;
  padding: 4px !important;
  width: 740px !important;
  font-weight: bolder !important;
}

.StatsTable td {
  padding: 2px !important;
  word-wrap: break-word !important;
  overflow-wrap: break-word !important;
  font-size: 16px !important;
  font-weight: bolder !important;
}

.StatsTable a {
  font-weight: bolder !important;
  text-decoration: underline !important;
}

.StatsTable th:first-child,
.StatsTable td:first-child {
  border-left: none !important;
}

.StatsTable th:last-child,
.StatsTable td:last-child {
  border-right: none !important;
}

.QueryFilter th {
  padding:2px !important;
  text-align:center !important;
}

.QueryFilter td {
  padding:2px !important;
  text-align:center !important;
}

div.queryTableContainer {
  height: 500px;
  overflow: auto;
  width: 750px;
  border: 1px solid #000;
}

thead.queryTableHeader th {
  background-image: linear-gradient(rgb(146, 160, 165) 0%, rgb(102, 117, 124) 100%);
  border-top: none !important;
	border-left: none !important;
	border-right: none !important;
	border-bottom: 1px solid #000 !important;
  font-weight: bolder;
  padding: 2px;
  text-align: center;
  color: #fff;
}

thead.queryTableHeader th:first-child,
thead.queryTableHeader th:last-child {
  border-right: none !important;
}

thead.queryTableHeader th:first-child,
thead.queryTableHeader td:first-child {
  border-left: none !important;
}

tbody.queryTableContent td, tbody.queryTableContent tr.queryNormalRow td {
  background-color: #2F3A3E !important;
  border-bottom: 1px solid #000 !important;
  border-left: none !important;
  border-right: 1px solid #000 !important;
  border-top: none !important;
  padding: 2px;
  text-align: center;
  overflow: hidden !important;
  white-space: nowrap !important;
}

tbody.queryTableContent tr.queryAlternateRow td {
  background-color: #475A5F !important;
  border-bottom: 1px solid #000 !important;
  border-left: none !important;
  border-right: 1px solid #000 !important;
  border-top: none !important;
  padding: 2px;
  overflow: hidden !important;
  white-space: nowrap !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-deferred.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/d3.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/uiDivStats/SQLData.js"></script>
<script>
var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)
var maxNoChartsBlocked = 6;
var currentNoChartsBlocked = 0;
var maxNoChartsTotal = 6;
var currentNoChartsTotal = 0;
var maxNoChartsTotalBlocked = 3;
var currentNoChartsTotalBlocked = 0;
var arrayqueryloglines = [];
var originalarrayqueryloglines = [];

Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
	return coordinates;
};

function keyHandler(e) {
	if (e.keyCode == 27){
		$j(document).off("keydown");
		ResetZoom();
	}
}

$j(document).keydown(function(e){keyHandler(e);});
$j(document).keyup(function(e){
	$j(document).keydown(function(e){
		keyHandler(e);
	});
});

var metriclist = ["Blocked","Total"];
var chartlist = ["daily","weekly","monthly"];
var timeunitlist = ["hour","day","day"];
var intervallist = [24,7,30];
var bordercolourlist = ["#fc8500","#42ecf5"];
var backgroundcolourlist = ["rgba(252,133,0,0.5)","rgba(66,236,245,0.5)"];

function Draw_Chart_NoData(txtchartname){
	document.getElementById("canvasChart" + txtchartname).width = "735";
	document.getElementById("canvasChart" + txtchartname).height = "500";
	document.getElementById("canvasChart" + txtchartname).style.width = "735px";
	document.getElementById("canvasChart" + txtchartname).style.height = "500px";
	var ctx = document.getElementById("canvasChart" + txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white';
	ctx.fillText('No data to display', 368, 250);
	ctx.restore();
}

function Draw_Chart(txtchartname){
	var chartperiod = getChartPeriod($j("#" + txtchartname + "_Period option:selected").val());
	var charttype = getChartType($j("#" + txtchartname + "_Type option:selected").val());
	var chartclient = $j("#" + txtchartname + "_Clients option:selected").text();
	
	var dataobject;
	if(chartclient == "All (*)"){
		dataobject = window[txtchartname+chartperiod];
	}
	else {
		dataobject = window[txtchartname+chartperiod+"clients"];
	}
	if(typeof dataobject === 'undefined' || dataobject === null) { Draw_Chart_NoData(txtchartname); return; }
	if (dataobject.length == 0) { Draw_Chart_NoData(txtchartname); return; }
	
	var chartData,chartLabels;
	
	if(chartclient == "All (*)"){
		chartData = dataobject.map(function(d) {return d.Count});
		chartLabels = dataobject.map(function(d) {return d.ReqDmn});
	}
	else {
		chartData = dataobject.filter(function(item) {
			return item.SrcIP == chartclient;
		}).map(function(d) {return d.Count});
		chartLabels = dataobject.filter(function(item) {
			return item.SrcIP == chartclient;
		}).map(function(d) {return d.ReqDmn});
	}
	var objchartname = window["Chart" + txtchartname];;
	
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("canvasChart" + txtchartname).getContext("2d");
	var chartOptions = {
		segmentShowStroke: false,
		segmentStrokeColor: "#000",
		animationEasing: "easeOutQuart",
		animationSteps: 100,
		maintainAspectRatio: false,
		animateScale: true,
		legend: {
			onClick: null,
			display: showLegend(charttype),
			position: "left",
			labels: {
				fontColor: "#ffffff"
			}
		},
		title: {
			display: showTitle(charttype),
			text: getChartLegendTitle(),
			position: "top"
		},
		tooltips: {
			callbacks: {
				title: function(tooltipItem, data) {
					return data.labels[tooltipItem[0].index];
				},
				label: function(tooltipItem, data) {
					return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]);
				}
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				display: showAxis(charttype, "x"),
				gridLines: {
					display: showGrid(charttype, "x"),
					color: "#282828"
				},
				scaleLabel: {
					display: true,
					labelString: getAxisLabel(charttype, "x")
				},
				ticks: {
					display: showTicks(charttype, "x"),
					beginAtZero: true,
					callback: function (value, index, values) {
						if(! isNaN(value)){
							return round(value,0).toFixed(0);
						} else {
							return value;
						}
					}
				}
			}],
			yAxes: [{
				display: showAxis(charttype, "y"),
				gridLines: {
					display: false,
					color: "#282828"
				},
				scaleLabel: {
					display: true,
					labelString: getAxisLabel(charttype, "y")
				},
				ticks: {
					display: showTicks(charttype, "y"),
					beginAtZero: false,
					callback: function (value, index, values) {
						if(! isNaN(value)){
							return round(value,0).toFixed(0);
						} else {
							return value;
						}
					}
				}
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: false,
					mode: ZoomPanEnabled(charttype),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttype, "x", chartData),
						y: ZoomPanMax(charttype, "y", chartData)
					}
				},
				zoom: {
					enabled: true,
					drag: true,
					mode: ZoomPanEnabled(charttype),
					rangeMin: {
						x: 0,
						y: 0
					},
					rangeMax: {
						x: ZoomPanMax(charttype, "x", chartData),
						y: ZoomPanMax(charttype, "y", chartData)
					},
					speed: 0.1
				}
			}
		}
	};
	var chartDataset = {
		labels: chartLabels,
		datasets: [{
			data: chartData,
			borderWidth: 1,
			backgroundColor: poolColors(chartLabels.length),
			borderColor: "#000000"
		}]
	};
	objchartname = new Chart(ctx, {
		type: charttype,
		options: chartOptions,
		data: chartDataset
	});
	window["Chart" + txtchartname] = objchartname;
}

function Draw_Time_Chart(txtchartname,txtunitx,numunitx){
	var chartperiod = getChartPeriod($j("#" + txtchartname + "time_Period option:selected").val());
	var txttitle = "DNS Queries";
	var txtunitx = timeunitlist[$j("#" + txtchartname + "time_Period option:selected").val()];
	var numunitx = intervallist[$j("#" + txtchartname + "time_Period option:selected").val()];
	var dataobject = window[txtchartname+chartperiod+"time"];
	
	if(typeof dataobject === 'undefined' || dataobject === null) { Draw_Chart_NoData(txtchartname+"time"); return; }
	if (dataobject.length == 0) { Draw_Chart_NoData(txtchartname+"time"); return; }
	
	var unique = [];
	var chartQueryTypes = [];
	for( let i = 0; i < dataobject.length; i++ ){
		if( !unique[dataobject[i].Fieldname]){
			chartQueryTypes.push(dataobject[i].Fieldname);
			unique[dataobject[i].Fieldname] = 1;
		}
	}
	
	var chartData = dataobject.map(function(d){ return {x: d.Time, y: d.QueryCount}});
	
	var objchartname = window["Chart" + txtchartname + "time"];;
	
	factor=0;
	if (txtunitx=="hour"){
		factor=60*60*1000;
	}
	else if (txtunitx=="day"){
		factor=60*60*24*1000;
	}
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("canvasChart"+txtchartname+"time").getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		hover: { mode: "point" },
		legend: { display: true, position: "top"},//, onClick: null },
		title: { display: true, text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return (moment(tooltipItem[0].xLabel,"X").format('YYYY-MM-DD HH:mm:ss')); },
					label: function (tooltipItem, data) { return data.datasets[tooltipItem.datasetIndex].label + ": " + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y;}
				},
				mode: 'x',
				position: 'cursor',
				intersect: false
		},
		scales: {
			xAxes: [{
				type: "time",
				gridLines: { display: true, color: "#282828" },
				ticks: {
					min: moment().subtract(numunitx, txtunitx+"s"),
					display: true
				},
				time: { parser: "X", unit: txtunitx, stepSize: 1 }
			}],
			yAxes: [{
				gridLines: { display: false, color: "#282828" },
				scaleLabel: { display: false, labelString: txttitle },
				ticks: {
					display: true,
					callback: function (value, index, values) {
						return round(value,0).toFixed(0);
					}
				},
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: false,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(chartData,"y","min",false),
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,"y","max",false),
					},
				},
				zoom: {
					enabled: true,
					drag: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(chartData,"y","min",false),
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,"y","max",false),
					},
					speed: 0.1
				},
			},
			deferred: {
				delay: 250
			},
		}
	};
	var lineDataset = {
		datasets: getDataSets(txtchartname, dataobject, chartQueryTypes)
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		data: lineDataset,
		options: lineOptions
	});
	window["Chart"+txtchartname+"time"]=objchartname;
}

function getDataSets(txtchartname, objdata, objQueryTypes) {
	var datasets = [];
	colourname="#fc8500";
	
	for(var i = 0; i < objQueryTypes.length; i++) {
		var querytypedata = objdata.filter(function(item) {
			return item.Fieldname == objQueryTypes[i];
		}).map(function(d) {return {x: d.Time, y: d.QueryCount}});
		
		datasets.push({ label: objQueryTypes[i], data: querytypedata, borderWidth: 1, pointRadius: 1, lineTension: 0, fill: true, backgroundColor: backgroundcolourlist[i], borderColor: bordercolourlist[i]});
	}
	datasets.reverse();
	return datasets;
}

function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get("uidivstats_"+cookiename)) != null) {
		return cookie.get("uidivstats_"+cookiename);
	}
	else {
		return 0;
	}
}

function SetCookie(cookiename,cookievalue) {
	cookie.set("uidivstats_"+cookiename, cookievalue, 31);
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	
	show_menu();
	
	$j("#uidivstats_title").after(BuildKeyStatsTableHtml("Key Stats", "keystats"));
	$j("#uidivstats_table_keystats").after(BuildChartHtml("Top requested domains", "Total", "false", "true"));
	$j("#uidivstats_table_keystats").after(BuildChartHtml("Top blocked domains", "Blocked", "false", "true"));
	$j("#uidivstats_table_keystats").after(BuildChartHtml("DNS Queries", "TotalBlockedtime", "true", "false"));
	for (i = 0; i < metriclist.length; i++) {
		$j("#"+metriclist[i]+"_Period").val(GetCookie(metriclist[i]+"_Period"));
		$j("#"+metriclist[i]+"_Type").val(GetCookie(metriclist[i]+"_Type"));
		for (i2 = 0; i2 < chartlist.length; i2++) {
			d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]));
			d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'clients.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]+"clients"));
		}
	}
	for (i = 0; i < chartlist.length; i++) {
		$j("#TotalBlockedtime_Period").val(GetCookie("TotalBlockedtime_Period"));
		d3.csv('/ext/uiDivStats/csv/TotalBlocked'+chartlist[i]+'time.htm').then(SetGlobalDataset.bind(null,"TotalBlocked"+chartlist[i]+"time"));
	}
	
	$j("#keystats_Period").val(GetCookie("keystats_Period")).change();
	
	get_querylog_file();
	
	Assign_EventHandlers();
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;
	
	if(txtchartname.indexOf("TotalBlocked") != -1){
		currentNoChartsTotalBlocked++;
		if(currentNoChartsTotalBlocked == maxNoChartsTotalBlocked) {
			Draw_Time_Chart("TotalBlocked");
		}
	}
	else if(txtchartname.indexOf("Blocked") != -1){
		currentNoChartsBlocked++;
		if(currentNoChartsBlocked == maxNoChartsBlocked) {
			SetClients("Blocked");
			Draw_Chart("Blocked");
		}
	}
	else if (txtchartname.indexOf("Total") != -1){
		currentNoChartsTotal++;
		if(currentNoChartsTotal == maxNoChartsTotal) {
			SetClients("Total");
			Draw_Chart("Total");
		}
	}
}

function SetClients(txtchartname){
	var dataobject = window[txtchartname+getChartPeriod($j("#" + txtchartname + "_Period option:selected").val())+"clients"];
	
	var unique = [];
	var chartClients = [];
	for( let i = 0; i < dataobject.length; i++ ){
		if( !unique[dataobject[i].SrcIP]){
			chartClients.push(dataobject[i].SrcIP);
			unique[dataobject[i].SrcIP] = 1;
		}
	}
	
	chartClients.sort();
	for (i = 0; i < chartClients.length; i++) {
		$j('#'+txtchartname+'_Clients').append($j('<option>', {
			value: i+1,
			text: chartClients[i]
		}));
	}
}

function reload() {
	location.reload(true);
}

function applyRule() {
	var action_script_tmp = "start_uiDivStats";
	document.form.action_script.value = action_script_tmp;
	var restart_time = document.form.action_wait.value*1;
	showLoading();
	document.form.submit();
}

function ToggleFill() {
	if(ShowFill == "false"){
		ShowFill = "origin";
		SetCookie("ShowFill","origin");
	}
	else {
		ShowFill = "false";
		SetCookie("ShowFill","false");
	}
	for(i = 0; i < metriclist.length; i++){
		for(i2 = 0; i2 < chartlist.length; i2++){
			window["Chart"+metriclist[i]+chartlist[i2]+"time"].data.datasets[0].fill=ShowFill;
			window["Chart"+metriclist[i]+chartlist[i2]+"time"].update();
		}
	}
}

function getLimit(datasetname,axis,maxmin,isannotation) {
	var limit=0;
	var values;
	if(axis == "x"){
		values = datasetname.map(function(o) { return o.x } );
	}
	else{
		values = datasetname.map(function(o) { return o.y } );
	}
	
	if(maxmin == "max"){
		limit=Math.max.apply(Math, values);
	}
	else{
		limit=Math.min.apply(Math, values);
	}
	if(maxmin == "max" && limit == 0 && isannotation == false){
		limit = 1;
	}
	return limit;
}

function getAverage(datasetname) {
	var total = 0;
	for(var i = 0; i < datasetname.length; i++) {
		total += (datasetname[i].y*1);
	}
	var avg = total / datasetname.length;
	return avg;
}

function getMax(datasetname) {
	return Math.max(...datasetname);
}

function round(value, decimals) {
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
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

function getChartType(layout) {
	var charttype = "horizontalBar";
	if (layout == 0) charttype = "horizontalBar";
	else if (layout == 1) charttype = "bar";
	else if (layout == 2) charttype = "pie";
	return charttype;
}

function getChartPeriod(period) {
	var chartperiod = "daily";
	if (period == 0) chartperiod = "daily";
	else if (period == 1) chartperiod = "weekly";
	else if (period == 2) chartperiod = "monthly";
	return chartperiod;
}

function ZoomPanEnabled(charttype) {
	if (charttype == "bar") {
		return 'y';
	}
	else if (charttype == "horizontalBar") {
		return 'x';
	}
	else {
		return '';
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
		else {
			return null;
		}
	}
	else if (axis == "y") {
		if (charttype == "bar") {
			return getMax(datasetname);
		}
		else if (charttype == "horizontalBar") {
			return null;
		}
		else {
			return null;
		}
	}
}

function ResetZoom(){
	for(i = 0; i < metriclist.length; i++){
		var chartobj = window["Chart"+metriclist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null) { continue; }
		chartobj.resetZoom();
	}
	var chartobj = window["ChartTotalBlockedtime"];
	if(typeof chartobj === 'undefined' || chartobj === null) { return; }
	chartobj.resetZoom();
}

function DragZoom(button){
	var drag = true;
	var pan = false;
	var buttonvalue = "";
	if(button.value.indexOf("On") != -1){
		drag = false;
		pan = true;
		buttonvalue = "Drag Zoom Off";
	}
	else {
		drag = true;
		pan = false;
		buttonvalue = "Drag Zoom On";
	}
	
	for(i = 0; i < metriclist.length; i++){
		for (i2 = 0; i2 < chartlist.length; i2++) {
			var chartobj = window["Chart"+metriclist[i]+chartlist[i2]];
			if(typeof chartobj === 'undefined' || chartobj === null) { continue; }
			chartobj.options.plugins.zoom.zoom.drag = drag;
			chartobj.options.plugins.zoom.pan.enabled = pan;
			button.value = buttonvalue;
			chartobj.update();
		}
	}
}

function showGrid(e, axis) {
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

function showAxis(e, axis) {
	if (e == "bar" && axis == "x") {
			return true;
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

function showTicks(e, axis) {
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

function showLegend(e) {
	if (e == "pie") {
		return true;
	}
	else {
		return false;
	}
}

function showTitle(e) {
	if (e == "pie") {
		return true;
	}
	else {
		return false;
	}
}

function getChartLegendTitle() {
	var chartlegendtitlelabel = "Domain name";
	
	for (i = 0; i < 350 - chartlegendtitlelabel.length; i++) {
		chartlegendtitlelabel = chartlegendtitlelabel + " ";
	}
	
	return chartlegendtitlelabel;
}

function getAxisLabel(type, axis) {
	var axislabel = "";
	if (axis == "x") {
		if (type == "horizontalBar") axislabel = "Hits";
			else if (type == "bar") {
				axislabel = "Domain";
			} else if (type == "pie") axislabel = "";
			return axislabel;
	} else if (axis == "y") {
		if (type == "horizontalBar") {
			axislabel = "Domain";
		} else if (type == "bar") axislabel = "Hits";
		else if (type == "pie") axislabel = "";
		return axislabel;
	}
}

function changeChart(e) {
	value = e.value * 1;
	name = e.id.substring(0, e.id.indexOf("_"));
	if(e.id.indexOf("Clients") == -1){
		SetCookie(e.id,value);
	}
	if(e.id.indexOf("Period") != -1){
		if(e.id.indexOf("TotalBlocked") == -1){
			$j("#"+name+"_Clients option[value!=0]").remove();
			SetClients(name);
		}
	}
	if(e.id.indexOf("time") == -1){
		Draw_Chart(name);
	}
	else{
		Draw_Time_Chart(name.replace("time",""));
	}
}

function changeTable(e) {
	value = e.value * 1;
	name = e.id.substring(0, e.id.indexOf("_"));
	SetCookie(e.id,value);
	
	var tableperiod = getChartPeriod(value);
	
	$j("#keystatstotal").text(window["QueriesTotal"+tableperiod]);
	$j("#keystatsblocked").text(window["QueriesBlocked"+tableperiod]);
	$j("#keystatspercent").text(window["BlockedPercentage"+tableperiod]);
}

function BuildChartHtml(txttitle, txtbase, istime, perip) {
	var charthtml = '<div style="line-height:10px;">&nbsp;</div>';
	charthtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_chart_' + txtbase + '">';
	charthtml += '<thead class="collapsible expanded"';
	charthtml += '<tr><td colspan="2">' + txttitle + ' (click to expand/collapse)</td></tr>';
	charthtml += '</thead>';
	charthtml += '<tr class="even">';
	charthtml += '<th width="40%">Period to display</th>';
	charthtml += '<td>';
	charthtml += '<select style="width:125px" class="input_option" onchange="changeChart(this)" id="' + txtbase + '_Period">';
	charthtml += '<option value=0>Last 24 hours</option>';
	charthtml += '<option value=1>Last 7 days</option>';
	charthtml += '<option value=2>Last 30 days</option>';
	charthtml += '</select>';
	charthtml += '</td>';
	charthtml += '</tr>';
	if (istime == "false") {
		charthtml += '<tr class="even">';
		charthtml += '<th width="40%">Layout for chart</th>';
		charthtml += '<td>';
		charthtml += '<select style="width:100px" class="input_option" onchange="changeChart(this)" id="' + txtbase + '_Type">';
		charthtml += '<option value=0>Horizontal</option>';
		charthtml += '<option value=1>Vertical</option>';
		charthtml += '<option value=2>Pie</option>';
		charthtml += '</select>';
		charthtml += '</td>';
		charthtml += '</tr>';
	}
	if (perip == "true") {
			charthtml += '<tr class="even">';
			charthtml += '<th width="40%">Client to display</th>';
			charthtml += '<td>';
			charthtml += '<select style="width:125px" class="input_option" onchange="changeChart(this)" id="' + txtbase + '_Clients">';
			charthtml += '<option value=0>All (*)</option>';
			charthtml += '</select>';
			charthtml += '</td>';
			charthtml += '</tr>';
	}
	charthtml += '<tr>';
	charthtml += '<td colspan="2" style="padding: 2px;">';
	charthtml += '<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;" id="divChart' + txtbase + '"><canvas id="canvasChart' + txtbase + '" height="500"></div>';
	charthtml += '</td>';
	charthtml += '</tr>';
	charthtml += '</table>';
	return charthtml;
}

function BuildKeyStatsTableHtml(txttitle, txtbase) {
	var tablehtml = '<div style="line-height:10px;">&nbsp;</div>';
	tablehtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_' + txtbase + '">';
	tablehtml += '<col style="width:40%;">';
	tablehtml += '<col style="width:60%;">';
	tablehtml += '<thead class="collapsible expanded">';
	tablehtml += '<tr><td colspan="2">' + txttitle + ' (click to expand/collapse)</td></tr>';
	tablehtml += '</thead>';
	tablehtml += '<div class="collapsiblecontent">';
	tablehtml += '<tr class="even">';
	tablehtml += '<th>Domains currently on blocklist</th>';
	tablehtml += '<td id="keystatsdomains" style="font-size: 16px; font-weight: bolder;">'+BlockedDomains+'</td>';
	tablehtml += '</tr>';
	tablehtml += '<tr class="even">';
	tablehtml += '<th>Period to display</th>';
	tablehtml += '<td colspan="2">';
	tablehtml += '<select style="width:125px" class="input_option" onchange="changeTable(this)" id="' + txtbase + '_Period">';
	tablehtml += '<option value=0>Last 24 hours</option>';
	tablehtml += '<option value=1>Last 7 days</option>';
	tablehtml += '<option value=2>Last 30 days</option>';
	tablehtml += '</select>';
	tablehtml += '</td>';
	tablehtml += '</tr>';
	tablehtml += '<tr style="line-height:5px;">';
	tablehtml += '<td colspan="2">&nbsp;</td>';
	tablehtml += '</tr>';
	tablehtml += '<tr>';
	tablehtml += '<td colspan="2" align="center" style="padding: 0px;">';
	tablehtml += '<table border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable StatsTable">';
	tablehtml += '<col style="width:250px;">';
	tablehtml += '<col style="width:250px;">';
	tablehtml += '<col style="width:250px;">';
	tablehtml += '<thead>';
	tablehtml += '<tr>';
	tablehtml += '<th>Total Queries</th>';
	tablehtml += '<th>Queries Blocked</th>';
	tablehtml += '<th>Percent Blocked</th>';
	tablehtml += '</tr>';
	tablehtml += '</thead>';
	tablehtml += '<tr class="even" style="text-align:center;">';
	tablehtml += '<td id="keystatstotal"></td>';
	tablehtml += '<td id="keystatsblocked"></td>';
	tablehtml += '<td id="keystatspercent"></td>';
	tablehtml += '</tr>';
	tablehtml += '</table>';
	tablehtml += '</td>';
	tablehtml += '</tr>';
	tablehtml += '<tr style="line-height:5px;">';
	tablehtml += '<td colspan="2">&nbsp;</td>';
	tablehtml += '</tr>';
	tablehtml += '</div>';
	tablehtml += '</table>';
	return tablehtml;
}

function BuildQueryLogTableHtml() {
	var tablehtml = '<table border="0" cellpadding="0" cellspacing="0" width="100%" class="queryTable" style="table-layout:fixed;">';
	tablehtml += '<col style="width:110px;">';
	tablehtml += '<col style="width:320px;">';
	tablehtml += '<col style="width:110px;">';
	tablehtml += '<col style="width:50px;">';
	tablehtml += '<col style="width:140px;">';
	tablehtml += '<thead class="queryTableHeader">';
	tablehtml += '<tr>';
	tablehtml += '<th>Time</th>';
	tablehtml += '<th>Domain</th>';
	tablehtml += '<th>Client</th>';
	tablehtml += '<th>Type</th>';
	tablehtml += '<th>Result</th>';
	tablehtml += '</tr>';
	tablehtml += '</thead>';
	tablehtml += '<tbody class="queryTableContent">';
	
	for(var i = 0; i < arrayqueryloglines.length; i++){
		tablehtml += '<tr>';
		tablehtml += '<td>'+arrayqueryloglines[i].Time+'</td>';
		tablehtml += '<td>'+arrayqueryloglines[i].ReqDmn+'</td>';
		tablehtml += '<td>'+arrayqueryloglines[i].SrcIP+'</td>';
		tablehtml += '<td>'+arrayqueryloglines[i].QryType+'</td>';
		tablehtml += '<td>'+arrayqueryloglines[i].Result+'</td>';
		tablehtml += '</tr>';
	}
	
	tablehtml += '</tbody>';
	tablehtml += '</table>';
	
	return tablehtml;
}

function get_querylog_file(){
	$j.ajax({
		url: '/ext/uiDivStats/csv/SQLQueryLog.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_querylog_file, 1000);
		},
		success: function(data){
			ParseQueryLog(data);
			if(document.getElementById("auto_refresh").checked){
				setTimeout("get_querylog_file();",60000);
			}
		}
	});
}

function ParseQueryLog(data){
	var arrayloglines = data.split("\n");
	arrayloglines = arrayloglines.filter(Boolean);
	arrayqueryloglines = [];
	for(var i = 0; i < arrayloglines.length; i++){
		var logfields = arrayloglines[i].split("|");
		var parsedlogline = new Object();
		parsedlogline.Time = moment.unix(logfields[0]).format('YYYY-MM-DD HH:mm').trim();
		parsedlogline.ReqDmn = logfields[1].trim();
		parsedlogline.SrcIP = logfields[2].trim();
		parsedlogline.QryType = logfields[3].trim();
		var parsedresult = logfields[4].replace(/"/g,'').trim();
		parsedlogline.Result = parsedresult.charAt(0).toUpperCase() + parsedresult.slice(1);
		arrayqueryloglines.push(parsedlogline);
	}
	FilterQueryLog();
}

function FilterQueryLog(){
	
	if(typeof originalarrayqueryloglines === 'undefined' || originalarrayqueryloglines === null) { originalarrayqueryloglines = arrayqueryloglines; }
	if (originalarrayqueryloglines.length == 0) { originalarrayqueryloglines = arrayqueryloglines; }
	
	if($j("#filter_result option:selected").val() != 0){
		arrayqueryloglines = originalarrayqueryloglines.filter(function(item){
			return item.Result == $j("#filter_result option:selected").text();
		});
	}
	else {
		arrayqueryloglines = originalarrayqueryloglines;
	}
	
	$j("#queryTableContainer").empty();
	$j("#queryTableContainer").append(BuildQueryLogTableHtml());
	stripedTable();
}

function Assign_EventHandlers(){
	$j("thead.collapsible").click(function(){
		$j(this).siblings().toggle("fast");
	})
	
	$j(".default-collapsed").trigger("click");
}

/* http://www.alistapart.com/articles/zebratables/ */
function stripedTable() {
	if (document.getElementById && document.getElementsByTagName) {
		var allTables = document.getElementsByClassName('queryTable');
		if (!allTables) { return; }
		
		for (var i = 0; i < allTables.length; i++) {
			var trs = allTables[i].getElementsByTagName("tr");
			for (var j = 0; j < trs.length; j++) {
				$j(trs[j]).removeClass('queryAlternateRow');
				$j(trs[j]).addClass('queryNormalRow');
			}
			for (var k = 0; k < trs.length; k += 2) {
				$j(trs[k]).removeClass('queryNormalRow');
				$j(trs[k]).addClass('queryAlternateRow');
			}
		}
	}
}

</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
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
<input type="hidden" name="amng_custom" id="amng_custom" value="">
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
<div class="formfonttitle" style="margin-bottom:0px;" id="uidivstats_title">Diversion Statistics</div>
<div style="line-height:10px;">&nbsp;</div>

<!-- Keystats table -->

<!-- Blocked Ads -->

<!-- Requested Ads -->

<!-- Start Query Log -->
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_querylog">
<col style="width:40%;">
<col style="width:60%;">
<thead class="collapsible expanded">
<tr><td colspan="2">Query Log (click to expand/collapse)</td></tr>
</thead>
<div class="collapsiblecontent">
<tr class="even">
<th>Update automatically?</th>
<td>
<label style="color:#FFCC00;display:block;">
<input type="checkbox" checked="" id="auto_refresh" style="padding:0;margin:0;vertical-align:middle;position:relative;top:-1px;" />&nbsp;&nbsp;Table will refresh every 60s</label>
</td>
</tr>
<tr style="line-height:5px;">
<td colspan="2">&nbsp;</td>
</tr>
<tr>
<td colspan="2" style="padding: 0px;">
<table style="table-layout:fixed;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable QueryFilter" id="uidivstats_table_filters_querylog">
<col style="width:110px;">
<col style="width:320px;">
<col style="width:110px;">
<col style="width:50px;">
<col style="width:156px;">
<thead>
<tr><td colspan="5">Filters</td></tr>
</thead>

<tr class="even">
<th>&nbsp;</th>
<th>Domain</th>
<th>Client</th>
<th>Type</th>
<th>Result</th>
</tr>
<tr>
<td>&nbsp;</td>
<td><input autocomplete="off" autocapitalize="off" type="text" class="input_30_table" name="filter_reqdmn" value="" data-lpignore="true" style="padding-left:0px;width:310px;text-align:center;"/></td>
<td><input autocomplete="off" autocapitalize="off" type="text" maxlength="15" class="input_20_table" name="filter_srcip" value="" onkeypress="return validator.isIPAddr(this, event)" data-lpignore="true" style="padding-left:0px;width:100px;text-align:center;"/></td>
<td>
<select style="width:45px" class="input_option" onchange="" id="filter_qrytype">
<option value="0">All</option>
<option value="1">A</option>
<option value="2">AAAA</option>
<option value="3">ANY</option>
<option value="4">SRV</option>
<option value="5">SOA</option>
<option value="6">PTR</option>
<option value="7">TXT</option>
</select>
</td>
<td>
<select style="width:125px" class="input_option" onchange="FilterQueryLog();" id="filter_result">
<option value="0">All</option>
<option value="1">Allowed</option>
<option value="2">Blocked (blacklist)</option>
<option value="3">Blocked (blocking list)</option>
<option value="4">Blocked (blocking list fs)</option>
<option value="5">Blocked (wildcard blacklist)</option>
<option value="6">Blocked (youtube blacklist)</option>
</select>
</td>
</tr>
</table>
</td>
</tr>
<tr style="line-height:5px;">
<td colspan="2">&nbsp;</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div id="queryTableContainer" class="queryTableContainer">
</div>
</td>
</tr>
</div>
</table>
<!-- End Query Log -->

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
