var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)
var maxNoChartsBlocked = 6;
var currentNoChartsBlocked = 0;
var maxNoChartsTotal = 6;
var currentNoChartsTotal = 0;
var maxNoChartsTotalBlocked = 3;
var currentNoChartsTotalBlocked = 0;
var maxNoChartsOverall = 15;
var currentNoChartsOverall = 0;
var arrayqueryloglines = [];
var originalarrayqueryloglines = [];
var sortname = 'Time';
var sortdir = 'desc';
var tout;

Chart.defaults.global.defaultFontColor = '#CCC';
Chart.Tooltip.positioners.cursor = function(chartElements,coordinates){
	return coordinates;
};

function keyHandler(e){
	if(e.keyCode == 82){
		$j(document).off('keydown');
		ResetZoom();
	}
	else if(e.keyCode == 70){
		$j(document).off('keydown');
		ToggleFill();
	}
}

function isFilterIP(o,event){
	var keyPressed = event.keyCode ? event.keyCode : event.which;
	var i,j;
	if(validator.isFunctionButton(event)){
		return true;
	}
	if(keyPressed == 33){
		return true;
	}
	if((keyPressed > 47 && keyPressed < 58)){
		j = 0;
		for(var i = 0; i < o.value.length; i++){
			if(o.value.charAt(i) == '.'){
				j++;
			}
		}
		if(j < 3 && i >= 3){
			if(o.value.charAt(i-3) != '.' && o.value.charAt(i-2) != '.' && o.value.charAt(i-1) != '.'){
				o.value = o.value+'.';
			}
		}
		return true;
	}
	else if(keyPressed == 46){
		j = 0;
		for(var i = 0; i < o.value.length; i++){
			if(o.value.charAt(i) == '.'){
				j++;
			}
		}
		if(o.value.charAt(i-1) == '.' || j == 3){
			return false;
		}
		return true;
	}
	else if(keyPressed == 13){ // 'ENTER'
		return true;
	}
	else if(event.metaKey && (keyPressed == 65 || keyPressed == 67 || keyPressed == 86 || keyPressed == 88
	|| keyPressed == 97 || keyPressed == 99 || keyPressed == 118 || keyPressed == 120)){ //for Mac+Safari,let 'Command+A'(C,V,X) can work
		return true
	}
	return false;
}

function Validate_Number_Setting(forminput,upperlimit,lowerlimit){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;

	if(inputvalue > upperlimit || inputvalue < lowerlimit){
		$j(forminput).addClass('invalid');
		return false;
	}
	else{
		$j(forminput).removeClass('invalid');
		return true;
	}
}

function Format_Number_Setting(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;

	if(forminput.value.length == 0 || inputvalue == NaN){
		return false;
	}
	else{
		forminput.value = parseInt(forminput.value);
		return true;
	}
}

function Validate_All(){
	var validationfailed = false;
	if(! Validate_Number_Setting(document.form.uidivstats_lastxqueries,10000,10)){validationfailed=true;}
	if(! Validate_Number_Setting(document.form.uidivstats_daystokeep,365,1)){validationfailed=true;}

	if(validationfailed){
		alert('Validation for some fields failed. Please correct invalid values and try again.');
		return false;
	}
	else{
		return true;
	}
}

$j(document).keydown(function(e){keyHandler(e);});
$j(document).keyup(function(e){
	$j(document).keydown(function(e){
		keyHandler(e);
	});
});

var metriclist = ['Blocked','Total'];
var chartlist = ['daily','weekly','monthly'];
var timeunitlist = ['hour','day','day'];
var intervallist = [24,7,30];
var bordercolourlist = ['#fc8500','#42ecf5'];
var backgroundcolourlist = ['rgba(252,133,0,0.5)','rgba(66,236,245,0.5)'];

function Draw_Chart_NoData(txtchartname,texttodisplay){
	document.getElementById('canvasChart'+txtchartname).width = '735';
	document.getElementById('canvasChart'+txtchartname).height = '500';
	document.getElementById('canvasChart'+txtchartname).style.width = '735px';
	document.getElementById('canvasChart'+txtchartname).style.height = '500px';
	var ctx = document.getElementById('canvasChart'+txtchartname).getContext('2d');
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = 'normal normal bolder 48px Arial';
	ctx.fillStyle = 'white';
	ctx.fillText(texttodisplay,368,250);
	ctx.restore();
}

function Draw_Chart(txtchartname){
	var chartperiod = getChartPeriod($j('#'+txtchartname+'_Period option:selected').val());
	var charttype = getChartType($j('#'+txtchartname+'_Type option:selected').val());
	var chartclientraw = $j('#'+txtchartname+'_Clients option:selected').text();

	var chartclient = chartclientraw.substring(chartclientraw.indexOf('(')+1,chartclientraw.indexOf(')',chartclientraw.indexOf('(')+1))

	var dataobject;
	if(chartclientraw == 'All (*)'){
		dataobject = window[txtchartname+chartperiod];
	}
	else{
		dataobject = window[txtchartname+chartperiod+'clients'];
	}
	if(typeof dataobject === 'undefined' || dataobject === null){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	if(dataobject.length == 0){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }

	var chartData,chartLabels;

	if(chartclientraw == 'All (*)'){
		chartData = dataobject.map(function(d){return d.Count});
		chartLabels = dataobject.map(function(d){return d.ReqDmn});
	}
	else{
		chartData = dataobject.filter(function(item){
			return item.SrcIP == chartclient;
		}).map(function(d){return d.Count});
		chartLabels = dataobject.filter(function(item){
			return item.SrcIP == chartclient;
		}).map(function(d){return d.ReqDmn});
	}

	$j.each(chartLabels,function(index,value){
		chartLabels[index] = chunk(value.toLowerCase(),30).join('\n');
	});

	var objchartname = window['Chart'+txtchartname];;

	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('canvasChart'+txtchartname).getContext('2d');
	var chartOptions = {
		segmentShowStroke: false,
		segmentStrokeColor: '#000',
		animationEasing: 'easeOutQuart',
		animationSteps: 100,
		maintainAspectRatio: false,
		animateScale: true,
		legend: {
			onClick: null,
			display: showLegend(charttype),
			position: 'left',
			labels: {
				fontColor: '#ffffff'
			}
		},
		layout: {
			padding: {
				top: getChartPadding(charttype)
			}
		},
		title: {
			display: showTitle(charttype),
			text: getChartLegendTitle(),
			position: 'top'
		},
		tooltips: {
			callbacks: {
				title: function(tooltipItem,data){
					return data.labels[tooltipItem[0].index];
				},
				label: function(tooltipItem,data){
					return comma(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]);
				}
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				display: showAxis(charttype,'x'),
				type: getChartScale($j('#'+txtchartname+'_Scale option:selected').val(),charttype,'x'),
				gridLines: {
					display: showGrid(charttype,'x'),
					color: '#282828'
				},
				scaleLabel: {
					display: true,
					labelString: getAxisLabel(charttype,'x')
				},
				ticks: {
					display: showTicks(charttype,'x'),
					beginAtZero: true,
					labels: {
						index:  ['min','max'],
						removeEmptyLines: true,
					},
					userCallback: LogarithmicFormatter
				}
			}],
			yAxes: [{
				display: showAxis(charttype,'y'),
				type: getChartScale($j('#'+txtchartname+'_Scale option:selected').val(),charttype,'y'),
				gridLines: {
					display: false,
					color: '#282828'
				},
				scaleLabel: {
					display: true,
					labelString: getAxisLabel(charttype,'y')
				},
				ticks: {
					display: showTicks(charttype,'y'),
					beginAtZero: true,
					autoSkip: false,
					lineHeight: 0.8,
					padding: -5,
					labels: {
						index:  ['min','max'],
						removeEmptyLines: true,
					},
					userCallback: LogarithmicFormatter
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
						x: ZoomPanMax(charttype,'x',chartData),
						y: ZoomPanMax(charttype,'y',chartData)
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
						x: ZoomPanMax(charttype,'x',chartData),
						y: ZoomPanMax(charttype,'y',chartData)
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
			borderColor: '#000000'
		}]
	};
	objchartname = new Chart(ctx,{
		type: charttype,
		options: chartOptions,
		data: chartDataset,
		plugins: [{
			beforeInit: function(chart){
				chart.data.labels.forEach(function(e,i,a){
					if(/\n/.test(e)){
						a[i] = e.split(/\n/);
					}
				});
			}
		}]
	});
	window['Chart'+txtchartname] = objchartname;
}

function Draw_Time_Chart(txtchartname){
	var chartperiod = getChartPeriod($j('#'+txtchartname+'time_Period option:selected').val());
	var txttitle = 'DNS Queries';
	var txtunitx = timeunitlist[$j('#'+txtchartname+'time_Period option:selected').val()];
	var numunitx = intervallist[$j('#'+txtchartname+'time_Period option:selected').val()];
	var dataobject = window[txtchartname+chartperiod+'time'];

	if(typeof dataobject === 'undefined' || dataobject === null){ Draw_Chart_NoData(txtchartname+'time','No data to display'); return; }
	if(dataobject.length == 0){ Draw_Chart_NoData(txtchartname+'time','No data to display'); return; }

	var unique = [];
	var chartQueryTypes = [];
	for(let i = 0; i < dataobject.length; i++ ){
		if( !unique[dataobject[i].Fieldname]){
			chartQueryTypes.push(dataobject[i].Fieldname);
			unique[dataobject[i].Fieldname] = 1;
		}
	}

	var chartData = dataobject.map(function(d){ return {x: d.Time,y: d.QueryCount}});
	var objchartname = window['Chart'+txtchartname+'time'];;

	factor=0;
	if(txtunitx=='hour'){
		factor=60*60*1000;
	}
	else if(txtunitx=='day'){
		factor=60*60*24*1000;
	}
	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('canvasChart'+txtchartname+'time').getContext('2d');
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : '#000',
		animationEasing : 'easeOutQuart',
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		hover: { mode: 'point' },
		legend: { display: true,position: 'top'},
		title: { display: true,text: txttitle },
		tooltips: {
			callbacks: {
				title: function (tooltipItem,data){ return (moment(tooltipItem[0].xLabel,'X').format('YYYY-MM-DD HH:mm:ss')); },
				label: function (tooltipItem,data){ return data.datasets[tooltipItem.datasetIndex].label+': '+data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y;}
			},
			mode: 'x',
			position: 'cursor',
			intersect: false
		},
		scales: {
			xAxes: [{
				type: 'time',
				gridLines: { display: true,color: '#282828' },
				ticks: {
					min: moment().subtract(numunitx,txtunitx+'s'),
					display: true
				},
				time: { parser: 'X',unit: txtunitx,stepSize: 1 }
			}],
			yAxes: [{
				type: getChartScale($j('#'+txtchartname+'time_Scale option:selected').val(),'time','y'),
				gridLines: { display: false,color: '#282828' },
				scaleLabel: { display: false,labelString: txttitle },
				ticks: {
					display: true,
					beginAtZero: true,
					labels: {
						index:  ['min','max'],
						removeEmptyLines: true,
					},
					userCallback: LogarithmicFormatter
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
						y: getLimit(chartData,'y','min',false),
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,'y','max',false),
					},
				},
				zoom: {
					enabled: true,
					drag: true,
					mode: 'xy',
					rangeMin: {
						x: new Date().getTime() - (factor * numunitx),
						y: getLimit(chartData,'y','min',false),
					},
					rangeMax: {
						x: new Date().getTime(),
						y: getLimit(chartData,'y','max',false),
					},
					speed: 0.1
				},
			}
		}
	};
	var lineDataset = {
		datasets: getDataSets(txtchartname,dataobject,chartQueryTypes)
	};
	objchartname = new Chart(ctx,{
		type: 'line',
		data: lineDataset,
		options: lineOptions
	});
	window['Chart'+txtchartname+'time']=objchartname;
}

function getDataSets(txtchartname,objdata,objQueryTypes){
	var datasets = [];
	colourname='#fc8500';

	for(var i = 0; i < objQueryTypes.length; i++){
		var querytypedata = objdata.filter(function(item){
			return item.Fieldname == objQueryTypes[i];
		}).map(function(d){return {x: d.Time,y: d.QueryCount}});

		datasets.push({ label: objQueryTypes[i],data: querytypedata,borderWidth: 1,pointRadius: 1,lineTension: 0,fill: true,backgroundColor: backgroundcolourlist[i],borderColor: bordercolourlist[i]});
	}
	datasets.reverse();
	return datasets;
}

function chunk(str,n){
	var ret = [];
	var i;
	var len;

	for(var i = 0,len = str.length; i < len; i += n){
		ret.push(str.substr(i,n));
	}

	return ret;
};

function LogarithmicFormatter(tickValue,index,ticks){
	if(this.type != 'logarithmic'){
		if(! isNaN(tickValue)){
			return round(tickValue,0).toFixed(0);
		}
		else{
			return tickValue;
		}
	}
	else{
		var labelOpts =  this.options.ticks.labels || {};
		var labelIndex = labelOpts.index || ['min','max'];
		var labelSignificand = labelOpts.significand || [1,2,5];
		var significand = tickValue / (Math.pow(10,Math.floor(Chart.helpers.log10(tickValue))));
		var emptyTick = labelOpts.removeEmptyLines === true ? undefined : '';
		var namedIndex = '';
		if(index === 0){
			namedIndex = 'min';
		}
		else if(index === ticks.length - 1){
			namedIndex = 'max';
		}
		if(labelOpts === 'all' || labelSignificand.indexOf(significand) !== -1 || labelIndex.indexOf(index) !== -1 || labelIndex.indexOf(namedIndex) !== -1){
			if(tickValue === 0){
				return '0';
			}
			else{
				if(! isNaN(tickValue)){
					return round(tickValue,0).toFixed(0);
				}
				else{
					return tickValue;
				}
			}
		}
		return emptyTick;
	}
};

function GetCookie(cookiename,returntype){
	if(cookie.get('uidivstats_'+cookiename) != null){
		return cookie.get('uidivstats_'+cookiename);
	}
	else{
		if(returntype == 'string'){
			return '';
		}
		else if(returntype == 'number'){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue){
	cookie.set('uidivstats_'+cookiename,cookievalue,10 * 365);
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	LoadCustomSettings();
	show_menu();
	get_conf_file();
	get_domainstoexclude_file();

	$j('#sortTableContainer').empty();
	$j('#sortTableContainer').append(BuildQueryLogTableHtmlNoData());

	$j('#td_charts').append(BuildChartHtml('DNS Queries','TotalBlockedtime','true','false'));
	$j('#td_charts').append(BuildChartHtml('Top blocked domains','Blocked','false','true'));
	$j('#td_charts').append(BuildChartHtml('Top requested domains','Total','false','true'));

	get_sqldata_file();
	get_querylog_file();
	get_DivStats_file();
	ScriptUpdateLayout();
}

function get_sqldata_file(){
	$j.ajax({
		url: '/ext/uiDivStats/SQLData.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(get_sqldata_file,1000);
		},
		success: function(){
			SetuiDivStatsTitle();
			$j('#uidivstats_div_keystats').append(BuildKeyStatsTableHtml('Key Stats','keystats'));
			$j('#keystats_Period').val(GetCookie('keystats_Period','number')).change();
			get_clients_file();
		}
	});
}

function get_clients_file(){
	$j.ajax({
		url: '/ext/uiDivStats/csv/ipdistinctclients.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(get_clients_file,1000);
		},
		success: function(){
			for(var i = 0; i < metriclist.length; i++){
				Draw_Chart_NoData(metriclist[i],'Data loading...');
				$j('#'+metriclist[i]+'_Period').val(GetCookie(metriclist[i]+'_Period','number'));
				$j('#'+metriclist[i]+'_Type').val(GetCookie(metriclist[i]+'_Type','number'));
				$j('#'+metriclist[i]+'_Scale').val(GetCookie(metriclist[i]+'_Scale','number'));
				ChartScaleOptions($j('#'+metriclist[i]+'_Type')[0]);
				for(var i2 = 0; i2 < chartlist.length; i2++){
					d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]));
					d3.csv('/ext/uiDivStats/csv/'+metriclist[i]+chartlist[i2]+'clients.htm').then(SetGlobalDataset.bind(null,metriclist[i]+chartlist[i2]+'clients'));
				}
			}
			Draw_Chart_NoData('TotalBlockedtime','Data loading...');
			for(var i = 0; i < chartlist.length; i++){
				$j('#TotalBlockedtime_Period').val(GetCookie('TotalBlockedtime_Period','number'));
				$j('#TotalBlockedtime_Scale').val(GetCookie('TotalBlockedtime_Scale','number'));
				d3.csv('/ext/uiDivStats/csv/TotalBlocked'+chartlist[i]+'time.htm').then(SetGlobalDataset.bind(null,'TotalBlocked'+chartlist[i]+'time'));
			}
		}
	});
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/uiDivStats/config.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_conf_file,1000);
		},
		success: function(data){
			var configdata=data.split('\n');
			configdata = configdata.filter(Boolean);

			for(var i = 0; i < configdata.length; i++){
				eval('document.form.uidivstats_'+configdata[i].split('=')[0].toLowerCase()).value = configdata[i].split('=')[1].replace(/(\r\n|\n|\r)/gm,'');
			}
		}
	});
}

function get_domainstoexclude_file(){
	$j.ajax({
		url: '/ext/uiDivStats/domainstoexclude.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_domainstoexclude_file,5000);
		},
		success: function(data){
			document.getElementById('uidivstats_domainstoexclude').innerHTML=data;
		}
	});
}

function get_DivStats_file(){
	$j.ajax({
		url: '/ext/uiDivStats/DiversionStats.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_DivStats_file,5000);
		},
		success: function(data){
			document.getElementById('DiversionStats').innerHTML=data;
		}
	});
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;

	if(txtchartname.indexOf('TotalBlocked') != -1){
		currentNoChartsTotalBlocked++;
		currentNoChartsOverall++;
		if(currentNoChartsTotalBlocked == maxNoChartsTotalBlocked){
			Draw_Time_Chart('TotalBlocked');
		}
	}
	else if(txtchartname.indexOf('Blocked') != -1){
		currentNoChartsBlocked++;
		currentNoChartsOverall++;
		if(currentNoChartsBlocked == maxNoChartsBlocked){
			SetClients('Blocked');
			Draw_Chart('Blocked');
		}
	}
	else if(txtchartname.indexOf('Total') != -1){
		currentNoChartsTotal++;
		currentNoChartsOverall++;
		if(currentNoChartsTotal == maxNoChartsTotal){
			SetClients('Total');
			Draw_Chart('Total');
		}
	}

	if(currentNoChartsOverall == maxNoChartsOverall){
		showhide('imgUpdateStats',false);
		showhide('uidivstats_text',false);
		showhide('btnUpdateStats',true);
		Assign_EventHandlers();
	}
}

function SetClients(txtchartname){
	var dataobject = window[txtchartname+getChartPeriod($j('#'+txtchartname+'_Period option:selected').val())+'clients'];

	var unique = [];
	var chartClients = [];
	for(let i = 0; i < dataobject.length; i++ ){
		if( !unique[dataobject[i].SrcIP]){
			chartClients.push(dataobject[i].SrcIP);
			unique[dataobject[i].SrcIP] = 1;
		}
	}

	chartClients.sort();
	for(var i = 0; i < chartClients.length; i++){
		var arrclient = hostiparray.filter(function(item){
			return item[0] == chartClients[i];
		})[0];
		$j('#'+txtchartname+'_Clients').append($j('<option>',{
			value: i+1,
			text: arrclient[1]+' ('+arrclient[0]+')'
		}));
	}
}

function ScriptUpdateLayout(){
	var localver = GetVersionNumber('local');
	var serverver = GetVersionNumber('server');
	$j('#uidivstats_version_local').text(localver);

	if(localver != serverver && serverver != 'N/A'){
		$j('#uidivstats_version_server').text('Updated version available: '+serverver);
		showhide('btnChkUpdate',false);
		showhide('uidivstats_version_server',true);
		showhide('btnDoUpdate',true);
	}
}

function update_status(){
	$j.ajax({
		url: '/ext/uiDivStats/detect_update.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(update_status,1000);
		},
		success: function(){
			if(updatestatus == 'InProgress'){
				setTimeout(update_status,1000);
			}
			else{
				document.getElementById('imgChkUpdate').style.display = 'none';
				showhide('uidivstats_version_server',true);
				if(updatestatus != 'None'){
					$j('#uidivstats_version_server').text('Updated version available: '+updatestatus);
					showhide('btnChkUpdate',false);
					showhide('btnDoUpdate',true);
				}
				else{
					$j('#uidivstats_version_server').text('No update available');
					showhide('btnChkUpdate',true);
					showhide('btnDoUpdate',false);
				}
			}
		}
	});
}

function CheckUpdate(){
	showhide('btnChkUpdate',false);
	document.formScriptActions.action_script.value='start_uiDivStatscheckupdate';
	document.formScriptActions.submit();
	document.getElementById('imgChkUpdate').style.display = '';
	setTimeout(update_status,2000);
}

function DoUpdate(){
	document.form.action_script.value = 'start_uiDivStatsdoupdate';
	document.form.action_wait.value = 10;
	showLoading();
	document.form.submit();
}

function SaveConfig(){
	if(Validate_All()){
		document.getElementById('amng_custom').value = JSON.stringify($j('form').serializeObject());
		document.form.action_script.value = 'start_uiDivStatsconfig';
		document.form.action_wait.value = 10;
		showLoading();
		document.form.submit();
	}
	else{
		return false;
	}
}

function RefreshNow(){
	clearTimeout(tout);
	showhide('spanRefreshNow',false);
	document.formScriptActions.action_script.value='start_uiDivStatsquerylog';
	document.formScriptActions.submit();
	document.getElementById('imgRefreshNow').style.display = '';
	setTimeout(get_querylog_file,5000);
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	var a = this.serializeArray();
	$j.each(a,function(){
		if(o[this.name] !== undefined && this.name.indexOf('uidivstats') != -1 && this.name.indexOf('version') == -1 && this.name.indexOf('domainstoexclude') == -1){
			if(!o[this.name].push){
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else if(this.name.indexOf('uidivstats') != -1 && this.name.indexOf('version') == -1 && this.name.indexOf('domainstoexclude') == -1){
			o[this.name] = this.value || '';
		}
	});
	var domainstoexclude = document.getElementById("uidivstats_domainstoexclude").value.replace(/\n/g,'||||');
	o["uidivstats_domainstoexclude"] = domainstoexclude;
	return o;
};

function GetVersionNumber(versiontype){
	var versionprop;
	if(versiontype == 'local'){
		versionprop = custom_settings.uidivstats_version_local;
	}
	else if(versiontype == 'server'){
		versionprop = custom_settings.uidivstats_version_server;
	}

	if(typeof versionprop == 'undefined' || versionprop == null){
		return 'N/A';
	}
	else{
		return versionprop;
	}
}

function RedrawAllCharts(){
	$j('#td_charts').append(BuildChartHtml('DNS Queries','TotalBlockedtime','true','false'));
	$j('#td_charts').append(BuildChartHtml('Top blocked domains','Blocked','false','true'));
	$j('#td_charts').append(BuildChartHtml('Top requested domains','Total','false','true'));

	get_sqldata_file();

	Assign_EventHandlers();
}

function PostStatUpdate(){
	currentNoChartsBlocked = 0;
	currentNoChartsTotal = 0;
	currentNoChartsTotalBlocked = 0;
	currentNoChartsOverall = 0;
	$j('#uidivstats_div_keystats').empty();
	$j('#uidivstats_chart_TotalBlockedtime').remove();
	$j('#uidivstats_chart_Blocked').remove();
	$j('#uidivstats_chart_Total').remove();
	setTimeout(RedrawAllCharts,3000);
}

function updateStats(){
	showhide('btnUpdateStats',false);
	document.formScriptActions.action_script.value='start_uiDivStats';
	document.formScriptActions.submit();
	showhide('imgUpdateStats',true);
	showhide('uidivstats_text',false);
	setTimeout(StartUpdateStatsInterval,2000);
}

var myinterval;
function StartUpdateStatsInterval(){
	myinterval = setInterval(update_uidivstats,1000);
}

var statcount=2;
function update_uidivstats(){
	statcount++;
	$j.ajax({
		url: '/ext/uiDivStats/detect_uidivstats.js',
		dataType: 'script',
		timeout: 1000,
		error: function(xhr){
			//do nothing
		},
		success: function(){
			if(uidivstatsstatus == 'InProgress'){
				showhide('imgUpdateStats',true);
				showhide('uidivstats_text',true);
				document.getElementById('uidivstats_text').innerHTML = 'Stat update in progress - '+statcount+'s elapsed';
			}
			else if(uidivstatsstatus == 'Done'){
				document.getElementById('uidivstats_text').innerHTML = 'Refreshing charts...';
				statcount=2;
				clearInterval(myinterval);
				PostStatUpdate();
			}
			else if(uidivstatsstatus == 'LOCKED'){
				showhide('imgUpdateStats',false);
				document.getElementById('uidivstats_text').innerHTML = 'Stat update already running!';
				showhide('uidivstats_text',true);
				showhide('btnUpdateStats',true);
				clearInterval(myinterval);
			}
		}
	});
}

function reload(){
	location.reload(true);
}

function ToggleFill(){
	if(ShowFill == 'false'){
		ShowFill = 'origin';
		SetCookie('ShowFill','origin');
	}
	else{
		ShowFill = 'false';
		SetCookie('ShowFill','false');
	}
	for(var i = 0; i < metriclist.length; i++){
		for(var i2 = 0; i2 < chartlist.length; i2++){
			window['Chart'+metriclist[i]+chartlist[i2]+'time'].data.datasets[0].fill=ShowFill;
			window['Chart'+metriclist[i]+chartlist[i2]+'time'].update();
		}
	}
}

function getLimit(datasetname,axis,maxmin,isannotation){
	var limit=0;
	var values;
	if(axis == 'x'){
		values = datasetname.map(function(o){ return o.x } );
	}
	else{
		values = datasetname.map(function(o){ return o.y } );
	}

	if(maxmin == 'max'){
		limit = Math.max.apply(Math,values);
	}
	else{
		limit = Math.min.apply(Math,values);
	}
	if(maxmin == 'max' && limit == 0 && isannotation == false){
		limit = 1;
	}
	return limit;
}

function getAverage(datasetname){
	var total = 0;
	for(var i = 0; i < datasetname.length; i++){
		total += (datasetname[i].y*1);
	}
	var avg = total / datasetname.length;
	return avg;
}

function getMax(datasetname){
	return Math.max(...datasetname);
}

function round(value,decimals){
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
}

function getRandomColor(){
	var r = Math.floor(Math.random() * 255);
	var g = Math.floor(Math.random() * 255);
	var b = Math.floor(Math.random() * 255);
	return 'rgba('+r+','+g+','+b+',1)';
}

function poolColors(a){
	var pool = [];
	for(var i = 0; i < a; i++){
		pool.push(getRandomColor());
	}
	return pool;
}

function getChartType(layout){
	var charttype = 'horizontalBar';
	if(layout == 0) charttype = 'horizontalBar';
	else if(layout == 1) charttype = 'bar';
	else if(layout == 2) charttype = 'pie';
	return charttype;
}

function getChartPeriod(period){
	var chartperiod = 'daily';
	if(period == 0) chartperiod = 'daily';
	else if(period == 1) chartperiod = 'weekly';
	else if(period == 2) chartperiod = 'monthly';
	return chartperiod;
}

function getChartScale(scale,charttype,axis){
	var chartscale = 'category';
	if(scale == 0){
		if((charttype == 'horizontalBar' && axis == 'x') || (charttype == 'bar' && axis == 'y') || (charttype == 'time' && axis == 'y')){
			chartscale = 'linear';
		}
	}
	else if(scale == 1){
		if((charttype == 'horizontalBar' && axis == 'x') || (charttype == 'bar' && axis == 'y') || (charttype == 'time' && axis == 'y')){
			chartscale = 'logarithmic';
		}
	}
	return chartscale;
}

function ChartScaleOptions(e){
	var chartname = e.id.substring(0,e.id.indexOf('_'));
	let dropdown = $j('#'+chartname+'_Scale');
	if($j('#'+chartname+'_Type option:selected').val() != 2){
		if(dropdown[0].length == 1){
			dropdown.empty();
			dropdown.append($j('<option></option>').attr('value',0).text('Linear'));
			dropdown.append($j('<option></option>').attr('value',1).text('Logarithmic'));
			dropdown.prop('selectedIndex',0);
		}
	}
	else{
		if(dropdown[0].length == 2){
			dropdown.empty();
			dropdown.append($j('<option></option>').attr('value',0).text('Linear'));
			dropdown.prop('selectedIndex',0);
		}
	}
}

function ZoomPanEnabled(charttype){
	if(charttype == 'bar'){
		return 'y';
	}
	else if(charttype == 'horizontalBar'){
		return 'x';
	}
	else{
		return '';
	}
}

function ZoomPanMax(charttype,axis,datasetname){
	if(axis == 'x'){
		if(charttype == 'bar'){
			return null;
		}
		else if(charttype == 'horizontalBar'){
			return getMax(datasetname);
		}
		else{
			return null;
		}
	}
	else if(axis == 'y'){
		if(charttype == 'bar'){
			return getMax(datasetname);
		}
		else if(charttype == 'horizontalBar'){
			return null;
		}
		else{
			return null;
		}
	}
}

function ResetZoom(){
	for(var i = 0; i < metriclist.length; i++){
		var chartobj = window['Chart'+metriclist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ continue; }
		chartobj.resetZoom();
	}
	var chartobj = window['ChartTotalBlockedtime'];
	if(typeof chartobj === 'undefined' || chartobj === null){ return; }
	chartobj.resetZoom();
}

function DragZoom(button){
	var drag = true;
	var pan = false;
	var buttonvalue = '';
	if(button.value.indexOf('On') != -1){
		drag = false;
		pan = true;
		buttonvalue = 'Drag Zoom Off';
	}
	else{
		drag = true;
		pan = false;
		buttonvalue = 'Drag Zoom On';
	}

	for(var i = 0; i < metriclist.length; i++){
		for(var i2 = 0; i2 < chartlist.length; i2++){
			var chartobj = window['Chart'+metriclist[i]+chartlist[i2]];
			if(typeof chartobj === 'undefined' || chartobj === null){ continue; }
			chartobj.options.plugins.zoom.zoom.drag = drag;
			chartobj.options.plugins.zoom.pan.enabled = pan;
			button.value = buttonvalue;
			chartobj.update();
		}
	}
}

function showGrid(e,axis){
	if(e == null){
		return true;
	}
	else if(e == 'pie'){
		return false;
	}
	else{
		return true;
	}
}

function showAxis(e,axis){
	if(e == 'bar' && axis == 'x'){
		return true;
	}
	else{
		if(e == null){
			return true;
		}
		else if(e == 'pie'){
			return false;
		}
		else{
			return true;
		}
	}
}

function showTicks(e,axis){
	if(e == 'bar' && axis == 'x'){
		return false;
	}
	else{
		if(e == null){
			return true;
		}
		else if(e == 'pie'){
			return false;
		}
		else{
			return true;
		}
	}
}

function showLegend(e){
	if(e == 'pie'){
		return true;
	}
	else{
		return false;
	}
}

function showTitle(e){
	if(e == 'pie'){
		return true;
	}
	else{
		return false;
	}
}

function getChartPadding(e){
	if(e == 'bar'){
		return 10;
	}
	else{
		return 0;
	}
}

function getChartLegendTitle(){
	var chartlegendtitlelabel = 'Domain name';

	for(var i = 0; i < 350 - chartlegendtitlelabel.length; i++){
		chartlegendtitlelabel = chartlegendtitlelabel+' ';
	}

	return chartlegendtitlelabel;
}

function getAxisLabel(type,axis){
	var axislabel = '';
	if(axis == 'x'){
		if(type == 'horizontalBar') axislabel = 'Hits';
			else if(type == 'bar'){
				axislabel = '';
			} else if(type == 'pie') axislabel = '';
			return axislabel;
	} else if(axis == 'y'){
		if(type == 'horizontalBar'){
			axislabel = '';
		} else if(type == 'bar') axislabel = 'Hits';
		else if(type == 'pie') axislabel = '';
		return axislabel;
	}
}

function changeChart(e){
	value = e.value * 1;
	name = e.id.substring(0,e.id.indexOf('_'));
	if(e.id.indexOf('Clients') == -1){
		SetCookie(e.id,value);
	}
	if(e.id.indexOf('Period') != -1){
		if(e.id.indexOf('TotalBlocked') == -1){
			$j('#'+name+'_Clients option[value!=0]').remove();
			SetClients(name);
		}
	}
	if(e.id.indexOf('time') == -1){
		Draw_Chart(name);
	}
	else{
		Draw_Time_Chart(name.replace('time',''));
	}
}

function changeTable(e){
	value = e.value * 1;
	name = e.id.substring(0,e.id.indexOf('_'));
	SetCookie(e.id,value);

	var tableperiod = getChartPeriod(value);

	$j('#keystatstotal').text(window['QueriesTotal'+tableperiod]);
	$j('#keystatsblocked').text(window['QueriesBlocked'+tableperiod]);
	$j('#keystatspercent').text(window['BlockedPercentage'+tableperiod]);
}

function BuildChartHtml(txttitle,txtbase,istime,perip){
	var charthtml = '<div style="line-height:10px;">&nbsp;</div>';
	charthtml += '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_chart_'+txtbase+'">';
	charthtml += '<thead class="collapsible-jquery"';
	charthtml += '<tr><td colspan="2">'+txttitle+' (click to expand/collapse)</td></tr>';
	charthtml += '</thead>';
	charthtml += '<tr class="even">';
	charthtml += '<th width="40%">Period to display</th>';
	charthtml += '<td>';
	charthtml += '<select style="width:150px" class="input_option" onchange="changeChart(this)" id="'+txtbase+'_Period">';
	charthtml += '<option value=0>Last 24 hours</option>';
	charthtml += '<option value=1>Last 7 days</option>';
	charthtml += '<option value=2>Last 30 days</option>';
	charthtml += '</select>';
	charthtml += '</td>';
	charthtml += '</tr>';
	if(istime == 'false'){
		charthtml += '<tr class="even">';
		charthtml += '<th width="40%">Layout for chart</th>';
		charthtml += '<td>';
		charthtml += '<select style="width:100px" class="input_option" onchange="ChartScaleOptions(this);changeChart(this)" id="'+txtbase+'_Type">';
		charthtml += '<option value=0>Horizontal</option>';
		charthtml += '<option value=1>Vertical</option>';
		charthtml += '<option value=2>Pie</option>';
		charthtml += '</select>';
		charthtml += '</td>';
		charthtml += '</tr>';
	}
	charthtml += '<tr class="even">';
	charthtml += '<th width="40%">Scale type</th>';
	charthtml += '<td>';
	charthtml += '<select style="width:150px" class="input_option" onchange="changeChart(this)" id="'+txtbase+'_Scale">';
	charthtml += '<option value=0>Linear</option>';
	charthtml += '<option value=1>Logarithmic</option>';
	charthtml += '</select>';
	charthtml += '</td>';
	charthtml += '</tr>';
	if(perip == 'true'){
		charthtml += '<tr class="even">';
		charthtml += '<th width="40%">Client to display</th>';
		charthtml += '<td>';
		charthtml += '<select style="width:250px" class="input_option" onchange="changeChart(this)" id="'+txtbase+'_Clients">';
		charthtml += '<option value=0>All (*)</option>';
		charthtml += '</select>';
		charthtml += '</td>';
		charthtml += '</tr>';
	}
	charthtml += '<tr>';
	charthtml += '<td colspan="2" style="padding: 2px;">';
	charthtml += '<div style="background-color:#2f3e44;border-radius:10px;width:735px;padding-left:5px;" id="divChart'+txtbase+'"><canvas id="canvasChart'+txtbase+'" height="500"></div>';
	charthtml += '</td>';
	charthtml += '</tr>';
	charthtml += '</table>';
	return charthtml;
}

function BuildKeyStatsTableHtml(txttitle,txtbase){
	var tablehtml = '<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="uidivstats_table_keystats">';
	tablehtml += '<col style="width:40%;">';
	tablehtml += '<col style="width:60%;">';
	tablehtml += '<thead class="collapsible-jquery">';
	tablehtml += '<tr><td colspan="2">'+txttitle+' (click to expand/collapse)</td></tr>';
	tablehtml += '</thead>';
	tablehtml += '<tr class="even">';
	tablehtml += '<th>Domains currently on blocklist</th>';
	tablehtml += '<td id="keystatsdomains" style="font-size: 16px; font-weight: bolder;">'+BlockedDomains+'</td>';
	tablehtml += '</tr>';
	tablehtml += '<tr class="even">';
	tablehtml += '<th>Period to display</th>';
	tablehtml += '<td colspan="2">';
	tablehtml += '<select style="width:150px" class="input_option" onchange="changeTable(this)" id="'+txtbase+'_Period">';
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
	tablehtml += '</table>';
	return tablehtml;
}

function BuildQueryLogTableHtmlNoData(){
	var tablehtml='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="sortTable">';
	tablehtml += '<tr>';
	tablehtml += '<td colspan="3" class="nodata">';
	tablehtml += 'Data loading...';
	tablehtml += '</td>';
	tablehtml += '</tr>';
	tablehtml += '</table>';
	return tablehtml;
}

function BuildQueryLogTableHtml(){
	var tablehtml = '<table border="0" cellpadding="0" cellspacing="0" width="100%" class="sortTable" style="table-layout:fixed;" id="sortTable">';
	tablehtml += '<col style="width:110px;">';
	tablehtml += '<col style="width:320px;">';
	tablehtml += '<col style="width:110px;">';
	tablehtml += '<col style="width:50px;">';
	tablehtml += '<col style="width:140px;">';
	tablehtml += '<thead class="sortTableHeader">';
	tablehtml += '<tr>';
	tablehtml += '<th class="sortable" onclick="SortTable(this.innerHTML)">Time</th>';
	tablehtml += '<th class="sortable" onclick="SortTable(this.innerHTML)">Domain</th>';
	tablehtml += '<th class="sortable" onclick="SortTable(this.innerHTML)">Client</th>';
	tablehtml += '<th class="sortable" onclick="SortTable(this.innerHTML)">Type</th>';
	tablehtml += '<th class="sortable" onclick="SortTable(this.innerHTML)">Result</th>';
	tablehtml += '</tr>';
	tablehtml += '</thead>';
	tablehtml += '<tbody class="sortTableContent">';

	for(var i = 0; i < arrayqueryloglines.length; i++){
		tablehtml += '<tr class="sortRow">';
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
			tout = setTimeout(get_querylog_file,1000);
		},
		success: function(data){
			ParseQueryLog(data);
			document.getElementById('imgRefreshNow').style.display = 'none';
			showhide('spanRefreshNow',true);
			if(document.getElementById('auto_refresh').checked){
				tout = setTimeout(get_querylog_file,60000);
			}
		}
	});
}

function ParseQueryLog(data){
	var arrayloglines = data.split('\n');
	arrayloglines = arrayloglines.filter(Boolean);
	arrayqueryloglines = [];
	for(var i = 0; i < arrayloglines.length; i++){
		var logfields = arrayloglines[i].split('|');
		var parsedlogline = new Object();
		parsedlogline.Time = moment.unix(logfields[0]).format('YYYY-MM-DD HH:mm').trim();
		parsedlogline.ReqDmn = logfields[1].trim();
		parsedlogline.SrcIP = logfields[2].trim();
		parsedlogline.QryType = logfields[3].trim();
		parsedlogline.Result = logfields[4].trim() == '1' ? 'Allowed' : 'Blocked';
		arrayqueryloglines.push(parsedlogline);
	}
	originalarrayqueryloglines = arrayqueryloglines;
	FilterQueryLog();
}

function FilterQueryLog(){
	if( $j('#filter_reqdmn').val() == '' && $j('#filter_srcip').val() == '' && $j('#filter_qrytype option:selected').val() == 0 && $j('#filter_result option:selected').val() == 0 ){
		arrayqueryloglines = originalarrayqueryloglines;
	}
	else{
		arrayqueryloglines = originalarrayqueryloglines;

		if($j('#filter_reqdmn').val() != '' ){
			if($j('#filter_reqdmn').val().startsWith('!')){
				arrayqueryloglines = arrayqueryloglines.filter(function(item){
					return item.ReqDmn.toLowerCase().indexOf($j('#filter_reqdmn').val().replace('!','').toLowerCase()) == -1;
				});
			}
			else{
				arrayqueryloglines = arrayqueryloglines.filter(function(item){
					return item.ReqDmn.toLowerCase().indexOf($j('#filter_reqdmn').val().toLowerCase()) != -1;
				});
			}
		}

		if( $j('#filter_srcip').val() != '' ){
			if($j('#filter_srcip').val().startsWith('!')){
				arrayqueryloglines = arrayqueryloglines.filter(function(item){
					return item.SrcIP.indexOf($j('#filter_srcip').val().replace('!','')) == -1;
				});
			}
			else{
				arrayqueryloglines = arrayqueryloglines.filter(function(item){
					return item.SrcIP.indexOf($j('#filter_srcip').val()) != -1;
				});
			}
		}

		if( $j('#filter_qrytype option:selected').val() != 0 ){
			arrayqueryloglines = arrayqueryloglines.filter(function(item){
				return item.QryType == $j('#filter_qrytype option:selected').text();
			});
		}

		if( $j('#filter_result option:selected').val() != 0 ){
			arrayqueryloglines = arrayqueryloglines.filter(function(item){
				return item.Result == $j('#filter_result option:selected').text();
			});
		}

	}
	SortTable(sortname+' '+sortdir.replace('desc','↑').replace('asc','↓').trim());
}

function SortTable(sorttext){
	sortname = sorttext.replace('↑','').replace('↓','').trim();
	var sortfield = sortname;
	switch(sortname){
		case 'Time':
			sortfield='Time';
		break;
		case 'Domain':
			sortfield='ReqDmn';
		break;
		case 'Client':
			sortfield='SrcIP';
		break;
		case 'Type':
			sortfield='QryType';
		break;
		case 'Result':
			sortfield='Result';
		break;
	}

	if(sorttext.indexOf('↓') == -1 && sorttext.indexOf('↑') == -1){
		eval('arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a.'+sortfield+' > b.'+sortfield+') ? 1 : ((b.'+sortfield+' > a.'+sortfield+') ? -1 : 0)); ');
		sortdir = 'asc';
	}
	else if(sorttext.indexOf('↓') != -1){
		eval('arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a.'+sortfield+' > b.'+sortfield+') ? 1 : ((b.'+sortfield+' > a.'+sortfield+') ? -1 : 0)); ');
		sortdir = 'asc';
	}
	else{
		eval('arrayqueryloglines = arrayqueryloglines.sort((a,b) => (a.'+sortfield+' < b.'+sortfield+') ? 1 : ((b.'+sortfield+' < a.'+sortfield+') ? -1 : 0)); ');
		sortdir = 'desc';
	}

	$j('#sortTableContainer').empty();
	$j('#sortTableContainer').append(BuildQueryLogTableHtml());

	$j('.sortable').each(function(index,element){
		if(element.innerHTML == sortname){
			if(sortdir == 'asc'){
				element.innerHTML = sortname+' ↑';
			}
			else{
				element.innerHTML = sortname+' ↓';
			}
		}
	});
}

function Assign_EventHandlers(){
	$j('.collapsible-jquery').off('click').on('click',function(){
		$j(this).siblings().toggle('fast',function(){
			if($j(this).css('display') == 'none'){
				SetCookie($j(this).siblings()[0].id,'collapsed');
			}
			else{
				SetCookie($j(this).siblings()[0].id,'expanded');
			}
		})
	});

	$j('.collapsible-jquery').each(function(index,element){
		if(GetCookie($j(this)[0].id,'string') == 'collapsed'){
			$j(this).siblings().toggle(false);
		}
		else{
			$j(this).siblings().toggle(true);
		}
	});

	let timeoutreqdmn = null;
	let timeoutsrcip = null;

	$j('#filter_reqdmn').off('keyup touchend').on('keyup touchend',function (e){
		clearTimeout(timeoutreqdmn);
		timeoutreqdmn = setTimeout(function(){
			FilterQueryLog();
		},1000);
	});

	$j('#filter_srcip').off('keyup touchend').on('keyup touchend',function (e){
		clearTimeout(timeoutsrcip);
		timeoutsrcip = setTimeout(function(){
			FilterQueryLog();
		},1000);
	});
	$j('#auto_refresh').off('click').on('click',function(){ToggleRefresh();});
}

function ToggleRefresh(){
	$j('#auto_refresh').prop('checked',function(i,v){ if(v){get_querylog_file();} else{clearTimeout(tout);} });
}
