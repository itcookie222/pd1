 function ShowLoadingOnControl(ControlID, Type) {
	ControlID = replaceAll(ControlID, '#', '');
	var html = '<div class="text-center PreLoad" id="PreLoad-' + replaceAll(ControlID, '#', '') + '"> <p class="text-center"><i class="ti-reload rotate-refresh"></i> Loading...</p></div>';

	if (Type == "Table") {
		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(html)
	}
	else if (ControlID.indexOf("PreLoad") < 0) {
		$('#PreLoad-' + ControlID).html(html);
	}
	$('#PreLoad').html(html);
}
function HideLoadingOnControl(ControlID, Type) {
	if (Type == "Table")
		$('#Table-' + ControlID + ' tbody').html('');
	else {
		$('#PreLoad-' + ControlID).html('');
	}
	$('#PreLoad').html('');
}
function LoadCardListsFromAjax(FormCode, FormID, ControlID, isReload, OnClickAction, CardType, ActionCustom, LayoutConfig) {
	if (CardType === undefined) CardType = 'CarlistUL';
	ShowLoadingOnControl(ControlID, CardType);

	var form = $('#' + FormID);
	var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
	var formData = form.serialize();
	disabledListControl.attr('disabled', 'disabled');
	formData += '&Action=' + ActionCustom;
	console.log(formData);
	formData += "&ReportCode=" + FormCode;
	$.ajax({
		type: 'POST',
		url: '/Categories/SReports/GetDataReports',
		data: formData,
		success: function (response) {
			CheckResponse(response);
			if (CardType === 'GeneralList') {
				RenderGeneralListFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'GeneralListStatus') {
				RenderGeneralListFromJsonTableStatus(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ProjectTask') {
				RenderProjectTaskFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ProgressList') {
				RenderProgressListFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ServicesCatalog') {
				RenderServicesCatalogFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'GeneralListCheck') {
				RenderGeneralListCheckFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ReportProcessKanban') {
				RenderProcessKanbanFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ReportKanban') {
				RenderKanbanFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'calendar') {
				RenderCalendarFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'calendarTimeLine') {
				RenderCalendarFromJsonTable(FormCode, response, ControlID, OnClickAction, CardType);
			}
			else if (CardType === 'notification') {
				RenderNotificationFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'timeline') {
				RenderTimelineFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'feednews') {
				RenderFeedNewsFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'CardCheck') {
				RenderCardCheckFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'CardDnD') {
				RenderCardDnDFromJsonTable(FormCode, response, ControlID, OnClickAction);
			}
			else if (CardType === 'ReportCardView') {
				RenderCardListFromJsonTable(FormCode, response, ControlID, OnClickAction, LayoutConfig);
			}
			else {
				RenderCardListFromJsonTable(FormCode, response, ControlID, OnClickAction, LayoutConfig);
			}
			HideLoadingOnControl(ControlID);

		},
		error: function (jqXHR, textStatus, errorThrown) {
			console.log(errorThrown);
			HideLoadingOnControl(ControlID);
		}
	});
}

function RenderCalendarFromJsonTable(FormCode, jsData, ControlID, OnClickAction, calendarType) {

	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		if (typeof jsData === 'string' && jsData.length) {
			arrData = JSON.parse(jsData);
			console.log(arrData);
			SetControlsConfig('list-' + ControlID, arrData);
		}
		else if (typeof jsData === 'string' && jsData.length == 0) {
			return;
		}
		else {
			arrData = jsData;
			SetControlsConfig('list-' + ControlID, jsData);
		}

		console.log(arrData);
		var events_array = [];
		var events_resources = [];

		$.map(arrData, function (item, i) {

			const index =
				events_resources.findIndex(
					x => (x.id === item.GroupID)
				);
			if (index < 0 && item.GroupItem) {
				var newitem = {
					id: item.GroupID,
					GroupName: item.GroupName,
					title: item.GroupItem
				};
				events_resources.push(newitem);
			}

			var SttColor = GetBackgroundColor(item.Color);
			events_array.push({
				id: item.ID,
				type: item.Type,
				val: item.Val,
				resourceId: item.GroupID,
				title: (item.Name !== "" ? item.Name : item.ID),
				popup: {
					title: item.Title,
					desc: item.Description,
				},
				start: item.DateFrom,
				end: item.DateTo,
				borderColor: SttColor,
				backgroundColor: SttColor,
				//textColor: '#fff',
				url: item.Url,
				allDay: false,
				DataItem: item,

				GroupItem: item.GroupItem,
				GroupName: item.GroupName,
				////Cân nhắc sử dụng
				IsCheck: item.IsCheck,
				IsCheckColor: item.IsCheckColor,
				TotalCost: (item.TotalCost == undefined ? 0 : item.TotalCost)

			});

		});
		if (calendarType == "calendarTimeLine") {
			$("#TotalRow-" + ControlID).text(events_resources.length);
			renderCalendarTimeline(ControlID, events_resources, events_array);
		}
		else
			if ($('#calendar').length) {
				console.log('render clendar');
				$('#calendar').fullCalendar('removeEvents');
				$('#calendar').fullCalendar('addEventSource', events_array);
				$("#TotalRow-" + ControlID).text(events_array.length);
				// $("#calendar").fullCalendar('rerenderEvents');
			}
	}
}
function renderCalendarTimeline(ControlID, events_resources, events_array) {

	if (typeof calendar != "undefined") {
		calendar.destroy();
		document.getElementById("calendar").innerHTML = "";
	}

	var calendarEl = document.getElementById('calendar');

	calendar = new FullCalendar.Calendar(calendarEl, {
		schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
		plugins: ['interaction', 'dayGrid', 'timeGrid', 'resourceTimeline'],
		editable: true,
		height: 450,
		aspectRatio: 1.8,
		scrollTime: '00:00',

		header: {
			right: 'prev,next,today',
			center: 'title',
			left: ''
		},
		defaultView: 'resourceTimelineMonth',
		resourceAreaWidth: '30%',
		displayEventTime: false,
		nextDayThreshold: '00:00:00',
		resourceGroupField: 'GroupName',
		resourceColumns: [
			//{
			//	group: true,
			//	labelText: 'Building',
			//	field: 'building'
			//},
			{
				labelText: 'Items'
			}
			//, 
			//{
			//	labelText: '',
			//	field: 'title'
			//}
		],
		resources: events_resources,
		events: events_array,
		eventRender: function (info) {
			console.log('calendar eventRender');
			var infoData = info.event?.extendedProps;
			if (info.event?.extendedProps.type?.toLowerCase() == "checkbox") {
				//var hour = moment(this.start._d).hour();
				var htmlC = '';
				htmlC += '<div class="border-checkbox-section">';
				htmlC += '<div class="checkbox-fade fade-in-success "> ';
				htmlC += '<label for="' + info.event.id + '">';
				htmlC += '<input class="cb-checkinout" type="checkbox" name="' + info.event.id + '" id="' + info.event.id + '" value="' + (infoData.val ? infoData.val : "0") + '" ' + (infoData.val == 1 ? "checked" : "") + '>';
				htmlC += '<span class="cr"> ';
				htmlC += '   <i class="cr-icon fa fa-check txt-success"></i>	';
				htmlC += '</span> ';
				//htmlC += '<span>@OptionConfig[0]</span>';
				htmlC += '</label>';
				htmlC += '</div>';
				htmlC += '</div>';

				$(info.el).find(".fc-title").html(htmlC);
			}
		},
		//eventClick: function (info) {
		//	console.log('calendar eventClick');
		//	if (info.event && info.event.url) {
		//		info.jsEvent.preventDefault();

		//		window.open(info.event.url, "_blank");
		//	}
		//	else {
		//		info.jsEvent.preventDefault();
		//		OpenModalCalendar(ControlID, info.event.url, false, null, null);
		//	}
		//},
		eventMouseEnter: function (info) {
			var tis = info.el;
			var popup = info.event.extendedProps.popup;
			var tooltip = '<div class="tooltipevent" style="top:' + ($(tis).offset().top - 5) + 'px;left:' + ($(tis).offset().left + ($(tis).width()) / 2) + 'px"><div>' + popup.title + '</div><div>' + popup.desc + '</div></div>';
			var $tooltip = $(tooltip).appendTo('body');

			//If you want to move the tooltip on mouse movement then you can uncomment it
			//$(tis).mouseover(function(e) {
			//    $(tis).css('z-index', 10000);
			//    $tooltip.fadeIn('500');
			//    $tooltip.fadeTo('10', 1.9);
			//}).mousemove(function(e) {
			//    $tooltip.css('top', e.pageY + 10);
			//    $tooltip.css('left', e.pageX + 20);
			//});
		},
		eventMouseLeave: function (info) {
			console.log('eventMouseLeave');
			$(info.el).css('z-index', 8);
			$('.tooltipevent').remove();
		},


	});


	calendar.render();
	$(".cb-checkinout").change(function (item, ele) {
		//$('#@ControlID').val($('#@(control.Key)')[0].checked);
		var checked = item.target.checked;
		TimekeepingCheckin(item.currentTarget.id, (checked == 1 ? "checkin" : "uncheck"), checked);
	});

}

function GetBackgroundColor(Color = "") {
	var SttColor = "";
	if (Color?.indexOf("primary") >= 0) SttColor = "#007bff";
	else if (Color?.indexOf("secondary") >= 0) SttColor = "#868e96";
	else if (Color?.indexOf("success") >= 0) SttColor = "#28a745";
	else if (Color?.indexOf("danger") >= 0) SttColor = "#dc3545";
	else if (Color?.indexOf("warning") >= 0) SttColor = "#ffc107";
	else if (Color?.indexOf("info") >= 0) SttColor = "#17a2b8";
	else if (Color?.indexOf("light") >= 0) SttColor = "#f8f9fa";
	else if (Color?.indexOf("dark") >= 0) SttColor = "#343a40";
	else if (Color?.indexOf("muted") >= 0) SttColor = "#e9ecef";
	else if (Color?.indexOf("white") >= 0) SttColor = "#fff";
	else if (Color === null || Color === undefined || Color == "") SttColor = "#fff";
	else SttColor = Color;
	return SttColor;
}
function OpenModalCalendar(ControlID, id, opentype, start, end, title, ObjectName, ObjectValue) {
	$('#modalChangeCalendar').modal('show');
	SetControlsConfig('OpenModalCalendarType', opentype);
	$("#ID").val(id);

	if (opentype === 'new') {
		$("#IsLock").val("0");
		$("#IsLockDisplay").val("");
		id = moment.utc(start).format('YYMMDD') + Math.floor((Math.random() * 1000000) + 1);
		$("#ID").val(id);
		$('#modalChangeCalendar').find('#ID').val(id);
		$('#btnCancelCalendar').addClass('d-none');

		$('#lbModalCalendar').text("Add New Calendar");
		$('#btnUpdateCalendar').html('<i class="fa fa-calendar-plus-o"></i> Add New Calendar');
		var checkDate = moment(start, 'YYYY-MM-DD').format('YYYY-MM-DD');
		var jsDatalists = GetControlsConfig('list-' + ControlID);
		const cindex =
			jsDatalists.findIndex(
				x => moment(x.DateStringBegin, 'YYYY-MM-DD').format('YYYY-MM-DD') === checkDate
			);
		if (cindex >= 0) {
			var DateFrom = moment.utc(start).format('YYYY-MM-DD') + ' 13:00';
			var DateTo = moment.utc(start).format('YYYY-MM-DD') + ' 17:00';
		}
		else {
			DateFrom = moment.utc(start).format('YYYY-MM-DD') + ' 8:00';
			DateTo = moment.utc(start).format('YYYY-MM-DD') + ' 11:00';
		}

		$('#modalChangeCalendar').find('#DateStringBegin').val(DateFrom);
		$('#modalChangeCalendar').find('#DateStringEnd').val(DateTo);

		if (title !== undefined) {
			$('#modalChangeCalendar').find('#Name').val(title);
		}
		if (ObjectValue !== undefined) {
			$('#modalChangeCalendar').find('#' + ObjectName).val(ObjectValue).trigger('change');
		}

		var arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));
		var ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));
		var ProcessStep = "ADD";
		$.map(arrControl, function (row) {
			var isDisable = "1";
			const idIdx =
				ProcessConfig.findIndex(
					x => x.key === "ItemName" && x.val === row.Key && x.parentId === ProcessStep
				);
			if (idIdx >= 0) {
				var idValue = ProcessConfig[idIdx].id;

				const idAdd =
					ProcessConfig.findIndex(
						x => x.key === "IsAdd" && x.id === idValue && x.parentId === ProcessStep
					);
				if (idAdd >= 0) {
					isDisable = ProcessConfig[idAdd].val === "1" ? "0" : "1";
				}
			}
			if (row.Key !== "ID" && (row.Type === 'DataReportEdit' || row.Disable === "1" || isDisable === "1")) {
				var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
				SetDataToObject(row.Type, row.Pattern, row.Key, null, row.OptionConfig, valueDisplay);
			}
			SetDisableControl(row.Type, row.Pattern, row.Key, row.Disable, isDisable);

		});
		$("#Action").val('ADD');

	}
	else if (opentype === "edit" || opentype === "movedate") {
		$("#ID").val(id);
		$('#modalChangeCalendar').find('#ID').val(id);
		$('#lbModalCalendar').text("Update Calendar");


		$('#btnUpdateCalendar').html('<i class="fa fa-calendar-check-o"></i> Update Calendar');
		jsDatalists = GetControlsConfig('list-' + ControlID);
		const cindex =
			jsDatalists.findIndex(
				x => x.id === id || x.ID === id
			);
		var itemList = jsDatalists[cindex];
		if (itemList.IsLock !== undefined) {
			$("#IsLock").val(itemList.IsLock);
			$("#IsLockDisplay").val(itemList.IsLockDisplay);
		}

		arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));
		ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));
		ProcessStep = itemList.ProcessStep === null || itemList.ProcessStep === undefined ? "EDIT" : itemList.ProcessStep;
		$("#ProcessStep").val(ProcessStep);
		if (itemList.IsDeletable === "1") {
			$('#btnCancelCalendar').removeClass('d-none');
		}
		else {
			$('#btnCancelCalendar').addClass('d-none');
		}

		$.map(arrControl, function (row) {
			$.map(itemList, function (itemVal, itemName) {
				if (itemName === row.Key) {
					var valueDisplay = itemList[row.Key + "Display"] != undefined ? itemList[row.Key + "Display"] : "";
					SetDataToObject(row.Type, row.Pattern, row.Key, itemVal, row.OptionConfig, valueDisplay);
					var isDisable = "1";
					const idIdx =
						ProcessConfig.findIndex(
							x => x.key === "ItemName" && x.val === row.Key && x.parentId === ProcessStep
						);
					if (idIdx >= 0) {
						var idValue = ProcessConfig[idIdx].id;

						const idEdit =
							ProcessConfig.findIndex(
								x => x.key === "IsEdit" && x.id === idValue && x.parentId === ProcessStep
							);
						if (idEdit >= 0) {
							isDisable = ProcessConfig[idEdit].val === "1" ? "0" : "1";
						}
					}
					SetDisableControl(row.Type, row.Pattern, row.Key, row.Disable, isDisable);
				}
			});
		});
		if (opentype === "movedate") {
			DateFrom = moment.utc(start).format('YYYY-MM-DD') + ' 8:00';
			DateTo = moment.utc(end).format('YYYY-MM-DD') + ' 11:00';
			$('#modalChangeCalendar').find('#DateStringBegin').val(DateFrom);
			$('#modalChangeCalendar').find('#DateStringEnd').val(DateTo);

		}
		$("#Action").val('EDIT');

	}
	///save event id
	console.log(id);
	CheckValidateButtonUpdateCalendar(true);
}

function OpenModalForm(ControlID, id, StepAction, StepTo, RowID) {
	//StepAction in add, edit
	$('#modal-' + ControlID).modal('show');

	$('#RowID').val(RowID);

	$("#ID").val(id);
	$('#modal-' + ControlID).find('#ID').val(id);
	if (id === undefined || id === null || id == "0" || StepAction == "ADD") {
		id = "0";
		$("#IsLock").val("0");
		$("#IsLockDisplay").val("");
		$("#ID").val("0");
		id = "0";
		$('#modal-' + ControlID).find('#ID').val(id);
		//$('#btnCancelModalForm').addClass('d-none');
		$('#lbModalForm').text("Add New");
		$('#btnUpdateModalForm').addClass("d-none");
		$('#btnAddModalForm').removeClass("d-none");

		var jsDatalists = GetControlsConfig('list-' + ControlID);

		var arrControl = JSON.parse(GetControlsConfig('ModalFormList' + ControlID));
		var ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));

		var ProcessStep = "ADD";
		$.map(arrControl, function (row) {
			var isDisable = "1";
			const idIdx =
				ProcessConfig.findIndex(
					x => x.key === "ItemName" && x.val === row.Key && x.parentId === ProcessStep
				);
			if (idIdx >= 0) {
				var idValue = ProcessConfig[idIdx].id;

				const idAdd =
					ProcessConfig.findIndex(
						x => x.key === "IsAdd" && x.id === idValue && x.parentId === ProcessStep
					);
				if (idAdd >= 0) {
					isDisable = ProcessConfig[idAdd].val === "1" ? "0" : "1";
				}
			}
			var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
			SetDataToObject(row.Type, row.Pattern, row.Key, null, row.OptionConfig, valueDisplay);

			SetDisableControl(row.Type, row.Pattern, row.Key, row.Disable, isDisable);

		});
		$("#Action").val('ADD');
		$('#modal-' + ControlID).find('#Action').val('ADD');
		$('#CateAddUpdateForm').find('#Action').val('ADD');
	}
	else if (StepAction == "VIEW") {
		$("#ID").val(id);
		$('#modal-' + ControlID).find('#ID').val(id);
		$("#Action").val('VIEW');
		$('#modal-' + ControlID).find('#Action').val('VIEW');
		$('#CateAddUpdateForm').find('#Action').val('VIEW');
		$('#lbModalForm').text("Update");
		//$('#btnUpdateModalForm').html('<i class="fa fa-check-square-o"></i> Update');
		$('#btnUpdateModalForm').addClass("d-none");
		$('#btnAddModalForm').addClass("d-none");
		$('#btnCancelModalForm').addClass("d-none");
		//arrControl = JSON.parse(GetControlsConfig('ModalFormList' + ControlID));
		ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));
		var FormCode = $("#FormCode").val();
		var SSID = $('#FSessionID').val();
		var jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&ID=" + id + "&SourceType=ModalForm";
		console.log(jsDataOnclick);
		$.ajax({
			type: "POST",
			url: "/Categories/CateAddupdate/GetDataByID",
			data: jsDataOnclick,
			async: false,
			success: function (response) {
				CheckResponse(response);
				LoadDataToForm(response, ProcessConfig, StepAction, StepTo);
			},
			error: function (response) {
				console.log(response);
			}
		});
	}
	else {
		$("#ID").val(id);
		$('#modal-' + ControlID).find('#ID').val(id);
		$("#Action").val('EDIT');
		$('#modal-' + ControlID).find('#Action').val('EDIT');
		$('#CateAddUpdateForm').find('#Action').val('EDIT');
		$('#lbModalForm').text("Update");
		//$('#btnUpdateModalForm').html('<i class="fa fa-check-square-o"></i> Update');
		$('#btnUpdateModalForm').removeClass("d-none");
		$('#btnAddModalForm').addClass("d-none");
		//arrControl = JSON.parse(GetControlsConfig('ModalFormList' + ControlID));
		ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));
		ProcessConfigAction = JSON.parse(GetControlsConfig('ProcessConfig-Action'));
		var FormCode = $("#FormCode").val();
		var SSID = $('#FSessionID').val();
		var jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&ID=" + id + "&SourceType=ModalForm";
		console.log(jsDataOnclick);
		$.ajax({
			type: "POST",
			url: "/Categories/CateAddupdate/GetDataByID",
			data: jsDataOnclick,
			async: false,
			success: function (response) {
				CheckResponse(response);
				LoadDataToForm(response, ProcessConfig, StepAction, StepTo, ProcessConfigAction);
			},
			error: function (response) {
				console.log(response);
			}
		});
	}
	///save event id
	console.log(id);
	CheckValidateButtonUpdateCalendar(true);
	if (StepTo != undefined && StepTo.length) {
		$('.ActionListButton').addClass("d-none");
		$('#ActionListButton').find("button").each(function () {
			var txt = $(this).attr("onclick");
			if (txt.indexOf(StepTo) > 0) {
				$(this).removeClass("d-none");
			}
			else $(this).addClass("d-none");
		});
	}

	var ModalComment = GetControlsConfig("ModalComment");
	if (ModalComment != undefined && ModalComment.length) {
		getListMessage(0, 'OpenModalForm');
	}
	$('#modal-' + ControlID).modal('show');
}

function OpenModalProcess(ControlID, id, ViewCode, opentype, RowID) {
	$('#modal-' + ControlID).modal('show');
	if (opentype == undefined) opentype = "ModalProcess";

	$("#ID").val(id);
	$('#RowID').val(RowID);
	$('#modal-' + ControlID).find('#ID').val(id);
	if (id === undefined || id === null) {//luu y khong co id = 0
		$("#IsLock").val("0");
		$("#IsLockDisplay").val("");
		id = moment.utc().format('YYMMDD') + Math.floor((Math.random() * 1000000) + 1);
		$("#ID").val(id);
		$('#modal-' + ControlID).find('#ID').val(id);
		$('#lbModalForm').text("Add Process");

		$('#btnCancelModalForm').addClass('d-none');
		$('#btnAddModalForm').removeClass('d-none');
		$('#btnUpdateModalForm').addClass('d-none');
		$('#btnAppModalApproval').addClass('d-none');
		$('#btnRejModalReject').addClass('d-none');

		var jsDatalists = GetControlsConfig('list-' + ControlID);

		var arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));
		var ProcessConfig = JSON.parse(GetControlsConfig('ProcessConfig-Control'));

		var ProcessStep = "Begin";
		$.map(arrControl, function (row) {
			var isDisable = "1";
			const idIdx =
				ProcessConfig.findIndex(
					x => x.key === "ItemName" && x.val === row.Key && x.parentId === ProcessStep
				);
			if (idIdx >= 0) {
				var idValue = ProcessConfig[idIdx].id;

				const idAdd =
					ProcessConfig.findIndex(
						x => x.key === "IsAdd" && x.id === idValue && x.parentId === ProcessStep
					);
				if (idAdd >= 0) {
					isDisable = ProcessConfig[idAdd].val === "1" ? "0" : "1";
				}
			}
			var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
			SetDataToObject(row.Type, row.Pattern, row.Key, null, row.OptionConfig, valueDisplay);

			SetDisableControl(row.Type, row.Pattern, row.Key, row.Disable, isDisable);

		});
		$("#Action").val('101');
		$('#modal-' + ControlID).find('#Action').val('101');
	}
	else {
		$("#ID").val(id);
		$('#modal-' + ControlID).find('#ID').val(id);
		$('#lbModalModalForm').text("Approval Process");
		//$("#Action").val('EDIT');
		//$('#ModalForm').find('#Action').val('EDIT');

		arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));
		ProcessConfigControl = JSON.parse(GetControlsConfig('ProcessConfig-Control'));
		ProcessConfigAction = JSON.parse(GetControlsConfig('ProcessConfig-Action'));
		var FormCode = $("#FormCode").val();
		var SSID = $('#FSessionID').val();
		var jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&ID=" + id + "&ViewCode=" + ViewCode + "&SourceType=ModalForm";
		console.log(jsDataOnclick);
		$.ajax({
			type: "POST",
			url: "/Categories/CateAddupdate/GetDataByID",
			data: jsDataOnclick,
			async: false,
			success: function (response) {
				CheckResponse(response);
				LoadDataToForm(response, ProcessConfigControl, opentype, undefined, ProcessConfigAction);
			},
			error: function (response) {
				console.log(response);
			}
		});
	}
	///save event id
	console.log(id);
	//CheckValidateButtonUpdateCalendar(true);
	var ModalComment = GetControlsConfig("ModalComment");
	if (ModalComment != undefined && ModalComment.length) {
		getListMessage(0, 'OpenModalProcess');
	}
}

function CheckValidateButtonUpdateModalForm(IsRemoveButton) {
	var DayForEdit = GetControlsConfig("DayForEdit");
	var DateStringCheck = $('#modal-' + ControlID).find('#DateStringBegin').val();
	var DateCheck = moment(DateStringCheck, 'YYYY-MM-DD').add(Number(DayForEdit), 'days');
	var now = moment();
	var IsLock = $("#IsLock").val();

	if (DateCheck >= now && IsLock !== "1") {
		$('#btnUpdateModalForm').removeClass("d-none");
		$('#modalUpdateModalFormNote').text("");
		return true;
	}
	else {
		if (IsRemoveButton) $('#btnUpdateModalForm').addClass("d-none");
		if (IsRemoveButton) $('#btnCancelModalForm').addClass("d-none");
		if (DateCheck < now)
			$('#modalUpdateModalFormNote').text("Note: Not edit available after " + DayForEdit + " days");

		if (IsLock !== "0") {
			var isLockDisplay = $("#IsLockDisplay").val();
			$('#modalUpdateModalFormNote').text("Note: This activity is locked" + isLockDisplay);
		}
		return false;
	}
}

function CheckValidateButtonUpdateCalendar(IsRemoveButton) {
	var DayForEdit = GetControlsConfig("DayForEdit");
	var DateStringCheck = $('#modalChangeCalendar').find('#DateStringBegin').val();
	var DateCheck = moment(DateStringCheck, 'YYYY-MM-DD').add(Number(DayForEdit), 'days');
	var now = moment();
	var IsLock = $("#IsLock").val();

	if (DateCheck >= now && IsLock !== "1") {
		$('#btnUpdateCalendar').removeClass("d-none");
		$('#modalUpdateClendarNote').text("");
		return true;
	}
	else {
		if (IsRemoveButton) $('#btnUpdateCalendar').addClass("d-none");
		if (IsRemoveButton) $('#btnCancelCalendar').addClass("d-none");
		if (DateCheck < now) {
			$('#modalUpdateClendarNote').text("Note: Not edit available after " + DayForEdit + " days");
			console.log("Note: Not edit available");
		}
		if (IsLock !== "0") {
			var IsLockDisplay = $("#IsLockDisplay").val();
			$('#modalUpdateClendarNote').text("Note: This activity is locked(" + IsLockDisplay + ")");
			console.log("Note: This activity is locked" + IsLockDisplay);
		}
		return false;
	}
}

function CloseModalCalendar(ControlID) {
	var OpenType = GetControlsConfig('OpenModalCalendarType');

	var id = $('#modalChangeCalendar').find('#ID').val();

	var jsDatalists = GetControlsConfig('list-' + ControlID);
	const cindex =
		jsDatalists.findIndex(
			x => String(x.id) == id || String(x.ID) == id
		);
	var itemList = jsDatalists[cindex];
	var arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));
	$.map(arrControl, function (row) {
		$.map(itemList, function (itemVal, itemName) {
			if (itemName === row.Key) {
				var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
				SetDataToObject(row.Type, row.Pattern, itemName, itemVal, row.OptionConfig, valueDisplay);
			}
		});
	});

	var start = moment($('#DateStringBegin').val(), 'YYYY-MM-DD HH:mm').toDate();
	var end = moment($('#DateStringEnd').val(), 'YYYY-MM-DD HH:mm').toDate();
	if (end < start) {
		end = start;
	}
	var title = $('#modalChangeCalendar').find('#Name').val();
	var backgroundColor = $('#modalChangeCalendar').find('button[id$=Status]').css("background-color");
	if (OpenType == "new") {
		$("#calendar").fullCalendar('removeEvents', id);
		$("#calendar").fullCalendar('removeEvents', function (eventObject) {
			if (eventObject.id == undefined)
				return true;
			return false;
		});

	}
	else
		AddUpdateCalenderEvent(ControlID, id, start, end, title, '', backgroundColor);
	$('#modalChangeCalendar').modal('hide');
}

function CancelCalendar(ControlID) {
	if (!confirm('Are you sure delete this id...')) {
		//$('#modalChangeCalendar').modal('hide');
		return true;
	}
	var id = $('#modalChangeCalendar').find('#ID').val();
	$("#Action").val("DEL");
	var retVal = CateAddUpdateFunction("DEL", '', '', '', 'ModalForm');
	console.log('retVal');
	console.log(retVal);
	if (retVal !== false) {
		$("#calendar").fullCalendar('removeEvents', id);
		$("#calendar").fullCalendar('removeEvents', function (eventObject) {
			if (eventObject.id == undefined)
				return true;
			return false;
		});
		$('#modalChangeCalendar').modal('hide');
	}
}

function CancelModalForm(ControlID) {
	if (!confirm('Are you sure delete this id...')) {
		//$('#modalChangeCalendar').modal('hide');
		return true;
	}
	var id = $('#modal-' + ControlID).find('#ID').val();
	$("#Action").val("DEL");
	$('#modal-' + ControlID).find('#Action').val("DEL");
	var retVal = CateAddUpdateFunction("DEL", '', '', '', 'ModalForm');
	console.log('retVal');
	console.log(retVal);
	if (retVal !== false) {
		$('#modal-' + ControlID).modal('hide');
		SubmitFunction();
	}

}
function SaveModalFormSetting(ControlID, ActionCode, NextStep, ReloadByRowID) {
	//if (CheckValidateButtonUpdateModalForm(false) === false) {
	//    //$('#ModalForm').modal('hide');
	//    console.log("not valid");
	//    return;
	//}
	var id = $('#modal-' + ControlID).find('#ID').val();
	if (id === "" || id === undefined || id === null || String(id) === "0") {
		id = "0";
	}
	//var Action = $('#ModalForm').find('#Action').val();
	//console.log(Action);
	ActionCode = String(ActionCode);
	if (ActionCode.length) {
		var retVal = CateAddUpdateFunction(ActionCode, NextStep, '', '', 'ModalForm');
		console.log('retVal');
		console.log(retVal);
		if (retVal !== false) {
			if (ActionCode !== 100) {
				$('#modal-' + ControlID).modal('hide');
				SubmitFunction(null, ReloadByRowID);
			}
			else if (ActionCode == 100) {
				OpenModalProcess();
			}
		}
	}
}

function SaveCalendarSetting(ControlID) {
	if (CheckValidateButtonUpdateCalendar(false) === false) {
		$('#modalChangeCalendar').modal('hide');
		return;
	}
	var id = $('#modalChangeCalendar').find('#ID').val();
	if (id === "" || id === undefined || id === null || String(id) === "0") {
		$('#modalChangeCalendar').modal('hide');
		return;
	}

	var start = moment($('#DateStringBegin').val(), 'YYYY-MM-DD HH:mm').toDate();
	var end = moment($('#DateStringEnd').val(), 'YYYY-MM-DD HH:mm').toDate();
	if (end < start) {
		end = start;
	}
	console.log("ID Save");
	console.log(id);

	var title = $('#modalChangeCalendar').find('#Name').val();
	var TotalCost = $('#modalChangeCalendar').find('#TotalCost').val();
	var icon = $('#modalChangeCalendar').find('button[id$=Status]').find('i')[0].className;
	var titleIcon = $('#modalChangeCalendar').find('button[id$=Status]').find('span')[0].textContent;
	var backgroundColor = $('#modalChangeCalendar').find('button[id$=Status]').css("background-color");
	var CalendarStatus = $('#modalChangeCalendar').find('button[id$=Status]')[0].innerHTML;
	var Action = $("#Action").val();
	var IsLock = $("#IsLock").val();
	var ProcessStep = $("#ProcessStep").val();


	console.log(Action);
	if (Action.length) {
		var retVal = CateAddUpdateFunction(Action, '', '', '', 'ModalForm');
		console.log('retVal');
		console.log(retVal);
		if (retVal !== false) {
			AddUpdateCalenderEvent(ControlID, id, start, end, title, '', backgroundColor, TotalCost, IsLock);
			AddUpdateCalendarData(ControlID, id, start, end, title, '', backgroundColor, CalendarStatus, icon, titleIcon, TotalCost, ProcessStep);
			$('#modalChangeCalendar').modal('hide');
		}
	}
}


function AddUpdateCalendarData(ControlID, id, start, end, title, url, color, CalendarStatus, icon, titleIcon, TotalCost, ProcessStep) {
	id = $('#modalChangeCalendar').find('#ID').val();
	var jsDatalists = GetControlsConfig('list-' + ControlID);
	const cindex =
		jsDatalists.findIndex(
			x => String(x.id) == id || String(x.ID) == id
		);
	var item = {};
	if (cindex >= 0)
		itemList = jsDatalists[cindex];

	item["ID"] = Number(id);
	item["Color"] = color;
	item["Icon"] = icon;
	item["TotalCost"] = TotalCost;
	item["ProcessStep"] = ProcessStep;

	var arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ControlID));

	var disabledListControl = $('#modalChangeCalendar').find(':input:disabled').removeAttr('disabled');
	var arrValues = $('#modalChangeCalendar').find('input,select').serializeArray();
	disabledListControl.attr('disabled', 'disabled');

	$.map(arrControl, function (control) {
		$.map(arrValues, function (row) {
			if (row.name === control.Key) {
				if (control.Pattern === 'DateTimeFrom' || control.Pattern === 'DateTimeTo') {
					item[row.name] = moment(row.value, 'YYYY-MM-DD HH:mm').toDate();
				}
				else if (control.Pattern === 'DatePick') {
					item[row.name] = moment(row.value, 'YYYY-MM-DD').toDate();
				}
				else {
					item[row.name] = row.value;
				}
			}
		});

	});


	if (cindex >= 0) {
		jsDatalists[cindex] = item;
	}
	else {
		jsDatalists.push(item);
	}
	SetControlsConfig('list-' + ControlID, jsDatalists);
	RenderCalendarFromJsonTable(null, jsDatalists, ControlID, null);
}

function SumTotalCostCalendar() {
	var totalThisView = 0;
	$('.event-cost').map(function () {
		var countdate = $('#' + this.id).attr("countdate");
		countdate = (countdate == undefined ? 0 : countdate);
		$(this).attr("countdate", countdate + 1);
		if (countdate == "" || countdate == 0) {
			totalThisView += Math.floor(replaceAll(this.textContent, ',', ''));
		}
		else {
			$(this).removeClass("text-danger");
			$(this).addClass("text-primary");
			$(this).text("-");
		}
	});

	if (totalThisView !== 0) {
		$('#totalThisMonth').html('Total:<span class="text-danger">' + FormatNumber(totalThisView) + '</span>');
	}
	else {
		$('#totalThisMonth').html('');
	}
}
function SumCalendarStatus(ControlID) {
	var jsDataListOut = GetControlsConfig('list-' + ControlID);
	if (jsDataListOut == undefined) return;

	var listStatus = [];
	var listCount = [];
	var CountFromID = GetControlsConfig("CountFromID");
	var CountToID = GetControlsConfig("CountToID");

	var date = $("#calendar").fullCalendar('getDate');
	var quater = moment(date).quarter();
	var year = moment(date).year();
	var qqstring = String(year) + "0" + String(quater);
	$("#DateSelect").val(date.format("YYYY-MM-DD"));

	var month_int = date._i[1];

	$.map(jsDataListOut, function (item, key) {
		var dateItem = moment(item.DateStringBegin);
		if (dateItem.month() === month_int) {
			if (item.CardStatus !== undefined && item.CardStatus !== "" && item.Color != "bg-danger") {
				const index =
					listStatus.findIndex(
						x => (x.Title === item.CardStatus)
					);
				if (index >= 0) {
					listStatus[index].Count += 1;
				}
				else {
					var SttColor = GetBackgroundColor(item.Color);
					listStatus.push({
						Icon: item.Icon,
						Title: item.CardStatus,
						Color: SttColor,
						Count: 1,
					});

				}
			}
			if (item[CountFromID] !== undefined && item[CountFromID] !== "" && item.Color != "bg-danger") {
				const index =
					listCount.findIndex(
						x => (x.ID === item[CountFromID])
					);
				if (index >= 0) {
					listCount[index].Count += 1;
				}
				else {
					listCount.push({
						ID: item[CountFromID],
						Name: item["GroupName"],
						Count: 1
					});
				}
			}
		}
	});
	var html = '';
	$.map(listStatus, function (item, key) {

		html += '<div class="col-sm-3">';
		html += '   <div class="card text-white mb-1 widget-visitor-card" style="background: ' + item.Color + ';">';
		html += '       <div class="card-block-small p-0 text-center">';

		html += '           <h3 class= "visible-xs">' + item.Count + '</h3>';
		html += '           <h2 class= "hidden-xs">' + item.Count + '</h2>';
		html += '           <h6 class= "hidden-xs">' + item.Title + '</h6>';
		html += '           <i class="' + item.Icon + '"></i>';
		html += '       </div>';
		html += '   </div>';
		html += '</div>';
	});
	$('#calendar-status').html(html);

	$('.card-dnd-label').each(function () {
		$(this).html('0');
	});

	var totalItem = 0;

	$('.card-dnd-item').each(function () {
		var qqfrom = $(this).attr('qqfrom');
		var qqto = $(this).attr('qqto');
		if (qqstring >= qqfrom && qqstring <= qqto) {
			totalItem++;
			$(this).addClass('dnd-view');
			$(this).attr('dnd-num', Math.floor(totalItem / 10 + 1));
			if (totalItem <= 10) {
				$(this).removeClass('d-none');
				$(this).addClass('d-flex');
			}
		}
		else {
			$(this).removeClass('d-flex');
			$(this).addClass('d-none');
			$(this).removeClass('dnd-view');
		}
	});
	var totalPageDnd = Math.floor(totalItem / 10 + 1);
	$("#pagindnd-totalpage").val(totalPageDnd);
	$("#pagindnd-pagenum").val("1");
	$("#pagindnd-title").text("Page 1 of " + totalPageDnd);
	$.map(listCount, function (item, key) {
		$('#CountTo-' + item.ID).html('');
		$('#CountTo-' + item.ID).html(item.Count);
	});
	getListMessage(0, 'SumCalendarStatus');
}
function DnDNumOnClick(action) {
	console.log(action);
	var pagenum = $("#pagindnd-pagenum").val();
	var totalPage = $("#pagindnd-totalpage").val();
	if (action == "R" && pagenum < totalPage) {
		pagenum++;
	}
	if (action == "L" && pagenum > 1 && pagenum <= totalPage) {
		pagenum--;
	}

	$('.dnd-view').each(function () {
		if ($(this).attr('dnd-num') == pagenum) {
			$(this).removeClass('d-none');
			$(this).addClass('d-flex');
		}
		else {
			$(this).removeClass('d-flex');
			$(this).addClass('d-none');
		}
	});
	$("#pagindnd-pagenum").val(pagenum);
	$("#pagindnd-title").text("Page " + pagenum + " of " + totalPage);

}

function AddUpdateCalenderEvent(ControlID, id, start, end, title, url, backgroundColor, TotalCost) {

	var eventObject = $('#calendar').fullCalendar('clientEvents', id);

	if (eventObject !== undefined && eventObject !== null && eventObject.length > 0 && eventObject[0].id !== 0) {
		event = eventObject[0];
		if (event.DataItem.IsLock == "0") {
			event.title = title;
			event.start = start;
			event.end = end;
			event.Name = title;
			event.TotalCost = TotalCost;
			event.borderColor = "#ffc107";//warning
			//eventObject.url = url;

			//id: item.ID,
			//title: (item.Name !== "" ? item.Name : item.ID),
			//start: item.DateStringBegin,
			//end: item.DateStringEnd,
			//borderColor: SttColor,
			//backgroundColor: SttColor,
			//textColor: '#fff',
			//url: item.Url,
			//allDay: false,
			//IsCheck: item.IsCheck,
			//IsCheckColor: item.IsCheckColor,
			//TotalCost: (item.TotalCost == undefined ? 0 : item.TotalCost),
			//DataItem: item
			$('#calendar').fullCalendar('updateEvent', event);
		}
	}
	else {
		var eventObjectNew = {
			title: title,
			start: start,
			end: end,
			id: id,
			borderColor: "#dc3545",//danger
			backgroundColor: backgroundColor,
			textColor: '#fff',
			url: url,
			allDay: false,
			TotalCost: TotalCost
		};
		$('#calendar').fullCalendar('renderEvent', eventObjectNew, true);
	}
}

function GetNotification(ControlID) {
	$.ajax({
		type: "POST",
		url: "/Categories/ControlsBase/SelectCardListAjax",
		data: "DataSource=NTF.GetNotificationList",
		success: function (response) {
			CheckResponse(response);
			RenderNotificationFromJsonTable(response, ControlID);
		},
		error: function (jqXHR, textStatus, errorThrown) {
			console.log(errorThrown);
		}
	});
}

function RenderNotificationFromJsonTable(jsData, ControlID) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		$.map(arrData, function (item, i) {
			html += '<tr id="ntfr' + i + '" class="wf-border-left-' + item.Color + '">';
			html += '       <td class="p-2 task-des" onclick="window.location.href=\'' + item.Url + '\'">';
			html += '           <div class="task-des-title">' + item.Title;
			html += '               <div class="des-shadow"></div>';
			html += '           </div>';
			html += '           <div class="d-flex">';
			html += '               <div class="mr-2 mt-2">';
			html += '                 <i class="fa fa-user-plus text-secondary mr-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Thời gian kết thúc"></i>' + item.Requester;
			html += '               </div>';
			html += '               <div class="mr-2 mt-2">';
			html += '                 <i class="fa fa-clock-o text-danger mr-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Thời gian kết thúc"></i>' + item.FromLastUpdate;
			html += '               </div>';
			html += '          </div>';
			html += '       </td>';
			//html += '       <td class="p-0">';
			//html += '           <div class="badge badge-' + item.Color + '" data-toggle="tooltip" data-placement="bottom" title data-original-title="' + item.Desc + '">' + item.CardStatus + '</div>';
			//html += '       </td>';
			html += '</tr>';

			//html += '       <td class="p-0">';
			//html += '          <div class="checkbox-fade fade-in-danger ml-2 mt-2">';
			//html += '            <label>';
			//html += '                 <input type="checkbox" name="Task_@item.TaskID" onclick="doneTaskList(@item.TaskID, '@item.StatusType')">';
			//html += '                     <span class="cr">';
			//html += '                        <i class="cr-icon fa fa-check txt-danger"></i>';
			//html += '                     </span>';
			//html += '                             </label>';
			//html += '                         </div>';
			//html += '                     </td>';


		});
		//$('#Table-' + ControlID + ' tbody').html('');
		//$('#Table-' + ControlID + ' tbody').append(html);

		$('.data-content-' + ControlID + ' tbody').html('');
		$('.data-content-' + ControlID + ' tbody').append(html);
	}
}
function RenderKanbanFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}

		var arrKanban = [];
		$('.kanban-item').each(function () {
			this.remove();
		});
		$.map(arrData, function (item) {
			KanbanTest.addElement(
				item.ProcessStep,
				{
					'id': item.ID,
					'title': item.Name,
				}
			);
		});
		CountByProcessStep();
	}
}
function CountByProcessStep() {
	$('.kanban-board').each(function (index, board) {
		var count = $(board).find('.kanban-item').length;
		$(board).find('.kanban-item-count').text(count);
	});
}
function RenderGeneralListCheckFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';
		var listType = {};
		listType["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';
		var listRequester = {};
		listRequester["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';

		$.map(arrData, function (item, i) {

			if (!listStatus[item.CardStatus]) {
				listStatus[item.CardStatus] = '<a href="#" class="dropdown-item btn btn-outline-' + item.Color + ' " onclick="FillterStatus(\'' + ControlID + '\', \'' + item.CardStatus + '\');">' + item.CardStatus + ' </a>';
			}
			if (!listType[item.Type]) {
				listType[item.Type] = '<a href="#" class="dropdown-item btn btn-outline-secondary" onclick="FillterStatus(\'' + ControlID + '\', \'' + item.Type + '\');">' + item.Type + ' </a>';
			}
			if (!listRequester[item.UserName]) {
				listRequester[item.UserName] = ' <a href="#" class="dropdown-item btn btn-outline-secondary" onclick="FillterStatus(\'' + ControlID + '\', \'' + item.UserName + '\');">' + item.UserName + ' </a>';
			}


			html += '<tr id="row-' + i + '" >';
			html += '    <td class="p-2">';
			if (item.IsCheck === '1') {
				html += '       <div class="border-checkbox-section">';
				html += '           <div class="checkbox-fade fade-in-primary mr-2">';
				html += '               <label for="' + item.ID + '" class="mb-0">';
				html += '                   <input type="checkbox" class="CheckCard" id="' + item.ID + '" value="1">';
				html += '                   <span class="cr">';
				html += '                       <i class="cr-icon fa fa-check txt-primary"></i>';
				html += '                   </span>';
				html += '               </label>';
				html += '               </div>';
				html += '       </div>';
			}
			else if (item.IsCheck === '-1') {
				html += '       <div class=" ">';
				html += '           <i class="ti-na txt-primary"></i>';
				html += '       </div>';
			}
			else {
				html += '       <div class=" ">';
				html += '           <i class="fa fa-check-square-o txt-primary"></i>';
				html += '       </div>';
			}
			html += '   </td>';

			html += '    <td class="p-2 task-des" onclick="' + item.OpenEdit + '">';
			html += '       <div class="task-des-title">';
			//if (item.IsToMe === '1') {
			//    html += '           <span id="dot" class=""><span class="ping"></span></span>';
			//}

			html += item.Name;
			// html += '           <div class="des-shadow"></div>';
			html += '       </div>';

			html += '       <div class="d-flex f-wrap">';
			html += '           <div class="">';
			html += '               <i class="fa fa-check text-test mr-1 mt-2 pointer"> </i >';
			html += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';

			html += '           </div>';
			html += '           <div class="visible-xs mr-2 ml-2"> ';
			html += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Created"></i> ' + item.DateString;
			html += '           </div>';
			html += '       </div>';

			html += '        <div class="visible-xs">';
			html += '             <div class="d-flex justify-content-between">';
			if (item.ObjectInCharge)
				html += '                   <span class="text-danger"> <i class="fa fa-user text-test mr-1 mt-2 pointer"> </i > ' + item.ObjectInCharge + ' </span>';
			html += '                   <button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" data-toggle="tooltip" data-placement="top" data-original-title="' + item.CardNote + '" onclick="window.location.href=\'' + item.Url + '\'">' + item.CardStatus + '</button>';
			html += '             </div>';
			html += '        </div>';
			html += '    </td>';




			html += '    <td class="p-2 hidden-xs">';
			html += '       <div class="">';
			html += '            <i class="fa fa-chain text-danger mr-1" data-toggle="tooltip" data-placement="bottom" title="Document Type" data-original-title="Document Type"></i>' + item.Type;
			html += '       </div>';
			html += '       <div class="pointer mt-1">';
			html += '            <i class="fa fa-key text-info mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="Document Code" data-original-title="Document Code"></i>' + item.Code;
			html += '       </div>';
			html += '   </td>';

			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-' + item.Color + ' btn-round btn-sm" href="' + item.Url + '">' + item.CardStatus + '</button></td>';


			html += '    <td class="p-2 hidden-xs">';
			html += '       <div class="mr-1">';
			html += '            <i class="fa fa-user text-danger text-danger" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Person Incharge"></i>' + item.UserName;
			html += '       </div>';
			html += '        <div class="mr-1 mt-1">';
			html += '           <i class="fa fa-clock-o text-warning" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Hold Time"></i>' + item.DateString;
			html += '       </div>';
			html += '   </td>';

			//html += '    <td class="p-2 hidden-xs">';
			//html += '       <div class="mr-1">';
			//html += '           <i class="fa fa-clock-o text-primary" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Start"></i>' + item.DateStringBegin;
			//html += '       </div>';
			//html += '        <div class="mr-1 mt-1">';
			//html += '           <i class="fa fa-clock-o text-danger" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date End"></i>' + item.DateStringEnd;
			//html += '       </div>';
			//html += '   </td>';

			html += ' </tr >';
		});
		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(html);
		CountRows('GeneralList-', ControlID);

		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);
		///
		var htmlFillterType = ''
		$.map(listType, function (item) {
			htmlFillterType += item;
		});
		$('#dropmenu-doctype').html('');
		$('#dropmenu-doctype').append(htmlFillterType);
		///
		var htmlFillterRequester = ''
		$.map(listRequester, function (item) {
			htmlFillterRequester += item;
		});
		$('#dropmenu-requester').html('');
		$('#dropmenu-requester').append(htmlFillterRequester);

		$('.CheckCard').on("click", function () {
			$('#lbCheckAll').text("(" + $('.CheckCard:checkbox:checked').length + ")");
		});
	}
}
function RenderProcessKanbanFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		$.map(arrData, function (item, i) {
			html += '<tr id="row-' + i + '" >';
			html += '    <td class="p-2 task-des" onclick="' + item.OpenEdit + '">';
			html += '       <div class="task-des-title">';
			//if (item.IsToMe === '1') {
			//    html += '           <span id="dot" class=""><span class="ping"></span></span>';
			//}

			html += item.Name;
			// html += '           <div class="des-shadow"></div>';
			html += '       </div>';

			html += '       <div class="d-flex f-wrap">';
			html += '           <div class="">';
			html += '               <i class="fa fa-edit text-test mr-1 mt-2 pointer"> </i >';
			html += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';

			html += '           </div>';
			html += '           <div class="visible-xs mr-2 ml-2"> ';
			html += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Created"></i> ' + item.DateStringBegin;
			html += '           </div>';
			html += '       </div>';

			html += '    </td>';

			html += '    <td class="p-2 hidden-xs">';
			if (item.IsCheck === '1') {
				html += '       <div class="border-checkbox-section mt-3">';
				html += '           <div class="checkbox-fade fade-in-primary mr-2">';
				html += '               <label for="' + item.ID + '" class="mb-0">';
				html += '                   <input type="checkbox" class="CheckCard" id="' + item.ID + '" value="1">';
				html += '                   <span class="cr">';
				html += '                       <i class="cr-icon fa fa-check txt-primary"></i>';
				html += '                   </span>';
				html += '               </label>';
				html += '               </div>';
				html += '       </div>';
			}
			else {
				html += '       <div class="mt-3">';
				html += '           <i class="fa fa-check-square-o txt-primary"></i>';
				html += '       </div>';
			}

			html += '   </td>';

			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-info btn-round btn-sm" >' + item.Total + '</button></td>';
			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-warning btn-round btn-sm">' + item.ToDo + '</button></td>';
			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-primary btn-round btn-sm">' + item.InProcess + '</button></td>';
			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-success btn-round btn-sm">' + item.Done + '</button></td>';
			html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-danger btn-round btn-sm">' + item.Reject + '</button></td>';

			html += ' </tr >';
		});
		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(html);
		CountRows('GeneralList-', ControlID);
	}
}

function RenderServicesCatalogFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';

		$.map(arrData, function (item, i) {
			var isView = i <= 100 ? "" : "d-none";
			if (item.RowType == "GroupRow") {
				html += '<tr class="' + isView + '">';
				html += '	<td class="grouprow-' + item.Color + '"><div><i class="' + item.Icon + '">&nbsp;&nbsp;&nbsp;</i>' + item.GroupRow + '</td>';
				html += '	<td class="grouprow-' + item.Color + '"><div><i class="fa fa-flag">&nbsp;&nbsp;&nbsp;</i>' + item.ItemVal + '</td>';
				html += '</tr> ';
			}
			else {
				if (!listStatus[item.CardStatus]) {
					listStatus[item.CardStatus] = ' <a href="#" class="dropdown-item btn btn-outline-' + item.Color + ' " onclick="FillterStatus(\'' + ControlID + '\', \'' + item.CardStatus + '\');">' + item.CardStatus + ' </a>';
				}
				html += '<tr id="row-' + i + '"  class="' + isView + '">';
				html += '    <td class="p-2 task-des" >';
				html += '       <div class="task-des-title" onclick="window.location.href=\'' + (item.Link != undefined ? item.Link : "#") + '\'">';
				if (item.IsToMe == '1') {
					html += '		<span id="dot" class=""><span class="ping"></span></span>';
				} else if (item.IsToMe == '2') {
					html += '		<span class="dot-warning"><span class="ping-warning"></span></span>';
				}
				var pColor = item.Progress == undefined ? 'c-pink' : item.Progress > 90 ? 'c-green' : item.Progress > 80 ? 'c-blue' : item.Progress > 60 ? 'c-yellow' : 'c-pink';

				html += item.Name;
				// html += '           <div class="des-shadow"></div>';
				html += '       </div>';

				html += '       <div class="d-flex f-wrap">';
				html += '           <div class="">';
				html += '               <i class="fa fa-flag-o text-' + item.PriorityColor + ' mr-1 mt-2 pointer"> </i >';
				html += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';
				html += '           </div>';
				//html += '           <div class="visible-xs mr-2 ml-2"> ';
				//html += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i> ' + item.DateStringEnd;
				//html += '           </div>';
				html += '       </div>';
				html += '        <div class="mr-2 visible-xs">';
				html += '             <div class="d-flex justify-content-between">';

				//html += '               <div class="m-w-2xx">';
				//html += '					<span class="" > <i class="fa fa-user text-success mr-1 mt-2 pointer"> </i > ' + item.ObjectInCharge + ' </span><br> ';
				//html += '					<div class="progress d-inline-block m-w-1xx mt-1">';
				//html += '       				<div class="progress-bar bg-' + pColor + '" style="width:' + item.Progress + '%"> ';
				//html += '       				</div> ';
				//html += '					</div>';
				//html += '				</div > ';
				//html += '				<button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" data-toggle="tooltip" data-placement="top" data-original-title="' + item.CardNote + '" onclick="window.location.href=\'' + item.Url + '\'">' + item.CardStatus + '</button>';

				html += '             </div>';
				html += '        </div>';
				html += '    </td>';
				html += '   	<td>';
				if (item.ActionList != undefined && item.ActionList.length) {
					var listItem = JSON.parse(item.ActionList);

					html += '   		<div class="dropdown-primary dropdown open">';
					html += '   			<button  class="btn btn btn-outline-' + item.Color + ' btn-round btn-sm" type="button" data-toggle="dropdown"><i class="fa fa-list-ul text-muted"></i>  ';
					html += '   			</button>';
					html += '   			<div class="dropdown-menu" data-dropdown-in="fadeIn" data-dropdown-out="fadeOut">';

					$.map(listItem, function (actionItem) {
						html += '   	<a class="dropdown-item waves-light waves-effect" href="' + actionItem.Link + '">' + actionItem.ActionName + '</a>';
					});
					html += '   </div > ';
					html += '</div>';

				}
				html += '   	</td>';

				html += ' </tr >';
			}
		});

		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(html);

		$('#pagetotal-' + ControlID).val(parseInt((arrData.length - arrData.length % 100) / 100));
		$('#rowtotal-' + ControlID).val(arrData.length);
		$("#pagetitle-" + ControlID).text("From " + 1 + " to 100 of " + (arrData.length));

		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);
	}
}
function RenderProgressListFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';

		var listColumns = GetControlsConfig('ColumnHeaderConfig' + ControlID);
		if (typeof (listColumns) == "string") {
			listColumns = JSON.parse(listColumns);
		}

		var htmlRawList = [];
		for (var i = 0; i < 100 && i < arrData.length; i++) {
			var item = arrData[i];
			RenderProgressListFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, 1, listColumns);
		}

		$('#Table-' + ControlID + ' tbody').html('');
		var showList = htmlRawList.reduce(
			(accumulator, currentValue) =>
				accumulator + currentValue.html, ""
		);
		$('#Table-' + ControlID + ' tbody').append(showList);

		for (var i = 100; i < arrData.length; i++) {
			var item = arrData[i];
			RenderProgressListFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, 0, listColumns);
		}

		SetControlsConfig('html-' + ControlID, htmlRawList);

		$('#pagetotal-' + ControlID).val(parseInt((arrData.length - arrData.length % 100) / 100));
		$('#rowtotal-' + ControlID).val(arrData.length);
		$("#pagetitle-" + ControlID).text("From " + 1 + " to 100 of " + (arrData.length));


		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);
		$('.dropdown-item.item-progress').on('click', function () {
			FillterStatus(ControlID, this.text);
		});

	}
}
const isMobileDevice = window.navigator.userAgent.toLowerCase().includes("mobi");
function RenderProgressListFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, visible, listColumns) {
	var htmlRaw = "";

	var isView = i <= 100 ? "" : "";
	if (item == undefined) return;
	if (item != undefined && item.RowType != undefined && item.RowType == "GroupRow") {
		htmlRaw += '<tr class="' + isView + '">';
		htmlRaw += '	<td colspan="6" class="GroupRow">' + item.GroupRow + '</td>';
		htmlRaw += '</tr> ';
	}
	else {
		if (item.CardStatus != undefined && !listStatus[item.CardStatus]) {
			listStatus[item.CardStatus] = ' <a href="#" class="dropdown-item item-progress btn btn-outline-' + item.Color + '">' + item.CardStatus + ' </a>';
		}
		htmlRaw += '<tr id="row-' + i + '"  class="' + isView + '">';
		htmlRaw += '    <td class="p-2 task-des" ' + (!isMobileDevice ? ' onclick="window.open(\'' + item.Url + '\') "' : "") + ' >';
		htmlRaw += '       <div class="task-des-title">';
		if (item.IsToMe == '1') {
			htmlRaw += '		<span id="dot" class=""><span class="ping"></span></span>';
		} else if (item.IsToMe == '2') {
			htmlRaw += '		<span class="dot-warning"><span class="ping-warning"></span></span>';
		}


		htmlRaw += item.Name;
		// html += '           <div class="des-shadow"></div>';
		htmlRaw += '       </div>';

		htmlRaw += '       <div class="d-flex f-wrap">';
		htmlRaw += '           <div class="">';
		htmlRaw += '               <i class="' + (item.TitleIconClass ?? "fa fa-flag-o text-secondary") + ' mr-1 mt-2 pointer"> </i >';
		htmlRaw += '               <span class="' + (item.TitleClass ?? "text-secondary") + '"> ' + (item.Title ?? "") + ' </span>';
		htmlRaw += '           </div>';
		//htmlRaw += '           <div class="visible-xs mr-2 ml-2"> ';
		//htmlRaw += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i> ' + item.ProgressTitle;
		//htmlRaw += '           </div>';
		htmlRaw += '       </div>';

		if (isMobileDevice) {
			htmlRaw += '<div class="mr-2 visible-xs">';
			for (var i = 1; i < listColumns.length; i++) {
				var colItem = listColumns[i].OptionConfig;
				if (typeof (colItem) == "string") colItem = JSON.parse(colItem);

				if (colItem.type?.toLowerCase() == "progress") {
					var colItem = listColumns[i].OptionConfig;
					if (typeof (colItem) == "string") colItem = JSON.parse(colItem);

					var pColor = "";
					var trackColor = "";
					var progressStatus = item[colItem.row2.status];
					var progressValue = item[colItem.row2.key];

					if (progressStatus) {
						pColor = progressStatus;
					}
					else if (colItem.type == -1) {
						pColor = progressValue == undefined ? 'c-green' : progressValue > 90 ? 'c-pink' : progressValue > 80 ? 'c-yellow' : progressValue > 60 ? 'c-blue' : 'c-green';
					}
					else {
						pColor = progressValue == undefined ? 'c-pink' : progressValue > 90 ? 'c-green' : progressValue > 80 ? 'c-blue' : progressValue > 60 ? 'c-yellow' : 'c-pink';
					}
					trackColor = pColor == "c-pink" ? "danger" : pColor == "c-green" ? "bg-success" : pColor == "c-blue" ? "bg-primary" : "bg-secondary";

					htmlRaw += '	<div class="d-flex justify-content-between">';
					htmlRaw += '		<div class="m-w-1xx">';
					htmlRaw += '			<div class="m-w-1xx">';
					htmlRaw += '				<div class="progress d-inline-block m-w-1xx mt-1">';
					htmlRaw += '       				<div class="progress-bar bg-' + trackColor + '" style="width:' + (progressValue ?? "0") + '%"></div> ';
					htmlRaw += '				</div>';
					htmlRaw += '				<span class="d-inline-block align-self-end t-' + pColor + ' m-r-20"><ins>' + (progressValue ?? "") + '%</ins></span>';
					htmlRaw += '			</div>';
					htmlRaw += '			<span class=""><i class="' + (colItem.row1.iconClass ?? " fa fa-map-marker text-doing") + ' t-' + pColor + ' mr-1 mt-2"> </i > ' + (item[colItem.row1.key] ?? "") + ' </span><br> ';

					htmlRaw += '		</div > ';
					if ((item.Url || item.Status) && i <= 3)
						htmlRaw += '		<button onclick="window.location.href=\'' + item.Url + '\'" class="btn mt-1 mb-1 btn-outline-' + item.Color + ' btn-round btn-sm">' + (item.Status ?? "view") + '</button>';
					htmlRaw += '    </div>';
				}
				else {
					htmlRaw += '			<div class="d-flex justify-content-between">';
					htmlRaw += '				<div class="m-w-1xx">';
					htmlRaw += '					<span class="' + (colItem.rowClass ?? "") + '">';
					htmlRaw += '						<i class="' + (colItem.row1.iconClass ?? " fa fa-map-marker text-doing") + ' t-' + pColor + ' mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="' + (colItem.row1.tootip ?? "") + '"></i>';
					htmlRaw += '						<span class="' + (colItem.row1.rowClass ?? "") + '">' + item[colItem.row1.key] + '</span>';
					htmlRaw += '						<i class="' + (colItem.row2.iconClass ?? " fa fa-user text-success ") + ' mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="' + (colItem.row2.tootip ?? "") + '"></i>';
					htmlRaw += '						<span class="' + (colItem.row2.rowClass ?? "") + '">' + item[colItem.row2.key] + '</span>';
					htmlRaw += '					</span>';
					htmlRaw += '				</div > ';
					htmlRaw += '             </div>';
				}
			}
			htmlRaw += '</div>';

		}

		htmlRaw += '    </td>';

		if (!isMobileDevice)
			for (var i = 1; i < listColumns.length; i++) {
				var colItem = listColumns[i].OptionConfig;
				if (typeof (colItem) == "string") colItem = JSON.parse(colItem);

				//console.log("render " + colItem.type);
				if (colItem.type?.toLowerCase() == "progress") {
					var pColor = "";
					var trackColor = "";
					var progressStatus = item[colItem.row2.status];
					var progressValue = item[colItem.row2.key];
					var progressURL = item[colItem.row2.key + "URL"];

					if (progressStatus) {
						pColor = progressStatus;
					}
					else if (colItem.type == -1) {
						pColor = progressValue == undefined ? 'c-green' : progressValue > 90 ? 'c-pink' : progressValue > 80 ? 'c-yellow' : progressValue > 60 ? 'c-blue' : 'c-green';
					}
					else {
						pColor = progressValue == undefined ? 'c-pink' : progressValue > 90 ? 'c-green' : progressValue > 80 ? 'c-blue' : progressValue > 60 ? 'c-yellow' : 'c-pink';
					}
					trackColor = pColor == "c-pink" ? "danger" : pColor == "c-green" ? "bg-success" : pColor == "c-blue" ? "bg-primary" : "bg-secondary";

					htmlRaw += '    <td class="p-2 hidden-xs">';
					htmlRaw += '       <div class="' + (colItem.row1.rowClass ?? "") + '" data-toggle="tooltip" data-placement="bottom" title="' + (colItem.row1.tootip ?? " Requester ") + '">';
					htmlRaw += '            <i class="' + (colItem.row1.iconClass ?? " fa fa-user text-success ") + ' mr-1 mt-2" ></i>' + item[colItem.row1.key];
					htmlRaw += '       </div>';
					htmlRaw += '       <div class="progress d-inline-block m-w-1xx">';
					htmlRaw += '       		<div class="progress-bar bg-' + pColor + '" style="width:' + (progressValue ?? "0") + '%"></div> ';
					htmlRaw += '       </div>';
					htmlRaw += '		<span class="d-inline-block t-' + pColor + ' m-r-20"><ins><a target="_blank" class=" t-' + pColor + '" href="' + (progressURL ?? "") + '">' + (progressValue ?? "") + '%</a></ins></span>';
					htmlRaw += '   </td>';
				}
				else {
					htmlRaw += '    <td class="p-2 hidden-xs' + (colItem.rowClass ?? "") + '">';
					htmlRaw += '       <div class="' + (colItem.row1.rowClass ?? "") + '" data-toggle="tooltip" data-placement="top" title="' + (colItem.row1.tootip ?? " Requester ") + '">';
					htmlRaw += '            <i class="' + (colItem.row1.iconClass ?? "fa fa-star-o") + ' mr-1 mt-2"></i><span class="">' + item[colItem.row1.key] + '</span>';
					htmlRaw += '       </div>';
					htmlRaw += '        <div class="' + colItem.row2.rowClass + '" data-toggle="tooltip" data-placement="top" title="' + (colItem.row2.tootip ?? " Requester ") + '">';
					htmlRaw += '           <i class="' + (colItem.row2.iconClass ?? "fa fa fa-flag-checkered") + ' mr-1 mt-1"></i><span class="">' + item[colItem.row2.key] + '</span>';
					htmlRaw += '       </div>';
					htmlRaw += '   </td>';
				}
			}
		htmlRaw += ' </tr >';
	}
	htmlRawList.push({ 'html': htmlRaw, 'visible': visible });
	$('[data-toggle="tooltip"]').tooltip();

}

function RenderProjectTaskFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';

		var htmlRawList = [];

		for (var i = 0; i < 100 && i < arrData.length; i++) {
			var item = arrData[i];
			RenderProjectTaskFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, 1);
		}

		$('#Table-' + ControlID + ' tbody').html('');
		var showList = htmlRawList.reduce(
			(accumulator, currentValue) =>
				accumulator + currentValue.html, ""
		);
		$('#Table-' + ControlID + ' tbody').append(showList);

		for (var i = 100; i < arrData.length; i++) {
			var item = arrData[i];
			RenderProjectTaskFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, 0);
		}

		SetControlsConfig('html-' + ControlID, htmlRawList);

		$('#pagetotal-' + ControlID).val(parseInt((arrData.length - arrData.length % 100) / 100));
		$('#rowtotal-' + ControlID).val(arrData.length);
		$("#pagetitle-" + ControlID).text("From " + 1 + " to 100 of " + (arrData.length));


		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);
		$('.dropdown-item.item-progress').on('click', function () {
			FillterStatus(ControlID, this.text);
		});

	}
}



function RenderProjectTaskFromJsonTableHtml(ControlID, htmlRawList, listStatus, item, i, visible) {
	var htmlRaw = "";

	var isView = i <= 100 ? "" : "";
	if (item == undefined) return;
	if (item != undefined && item.RowType != undefined && item.RowType == "GroupRow") {
		htmlRaw += '<tr class="' + isView + '">';
		htmlRaw += '	<td colspan="6" class="GroupRow">' + item.GroupRow + '</td>';
		htmlRaw += '</tr> ';
	}
	else {
		if (item.CardStatus != undefined && !listStatus[item.CardStatus]) {
			listStatus[item.CardStatus] = ' <a href="#" class="dropdown-item item-progress btn btn-outline-' + item.Color + '">' + item.CardStatus + ' </a>';
		}
		htmlRaw += '<tr id="row-' + i + '"  class="' + isView + '">';
		htmlRaw += '    <td class="p-2 task-des" >';
		htmlRaw += '       <div class="task-des-title">';
		if (item.IsToMe == '1') {
			htmlRaw += '		<span id="dot" class=""><span class="ping"></span></span>';
		} else if (item.IsToMe == '2') {
			htmlRaw += '		<span class="dot-warning"><span class="ping-warning"></span></span>';
		}
		var pColor = item.Progress == undefined ? 'c-pink' : item.Progress > 90 ? 'c-green' : item.Progress > 80 ? 'c-blue' : item.Progress > 60 ? 'c-yellow' : 'c-pink';
		var trackColor = item.ProgressColor != undefined && item.ProgressColor.length ? item.ProgressColor : pColor;
		htmlRaw += item.Name;
		// html += '           <div class="des-shadow"></div>';
		htmlRaw += '       </div>';

		htmlRaw += '       <div class="d-flex f-wrap">';
		htmlRaw += '           <div class="">';
		htmlRaw += '               <i class="fa fa-check text-' + item.PriorityColor + ' mr-1 mt-2 pointer"> </i >';
		htmlRaw += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';
		htmlRaw += '           </div>';
		htmlRaw += '           <div class="visible-xs mr-2 ml-2"> ';
		htmlRaw += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i> ' + item.DateStringEnd;
		htmlRaw += '           </div>';
		htmlRaw += '       </div>';
		htmlRaw += '        <div class="mr-2 visible-xs">';
		htmlRaw += '             <div class="d-flex justify-content-between">';
		htmlRaw += '               <div class="m-w-1xx">';
		htmlRaw += '		<span class="">';
		htmlRaw += '            <i class="fa fa-star-o t-' + pColor + ' mr-1 mt-2" data-toggle="tooltip" data-placement="top" title data-original-title="Current"></i><span class="font-weight-bold">' + item.Actual + '</span>';
		htmlRaw += '            <i class="fa fa-flag-o ' + item.TargetStatus + ' font-weight-bold mr-1 mt-1" data-toggle="tooltip"  data-original-title="Target"></i><span class="font-weight-bold ' + item.TargetStatus + '">' + item.Target + '</span>';
		htmlRaw += '        </span>';
		htmlRaw += '					<div class="progress d-inline-block m-w-1xx mt-1">';
		htmlRaw += '       				<div class="progress-bar bg-' + trackColor + '" style="width:' + item.Progress + '%"></div> ';
		htmlRaw += '					</div>';
		htmlRaw += '				</div > ';
		htmlRaw += '				<span class="d-inline-block align-self-end t-' + pColor + ' m-r-20"><ins>' + (item.ProgressDisplay ?? +item.Progress ?? '0' + '%') + '</ins></span>';
		//htmlRaw += '				<button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" data-toggle="tooltip" data-placement="top" data-original-title="' + item.CardNote + '" onclick="OpenModalForm(\'' + ControlID + '\',\'' + item.ID + '\',\'ModalForm\',\'' + item.ProcessStep + '\', 0);" >' + item.CardStatus + '</button>';
		htmlRaw += '				<button onclick="window.location.href=\'' + item.Url + '\'" class="btn mt-1 btn-outline-' + item.Color + ' btn-round btn-sm">' + item.CardStatus + '</button>';
		htmlRaw += '             </div>';
		htmlRaw += '					<span class="" > <i class="fa fa-user text-success mr-1 mt-2 pointer"> </i > ' + item.ObjectInCharge + ' </span><br> ';

		htmlRaw += '        </div>';
		htmlRaw += '    </td>';

		htmlRaw += '    <td class="p-2 hidden-xs">';
		htmlRaw += '       <div class="">';
		htmlRaw += '            <i class="fa fa-chain text-danger mr-1 mt-2"></i>' + item.Type;
		htmlRaw += '       </div>';
		htmlRaw += '       <div class="">';
		htmlRaw += '            <i class="fa fa-key text-info mr-1 mt-1"></i>' + item.Code;
		htmlRaw += '       </div>';
		htmlRaw += '   </td>';

		//htmlRaw += '    <td class="p-2 hidden-xs btn-status"><button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" onclick="OpenModalForm(\'' + ControlID + '\',\'' + item.ID + '\',\'ModalForm\',\'' + item.ProcessStep + '\', 0);">' + item.CardStatus + '</button></td>';
		htmlRaw += '    <td class="p-2 hidden-xs"><a type="button" target ="_blank" href="' + item.Url + '" class="btn btn-outline-' + item.Color + ' btn-round btn-sm">' + item.CardStatus + '</a></td>';

		htmlRaw += '    <td class="p-2 hidden-xs">';
		htmlRaw += '       <div class="" data-toggle="tooltip" data-placement="left" title data-original-title="Actual">';
		htmlRaw += '            <i class="fa fa-star-o t-' + pColor + ' mr-1 mt-2"></i><span class="font-weight-bold">' + item.Actual + '</span>';
		htmlRaw += '       </div>';
		htmlRaw += '        <div class="">';
		htmlRaw += '           <i class="fa fa-flag-o ' + item.TargetStatus + ' font-weight-bold mr-1 mt-1" data-toggle="tooltip"  data-original-title="Target"></i><span class="font-weight-bold ' + item.TargetStatus + '">' + item.Target + '</span>';
		htmlRaw += '       </div>';
		htmlRaw += '   </td>';

		htmlRaw += '    <td class="p-2 hidden-xs">';
		htmlRaw += '       <div class="">';
		htmlRaw += '            <i class="fa fa-user text-success mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Requester"></i>' + item.ObjectInCharge;
		htmlRaw += '       </div>';

		htmlRaw += '       <div class="progress d-inline-block m-w-1xx">';
		htmlRaw += '       	<div class="progress-bar bg-' + pColor + '" style="width:' + item.Progress + '%"> ';
		htmlRaw += '       	</div> ';

		htmlRaw += '       </div>	';
		htmlRaw += '		<span class="d-inline-block t-' + pColor + ' m-r-20"><ins>' + (item.ProgressDisplay ?? +item.Progress ?? '0' + '%') + '</ins></span>';


		htmlRaw += '   </td>';

		htmlRaw += '    <td class="p-2 hidden-xs">';
		htmlRaw += '     <div class="">';
		htmlRaw += '           <i class="fa fa-clock-o text-primary mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Start"></i>' + item.DateStringBegin;
		htmlRaw += '       </div>';
		htmlRaw += '        <div class="">';
		htmlRaw += '           <i class="fa fa-clock-o text-danger mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date End"></i>' + item.DateStringEnd;
		htmlRaw += '       </div>';
		htmlRaw += '   </td>';

		htmlRaw += ' </tr >';
	}
	htmlRawList.push({ 'html': htmlRaw, 'visible': visible });
	$('[data-toggle="tooltip"]').tooltip();

}


function RenderGeneraTimeLineFromJsonTableStatus(FormCode, jsData, ControlID, OnClickAction) {
	renderGeneralListTimeLine(FormCode, jsData, ControlID, OnClickAction);
}

function RenderGeneralListFromJsonTableStatus(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';

		$.map(arrData, function (item, i) {
			if (item.ID > 0) {
				if (!listStatus[item.CardStatus]) {
					listStatus[item.CardStatus] = ' <a href="#" class="dropdown-item btn btn-outline-' + item.Color + ' " onclick="FillterStatus(\'' + ControlID + '\', \'' + item.CardStatus + '\');">' + item.CardStatus + ' </a>';
				}

				html += '<tr id="row-' + i + '" onclick="window.location.href=\'' + item.Url + '\'">';
				html += '    <td class="p-2 task-des" >';
				html += '       <div class="task-des-title">';
				if (item.IsToMe == '1') {
					html += '		<span id="dot" class=""><span class="ping"></span></span>';
				} else if (item.IsToMe == '2') {
					html += '		<span class="dot-warning"><span class="ping-warning"></span></span>';
				}

				html += item.Name;
				// html += '           <div class="des-shadow"></div>';
				html += '       </div>';

				html += '       <div class="d-flex f-wrap">';
				html += '           <div class="">';
				html += '               <i class="fa fa-flag-o text-test mr-1 mt-2 pointer"> </i >';
				html += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';
				html += '           </div>';
				html += '           <div class="visible-xs mr-2 ml-2"> ';
				html += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i> ' + item.DateStringEnd;
				html += '           </div>';
				html += '       </div>';

				html += '        <div class="mr-2 visible-xs">';
				html += '             <div class="d-flex justify-content-between">';
				html += '                   <span class="text-danger"> <i class="fa fa-user text-test mr-1 mt-2 pointer"> </i > ' + item.ObjectInCharge + ' </span>';
				html += '                   <button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" data-toggle="tooltip" data-placement="top" data-original-title="' + item.CardNote + '" onclick="window.location.href=\'' + item.Url + '\'">' + item.CardStatus + '</button>';
				html += '             </div>';
				html += '        </div>';
				html += '    </td>';

				html += '    <td class="p-2 hidden-xs">';
				html += '       <div class="">';
				html += '            <i class="fa fa-chain text-danger mr-1 mt-2" data-toggle="tooltip" ></i>' + item.Type;
				html += '       </div>';
				html += '       <div class="">';
				html += '            <i class="fa fa-key text-info mr-1 mt-1" ></i>' + item.Code;
				html += '       </div>';
				html += '   </td>';

				html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-' + item.Color + ' btn-round btn-sm" href="' + item.Url + '">' + item.CardStatus + '</button></td>';

				html += '    <td class="p-2 hidden-xs">';
				html += '       <div class="">';
				html += '            <i class="fa fa-user text-danger text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Person Incharge"></i>' + item.ObjectInCharge;

				html += '       </div>';
				html += '        <div class="">';
				html += '           <i class="fa fa-clock-o text-warning mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Hold Time"></i>' + item.FromLastUpdate;
				html += '       </div>';
				html += '   </td>';

				html += '    <td class="p-2 hidden-xs">';
				html += '     <div class="">';
				html += '           <i class="fa fa-clock-o text-primary mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Start"></i>' + item.DateStringBegin;
				html += '       </div>';
				html += '        <div class="">';
				html += '           <i class="fa fa-clock-o text-danger mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date End"></i>' + item.DateStringEnd;
				html += '       </div>';
				html += '   </td>';

				html += ' </tr >';
			}
		});


		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(html);
		CountRows('GeneralList-', ControlID);


		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);
	}
}

function RenderGeneralListFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		var html = '';
		var listStatus = {};
		listStatus["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';
		var listRequester = {};
		listRequester["ALL"] = '<a href="#" class="dropdown-item text-primary" onclick="FillterStatus(\'' + ControlID + '\', \'ALL\');">ALL</a>';
		var htmlRawList = [];

		for (var i = 0; i < 100 && i < arrData.length; i++) {
			var item = arrData[i];
			RenderGeneralListFromJsonTableHtml(ControlID, htmlRawList, listStatus, listRequester, item, i, 1);
		}

		$('#Table-' + ControlID + ' tbody').html('');
		var showList = htmlRawList.reduce(
			(accumulator, currentValue) =>
				accumulator + currentValue.html, ""
		);
		$('#Table-' + ControlID + ' tbody').append(showList);

		for (var i = 100; i < arrData.length; i++) {
			var item = arrData[i];
			RenderGeneralListFromJsonTableHtml(ControlID, htmlRawList, listStatus, listRequester, item, i, 1);
		}

		SetControlsConfig('html-' + ControlID, htmlRawList);

		$('#pagetotal-' + ControlID).val(parseInt((arrData.length - arrData.length % 100) / 100));
		$('#rowtotal-' + ControlID).val(arrData.length);
		var tonum = arrData.length > 100 ? 100 : arrData.length;
		$("#pagetitle-" + ControlID).text("From 0 to " + tonum + " of " + (arrData.length));

		var htmlFillterStatus = ''
		$.map(listStatus, function (item) {
			htmlFillterStatus += item;
		});
		$('#dropmenu-status').html('');
		$('#dropmenu-status').append(htmlFillterStatus);

		var htmlFillterRequester = ''
		$.map(listRequester, function (item) {
			htmlFillterRequester += item;
		});
		$('#dropmenu-requester').html('');
		$('#dropmenu-requester').append(htmlFillterRequester);

	}
}

function RenderGeneralListFromJsonTableHtml(ControlID, htmlRawList, listStatus, listRequester, item, i, visible) {

	var html = '';

	if (!listStatus[item.CardStatus]) {
		listStatus[item.CardStatus] = ' <a href="#" class="dropdown-item btn btn-outline-' + item.Color + ' " onclick="FillterStatus(\'' + ControlID + '\', \'' + item.CardStatus + '\');">' + item.CardStatus + ' </a>';
	}
	if (!listRequester[item.UserName]) {
		listRequester[item.UserName] = ' <a href="#" class="dropdown-item btn btn-outline-secondary" onclick="FillterStatus(\'' + ControlID + '\', \'' + item.UserName + '\');">' + item.UserName + ' </a>';
	}

	html += '<tr id="row-' + i + '" onclick="window.location.href=\'' + item.Url + '\'">';
	html += '    <td class="p-2 task-des" >';
	html += '       <div class="task-des-title">';
	if (item.IsToMe == '1') {
		html += '		<span id="dot" class=""><span class="ping"></span></span>';
	} else if (item.IsToMe == '2') {
		html += '		<span class="dot-warning"><span class="ping-warning"></span></span>';
	}

	html += item.Name;
	// html += '           <div class="des-shadow"></div>';
	html += '       </div>';

	html += '       <div class="d-flex f-wrap">';
	html += '           <div class="">';
	html += '               <i class="fa fa-flag-o text-test mr-1 mt-2 pointer"> </i >';
	html += '               <span class="text-' + item.PriorityColor + '"> ' + item.PriorityLevel + ' </span>';
	html += '           </div>';
	html += '           <div class="visible-xs mr-2 ml-2"> ';
	html += '                <i class="fa fa-clock-o text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i> ' + item.DateStringEnd;
	html += '           </div>';
	html += '       </div>';

	html += '        <div class="mr-2 visible-xs">';
	html += '             <div class="d-flex justify-content-between">';
	html += '                   <span class="text-danger"> <i class="fa fa-user text-test mr-1 mt-2 pointer"> </i > ' + item.ObjectInCharge + ' </span>';
	html += '                   <button class="btn btn-outline-' + item.Color + ' btn-round btn-sm" data-toggle="tooltip" data-placement="top" data-original-title="' + item.CardNote + '" onclick="window.location.href=\'' + item.Url + '\'">' + item.CardStatus + '</button>';
	html += '             </div>';
	html += '        </div>';
	html += '    </td>';

	html += '    <td class="p-2 hidden-xs">';
	html += '       <div class="">';
	html += '            <i class="fa fa-chain text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="Document Type" data-original-title="Document Type"></i>' + item.Type;
	html += '       </div>';
	html += '       <div class="">';
	html += '            <i class="fa fa-key text-info mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="Document Code" data-original-title="Document Code"></i>' + item.Code;
	html += '       </div>';
	html += '   </td>';

	html += '    <td class="p-2 hidden-xs btn-status"><a class="btn btn-outline-' + item.Color + ' btn-round btn-sm" href="' + item.Url + '">' + item.CardStatus + '</button></td>';



	html += '    <td class="p-2 hidden-xs">';
	html += '       <div class="">';
	html += '            <i class="fa fa-user text-danger text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Person Incharge"></i>' + item.ObjectInCharge;

	html += '       </div>';
	html += '        <div class="">';
	html += '           <i class="fa fa-clock-o text-warning mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Hold Time"></i>' + item.FromLastUpdate;
	html += '       </div>';
	html += '   </td>';

	html += '    <td class="p-2 hidden-xs">';
	html += '       <div class="">';
	html += '            <i class="fa fa-user text-warning mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Updated By"></i>' + item.UserNameUpdated;

	html += '       </div>';
	html += '        <div class="">';
	html += '           <i class="fa fa-clock-o text-warning mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Last Updated"></i>' + item.DateStringUpdated;
	html += '       </div>';
	html += '   </td>';

	html += '    <td class="p-2 hidden-xs">';
	html += '       <div class="">';
	html += '            <i class="fa fa-user text-danger mr-1 mt-2" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Requester"></i>' + item.UserName;
	html += '       </div>';
	html += '       <div class="">';
	html += '            <i class="fa fa-clock-o text-info mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Submission Date"></i>' + item.DateString;
	html += '       </div>';
	html += '   </td>';

	html += '    <td class="p-2 hidden-xs">';
	html += '     <div class="">';
	html += '           <i class="fa fa-clock-o text-primary mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date Start"></i>' + item.DateStringBegin;
	html += '       </div>';
	html += '        <div class="">';
	html += '           <i class="fa fa-clock-o text-danger mr-1 mt-1" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Date End"></i>' + item.DateStringEnd;
	html += '       </div>';
	html += '   </td>';

	html += ' </tr >';

	htmlRawList.push({ 'html': html, 'visible': visible });

}

function FillterStatus(ControlID, status) {
	console.log('SearchInTable');
	status = replaceAll(status.toUpperCase(), ' ', '');
	var List = $('#Table-' + ControlID + ' tbody').find("tr");
	var count = 0;

	var htmlRawList = GetControlsConfig('html-' + ControlID);
	var count = 0;
	var showList = [];
	$.map(htmlRawList, function (item) {
		if (replaceAll(item.html.toUpperCase().replace(/\s+/g, ''), ' ', '').indexOf(status) >= 0) {
			count++;
			item.visible = 1;
			if (count <= 100) {
				showList.push(item.html);
			}
		}
		else item.visible = 0;
	});
	SetControlsConfig('html-' + ControlID, htmlRawList);
	$('#Table-' + ControlID + ' tbody').html('');
	$('#Table-' + ControlID + ' tbody').append(showList.join());

	$('#pagetotal-' + ControlID).val(parseInt((count - count % 100) / 100));
	$('#rowtotal-' + ControlID).val(count);
	var tonum = count > 100 ? 100 : count;
	$("#pagetitle-" + ControlID).text("From 0 to " + tonum + " of " + (count));
	$('#TotalRow-' + ControlID).text(count);
}

function PageChange(ControlID, action) {
	console.log(action);
	var pagenum = parseInt($("#pagenum-" + ControlID).val());
	var rowtotal = parseInt($("#rowtotal-" + ControlID).val());
	var totalPage = (rowtotal - rowtotal % 100) / 100 + 1;

	if (action == "R" && pagenum < totalPage && pagenum < totalPage) {
		pagenum++;
	}
	if (action == "L" && pagenum > 1) {
		pagenum--;
	}
	var htmlRawList = GetControlsConfig('html-' + ControlID);

	var showList = [];
	console.log(pagenum);

	var j = 0;
	for (var i = 0; i < htmlRawList.length; i++) {
		var item = htmlRawList[i];
		if (item.visible == 1) {
			if (j >= (pagenum - 1) * 100 && j < pagenum * 100 && j < rowtotal) {
				showList.push(item.html);
			}
			j++;
		}
	}

	$('#Table-' + ControlID + ' tbody').html('');
	$('#Table-' + ControlID + ' tbody').append(showList.join());

	$("#pagenum-" + ControlID).val(pagenum);
	var toRow = ((pagenum) * 100) > rowtotal ? rowtotal : ((pagenum) * 100)

	$("#pagetitle-" + ControlID).text("From " + ((pagenum - 1) * 100) + " to " + toRow + " of " + (rowtotal));

}


function RenderFeedNewsFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			//console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		console.log(arrData);
		$.map(arrData, function (item, i) {

			htmlBody += '<div class="list d-flex align-items-center border-top p-1 pointer" onclick = "location.href=\'/Categories/CateAddUpdate?FormCode=FAC-0124&ID=' + item.ID + '\'">';
			htmlBody += '     <img class="img-sm rounded-circle m-1 hidden-xs d-none d-lg-block" src="' + item.Avatar + '" alt="Avatar" onerror="this.src=\'/Files/Avatar/avatarnull.png\'">';
			htmlBody += '         <div class="wrapper w-100">';
			htmlBody += '            <p class="mb-0">';
			htmlBody += '                 <a class="home-link">';
			htmlBody += '                     <b class="' + (item.IsView == 1 ? 'feed-post-read' : 'feed-post-unread') + '">' + item.FullName + '</b>' + item.Name;
			htmlBody += '                </a>';
			htmlBody += '            </p>';
			htmlBody += '            <div class="d-flex justify-content-between align-items-center">';
			htmlBody += '                <div class="d-flex align-items-center feed-date">';
			htmlBody += '                    <i class="fa fa-clock-o text-muted"></i>';
			htmlBody += '                    <span class="mb-0 pl-1">' + item.DateString + '</span>';
			htmlBody += '                </div>';
			htmlBody += '                <span class="text-muted ml-auto feed-view">';
			htmlBody += '                    ' + item.ViewCount + ' view';
			htmlBody += '                </span>';
			htmlBody += '            </div>';
			htmlBody += '        </div>';
			htmlBody += '    </div>';


		});
		$('#feednews').html('');
		$('#feednews').append(htmlBody);
	}
}


function RenderTimelineFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			//console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		//console.log(arrData);
		$.map(arrData, function (item, i) {
			htmlBody += '<div class="timeline-wrapper timeline-wrapper-' + item.Color + '">';
			htmlBody += '   <div class="timeline-badge"></div>';
			htmlBody += '       <div class="timeline-panel p-2">';
			htmlBody += '           <div class="timeline-body">';
			htmlBody += '               <p data-toggle="tooltip" data-placement="bottom" title="" data-original-title=""><i class="fa fa-calendar text-' + item.Color + ' mr-1"></i> <span>' + item.DateString + '</span></p>';
			htmlBody += '               <p class="font-weight-bold text-primary"> ' + item.Name + ' </p>';
			htmlBody += '               <p class="text-muted">' + item.Title + '</p>';
			htmlBody += '               <p class="text-secondary hidden-xs"><i class="fa fa-comments-o"></i> ' + (item.Desc != null ? item.Desc : "") + '</p>';
			htmlBody += '           <div class="badge badge-' + item.Color + '" data-toggle="tooltip" data-placement="bottom" title data-original-title="' + item.Desc + '">' + item.CardStatus + '</div>';
			htmlBody += '       </div >';
			htmlBody += '   </div >';
			htmlBody += '</div >';
		});
		$('#timeline-' + ControlID).html('');
		$('#timeline-' + ControlID).append(htmlBody);
	}
}
function RenderCardDnDFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	//var isFistLoadDnd = GetControlsConfig("isFistLoadDnd");
	//if (isFistLoadDnd == undefined || isFistLoadDnd === null || isFistLoadDnd === "0") {
	//    isFistLoadDnd = 1;
	//    SetControlsConfig("isFistLoadDnd", 0);
	//}
	var zInd = $.topZIndex("div");
	//luu y dung do vo jquery.draggable.js trong easyuiloader.js remove phan load daragable va dropable cua easyui
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}

		htmlBody += ' <div id="wrap" class="col-12">';
		htmlBody += '    <div id="external-events" class="row">';
		$.map(arrData, function (row, i) {
			htmlBody += '<div id="' + row.ID + '" class="card-dnd-item fc-event col-12 b-l-primary b-l-w-5 pb-0 justify-content-between d-none" qqfrom="' + row.QQFrom + '" qqto="' + row.QQTo + '" >';
			htmlBody += row.Name;
			htmlBody += '   <label id= "CountTo-' + row.ID + '" class="card-dnd-label font-weight-bold badge badge-' + row.Color + '">' + row.CardStatus + '</label>';
			htmlBody += '</div>';
		});
		htmlBody += '    </div>';
		htmlBody += '</div>';

		$('#DragNDropItemsList').html()
		$('#DragNDropItemsList').html('');
		$('#DragNDropItemsList').append(htmlBody);

		$('#external-events .fc-event').each(function () {
			// store data so the calendar knows to render an event upon drop
			$(this).data('event', {
				title: $.trim($(this).text()), // use the element's text as the event title
				stick: true, // maintain when user navigates (see docs on the renderEvent method)
				id: $(this).id,
				borderColor: "#dc3545",
				backgroundColor: "#dc3545",//danger    
				textColor: '#fff',
				icon: '',
				allDay: false,
				isNew: true
				//url: item.Url   
			});

			/// make the event draggable using jQuery UI

			$(this).draggable({
				stack: ".fc-event",
				zIndex: zInd,
				revert: true,      // will cause the event to go back to its
				revertDuration: 0  //  original position after the drag
			});


		});

		$('.card-dnd-item').on('click', function () {
			OnCardDnDClick(this, FormCode, ControlID);
		});

		SumCalendarStatus(ControlID);

	}
}

function OnCardDnDClick(item, FormCode, ControlID) {
	console.log('OnCardDnDClick');
	console.log(item.id);
	$('#IDCardList').val(item.id);
	$(item).parent().children().each(function () {
		$(this).removeClass("CardDnDOnClick");
	});
	$(item).addClass("CardDnDOnClick");


	FormCode = $('#FormCode').val();
	console.log(FormCode);
	$('a[data-toggle="pill"]').on('shown.bs.tab', function (e) {
		$('#calendar').fullCalendar('render');
	});
	LoadCardListsFromAjax(FormCode, 'ReportForm', FormCode, 1, null, 'calendar');
}

function RenderCardCheckFromJsonTable(FormCode, jsData, ControlID, OnClickAction) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		$.map(arrData, function (row, i) {
			htmlBody += '<li class="p-2 pointer b-l-' + row.Color + ' b-l-w-5" onclick = "OnClickCardList(' + row.ID + ')" >';
			htmlBody += '   <div class="media">';
			if (row.Url.length) {
				htmlBody += '       <img class="d-flex mr-2" src="' + row.Url + '" width="40">';
			}
			htmlBody += '       <div class="media-body">';
			htmlBody += '           <div class="d-flex flex-wrap justify-content-between">';
			htmlBody += '               <p class="notification-msg text-capitalize mb-0">' + row.Name + '</p>';
			htmlBody += '               <label class="badge badge-' + row.Color + '">' + row.CardStatus + '</label>';
			htmlBody += '           </div>';
			htmlBody += '           <div class="d-flex flex-wrap justify-content-between ">';
			htmlBody += '               <p class="text-muted">' + row.Title + '</p>';
			htmlBody += '               <div class="border-checkbox-section">';
			htmlBody += '                   <div class="checkbox-fade fade-in-primary">';
			htmlBody += '                       <label for="' + ControlID + '-' + row.ID + '">';
			htmlBody += '                           <input type="checkbox" class ="CardCheck" id="' + ControlID + '-' + row.ID + '" value="1" checked>';
			htmlBody += '                           <span class="cr">';
			htmlBody += '                               <i class="cr-icon fa fa-check txt-primary"></i>';
			htmlBody += '                           </span>';
			htmlBody += '                       </label>';
			htmlBody += '                   </div>';
			htmlBody += '               </div>';
			htmlBody += '           </div>';
			htmlBody += '       </div>';
			htmlBody += '   </div>';
			htmlBody += '</li>';

		});

		$('#CarlistUL-' + ControlID).html('');
		$('#CarlistUL-' + ControlID).append(htmlBody);


	}
}

function RenderCardListFromJsonTable(FormCode, jsData, ControlID, OnClickAction, LayoutConfig) {
	var htmlBody = '';
	if (jsData !== null) {
		var arrData = [];
		try {
			arrData = JSON.parse(jsData);
			console.log(arrData);
		} catch (e) {
			console.log(e);
		}
		var showImage = GetControlsConfig("ShowImage-" + ControlID);


		$.map(arrData, function (row, i) {
			htmlBody += '<li class="p-2 pointer b-l-' + row.Color + ' b-l-w-5"  data-toggle="tooltip" data-placement="right"  title="' + row.CardNote + '"  onclick = "OnClickCardList(' + row.ID + ',this)" >';
			htmlBody += '   <div class="media">';
			if (row.Url?.length && showImage == "1") {
				htmlBody += '       <img class="d-flex mr-2" src="' + row.Url + '" width="40" alt="Avatar" onerror=this.src="/Files/Avatar/avatarnull.png">';
			}
			htmlBody += '       <div class="media-body">';
			htmlBody += '           <div class="d-flex flex-wrap justify-content-between">';
			htmlBody += '               <p class="notification-msg text-capitalize mb-0">' + row.Name + '</p>';
			htmlBody += '               <label class="badge badge-' + row.Color + '" >' + row.CardStatus + '</label>';
			htmlBody += '           </div>';
			htmlBody += '           <div class="d-flex flex-wrap justify-content-between">';
			htmlBody += '               <p class="text-muted mb-0">' + row.Title + '</p>';
			htmlBody += '           </div>';
			htmlBody += '       </div>';
			htmlBody += '   </div>';
			htmlBody += '</li>';
		});

		$('#CarlistUL-' + ControlID).html('');
		$('#CarlistUL-' + ControlID).append(htmlBody);
		$('.TotalRow-' + ControlID).each(function (i, item) {
			$(item).text(arrData.length);
		});
	}
}

function OnClickCardList(ID, element) {
	if (element !== undefined) {
		$('.liselect').removeClass("liselect");
		$(element).addClass("liselect");
	}
	var statusAddUpdate;
	if (ID === 0) {
		statusAddUpdate = 'ADD';
		SetStatusAddUpdate(statusAddUpdate, 0);
	}
	else {
		statusAddUpdate = 'EDIT';
		ShowLoadingOnControl('PreLoad');
		SetStatusAddUpdate(statusAddUpdate, 1);
	}
	$('#ID').val(ID);
	var FormCode = $('#FormCode').val();
	var SSID = $('#FSessionID').val();

	jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&ID=" + ID;
	console.log('OpenLink');
	console.log(jsDataOnclick);

	$.ajax({
		type: "POST",
		url: "/Categories/CateAddupdate/GetDataByID",
		data: jsDataOnclick,
		success: function (response) {
			CheckResponse(response);
			CateResetControlAll();
			LoadDataToForm(response);
			SetStatusAddUpdate(statusAddUpdate, 0);
			HideLoadingOnControl();
		},
		error: function (response) {
			HideLoadingOnControl();
			notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
		}
	});
	$("#box-right").removeClass('d-none');
	$("#AddUpdateActionDelete").removeClass('d-none');
}


function LoadDataListsFromAjax(FormCode, FormID, ControlID, isRenderHeader, listType, Pattern, JsonData, ServiceUrl) {
	ShowLoadingOnControl(ControlID, 'Table');
	var form = $('#' + FormID);
	var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
	var formData = form.serialize();
	disabledListControl.attr('disabled', 'disabled');
	var arrC = GetControlsConfig('ColumnHeaderConfig' + ControlID);
	var arrColumns = [];
	if (typeof (arrC) == "string" && arrC.length > 0) {
		console.log(arrC);
		arrColumns = JSON.parse(arrC);
	}
	else {
		arrColumns = arrC;
	}
	formData += "&ReportCode=" + FormCode;
	formData += "&ServiceUrl=" + ServiceUrl;
	console.log(formData);
	if (listType == "ItemsDetail" && Pattern?.indexOf("JsonDataList") >= 0) {
		if (typeof (JsonData) == "string" && (JsonData == "" || JsonData == null)) JsonData = "[]";
		SetControlsConfig('list-' + ControlID, JsonData);

		RenderItemsDetailFromJsonTable(FormCode, JsonData, isRenderHeader, arrColumns, ControlID);
		HideLoadingOnControl(ControlID);
	}
	else if (Pattern?.indexOf("JsonDataList") >= 0) {
		if (typeof (JsonData) == "string" && (JsonData == "" || JsonData == null))
			JsonData = "[]";

		SetControlsConfig('list-' + ControlID, JsonData);
		if (Pattern.indexOf("JsonDataListAjax") >= 0) {
			console.log("JsonDataListAjax");
			loadDataAjax();
		}
		//else if (JsonData == "[]" ) {
		//	loadDataAjax();
		//}
		else {
			RenderDataListFromJsonTable(FormCode, JsonData, isRenderHeader, arrColumns, ControlID);
		}
		HideLoadingOnControl(ControlID);
	}
	else if (Pattern == "JsonDataEdit") {
		if (typeof (JsonData) == "string" && (JsonData == "" || JsonData == null)) JsonData = "[]";
		SetControlsConfig('list-' + ControlID, JsonData);

		RenderDataListFromJsonTable(FormCode, JsonData, isRenderHeader, arrColumns, ControlID);
		HideLoadingOnControl(ControlID);
	}
	else {
		loadDataAjax();
	}

	function loadDataAjax() {
		$.ajax({
			type: 'POST',
			url: '/Categories/SReports/GetDataReports',
			data: formData,
			success: function (response) {
				CheckResponse(response);
				//console.log(response);
				SetControlsConfig('list-' + ControlID, response);
				//console.log(GetControlsConfig('list-' + ControlID));
				if (listType == "SalesReports") {
					RenderDataReportFromJsonTable(FormCode, response, isRenderHeader, arrColumns, ControlID);
				}
				else if (listType == "DxDataGrid") {
					RenderDxDataGrid(FormCode, response, isRenderHeader, arrColumns, ControlID);
				}
				else if (listType == "ItemsDetail") {
					RenderItemsDetailFromJsonTable(FormCode, response, isRenderHeader, arrColumns, ControlID);
				}
				else {
					RenderDataListFromJsonTable(FormCode, response, isRenderHeader, arrColumns, ControlID);
				}
				HideLoadingOnControl(ControlID);
			},
			error: function (jqXHR, textStatus, errorThrown) {
				HideLoadingOnControl(ControlID);
				console.log(errorThrown);
			}
		});
	}

}

function RenderDxDataGrid(FormCode, jsData, isRenderHeader, arrColumnsConfig, ControlID, TriggerChange) {
	if (arrColumnsConfig === undefined || arrColumns === null) {
		var jsColumn = GetControlsConfig('ColumnHeaderConfig' + ControlID);
		if (jsColumn !== undefined) arrColumnsConfig = JSON.parse(jsColumn);
	}
	else jsColumn = arrColumnsConfig;
	console.log(ControlID);
	if (jsData !== null && jsData !== undefined) {
		var arrColumns = [];
		var arrData = [];
		if (typeof (jsData) == "string") {
			arrData = JSON.parse(jsData);
		}
		else arrData = jsData;

		if (arrData == undefined || arrData.length == 0) {
			$("#notif-" + ControlID).html('<h5 class="text-danger">No data avaiable</h5>');
			var grid = $("#dx-" + ControlID).dxDataGrid(
				{
					dataSource: []
				}).dxDataGrid('instance');
			grid.option('dataSource', []);

			return;
		}
		else {
			$("#notif-" + ControlID).html('');
		}

		if (arrData != undefined && arrData.length) {


			arrColumns = Object.keys(arrData[0]);
			var fixedColumns = GetControlsConfig('fixedColumns' + ControlID);
			var hideColumns = GetControlsConfig('hideColumns' + ControlID) ?? 0;
			var startNumberColumns = GetControlsConfig('startNumberColumns' + ControlID);
			if (arrData[0] != undefined && arrData[0].hideColumns) {
				hideColumns = arrData[0].hideColumns;
			}

			dxColumns = [];
			$.map(arrColumns, function (colID, i) {
				if (colID.indexOf("Display") >= 0) {

				}
				else {
					var colConfig = jsColumn?.find(m => m.Key == colID);
					var colSetting = replaceAll(colConfig?.OptionConfig, '\\"','"');
					if (colSetting) colSetting = JSON.parse(colSetting);
					var colName = colConfig?.Name ?? colID;
					if (colName != "RowType" && colName != "RowStyleClass" && colName != "hideColumns") {
						dxColumns.push({
							dataField: colID,
							caption: colName,
							dataType: "text",
							//width: 200,
							fixed: i < fixedColumns ? true : false,
							visible: i < hideColumns || hideColumns == 0 ? true : false,
							alignment: i >= startNumberColumns && startNumberColumns > 0 ? "right" : "left",
							headerFilter: {
								dataSource: function () {
									var dataFillter = [];
									for (var i = 0; i < arrData.length; i++) {
										var item = {
											text: (arrData[i][colID + "Display"] ?? arrData[i][colID]),
											value: arrData[i][colID]
										}
										if (!dataFillter[item]) {
											dataFillter.push(item);
										}
									}
									return dataFillter;
								}

							},
							allowSearch: true,
							cellTemplate: function (container, options) {
								var fieldData = options.data;
								var cls = "";

								if (colName.toLowerCase().indexOf('total') >= 0) {
									cls += " text-danger"
								}
								if (fieldData.RowType && fieldData.RowType == "GroupRow") {
									cls += " text-danger"
								}
								if (fieldData.RowType && fieldData.RowType == "GrandTotal") {
									cls += " text-danger font-weight-bold"
								}
								if (fieldData.RowStyleClass) {
									container.addClass(fieldData.RowStyleClass);
								}

								if (colSetting?.DataType == "number") {
									container.css("text-align", "right");

								}

								if (cls.length)
									$("<span>")
										.addClass(cls)
										//.text(fieldData[colItem])
										.html(fieldData[colID + "Display"] ?? fieldData[colID])
										.appendTo(container);
								else container.html(fieldData[colID + "Display"] ?? fieldData[colID]);
							}
						});
					}
				}
			});

			$("#dx-" + ControlID).dxDataGrid({
				dataSource: arrData,
				allowColumnReordering: true,
				allowColumnResizing: true,
				columnAutoWidth: true,
				showBorders: true,

				//searchPanel: {
				//	visible: true,
				//	width: 240,
				//	placeholder: "Search..."
				//},
				//searchPanel: {
				//	visible: true,
				//	highlightCaseSensitive: true
				//},
				headerFilter: {
					visible: true
				},
				//filterRow: {
				//	visible: true
				//},
				hoverStateEnabled: true,
				paging: {
					pageSize: 50
				},
				pager: {
					showPageSizeSelector: true,
					allowedPageSizes: [50, 100],
					showInfo: true
				},
				columnChooser: {
					enabled: true
				},
				columnFixing: {
					enabled: true
				},
				columns: dxColumns


			});

		}
	}

}

function RenderDataReportFromJsonTable(FormCode, jsData, isRenderHeader, arrColumnsConfig, ControlID, TriggerChange) {
	if (arrColumnsConfig === undefined || arrColumns === null) {
		var jsColumn = GetControlsConfig('ColumnHeaderConfig' + ControlID);
		if (jsColumn !== undefined) arrColumnsConfig = JSON.parse(jsColumn);
	}
	if (ControlID === "StepAction");
	console.log(ControlID);

	var isEdit = GetControlsConfig('isEdit' + ControlID);
	var isDelete = GetControlsConfig('isDelete' + ControlID);
	var isTableEdit = GetControlsConfig('isTableEdit' + ControlID);

	var htmlBody = '';
	var htmlHeader = '';

	htmlHeader += '<tr style="background:#0088cc; color:#fff;">';

	if (jsData !== null && jsData !== undefined) {
		var arrColumns = [];
		var arrData = [];
		if (typeof (jsData) == "string") {
			arrData = JSON.parse(jsData);
		}
		else arrData = jsData;
		if (arrData.length == 0) {
			$('#Table-' + ControlID + ' tbody').html('No Data Avaiable');
			return;
		}
		arrColumns = Object.keys(arrData[0]);

		//console.log(arrData);
		var SelectListAjaxArr = [];
		$.map(arrData, function (row, i) {
			var id = row.id === undefined ? row.ID : row.id;
			var htmlRow = "";
			var htmlcell = "";
			var classRow = "";

			if (row.RowType != undefined && row.RowType.length)	//GroupRow
			{
				htmlRow += '<tr class="' + row.RowType + ' dataitem-' + id + '">';
			}
			else {
				htmlRow += '<tr class="dataitem-' + id + '">';
			}
			//insert new rows
			$.map(arrColumns, function (col) {
				//find columns config
				var itemConfig = arrColumnsConfig.find(m => m.Key == col);
				$.map(row, function (ColVal, ColName) {
					if (ColName == "RowType") {
						//not render
					} else
						if (col === ColName && ColName.length) {
							var classCell = ""
							var valueCell = (ColVal == null ? "" : ColVal);
							if (itemConfig !== undefined && itemConfig.Pattern === "DimColumn" && ColVal !== undefined) {
								ColVal = String(ColVal);
								if (ColVal.indexOf("Grand Total") >= 0) {
									classRow += "bg-grand-total font-weight-bold ";
								} else if (ColVal.indexOf("Total") >= 0) {
									classRow += "bg-total font-weight-bold ";
								}
							}
							else {//fact column
								classCell += "text-right ";
							}
							if (itemConfig !== undefined && itemConfig.Pattern === "TotalColumn") {
								classCell += "text-primary ";
							}
							if (itemConfig !== undefined && itemConfig.Pattern === "TargetColumn") {
								classCell += "text-danger ";
							}
							if (itemConfig !== undefined && itemConfig.Pattern === "AchiveColumn") {
								classCell += "text-success font-weight-bold ";
							}

							htmlcell += '<td class="' + classRow + ' ' + classCell + '">';
							htmlcell += valueCell;
							htmlcell += '</td>';

							if (i === 0) {
								htmlHeader += '<td style="text-align: center;font-weight: bold">' + col + '</td>';
							}
						}
				});

				//if (col.Type === "ActionBtn") {
				//    htmlBody += '<td>';
				//    htmlBody += '   <div>';
				//    if (isEdit === "1") {
				//        htmlBody += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\');">';
				//        htmlBody += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
				//        htmlBody += '       </button>';
				//    }
				//    if (isDelete === "1") {
				//        htmlBody += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
				//        htmlBody += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
				//        htmlBody += '       </button>';
				//    }
				//    htmlBody += '   </div>';
				//    htmlBody += '</td>';
				//}
				//if (col.Type === "OpenModalForm") {
				//    htmlBody += '<td>';
				//    htmlBody += '   <div>';
				//    if (isEdit === "1") {
				//        htmlBody += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalForm(\'' + ControlID + '\', \'' + id + '\', \'edit\');">';
				//        htmlBody += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
				//        htmlBody += '       </button>';
				//    }
				//    //if (isDelete === "1") {
				//    //    htmlBody += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
				//    //    htmlBody += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
				//    //    htmlBody += '       </button>';
				//    //}
				//    htmlBody += '   </div>';
				//    htmlBody += '</td>';
				//}
			});
			//end insert
			htmlBody += htmlRow;
			htmlBody += htmlcell;
			htmlBody += '</tr>';
		});
		//if (isEdit || isDelete) {
		//    htmlHeader += '<td style="text-align: middle;font-weight: bold"><i class="fa fa-navicon"></i> </td>';
		//}
		htmlHeader += '</tr>';


		$('#Table-' + ControlID + ' thead').html('');
		$('#Table-' + ControlID + ' thead').append(htmlHeader);

		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(htmlBody);

		//$.each(SelectListAjaxArr, function () {
		//    SelectListToTableByClassName(this.ClassName, '-', this.DataSource, this.ColCode, this.ColName, this.Condition, 1, this.Type, this.Parten);
		//    $('.' + this.ClassName).on('change', function () {
		//        onHanderChangeDTL(this);
		//    });
		//});
		//$('.CheckBoxListEdit').on('change', function () {
		//    onHanderChangeDTL(this);
		//});

		//$('.CheckBoxListEdit').trigger('change');

		//$('.table-textedit-' + ControlID).on('change', function () {
		//    onHanderChangeDTL(this);
		//});
		//var select2item = $(".js-example-basic-multiple");
		//if (select2item.length)
		//    $(".js-example-basic-multiple").select2();
	}

	//ConvertConfigValueToKeyVal(ControlID);
	CountRows('Table-', ControlID);
}
function RenderItemsDetailFromJsonTable(FormCode, jsData, isRenderHeader, arrColumns, ControlID, TriggerChange) {
	console.log("RenderItemsDetailFromJsonTable");
	if (arrColumns === undefined || arrColumns === null) {
		var jsColumn = GetControlsConfig('ColumnHeaderConfig' + ControlID);
		if (typeof (jsColumn) == "string") arrColumns = JSON.parse(jsColumn);
		else arrColumns = jsColumn;
	}

	if (ControlID === "StepAction");
	console.log(ControlID);

	var isEdit = GetControlsConfig('isEdit' + ControlID);
	var isDelete = GetControlsConfig('isDelete' + ControlID);
	var isTableEdit = GetControlsConfig('isTableEdit' + ControlID);

	var htmlBody = '';
	var htmlHeader = '';
	htmlHeader += '<tr style="background:#0088cc; color:#fff;">';
	htmlHeader += '<th>#</th>';
	if (jsData !== null && jsData !== undefined) {
		var arrData = [];
		if (typeof (jsData) == "string") {
			try {
				arrData = JSON.parse(jsData);
			}
			catch (err) {
				ShowMessage('danger', 'Error:', jsData, 3000, '');
			}
		}
		else arrData = jsData;

		//console.log(arrData);
		var SelectListAjaxArr = [];
		$.map(arrData, function (row, i) {
			var id = row.id === undefined ? row.ID : row.id;
			if (row.RowType === "GroupRow") {
				htmlBody += '<tr class="GroupRow dataitem-' + id + '">';
				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
			}
			else {
				htmlBody += '<tr class="dataitem-' + id + '">';
				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
			}
			$.map(arrColumns, function (col) {
				var htmlRaw = "";
				$.map(row, function (ColVal, ColName) {
					if (col.Key === ColName && ColName.length) {
						//console.log(col.OptionConfig);
						if (ColName == "Note" || ColName == "VATAmount" || ColName == "Discount" || ColName == "Saler") {
							//not render
						}
						else if (ColName == "ItemsID") {
							htmlRaw += '<td class="v-align-left">';
							//htmlRaw += '	<div class="">';
							htmlRaw += '		<h6 data-toggle="tooltip" data-placement="top" title="Sản phẩm/Dịch vụ">' + (row[ColName + 'Display'] ? row[ColName + 'Display'] : ColVal) + '</h6>';
							//htmlRaw += '	</div>';
							//htmlRaw += '	<div class="">';
							htmlRaw += '		<span class="text-seconday font-italic" data-toggle="tooltip" data-placement="top" title="Nhân viên/Ghi chú">' + (row['SalerDisplay'] ? row["SalerDisplay"] : row["Note"]) + '</span>';
							//htmlRaw += '	</div>';
							htmlRaw += '</td>';
						}
						else if (ColName == "Amount") {
							htmlRaw += '<td class="v-align-left" >';
							htmlRaw += '	<div class="pointer" ' + (isEdit === "1" && row.IsLocked != 1 ? ' onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\',' + (i + 1) + ');"' : '') + '>';
							htmlRaw += '		<span class="d-inline-block t-c-green m-r-20 font-weight-bold text-success"><ins>' + ColVal + '</ins>&nbsp;<i  class="ti-new-window text-pink"/></span>';
							htmlRaw += '	</div>';
							//if (isEdit === "1" && row.IsLocked != 1) {

							//	htmlRaw += '       <a href="#" class="text-danger" onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\',' + (i + 1) + ');">';
							//	htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
							//	htmlRaw += '       </a>';
							//	<span class="d-inline-block t-c-green m-r-20"><ins>98%</ins></span> 
							//}
							htmlRaw += '</td>';

						}
						else if (row.RowType === "GroupRow") {
							if (col.Type === "TextBox") {
								htmlRaw += '<td class="v-align-left">';
								htmlRaw += ColVal;
								htmlRaw += '</td>';
							}
							else {
								htmlRaw += '<td/>';
							}
						}
						else
							if (col.EditOnList == "1" || col.EditOnList == "on" || col.EditOnList == "true") {
								if (col.Type === "CheckBox") {
									htmlRaw += '<td class="v-align-left" >';

									var dtIsCheck = String(ColVal).toLowerCase();
									if (ColName === "IsView")
										console.log(dtIsCheck);

									var isCheckData = "";
									if (dtIsCheck === "true" || dtIsCheck === "1" || dtIsCheck === "on")
										isCheckData = "Checked";
									else isCheckData = "";

									htmlRaw += '<div class="checkbox-fade fade-in-success m-0">';
									htmlRaw += '<label>';
									htmlRaw += '     <input type="checkbox" class="CheckBoxListEdit" id="' + ControlID + '-' + ColName + '-' + id + '" ' + isCheckData + '>';
									htmlRaw += '          <span class="cr">';
									htmlRaw += '              <i class="cr-icon fa fa-check"></i>';
									htmlRaw += '          </span>';
									htmlRaw += '  </label>';
									htmlRaw += ' </div>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "TextBox" && col.Pattern == "NumberUpDown") {
									htmlRaw += '<td class="tabledit-edit-mode" >';
									//htmlBody += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '     <div class="d-flex number-list-con">';
									htmlRaw += '        <input type="number" step="1" min="0" class="table-numberedit form-control text-danger number-list-input-' + ControlID + '" idtype="' + row.IDType + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '" disabled >';
									htmlRaw += '        <a href="#" class="btn btn-outline-primary btn-sm fa fa-plus-square number-list-up" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';
									htmlRaw += '        <a href="#" class="btn btn-outline-danger btn-sm fa fa-times number-list-reset" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';

									htmlRaw += '     </div>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "TextBox" && col.Pattern == "NumberOnly") {

									htmlRaw += '<td class="tabledit-edit-mode" >';
									htmlRaw += '     <div class="d-flex w-20">';
									htmlRaw += '        <input type="text" step="1" min="0" autonumber data-a-sep="," data-a-dec="." class="table-numberedit form-control ' + ControlID + '-' + ColName + ' text-danger text-right" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + replaceAll(ColVal, ',', '') + '">';
									htmlRaw += '     </div>';

									if (col.Key == "UnitPrice" && row["Discount"] != undefined) {
										htmlRaw += '    <div class="text-right">';
										htmlRaw += '		<p class="text-danger text-right">-' + row["Discount"] + '</p>';
										htmlRaw += '    </div>';
									}
									else if (col.Key == "VAT" && row["VATAmount"] != undefined) {
										htmlRaw += '    <div class="text-right">';
										htmlRaw += '		<p class="text-primary">' + row["VATAmount"] + '</p>';
										htmlRaw += '    </div>';
									}
									htmlRaw += '</td>';

								}
								else if (col.Type === "TextBox") {

									htmlRaw += '<td class="tabledit-edit-mode" >';
									htmlRaw += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectStatistic") {
									var OptionConfigArr = col.OptionConfig.split(',');
									htmlRaw += '<td class="v-align-left" >';
									console.log(ColVal);
									htmlRaw += '<select class="tabledit-input form-control input-sm" id="' + id + '">';
									$.each(OptionConfigArr, function () {
										var configItem = this.split(':');
										htmlRaw += '<option value="' + configItem[0] + '">' + configItem[1] + '</option>';
									});
									htmlRaw += '  </select>';

									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectListAjax") {
									console.log(col.DataSource);

									var condString = ValidateSelectConditionString(col.Condition);

									htmlRaw += '<td class="v-align-left" >';
									var className = 'tabledit-input form-control input-sm select-' + ControlID + '-' + ColName;
									console.log(ColVal);
									if (i === 0) {
										SelectListAjaxArr.push({
											ClassName: 'select-' + ControlID + '-' + ColName,
											ControlID: ControlID + '-' + ColName + '-' + id,
											DataSource: col.DataSource,
											ColCode: col.ColCode,
											ColName: col.ColName,
											ColVal: ColVal,
											Condition: condString,
											Type: col.Type,
											Parten: col.Parten
										});
									}

									htmlRaw += '<select class="' + className + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</select>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectMultiListAjax") {
									//console.log('SelectMultiListAjax');
									condString = ValidateSelectConditionString(col.Condition);
									htmlRaw += '<td>';
									className = 'js-example-basic-multiple select-' + ControlID + '-' + ColName;

									if (i === 0) {
										SelectListAjaxArr.push({
											ClassName: 'select-' + ControlID + '-' + ColName,
											ControlID: ControlID + '-' + ColName + '-' + id,
											DataSource: col.DataSource,
											ColCode: col.ColCode,
											ColName: col.ColName,
											ColVal: ColVal,
											Condition: condString,
											Type: col.Type,
											Parten: col.Parten
										});
									}
									htmlRaw += '<select class="' + className + '" multiple="multiple" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</select>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "Button" && col.Pattern === "OpenLink" && ColVal.length > 0) {
									var arrVal = ColVal.split(',');
									htmlRaw += '<td>';
									if (arrVal.length) {
										var linkVal = arrVal[0];
										var iconVal = arrVal.length > 1 ? arrVal[1] : "";
										htmlRaw += '<button type="button" class="btn btn-outline-primary btn-icon-text btn-sm" onclick="location.href=\'' + linkVal + '\';">';
										htmlRaw += '    <i class="' + iconVal + '"></i>';
										htmlRaw += '</button>';
									}
									htmlRaw += '</td>';
								}
							}
							else {
								if (col.Type === "CheckBox") {
									var isCheck = String(ColVal).toLowerCase();
									if (isCheck === "true" || isCheck === "1" || isCheck === "on") {
										htmlRaw += '<td class="v-align-left"><i class="fa fa-check-square-o"/></td>';
									}
									else {
										htmlRaw += '<td class="v-align-left"></td>';
									}
								}
								else if (row[ColName + 'Display'] !== undefined) {
									htmlRaw += '<td class="v-align-left" >';
									htmlRaw += row[ColName + 'Display'];
									htmlRaw += '</td>';
								}

								else {
									htmlRaw += '<td class="v-align-left" >';
									htmlRaw += ColVal;
									htmlRaw += '</td>';
								}
							}
						//

					}

				});

				if (col.Type === "ActionBtn") {
					htmlRaw += '<td>';
					htmlRaw += '   <div>';
					//if (isEdit === "1" && row.IsLocked != 1) {
					//	htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\',' + (i + 1) + ');">';
					//	htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
					//	htmlRaw += '       </button>';
					//}
					if (isDelete === "1" && row.IsLocked != 1) {
						htmlRaw += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
						htmlRaw += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
						htmlRaw += '       </button>';
					}
					if (row.IsLocked == 1) {
						htmlRaw += '<span><i class ="fa fa-lock text-success"/></span>';
					}
					//else if (isEdit != "1" & isDelete != "1" && row.IsLocked > 1) {
					//	htmlRaw += '<span><i class ="fa fa-user-plus text-danger"/></span>';
					//}
					htmlRaw += '   </div>';
					htmlRaw += '</td>';
				}

				if (i === 0 && col.Type != "ActionBtn" && col.Key != "Note" && col.Key != "Saler" && col.Key != "Discount" && col.Key != "Amount") {
					htmlHeader += '<th>' + col.Name + '</th>';
				}

				if (col.Type === "OpenModalForm") {
					htmlRaw += '<td>';
					htmlRaw += '   <div>';
					if (isEdit === "1") {
						htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalForm(\'' + ControlID + '\', \'' + id + '\', \'edit\');">';
						htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
						htmlRaw += '       </button>';
					}
					//if (isDelete === "1") {
					//    htmlBody += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
					//    htmlBody += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
					//    htmlBody += '       </button>';
					//}
					htmlRaw += '   </div>';
					htmlRaw += '</td>';
				}

				if (htmlRaw.length) {
					htmlBody += htmlRaw;
				}
				else if (col.Key != "Note" && col.Key != "Saler" && col.Key != "Discount" && col.Key != "VATAmount") {
					htmlBody += "<td></td>";
					//if (i === 0) {//kiểm tra kỹ lỗi phát sinh từ chỗ này.
					//	htmlHeader += '<th>' + col.Name + '</th>';
					//}
				}



			});

			htmlBody += '</tr>';
		});
		if (isEdit || isDelete) {
			htmlHeader += '<th><i class="fa fa-navicon"></i> </th>';
		}
		htmlHeader += '</tr>';

		if (isRenderHeader === 1 && arrData.length) {
			$('#Table-' + ControlID + ' thead').html('');
			$('#Table-' + ControlID + ' thead').append(htmlHeader);
		}
		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(htmlBody);

		$.each(SelectListAjaxArr, function () {
			SelectListToTableByClassName(this.ClassName, '-', this.DataSource, this.ColCode, this.ColName, this.Condition, 1, this.Type, this.Parten);
			$('.' + this.ClassName).on('change', function () {
				onHanderChangeDTL(this);
			});
		});
		$('.CheckBoxListEdit').on('change', function () {
			onHanderChangeDTL(this);
		});

		//$('.CheckBoxListEdit').trigger('change');

		$('.table-textedit-' + ControlID).on('change', function () {
			onHanderChangeDTL(this);
		});
		$('.table-numberedit').on('change', function () {
			onHanderChangeDTL(this);

			var arritem = this.id.split('-');
			var ControlID = arritem[0];
			var key = arritem[1];
			var id = arritem[2];
			OpenModalEditList(ControlID, id, '', null, 1);
			$("#" + ControlID + key).trigger("change");
			$("#" + ControlID + key).trigger("keyup");
			SaveDataModal(ControlID);

		});

		//$('select.tabledit-input').change(function () {
		//	var arritem = this.id.split('-');
		//	var ControlID = arritem[0];
		//	var key = arritem[1];
		//	var id = arritem[2];
		//	OpenModalEditList(ControlID, id, '', null, 1);
		//	SaveDataModal(ControlID);
		//});

		var select2item = $(".js-example-basic-multiple");
		if (select2item.length)
			$(".js-example-basic-multiple").select2();

		$('.number-list-up').on("click", function () {
			var ParentID = $(this).attr("parentid");
			var IDType = $(this).attr("idtype");
			console.log(ParentID);
			var idArr = ParentID.split('-');
			id = idArr[idArr.length - 1];
			//if ($('#' + ParentID).val() == 0) {
			GetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
			//}
		});
		$('.number-list-reset').on("click", function () {
			var ParentID = $(this).attr("parentid");
			var IDType = $(this).attr("idtype");
			console.log(ParentID);
			var idArr = ParentID.split('-');
			id = idArr[idArr.length - 1];
			//if ($('#' + ParentID).val() == 0) {
			ResetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
			//}
		});
		$(".table-numberedit").autoNumeric('init', { mDec: 0 });
	}


	var pattern = GetControlsConfig('Pattern' + ControlID);
	if (pattern?.indexOf('JsonDataList') >= 0) {
		$('#' + ControlID).val(jsData);
	}
	else if (pattern == 'JsonDataEdit') {
		ConvertConfigValueToKeyVal(ControlID);
	}
	else {
		ConvertConfigValueToKeyVal(ControlID);
	}

	CountRows('Table-', ControlID);
}
function RenderDataListFromJsonTable(FormCode, jsData, isRenderHeader, arrColumns, ControlID, TriggerChange) {
	if (arrColumns === undefined || arrColumns === null) {
		var jsColumn = GetControlsConfig('ColumnHeaderConfig' + ControlID);
		if (jsColumn !== undefined) arrColumns = JSON.parse(jsColumn);
	}
	if (ControlID === "StepAction");
	console.log(ControlID);

	var isEdit = GetControlsConfig('isEdit' + ControlID);
	var isDelete = GetControlsConfig('isDelete' + ControlID);
	var isTableEdit = GetControlsConfig('isTableEdit' + ControlID);

	var htmlBody = '';
	var htmlHeader = '';
	htmlHeader += '<tr class="fixed-header-primary" style="background:#0088cc; color:#fff;">';
	htmlHeader += '<th>#</th>';
	if (jsData !== null && jsData !== undefined) {
		var arrData = [];
		if (typeof (jsData) == "string") {
			try {
				arrData = JSON.parse(jsData);
			}
			catch (err) {
				ShowMessage('danger', 'Error:', jsData, 3000, '');
			}
		}
		else arrData = jsData;
		var arrViewImage = "png,jpg,jpeg,bmp";
		//console.log(arrData);
		var SelectListAjaxArr = [];
		$.map(arrData, function (row, i) {
			var id = row.id === undefined ? row.ID : row.id;
			if (row.RowType === "GroupRow") {
				htmlBody += '<tr class="GroupRow dataitem-' + id + '">';
				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
			}
			else {
				htmlBody += '<tr class="dataitem-' + id + '">';
				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
			}
			$.map(arrColumns, function (col) {
				var htmlRaw = "";
				$.map(row, function (ColVal, ColName) {
					if (col.Key === ColName && ColName.length) {
						//console.log(col.OptionConfig);
						if (row.RowType === "GroupRow") {
							if (col.Type === "TextBox") {
								htmlRaw += '<td class="v-align-left">';
								htmlRaw += ColVal;
								htmlRaw += '</td>';
							}
							else {
								htmlRaw += '<td/>';
							}
						}
						else
							if (col.EditOnList == "1" || col.EditOnList == "on" || col.EditOnList == "true") {
								if (col.Type === "CheckBox") {
									htmlRaw += '<td class="v-align-left" >';

									var dtIsCheck = String(ColVal).toLowerCase();
									if (ColName === "IsView")
										console.log(dtIsCheck);

									var isCheckData = "";
									if (dtIsCheck === "true" || dtIsCheck === "1" || dtIsCheck === "on")
										isCheckData = "Checked";
									else isCheckData = "";

									htmlRaw += '<div class="checkbox-fade fade-in-success m-0">';
									htmlRaw += '<label>';
									htmlRaw += '     <input type="checkbox" class="CheckBoxListEdit" id="' + ControlID + '-' + ColName + '-' + id + '" ' + isCheckData + '>';
									htmlRaw += '          <span class="cr">';
									htmlRaw += '              <i class="cr-icon fa fa-check"></i>';
									htmlRaw += '          </span>';
									htmlRaw += '  </label>';
									htmlRaw += ' </div>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "TextBox" && col.Pattern == "NumberUpDown") {
									htmlRaw += '<td class="tabledit-edit-mode" >';
									//htmlBody += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '     <div class="d-flex number-list-con">';
									htmlRaw += '        <input type="number" step="1" min="0" class="table-numberedit form-control text-danger number-list-input-' + ControlID + '" idtype="' + row.IDType + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '" disabled >';
									htmlRaw += '        <a href="#" class="btn btn-outline-primary btn-sm fa fa-plus-square number-list-up" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';
									htmlRaw += '        <a href="#" class="btn btn-outline-danger btn-sm fa fa-times number-list-reset" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';

									htmlRaw += '     </div>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "TextBox" && col.Pattern == "NumberOnly") {
									htmlRaw += '<td class="tabledit-edit-mode" >';
									htmlRaw += '     <div class="d-flex w-20">';
									htmlRaw += '        <input type="text" class="autonumber table-numberedit form-control text-danger" data-a-sep="," data-a-dec="." id="' + ControlID + '-' + ColName + '-' + id + '" value="' + replaceAll(ColVal, ',', '') + '">';
									//htmlRaw += '        <input type="text" class="form-control text-danger autonumber" data-a-sep="," data-a-dec="." id="@ControlID" name="@ControlID" value="@Value" >'

									htmlRaw += '     </div>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "TextBox") {

									htmlRaw += '<td class="tabledit-edit-mode" >';
									htmlRaw += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectStatistic") {
									var OptionConfigArr = col.OptionConfig.split(',');
									htmlRaw += '<td class="v-align-left" >';
									console.log(ColVal);
									htmlRaw += '<select class="tabledit-input form-control input-sm" id="' + id + '">';
									$.each(OptionConfigArr, function () {
										var configItem = this.split(':');
										htmlRaw += '<option value="' + configItem[0] + '">' + configItem[1] + '</option>';
									});
									htmlRaw += '  </select>';

									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectListAjax") {
									console.log(col.DataSource);

									var condString = ValidateSelectConditionString(col.Condition);

									htmlRaw += '<td class="v-align-left" >';
									var className = 'tabledit-input form-control input-sm select-' + ControlID + '-' + ColName;
									console.log(ColVal);
									if (i === 0) {
										SelectListAjaxArr.push({
											ClassName: 'select-' + ControlID + '-' + ColName,
											ControlID: ControlID + '-' + ColName + '-' + id,
											DataSource: col.DataSource,
											ColCode: col.ColCode,
											ColName: col.ColName,
											ColVal: ColVal,
											Condition: condString,
											Type: col.Type,
											Parten: col.Parten
										});
									}

									htmlRaw += '<select class="' + className + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</select>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "SelectMultiListAjax") {
									//console.log('SelectMultiListAjax');
									condString = ValidateSelectConditionString(col.Condition);
									htmlRaw += '<td>';
									className = 'js-example-basic-multiple select-' + ControlID + '-' + ColName;

									if (i === 0) {
										SelectListAjaxArr.push({
											ClassName: 'select-' + ControlID + '-' + ColName,
											ControlID: ControlID + '-' + ColName + '-' + id,
											DataSource: col.DataSource,
											ColCode: col.ColCode,
											ColName: col.ColName,
											ColVal: ColVal,
											Condition: condString,
											Type: col.Type,
											Parten: col.Parten
										});
									}
									htmlRaw += '<select class="' + className + '" multiple="multiple" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
									htmlRaw += '</select>';
									htmlRaw += '</td>';
								}
								else if (col.Type === "Button" && col.Pattern === "OpenLink" && ColVal.length > 0) {
									var arrVal = ColVal.split(',');
									htmlRaw += '<td>';
									if (arrVal.length) {
										var linkVal = arrVal[0];
										var iconVal = arrVal.length > 1 ? arrVal[1] : "";
										htmlRaw += '<button type="button" class="btn btn-outline-primary btn-icon-text btn-sm" onclick="location.href=\'' + linkVal + '\';">';
										htmlRaw += '    <i class="' + iconVal + '"></i>';
										htmlRaw += '</button>';
									}
									htmlRaw += '</td>';
								}
							}
							else {
								if (col.Type === "CheckBox") {
									var isCheck = String(ColVal).toLowerCase();
									if (isCheck === "true" || isCheck === "1" || isCheck === "on") {
										htmlRaw += '<td class="v-align-left"><i class="fa fa-check-square-o"/></td>';
									}
									else {
										htmlRaw += '<td class="v-align-left"></td>';
									}
								}
								else if (col.Type === "MultiFileUpload") {
									var jsFile = [];
									if (ColVal)
										var jsFile = JSON.parse(ColVal);

									htmlRaw += '<td class="v-align-left" >';
									$.map(jsFile, function (itemFile) {
										var pos = itemFile.Name.lastIndexOf(".");
										var check = itemFile.Name.substr(pos + 1).toLowerCase();
											 
										htmlRaw += '   <a href="' + itemFile.Val + '" target="_blank" class="download" FileID="' + i + '">';
										if (arrViewImage.indexOf(check) >= 0) {
											htmlRaw += '       <img width="60" src="' + itemFile.Val + '"></img> '
										}
										else if (check == 'pdf') {
											htmlRaw += '<i class="fa fa-file-pdf-o text-danger" data-toggle="tooltip" title="' + itemFile.Name + '"></i>';
										}
										else if (check.indexOf('doc') >= 0) {
											htmlRaw += '<i class="fa fa-file-word-o text-primary"></i>';
										}
										else {
											htmlRaw += '<i class="fa fa-file text-primary"></i>';
										}

										htmlRaw += '   </a>';
										   
									});

									htmlRaw += '</td>';
								}
								else if (row[ColName + 'Display'] !== undefined) {
									htmlRaw += '<td class="v-align-left" >';
									htmlRaw += row[ColName + 'Display'];
									htmlRaw += '</td>';
								}
								else if (col.Type == "DataReportEdit") {
									htmlRaw += '<td class="v-align-left" >';
									htmlRaw += '<i class="fa fa-check">' + JSON.parse(ColVal).length;
									htmlRaw += '</td>';
								}
								else {
									htmlRaw += '<td class="v-align-left" >';
									htmlRaw += ColVal;
									htmlRaw += '</td>';
								}
							}
						//

					}

				});

				if (col.Type === "ActionBtn") {
					htmlRaw += '<td>';
					htmlRaw += '   <div>';
					if (isEdit === "1" && row.IsLocked != 1) {
						htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\',' + (i + 1) + ');">';
						htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
						htmlRaw += '       </button>';
					}
					if (isDelete === "1" && row.IsLocked != 1) {
						htmlRaw += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
						htmlRaw += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
						htmlRaw += '       </button>';
					}
					if (row.IsLocked == 1) {
						htmlRaw += '<span><i class ="fa fa-lock text-success"/></span>';
					}
					else if (isEdit != "1" & isDelete != "1" && row.IsLocked > 1) {
						htmlRaw += '<span><i class ="fa fa-user-plus text-danger"/></span>';
					}
					htmlRaw += '   </div>';
					htmlRaw += '</td>';
				}

				if (i === 0 && col.Type != "ActionBtn") {
					htmlHeader += '<th>' + col.Name + '</th>';
				}

				if (col.Type === "OpenModalForm") {
					htmlRaw += '<td>';
					htmlRaw += '   <div>';
					if (isEdit === "1") {
						htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalForm(\'' + ControlID + '\', \'' + id + '\', \'edit\');">';
						htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
						htmlRaw += '       </button>';
					}
					//if (isDelete === "1") {
					//    htmlBody += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
					//    htmlBody += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
					//    htmlBody += '       </button>';
					//}
					htmlRaw += '   </div>';
					htmlRaw += '</td>';
				}

				if (htmlRaw.length) {
					htmlBody += htmlRaw;
				}
				else {
					htmlBody += "<td></td>";
					//if (i === 0) {//kiểm tra kỹ lỗi phát sinh từ chỗ này.
					//	htmlHeader += '<th>' + col.Name + '</th>';
					//}
				}
			    
			});

			htmlBody += '</tr>';
		});
		if (isEdit || isDelete) {
			htmlHeader += '<th><i class="fa fa-navicon"></i> </th>';
		}
		htmlHeader += '</tr>';
			 
		if (isRenderHeader === 1 && arrData.length) {
			$('#Table-' + ControlID + ' thead').html('');
			$('#Table-' + ControlID + ' thead').append(htmlHeader);
		}
		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(htmlBody);
		$.each(SelectListAjaxArr, function () {
			SelectListToTableByClassName(this.ClassName, '-', this.DataSource, this.ColCode, this.ColName, this.Condition, 1, this.Type, this.Parten);
			$('.' + this.ClassName).on('change', function () {
				onHanderChangeDTL(this);
			});
		});
		$('.CheckBoxListEdit').on('change', function () {
			onHanderChangeDTL(this);
		});

		if ($("input.autonumber").length) {
			$("input.autonumber").autoNumeric('init', { mDec: 0 });
		}
		//$('.CheckBoxListEdit').trigger('change');

		$('.table-textedit-' + ControlID).on('change', function () {
			onHanderChangeDTL(this);
		});
		$('.table-numberedit').on('change', function () {
			onHanderChangeDTL(this);
		});

		var select2item = $(".js-example-basic-multiple");
		if (select2item.length)
			$(".js-example-basic-multiple").select2();

		$('.number-list-up').on("click", function () {
			var ParentID = $(this).attr("parentid");
			var IDType = $(this).attr("idtype");
			console.log(ParentID);
			var idArr = ParentID.split('-');
			id = idArr[idArr.length - 1];
			//if ($('#' + ParentID).val() == 0) {
			GetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
			//}
		});
		$('.number-list-reset').on("click", function () {
			var ParentID = $(this).attr("parentid");
			var IDType = $(this).attr("idtype");
			console.log(ParentID);
			var idArr = ParentID.split('-');
			id = idArr[idArr.length - 1];
			//if ($('#' + ParentID).val() == 0) {
			ResetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
			//}
		});


	}

	var pattern = GetControlsConfig('Pattern' + ControlID);
	if (pattern?.indexOf('JsonDataList')>=0) {
		$('#' + ControlID).val(jsData);
	}
	else if (pattern == 'JsonDataEdit') {
		ConvertConfigValueToKeyVal(ControlID);
	}
	else {
		ConvertConfigValueToKeyVal(ControlID);
	}

	CountRows('Table-', ControlID);
}

//function RenderDataListFromJsonTable(FormCode, jsData, isRenderHeader, arrColumns, ControlID, TriggerChange) {
//	if (arrColumns === undefined || arrColumns === null) {
//		var jsColumn = GetControlsConfig('ColumnHeaderConfig' + ControlID);
//		if (typeof (jsColumn) == "string") arrColumns = JSON.parse(jsColumn);
//		else arrColumns = jsColumn;
//	}
//	if (ControlID === "StepAction");
//	console.log(ControlID);

//	var isEdit = GetControlsConfig('isEdit' + ControlID);
//	var isDelete = GetControlsConfig('isDelete' + ControlID);
//	var isTableEdit = GetControlsConfig('isTableEdit' + ControlID);

//	var htmlBody = '';
//	var htmlHeader = '';

//	htmlHeader += '<tr class="fixed-header-primary" style="background:#0088cc; color:#fff;">';
//	htmlHeader += '<th>#</th>';
//	if (jsData !== null && jsData !== undefined) {
//		var arrData = [];
//		if (typeof (jsData) == "string") {
//			try {
//				arrData = JSON.parse(jsData);
//			}
//			catch (err) {
//				ShowMessage('danger', 'Error:', jsData, 3000, '');
//			}
//		}
//		else arrData = jsData;
//		var arrViewImage = "png,jpg,jpeg,bmp";
//		//console.log(arrData);
//		var SelectListAjaxArr = [];
//		$.map(arrData, function (row, i) {
//			var id = row.id === undefined ? row.ID : row.id;
//			if (row.RowType === "GroupRow") {
//				htmlBody += '<tr class="GroupRow dataitem-' + id + '">';
//				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
//			}
//			else {
//				htmlBody += '<tr class="dataitem-' + id + '">';
//				htmlBody += '<td class="v-align-left">' + (i + 1) + '</td>';
//			}
//			$.map(arrColumns, function (col) {
//				var htmlRaw = "";
//				$.map(row, function (ColVal, ColName) {
//					if (col.Key === ColName && ColName.length) {
//						//console.log(col.OptionConfig);
//						if (row.RowType === "GroupRow") {
//							if (col.Type === "TextBox") {
//								htmlRaw += '<td class="v-align-left">';
//								htmlRaw += ColVal;
//								htmlRaw += '</td>';
//							}
//							else {
//								htmlRaw += '<td/>';
//							}
//						}
//						else
//							if (col.EditOnList == "1" || col.EditOnList == "on" || col.EditOnList == "true") {
//								if (col.Type === "CheckBox") {
//									htmlRaw += '<td class="v-align-left" >';

//									var dtIsCheck = String(ColVal).toLowerCase();
//									if (ColName === "IsView")
//										console.log(dtIsCheck);

//									var isCheckData = "";
//									if (dtIsCheck === "true" || dtIsCheck === "1" || dtIsCheck === "on")
//										isCheckData = "Checked";
//									else isCheckData = "";

//									htmlRaw += '<div class="checkbox-fade fade-in-success m-0">';
//									htmlRaw += '<label>';
//									htmlRaw += '     <input type="checkbox" class="CheckBoxListEdit" id="' + ControlID + '-' + ColName + '-' + id + '" ' + isCheckData + '>';
//									htmlRaw += '          <span class="cr">';
//									htmlRaw += '              <i class="cr-icon fa fa-check"></i>';
//									htmlRaw += '          </span>';
//									htmlRaw += '  </label>';
//									htmlRaw += ' </div>';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "TextBox" && col.Pattern == "NumberUpDown") {
//									htmlRaw += '<td class="tabledit-edit-mode" >';
//									//htmlBody += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
//									htmlRaw += '     <div class="d-flex number-list-con">';
//									htmlRaw += '        <input type="number" step="1" min="0" class="table-numberedit form-control text-danger number-list-input-' + ControlID + '" idtype="' + row.IDType + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '" disabled >';
//									htmlRaw += '        <a href="#" class="btn btn-outline-primary btn-sm fa fa-plus-square number-list-up" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';
//									htmlRaw += '        <a href="#" class="btn btn-outline-danger btn-sm fa fa-times number-list-reset" parentid="' + ControlID + '-' + ColName + '-' + id + '" idtype="' + row.IDType + '"></a>';

//									htmlRaw += '     </div>';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "TextBox" && col.Pattern == "NumberOnly") {
//									htmlRaw += '<td class="tabledit-edit-mode" >';
//									htmlRaw += '     <div class="d-flex w-20">';
//									htmlRaw += '        <input type="number" step="1" min="0" class="table-numberedit form-control text-danger ' + ControlID + '-' + ColName + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
//									htmlRaw += '     </div>';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "TextBox") {

//									htmlRaw += '<td class="tabledit-edit-mode" >';
//									htmlRaw += '     <input type="text" class="tabledit-input form-control input-sm table-textedit-' + ControlID + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "SelectStatistic") {
//									var OptionConfigArr = col.OptionConfig.split(',');
//									htmlRaw += '<td class="v-align-left" >';
//									console.log(ColVal);
//									htmlRaw += '<select class="tabledit-input form-control input-sm" id="' + id + '">';
//									$.each(OptionConfigArr, function () {
//										var configItem = this.split(':');
//										htmlRaw += '<option value="' + configItem[0] + '">' + configItem[1] + '</option>';
//									});
//									htmlRaw += '  </select>';

//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "SelectListAjax") {
//									console.log(col.DataSource);

//									var condString = ValidateSelectConditionString(col.Condition);

//									htmlRaw += '<td class="v-align-left" >';
//									var className = 'tabledit-input form-control input-sm select-' + ControlID + '-' + ColName;
//									console.log(ColVal);
//									if (i === 0) {
//										SelectListAjaxArr.push({
//											ClassName: 'select-' + ControlID + '-' + ColName,
//											ControlID: ControlID + '-' + ColName + '-' + id,
//											DataSource: col.DataSource,
//											ColCode: col.ColCode,
//											ColName: col.ColName,
//											ColVal: ColVal,
//											Condition: condString,
//											Type: col.Type,
//											Parten: col.Parten
//										});
//									}

//									htmlRaw += '<select class="' + className + '" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
//									htmlRaw += '</select>';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "SelectMultiListAjax") {
//									//console.log('SelectMultiListAjax');
//									condString = ValidateSelectConditionString(col.Condition);
//									htmlRaw += '<td>';
//									className = 'js-example-basic-multiple select-' + ControlID + '-' + ColName;

//									if (i === 0) {
//										SelectListAjaxArr.push({
//											ClassName: 'select-' + ControlID + '-' + ColName,
//											ControlID: ControlID + '-' + ColName + '-' + id,
//											DataSource: col.DataSource,
//											ColCode: col.ColCode,
//											ColName: col.ColName,
//											ColVal: ColVal,
//											Condition: condString,
//											Type: col.Type,
//											Parten: col.Parten
//										});
//									}
//									htmlRaw += '<select class="' + className + '" multiple="multiple" id="' + ControlID + '-' + ColName + '-' + id + '" value="' + ColVal + '">';
//									htmlRaw += '</select>';
//									htmlRaw += '</td>';
//								}
//								else if (col.Type === "Button" && col.Pattern === "OpenLink" && ColVal.length > 0) {
//									var arrVal = ColVal.split(',');
//									htmlRaw += '<td>';
//									if (arrVal.length) {
//										var linkVal = arrVal[0];
//										var iconVal = arrVal.length > 1 ? arrVal[1] : "";
//										htmlRaw += '<button type="button" class="btn btn-outline-primary btn-icon-text btn-sm" onclick="location.href=\'' + linkVal + '\';">';
//										htmlRaw += '    <i class="' + iconVal + '"></i>';
//										htmlRaw += '</button>';
//									}
//									htmlRaw += '</td>';
//								}
//							}
//							else {
//								if (col.Type === "CheckBox") {
//									var isCheck = String(ColVal).toLowerCase();
//									if (isCheck === "true" || isCheck === "1" || isCheck === "on") {
//										htmlRaw += '<td class="v-align-left"><i class="fa fa-check-square-o"/></td>';
//									}
//									else {
//										htmlRaw += '<td class="v-align-left"></td>';
//									}
//								}
//								else if (col.Type === "MultiFileUpload") {
//									var jsFile = [];
//									if (ColVal)
//										var jsFile = JSON.parse(ColVal);

//									htmlRaw += '<td class="v-align-left" >';
//									$.map(jsFile, function (itemFile) {
//										var pos = itemFile.Name.lastIndexOf(".");
//										var check = itemFile.Name.substr(pos + 1).toLowerCase();



//										htmlRaw += '   <a href="' + itemFile.Val + '" target="_blank" class="download" FileID="' + i + '">';
//										if (arrViewImage.indexOf(check) >= 0) {
//											htmlRaw += '       <img width="60" src="' + itemFile.Val + '"></img> '
//										}
//										else if (check == 'pdf') {
//											htmlRaw += '<i class="fa fa-file-pdf-o text-danger" data-toggle="tooltip" title="' + itemFile.Name + '"></i>';
//										}
//										else if (check.indexOf('doc') >= 0) {
//											htmlRaw += '<i class="fa fa-file-word-o text-primary"></i>';
//										}
//										else {
//											htmlRaw += '<i class="fa fa-file text-primary"></i>';
//										}

//										htmlRaw += '   </a>';


//									});

//									htmlRaw += '</td>';
//								}
//								else if (row[ColName + 'Display'] !== undefined) {
//									htmlRaw += '<td class="v-align-left" >';
//									htmlRaw += row[ColName + 'Display'];
//									htmlRaw += '</td>';
//								}
//								else if (col.Type == "DataReportEdit") {
//									//htmlRaw += '<td class="v-align-left" >';
//									//htmlRaw += '</td>';
//								}
//								else {
//									htmlRaw += '<td class="v-align-left" >';
//									htmlRaw += ColVal;
//									htmlRaw += '</td>';
//								}
//							}
//						//

//					}

//				});

//				if (col.Type === "ActionBtn") {
//					htmlRaw += '<td>';
//					htmlRaw += '   <div>';
//					if (isEdit === "1" && row.IsLocked != 1) {
//						htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalEditList(\'' + ControlID + '\', \'' + id + '\', \'edit\',' + (i + 1) + ');">';
//						htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
//						htmlRaw += '       </button>';
//					}
//					if (isDelete === "1" && row.IsLocked != 1) {
//						htmlRaw += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
//						htmlRaw += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
//						htmlRaw += '       </button>';
//					}
//					if (row.IsLocked == 1) {
//						htmlRaw += '<span><i class ="fa fa-lock text-success"/></span>';
//					}
//					else if (isEdit != "1" & isDelete != "1" && row.IsLocked > 1) {
//						htmlRaw += '<span><i class ="fa fa-user-plus text-danger"/></span>';
//					}
//					htmlRaw += '   </div>';
//					htmlRaw += '</td>';
//				}

//				if (i === 0 && col.Type != "ActionBtn" && col.Type != "DataReportEdit") {
//					htmlHeader += '<th>' + col.Name + '</th>';
//				}

//				if (col.Type === "OpenModalForm") {
//					htmlRaw += '<td>';
//					htmlRaw += '   <div>';
//					if (isEdit === "1") {
//						htmlRaw += '       <button type="button" class="btn btn-outline-warning btn-icon-text btn-sm" onclick="OpenModalForm(\'' + ControlID + '\', \'' + id + '\', \'edit\');">';
//						htmlRaw += '           <i class="fa fa-edit" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Edit"></i>';
//						htmlRaw += '       </button>';
//					}
//					//if (isDelete === "1") {
//					//    htmlBody += '       <button type="button" class="btn btn-outline-danger btn-icon-text btn-sm" onclick="DeleteItem(\'' + ControlID + '\', \'' + id + '\');">';
//					//    htmlBody += '           <i class="fa fa-trash" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="Delete"></i>';
//					//    htmlBody += '       </button>';
//					//}
//					htmlRaw += '   </div>';
//					htmlRaw += '</td>';
//				}

//				if (htmlRaw.length) {
//					htmlBody += htmlRaw;
//				}
//				else if (col.Type != "DataReportEdit") {
//					htmlBody += "<td></td>";
//					//if (i === 0) {//kiểm tra kỹ lỗi phát sinh từ chỗ này.
//					//	htmlHeader += '<th>' + col.Name + '</th>';
//					//}
//				}

//			});

//			htmlBody += '</tr>';
//		});
//		if (isEdit || isDelete) {
//			htmlHeader += '<th><i class="fa fa-navicon"></i> </th>';
//		}
//		htmlHeader += '</tr>';

//		if (isRenderHeader === 1 && arrData.length) {
//			$('#Table-' + ControlID + ' thead').html('');
//			$('#Table-' + ControlID + ' thead').append(htmlHeader);
//		}
//		$('#Table-' + ControlID + ' tbody').html('');
//		$('#Table-' + ControlID + ' tbody').append(htmlBody);
//		$.each(SelectListAjaxArr, function () {
//			SelectListToTableByClassName(this.ClassName, '-', this.DataSource, this.ColCode, this.ColName, this.Condition, 1, this.Type, this.Parten);
//			$('.' + this.ClassName).on('change', function () {
//				onHanderChangeDTL(this);
//			});
//		});
//		$('.CheckBoxListEdit').on('change', function () {
//			onHanderChangeDTL(this);
//		});

//		//$('.CheckBoxListEdit').trigger('change');

//		$('.table-textedit-' + ControlID).on('change', function () {
//			onHanderChangeDTL(this);
//		});
//		$('.table-numberedit').on('change', function () {
//			onHanderChangeDTL(this);
//		});

//		var select2item = $(".js-example-basic-multiple");
//		if (select2item.length)
//			$(".js-example-basic-multiple").select2();

//		$('.number-list-up').on("click", function () {
//			var ParentID = $(this).attr("parentid");
//			var IDType = $(this).attr("idtype");
//			console.log(ParentID);
//			var idArr = ParentID.split('-');
//			id = idArr[idArr.length - 1];
//			//if ($('#' + ParentID).val() == 0) {
//			GetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
//			//}
//		});
//		$('.number-list-reset').on("click", function () {
//			var ParentID = $(this).attr("parentid");
//			var IDType = $(this).attr("idtype");
//			console.log(ParentID);
//			var idArr = ParentID.split('-');
//			id = idArr[idArr.length - 1];
//			//if ($('#' + ParentID).val() == 0) {
//			ResetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
//			//}
//		});


//	}

//	var pattern = GetControlsConfig('Pattern' + ControlID);
//	if (pattern?.indexOf('JsonDataList') >= 0) {
//		$('#' + ControlID).val(jsData);
//	}
//	else if (pattern == 'JsonDataEdit') {
//		ConvertConfigValueToKeyVal(ControlID);
//	}
//	else {
//		ConvertConfigValueToKeyVal(ControlID);
//	}

//	CountRows('Table-', ControlID);
//}

function GetNewID(ControlID, ParentID, ID, item, IDType) {
	var IDVal = $('#' + ParentID).val();
	if (IDVal > 0) return;
	var data = "FormCode=" + $("#FormCode").val() + "&ControlID=" + ControlID + "&ParentID=" + ParentID + "&ID=" + ID + "&IDType=" + IDType + "&IDVal=" + IDVal;
	$.ajax({
		type: "POST",
		url: '/Categories/ControlsBase/SelectNewID',
		data: data,
		success: function (response) {
			CheckResponse(response);
			console.log(response);
			if (typeof (response) == "string")
				response = JSON.parse(response);
			$('#' + ParentID).val(response[0].Code);
			$('#groupcode-' + ID).val(response[0].Name);
			onHanderChangeDTL(item);
			// ShowMessage('success', '!Thông báo', response[0].Code, 500, '');

			//if (response.length) {
			//    if (typeof (response) == "string")
			//        response = JSON.parse(response);
			//    if (Pattern == "KPIDoubleAchive" && response.length > 1) {

			//        $('#selectKPI-' + ControlID).text(response[0].Code);
			//        $('#selectKPIName-' + ControlID).text(response[0].Name);

			//        $('#selectKPI1-' + ControlID).text(response[1].Code);
			//        $('#selectKPIName1-' + ControlID).text(response[1].Name);
			//        $('#selectKPIVal1-' + ControlID).text(response[1].Val + '%');
			//        $('#selectKPIRate1-' + ControlID).attr("style", "width:" + response[1].Rate + "%");

			//        //$('#selectKPI2-' + ControlID).text(response[2].Code);
			//        //$('#selectKPIName2-' + ControlID).text(response[2].Name);
			//        //$('#selectKPIVal2-' + ControlID).text(response[2].Val + '%');
			//        //$('#selectKPIRate2-' + ControlID).attr("style", "width:" + response[2].Rate +"%");

			//    } else
			//        $('#selectKPI-' + ControlID).text(response[0].Code);
			//}
			//else {
			//    $('#selectKPI-' + ControlID).text("0");
			//}
		},
		error: function () {
			$('#selectKPI-' + ControlID).text("0");
		}
	});
}
function ResetNewID(ControlID, ParentID, ID, item, IDType) {
	var IDVal = $('#' + ParentID).val();
	if (IDVal > 0) {
		if (confirm('Bạn có muốn reset toàn bộ STT trên danh sách từ số: ' + IDVal)) {
			console.log('Confirm');
		} else {
			return;
		}
	}
	else {
		if (confirm('Bạn có muốn reset toàn bộ STT trên danh sách từ lớn nhất đã được cấp(Vui lòng mở lại sau khi xác nhận)')) {
			console.log('Confirm');
		} else {
			return;
		}
	}

	var data = "FormCode=" + $("#FormCode").val() + "&ControlID=" + ControlID + "&ParentID=" + ParentID + "&ID=" + ID + "&IDType=" + IDType + "&IDVal=" + IDVal;
	$.ajax({
		type: "POST",
		url: '/Categories/ControlsBase/ResetNewID',
		data: data,
		success: function (response) {
			CheckResponse(response);
			console.log(response);
			if (typeof (response) == "string")
				response = JSON.parse(response);
			if (response[0] != undefined) {
				var ResetID = response[0].ResetID;
				if (ResetID == null || ResetID == undefined) {
					ResetID = $('#' + ParentID).val();
				}
				if (ResetID > 0) {
					$('.number-list-input-' + ControlID).each(function () {
						if ($(this).val() >= ResetID && $(this).attr('idtype') == IDType) {
							$(this).val(0);
							onHanderChangeDTL(this);
						}
					});
				}
				else {
					CloseModalForm('modal-' + $('#FormCode').val());
				}
			}
		},
		error: function () {
			$('#selectKPI-' + ControlID).text("0");
		}
	});
}


function SelectListToTableByClassName(ClassName, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, ControlType, Patern) {
	var IsLoad = -1;
	IsLoad = window.IsLoadAjaxArr.indexOf(ClassName + Condition);
	console.log(IsLoad);
	if (IsLoad < 0 || IsLoad === undefined || IsReload === 1) {
		window.IsLoadAjaxArr += ClassName + Condition + ',';
		console.log(ClassName + Condition);
		$.ajax({
			type: "POST",
			url: '/Categories/ControlsBase/SelectTBListAjax',
			data: "DataSource=" + DataSource + "&cc=" + ColCode + "&cn=" + ColName + "&cd=" + Condition + "&Action=" + Action,
			success: function (response) {
				CheckResponse(response);
				$('.' + ClassName).find('option').remove().end();
				//var newOption = '<option value="-">-Select-</option>';
				var newOption = '';
				$.map(response, function (item) {
					newOption += '<option value="' + item.Code + '">' + item.Name + '</option>';
				});
				//console.log($('.' + ClassName));
				$('.' + ClassName).append(newOption);
				$('.' + ClassName).each(function () {
					var arrData = $(this).attr("value").split(',');
					if ($(this).attr("multiple") === "multiple")
						$(this).val(arrData).trigger("change");
					else
						$(this).val(arrData[0]).trigger("change");
				});


			},
			error: function (jqXHR, textStatus, errorThrown) {
				console.log(errorThrown);
			}
		});
	} else {
		$('.' + ClassName).each(function () {
			var arrData = $(this).attr("value").split(',');
			if ($(this).attr("multiple") === "multiple")
				$(this).val(arrData).trigger("change");
			else
				$(this).val(arrData[0]).trigger("change");
		});
	}
}

var IsLoadAjaxArr = '';
//function SelectListToTable(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action) {
//    var IsLoad = -1;
//    IsLoad = window.IsLoadAjaxArr.indexOf(ControlID + Condition);
//    console.log(IsLoad);
//    if (IsLoad < 0 || IsLoad === undefined || IsReload === 1) {
//        window.IsLoadAjaxArr += ControlID + Condition + ',';
//        console.log(ControlID + Condition);
//        $.ajax({
//            type: "POST",
//            url: '/Categories/ControlsBase/SelectTBListAjax',
//            data: "DataSource=" + DataSource + "&cc=" + ColCode + "&cn=" + ColName + "&cd=" + Condition + "&Action=" + Action,
//            success: function (response) {
//                $('#' + ControlID).find('option').remove().end();
//                var newOption = '<option value="-">-Select-</option>';
//                $.map(response, function (item) {
//                    newOption += '<option value="' + item.Code + '" >' + item.Name + '</option>';
//                });
//                $('#' + ControlID).append(newOption);
//                $('#' + ControlID).val(Value).trigger('change');

//            }
//        });
//    }


//}

function GetControlValue(itemIn, id) {
	var item;
	if (typeof (itemIn) == "object" && itemIn.type == undefined) {
		item = itemIn[0];
	}
	else item = itemIn;
	var newItem = {};
	newItem.id = id;
	newItem.key = item.id;

	if (item.type === 'text' || item.type === "hidden") {
		newItem.key = item.id;
		newItem.val = item.value;
	}
	else if (item.type === 'checkbox') {
		if (String(item.checked) === "true" || String(item.checked) === "1" || String(item.checked) === "checked")
			newItem.val = "1";
		else newItem.val = "0";
	}
	else if (item.type === 'select-one') {
		newItem.val = item.value;
	}
	else if (item.type === 'select-multiple') {
		newItem.val = $(item).val().join(',');
	}
	return newItem;
}
function GetCellValue(item, i) {
	var newItem = { id: "", key: "", val: "" };
	var arrItem = item.id.split('-');
	newItem.key = arrItem[1];
	newItem.id = i;
	if (item.type === 'text') {
		if (arrItem[1].indexOf("Display") >= 0) {
			newItem.val = htmlEscape(item.value);
		}
		else newItem.val = item.value;
	}
	else if (item.type === 'number') {
		newItem.val = item.value;
	}
	else if (item.type === 'checkbox') {
		if (String(item.checked) === "true" || String(item.checked) === "1" || String(item.checked) === "checked")
			newItem.val = "1";
		else newItem.val = "0";
	}
	else if (item.type === 'select-one') {
		newItem.val = item.value;
	}
	else if (item.type === 'select-multiple') {
		newItem.val = $(item).val().join(',');
	}
	return newItem;
}

function GetControlCellValue(item) {
	var newItem = { id: "", key: "", val: "" };
	var arrItem = item.id.split('-');
	newItem.key = arrItem[1];
	newItem.id = arrItem[2];
	if (item.type === 'text') {
		newItem.val = item.value;
	}
	else if (item.type === 'checkbox') {
		if (String(item.checked) === "true" || String(item.checked) === "1" || String(item.checked) === "checked")
			newItem.val = "1";
		else newItem.val = "0";
	}
	else if (item.type === 'select-one') {
		newItem.val = item.value;
	}
	else if (item.type === 'select-multiple') {
		newItem.val = $(item).val().join(',');
	}
	return newItem;
}
function onHanderChangeDTL(element) {
	CommitDataToControlID(element);
}
function ConvertConfigValueToKeyVal(ControlID) {
	var jsString = GetControlsConfig('list-' + ControlID);
	if (jsString === undefined) return;
	var jsList = JSON.parse(jsString);
	var dataList = [];
	$.map(jsList, function (item, i) {
		$.map(item, function (val, key) {
			var id = i;
			if (item.id !== undefined) id = String(item.id);
			else if (item.ID !== undefined) id = String(item.ID);
			if (key !== 'id') {
				dataList.push({
					id: id,
					key: key,
					val: val
				});
			}
		});
	});
	console.log(dataList);

	$('#' + ControlID).val(JSON.stringify(dataList)).trigger('change');

}
function CommitDataToControlID(item) {
	var arritem = item.id.split('-');
	var ControlID = arritem[0];
	var key = arritem[1];
	var id = arritem[2];
	var controlDataOut = $('#' + ControlID).val();
	var pattern = GetControlsConfig('Pattern' + ControlID);

	if (pattern.indexOf("JsonDataList")>=0) {
		var jsFullList = [];
		var jsFullListData = GetControlsConfig('list-' + ControlID);
		if (jsFullListData !== undefined)
			jsFullList = JSON.parse(GetControlsConfig('list-' + ControlID));
		const rowid =
			jsFullList.findIndex(
				x => String(x.id) === id || String(x.ID) === id
			);
		if (rowid >= 0)
			jsFullList[rowid][key] = item.value;
		var jsString = JSON.stringify(jsFullList);
		console.log(jsFullList);
		$('#' + ControlID).val(JSON.stringify(jsFullList));
		SetControlsConfig('list-' + ControlID, jsString);
	}
	else {
		var jsDataListOut = [];
		if (controlDataOut !== undefined && controlDataOut !== "" && controlDataOut !== null) {
			jsDataListOut = JSON.parse(controlDataOut);
		}
		console.log(jsDataListOut);
		const index =
			jsDataListOut.findIndex(
				x => (String(x.id) === id || String(x.ID) === id) && x.key === key
			);
		var newObj = GetCellValue(item, id);
		if (index >= 0)
			jsDataListOut[index].val = newObj.val;
		else {
			jsDataListOut.push(newObj);
		}
		console.log(jsDataListOut);
		$('#' + ControlID).val(JSON.stringify(jsDataListOut));
		//////////////////////////////
		var jsFullList = [];
		var jsFullListData = GetControlsConfig('list-' + ControlID);
		if (jsFullListData !== undefined)
			jsFullList = JSON.parse(GetControlsConfig('list-' + ControlID));
		const rowid =
			jsFullList.findIndex(
				x => String(x.id) === id || String(x.ID) === id
			);
		if (rowid >= 0)
			jsFullList[rowid][key] = item.value;
		var jsString = JSON.stringify(jsFullList);
		console.log(jsFullList);
		SetControlsConfig('list-' + ControlID, jsString);
	}
	$('#' + ControlID).trigger("change");
}

//function CommitDataToControlID(item) {
//	var arritem = item.id.split('-');
//	var ControlID = arritem[0];
//	var key = arritem[1];
//	var id = arritem[2];
//	var controlDataOut = $('#' + ControlID).val();
//	var jsDataListOut = [];
//	if (controlDataOut !== undefined && controlDataOut !== "" && controlDataOut !== null) {
//		jsDataListOut = JSON.parse(controlDataOut);
//	}
//	console.log(jsDataListOut);
//	const index =
//		jsDataListOut.findIndex(
//			x => (String(x.id) === id || String(x.ID) === id) && x.key === key
//		);
//	var newObj = GetCellValue(item, id);
//	if (index >= 0)
//		jsDataListOut[index].val = newObj.val;
//	else {
//		jsDataListOut.push(newObj);
//	}
//	console.log(jsDataListOut);

//	$('#' + ControlID).val(JSON.stringify(jsDataListOut));
//	////////////////////////////////
//	var jsFullList = [];
//	var jsFullListData = GetControlsConfig('list-' + ControlID);
//	if (jsFullListData !== undefined)
//		jsFullList = JSON.parse(GetControlsConfig('list-' + ControlID));
//	const rowid =
//		jsFullList.findIndex(
//			x => String(x.id) === id || String(x.ID) === id
//		);
//	if (rowid >= 0)
//		jsFullList[rowid][key] = item.value;
//	var jsString = JSON.stringify(jsFullList);
//	console.log(jsFullList);
//	SetControlsConfig('list-' + ControlID, jsString);
//}
//function RenderDataListFromJson(el, jsData, arrColumns) {
//    el.html('');
//    var html = '';
//    if (jsData !== null) {
//        var arrData = JSON.parse(jsData);
//        //console.log(arrData);
//        $.map(arrData, function (row, i) {
//            html += '<tr class="dataitem-' + i + '">';
//            $.map(arrColumns, function (Title) {
//                html += '<td class="v-align-left">';
//                $.map(row, function (ColVal, ColName) {
//                    if (Title === ColName) {
//                        html += ColVal;
//                    }
//                });
//                html += '</td >';
//            });
//            html += '</tr >';
//        });
//        el.append(html);
//    }
//}

function LoadDataLists(FormCode, ControlID, Value) {//danh cho du lieu tren control
	var jsDatalists = [];
	var js = "";
	if (Value === undefined)
		js = $('#' + ControlID).val();
	else {
		js = Value;
		$('#' + ControlID).val(Value);
	}

	if (js !== "" && js !== undefined) {
		try {
			SetControlsConfig('list-' + ControlID, js);
			RenderDataListFromJsonTable(FormCode, js, 0, null, ControlID);
		}
		catch (e) {
			$('#' + ControlID).val('');
		}
	}
	else {
		$('#Table-' + ControlID + ' tbody').html('');
	}
}
function OpenModalEditList(ModalID, index, actionModal, RowID, IsHide) {
	if (IsHide != 1) {
		$('#modalAdd-' + ModalID).modal('show');
	}

	$('#ModalIndex-' + ModalID).val(index);
	$('#RowID-' + ModalID).val(RowID);

	if (index >= 0) {

		var jsDatalists = JSON.parse(GetControlsConfig('list-' + ModalID));
		const cindex =
			jsDatalists.findIndex(
				x => String(x.id) === index || String(x.ID) === index
			);

		LoadDataToObject(jsDatalists[cindex], ModalID, 'Modal');
	}
	if (index >= 0) {
		$('#lbModalAddUpdateReportEdit').text('Chỉnh sửa [' + index + ']');
	}
	else {
		$('#lbModalAddUpdateReportEdit').text('Thêm mới [' + index + ']');
	}

	if (actionModal.toLowerCase() === "isreloadmodal") {
		ResetDataObject(ModalID, 'Modal');
	}
}
function ResetDataObject(ObjectID, ObjectType) {// su dung reset data modal
	var arrControl = JSON.parse(GetControlsConfig('ColumnHeaderConfig' + ObjectID));
	$.map(arrControl, function (row) {
		var rowVal = "";
		if (row.Key.toLowerCase().indexOf("id") || row.Key.toLowerCase().indexOf("code") || row.Key.toLowerCase().indexOf("name")) {
			rowVal = null;
		}
		else rowVal = $('#' + ObjectID + row.Key).val();
		var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
		SetDataToObject(row.Type, row.Pattern, ObjectID + row.Key, rowVal, row.OptionConfig, valueDisplay);
		SetDisableControl(row.Type, row.Pattern, ObjectID + row.Key, row.Disable, '0');
	});
}
function LoadDataToObject(itemList, ObjectID, ObjectType) {// su dung load vao danh sach control
	var arrControl = GetControlsConfig('ColumnHeaderConfig' + ObjectID);
	SetControlsConfig("tmpLoadDataToObject", itemList);
	SetControlsConfig("tmpLoadDataToObjectID", ObjectID);

	if (typeof (arrControl) == "string") arrControl = JSON.parse(arrControl);

	$.map(arrControl, function (row) {
		$.map(itemList, function (itemVal, itemName) {
			if (ObjectType === 'Modal' && itemName === row.Key) {
				var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
				SetDataToObject(row.Type, row.Pattern, ObjectID + itemName, itemVal, row.OptionConfig, valueDisplay);
			}
		});
	});
}

function SaveDataModal(ModalID) {//dau vao
	var retVal = IsValidInput('modal-ControlList-' + ModalID);
	if (retVal === false) {
		return retVal;
	}
	var currentIndex = $('#ModalIndex-' + ModalID).val();
	var currentRowID = $('#RowID-' + ModalID).val();
	var rowData = {};
	var retfalse = false;
	//var configHeader = SetControlsConfig('ColumnHeaderConfig' + ModalID);
	//var configArr = [];
	//if (configHeader !== undefined) configArr = JSON.parse(configitem); 

	$('#modal-ControlList-' + ModalID + ' :input').each(function (i, item) {
		if (item.id !== "" && retfalse === false) {
			var retVal = CheckValidInput(item.id);
			if (retVal === false) retfalse = true;

			var itemConfig = [];
			var iConfig = GetControlsConfig(item.id);
			if (iConfig) itemConfig = JSON.parse(iConfig);

			if (itemConfig.Type === "SelectListData") {
				rowData[item.id.replace(ModalID, '')] = item.value;
				rowData[item.id.replace(ModalID, '') + 'Display'] = $('#Search-' + item.id).val();
			}
			else if (item.type === "select-one" && item.options[item.selectedIndex] !== undefined && item.options[item.selectedIndex].text !== undefined) {
				rowData[item.id.replace(ModalID, '')] = item.value;
				rowData[item.id.replace(ModalID, '') + 'Display'] = item.options[item.selectedIndex].text;
			}
			else if (item.type === "select-multiple" && $(item).val() !== undefined) {
				rowData[item.id.replace(ModalID, '')] = $(item).val().join(',');
				rowData[item.id.replace(ModalID, '') + 'Display'] = $(item).find("option:selected").toArray().map(item => item.text).join();
			}
			else if (itemConfig.Type === "SelectTree") {
				rowData[item.id.replace(ModalID, '')] = item.value;
				var t = $('#' + item.id).combotree('tree');	// get the tree object
				var n = t.tree('getSelected');		// get selected node
				rowData[item.id.replace(ModalID, '') + 'Display'] = (n !== null ? n.text : item.value);
			}
			else if (itemConfig.Type === "Button") {
				rowData[item.id.replace(ModalID, '')] = item.value;

				var icon = $('#modalChangeCalendar').find('button[id$=Status]').find('i')[0].className;
				var titleIcon = $('#modalChangeCalendar').find('button[id$=Status]').find('span')[0].textContent;
				var backgroundColor = $('#modalChangeCalendar').find('button[id$=Status]').css("background-color");
				var CalendarStatus = $('#modalChangeCalendar').find('button[id$=Status]')[0].innerHTML;
				var html = CalendarStatus;
				rowData[item.id.replace(ModalID, '') + 'Display'] = item.options[item.selectedIndex].text;

			}
			else if (item.type === "checkbox") {
				rowData[item.id.replace(ModalID, '')] = (item.checked === true ? "1" : "0");
			}
			else {
				rowData[item.id.replace(ModalID, '')] = item.value;
			}
		}
	});
	rowData.RowID = currentRowID;
	if (retfalse === false) {
		console.log('SaveDataModal');
		var jsDatalists = [];
		var jsList = GetControlsConfig('list-' + ModalID);
		if (jsList !== undefined && jsList !== "" && jsList !== null) {
			jsDatalists = JSON.parse(jsList);
		}
		if (currentIndex >= 0) {
			const index =
				jsDatalists.findIndex(
					x => String(x.id) == currentIndex ||
						String(x.ID) == currentIndex
				);
			rowData.id = index;
			jsDatalists[index] = rowData;
		}
		else {
			rowData.RowID = jsDatalists.length + 1;
			rowData.id = jsDatalists.length;
			jsDatalists.push(rowData);
		}
		var jsData = JSON.stringify(jsDatalists);
		SetControlsConfig('list-' + ModalID, jsData);
		var pattern = GetControlsConfig('Pattern' + ModalID);

		if (pattern?.indexOf('JsonDataList') >= 0) {
			$('#' + ModalID).val(jsData);
			$('#' + ModalID).trigger("change");
			//$('#' + ModalID).val(jsDatalists).trigger('change');	//save data
		}
		else {
			ConvertConfigValueToKeyVal(ModalID);   //convert and save data
		}
		var controlType = GetControlsConfig('ControlType' + ModalID);
		if (controlType == "ItemsDetail") {
			RenderItemsDetailFromJsonTable(null, jsData, 0, null, ModalID);
		}
		else {
			RenderDataListFromJsonTable(null, jsData, 0, null, ModalID);
		}
		$('#modalAdd-' + ModalID).modal('hide');
	}
}
function DeleteAllItem(ControlID) {
	var jsDatalists = [];
	var jsData = JSON.stringify(jsDatalists);
	SetControlsConfig('list-' + ControlID, jsData);
	ConvertConfigValueToKeyVal(ControlID);
	RenderDataListFromJsonTable(null, jsData, 0, null, ControlID);
}

function DeleteItem(ControlID, id) {
	var jsDatalists = JSON.parse(GetControlsConfig('list-' + ControlID));
	const index =
		jsDatalists.findIndex(
			x => String(x.id) === id || String(x.ID) === id
		);
	jsDatalists.splice(index, 1);
	var jsData = JSON.stringify(jsDatalists);
	SetControlsConfig('list-' + ControlID, jsData);
	ConvertConfigValueToKeyVal(ControlID);
	if (GetControlsConfig('ControlType' + ControlID) == "ItemsDetail") {
		RenderItemsDetailFromJsonTable(null, jsData, 0, null, ControlID);
	}
	else
		RenderDataListFromJsonTable(null, jsData, 0, null, ControlID);
}

function OpenLink(link) {
	location.href = link;
}


function CountRows(ListType, ControlID) {
	var count = $('#' + ListType + ControlID + ' tr').length;
	$('#TotalRow-' + ControlID).text(count);
}
function zoomPage() {
	$('#divFullScreen').toggleClass('fullscreen');
}
function SearchInTable(ControlID, e, key) {
	console.log('SearchInTable');
	if (key != undefined) {
		var searchText = key.toUpperCase();
		$.each($('#Table-' + ControlID + ' tbody').find("tr"), function () {
			if ($(this).text().toUpperCase().replace(/\s+/g, '').indexOf(searchText.replace(/\s+/g, '').toUpperCase()) == -1)
			{
				$(this).hide();
				$(this).removeClass("ishow");
			} 
			else {
				$(this).show();
				$(this).addClass("ishow");
			}
				
		});
		if (e != undefined && e.keyCode == 13) {
			var itemSelect = $('#Table-' + ControlID + ' tbody').find("tr.ishow")[0];
			if (itemSelect) {
				$(itemSelect).trigger("click");
				ClearSearchHeader(ControlID);
			}
		}
	}
	else if (e != undefined && e.keyCode == 13) {
		var searchText = $('#Search-' + ControlID).val().toUpperCase();
		$.each($('#Table-' + ControlID + ' tbody').find("tr"), function () {
			if ($(this).text().toUpperCase().replace(/\s+/g, '').indexOf(searchText.replace(/\s+/g, '').toUpperCase()) == -1)
			{
				$(this).hide();
				$(this).addClass("ishow");
			}
			else {
				$(this).show();
				$(this).addClass("ishow");
			}
		});
	}
	else if (e == undefined) {
		var searchText = $('#Search-' + ControlID).val().toUpperCase();
		$.each($('#Table-' + ControlID + ' tbody').find("tr"), function () {
			if (searchText == "")
			{
				$(this).show();
				$(this).addClass("ishow");
			}
			else if ($(this).text().toUpperCase().replace(/\s+/g, '').indexOf(searchText.replace(/\s+/g, '').toUpperCase()) == -1)
			{
				$(this).hide();
				$(this).removeClass("ishow");
			}
			else {
				$(this).show();
				$(this).addClass("ishow");
			}
		});
	}
}

function FillterInTable(ControlID, e, keysearch) {
	console.log('SearchInTable');
	if ((e != undefined && e.keyCode == 13) || e == undefined || keysearch != undefined) {

		var searchText = $('#Search-' + ControlID).val()?.toUpperCase() ?? keysearch;

		if (keysearch != undefined && keysearch.length)
			searchText = keysearch.toUpperCase();

		var listRowData = GetControlsConfig('html-' + ControlID);
		var listMatching100 = [];
		var countMatching = 0;
		$.each(listRowData, function (i, item) {
			if (item.toUpperCase().replace(/\s+/g, '').indexOf(searchText.replace(/\s+/g, '').toUpperCase()) >= 0) {
				if (listMatching100.length < 100) {
					listMatching100.push(item);
				}
				countMatching++;
			}
		});

		$('#Table-' + ControlID + ' tbody').html('');
		$('#Table-' + ControlID + ' tbody').append(listMatching100.join());

		$('#pagetotal-' + ControlID).val(parseInt((countMatching - countMatching % 100) / 100));
		$('#rowtotal-' + ControlID).val(countMatching);
		$("#pagetitle-" + ControlID).text("From " + 1 + " to 100 of " + (countMatching));

	}

}


function ShowThemeLoader(isShow) {
	if (isShow === 1) {
		$('.theme-loader').removeClass("d-none");
	}
	else {
		$('.theme-loader').addClass("d-none");
	}
}
function ReloadTableByRowID() {
	var FormCode = $("#FormCode").val();
	var SSID = $('#FSessionID').val();
	var ID = $('#modal-' + FormCode).find('#ID').val();
	var jsDataOnclick = "ReportCode=" + FormCode + "&SSID=" + SSID + "&ID=" + ID + "&SourceType=ModalForm";
	var RowID = $('#RowID').val();

	console.log(jsDataOnclick);
	$.ajax({
		type: "POST",
		url: '/Categories/SReports/GetDataReportsByID',
		data: jsDataOnclick,
		async: false,
		success: function (response) {
			CheckResponse(response);
			if (RowID >= 0 && response != undefined && response.length) {
				var jsList = JSON.parse(response);
				var data = jsList[0];

				var IsCheck = GetControlsConfig('ReportEdit-IsCheck');
				if (IsCheck == 1) {
					var html = '';
					if (data.IsCheck === '1') {
						html += '       <div class="border-checkbox-section m-0 p-0 ml-2">';
						html += '           <div class="checkbox-fade fade-in-primary m-0 p-0">';
						html += '               <label for="' + data.ID + '" class="m-0 p-0">';
						html += '                   <input type="checkbox" class="CheckCard" id="' + data.ID + '" value="1">';
						html += '                   <span class="cr m-0 p-0">';
						html += '                       <i class="cr-icon fa fa-check txt-primary"></i>';
						html += '                   </span>';
						html += '               </label>';
						html += '               </div>';
						html += '       </div>';
					}
					else if (data.IsCheck === '-1') {
						html += '       <div class="m-0 p-0 ml-2">';
						html += '           <i class="ti-na txt-primary"></i>';
						html += '       </div>';
					}
					else {
						html += '       <div class="m-0 p-0 ml-2">';
						html += '           <i class="fa fa-check-square-o txt-primary"></i>';
						html += '       </div>';
					}
					data.IsCheck = html;
				}

				var dt = $("#Table-" + FormCode).DataTable();
				//dt.row(RowID).data(tempRow).draw();
				dt.row(RowID).data(data);

			}
		},
		error: function (response) {
			console.log(response);
		}
	});
}
function LoadDataLargerListsFromAjax(FormCode, FormID, ControlID, jsColumnsDataLoad, IsEdit, fillterItems, fixedColumns, IsCheck, OpenModalType) {
	ShowLoadingOnControl('fillterTable', 'Table');
	if (OpenModalType == undefined) {
		OpenModalType = "OpenModalForm";
	}
	var form = $('#' + FormID);
	var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
	var formData = form.serialize();
	disabledListControl.attr('disabled', 'disabled');
	var arrC = GetControlsConfig('ColumnHeaderConfig' + ControlID);
	//if (arrC === undefined) arrC = $('#ColumnHeaderConfig' + ControlID).val();
	var arrColumns = JSON.parse(arrC);
	formData += "&ReportCode=" + FormCode;

	console.log(formData);
	var fillterList = [];
	var fixedColLeft = 0;
	var sizedWindowWidth = $(document).width();

	if (sizedWindowWidth < 700) fixedColLeft = 0;
	else if (fixedColumns != undefined && fixedColumns.length) fixedColLeft = Number(fixedColumns);
	var maxh = document.body.scrollHeight - 325;
	if (maxh < 346) maxh = 346;
	var scrollX = false;
	if (fixedColLeft > 0) {
		scrollX = true;
	}


	$.ajax({
		type: 'POST',
		url: '/Categories/SReports/GetDataReports',
		data: formData,
		success: function (response) {
			CheckResponse(response);
			var jsList = JSON.parse(jsColumnsDataLoad);

			$("#Table-" + ControlID).DataTable({
				data: JSON.parse(response),
				columns: jsList,
				stateSave: true,
				scrollY: maxh,
				scrollX: scrollX,
				destroy: true,
				scrollCollapse: true,
				fixedColumns: {
					leftColumns: fixedColLeft,
				},
				"createdRow": function (row, data, index) {
					if (IsEdit == 1) {
						var ele = $('td', row).eq(0);
						ele.addClass("text-primary pointer");
						if (OpenModalType == "OpenModalForm")
							ele.attr("onclick", 'OpenModalForm(\'' + ControlID + '\',\'' + data.ID + '\',\'ModalForm\', undefined, ' + index + ')');
						else
							ele.attr("onclick", 'OpenModalProcess(\'' + ControlID + '\',' + data.ID + ',\'' + data.ProcessStep + '\',undefined, ' + index + ' )');
						ele.append('<i class="fa fa-edit text-danger" ><i>');
					}

					if (IsCheck == 1) {
						var ele = $('td', row).eq(1);
						var checkVal = ele[0].textContent;
						var html = '';
						if (data.IsCheck === '1') {
							html += '       <div class="border-checkbox-section m-0 p-0 ml-2">';
							html += '           <div class="checkbox-fade fade-in-primary m-0 p-0">';
							html += '               <label for="' + data.ID + '" class="m-0 p-0">';
							html += '                   <input type="checkbox" class="CheckCard" id="' + data.ID + '" value="1">';
							html += '                   <span class="cr m-0 p-0">';
							html += '                       <i class="cr-icon fa fa-check txt-primary"></i>';
							html += '                   </span>';
							html += '               </label>';
							html += '               </div>';
							html += '       </div>';
						}
						else if (data.IsCheck === '-1') {
							html += '       <div class="m-0 p-0 ml-2">';
							html += '           <i class="ti-na txt-primary"></i>';
							html += '       </div>';
						}
						else {
							html += '       <div class="m-0 p-0 ml-2">';
							html += '           <i class="fa fa-check-square-o txt-primary"></i>';
							html += '       </div>';
						}
						ele.html("");
						ele.html(html);

					}

					if (data["RowStyleClass"] != undefined && data["RowStyleClass"].length) {
						var ele = $('td', row);
						ele.addClass(data["RowStyleClass"]);
					}
					if (fillterItems != undefined && fillterItems.length) {
						if (!fillterList[data[fillterItems]]) {
							fillterList[data[fillterItems]] = {};
							fillterList[data[fillterItems]].id = data[fillterItems];
							fillterList[data[fillterItems]].color = data["StatusColor"];
							fillterList[data[fillterItems]].value = 0;
						}
						fillterList[data[fillterItems]].value += 1;
					}
				},
				"initComplete": function (settings, json) {
					$('.number-list-up').on("click", function () {
						if (this.classList.contains("fa-plus-square")) {
							var ParentID = $(this).attr("parentid");
							var IDType = $(this).attr("idtype");
							$(this).removeClass("fa-plus-square");
							$(this).addClass("fa-check");
							$('#' + ParentID).attr("disabled", 'disabled');
							console.log(ParentID);
							var idArr = ParentID.split('-');
							id = idArr[idArr.length - 1];
							//if ($('#' + ParentID).val() == 0) {
							GetNewID(ControlID, ParentID, id, $('#' + ParentID)[0], IDType);
							//}
						}
					});
					var htmlFillterList = ''
					Object.entries(fillterList).map(function (item) {
						htmlFillterList += '<button class="btn btn-sm btn-round btn-' + item[1].color + ' mr-3 mb-2" onclick="FillterTableBy(\'' + ControlID + '\',\'' + item[1].id + '\')">' + item[1].id + '<span class="font-weight-bold">(' + item[1].value + ')</span></button>';
					});

					console.log(htmlFillterList);
					$('#fillterTable').html('');
					$('#fillterTable').append(htmlFillterList);

					$('.CheckCard').on("click", function () {
						$('#lbCheckAll').text("(" + $('.CheckCard:checkbox:checked').length + ")");
					});
				}
			});

		},
		timeout: 300000,
		error: function (jqXHR, textStatus, errorThrown) {
			//  HideLoadingOnControl();
			console.log(errorThrown);
			console.log(jqXHR);
			console.log(textStatus);
		}
	});


}

function CheckAllCard(item) {
	var isCheckAll = $('#CheckAllItem')[0].checked;
	if (isCheckAll === true || String(isCheckAll) === "1") {
		console.log('CheckAll' + isCheckAll);
		$('.CheckCard').map(function () {
			if ($(this).parent().is(':visible')) this.checked = true;
		})
		$('#lbCheckAll').text("(" + $('.CheckCard:checkbox:checked').length + ")");
	}
	else {
		console.log('un CheckAll' + isCheckAll);
		$('.CheckCard:checkbox:checked').map(function () {
			this.checked = false;
		})
		$('#lbCheckAll').text("(0)");
	}
}


function FillterTableBy(ControlID, FillText) {
	var table = $("#Table-" + ControlID).DataTable();
	table.search(FillText).draw();
}
var chartList = [];
function LoadChart(ControlID) {
	console.log("LoadChart");
	var charItem = chartList.find(m => m.ControlID == ControlID);
	if (charItem)
		LoadChartFromAjax(charItem.Chart, charItem.FormCode, charItem.FormID, charItem.ControlID, charItem.Pattern, charItem.jsChartAxisList, charItem.jsChartGraphList);
}
function LoadChartFromAjax(Chart, FormCode, FormID, ControlID, ReportType, jsChartAxisList, jsChartGraphList, OptionConfig) {
	var data = "";

	if (FormID) {
		var form = $('#' + FormID);
		var formData = form.serialize();
		data += "&FormCode=" + $("#FormCode").val();
		data += "&" + formData
		data += "&IsAllData=1";
		console.log(data);
	}
	else if (OptionConfig != undefined && OptionConfig.indexOf("IsAllData") >= 0) {
		var form = $('#CateAddUpdateForm');
		var formData = form.serialize();
		data += "&FormCode=" + $("#FormCode").val();
		data += "&" + formData
		data += "&IsAllData=1";
		console.log(data);
	}
	else {
		data += "&ID=" + ($("#ID").val() != undefined ? $("#ID").val() : "");
		data += "&DocumentID=" + ($("#DocumentID").val() != undefined ? $("#DocumentID").val() : "");
	}
	if ($("#ViewDataLink") != undefined)
		data += "&ViewDataLink=" + $("#ViewDataLink").val();
	data += "&ReportCode=" + FormCode;

	$.ajax({
		type: 'POST',
		url: '/Categories/SReports/GetDataReports',
		data: data,
		timeout: 32000,
		success: function (response) {
			CheckResponse(response);
			if (typeof (response) == "string") response = JSON.parse(response);
			if (ReportType == "PieChart") {
				var lPos = GetControlsConfig(ControlID + "-legend-position");
				if (!lPos) lPos = "right";
				if (response[0] && response[0].Note != undefined) {
					$("#" + ControlID + "-Note").text(response[0].Note);
				}

				var chart = AmCharts.makeChart(ControlID, {
					"type": "pie",
					"hideCredits": true,
					"theme": "light",
					"dataProvider": response,
					"colorField": "Color",
					"addClassNames": true,
					"legend": {
						"position": lPos,
						//"marginRight": 8,
						//"marginLeft": 8,
						"autoMargins": true
					},
					"allLabels": [
						{
							"y": "38%",
							"align": "center",
							"size": 15,
							"text": response[0]?.GroupCode ?? "",
							"color": "#555"
						},
						{
							"y": "46%",
							"align": "center",
							"size": 25,
							"bold": true,
							"text": response[0]?.GroupVal ?? "",
							"color": "#555"
						}
					],

					"defs": {
						"filter": [{
							"id": "shadow",
							"width": "130%",
							"height": "130%",
							"feOffset": {
								"result": "offOut",
								"in": "SourceAlpha",
								"dx": 0,
								"dy": 0
							},
							"feGaussianBlur": {
								"result": "blurOut",
								"in": "offOut",
								"stdDeviation": 5
							},
							"feBlend": {
								"in": "SourceGraphic",
								"in2": "blurOut",
								"mode": "normal"
							}
						}]
					},
					"valueField": "Val",
					"titleField": "Code",
					"color": "#555",
					"labelsEnabled": false,
					//"labelRadius":  -22,
					//"labelText": "[[value]]%",
					"pullOutRadius": 16,
					"innerRadius": "60%",
					//"outlineAlpha": 0.9,
					//"depth3D": 0,
					"balloonText": "[[title]]<br><span style='font-size:14px'><b>[[value]]</b> ([[percents]]%)</span>",
					//"angle": 0,
				});
				chart.addListener("init", handleInit);

				chart.addListener("rollOverSlice", function (e) {
					handleRollOver(e);
				});
				function handleInit() {
					chart.legend.addListener("rollOverItem", handleRollOver);
				}

				function handleRollOver(e) {
					var wedge = e.dataItem.wedge.node;
					wedge.parentNode.appendChild(wedge);
				}

			} else {
				Chart.dataProvider = response;
				Chart.validateData();
			}
		},
		error: function (jqXHR, textStatus, errorThrown) {
			$('#Chart-' + ControlID).html('<div class="m-3">' + errorThrown + '</div>');
		}
	});
}


function LoadDWFromAjax(FormCode, FormID, ControlID, Type, fieldsList) {
	ShowLoadingOnControl(ControlID, Type);

	var form = $('#' + FormID);
	var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
	var formData = form.serialize();
	disabledListControl.attr('disabled', 'disabled');
	//formData += '&Action=' + ActionCustom;

	formData += "&ReportCode=" + FormCode;
	console.log(formData);
	$.ajax({
		type: 'POST',
		url: '/Categories/SReports/GetDataReports',
		data: formData,
		success: function (response) {
			CheckResponse(response);
			if (Type === 'PivotDevX') {
				PivotDevX(ControlID, fieldsList, response);
			}
			HideLoadingOnControl(ControlID);

		},
		error: function (jqXHR, textStatus, errorThrown) {
			console.log(errorThrown);
			HideLoadingOnControl(ControlID);
		}
	});
}
function PivotDevX(ControlID, fieldsList, jsData) {
	if (typeof (jsData) == "string") {
		jsData = JSON.parse(jsData);
	}
	var pivotGrid = $("#" + ControlID).dxPivotGrid({
		allowExpandAll: true,
		allowSortingBySummary: true,
		allowSorting: true,
		allowFiltering: true,
		showBorders: true,
		theme: "Blue",
		fieldPanel: {
			showColumnFields: true,
			showDataFields: true,
			showFilterFields: true,
			showRowFields: true,
			allowFieldDragging: true,
			visible: true
		},
		fieldChooser: {
			height: 500
		},
		dataSource: {
			fields: fieldsList,
			store: jsData,
			retrieveFields: false
		},
		//onContextMenuPreparing: contextMenuPreparing,
		export: {
			enabled: true,
			fileName: "bps_pivotgrid",
			ignoreExcelErrors: true,
			proxyUrl: undefined
		},
		fieldPanel: {
			allowFieldDragging: true,
			showColumnFields: true,
			showDataFields: true,
			showFilterFields: true,
			showRowFields: true,
			texts: {
				columnFieldArea: "Drop Column Fields Here",
				dataFieldArea: "Drop Data Fields Here",
				filterFieldArea: "Drop Filter Fields Here",
				rowFieldArea: "Drop Row Fields Here"
			},
			visible: true
		},
		headerFilter: {
			allowSearch: true,
			height: 325,
			searchTimeout: NaN,
			showRelevantValues: true,
			texts: {
				cancel: "Cancel",
				emptyValue: "",
				ok: "Ok"
			},
			width: 252
		},
		stateStoring: {
			enabled: true,
			type: "localStorage",
			storageKey: "dx-widget-gallery-pivotgrid-storing" + ControlID
		},
		//height: 350,
		hideEmptySummaryCells: true,
		showBorders: true,
		showColumnGrandTotals: true,
		showColumnTotals: true,
		showRowGrandTotals: true,
		showRowTotals: true,
		showTotalsPrior: "none",
	}).dxPivotGrid("instance");

	function contextMenuPreparing(e) {
		var dataSource = e.component.getDataSource(),
			sourceField = e.field;

		if (sourceField) {
			if (!sourceField.groupName || sourceField.groupIndex === 0) {
				e.items.push({
					text: "Hide field",
					onItemClick: function () {
						var fieldIndex;
						if (sourceField.groupName) {
							fieldIndex = dataSource.getAreaFields(sourceField.area, true)[sourceField.areaIndex].index;
						} else {
							fieldIndex = sourceField.index;
						}

						dataSource.field(fieldIndex, {
							area: null
						});
						dataSource.load();
					}
				});
			}

			if (sourceField.dataType === "number") {
				var setSummaryType = function (args) {
					dataSource.field(sourceField.index, {
						summaryType: args.itemData.value
					});

					dataSource.load();
				},
					menuItems = [];

				e.items.push({ text: "Summary Type", items: menuItems });

				$.each(["Sum", "Avg", "Min", "Max"], function (_, summaryType) {
					var summaryTypeValue = summaryType.toLowerCase();

					menuItems.push({
						text: summaryType,
						value: summaryType.toLowerCase(),
						onItemClick: setSummaryType,
						selected: e.field.summaryType === summaryTypeValue
					});
				});
			}
		}

	}

}

$('#thunho').on("click", function (e) {


	console.log('thunho');
	$('#phongto').removeClass('d-none');
	$('#box-left').attr("style", "display: none !important");
	$('#box-right').css('padding-left', '25px');
	$('#box-right').addClass('col-md-12');
	DataTableReDraw();
})

$('#phongto').on("click", function (e) {
	var boxLeft = GetControlsConfig("box-left");
	var boxRight = GetControlsConfig("box-right");

	console.log('phongto');
	$('#box-left').attr("style", "display");
	$('#box-right').css('padding-left', 'unset');
	$('#box-right').removeClass('col-md-12');
	$('#box-right').addClass(boxRight);
	$('#phongto').addClass('d-none');
	$('#box-left').addClass(boxLeft);
	DataTableReDraw();
})

$('#mobile-collapse').on("click", function (e) {
	setTimeout(function () {
		console.log('mobile-collapse');
		DataTableReDraw();
	}, 100);
})

function DataTableReDraw() {
	try {
		var formcode = $("#FormCode").val();
		var table = $('#Table-' + formcode).DataTable();
		table.columns.adjust().draw();
	}
	catch (err) {

	}
}

$('.searchbox-fillter').on("click", function () {
	var id = this.id.split('-')[1];

	if (this.className.indexOf('ti-search') >= 0) {
		var filltertext = $(this).parent().find('input').val();
		if (filltertext) {
			SearchInTable(id, undefined);
			$(this).removeClass('ti-search text-primary');
			$(this).addClass('ti-close text-danger');
		}
	}
	else {
		ClearSelectData(id);
		SearchInTable(id, undefined);
		$(this).removeClass('ti-close text-danger');
		$(this).addClass('ti-search text-primary');
	}
});

function SearchSelectDataList(element, event) {
	var item = $(element).parent().find('.searchbox-fillter');
	var id = item[0].id.split('-')[1];
	var filltertext = $(item).parent().find('input').val();
	if ($(item).hasClass('ti-search') >= 0 && filltertext) {
		SearchInTable(id, undefined);
		$(item).removeClass('ti-search text-primary');
		$(item).addClass('ti-close text-danger');
		$(item).attr("title", "Xóa lựa chọn");
	}
	else {
		ClearSelectData(id);
		SearchInTable(id, undefined);
		$(item).removeClass('ti-close text-danger');
		$(item).addClass('ti-search text-primary');
		$(item).attr("title", "Tìm kiếm");
	}
}
function SearchSelectHeader(element, event, id) {
	var key = element.value;
	
	SearchInTable('fillter-'+id, event, key);
	$('#search-icon-' + id).removeClass('ti-search text-primary');
	$('#search-icon-' + id).addClass('ti-close text-danger');
	$('#search-icon-' + id).attr("title", "Xóa");
   
}
function ClearSearchHeader(id) {
	$('#Search-' + id).val('');
	SearchInTable('fillter-'+id, undefined, '');
	$('#search-icon-' + id).removeClass('ti-close text-danger');
	$('#search-icon-' + id).addClass('ti-search text-primary');
	$('#search-icon-' + id).attr("title", "Tìm kiếm");
}
  