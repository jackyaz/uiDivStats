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
  font-size: 14px !important;
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
					beginAtZero: true
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
					beginAtZero: false
				}
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: true,
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

function Draw_Time_Chart(txtchartname,txttitle,txtunity,txtunitx,numunitx,colourname){
	var objchartname=window["LineChart"+txtchartname];
	var objdataname=window[txtchartname+"size"];
	if(typeof objdataname === 'undefined' || objdataname === null) { Draw_Chart_NoData(txtchartname); return; }
	if (objdataname == 0) { Draw_Chart_NoData(txtchartname); return; }
	
	factor=0;
	if (txtunitx=="hour"){
		factor=60*60*1000;
	}
	else if (txtunitx=="day"){
		factor=60*60*24*1000;
	}
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("divLineChart"+txtchartname).getContext("2d");
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : "#000",
		animationEasing : "easeOutQuart",
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		hover: { mode: "point" },
		legend: { display: false, position: "bottom", onClick: null },
		title: { display: true, text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem, data) { return (moment(tooltipItem[0].xLabel,"X").format('YYYY-MM-DD HH:mm:ss')); },
					label: function (tooltipItem, data) { return data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y.toString() + ' ' + txtunity;}
				},
				mode: 'point',
				position: 'cursor',
				intersect: true
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
						return round(value,3).toFixed(3) + ' ' + txtunity;
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
						y: getLimit(txtchartname,"y","min",false) - Math.sqrt(Math.pow(getLimit(txtchartname,"y","min",false),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtchartname,"y","max",false) + getLimit(txtchartname,"y","max",false)*0.1,
					},
				},
				zoom: {
					enabled: true,
					drag: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(txtchartname,"y","min",false) - Math.sqrt(Math.pow(getLimit(txtchartname,"y","min",false),2))*0.1,
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(txtchartname,"y","max",false) + getLimit(txtchartname,"y","max",false)*0.1,
					},
					speed: 0.1
				},
			},
			datasource: {
				type: 'csv',
				url: '/ext/connmon/csv/'+txtchartname+'.htm',
				delimiter: ',',
				rowMapping: 'datapoint',
				datapointLabelMapping: {
					_dataset: 'Metric',
					x: 'Time',
					y: 'Value'
				}
			},
			deferred: {
				delay: 250
			},
		},
		annotation: {
			drawTime: 'afterDatasetsDraw',
			annotations: [{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getAverage(txtchartname),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Avg=" + round(getAverage(txtchartname),3).toFixed(3)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(txtchartname,"y","max",true),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Max=" + round(getLimit(txtchartname,"y","max",true),3).toFixed(3)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'y-axis-0',
				value: getLimit(txtchartname,"y","min",true),
				borderColor: colourname,
				borderWidth: 1,
				borderDash: [5, 5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: "sans-serif",
					fontSize: 10,
					fontStyle: "bold",
					fontColor: "#fff",
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: "center",
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: "Min=" + round(getLimit(txtchartname,"y","min",true),3).toFixed(3)+txtunity,
				}
			}]
		}
	};
	var lineDataset = {
		datasets: [{label: txttitle,
			borderWidth: 1,
			pointRadius: 1,
			lineTension: 0,
			fill: ShowFill,
			backgroundColor: colourname,
			borderColor: colourname,
		}]
	};
	objchartname = new Chart(ctx, {
		type: 'line',
		plugins: [ChartDataSource,datafilterPlugin],
		options: lineOptions,
		data: lineDataset
	});
	window["LineChart"+txtchartname]=objchartname;
}

function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get("uidivstats_"+cookiename)) != null) {
		return cookie.get("uidivstats_"+cookiename);
	}
	else {
		return "";
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
	
	$j("#uidivstats_title").after(BuildTableHtml("Key Stats", "keystats"));
	$j("#uidivstats_table_keystats").after(BuildChartHtml("Top requested domains", "Total", "true"));
	$j("#uidivstats_table_keystats").after(BuildChartHtml("Top blocked domains", "Blocked", "true"));
	for (i = 0; i < metriclist.length; i++) {
		$j("#"+metriclist[i]+"_Period").val(GetCookie(metriclist[i]+"_Period"));
		$j("#"+metriclist[i]+"_Type").val(GetCookie(metriclist[i]+"_Type"));
		for (i2 = 0; i2 < chartlist.length; i2++) {
			d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]));
			d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'clients.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]+"clients"));
		}
	}
	Assign_EventHandlers();
	
	//SetDivStatsTitle();
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;
	
	if(txtchartname.indexOf("Blocked") != -1){
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
	max = Math.max(...datasetname);
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
		$j("#"+name+"_Clients option[value!=0]").remove();
		SetClients(name);
	}
	Draw_Chart(name);
}

function BuildChartHtml(txttitle, txtbase, perip) {
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

function BuildTableHtml(txttitle, txtbase) {
		var tablehtml = '<div style="line-height:10px;">&nbsp;</div>';
		tablehtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_' + txtbase + '">';
		tablehtml += '<thead class="collapsible expanded">';
		tablehtml += '<tr><td colspan="2">' + txttitle + ' (click to expand/collapse)</td></tr>';
		tablehtml += '</thead>';
		tablehtml += '<tr>';
		tablehtml += '<td colspan="2" align="center" style="padding: 0px;">';
		tablehtml += '<div class="collapsiblecontent">';
		tablehtml += '<table border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable StatsTable">';
		tablehtml += '</tr>';
		tablehtml += '<col style="width:187.5px;">';
		tablehtml += '<col style="width:187.5px;">';
		tablehtml += '<col style="width:187.5px;">';
		tablehtml += '<col style="width:187.5px;">';
		tablehtml += '<thead>';
		tablehtml += '<tr>';
		tablehtml += '<th>Total Queries</th>';
		tablehtml += '<th>Queries Blocked</th>';
		tablehtml += '<th>Percent Blocked</th>';
		tablehtml += '<th>Domains on Blocklist</th>';
		tablehtml += '</tr>';
		tablehtml += '</thead>';
		tablehtml += '<tr class="even" style="text-align:center;">';
		tablehtml += '<td id="keystatstotal">'+QueriesTotal+'</td>';
		tablehtml += '<td id="keystatsblocked">'+QueriesBlocked+'</td>';
		tablehtml += '<td id="keystatspercent">'+BlockedPercentage+'</td>';
		tablehtml += '<td id="keystatsdomains">'+BlockedDomains+'</td>';
		tablehtml += '</tr>';
		tablehtml += '</table>';
		tablehtml += '</div>';
		tablehtml += '</td>';
		tablehtml += '</tr>';
		tablehtml += '</table>';
		return tablehtml;
}

function Assign_EventHandlers(){
	$j("thead.collapsible").click(function(){
		$j(this).siblings().toggle("fast");
	})
	
	$j(".default-collapsed").trigger("click");
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
