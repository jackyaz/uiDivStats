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
var $j=jQuery.noConflict(),maxNoChartsBlocked=6,currentNoChartsBlocked=0,maxNoChartsTotal=6,currentNoChartsTotal=0,maxNoChartsTotalBlocked=3,currentNoChartsTotalBlocked=0,maxNoChartsOverall=15,currentNoChartsOverall=0,arrayqueryloglines=[],originalarrayqueryloglines=[],sortname="Time",sortdir="desc",tout;function keyHandler(t){82==t.keyCode?($j(document).off("keydown"),ResetZoom()):70==t.keyCode&&($j(document).off("keydown"),ToggleFill())}function isFilterIP(t,e){var a,i=e.keyCode?e.keyCode:e.which;if(validator.isFunctionButton(e))return!0;if(33==i)return!0;if(i>47&&i<58){a=0;for(var o=0;o<t.value.length;o++)"."==t.value.charAt(o)&&a++;return a<3&&o>=3&&"."!=t.value.charAt(o-3)&&"."!=t.value.charAt(o-2)&&"."!=t.value.charAt(o-1)&&(t.value=t.value+"."),!0}if(46==i){a=0;for(o=0;o<t.value.length;o++)"."==t.value.charAt(o)&&a++;return"."!=t.value.charAt(o-1)&&3!=a}return 13==i||!(!e.metaKey||65!=i&&67!=i&&86!=i&&88!=i&&97!=i&&99!=i&&118!=i&&120!=i)}function Validate_Number_Setting(t,e,a){t.name;var i=1*t.value;return i>e||i<a?($j(t).addClass("invalid"),!1):($j(t).removeClass("invalid"),!0)}function Format_Number_Setting(t){t.name;var e=1*t.value;return 0!=t.value.length&&NaN!=e&&(t.value=parseInt(t.value),!0)}function Validate_All(){var t=!1;return Validate_Number_Setting(document.form.uidivstats_lastxqueries,1e4,10)||(t=!0),Validate_Number_Setting(document.form.uidivstats_daystokeep,365,1)||(t=!0),!t||(alert("Validation for some fields failed. Please correct invalid values and try again."),!1)}Chart.defaults.global.defaultFontColor="#CCC",Chart.Tooltip.positioners.cursor=function(t,e){return e},$j(document).keydown((function(t){keyHandler(t)})),$j(document).keyup((function(t){$j(document).keydown((function(t){keyHandler(t)}))}));var metriclist=["Blocked","Total"],chartlist=["daily","weekly","monthly"],timeunitlist=["hour","day","day"],intervallist=[24,7,30],bordercolourlist=["#fc8500","#42ecf5"],backgroundcolourlist=["rgba(252,133,0,0.5)","rgba(66,236,245,0.5)"],myinterval;function Draw_Chart_NoData(t,e){document.getElementById("canvasChart"+t).width="735",document.getElementById("canvasChart"+t).height="500",document.getElementById("canvasChart"+t).style.width="735px",document.getElementById("canvasChart"+t).style.height="500px";var a=document.getElementById("canvasChart"+t).getContext("2d");a.save(),a.textAlign="center",a.textBaseline="middle",a.font="normal normal bolder 48px Arial",a.fillStyle="white",a.fillText(e,368,250),a.restore()}function Draw_Chart(t){var e,a=getChartPeriod($j("#"+t+"_Period option:selected").val()),i=getChartType($j("#"+t+"_Type option:selected").val()),o=$j("#"+t+"_Clients option:selected").text(),r=o.substring(o.indexOf("(")+1,o.indexOf(")",o.indexOf("(")+1));if(null!=(e="All (*)"==o?window[t+a]:window[t+a+"clients"]))if(0!=e.length){var n,l;"All (*)"==o?(n=e.map((function(t){return t.Count})),l=e.map((function(t){return t.ReqDmn}))):(n=e.filter((function(t){return t.SrcIP==r})).map((function(t){return t.Count})),l=e.filter((function(t){return t.SrcIP==r})).map((function(t){return t.ReqDmn}))),$j.each(l,(function(t,e){l[t]=chunk(e.toLowerCase(),30).join("\n")}));var s=window["Chart"+t];null!=s&&s.destroy();var d=document.getElementById("canvasChart"+t).getContext("2d"),c={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,legend:{onClick:null,display:showLegend(i),position:"left",labels:{fontColor:"#ffffff"}},layout:{padding:{top:getChartPadding(i)}},title:{display:showTitle(i),text:getChartLegendTitle(),position:"top"},tooltips:{callbacks:{title:function(t,e){return e.labels[t[0].index]},label:function(t,e){return comma(e.datasets[t.datasetIndex].data[t.index])}},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{display:showAxis(i,"x"),type:getChartScale($j("#"+t+"_Scale option:selected").val(),i,"x"),gridLines:{display:showGrid(i,"x"),color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(i,"x")},ticks:{display:showTicks(i,"x"),beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}],yAxes:[{display:showAxis(i,"y"),type:getChartScale($j("#"+t+"_Scale option:selected").val(),i,"y"),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!0,labelString:getAxisLabel(i,"y")},ticks:{display:showTicks(i,"y"),beginAtZero:!0,autoSkip:!1,lineHeight:.8,padding:-5,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:!1,mode:ZoomPanEnabled(i),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(i,"x",n),y:ZoomPanMax(i,"y",n)}},zoom:{enabled:!0,drag:!0,mode:ZoomPanEnabled(i),rangeMin:{x:0,y:0},rangeMax:{x:ZoomPanMax(i,"x",n),y:ZoomPanMax(i,"y",n)},speed:.1}}}},u={labels:l,datasets:[{data:n,borderWidth:1,backgroundColor:poolColors(l.length),borderColor:"#000000"}]};s=new Chart(d,{type:i,options:c,data:u,plugins:[{beforeInit:function(t){t.data.labels.forEach((function(t,e,a){/\n/.test(t)&&(a[e]=t.split(/\n/))}))}}]}),window["Chart"+t]=s}else Draw_Chart_NoData(t,"No data to display");else Draw_Chart_NoData(t,"No data to display")}function Draw_Time_Chart(t){var e=getChartPeriod($j("#"+t+"time_Period option:selected").val()),a="DNS Queries",i=timeunitlist[$j("#"+t+"time_Period option:selected").val()],o=intervallist[$j("#"+t+"time_Period option:selected").val()],r=window[t+e+"time"];if(null!=r)if(0!=r.length){var n=[],l=[];for(let t=0;t<r.length;t++)n[r[t].Fieldname]||(l.push(r[t].Fieldname),n[r[t].Fieldname]=1);var s=r.map((function(t){return{x:t.Time,y:t.QueryCount}})),d=window["Chart"+t+"time"];factor=0,"hour"==i?factor=36e5:"day"==i&&(factor=864e5),null!=d&&d.destroy();var c=document.getElementById("canvasChart"+t+"time").getContext("2d"),u={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top"},title:{display:!0,text:a},tooltips:{callbacks:{title:function(t,e){return moment(t[0].xLabel,"X").format("YYYY-MM-DD HH:mm:ss")},label:function(t,e){return e.datasets[t.datasetIndex].label+": "+e.datasets[t.datasetIndex].data[t.index].y}},mode:"x",position:"cursor",intersect:!1},scales:{xAxes:[{type:"time",gridLines:{display:!0,color:"#282828"},ticks:{min:moment().subtract(o,i+"s"),display:!0},time:{parser:"X",unit:i,stepSize:1}}],yAxes:[{type:getChartScale($j("#"+t+"time_Scale option:selected").val(),"time","y"),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:a},ticks:{display:!0,beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:!1,mode:"xy",rangeMin:{x:(new Date).getTime()-factor*o,y:getLimit(s,"y","min",!1)},rangeMax:{x:(new Date).getTime(),y:getLimit(s,"y","max",!1)}},zoom:{enabled:!0,drag:!0,mode:"xy",rangeMin:{x:(new Date).getTime()-factor*o,y:getLimit(s,"y","min",!1)},rangeMax:{x:(new Date).getTime(),y:getLimit(s,"y","max",!1)},speed:.1}}}},m={datasets:getDataSets(t,r,l)};d=new Chart(c,{type:"line",data:m,options:u}),window["Chart"+t+"time"]=d}else Draw_Chart_NoData(t+"time","No data to display");else Draw_Chart_NoData(t+"time","No data to display")}function getDataSets(t,e,a){var i=[];colourname="#fc8500";for(var o=0;o<a.length;o++){var r=e.filter((function(t){return t.Fieldname==a[o]})).map((function(t){return{x:t.Time,y:t.QueryCount}}));i.push({label:a[o],data:r,borderWidth:1,pointRadius:1,lineTension:0,fill:!0,backgroundColor:backgroundcolourlist[o],borderColor:bordercolourlist[o]})}return i.reverse(),i}function chunk(t,e){for(var a=[],i=0,o=t.length;i<o;i+=e)a.push(t.substr(i,e));return a}function LogarithmicFormatter(t,e,a){if("logarithmic"!=this.type)return isNaN(t)?t:round(t,0).toFixed(0);var i=this.options.ticks.labels||{},o=i.index||["min","max"],r=i.significand||[1,2,5],n=t/Math.pow(10,Math.floor(Chart.helpers.log10(t))),l=!0===i.removeEmptyLines?void 0:"",s="";return 0===e?s="min":e===a.length-1&&(s="max"),"all"===i||-1!==r.indexOf(n)||-1!==o.indexOf(e)||-1!==o.indexOf(s)?0===t?"0":isNaN(t)?t:round(t,0).toFixed(0):l}function GetCookie(t,e){return null!=cookie.get("uidivstats_"+t)?cookie.get("uidivstats_"+t):"string"==e?"":"number"==e?0:void 0}function SetCookie(t,e){cookie.set("uidivstats_"+t,e,3650)}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),show_menu(),get_conf_file(),get_domainstoexclude_file(),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildQueryLogTableHtmlNoData()),$j("#td_charts").append(BuildChartHtml("DNS Queries","TotalBlockedtime","true","false")),$j("#td_charts").append(BuildChartHtml("Top blocked domains","Blocked","false","true")),$j("#td_charts").append(BuildChartHtml("Top requested domains","Total","false","true")),get_sqldata_file(),get_querylog_file(),get_DivStats_file(),ScriptUpdateLayout()}function get_sqldata_file(){$j.ajax({url:"/ext/uiDivStats/SQLData.js",dataType:"script",timeout:3e3,error:function(t){setTimeout(get_sqldata_file,1e3)},success:function(){SetuiDivStatsTitle(),$j("#uidivstats_div_keystats").append(BuildKeyStatsTableHtml("Key Stats","keystats")),$j("#keystats_Period").val(GetCookie("keystats_Period","number")).change(),get_clients_file()}})}function get_clients_file(){$j.ajax({url:"/ext/uiDivStats/csv/ipdistinctclients.js",dataType:"script",timeout:3e3,error:function(t){setTimeout(get_clients_file,1e3)},success:function(){for(var t=0;t<metriclist.length;t++){Draw_Chart_NoData(metriclist[t],"Data loading..."),$j("#"+metriclist[t]+"_Period").val(GetCookie(metriclist[t]+"_Period","number")),$j("#"+metriclist[t]+"_Type").val(GetCookie(metriclist[t]+"_Type","number")),$j("#"+metriclist[t]+"_Scale").val(GetCookie(metriclist[t]+"_Scale","number")),ChartScaleOptions($j("#"+metriclist[t]+"_Type")[0]);for(var e=0;e<chartlist.length;e++)d3.csv("/ext/uiDivStats/csv/"+metriclist[t]+chartlist[e]+".htm").then(SetGlobalDataset.bind(null,metriclist[t]+chartlist[e])),d3.csv("/ext/uiDivStats/csv/"+metriclist[t]+chartlist[e]+"clients.htm").then(SetGlobalDataset.bind(null,metriclist[t]+chartlist[e]+"clients"))}Draw_Chart_NoData("TotalBlockedtime","Data loading...");for(t=0;t<chartlist.length;t++)$j("#TotalBlockedtime_Period").val(GetCookie("TotalBlockedtime_Period","number")),$j("#TotalBlockedtime_Scale").val(GetCookie("TotalBlockedtime_Scale","number")),d3.csv("/ext/uiDivStats/csv/TotalBlocked"+chartlist[t]+"time.htm").then(SetGlobalDataset.bind(null,"TotalBlocked"+chartlist[t]+"time"))}})}function get_conf_file(){$j.ajax({url:"/ext/uiDivStats/config.htm",dataType:"text",error:function(t){setTimeout(get_conf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)eval("document.form.uidivstats_"+configdata[i].split("=")[0].toLowerCase()).value=configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"")}})}function get_domainstoexclude_file(){$j.ajax({url:"/ext/uiDivStats/domainstoexclude.htm",dataType:"text",error:function(t){setTimeout(get_domainstoexclude_file,5e3)},success:function(t){document.getElementById("uidivstats_domainstoexclude").innerHTML=t}})}function get_DivStats_file(){$j.ajax({url:"/ext/uiDivStats/DiversionStats.htm",dataType:"text",error:function(t){setTimeout(get_DivStats_file,5e3)},success:function(t){document.getElementById("DiversionStats").innerHTML=t}})}function SetGlobalDataset(t,e){window[t]=e,-1!=t.indexOf("TotalBlocked")?(currentNoChartsTotalBlocked++,currentNoChartsOverall++,currentNoChartsTotalBlocked==maxNoChartsTotalBlocked&&Draw_Time_Chart("TotalBlocked")):-1!=t.indexOf("Blocked")?(currentNoChartsBlocked++,currentNoChartsOverall++,currentNoChartsBlocked==maxNoChartsBlocked&&(SetClients("Blocked"),Draw_Chart("Blocked"))):-1!=t.indexOf("Total")&&(currentNoChartsTotal++,currentNoChartsOverall++,currentNoChartsTotal==maxNoChartsTotal&&(SetClients("Total"),Draw_Chart("Total"))),currentNoChartsOverall==maxNoChartsOverall&&(showhide("imgUpdateStats",!1),showhide("uidivstats_text",!1),showhide("btnUpdateStats",!0),Assign_EventHandlers())}function SetClients(t){var e=window[t+getChartPeriod($j("#"+t+"_Period option:selected").val())+"clients"],a=[],i=[];for(let t=0;t<e.length;t++)a[e[t].SrcIP]||(i.push(e[t].SrcIP),a[e[t].SrcIP]=1);i.sort();for(var o=0;o<i.length;o++){var r=hostiparray.filter((function(t){return t[0]==i[o]}))[0];$j("#"+t+"_Clients").append($j("<option>",{value:o+1,text:r[1]+" ("+r[0]+")"}))}}function ScriptUpdateLayout(){var t=GetVersionNumber("local"),e=GetVersionNumber("server");$j("#uidivstats_version_local").text(t),t!=e&&"N/A"!=e&&($j("#uidivstats_version_server").text("Updated version available: "+e),showhide("btnChkUpdate",!1),showhide("uidivstats_version_server",!0),showhide("btnDoUpdate",!0))}function update_status(){$j.ajax({url:"/ext/uiDivStats/detect_update.js",dataType:"script",timeout:3e3,error:function(t){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("uidivstats_version_server",!0),"None"!=updatestatus?($j("#uidivstats_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)):($j("#uidivstats_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_uiDivStatscheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_uiDivStatsdoupdate",document.form.action_wait.value=10,showLoading(),document.form.submit()}function SaveConfig(){if(!Validate_All())return!1;document.getElementById("amng_custom").value=JSON.stringify($j("form").serializeObject()),document.form.action_script.value="start_uiDivStatsconfig",document.form.action_wait.value=10,showLoading(),document.form.submit()}function RefreshNow(){clearTimeout(tout),showhide("spanRefreshNow",!1),document.formScriptActions.action_script.value="start_uiDivStatsquerylog",document.formScriptActions.submit(),document.getElementById("imgRefreshNow").style.display="",setTimeout(get_querylog_file,5e3)}function GetVersionNumber(t){var e;return"local"==t?e=custom_settings.uidivstats_version_local:"server"==t&&(e=custom_settings.uidivstats_version_server),void 0===e||null==e?"N/A":e}function RedrawAllCharts(){$j("#td_charts").append(BuildChartHtml("DNS Queries","TotalBlockedtime","true","false")),$j("#td_charts").append(BuildChartHtml("Top blocked domains","Blocked","false","true")),$j("#td_charts").append(BuildChartHtml("Top requested domains","Total","false","true")),get_sqldata_file(),Assign_EventHandlers()}function PostStatUpdate(){currentNoChartsBlocked=0,currentNoChartsTotal=0,currentNoChartsTotalBlocked=0,currentNoChartsOverall=0,$j("#uidivstats_div_keystats").empty(),$j("#uidivstats_chart_TotalBlockedtime").remove(),$j("#uidivstats_chart_Blocked").remove(),$j("#uidivstats_chart_Total").remove(),setTimeout(RedrawAllCharts,3e3)}function updateStats(){showhide("btnUpdateStats",!1),document.formScriptActions.action_script.value="start_uiDivStats",document.formScriptActions.submit(),showhide("imgUpdateStats",!0),showhide("uidivstats_text",!1),setTimeout(StartUpdateStatsInterval,2e3)}function StartUpdateStatsInterval(){myinterval=setInterval(update_uidivstats,1e3)}$j.fn.serializeObject=function(){var t=custom_settings,e=this.serializeArray();$j.each(e,(function(){void 0!==t[this.name]&&-1!=this.name.indexOf("uidivstats")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("domainstoexclude")?(t[this.name].push||(t[this.name]=[t[this.name]]),t[this.name].push(this.value||"")):-1!=this.name.indexOf("uidivstats")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("domainstoexclude")&&(t[this.name]=this.value||"")}));var a=document.getElementById("uidivstats_domainstoexclude").value.replace(/\n/g,"||||");return t.uidivstats_domainstoexclude=a,t};var statcount=2;function update_uidivstats(){statcount++,$j.ajax({url:"/ext/uiDivStats/detect_uidivstats.js",dataType:"script",timeout:1e3,error:function(t){},success:function(){"InProgress"==uidivstatsstatus?(showhide("imgUpdateStats",!0),showhide("uidivstats_text",!0),document.getElementById("uidivstats_text").innerHTML="Stat update in progress - "+statcount+"s elapsed"):"Done"==uidivstatsstatus?(document.getElementById("uidivstats_text").innerHTML="Refreshing charts...",statcount=2,clearInterval(myinterval),PostStatUpdate()):"LOCKED"==uidivstatsstatus&&(showhide("imgUpdateStats",!1),document.getElementById("uidivstats_text").innerHTML="Stat update already running!",showhide("uidivstats_text",!0),showhide("btnUpdateStats",!0),clearInterval(myinterval))}})}function reload(){location.reload(!0)}function ToggleFill(){"false"==ShowFill?(ShowFill="origin",SetCookie("ShowFill","origin")):(ShowFill="false",SetCookie("ShowFill","false"));for(var t=0;t<metriclist.length;t++)for(var e=0;e<chartlist.length;e++)window["Chart"+metriclist[t]+chartlist[e]+"time"].data.datasets[0].fill=ShowFill,window["Chart"+metriclist[t]+chartlist[e]+"time"].update()}function getLimit(t,e,a,i){var o,r=0;return o="x"==e?t.map((function(t){return t.x})):t.map((function(t){return t.y})),r="max"==a?Math.max.apply(Math,o):Math.min.apply(Math,o),"max"==a&&0==r&&0==i&&(r=1),r}function getAverage(t){for(var e=0,a=0;a<t.length;a++)e+=1*t[a].y;return e/t.length}function getMax(t){return Math.max(...t)}function round(t,e){return Number(Math.round(t+"e"+e)+"e-"+e)}function getRandomColor(){return"rgba("+Math.floor(255*Math.random())+","+Math.floor(255*Math.random())+","+Math.floor(255*Math.random())+",1)"}function poolColors(t){for(var e=[],a=0;a<t;a++)e.push(getRandomColor());return e}function getChartType(t){var e="horizontalBar";return 0==t?e="horizontalBar":1==t?e="bar":2==t&&(e="pie"),e}function getChartPeriod(t){var e="daily";return 0==t?e="daily":1==t?e="weekly":2==t&&(e="monthly"),e}function getChartScale(t,e,a){var i="category";return 0==t?("horizontalBar"==e&&"x"==a||"bar"==e&&"y"==a||"time"==e&&"y"==a)&&(i="linear"):1==t&&("horizontalBar"==e&&"x"==a||"bar"==e&&"y"==a||"time"==e&&"y"==a)&&(i="logarithmic"),i}function ChartScaleOptions(t){var e=t.id.substring(0,t.id.indexOf("_"));let a=$j("#"+e+"_Scale");2!=$j("#"+e+"_Type option:selected").val()?1==a[0].length&&(a.empty(),a.append($j("<option></option>").attr("value",0).text("Linear")),a.append($j("<option></option>").attr("value",1).text("Logarithmic")),a.prop("selectedIndex",0)):2==a[0].length&&(a.empty(),a.append($j("<option></option>").attr("value",0).text("Linear")),a.prop("selectedIndex",0))}function ZoomPanEnabled(t){return"bar"==t?"y":"horizontalBar"==t?"x":""}function ZoomPanMax(t,e,a){return"x"==e?"bar"==t?null:"horizontalBar"==t?getMax(a):null:"y"==e?"bar"==t?getMax(a):null:void 0}function ResetZoom(){for(var t=0;t<metriclist.length;t++){null!=(e=window["Chart"+metriclist[t]])&&e.resetZoom()}var e;null!=(e=window.ChartTotalBlockedtime)&&e.resetZoom()}function DragZoom(t){var e=!0,a=!1,i="";-1!=t.value.indexOf("On")?(e=!1,a=!0,i="Drag Zoom Off"):(e=!0,a=!1,i="Drag Zoom On");for(var o=0;o<metriclist.length;o++)for(var r=0;r<chartlist.length;r++){var n=window["Chart"+metriclist[o]+chartlist[r]];null!=n&&(n.options.plugins.zoom.zoom.drag=e,n.options.plugins.zoom.pan.enabled=a,t.value=i,n.update())}}function showGrid(t,e){return null==t||"pie"!=t}function showAxis(t,e){return"bar"==t&&"x"==e||(null==t||"pie"!=t)}function showTicks(t,e){return("bar"!=t||"x"!=e)&&(null==t||"pie"!=t)}function showLegend(t){return"pie"==t}function showTitle(t){return"pie"==t}function getChartPadding(t){return"bar"==t?10:0}function getChartLegendTitle(){for(var t="Domain name",e=0;e<350-t.length;e++)t+=" ";return t}function getAxisLabel(t,e){var a="";return"x"==e?("horizontalBar"==t?a="Hits":("bar"==t||"pie"==t)&&(a=""),a):"y"==e?("horizontalBar"==t?a="":"bar"==t?a="Hits":"pie"==t&&(a=""),a):void 0}function changeChart(t){value=1*t.value,name=t.id.substring(0,t.id.indexOf("_")),-1==t.id.indexOf("Clients")&&SetCookie(t.id,value),-1!=t.id.indexOf("Period")&&-1==t.id.indexOf("TotalBlocked")&&($j("#"+name+"_Clients option[value!=0]").remove(),SetClients(name)),-1==t.id.indexOf("time")?Draw_Chart(name):Draw_Time_Chart(name.replace("time",""))}function changeTable(t){value=1*t.value,name=t.id.substring(0,t.id.indexOf("_")),SetCookie(t.id,value);var e=getChartPeriod(value);$j("#keystatstotal").text(window["QueriesTotal"+e]),$j("#keystatsblocked").text(window["QueriesBlocked"+e]),$j("#keystatspercent").text(window["BlockedPercentage"+e])}function BuildChartHtml(t,e,a,i){var o='<div style="line-height:10px;">&nbsp;</div>';return o+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_chart_'+e+'">',o+='<thead class="collapsible-jquery"',o+='<tr><td colspan="2">'+t+" (click to expand/collapse)</td></tr>",o+="</thead>",o+='<tr class="even">',o+='<th width="40%">Period to display</th>',o+="<td>",o+='<select style="width:150px" class="input_option" onchange="changeChart(this)" id="'+e+'_Period">',o+="<option value=0>Last 24 hours</option>",o+="<option value=1>Last 7 days</option>",o+="<option value=2>Last 30 days</option>",o+="</select>",o+="</td>",o+="</tr>","false"==a&&(o+='<tr class="even">',o+='<th width="40%">Layout for chart</th>',o+="<td>",o+='<select style="width:100px" class="input_option" onchange="ChartScaleOptions(this);changeChart(this)" id="'+e+'_Type">',o+="<option value=0>Horizontal</option>",o+="<option value=1>Vertical</option>",o+="<option value=2>Pie</option>",o+="</select>",o+="</td>",o+="</tr>"),o+='<tr class="even">',o+='<th width="40%">Scale type</th>',o+="<td>",o+='<select style="width:150px" class="input_option" onchange="changeChart(this)" id="'+e+'_Scale">',o+="<option value=0>Linear</option>",o+="<option value=1>Logarithmic</option>",o+="</select>",o+="</td>",o+="</tr>","true"==i&&(o+='<tr class="even">',o+='<th width="40%">Client to display</th>',o+="<td>",o+='<select style="width:250px" class="input_option" onchange="changeChart(this)" id="'+e+'_Clients">',o+="<option value=0>All (*)</option>",o+="</select>",o+="</td>",o+="</tr>"),o+="<tr>",o+='<td colspan="2" style="padding: 2px;">',o+='<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;" id="divChart'+e+'"><canvas id="canvasChart'+e+'" height="500"></div>',o+="</td>",o+="</tr>",o+="</table>"}function BuildKeyStatsTableHtml(t,e){var a='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_keystats">';return a+='<col style="width:40%;">',a+='<col style="width:60%;">',a+='<thead class="collapsible-jquery">',a+='<tr><td colspan="2">'+t+" (click to expand/collapse)</td></tr>",a+="</thead>",a+='<tr class="even">',a+="<th>Domains currently on blocklist</th>",a+='<td id="keystatsdomains" style="font-size: 16px; font-weight: bolder;">'+BlockedDomains+"</td>",a+="</tr>",a+='<tr class="even">',a+="<th>Period to display</th>",a+='<td colspan="2">',a+='<select style="width:150px" class="input_option" onchange="changeTable(this)" id="'+e+'_Period">',a+="<option value=0>Last 24 hours</option>",a+="<option value=1>Last 7 days</option>",a+="<option value=2>Last 30 days</option>",a+="</select>",a+="</td>",a+="</tr>",a+='<tr style="line-height:5px;">',a+='<td colspan="2">&nbsp;</td>',a+="</tr>",a+="<tr>",a+='<td colspan="2" align="center" style="padding: 0px;">',a+='<table border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable StatsTable">',a+='<col style="width:250px;">',a+='<col style="width:250px;">',a+='<col style="width:250px;">',a+="<thead>",a+="<tr>",a+="<th>Total Queries</th>",a+="<th>Queries Blocked</th>",a+="<th>Percent Blocked</th>",a+="</tr>",a+="</thead>",a+='<tr class="even" style="text-align:center;">',a+='<td id="keystatstotal"></td>',a+='<td id="keystatsblocked"></td>',a+='<td id="keystatspercent"></td>',a+="</tr>",a+="</table>",a+="</td>",a+="</tr>",a+='<tr style="line-height:5px;">',a+='<td colspan="2">&nbsp;</td>',a+="</tr>",a+="</table>"}function BuildQueryLogTableHtmlNoData(){return"<tr>",'<td colspan="3" class="nodata">',"Data loading...","</td>","</tr>","</table>",'<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="sortTable"><tr><td colspan="3" class="nodata">Data loading...</td></tr></table>'}function BuildQueryLogTableHtml(){var t='<table border="0" cellpadding="0" cellspacing="0" width="100%" class="sortTable" style="table-layout:fixed;" id="sortTable">';t+='<col style="width:110px;">',t+='<col style="width:320px;">',t+='<col style="width:110px;">',t+='<col style="width:50px;">',t+='<col style="width:140px;">',t+='<thead class="sortTableHeader">',t+="<tr>",t+='<th class="sortable" onclick="SortTable(this.innerHTML)">Time</th>',t+='<th class="sortable" onclick="SortTable(this.innerHTML)">Domain</th>',t+='<th class="sortable" onclick="SortTable(this.innerHTML)">Client</th>',t+='<th class="sortable" onclick="SortTable(this.innerHTML)">Type</th>',t+='<th class="sortable" onclick="SortTable(this.innerHTML)">Result</th>',t+="</tr>",t+="</thead>",t+='<tbody class="sortTableContent">';for(var e=0;e<arrayqueryloglines.length;e++)t+='<tr class="sortRow">',t+="<td>"+arrayqueryloglines[e].Time+"</td>",t+="<td>"+arrayqueryloglines[e].ReqDmn+"</td>",t+="<td>"+arrayqueryloglines[e].SrcIP+"</td>",t+="<td>"+arrayqueryloglines[e].QryType+"</td>",t+="<td>"+arrayqueryloglines[e].Result+"</td>",t+="</tr>";return t+="</tbody>",t+="</table>"}function get_querylog_file(){$j.ajax({url:"/ext/uiDivStats/csv/SQLQueryLog.htm",dataType:"text",error:function(t){tout=setTimeout(get_querylog_file,1e3)},success:function(t){ParseQueryLog(t),document.getElementById("imgRefreshNow").style.display="none",showhide("spanRefreshNow",!0),document.getElementById("auto_refresh").checked&&(tout=setTimeout(get_querylog_file,6e4))}})}function ParseQueryLog(t){var e=t.split("\n");e=e.filter(Boolean),arrayqueryloglines=[];for(var a=0;a<e.length;a++){var i=e[a].split("|"),o=new Object;o.Time=moment.unix(i[0]).format("YYYY-MM-DD HH:mm").trim(),o.ReqDmn=i[1].trim(),o.SrcIP=i[2].trim(),o.QryType=i[3].trim(),o.Result="1"==i[4].trim()?"Allowed":"Blocked",arrayqueryloglines.push(o)}originalarrayqueryloglines=arrayqueryloglines,FilterQueryLog()}function FilterQueryLog(){""==$j("#filter_reqdmn").val()&&""==$j("#filter_srcip").val()&&0==$j("#filter_qrytype option:selected").val()&&0==$j("#filter_result option:selected").val()?arrayqueryloglines=originalarrayqueryloglines:(arrayqueryloglines=originalarrayqueryloglines,""!=$j("#filter_reqdmn").val()&&(arrayqueryloglines=$j("#filter_reqdmn").val().startsWith("!")?arrayqueryloglines.filter((function(t){return-1==t.ReqDmn.toLowerCase().indexOf($j("#filter_reqdmn").val().replace("!","").toLowerCase())})):arrayqueryloglines.filter((function(t){return-1!=t.ReqDmn.toLowerCase().indexOf($j("#filter_reqdmn").val().toLowerCase())}))),""!=$j("#filter_srcip").val()&&(arrayqueryloglines=$j("#filter_srcip").val().startsWith("!")?arrayqueryloglines.filter((function(t){return-1==t.SrcIP.indexOf($j("#filter_srcip").val().replace("!",""))})):arrayqueryloglines.filter((function(t){return-1!=t.SrcIP.indexOf($j("#filter_srcip").val())}))),0!=$j("#filter_qrytype option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter((function(t){return t.QryType==$j("#filter_qrytype option:selected").text()}))),0!=$j("#filter_result option:selected").val()&&(arrayqueryloglines=arrayqueryloglines.filter((function(t){return t.Result==$j("#filter_result option:selected").text()})))),SortTable(sortname+" "+sortdir.replace("desc","↑").replace("asc","↓").trim())}function SortTable(sorttext){sortname=sorttext.replace("↑","").replace("↓","").trim();var sortfield=sortname;switch(sortname){case"Time":sortfield="Time";break;case"Domain":sortfield="ReqDmn";break;case"Client":sortfield="SrcIP";break;case"Type":sortfield="QryType";break;case"Result":sortfield="Result"}-1==sorttext.indexOf("↓")&&-1==sorttext.indexOf("↑")||-1!=sorttext.indexOf("↓")?(eval("arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a."+sortfield+" > b."+sortfield+") ? 1 : ((b."+sortfield+" > a."+sortfield+") ? -1 : 0)); "),sortdir="asc"):(eval("arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a."+sortfield+" < b."+sortfield+") ? 1 : ((b."+sortfield+" < a."+sortfield+") ? -1 : 0)); "),sortdir="desc"),$j("#sortTableContainer").empty(),$j("#sortTableContainer").append(BuildQueryLogTableHtml()),$j(".sortable").each((function(t,e){e.innerHTML==sortname&&(e.innerHTML="asc"==sortdir?sortname+" ↑":sortname+" ↓")}))}function Assign_EventHandlers(){$j(".collapsible-jquery").off("click").on("click",(function(){$j(this).siblings().toggle("fast",(function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")}))})),$j(".collapsible-jquery").each((function(t,e){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)}));let t=null,e=null;$j("#filter_reqdmn").off("keyup touchend").on("keyup touchend",(function(e){clearTimeout(t),t=setTimeout((function(){FilterQueryLog()}),1e3)})),$j("#filter_srcip").off("keyup touchend").on("keyup touchend",(function(t){clearTimeout(e),e=setTimeout((function(){FilterQueryLog()}),1e3)})),$j("#auto_refresh").off("click").on("click",(function(){ToggleRefresh()}))}function ToggleRefresh(){$j("#auto_refresh").prop("checked",(function(t,e){e?get_querylog_file():clearTimeout(tout)}))}
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
<input type="radio" name="uidivstats_querymode" id="uidivstats_query_aaaaahttps" class="input" value="A+AAAA+HTTPS">
<label for="uidivstats_query_aaaaahttps">A+AAAA+HTTPS only</label>
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
<tr class="even" id="rowlastxqueries">
<td class="settingname">Last X DNS queries to display in query log</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="5" class="input_6_table removespacing" name="uidivstats_lastxqueries" value="5000" onkeypress="return validator.isNumber(this,event)" onblur="Validate_Number_Setting(this,10000,10);Format_Number_Setting(this)" onkeyup="Validate_Number_Setting(this,10000,10)"/>
&nbsp;results <span style="color:#FFCC00;">(between 10 and 10000, default: 5000)</span>
</td>
</tr>
<tr class="even" id="rowdaystokeep">
<td class="settingname">Number of days of data to keep</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="3" class="input_6_table removespacing" name="uidivstats_daystokeep" value="30" onkeypress="return validator.isNumber(this,event)" onblur="Validate_Number_Setting(this,365,1);Format_Number_Setting(this)" onkeyup="Validate_Number_Setting(this,365,1)"/>
&nbsp;days <span style="color:#FFCC00;">(between 1 and 365, default: 30)</span>
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
<label style="color:#FFCC00;">
<input type="checkbox" checked="" id="auto_refresh" style="padding:0;margin:0;vertical-align:middle;position:relative;top:-1px;" />&nbsp;&nbsp;Table will refresh every 60s</label>
&nbsp;&nbsp;&nbsp;&nbsp;<span id="spanRefreshNow" style="color:#FFCC00;text-decoration:underline;cursor:pointer" onclick="RefreshNow();">Refresh now</span>
<img id="imgRefreshNow" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
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
<option value="3">HTTPS</option>
<option value="4">ANY</option>
<option value="5">SRV</option>
<option value="6">SOA</option>
<option value="7">PTR</option>
<option value="8">TXT</option>
</select>
</td>
<td>
<select style="width:125px" class="input_option" onchange="FilterQueryLog();" id="filter_result">
<option value="0">All</option>
<option value="1">Allowed</option>
<option value="2">Blocked</option>
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
