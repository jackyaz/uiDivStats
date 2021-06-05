<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>uiDivStats</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p{font-weight:bolder}thead.collapsible-jquery{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}.nodata{height:65px!important;border:none!important;text-align:center!important;font:bolder 48px Arial!important}.StatsTable{table-layout:fixed!important;width:747px!important;text-align:center!important}.StatsTable th{background-color:#1F2D35!important;background:#2F3A3E!important;border-bottom:none!important;border-top:none!important;font-size:12px!important;color:#fff!important;padding:4px!important;width:740px!important;font-weight:bolder!important}.StatsTable td{padding:2px!important;word-wrap:break-word!important;overflow-wrap:break-word!important;font-size:16px!important;font-weight:bolder!important}.StatsTable a{font-weight:bolder!important;text-decoration:underline!important}.StatsTable th:first-child,.StatsTable td:first-child{border-left:none!important}.StatsTable th:last-child,.StatsTable td:last-child{border-right:none!important}.QueryFilter th{padding:2px!important;text-align:center!important}.QueryFilter td{padding:2px!important;text-align:center!important}div.sortTableContainer{height:500px;overflow-y:scroll;width:750px;border:1px solid #000}.sortTable{table-layout:fixed!important;border:none}thead.sortTableHeader th{background-image:linear-gradient(#92a0a5 0%,#66757c 100%);border-top:none!important;border-left:none!important;border-right:none!important;border-bottom:1px solid #000!important;font-weight:bolder;padding:2px;text-align:center;color:#fff;position:sticky;top:0}th.sortable{cursor:pointer}thead.sortTableHeader th:first-child,thead.sortTableHeader th:last-child{border-right:none!important}thead.sortTableHeader th:first-child,thead.sortTableHeader td:first-child{border-left:none!important}tbody.sortTableContent td,tbody.sortTableContent td{background-color:#2F3A3E!important;border-bottom:1px solid #000!important;border-left:none!important;border-right:1px solid #000!important;border-top:none!important;padding:2px;text-align:center;overflow:hidden!important;white-space:nowrap!important}tbody.sortTableContent tr.sortRow:nth-child(odd) td{background-color:#2F3A3E!important}tbody.sortTableContent tr.sortRow:nth-child(even) td{background-color:#475A5F!important}.SettingsTable{text-align:left}.SettingsTable input{text-align:left;margin-left:3px!important}.SettingsTable input.savebutton{text-align:center;margin-top:5px;margin-bottom:5px;border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000}.SettingsTable td.savebutton{border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000;background-color:#4d595d}.SettingsTable .cronbutton{text-align:center;min-width:50px;width:50px;height:23px;vertical-align:middle}.SettingsTable select{margin-left:3px!important}.SettingsTable label{margin-right:10px!important;vertical-align:top!important}.SettingsTable th{background-color:#1F2D35!important;background:#2F3A3E!important;border-bottom:none!important;border-top:none!important;font-size:12px!important;color:#fff!important;padding:4px!important;font-weight:bolder!important;padding:0!important}.SettingsTable td{word-wrap:break-word!important;overflow-wrap:break-word!important;border-right:none;border-left:none}.SettingsTable span.settingname{background-color:#1F2D35!important;background:#2F3A3E!important}.SettingsTable td.settingname{border-right:solid 1px #000;border-left:solid 1px #000;background-color:#1F2D35!important;background:#2F3A3E!important;width:35%!important}.SettingsTable td.settingvalue{text-align:left!important;border-right:solid 1px #000}.SettingsTable th:first-child{border-left:none!important}.SettingsTable th:last-child{border-right:none!important}.SettingsTable .invalid{background-color:#8b0000!important}.SettingsTable .disabled{background-color:#CCC!important;color:#888!important}.removespacing{padding-left:0!important;margin-left:0!important;margin-bottom:5px!important;text-align:center!important}textarea.settings{padding:2px!important;background:#576D73!important;width:98%!important;font:13px 'Courier New',Courier,mono!important}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/d3.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script>
var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for(var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings,prop)){
			if(prop.indexOf('uidivstats') != -1 && prop.indexOf('uidivstats_version') == -1){
				eval('delete custom_settings.'+prop)
			}
		}
	}
}
var tout,$j=jQuery.noConflict(),maxNoChartsBlocked=6,currentNoChartsBlocked=0,maxNoChartsTotal=6,currentNoChartsTotal=0,maxNoChartsTotalBlocked=3,currentNoChartsTotalBlocked=0,maxNoChartsOverall=15,currentNoChartsOverall=0,arrayqueryloglines=[],originalarrayqueryloglines=[],sortfield="Time",sortname="Time",sortdir="desc";Chart.defaults.global.defaultFontColor="#CCC",Chart.Tooltip.positioners.cursor=function(a,b){return b};function keyHandler(a){82==a.keyCode?($j(document).off("keydown"),ResetZoom()):70==a.keyCode&&($j(document).off("keydown"),ToggleFill())}function isFilterIP(a,b){var c,d,e=b.keyCode?b.keyCode:b.which;if(validator.isFunctionButton(b))return!0;if(33==e)return!0;if(47<e&&58>e){d=0;for(var c=0;c<a.value.length;c++)"."==a.value.charAt(c)&&d++;return 3>d&&3<=c&&"."!=a.value.charAt(c-3)&&"."!=a.value.charAt(c-2)&&"."!=a.value.charAt(c-1)&&(a.value+="."),!0}if(46==e){d=0;for(var c=0;c<a.value.length;c++)"."==a.value.charAt(c)&&d++;return"."!=a.value.charAt(c-1)&&3!=d}return 13==e||!!(b.metaKey&&(65==e||67==e||86==e||88==e||97==e||99==e||118==e||120==e))}function Validate_Number_Setting(a,b,c){var d=a.name,e=1*a.value;return e>b||e<c?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Format_Number_Setting(a){var b=a.name,c=1*a.value;return 0!=a.value.length&&c!=NaN&&(a.value=parseInt(a.value),!0)}function Validate_All(){var a=!1;return Validate_Number_Setting(document.form.uidivstats_daystokeep,365,30)||(a=!0),!a||(alert("Validation for some fields failed. Please correct invalid values and try again."),!1)}$j(document).keydown(function(a){keyHandler(a)}),$j(document).keyup(function(){$j(document).keydown(function(a){keyHandler(a)})});var metriclist=["Blocked","Total"],chartlist=["daily","weekly","monthly"],timeunitlist=["hour","day","day"],intervallist=[24,7,30],bordercolourlist=["#fc8500","#42ecf5"],backgroundcolourlist=["rgba(252,133,0,0.5)","rgba(66,236,245,0.5)"];function Draw_Chart_NoData(a){document.getElementById("canvasChart"+a).width="735",document.getElementById("canvasChart"+a).height="500",document.getElementById("canvasChart"+a).style.width="735px",document.getElementById("canvasChart"+a).style.height="500px";var b=document.getElementById("canvasChart"+a).getContext("2d");b.save(),b.textAlign="center",b.textBaseline="middle",b.font="normal normal bolder 48px Arial",b.fillStyle="white",b.fillText("Data loading...",368,250),b.restore()}function Draw_Chart(a){var b,c=getChartPeriod($j("#"+a+"_Period option:selected").val()),d=getChartType($j("#"+a+"_Type option:selected").val()),e=$j("#"+a+"_Clients option:selected").text(),f=e.substring(e.indexOf("(")+1,e.indexOf(")",e.indexOf("(")+1));if(b="All (*)"==e?window[a+c]:window[a+c+"clients"],"undefined"==typeof b||null===b)return void Draw_Chart_NoData(a);if(0==b.length)return void Draw_Chart_NoData(a);var g,h;"All (*)"==e?(g=b.map(function(a){return a.Count}),h=b.map(function(a){return a.ReqDmn})):(g=b.filter(function(a){return a.SrcIP==f}).map(function(a){return a.Count}),h=b.filter(function(a){return a.SrcIP==f}).map(function(a){return a.ReqDmn})),$j.each(h,function(a,b){h[a]=chunk(b.toLowerCase(),30).join("\n")});var i=window["Chart"+a];null!=i&&i.destroy();var j=document.getElementById("canvasChart"+a).getContext("2d"),k={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,legend:{onClick:null,display:showLegend(d),position:"left",labels:{fontColor:"#ffffff"}},layout:{padding:{top:getChartPadding(d)}},title:{display:showTitle(d),text:getChartLegendTitle(),position:"top"},tooltips:{callbacks:{title:function(a,b){return b.labels[a[0].index]},label:function(a,b){return comma(b.datasets[a.datasetIndex].data[a.index])}},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{display:showAxis(d,"x"),type:getChartScale($j("#"+a+"_Scale option:selected").val(),d,"x"),gridLines:{display:showGrid(d,"x"),color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(d,"x")},ticks:{display:showTicks(d,"x"),beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}],yAxes:[{display:showAxis(d,"y"),type:getChartScale($j("#"+a+"_Scale option:selected").val(),d,"y"),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(d,"y")},ticks:{display:showTicks(d,"y"),beginAtZero:!0,autoSkip:!1,lineHeight:.8,padding:-5,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:!1,mode:ZoomPanEnabled(d),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(d,"x",g),y:ZoomPanMax(d,"y",g)}},zoom:{enabled:!0,drag:!0,mode:ZoomPanEnabled(d),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(d,"x",g),y:ZoomPanMax(d,"y",g)},speed:.1}}}},l={labels:h,datasets:[{data:g,borderWidth:1,backgroundColor:poolColors(h.length),borderColor:"#000000"}]};i=new Chart(j,{type:d,options:k,data:l,plugins:[{beforeInit:function(a){a.data.labels.forEach(function(b,c,d){/\n/.test(b)&&(d[c]=b.split(/\n/))})}}]}),window["Chart"+a]=i}function Draw_Time_Chart(a){var b=getChartPeriod($j("#"+a+"time_Period option:selected").val()),c="DNS Queries",d=timeunitlist[$j("#"+a+"time_Period option:selected").val()],e=intervallist[$j("#"+a+"time_Period option:selected").val()],f=window[a+b+"time"];if("undefined"==typeof f||null===f)return void Draw_Chart_NoData(a+"time");if(0==f.length)return void Draw_Chart_NoData(a+"time");var g=[],h=[];for(let b=0;b<f.length;b++)g[f[b].Fieldname]||(h.push(f[b].Fieldname),g[f[b].Fieldname]=1);var i=f.map(function(a){return{x:a.Time,y:a.QueryCount}}),j=window["Chart"+a+"time"];factor=0,"hour"==d?factor=3600000:"day"==d&&(factor=86400000),j!=null&&j.destroy();var k=document.getElementById("canvasChart"+a+"time").getContext("2d"),l={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top"},title:{display:!0,text:c},tooltips:{callbacks:{title:function(a){return moment(a[0].xLabel,"X").format("YYYY-MM-DD HH:mm:ss")},label:function(a,b){return b.datasets[a.datasetIndex].label+": "+b.datasets[a.datasetIndex].data[a.index].y}},mode:"x",position:"cursor",intersect:!1},scales:{xAxes:[{type:"time",gridLines:{display:!0,color:"#282828"},ticks:{min:moment().subtract(e,d+"s"),display:!0},time:{parser:"X",unit:d,stepSize:1}}],yAxes:[{type:getChartScale($j("#"+a+"time_Scale option:selected").val(),"time","y"),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:c},ticks:{display:!0,beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:!1,mode:"xy",rangeMin:{x:new Date().getTime()-factor*e,y:getLimit(i,"y","min",!1)},rangeMax:{x:new Date().getTime(),y:getLimit(i,"y","max",!1)}},zoom:{enabled:!0,drag:!0,mode:"xy",rangeMin:{x:new Date().getTime()-factor*e,y:getLimit(i,"y","min",!1)},rangeMax:{x:new Date().getTime(),y:getLimit(i,"y","max",!1)},speed:.1}}}},m={datasets:getDataSets(a,f,h)};j=new Chart(k,{type:"line",data:m,options:l}),window["Chart"+a+"time"]=j}function getDataSets(a,b,c){var d=[];colourname="#fc8500";for(var e,f=0;f<c.length;f++)e=b.filter(function(a){return a.Fieldname==c[f]}).map(function(a){return{x:a.Time,y:a.QueryCount}}),d.push({label:c[f],data:e,borderWidth:1,pointRadius:1,lineTension:0,fill:!0,backgroundColor:backgroundcolourlist[f],borderColor:bordercolourlist[f]});return d.reverse(),d}function chunk(a,b){for(var c,d,e=[],c=0,d=a.length;c<d;c+=b)e.push(a.substr(c,b));return e}function LogarithmicFormatter(a,b,c){if("logarithmic"!=this.type)return isNaN(a)?a:round(a,0).toFixed(0);var d=this.options.ticks.labels||{},e=d.index||["min","max"],f=d.significand||[1,2,5],g=a/Math.pow(10,Math.floor(Chart.helpers.log10(a))),h=!0===d.removeEmptyLines?void 0:"",i="";return 0===b?i="min":b==c.length-1&&(i="max"),"all"===d||-1!==f.indexOf(g)||-1!==e.indexOf(b)||-1!==e.indexOf(i)?0===a?"0":isNaN(a)?a:round(a,0).toFixed(0):h}function GetCookie(a,b){if(null!=cookie.get("uidivstats_"+a))return cookie.get("uidivstats_"+a);return"string"==b?"":"number"==b?0:void 0}function SetCookie(a,b){cookie.set("uidivstats_"+a,b,3650)}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),show_menu(),get_conf_file(),get_domainstoexclude_file(),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildQueryLogTableHtmlNoData()),$j("#td_charts").append(BuildChartHtml("DNS Queries","TotalBlockedtime","true","false")),$j("#td_charts").append(BuildChartHtml("Top blocked domains","Blocked","false","true")),$j("#td_charts").append(BuildChartHtml("Top requested domains","Total","false","true")),get_sqldata_file(),get_querylog_file(),get_DivStats_file(),ScriptUpdateLayout()}function get_sqldata_file(){$j.ajax({url:"/ext/uiDivStats/SQLData.js",dataType:"script",timeout:3e3,error:function(){setTimeout(get_sqldata_file,1e3)},success:function(){SetuiDivStatsTitle(),$j("#uidivstats_div_keystats").append(BuildKeyStatsTableHtml("Key Stats","keystats")),$j("#keystats_Period").val(GetCookie("keystats_Period","number")).change(),get_clients_file()}})}function get_clients_file(){$j.ajax({url:"/ext/uiDivStats/csv/ipdistinctclients.js",dataType:"script",timeout:3e3,error:function(){setTimeout(get_clients_file,1e3)},success:function(){for(var a=0;a<metriclist.length;a++){Draw_Chart_NoData(metriclist[a]),$j("#"+metriclist[a]+"_Period").val(GetCookie(metriclist[a]+"_Period","number")),$j("#"+metriclist[a]+"_Type").val(GetCookie(metriclist[a]+"_Type","number")),$j("#"+metriclist[a]+"_Scale").val(GetCookie(metriclist[a]+"_Scale","number")),ChartScaleOptions($j("#"+metriclist[a]+"_Type")[0]);for(var b=0;b<chartlist.length;b++)d3.csv("/ext/uiDivStats/csv/"+metriclist[a]+chartlist[b]+".htm").then(SetGlobalDataset.bind(null,metriclist[a]+chartlist[b])),d3.csv("/ext/uiDivStats/csv/"+metriclist[a]+chartlist[b]+"clients.htm").then(SetGlobalDataset.bind(null,metriclist[a]+chartlist[b]+"clients"))}Draw_Chart_NoData("TotalBlockedtime");for(var a=0;a<chartlist.length;a++)$j("#TotalBlockedtime_Period").val(GetCookie("TotalBlockedtime_Period","number")),$j("#TotalBlockedtime_Scale").val(GetCookie("TotalBlockedtime_Scale","number")),d3.csv("/ext/uiDivStats/csv/TotalBlocked"+chartlist[a]+"time.htm").then(SetGlobalDataset.bind(null,"TotalBlocked"+chartlist[a]+"time"))}})}function get_conf_file(){$j.ajax({url:"/ext/uiDivStats/config.htm",dataType:"text",error:function(){setTimeout(get_conf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)eval("document.form.uidivstats_"+configdata[i].split("=")[0].toLowerCase()).value=configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"")}})}function get_domainstoexclude_file(){$j.ajax({url:"/ext/uiDivStats/domainstoexclude.htm",dataType:"text",error:function(){setTimeout(get_domainstoexclude_file,5e3)},success:function(a){document.getElementById("uidivstats_domainstoexclude").innerHTML=a}})}function get_DivStats_file(){$j.ajax({url:"/ext/uiDivStats/DiversionStats.htm",dataType:"text",error:function(){setTimeout(get_DivStats_file,5e3)},success:function(a){document.getElementById("DiversionStats").innerHTML=a}})}function SetGlobalDataset(a,b){window[a]=b,-1==a.indexOf("TotalBlocked")?-1==a.indexOf("Blocked")?-1!=a.indexOf("Total")&&(currentNoChartsTotal++,currentNoChartsOverall++,currentNoChartsTotal==maxNoChartsTotal&&(SetClients("Total"),Draw_Chart("Total"))):(currentNoChartsBlocked++,currentNoChartsOverall++,currentNoChartsBlocked==maxNoChartsBlocked&&(SetClients("Blocked"),Draw_Chart("Blocked"))):(currentNoChartsTotalBlocked++,currentNoChartsOverall++,currentNoChartsTotalBlocked==maxNoChartsTotalBlocked&&Draw_Time_Chart("TotalBlocked")),currentNoChartsOverall==maxNoChartsOverall&&(showhide("imgUpdateStats",!1),showhide("uidivstats_text",!1),showhide("btnUpdateStats",!0),Assign_EventHandlers())}function SetClients(a){var b=window[a+getChartPeriod($j("#"+a+"_Period option:selected").val())+"clients"],c=[],d=[];for(let e=0;e<b.length;e++)c[b[e].SrcIP]||(d.push(b[e].SrcIP),c[b[e].SrcIP]=1);d.sort();for(var e,f=0;f<d.length;f++)e=hostiparray.filter(function(a){return a[0]==d[f]})[0],$j("#"+a+"_Clients").append($j("<option>",{value:f+1,text:e[1]+" ("+e[0]+")"}))}function ScriptUpdateLayout(){var a=GetVersionNumber("local"),b=GetVersionNumber("server");$j("#uidivstats_version_local").text(a),a!=b&&"N/A"!=b&&($j("#uidivstats_version_server").text("Updated version available: "+b),showhide("btnChkUpdate",!1),showhide("uidivstats_version_server",!0),showhide("btnDoUpdate",!0))}function update_status(){$j.ajax({url:"/ext/uiDivStats/detect_update.js",dataType:"script",timeout:3e3,error:function(){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("uidivstats_version_server",!0),"None"==updatestatus?($j("#uidivstats_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)):($j("#uidivstats_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_uiDivStatscheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_uiDivStatsdoupdate",document.form.action_wait.value=10,showLoading(),document.form.submit()}function SaveConfig(){return!!Validate_All()&&void(document.getElementById("amng_custom").value=JSON.stringify($j("form").serializeObject()),document.form.action_script.value="start_uiDivStatsconfig",document.form.action_wait.value=10,showLoading(),document.form.submit())}$j.fn.serializeObject=function(){var b=custom_settings,c=this.serializeArray();$j.each(c,function(){void 0!==b[this.name]&&-1!=this.name.indexOf("uidivstats")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("domainstoexclude")?(!b[this.name].push&&(b[this.name]=[b[this.name]]),b[this.name].push(this.value||"")):-1!=this.name.indexOf("uidivstats")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("domainstoexclude")&&(b[this.name]=this.value||"")});var a=document.getElementById("uidivstats_domainstoexclude").value.replace(/\n/g,"||||");return b.uidivstats_domainstoexclude=a,b};function GetVersionNumber(a){var b;return"local"==a?b=custom_settings.uidivstats_version_local:"server"==a&&(b=custom_settings.uidivstats_version_server),"undefined"==typeof b||null==b?"N/A":b}function RedrawAllCharts(){$j("#td_charts").append(BuildChartHtml("DNS Queries","TotalBlockedtime","true","false")),$j("#td_charts").append(BuildChartHtml("Top blocked domains","Blocked","false","true")),$j("#td_charts").append(BuildChartHtml("Top requested domains","Total","false","true")),get_sqldata_file(),Assign_EventHandlers()}function PostStatUpdate(){currentNoChartsBlocked=0,currentNoChartsTotal=0,currentNoChartsTotalBlocked=0,currentNoChartsOverall=0,$j("#uidivstats_div_keystats").empty(),$j("#uidivstats_chart_TotalBlockedtime").remove(),$j("#uidivstats_chart_Blocked").remove(),$j("#uidivstats_chart_Total").remove(),setTimeout(RedrawAllCharts,3e3)}function updateStats(){showhide("btnUpdateStats",!1),document.formScriptActions.action_script.value="start_uiDivStats",document.formScriptActions.submit(),showhide("imgUpdateStats",!0),showhide("uidivstats_text",!1),setTimeout(StartUpdateStatsInterval,2e3)}var myinterval;function StartUpdateStatsInterval(){myinterval=setInterval(update_uidivstats,1e3)}var statcount=2;function update_uidivstats(){statcount++,$j.ajax({url:"/ext/uiDivStats/detect_uidivstats.js",dataType:"script",timeout:1e3,error:function(){},success:function(){"InProgress"==uidivstatsstatus?(showhide("imgUpdateStats",!0),showhide("uidivstats_text",!0),document.getElementById("uidivstats_text").innerHTML="Stat update in progress - "+statcount+"s elapsed"):"Done"==uidivstatsstatus?(document.getElementById("uidivstats_text").innerHTML="Refreshing charts...",statcount=2,clearInterval(myinterval),PostStatUpdate()):"LOCKED"==uidivstatsstatus&&(showhide("imgUpdateStats",!1),document.getElementById("uidivstats_text").innerHTML="Stat update already running!",showhide("uidivstats_text",!0),showhide("btnUpdateStats",!0),clearInterval(myinterval))}})}function reload(){location.reload(!0)}function ToggleFill(){"false"==ShowFill?(ShowFill="origin",SetCookie("ShowFill","origin")):(ShowFill="false",SetCookie("ShowFill","false"));for(var a=0;a<metriclist.length;a++)for(var b=0;b<chartlist.length;b++)window["Chart"+metriclist[a]+chartlist[b]+"time"].data.datasets[0].fill=ShowFill,window["Chart"+metriclist[a]+chartlist[b]+"time"].update()}function getLimit(a,b,c,d){var e,f=0;return e="x"==b?a.map(function(a){return a.x}):a.map(function(a){return a.y}),f="max"==c?Math.max.apply(Math,e):Math.min.apply(Math,e),"max"==c&&0==f&&!1==d&&(f=1),f}function getAverage(a){for(var b=0,c=0;c<a.length;c++)b+=1*a[c].y;var d=b/a.length;return d}function getMax(a){return Math.max(...a)}function round(a,b){return+(Math.round(a+"e"+b)+"e-"+b)}function getRandomColor(){var a=Math.floor(255*Math.random()),c=Math.floor(255*Math.random()),d=Math.floor(255*Math.random());return"rgba("+a+","+c+","+d+",1)"}function poolColors(b){for(var a=[],c=0;c<b;c++)a.push(getRandomColor());return a}function getChartType(a){var b="horizontalBar";return 0==a?b="horizontalBar":1==a?b="bar":2==a&&(b="pie"),b}function getChartPeriod(a){var b="daily";return 0==a?b="daily":1==a?b="weekly":2==a&&(b="monthly"),b}function getChartScale(a,b,c){var d="category";return 0==a?("horizontalBar"==b&&"x"==c||"bar"==b&&"y"==c||"time"==b&&"y"==c)&&(d="linear"):1==a&&("horizontalBar"==b&&"x"==c||"bar"==b&&"y"==c||"time"==b&&"y"==c)&&(d="logarithmic"),d}function ChartScaleOptions(a){var b=a.id.substring(0,a.id.indexOf("_"));let c=$j("#"+b+"_Scale");2==$j("#"+b+"_Type option:selected").val()?2==c[0].length&&(c.empty(),c.append($j("<option></option>").attr("value",0).text("Linear")),c.prop("selectedIndex",0)):1==c[0].length&&(c.empty(),c.append($j("<option></option>").attr("value",0).text("Linear")),c.append($j("<option></option>").attr("value",1).text("Logarithmic")),c.prop("selectedIndex",0))}function ZoomPanEnabled(a){return"bar"==a?"y":"horizontalBar"==a?"x":""}function ZoomPanMax(a,b,c){if("x"==b)return"bar"==a?null:"horizontalBar"==a?getMax(c):null;return"y"==b?"bar"==a?getMax(c):"horizontalBar"==a?null:null:void 0}function ResetZoom(){for(var a,b=0;b<metriclist.length;b++)(a=window["Chart"+metriclist[b]],"undefined"!=typeof a&&null!==a)&&a.resetZoom();var a=window.ChartTotalBlockedtime;"undefined"==typeof a||null===a||a.resetZoom()}function DragZoom(a){var b=!0,c=!1,d="";-1==a.value.indexOf("On")?(b=!0,c=!1,d="Drag Zoom On"):(b=!1,c=!0,d="Drag Zoom Off");for(var e=0;e<metriclist.length;e++)for(var f,g=0;g<chartlist.length;g++)(f=window["Chart"+metriclist[e]+chartlist[g]],"undefined"!=typeof f&&null!==f)&&(f.options.plugins.zoom.zoom.drag=b,f.options.plugins.zoom.pan.enabled=c,a.value=d,f.update())}function showGrid(a){return!(null!=a)||"pie"!=a}function showAxis(a,b){return!("bar"!=a||"x"!=b)||null==a||"pie"!=a}function showTicks(a,b){return("bar"!=a||"x"!=b)&&(null==a||"pie"!=a)}function showLegend(a){return!("pie"!=a)}function showTitle(a){return!("pie"!=a)}function getChartPadding(a){return"bar"==a?10:0}function getChartLegendTitle(){for(var a="Domain name",b=0;b<350-a.length;b++)a+=" ";return a}function getAxisLabel(a,b){var c="";return"x"==b?("horizontalBar"==a?c="Hits":"bar"==a?c="":"pie"==a&&(c=""),c):"y"==b?("horizontalBar"==a?c="":"bar"==a?c="Hits":"pie"==a&&(c=""),c):void 0}function changeChart(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),-1==a.id.indexOf("Clients")&&SetCookie(a.id,value),-1!=a.id.indexOf("Period")&&-1==a.id.indexOf("TotalBlocked")&&($j("#"+name+"_Clients option[value!=0]").remove(),SetClients(name)),-1==a.id.indexOf("time")?Draw_Chart(name):Draw_Time_Chart(name.replace("time",""))}function changeTable(a){value=1*a.value,name=a.id.substring(0,a.id.indexOf("_")),SetCookie(a.id,value);var b=getChartPeriod(value);$j("#keystatstotal").text(window["QueriesTotal"+b]),$j("#keystatsblocked").text(window["QueriesBlocked"+b]),$j("#keystatspercent").text(window["BlockedPercentage"+b])}function BuildChartHtml(a,b,c,d){var e="<div style=\"line-height:10px;\">&nbsp;</div>";return e+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable\" id=\"uidivstats_chart_"+b+"\">",e+="<thead class=\"collapsible-jquery\"",e+="<tr><td colspan=\"2\">"+a+" (click to expand/collapse)</td></tr>",e+="</thead>",e+="<tr class=\"even\">",e+="<th width=\"40%\">Period to display</th>",e+="<td>",e+="<select style=\"width:150px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Period\">",e+="<option value=0>Last 24 hours</option>",e+="<option value=1>Last 7 days</option>",e+="<option value=2>Last 30 days</option>",e+="</select>",e+="</td>",e+="</tr>","false"==c&&(e+="<tr class=\"even\">",e+="<th width=\"40%\">Layout for chart</th>",e+="<td>",e+="<select style=\"width:100px\" class=\"input_option\" onchange=\"ChartScaleOptions(this);changeChart(this)\" id=\""+b+"_Type\">",e+="<option value=0>Horizontal</option>",e+="<option value=1>Vertical</option>",e+="<option value=2>Pie</option>",e+="</select>",e+="</td>",e+="</tr>"),e+="<tr class=\"even\">",e+="<th width=\"40%\">Scale type</th>",e+="<td>",e+="<select style=\"width:150px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Scale\">",e+="<option value=0>Linear</option>",e+="<option value=1>Logarithmic</option>",e+="</select>",e+="</td>",e+="</tr>","true"==d&&(e+="<tr class=\"even\">",e+="<th width=\"40%\">Client to display</th>",e+="<td>",e+="<select style=\"width:250px\" class=\"input_option\" onchange=\"changeChart(this)\" id=\""+b+"_Clients\">",e+="<option value=0>All (*)</option>",e+="</select>",e+="</td>",e+="</tr>"),e+="<tr>",e+="<td colspan=\"2\" style=\"padding: 2px;\">",e+="<div style=\"background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;\" id=\"divChart"+b+"\"><canvas id=\"canvasChart"+b+"\" height=\"500\"></div>",e+="</td>",e+="</tr>",e+="</table>",e}function BuildKeyStatsTableHtml(a,b){var c="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable\" id=\"uidivstats_table_keystats\">";return c+="<col style=\"width:40%;\">",c+="<col style=\"width:60%;\">",c+="<thead class=\"collapsible-jquery\">",c+="<tr><td colspan=\"2\">"+a+" (click to expand/collapse)</td></tr>",c+="</thead>",c+="<tr class=\"even\">",c+="<th>Domains currently on blocklist</th>",c+="<td id=\"keystatsdomains\" style=\"font-size: 16px; font-weight: bolder;\">"+BlockedDomains+"</td>",c+="</tr>",c+="<tr class=\"even\">",c+="<th>Period to display</th>",c+="<td colspan=\"2\">",c+="<select style=\"width:150px\" class=\"input_option\" onchange=\"changeTable(this)\" id=\""+b+"_Period\">",c+="<option value=0>Last 24 hours</option>",c+="<option value=1>Last 7 days</option>",c+="<option value=2>Last 30 days</option>",c+="</select>",c+="</td>",c+="</tr>",c+="<tr style=\"line-height:5px;\">",c+="<td colspan=\"2\">&nbsp;</td>",c+="</tr>",c+="<tr>",c+="<td colspan=\"2\" align=\"center\" style=\"padding: 0px;\">",c+="<table border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable StatsTable\">",c+="<col style=\"width:250px;\">",c+="<col style=\"width:250px;\">",c+="<col style=\"width:250px;\">",c+="<thead>",c+="<tr>",c+="<th>Total Queries</th>",c+="<th>Queries Blocked</th>",c+="<th>Percent Blocked</th>",c+="</tr>",c+="</thead>",c+="<tr class=\"even\" style=\"text-align:center;\">",c+="<td id=\"keystatstotal\"></td>",c+="<td id=\"keystatsblocked\"></td>",c+="<td id=\"keystatspercent\"></td>",c+="</tr>",c+="</table>",c+="</td>",c+="</tr>",c+="<tr style=\"line-height:5px;\">",c+="<td colspan=\"2\">&nbsp;</td>",c+="</tr>",c+="</table>",c}function BuildQueryLogTableHtmlNoData(){var a="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"sortTable\">";return a+="<tr>",a+="<td colspan=\"3\" class=\"nodata\">",a+="Data loading...",a+="</td>",a+="</tr>",a+="</table>",a}function BuildQueryLogTableHtml(){var a="<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" class=\"sortTable\" style=\"table-layout:fixed;\" id=\"sortTable\">";a+="<col style=\"width:110px;\">",a+="<col style=\"width:320px;\">",a+="<col style=\"width:110px;\">",a+="<col style=\"width:50px;\">",a+="<col style=\"width:140px;\">",a+="<thead class=\"sortTableHeader\">",a+="<tr>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML)\">Time</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML)\">Domain</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML)\">Client</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML)\">Type</th>",a+="<th class=\"sortable\" onclick=\"SortTable(this.innerHTML)\">Result</th>",a+="</tr>",a+="</thead>",a+="<tbody class=\"sortTableContent\">";for(var b=0;b<arrayqueryloglines.length;b++)a+="<tr class=\"sortRow\">",a+="<td>"+arrayqueryloglines[b].Time+"</td>",a+="<td>"+arrayqueryloglines[b].ReqDmn+"</td>",a+="<td>"+arrayqueryloglines[b].SrcIP+"</td>",a+="<td>"+arrayqueryloglines[b].QryType+"</td>",a+="<td>"+arrayqueryloglines[b].Result+"</td>",a+="</tr>";return a+="</tbody>",a+="</table>",a}function get_querylog_file(){$j.ajax({url:"/ext/uiDivStats/csv/SQLQueryLog.htm",dataType:"text",error:function(){tout=setTimeout(get_querylog_file,1e3)},success:function(a){ParseQueryLog(a),document.getElementById("auto_refresh").checked&&(tout=setTimeout(get_querylog_file,6e4))}})}function ParseQueryLog(a){var b=a.split("\n");b=b.filter(Boolean),arrayqueryloglines=[];for(var c=0;c<b.length;c++){var d=b[c].split("|"),e={};e.Time=moment.unix(d[0]).format("YYYY-MM-DD HH:mm").trim(),e.ReqDmn=d[1].trim(),e.SrcIP=d[2].trim(),e.QryType=d[3].trim();var f=d[4].replace(/'/g,"").trim();e.Result=f.charAt(0).toUpperCase()+f.slice(1),arrayqueryloglines.push(e)}originalarrayqueryloglines=arrayqueryloglines,FilterQueryLog()}function FilterQueryLog(){""==$j("#filter_reqdmn").val()&&""==$j("#filter_srcip").val()&&0==$j("#filter_qrytype option:selected").val()&&0==$j("#filter_result option:selected").val()?arrayqueryloglines=originalarrayqueryloglines:(arrayqueryloglines=originalarrayqueryloglines,""!=$j("#filter_reqdmn").val()&&($j("#filter_reqdmn").val().startsWith("!")?arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1==a.ReqDmn.toLowerCase().indexOf($j("#filter_reqdmn").val().replace("!","").toLowerCase())}):arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.ReqDmn.toLowerCase().indexOf($j("#filter_reqdmn").val().toLowerCase())})),""!=$j("#filter_srcip").val()&&($j("#filter_srcip").val().startsWith("!")?arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1==a.SrcIP.indexOf($j("#filter_srcip").val().replace("!",""))}):arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.SrcIP.indexOf($j("#filter_srcip").val())})),0!=$j("#filter_qrytype option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return a.QryType==$j("#filter_qrytype option:selected").text()})),2==$j("#filter_result option:selected").val()?arrayqueryloglines=arrayqueryloglines.filter(function(a){return-1!=a.Result.toLowerCase().indexOf("blocked")}):0!=$j("#filter_result option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter(function(a){return a.Result==$j("#filter_result option:selected").text()}))),SortTable(sortname+" "+sortdir.replace("desc","\u2191").replace("asc","\u2193").trim())}function SortTable(sorttext){sortname=sorttext.replace("\u2191","").replace("\u2193","").trim();"Time"===sortname?sortfield="Time":"Domain"===sortname?sortfield="ReqDmn":"Client"===sortname?sortfield="SrcIP":"Type"===sortname?sortfield="QryType":"Result"===sortname?sortfield="Result":void 0;-1==sorttext.indexOf("\u2193")&&-1==sorttext.indexOf("\u2191")?(eval("arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a."+sortfield+" > b."+sortfield+") ? 1 : ((b."+sortfield+" > a."+sortfield+") ? -1 : 0)); "),sortdir="asc"):-1==sorttext.indexOf("\u2193")?(eval("arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a."+sortfield+" < b."+sortfield+") ? 1 : ((b."+sortfield+" < a."+sortfield+") ? -1 : 0)); "),sortdir="desc"):(eval("arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a."+sortfield+" > b."+sortfield+") ? 1 : ((b."+sortfield+" > a."+sortfield+") ? -1 : 0)); "),sortdir="asc"),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildQueryLogTableHtml()),$j(".sortable").each(function(a,b){b.innerHTML==sortname&&("asc"==sortdir?b.innerHTML=sortname+" \u2191":b.innerHTML=sortname+" \u2193")})}function Assign_EventHandlers(){$j(".collapsible-jquery").off("click").on("click",function(){$j(this).siblings().toggle("fast",function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")})}),$j(".collapsible-jquery").each(function(){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)});let a=null,b=null;$j("#filter_reqdmn").off("keyup touchend").on("keyup touchend",function(){clearTimeout(a),a=setTimeout(function(){FilterQueryLog()},1e3)}),$j("#filter_srcip").off("keyup touchend").on("keyup touchend",function(){clearTimeout(b),b=setTimeout(function(){FilterQueryLog()},1e3)}),$j("#auto_refresh").off("click").on("click",function(){ToggleRefresh()})}function ToggleRefresh(){$j("#auto_refresh").prop("checked",function(a,b){b?get_querylog_file():clearTimeout(tout)})}
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
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<thead class="collapsible-jquery" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="uidivstats_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="uidivstats_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_updatestats">
<thead class="collapsible-jquery" id="thead_updatestats">
<tr><td colspan="2">Diversion Statistics Control (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Last 24 hours / daily</th>
<td>
<input type="button" onclick="updateStats();" value="Update stats" class="button_gen" name="btnUpdateStats" id="btnUpdateStats">
<img id="imgUpdateStats" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
&nbsp;&nbsp;&nbsp;
<span id="uidivstats_text" style="display:none;"></span>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable SettingsTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery" id="scriptconfig">
<tr><td colspan="2">Configuration (click to expand/collapse)</td></tr>
</thead>
<tr class="even" id="rowquerymode">
<td class="settingname">Query Mode<br/><span class="settingname" style="color:#FFCC00;">(DNS query types for logging)</span></td>
<td class="settingvalue">
<input type="radio" name="uidivstats_querymode" id="uidivstats_query_all" class="input" value="all" checked>
<label for="uidivstats_query_all">All</label>
<input type="radio" name="uidivstats_querymode" id="uidivstats_query_aaaaa" class="input" value="A+AAAA">
<label for="uidivstats_query_aaaaa">A+AAAA only</label>
</td>
</tr>
<tr class="even" id="rowcachemode">
<td class="settingname">Cache Mode<br/><span class="settingname" style="color:#FFCC00;">(use tmpfs instead of direct write to disk)</span></td>
<td class="settingvalue">
<input type="radio" name="uidivstats_cachemode" id="uidivstats_cache_tmp" class="input" value="tmp" checked>
<label for="uidivstats_cache_tmp">Enabled</label>
<input type="radio" name="uidivstats_cachemode" id="uidivstats_cache_none" class="input" value="none">
<label for="uidivstats_cache_none">Disabled</label>
</td>
</tr>
<tr class="even" id="rowdaystokeep">
<td class="settingname">Number of days of data to keep</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="3" class="input_6_table removespacing" name="uidivstats_daystokeep" value="30" onkeypress="return validator.isNumber(this,event)" onblur="Validate_Number_Setting(this,365,30);Format_Number_Setting(this)" onkeyup="Validate_Number_Setting(this,365,30)"/>
&nbsp;days <span style="color:#FFCC00;">(between 30 and 365, default: 30)</span>
</td>
</tr>
<tr class="even" id="rowdomainstoexclude">
<td class="settingname">List of domains to exclude from<br />"Top requested domains" and<br />"Top blocked domains" charts<br/><span class="settingname" style="color:#FFCC00;">(use * as a wildcard)</span></td>
<td class="settingvalue" style="padding:2px;">
<textarea cols="75" rows="10" wrap="off" id="uidivstats_domainstoexclude" name="uidivstats_domainstoexclude" class="textarea_log_table settings" data-lpignore="true"></textarea>
</td>
</tr>
<tr class="apply_gen" valign="top" height="35px">
<td colspan="2" class="savebutton">
<input type="button" onclick="SaveConfig();" value="Save" class="button_gen savebutton" name="button">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<div id="uidivstats_div_keystats"></div>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="table_charts">
<thead class="collapsible-jquery" id="thead_charts">
<tr>
<td>Charts (click to expand/collapse)</td>
</tr>
</thead>
<tr><td align="center" style="padding: 0px;" id="td_charts">
</td></tr></table>
<!-- Keystats table -->

<!-- Blocked Ads -->

<!-- Requested Ads -->

<!-- Start Query Log -->
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_querylog">
<col style="width:40%;">
<col style="width:60%;">
<thead class="collapsible-jquery">
<tr><td colspan="2">Query Log (click to expand/collapse)</td></tr>
</thead>
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
<td><input autocomplete="off" autocapitalize="off" type="text" maxlength="15" class="input_20_table" id="filter_srcip" name="filter_srcip" value="" onkeypress="return isFilterIP(this,event);" data-lpignore="true" style="margin:0px;padding-left:0px;width:100px;text-align:center;"/></td>
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
<option value="8">type=65</option>
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
<div id="sortTableContainer" class="sortTableContainer"></div>
</td>
</tr>
</table>
<!-- End Query Log -->
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="uidivstats_diversiontextstats">
<thead class="collapsible-jquery" id="thead_diversiontextstats">
<tr>
<td colspan="2">Diversion Statistics Report (click to expand/collapse)</td>
</tr>
</thead>
<tr>
<td style="padding: 0px;">
<textarea cols="75" rows="35" wrap="off" readonly="readonly" id="DiversionStats" class="textarea_log_table" style="font-family:'Courier New',Courier,mono;font-size:11px;border:none;padding:0px;">If you are seeing this message,it means you don't have a weekly stats file from Diversion present on your router.
Please check that weekly stats are enabled in Diversion,menu options c 2</textarea>
</td>
</tr>
</table>
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
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer">
</div>
</body>
</html>
