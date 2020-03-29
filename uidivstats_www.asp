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

td.keystatsnumber {
  font-size: 20px !important;
  font-weight: bolder !important;
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
}

.StatsTable td {
  padding: 2px !important;
  word-wrap: break-word !important;
  overflow-wrap: break-word !important;
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
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
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
<script language="JavaScript" type="text/javascript" src="/ext/uiDivStats/uidivstatsclients.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/uiDivStats/uidivstatstext.js"></script>

<script>
var charttypead, charttypedomain;
var BarChartReqDomains;
Chart.defaults.global.defaultFontColor = "#CCC";
Chart.Tooltip.positioners.cursor = function(chartElements, coordinates) {
	return coordinates;
};

function Draw_Chart_NoData(txtchartname){
	document.getElementById("divChart" + txtchartname).width = "735";
	document.getElementById("divChart" + txtchartname).height = "400";
	document.getElementById("divChart" + txtchartname).style.width = "735px";
	document.getElementById("divChart" + txtchartname).style.height = "400px";
	var ctx = document.getElementById("divChart" + txtchartname).getContext("2d");
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = "normal normal bolder 48px Arial";
	ctx.fillStyle = 'white';
	ctx.fillText('No data to display', 368, 200);
	ctx.restore();
}

function Draw_Chart(txtchartname) {
	var objchartname = window["Chart" + txtchartname];
	var objdataname = window["Data" + txtchartname];
	var objlabeldataname = window["Labels" + txtchartname];
	var charttype = getChartType($("#" + txtchartname + "_Type option:selected").val());
	if (typeof objdataname === 'undefined' || objdataname === null) {
		Draw_Chart_NoData(txtchartname);
		return;
	}
	if (objdataname.length == 1 && objdataname[0] == "") {
		Draw_Chart_NoData(txtchartname);
		return;
	}
	if (typeof objlabeldataname === 'undefined' || objlabeldataname === null) {
		Draw_Chart_NoData(txtchartname);
		return;
	}
	if (objlabeldataname.length == 0) {
		Draw_Chart_NoData(txtchartname);
		return;
	}
		
	if (objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById("divChart" + txtchartname).getContext("2d");
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
			//text: getChartLegendTitle(charttype, txtchartname),
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
					//labelString: getAxisLabel(charttype, "x", txtchartname)
				},
				ticks: {
					display: showTicks(charttype, "x"),
					beginAtZero: false
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
					//labelString: getAxisLabel(charttype, "y", txtchartname)
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
						x: ZoomPanMax(charttype, "x", objdataname),
						y: ZoomPanMax(charttype, "y", objdataname)
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
						x: ZoomPanMax(charttype, "x", objdataname),
						y: ZoomPanMax(charttype, "y", objdataname)
					},
					speed: 0.1
				}
			}
		}
	};
	var chartDataset = {
		labels: window["Labels" + txtchartname],
		datasets: [{
			data: objdataname,
			borderWidth: 1,
			backgroundColor: poolColors(objdataname.length),
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
		/*animation: {
			duration: 0 // general animation time
		},
		responsiveAnimationDuration: 0, */ // animation duration after a resize
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
		type: getChartType($("#charttypedomains option:selected").val()),
		options: barOptionsDomains,
		data: barDatasetDomains
	});
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
	GetCookie("charttypeads");
	
	show_menu();
	loadDivStats();
	Draw_Domain_Chart();
	changeLayout(E('charttypedomains'),"BarChartReqDomains","charttypedomains");
	
	$("#BlockedAds_Type").val(GetCookie("BlockedAds_Type"));
	Draw_Chart("BlockedAds");
	
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

function ZoomPanEnabled(charttype) {
	if (charttype == "bar") {
			return 'y';
	} else if (charttype == "horizontalBar") {
			return 'x';
	} else {
			return '';
	}
}

function ZoomPanMax(charttype, axis, datasetname) {
	if (axis == "x") {
			if (charttype == "bar") {
					return null;
			} else if (charttype == "horizontalBar") {
					return getMax(datasetname);
			} else {
					return null;
			}
	} else if (axis == "y") {
			if (charttype == "bar") {
					return getMax(datasetname);
			} else if (charttype == "horizontalBar") {
					return null;
			} else {
					return null;
			}
	}
}

function showGrid(e, axis) {
	if (e == null) {
			return true;
	} else if (e == "pie") {
			return false;
	} else {
			return true;
	}
}

function showAxis(e, axis) {
	if (e == "bar" && axis == "x") {
			return true;
	} else {
			if (e == null) {
					return true;
			} else if (e == "pie") {
					return false;
			} else {
					return true;
			}
	}
}

function showTicks(e, axis) {
	if (e == "bar" && axis == "x") {
			return false;
	} else {
			if (e == null) {
					return true;
			} else if (e == "pie") {
					return false;
			} else {
					return true;
			}
	}
}

function showLegend(e) {
	if (e == "pie") {
			return true;
	} else {
			return false;
	}
}

function showTitle(e) {
	if (e == "pie") {
			return true;
	} else {
			return false;
	}
}

function changeChart(e) {
	value = e.value * 1;
	name = e.id.substring(0, e.id.indexOf("_"));
	SetCookie("BlockedAds_Type",value);
	Draw_Chart(name);
}

function BuildChartHtml(txttitle, txtbase, multilabel) {
	var charthtml = '<div style="line-height:10px;">&nbsp;</div>';
	charthtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">';
	charthtml += '<thead class="collapsible expanded" id="uidivstats_chart_' + txtbase + '"';
	charthtml += '<tr><td colspan="2">' + txttitle + ' (click to expand/collapse)</td></tr>';
	charthtml += '</thead>';
	/* Colour selector start ---
	charthtml+='<tr class="even">';
	charthtml+='<th width="40%">Style for chart</th>';
	charthtml+='<td>';
	charthtml+='<select style="width:100px" class="input_option" onchange="changeChart(this,\''+multilabel+'\')" id="' + txtbase + '_Colour">';
	charthtml+='<option value=0>Colour</option>';
	charthtml+='<option value=1>Plain</option>';
	charthtml+='</select>';
	charthtml+='</td>';
	charthtml+='</tr>';
	--- Colour selector end */
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
			charthtml += '<select style="width:100px" class="input_option" onchange="changeChart(this)" id="' + txtbase + '_Clients">';
			charthtml += '<option value=0>All (*)</option>';
			charthtml += '</select>';
			charthtml += '</td>';
			charthtml += '</tr>';
	}
	charthtml += '<tr>';
	charthtml += '<td colspan="2" style="padding: 2px;">';
	charthtml += '<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;"><canvas id="divChart' + txtbase + '" height="360"></div>';
	charthtml += '</td>';
	charthtml += '</tr>';
	charthtml += '</table>';
	return charthtml;
}

function changeLayout(e,chartname,cookiename) {
	layout = e.value * 1;
	if ( layout == 0 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "horizontalBar";
		}
		else {
			charttypedomain = "horizontalBar";
		}
	}
	else if ( layout == 1 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "bar";
		}
		else {
			charttypedomain = "bar";
		}
	}
	else if ( layout == 2 ) {
		if ( chartname == "BarChartBlockedAds" ) {
			charttypead = "pie";
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

function changeClient(e,chartname,cookiename) {
	index = e.value * 1;
	cookie.set(cookiename, index, 31);
	Draw_Domain_Chart();
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
<th width="40%">Layout for charts</th>
<td>
<select style="width:100px" class="input_option" onchange="changeChart(this)" id="BlockedAds_Type">
<option value="0">Horizontal</option>
<option value="1">Vertical</option>
<option value="2">Pie</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" style="padding: 2px;">
<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;"><canvas id="divChartBlockedAds" height="400" /></div>
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
