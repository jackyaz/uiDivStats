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
  overflow-y: scroll;
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
var $j=jQuery.noConflict(),maxNoChartsBlocked=6,currentNoChartsBlocked=0,maxNoChartsTotal=6,currentNoChartsTotal=0,maxNoChartsTotalBlocked=3,currentNoChartsTotalBlocked=0,arrayqueryloglines=[],originalarrayqueryloglines=[];Chart.defaults.global.defaultFontColor="#CCC",Chart.Tooltip.positioners.cursor=function(a,b){return b};function keyHandler(a){27==a.keyCode&&($j(document).off("keydown"),ResetZoom())}$j(document).keydown(function(a){keyHandler(a)}),$j(document).keyup(function(){$j(document).keydown(function(a){keyHandler(a)})});var metriclist=["Blocked","Total"],chartlist=["daily","weekly","monthly"],timeunitlist=["hour","day","day"],intervallist=[24,7,30],bordercolourlist=["#fc8500","#42ecf5"],backgroundcolourlist=["rgba(252,133,0,0.5)","rgba(66,236,245,0.5)"];function Draw_Chart_NoData(a){document.getElementById("canvasChart"+a).width="735",document.getElementById("canvasChart"+a).height="500",document.getElementById("canvasChart"+a).style.width="735px",document.getElementById("canvasChart"+a).style.height="500px";var b=document.getElementById("canvasChart"+a).getContext("2d");b.save(),b.textAlign="center",b.textBaseline="middle",b.font="normal normal bolder 48px Arial",b.fillStyle="white",b.fillText("No data to display",368,250),b.restore()}function Draw_Chart(a){var b,c=getChartPeriod($j("#"+a+"_Period option:selected").val()),d=getChartType($j("#"+a+"_Type option:selected").val()),e=$j("#"+a+"_Clients option:selected").text();if(b="All (*)"==e?window[a+c]:window[a+c+"clients"],"undefined"==typeof b||null===b)return void Draw_Chart_NoData(a);if(0==b.length)return void Draw_Chart_NoData(a);var f,g;"All (*)"==e?(f=b.map(function(a){return a.Count}),g=b.map(function(a){return a.ReqDmn})):(f=b.filter(function(a){return a.SrcIP==e}).map(function(a){return a.Count}),g=b.filter(function(a){return a.SrcIP==e}).map(function(a){return a.ReqDmn}));var h=window["Chart"+a];null!=h&&h.destroy();var j=document.getElementById("canvasChart"+a).getContext("2d"),k={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,legend:{onClick:null,display:showLegend(d),position:"left",labels:{fontColor:"#ffffff"}},title:{display:showTitle(d),text:getChartLegendTitle(),position:"top"},tooltips:{callbacks:{title:function(a,b){return b.labels[a[0].index]},label:function(a,b){return comma(b.datasets[a.datasetIndex].data[a.index])}},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{display:showAxis(d,"x"),gridLines:{display:showGrid(d,"x"),color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(d,"x")},ticks:{display:showTicks(d,"x"),beginAtZero:!0,callback:function(a){return isNaN(a)?a:round(a,0).toFixed(0)}}}],yAxes:[{display:showAxis(d,"y"),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(d,"y")},ticks:{display:showTicks(d,"y"),beginAtZero:!1,callback:function(a){return isNaN(a)?a:round(a,0).toFixed(0)}}}]},plugins:{zoom:{pan:{enabled:!1,mode:ZoomPanEnabled(d),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(d,"x",f),y:ZoomPanMax(d,"y",f)}},zoom:{enabled:!0,drag:!0,mode:ZoomPanEnabled(d),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(d,"x",f),y:ZoomPanMax(d,"y",f)},speed:.1}}}},l={labels:g,datasets:[{data:f,borderWidth:1,backgroundColor:poolColors(g.length),borderColor:"#000000"}]};h=new Chart(j,{type:d,options:k,data:l}),window["Chart"+a]=h}function Draw_Time_Chart(a,b,c){var d=getChartPeriod($j("#"+a+"time_Period option:selected").val()),e="DNS Queries",b=timeunitlist[$j("#"+a+"time_Period option:selected").val()],c=intervallist[$j("#"+a+"time_Period option:selected").val()],f=window[a+d+"time"];if("undefined"==typeof f||null===f)return void Draw_Chart_NoData(a+"time");if(0==f.length)return void Draw_Chart_NoData(a+"time");var g=[],h=[];for(let d=0;d<f.length;d++)g[f[d].Fieldname]||(h.push(f[d].Fieldname),g[f[d].Fieldname]=1);var j=f.map(function(a){return{x:a.Time,y:a.QueryCount}}),k=window["Chart"+a+"time"];factor=0,"hour"==b?factor=3600000:"day"==b&&(factor=86400000),k!=null&&k.destroy();var l=document.getElementById("canvasChart"+a+"time").getContext("2d"),m={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top"},title:{display:!0,text:e},tooltips:{callbacks:{title:function(a){return moment(a[0].xLabel,"X").format("YYYY-MM-DD HH:mm:ss")},label:function(a,b){return b.datasets[a.datasetIndex].label+": "+b.datasets[a.datasetIndex].data[a.index].y}},mode:"x",position:"cursor",intersect:!1},scales:{xAxes:[{type:"time",gridLines:{display:!0,color:"#282828"},ticks:{min:moment().subtract(c,b+"s"),display:!0},time:{parser:"X",unit:b,stepSize:1}}],yAxes:[{gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:e},ticks:{display:!0,callback:function(a){return round(a,0).toFixed(0)}}}]},plugins:{zoom:{pan:{enabled:!1,mode:"xy",rangeMin:{x:new Date().getTime()-factor*c,y:getLimit(j,"y","min",!1)},rangeMax:{x:new Date().getTime(),y:getLimit(j,"y","max",!1)}},zoom:{enabled:!0,drag:!0,mode:"xy",rangeMin:{x:new Date().getTime()-factor*c,y:getLimit(j,"y","min",!1)},rangeMax:{x:new Date().getTime(),y:getLimit(j,"y","max",!1)},speed:.1}},deferred:{delay:250}}},n={datasets:getDataSets(a,f,h)};k=new Chart(l,{type:"line",data:n,options:m}),window["Chart"+a+"time"]=k}function getDataSets(a,b,c){var d=[];colourname="#fc8500";for(var e,f=0;f<c.length;f++)e=b.filter(function(a){return a.Fieldname==c[f]}).map(function(a){return{x:a.Time,y:a.QueryCount}}),d.push({label:c[f],data:e,borderWidth:1,pointRadius:1,lineTension:0,fill:!0,backgroundColor:backgroundcolourlist[f],borderColor:bordercolourlist[f]});return d.reverse(),d}function GetCookie(a){var b;return null==(b=cookie.get("uidivstats_"+a))?0:cookie.get("uidivstats_"+a)}function SetCookie(a,b){cookie.set("uidivstats_"+a,b,31)}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function initial(){for(SetCurrentPage(),show_menu(),$j("#formfontdesc").after(BuildKeyStatsTableHtml("Key Stats","keystats")),$j("#uidivstats_table_keystats").after(BuildChartHtml("Top requested domains","Total","false","true")),$j("#uidivstats_table_keystats").after(BuildChartHtml("Top blocked domains","Blocked","false","true")),$j("#uidivstats_table_keystats").after(BuildChartHtml("DNS Queries","TotalBlockedtime","true","false")),i=0;i<metriclist.length;i++)for($j("#"+metriclist[i]+"_Period").val(GetCookie(metriclist[i]+"_Period")),$j("#"+metriclist[i]+"_Type").val(GetCookie(metriclist[i]+"_Type")),i2=0;i2<chartlist.length;i2++)d3.csv("/ext/uiDivStats/csv/"+metriclist[i]+chartlist[i2]+".htm").then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2])),d3.csv("/ext/uiDivStats/csv/"+metriclist[i]+chartlist[i2]+"clients.htm").then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]+"clients"));for(i=0;i<chartlist.length;i++)$j("#TotalBlockedtime_Period").val(GetCookie("TotalBlockedtime_Period")),d3.csv("/ext/uiDivStats/csv/TotalBlocked"+chartlist[i]+"time.htm").then(SetGlobalDataset.bind(null,"TotalBlocked"+chartlist[i]+"time"));$j("#keystats_Period").val(GetCookie("keystats_Period")).change(),get_querylog_file(),Assign_EventHandlers()}function SetGlobalDataset(a,b){window[a]=b,-1==a.indexOf("TotalBlocked")?-1==a.indexOf("Blocked")?-1!=a.indexOf("Total")&&(currentNoChartsTotal++,currentNoChartsTotal==maxNoChartsTotal&&(SetClients("Total"),Draw_Chart("Total"))):(currentNoChartsBlocked++,currentNoChartsBlocked==maxNoChartsBlocked&&(SetClients("Blocked"),Draw_Chart("Blocked"))):(currentNoChartsTotalBlocked++,currentNoChartsTotalBlocked==maxNoChartsTotalBlocked&&Draw_Time_Chart("TotalBlocked"))}function SetClients(a){var b=window[a+getChartPeriod($j("#"+a+"_Period option:selected").val())+"clients"],c=[],d=[];for(let e=0;e<b.length;e++)c[b[e].SrcIP]||(d.push(b[e].SrcIP),c[b[e].SrcIP]=1);for(d.sort(),i=0;i<d.length;i++)$j("#"+a+"_Clients").append($j("<option>",{value:i+1,text:d[i]}))}function reload(){location.reload(!0)}function applyRule(){document.form.action_script.value="start_uiDivStats";1*document.form.action_wait.value;showLoading(),document.form.submit()}function ToggleFill(){for("false"==ShowFill?(ShowFill="origin",SetCookie("ShowFill","origin")):(ShowFill="false",SetCookie("ShowFill","false")),i=0;i<metriclist.length;i++)for(i2=0;i2<chartlist.length;i2++)window["Chart"+metriclist[i]+chartlist[i2]+"time"].data.datasets[0].fill=ShowFill,window["Chart"+metriclist[i]+chartlist[i2]+"time"].update()}function getLimit(a,b,c,d){var e,f=0;return e="x"==b?a.map(function(a){return a.x}):a.map(function(a){return a.y}),f="max"==c?Math.max.apply(Math,e):Math.min.apply(Math,e),"max"==c&&0==f&&!1==d&&(f=1),f}function getAverage(a){for(var b=0,c=0;c<a.length;c++)b+=1*a[c].y;var d=b/a.length;return d}function getMax(a){return Math.max(...a)}function round(a,b){return+(Math.round(a+"e"+b)+"e-"+b)}function getRandomColor(){var a=Math.floor(255*Math.random()),c=Math.floor(255*Math.random()),d=Math.floor(255*Math.random());return"rgba("+a+","+c+","+d+", 1)"}function poolColors(b){var a=[];for(i=0;i<b;i++)a.push(getRandomColor());return a}function getChartType(a){var b="horizontalBar";return 0==a?b="horizontalBar":1==a?b="bar":2==a&&(b="pie"),b}function getChartPeriod(a){var b="daily";return 0==a?b="daily":1==a?b="weekly":2==a&&(b="monthly"),b}function ZoomPanEnabled(a){return"bar"==a?"y":"horizontalBar"==a?"x":""}function ZoomPanMax(a,b,c){if("x"==b)return"bar"==a?null:"horizontalBar"==a?getMax(c):null;return"y"==b?"bar"==a?getMax(c):"horizontalBar"==a?null:null:void 0}function ResetZoom(){for(i=0;i<metriclist.length;i++){var a=window["Chart"+metriclist[i]];"undefined"!=typeof a&&null!==a&&a.resetZoom()}var a=window.ChartTotalBlockedtime;"undefined"==typeof a||null===a||a.resetZoom()}function DragZoom(a){var b=!0,c=!1,d="";for(-1==a.value.indexOf("On")?(b=!0,c=!1,d="Drag Zoom On"):(b=!1,c=!0,d="Drag Zoom Off"),i=0;i<metriclist.length;i++)for(i2=0;i2<chartlist.length;i2++){var e=window["Chart"+metriclist[i]+chartlist[i2]];"undefined"!=typeof e&&null!==e&&(e.options.plugins.zoom.zoom.drag=b,e.options.plugins.zoom.pan.enabled=c,a.value=d,e.update())}}function showGrid(a){return!(null!=a)||"pie"!=a}function showAxis(a,b){return!("bar"!=a||"x"!=b)||null==a||"pie"!=a}function showTicks(a,b){return("bar"!=a||"x"!=b)&&(null==a||"pie"!=a)}function showLegend(a){return!("pie"!=a)}function showTitle(a){return!("pie"!=a)}function getChartLegendTitle(){var a="Domain name";for(i=0;i<350-a.length;i++)a+=" ";return a}function getAxisLabel(a,b){var c="";return"x"==b?("horizontalBar"==a?c="Hits":"bar"==a?c="Domain":"pie"==a&&(c=""),c):"y"==b?("horizontalBar"==a?c="Domain":"bar"==a?c="Hits":"pie"==a&&(c=""),c):void 0}function changeChart(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),-1==a.id.indexOf("Clients")&&SetCookie(a.id,value),-1!=a.id.indexOf("Period")&&-1==a.id.indexOf("TotalBlocked")&&($j("#"+name+"_Clients option[value!=0]").remove(),SetClients(name)),-1==a.id.indexOf("time")?Draw_Chart(name):Draw_Time_Chart(name.replace("time",""))}function changeTable(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),SetCookie(a.id,value);var b=getChartPeriod(value);$j("#keystatstotal").text(window["QueriesTotal"+b]),$j("#keystatsblocked").text(window["QueriesBlocked"+b]),$j("#keystatspercent").text(window["BlockedPercentage"+b])}function BuildChartHtml(a,b,c,d){var e="<div style=\"line-height:10px;\">&nbsp;</div>";return e+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable\" id=\"uidivstats_chart_"+b+"\">",e+="<thead class=\"collapsible expanded\"",e+="<tr><td colspan=\"2\">"+a+" (click to expand/collapse)</td></tr>",e+="</thead>",e+="<tr class=\"even\">",e+="<th width=\"40%\">Period to display</th>",e+="<td>",e+="<select style=\"width:125px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Period\">",e+="<option value=0>Last 24 hours</option>",e+="<option value=1>Last 7 days</option>",e+="<option value=2>Last 30 days</option>",e+="</select>",e+="</td>",e+="</tr>","false"==c&&(e+="<tr class=\"even\">",e+="<th width=\"40%\">Layout for chart</th>",e+="<td>",e+="<select style=\"width:100px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Type\">",e+="<option value=0>Horizontal</option>",e+="<option value=1>Vertical</option>",e+="<option value=2>Pie</option>",e+="</select>",e+="</td>",e+="</tr>"),"true"==d&&(e+="<tr class=\"even\">",e+="<th width=\"40%\">Client to display</th>",e+="<td>",e+="<select style=\"width:125px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Clients\">",e+="<option value=0>All (*)</option>",e+="</select>",e+="</td>",e+="</tr>"),e+="<tr>",e+="<td colspan=\"2\" style=\"padding: 2px;\">",e+="<div style=\"background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;\" id=\"divChart"+b+"\"><canvas id=\"canvasChart"+b+"\" height=\"500\"></div>",e+="</td>",e+="</tr>",e+="</table>",e}function BuildKeyStatsTableHtml(a,b){var c="<div style=\"line-height:10px;\">&nbsp;</div>";return c+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable\" id=\"uidivstats_table_"+b+"\">",c+="<col style=\"width:40%;\">",c+="<col style=\"width:60%;\">",c+="<thead class=\"collapsible expanded\">",c+="<tr><td colspan=\"2\">"+a+" (click to expand/collapse)</td></tr>",c+="</thead>",c+="<div class=\"collapsiblecontent\">",c+="<tr class=\"even\">",c+="<th>Domains currently on blocklist</th>",c+="<td id=\"keystatsdomains\" style=\"font-size: 16px; font-weight: bolder;\">"+BlockedDomains+"</td>",c+="</tr>",c+="<tr class=\"even\">",c+="<th>Period to display</th>",c+="<td colspan=\"2\">",c+="<select style=\"width:125px\" class=\"input_option\" onchange=\"changeTable(this)\" id=\""+b+"_Period\">",c+="<option value=0>Last 24 hours</option>",c+="<option value=1>Last 7 days</option>",c+="<option value=2>Last 30 days</option>",c+="</select>",c+="</td>",c+="</tr>",c+="<tr style=\"line-height:5px;\">",c+="<td colspan=\"2\">&nbsp;</td>",c+="</tr>",c+="<tr>",c+="<td colspan=\"2\" align=\"center\" style=\"padding: 0px;\">",c+="<table border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable StatsTable\">",c+="<col style=\"width:250px;\">",c+="<col style=\"width:250px;\">",c+="<col style=\"width:250px;\">",c+="<thead>",c+="<tr>",c+="<th>Total Queries</th>",c+="<th>Queries Blocked</th>",c+="<th>Percent Blocked</th>",c+="</tr>",c+="</thead>",c+="<tr class=\"even\" style=\"text-align:center;\">",c+="<td id=\"keystatstotal\"></td>",c+="<td id=\"keystatsblocked\"></td>",c+="<td id=\"keystatspercent\"></td>",c+="</tr>",c+="</table>",c+="</td>",c+="</tr>",c+="<tr style=\"line-height:5px;\">",c+="<td colspan=\"2\">&nbsp;</td>",c+="</tr>",c+="</div>",c+="</table>",c}function BuildQueryLogTableHtml(){var a="<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" class=\"queryTable\" style=\"table-layout:fixed;\">";a+="<col style=\"width:110px;\">",a+="<col style=\"width:320px;\">",a+="<col style=\"width:110px;\">",a+="<col style=\"width:50px;\">",a+="<col style=\"width:140px;\">",a+="<thead class=\"queryTableHeader\">",a+="<tr>",a+="<th>Time</th>",a+="<th>Domain</th>",a+="<th>Client</th>",a+="<th>Type</th>",a+="<th>Result</th>",a+="</tr>",a+="</thead>",a+="<tbody class=\"queryTableContent\">";for(var b=0;b<arrayqueryloglines.length;b++)a+="<tr>",a+="<td>"+arrayqueryloglines[b].Time+"</td>",a+="<td>"+arrayqueryloglines[b].ReqDmn+"</td>",a+="<td>"+arrayqueryloglines[b].SrcIP+"</td>",a+="<td>"+arrayqueryloglines[b].QryType+"</td>",a+="<td>"+arrayqueryloglines[b].Result+"</td>",a+="</tr>";return a+="</tbody>",a+="</table>",a}function get_querylog_file(){$j.ajax({url:"/ext/uiDivStats/csv/SQLQueryLog.htm",dataType:"text",error:function(){setTimeout(get_querylog_file,1e3)},success:function(a){ParseQueryLog(a),document.getElementById("auto_refresh").checked&&setTimeout("get_querylog_file();",6e4)}})}function ParseQueryLog(a){var b=a.split("\n");b=b.filter(Boolean),arrayqueryloglines=[];for(var c=0;c<b.length;c++){var d=b[c].split("|"),e={};e.Time=moment.unix(d[0]).format("YYYY-MM-DD HH:mm").trim(),e.ReqDmn=d[1].trim(),e.SrcIP=d[2].trim(),e.QryType=d[3].trim();var f=d[4].replace(/"/g,"").trim();e.Result=f.charAt(0).toUpperCase()+f.slice(1),arrayqueryloglines.push(e)}originalarrayqueryloglines=arrayqueryloglines,FilterQueryLog()}function FilterQueryLog(){""==$j("#filter_reqdmn").val()&&""==$j("#filter_srcip").val()&&0==$j("#filter_qrytype option:selected").val()&&0==$j("#filter_result option:selected").val()?arrayqueryloglines=originalarrayqueryloglines:(arrayqueryloglines=originalarrayqueryloglines,""!=$j("#filter_reqdmn").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.ReqDmn.toLowerCase().indexOf($j("#filter_reqdmn").val().toLowerCase())})),""!=$j("#filter_srcip").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.SrcIP.indexOf($j("#filter_srcip").val())})),0!=$j("#filter_qrytype option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return a.QryType==$j("#filter_qrytype option:selected").text()})),2==$j("#filter_result option:selected").val()?arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.Result.toLowerCase().indexOf("blocked")}):0!=$j("#filter_result option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return a.Result==$j("#filter_result option:selected").text()}))),$j("#queryTableContainer").empty(),$j("#queryTableContainer").append(BuildQueryLogTableHtml()),stripedTable()}function Assign_EventHandlers(){$j("thead.collapsible").click(function(){$j(this).siblings().toggle("fast")}),$j(".default-collapsed").trigger("click");let a=null,b=null;$j("#filter_reqdmn").on("keyup touchend",function(){clearTimeout(a),a=setTimeout(function(){FilterQueryLog()},1e3)}),$j("#filter_srcip").on("keyup touchend",function(){clearTimeout(b),b=setTimeout(function(){FilterQueryLog()},1e3)})}function stripedTable(){if(document.getElementById&&document.getElementsByTagName){var a=document.getElementsByClassName("queryTable");if(!a)return;for(var b,c=0;c<a.length;c++){b=a[c].getElementsByTagName("tr");for(var d=0;d<b.length;d++)$j(b[d]).removeClass("queryAlternateRow"),$j(b[d]).addClass("queryNormalRow");for(var e=0;e<b.length;e+=2)$j(b[e]).removeClass("queryNormalRow"),$j(b[e]).addClass("queryAlternateRow")}}}
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
<div>&nbsp;</div>
<div class="formfonttitle" id="scripttitle" style="text-align:center;">uiDivStats</div>
<div id="statstitle" style="text-align:center;">Stats last updated:</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div id="formfontdesc" class="formfontdesc">uiDivStats is a graphical representation of domain blocking performed by Diversion.</div>

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
<td><input autocomplete="off" autocapitalize="off" type="text" class="input_30_table" id="filter_reqdmn" name="filter_reqdmn" value="" data-lpignore="true" style="margin:0px;padding-left:0px;width:310px;text-align:center;"/></td>
<td><input autocomplete="off" autocapitalize="off" type="text" maxlength="15" class="input_20_table" id="filter_srcip" name="filter_srcip" value="" onkeypress="return validator.isIPAddr(this, event);" data-lpignore="true" style="margin:0px;padding-left:0px;width:100px;text-align:center;"/></td>
<td>
<select style="width:45px" class="input_option" onchange="FilterQueryLog();" id="filter_qrytype">
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
<option value="2">Blocked (all reasons)</option>
<option value="3">Blocked (blacklist)</option>
<option value="4">Blocked (blocking list)</option>
<option value="5">Blocked (blocking list fs)</option>
<option value="6">Blocked (wildcard blacklist)</option>
<option value="7">Blocked (youtube blacklist)</option>
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
