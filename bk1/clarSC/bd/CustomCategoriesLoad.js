function SetControlsConfig(ControlID, jsValue) {
    if (typeof jsValue === "string") {
        jsValue = jsValue.replace(/&quot;/g, '"');
    }
    //else if (typeof jsValue === "string") {
    //    jsValue = JSON.stringify(jsValue);
    //}

    var lstConfig = [];
    if (window.lstControlConfig !== undefined) {
        lstConfig = JSON.parse(window.lstControlConfig);
    }
    $.each(lstConfig, function (index, item) {
        if (item !== undefined && item.ControlID === ControlID) {
            lstConfig.splice(index, 1);
        }
    });
    var newItem = {
        "ControlID": ControlID,
        "JConfig": jsValue
    };
    lstConfig.push(newItem);
    window.lstControlConfig = JSON.stringify(lstConfig);

}
function GetControlsConfig(ControlID) {
    var lstConfig = [];
    if (window.lstControlConfig !== undefined) {
        lstConfig = JSON.parse(window.lstControlConfig);
    }
    const ret = lstConfig.find(item => item.ControlID === ControlID);
    if (ret !== undefined)
        return ret.JConfig;
    return undefined;
}


$.fn.serializeObject = function () {
    var o = {};
    var a = this.serializeArray();
    $.each(a, function () {
        if (o[this.name]) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};


function SelectKPIData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Pattern, OptionConfig) {
    var data = "DataSource=" + DataSource + "&cc=" + ColCode + "&cn=" + ColName + "&cd=" + Condition + "&Action=" + Action;

    if (OptionConfig != undefined && OptionConfig.indexOf("IsAllData") >= 0) {
        var form = $('#CateAddUpdateForm');
        var formData = form.serialize();
        data += "&FormCode=" + $("#FormCode").val();
        data += "&" + formData
        data += "&IsAllData=1";
        console.log(data);
    }
    else {
        data += "&ID=" + $("#ID").val();
        data += "&DocumentID=" + $("#DocumentID").val();
    }
    if ($("#ViewDataLink") != undefined)
        data += "&ViewDataLink=" + $("#ViewDataLink").val();
    if (Value != null && Value != undefined && Value.length) {
        RenderSelectKPIData(ControlID, Pattern, Value);
    }
    else {
        $.ajax({
            type: "POST",
            url: '/Categories/ControlsBase/SelectKPIAjax',
            data: data,
            timeout: 9000,
            success: function (response) {
                RenderSelectKPIData(ControlID, Pattern, response);
            },
            error: function (jqXHR, textStatus, errorThrown) {
                $('#selectKPI-' + ControlID).text("ERR" + errorThrown);
            },
        });
    }

}
function RenderSelectKPIData(ControlID, Pattern, response) {
    CheckResponse(response);
    console.log(response);
    if (response.length) {
        if (typeof (response) == "string")
            response = JSON.parse(response);
        SetControlsConfig(ControlID, response);

        if (Pattern == "KPIDoubleAchive") {
            if (response[0] != undefined) {
                $('#selectKPI-' + ControlID).html(response[0].Code);
                $('#selectKPIName-' + ControlID).html(response[0].Name);
            }
            else {
                $('#selectKPI-' + ControlID).text(0);
            }
            if (response[1] != undefined) {
                $('#selectKPI1-' + ControlID).html(response[1].Code);
                $('#selectKPIName1-' + ControlID).html(response[1].Name);
                $('#selectKPIVal1-' + ControlID).text(response[1].Val + '%');
                $('#selectKPIRate1-' + ControlID).attr("style", "width:" + response[1].Rate + "%");
            }
            else {
                $('#selectKPI1-' + ControlID).text(0);
                $('#selectKPIVal1-' + ControlID).text('0 %');
                $('#selectKPIRate1-' + ControlID).attr("style", "width:0%");
            }
        }
        else if (Pattern == "KPITrippleAchive") {
            //$('#debug-' + ControlID).text(response[0].Rate > 90 ? 'bg-c-blue' : response[0].Rate > 80 ? 'bg-c-yellow' : 'bg-c-pink');
            //sleep(500);
            if (response[0] != undefined) {
                $('#selectKPICode-0-' + ControlID).text(response[0].Code);
                $('#selectKPIName-0-' + ControlID).text(response[0].Name);
                $('#selectKPIVal-0-' + ControlID).text(response[0].Val);
                $('#selectKPIVal-0-' + ControlID).addClass(response[0].Rate > 90 ? 'bg-c-blue' : response[0].Rate > 80 ? 'bg-c-yellow' : 'bg-c-pink');
                $('#selectKPIValDesc-0-' + ControlID).text(response[0].ValDesc);
                $('#selectKPIRate-0-' + ControlID).data('easyPieChart').update(response[0].Rate);
            } else {
                $('#selectKPIVal-0-' + ControlID).text(0);
                $('#selectKPICode-0-' + ControlID).text(0);
                $('#selectKPIRate-0-' + ControlID).data('easyPieChart').update(0);
            }

            if (response[1] != undefined) {
                $('#selectKPICode-1-' + ControlID).text(response[1].Code);
                $('#selectKPIName-1-' + ControlID).text(response[1].Name);
                $('#selectKPIVal-1-' + ControlID).text(response[1].Val);
                $('#selectKPIVal-1-' + ControlID).addClass(response[1].Rate > 90 ? 'bg-c-blue' : response[1].Rate > 80 ? 'bg-c-yellow' : 'bg-c-pink');
                $('#selectKPIValDesc-1-' + ControlID).text(response[1].ValDesc);
                $('#selectKPIRate-1-' + ControlID).data('easyPieChart').update(response[1].Rate);
            } else {
                $('#selectKPIVal-1-' + ControlID).text(0);
                $('#selectKPICode-1-' + ControlID).text(0);
                $('#selectKPIRate-1-' + ControlID).data('easyPieChart').update(0);
            }

            if (response[2] != undefined) {
                $('#selectKPICode-2-' + ControlID).text(response[2].Code);
                $('#selectKPIName-2-' + ControlID).text(response[2].Name);
                $('#selectKPIVal-2-' + ControlID).text(response[2].Val);
                $('#selectKPIVal-2-' + ControlID).addClass(response[2].Rate > 90 ? 'bg-c-blue' : response[2].Rate > 80 ? 'bg-c-yellow' : 'bg-c-pink');
                $('#selectKPIValDesc-2-' + ControlID).text(response[2].ValDesc);
                $('#selectKPIRate-2-' + ControlID).data('easyPieChart').update(response[2].Rate);
            }
            else {
                $('#selectKPIVal-2-' + ControlID).text(0);
                $('#selectKPICode-2-' + ControlID).text(0);
                $('#selectKPIRate-2-' + ControlID).data('easyPieChart').update(0);
            }


        }
        else if (Pattern == "KPITableStatus") {
            var html = '';

            $.map(response, function (item) {
                html += ' <div class="row">';
                html += '    <div class="col-9 col-md-12 col-lg-9">';
                html += '       <h6 class="mb-0">';
                html += '           <i class="' + item.Icon + '"></i>   ';
                html += '            <span>' + item.Name + '</span>';
                html += '        </h6>';
                html += '   </div>';
                html += '    <div class="col-3 col-md-12 col-lg-3">';
                html += '       <button onclick="window.location=\'' + (item.Url != undefined ? item.Url : "#") + '\'" class="btn ' + item.Color + ' btn-round float-right btn-browser btn-sm">';
                html += item.Val;
                html += '        </button>';
                html += '   </div>';

                html += '</div>';
            });
            $('#' + ControlID).html('');
            $('#' + ControlID).html(html);
        }
        else if (Pattern == "KPIPieChart") {
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
        }
        else if (Pattern == "SelectHTMLInfor") {
            var html = response[0].Title;
            $('#' + ControlID).html('');
            $('#' + ControlID).html(html);
        }
        else if (response[0] != undefined && response[0].Code != undefined) {
            $('#selectKPI-' + ControlID).text(response[0].Code);
            if (response[0].URL) {
                $('#selectKPIURL-' + ControlID).attr("onclick", "location.href='" + response[0].URL + "'")
            }
        }
        else {
            $('#selectKPI-' + ControlID).text(0);

        }
    }
    else {
        $('#selectKPI-' + ControlID).text("0");
    }
}

function SelectListData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Pattern, OptionConfig, ServiceUrl) {
    if (Value == null || Value == undefined || Value.length == 0) {
        var jsList = GetControlsConfig("tmpLoadDataToObject");
        var ObjectID = GetControlsConfig("tmpLoadDataToObjectID");
        if (ObjectID) {
            var key = replaceAll(ControlID, ObjectID, '');
            Value = jsList != undefined ? jsList[key] ?? null : null;
        }
    }

    if (GetControlsConfig(ControlID) === undefined || (Value && Value.length)) {
        Pattern = (Pattern === undefined || Pattern === "") ? "LoadOneTime" : Pattern;
        Type = (Type === undefined) ? "SelectListAjax" : Type;
        var configItem = {
            "ServiceUrl": ServiceUrl,
            "ControlID": ControlID,
            "Value": Value,
            "PlaceHolder": PlaceHolder,
            "DataSource": DataSource,
            "ColCode": ColCode,
            "ColName": ColName,
            "Condition": Condition,
            "IsReload": IsReload,
            "Pattern": Pattern,
            "OptionConfig": OptionConfig,
            "Action": Action,
            "Type": Type
        };
        SetControlsConfig(ControlID, JSON.stringify(configItem));
    }
    var IsLoad = -1;
    IsLoad = window.IsLoadAjaxArr.indexOf(',' + ControlID + Condition + ',');
    console.log(IsLoad);


    if (IsLoad < 0 || IsLoad === undefined || IsReload === 1) {
        window.IsLoadAjaxArr += ',' + ControlID + Condition + ',';
        console.log(ControlID);
        Condition = ValidateSelectConditionString(Condition);
        var condString = "";
        if (Condition === undefined || Condition === null) return "";
        condString = Condition;
        LoadDataAjax(ControlID, Value, Type, DataSource, ColCode, ColName, Condition, Action, PlaceHolder, ServiceUrl);
    }
    else {
        if (Type === "SelectListData" && Value) {
            SelectListDataItemByValue(ControlID, Value);
        }
    }
}

function LoadDataAjax(ControlID, Value, Type, DataSource, ColCode, ColName, Condition, Action, PlaceHolder, ServiceUrl) {
    $.ajax({
        type: "POST",
        url: '/Categories/ControlsBase/' + Type,
        data: "DataSource=" + DataSource + "&cc=" + ColCode + "&cn=" + ColName + "&cd=" + Condition + "&Action=" + Action + "&ServiceUrl=" + ServiceUrl,
        success: function (response) {
            CheckResponse(response);
            SetControlsConfig('SelectData-' + ControlID, response);
            if (Type === "SelectTree") {
                RenderSelectTree(ControlID, response, Value, Type);
            }
            else if (Type === "SelectListData") {
                RenderSelectListData(ControlID, response, Value, Type);
            }
            else {
                RenderSelectList(ControlID, response, Value, Type, PlaceHolder);
            }
        }
    });
}

function RenderSelectTree(ControlID, response, Value, Type) {
    const arrData = response;
    let treeData = [];
    const findChild = (node, item, type) => {
        //if (type == 'root') {
        node = { id: item.ID, text: item.Name, type: type, state: 'open', children: [] }; // add object
        const reArr = arrData.filter(entry => entry.ParentID == node.id)
        if (reArr !== undefined && reArr.length) {
            reArr.forEach((fi) => {
                node.children.push(findChild(node, fi, 'child'));
            });
        }
        return node;
    };
    response.filter(a => a.ParentID == 0).forEach((entry) => {
        treeData.push(findChild(treeData, entry, 'root'));
    });
    var isDisable = false;
    if ($('#' + ControlID).attr("disable") !== undefined) isDisable = true;
    easyloader.load(['tree', 'menu', 'combotree'], function () {        // load the specified module
        $('#' + ControlID).combotree({
            disabled: isDisable,
            onChange: function (newValue, oldValue) {
                console.log('change select tree: ' + ControlID);
                var jsS = GetControlsConfig('SelectData-' + ControlID);
                if (jsS === undefined) return;
                var jsList = typeof jsS === "object" ? jsS : JSON.parse(jsS);
                const index =
                    jsList.findIndex(
                        x => (String(x.Code) === newValue)
                    );
                if (index >= 0 && jsList[index].DataInfor !== undefined && jsList[index].DataInfor !== null && jsList[index].DataInfor.length > 0) {
                    $("#selectlistinfor" + ControlID).html(jsList[index].DataInfor);
                    $("#selectlistinfor" + ControlID).removeClass('d-none');
                }
                ///find list config relate
                var listChild = FindChildConfig(ControlID);
                $.map(listChild, function (item) {
                    console.log('Reload tree select');
                    Value = $('#' + item).val();
                    ReLoadDataInitToObject(item, Value);
                });

            },
        });
        $('#' + ControlID).combotree('loadData', treeData);
        $('#' + ControlID).combotree('setValue', Value);

    });
}

function FindChildConfig(ControlID) {
    var lstConfig = [];
    if (window.lstControlConfig !== undefined) {
        lstConfig = JSON.parse(window.lstControlConfig);
    }
    var lstIDChild = [];
    $.map(lstConfig, function (item) {
        if (item.JConfig != undefined && item.JConfig != null && item.JConfig.length && item.JConfig.indexOf("GetParentRowID") > 0) {
            var con = JSON.parse(item.JConfig).Condition;
            if (con) {
                var arrConfigCon = con.split(":");
                if (arrConfigCon.length > 2 && arrConfigCon[2] === ControlID)
                    lstIDChild.push(item.ControlID);
            }
        }
    });
    return lstIDChild;
}

function RenderSelectListData(ControlID, response, Value, Type, PlaceHolder) {
    console.log('RenderSelectListData response undefined')
    var SelectDataMapping = GetControlsConfig('SelectDataMapping-' + ControlID);
    if (typeof (SelectDataMapping) == 'string') {
        SelectDataMapping = JSON.parse(SelectDataMapping);
    }

    var html = new String();
    if (Value && Value.length && (response == undefined || response.length == 0)) {
        return;
    }

    var jsList = [];
    if (typeof response == 'object') {
        jsList = response;
    }
    else jsList = JSON.parse(response);

    var html = "";
    var showImage = SelectDataMapping.showImage;
    if (SelectDataMapping.showImage) {
        $('#searchdiv-avatar-' + ControlID).removeClass('d-none');
    }

    $.map(jsList, function (row) {
        var htmlRaw = "";
        htmlRaw += '<tr rowid=' + row.RowID + '>';
        //1

        if (row.Avatar?.length && showImage) {
            htmlRaw += '<td>';
            htmlRaw += '<img class="d-flex mr-2" src="' + row.Avatar + '" width="40" alt="Avatar" onerror=this.src="/Files/Avatar/avatarnull.png">';
            htmlRaw += '</td>';
        }

        //2
        htmlRaw += '<td>';
        htmlRaw += '    <p class="text-primary mb-0">' + row.Name + '</p>';
        htmlRaw += '    <p class="text-truncate mb-0">' + row.NameDesc + '</p>';
        htmlRaw += '</td>';
        //3
        htmlRaw += '<td>';
        htmlRaw += '    <p class="text-danger mb-0 text-right">' + row.Title + '</p>';
        htmlRaw += '    <p class="text-truncate title-desc-s mb-0 text-right">' + row.TitleDesc + '</p>';
        htmlRaw += '</td>';

        htmlRaw += '</tr>';

        html += htmlRaw;

    });
    $('#search-result-' + ControlID).html(html);

    if (Value)
        SelectListDataItemByValue(ControlID, Value);


    $('#search-result-' + ControlID + ' tr').click(function (item) {
        SelectListDataItem(ControlID, $(this).attr('rowid'));
    });

    if (SelectDataMapping.SearchOnHeader) {

        $('#search-result-header').html(html);
        $('#search-result-header tr').click(function (item) {

            var existList = [];
            var id;
            if (SelectDataMapping.IsUpdateQtyExists) {
                existList = GetControlsConfig("list-" + SelectDataMapping.UpdateDataList);
                if (typeof (existList) == "string") {
                    existList = JSON.parse(existList);
                }
                var jsListSelectList = GetControlsConfig('SelectData-' + ControlID);
                if (typeof (jsListSelectList) == "string") {
                    jsListSelectList = JSON.parse(jsListSelectList);
                }
                var itemid = jsListSelectList.find(m => m.RowID == $(this).attr('rowid'))?.ID;
                if (itemid)
                    id = existList?.find(m => m[SelectDataMapping.UpdateCheckItemID] == itemid)?.id;

            }
            console.log("search header:" + id);
            if (id >= 0) {
                OpenModalEditList('OrderDetail', id, '', null, 1);

                var qty = parseFloat(replaceAll($("#" + SelectDataMapping.UpdateQtyID).val(), ',', '')) + 1;
                $("#" + SelectDataMapping.UpdateQtyID).val(qty);
                //$("#" + SelectDataMapping.UpdateQtyID).trigger("change");
                SelectListDataItem(ControlID, $(this).attr('rowid'));
                SaveDataModal(SelectDataMapping.UpdateDataList);
                $('#search-result-header').val();
            }
            else {
                OpenModalEditList('OrderDetail', -1, '', null, 1);
                $("#" + SelectDataMapping.UpdateQtyID).val(1);
                SelectListDataItem(ControlID, $(this).attr('rowid'));
                SaveDataModal(SelectDataMapping.UpdateDataList);
                $('#search-result-header').val();
            }
        });
    }
    if (SelectDataMapping.SearchOnTable) {
        var TableID = SelectDataMapping.TableID;
        $('#search-result-table-' + TableID).html();
        $('#search-result-table-' + TableID).html(html);
        $('#search-result-table-' + TableID + ' tr').click(function (item) {

            var existList = [];
            var id;
            if (SelectDataMapping.IsUpdateQtyExists) {
                existList = GetControlsConfig("list-" + SelectDataMapping.UpdateDataList);
                if (typeof (existList) == "string") {
                    existList = JSON.parse(existList);
                }
                var jsListSelectList = GetControlsConfig('SelectData-' + ControlID);
                if (typeof (jsListSelectList) == "string") {
                    jsListSelectList = JSON.parse(jsListSelectList);
                }
                var itemid = jsListSelectList.find(m => m.RowID == $(this).attr('rowid'))?.ID;
                if (itemid)
                    id = existList?.find(m => m[SelectDataMapping.UpdateCheckItemID] == itemid)?.id;

            }
            console.log("search header:" + id);
            if (id >= 0) {
                OpenModalEditList(TableID, id, '', null, 1);

                var qty = parseFloat(replaceAll($("#" + SelectDataMapping.UpdateQtyID).val(), ',', '')) + 1;
                $("#" + SelectDataMapping.UpdateQtyID).val(qty);
                //$("#" + SelectDataMapping.UpdateQtyID).trigger("change");
                SelectListDataItem(ControlID, $(this).attr('rowid'));
                SaveDataModal(SelectDataMapping.UpdateDataList);
                $('#search-result-header-' + TableID).val();
            }
            else {
                OpenModalEditList(TableID, -1, '', null, 1);
                $("#" + SelectDataMapping.UpdateQtyID).val(1);
                SelectListDataItem(ControlID, $(this).attr('rowid'));
                SaveDataModal(TableID);
                $('#search-result-header' + TableID).val();
            }
        });
    }
}
function SelectListDataItemByValue(ControlID, value) {
    var jsList = GetControlsConfig('SelectData-' + ControlID);
    var SelectDataMapping = GetControlsConfig('SelectDataMapping-' + ControlID);
    if (typeof SelectDataMapping == 'string') {
        SelectDataMapping = JSON.parse(SelectDataMapping);
    }
    if (typeof jsList == 'string') {
        jsList = JSON.parse(jsList);
    }
    var data = jsList.find(m => m.ID == value);

    $('#' + ControlID).val(data?.ID);

    if (data) {
        $('#Search-' + ControlID).val(data.Name);
        $('#searchbox-avatar-' + ControlID).attr('scr', data.Avatar);
        $('#searchbox-namedesc-' + ControlID).text(data.NameDesc);
        $('#searchbox-title-' + ControlID).text(data.Title);
        $('#searchbox-titledesc-' + ControlID).text(data.TitleDesc);

        $.map(SelectDataMapping.DataMapping, function (item) {
            $('#' + item.target).val(data[item.source]);
            $('#' + item.target).trigger("change");
            $('#' + item.target).trigger("keyup");
        });
    }
}

function SelectListDataItem(ControlID, id) {
    var jsList = GetControlsConfig('SelectData-' + ControlID);
    var SelectDataMapping = GetControlsConfig('SelectDataMapping-' + ControlID);
    if (typeof SelectDataMapping == 'string') {
        SelectDataMapping = JSON.parse(SelectDataMapping);
    }
    if (typeof jsList == 'string') {
        jsList = JSON.parse(jsList);
    }
    var data = jsList[Number(id) - 1];

    $('#' + ControlID).val(data.ID);
    $('#Search-' + ControlID).val(data.Name);

    $('#searchbox-avatar-' + ControlID).attr('src', data.Avatar);
    $('#searchbox-namedesc-' + ControlID).text(data.NameDesc);
    $('#searchbox-title-' + ControlID).text(data.Title);
    $('#searchbox-titledesc-' + ControlID).text(data.TitleDesc);

    $('#searchicon-' + ControlID).removeClass('ti-search');
    $('#searchicon-' + ControlID).addClass('ti-close text-danger');
    $('#searchicon-' + ControlID).attr('title', 'Xóa lựa chọn');

    $.map(SelectDataMapping.DataMapping, function (item) {
        console.log("select data mapping");
        if (item?.type) {
            SetDataToObject(item.type, item.pattern, item.target, data[item.source], null);
        }
        else {
            $('#' + item.target).val(data[item.source]);
            $('#' + item.target).trigger("change");
            $('#' + item.target).trigger("keyup");
        }
    });

}
function ClearSelectData(ControlID) {
    $('#' + ControlID).val('');
    $('#Search-' + ControlID).val('');
    $('#searchbox-avatar-' + ControlID).attr('src', '');
    $('#searchbox-namedesc-' + ControlID).text('-');
    $('#searchbox-title-' + ControlID).text('-');
    $('#searchbox-titledesc-' + ControlID).text('-');

}


function RenderSelectList(ControlID, response, Value, Type, PlaceHolder) {
    var html = new String();
    if (Value && Value.length && (response == undefined || response.length == 0)) {
        console.log('RenderSelectList response undefined')
        return;
    }

    var jsList = [];
    if (typeof response == 'object') {
        jsList = response;
    }
    else jsList = JSON.parse(response);

    var selectitem = [];
    selectitem.push({
        id: 0,
        text: ''
    });
    $.map(jsList, function (i) {
        selectitem.push({
            id: i.Code,
            text: i.Name
        });
    });

    $('#' + ControlID).select2({
        data: selectitem,
        value: Value,
        allowClear: true,
        placeholder: (PlaceHolder.length ? PlaceHolder : "Search..."),
        minimumInputLength: 3,
        language: {
            noResults: function () {
                return "Tìm(Search)...";
            }
        },
        query: function (q) {
            var pageSize,
                results,
                that = this;
            pageSize = 100; // or whatever pagesize
            results = [];
            if (q.term && q.term !== '') {
                // HEADS UP; for the _.filter function i use underscore (actually lo-dash) here
                results = selectitem.filter(m => m.text.toUpperCase().indexOf(q.term.toUpperCase()) >= 0);
            }
            //else if (Value && Value.length) {
            //    results = selectitem.filter(m => m.id == Value);
            //}
            else if ((q.term == undefined || q.term == '') && selectitem.length < pageSize) {
                //results = selectitem.slice(((q.page != undefined ? q.page : 1) - 1) * pageSize, (q.page != undefined ? q.page : 1) * pageSize)
                results = selectitem;
            }

            var p = (q.page != undefined ? q.page : 1);
            q.callback({
                results: results.slice((p - 1) * pageSize, p * pageSize),
                more: results.length >= p * pageSize,
            });

        }
    });

    if ($('#' + ControlID).attr("multiple") === "multiple" && Value.length > 0) {
        var arrData = Value.split(',');
        $('#' + ControlID).val(arrData).trigger("change");
    }
    else {

        $('select[id=' + ControlID + ']').val(Value).trigger("change");
    }

    //$.map(jsList, function (item) {
    //    html += '<option value="' + item.Code + '">' + item.Name + '</option>';
    //});
    //$('select[id=' + ControlID + ']').append(html);

    //if (!Value) {
    //    $('select[id=' + ControlID + ']').trigger('change');
    //}
    //else
    //    if ($('#' + ControlID).attr("multiple") === "multiple" && Value.length > 0) {
    //        var arrData = Value.split(',');
    //        $('#' + ControlID).val(arrData).trigger("change");
    //    }
    //    else {
    //        $('select[id=' + ControlID + ']').val(Value).trigger('change');
    //    }

}

function ValidateSelectConditionString(Condition) {
    if (Condition === undefined || Condition === null) return "";
    var arrConfigCon = Condition.split(":");
    var condString = '';
    if (arrConfigCon[0] === 'GetRowID') {
        condString = arrConfigCon[1] + "=\'" + row.ID + "\'";
    }
    else
        if (arrConfigCon[0] === 'GetParentRowID') {
            var strItem = GetControlValue($('#' + arrConfigCon[2]), 0).val;
            if ((strItem == undefined || strItem == null || strItem.length == 0) && $('#' + arrConfigCon[2])[0].type == "select-one") {
                //load tu config
                var jsParrent = GetControlsConfig(arrConfigCon[2]);
                if (jsParrent != undefined && jsParrent.length) {
                    var jsParrentObj = JSON.parse(jsParrent);
                    strItem = jsParrentObj.Value;

                }

            }
            if ($('#' + arrConfigCon[2])[0].type == "text") {
                strItem = replaceAll(strItem, ',', '');
            }
            if (strItem === '') { strItem = 'NULL'; }
            condString = arrConfigCon[1] + "=\'" + strItem + "\'";
        }
        else condString = Condition;
    return condString;
}

//#region textbox config
$(document).ready(function () {
    var maxLengs = $('input[maxlength]');
    if (maxLengs.val() !== undefined && maxLengs.val() !== "") {
        maxLengs.maxlength();
    }

    if ($('textarea.max-textarea').val() !== undefined) {
        $('textarea.max-textarea').maxlength();
    }
    // drop down config
    $(".dropdown-menu a").click(function () {
        var currentIcon = $(this).parents(".dropdown").find("i")[0].outerHTML;
        $(this).parents(".dropdown").find('.btn').html($(this).text());
        $(this).parents(".dropdown").find('.btn').val($(this).data('value'));
        console.log("dropdown");
        var newClass = $(this).attr('DisplayConfig');
        var ControlID = $(this).attr('ControlID');
        var dataValue = $(this).attr('data-value');
        var fxAction = $(this).attr('fxAction');
        if (ControlID !== undefined && ControlID.length) {
            $('#' + ControlID).val(dataValue);
            $('#dropdown-' + ControlID).val(dataValue);
            var newColor = $(this).css("background-color");
            var newIcon = $(this).find("i")[0].outerHTML;
            var newIconClass = $(this).find("i")[0].className;
            var newTitle = $(this).find("span")[0].outerHTML;
            var htmlValue = "";


            htmlValue += ((newIconClass != undefined && newIconClass.length) ? newIcon : currentIcon);
            htmlValue += newTitle;
            $('#dropdown-' + ControlID).html('');
            $('#dropdown-' + ControlID).html(htmlValue);
            $('#dropdown-' + ControlID).css("background-color", newColor);
            if (newClass != undefined && newClass.length && ControlID.length) {
                var oldClass = $('#dropdown-' + ControlID).attr('class');
                $('#dropdown-' + ControlID).removeClass(oldClass).addClass(newClass);
            }
        }
        if (fxAction !== undefined && fxAction.indexOf("(")) {
            var tmpFunc = new Function(fxAction);
            tmpFunc();
        }
    });
}
);

function HtmlEditorSetVal(ControlID, textstring) {
    $('#' + ControlID).summernote("code", textstring);
}

//#endregion

function stringToDate(_date, _format, _delimiter = '/') {
    var formatLowerCase = _format.toLowerCase();
    var formatItems = formatLowerCase.split(_delimiter);
    var dateItems = _date.split(_delimiter);
    var monthIndex = formatItems.indexOf("mm");
    var dayIndex = formatItems.indexOf("dd");
    var yearIndex = formatItems.indexOf("yyyy");
    var month = parseInt(dateItems[monthIndex]);
    month -= 1;

    var formatedDate = new Date(dateItems[yearIndex], month, dateItems[dayIndex]);
    var mm = formatedDate.getMonth() + 1; // getMonth() is zero-based
    var dd = formatedDate.getDate();

    return [formatedDate.getFullYear(),
    (mm > 9 ? '' : '0') + mm,
    (dd > 9 ? '' : '0') + dd
    ].join('/');
}

function ObjectRadioSet(ObjectName, ObjectValue) {
    var val;
    if (ObjectValue === "True") val = '1';
    else if (ObjectValue === "on") val = '1';
    else if (ObjectValue === true) val = '1';
    else if (ObjectValue === "1") val = '1';
    else if (ObjectValue === "False") val = '0';
    else if (ObjectValue === "off") val = '0';
    else if (ObjectValue === false) val = '0';
    else if (ObjectValue === "0") val = '0';
    else val = '0';

    var radios = document.getElementsByName(ObjectName);
    for (var j = 0; j < radios.length; j++) {
        if (radios[j].value == val) {
            radios[j].checked = true;
        }
        else radios[j].checked = false;
    }

}

function ObjectCheckBoxSet(ObjecName, ObjectValue) {
    var val;
    console.log('ObjectCheckBoxSet');
    console.log(ObjectValue);
    ObjectValue = (ObjectValue === undefined || ObjectValue === null ? "0" : String(ObjectValue).toLocaleLowerCase());
    var items = document.getElementsByName(ObjecName);
    var stringCheck = 'on,true,1';
    if (items[0] != undefined) {
        if (stringCheck.indexOf(ObjectValue) >= 0 && ObjectValue) {
            items[0].checked = true;
        }
        else { items[0].checked = false; }
    }
    $('#' + ObjecName).trigger("change");
}
function ObjectCheckGroupSet(ControlID, ObjectValue) {
    console.log('ObjectCheckGroupSet');
    console.log(ObjectValue);
    var objArr = ObjectValue.split(',');
    $('#' + ControlID).val(ObjectValue);
    var checkall = $('#CheckAllItem-' + ControlID);
    if (checkall != undefined && checkall[0] != undefined)
        checkall[0].checked = false;

    $("#CheckGroup-" + ControlID + " input[type=checkbox]").each(function () {
        if (ObjectValue.indexOf($(this).val()) >= 0 && ObjectValue.length > 0 && $(this).val().length > 0) {
            this.checked = true;
        }
        else this.checked = false;
    });
    ShowItemCondition(ControlID, ObjectValue);
}
function ObjectCheckGroupAddEventOnClick(ControlID) {
    $("#CheckGroup-" + ControlID + " input[type=checkbox]").change(function () {
        var arrData = [];
        $("#CheckGroup-" + ControlID + " input[type=checkbox]:checked").each(function () {
            arrData.push($(this).val());
        });
        $("#" + ControlID).val(arrData.join(','));
        $("#CheckAllCount-" + ControlID).text('(' + arrData.length + ')');
        ShowItemCondition(ControlID, arrData.join(','));
    });
}

function ObjectCheckGroupSetCheckAll(ControlID, IsCheckAll) {
    console.log('ObjectCheckGroupSetCheckAll');
    var arrData = [];
    if (IsCheckAll == true) {

        $("#CheckGroup-" + ControlID + " input[type=checkbox]").each(function () {
            this.checked = true;
            arrData.push($(this).val());
        });
        $("#" + ControlID).val(arrData.join(','));
        $("#CheckAllCount-" + ControlID).text('(' + arrData.length + ')');
    }
    else {
        $('#' + ControlID).val('');
        $("#CheckAllCount-" + ControlID).text('(0)');
    }
    $("#CheckGroup-" + ControlID + " input[type=checkbox]").each(function () {
        this.checked = IsCheckAll;
    });
    ShowItemCondition(ControlID, arrData.join(','));

}
function CheckGroupCheckAll(ControlID) {
    var isCheckAll = $('#CheckAllItem-' + ControlID)[0].checked;
    if (isCheckAll === true || String(isCheckAll) === "1") {
        ObjectCheckGroupSetCheckAll(ControlID, true);
    }
    else {
        ObjectCheckGroupSetCheckAll(ControlID, false);
    }

}
function NoEndDateClick(DateFrom, DateTo) {
    var isCheck = $('#NoEndDate' + DateTo)[0].checked;
    if (isCheck === true || String(isCheck) === "1") {
        $('#' + DateTo).attr("disabled", "");
        $('#' + DateTo).val(null);
    }
    else {
        $("#" + DateTo).removeAttr("disabled");
        $('#' + DateTo).val($('#' + DateFrom).val());
    }
}

function ObjectSwitchSet(ControlID, ObjectValue) {
    var e = $('#' + ControlID);
    changeSwitchery(e, ObjectValue);

}
function changeSwitchery(element, checked) {
    console.log(checked);
    if (checked === true || checked === "True" || checked === 1 || checked === '1' || checked === 'on') {
        checked = true;
        element.checked = true;
    }
    else {
        checked = false;
        element.checked = false;
    }

    if ((element.is(':checked') && checked === false) || (!element.is(':checked') && checked === true)) {
        element.parent().find('.switchery').trigger('click'); //Không chạy nếu bị disabe
    }
}


//#region treeview

function GetTreeFunctions(TreeID, ServiceUrl) {
    if (TreeID === "") {
        TreeID = "TreeListEdit" + $('#FormCode').val();
    }
    console.log('run get list tree');
    var eventGetDataParam = $('#' + TreeID + 'eventGetDataParam').val();
    var eventGetDataUrl = $('#' + TreeID + 'eventGetDataUrl').val();

    var Action = $('#' + TreeID + 'Action').val();
    var DomainID = $('#DomainID').val();
    var UserID = $('#UserID_Check').val();

    var parent = $('#SelectRoot' + TreeID).val();
    var RootColParent = $('#' + TreeID + 'RootColParent').val();

    var paramList = '';
    if (eventGetDataParam !== undefined && eventGetDataParam !== '') {
        var arrParamList = eventGetDataParam.split(',');
        if (arrParamList.length > 0) {
            $.map(arrParamList, function (item, i) {
                paramList += '&' + item + '=' + $('#' + item).val();
            });
        }
    }
    //console.log(eventGetDataParam);
    //console.log(paramList);

    var jsData = "Action=" + Action + "&DomainID=" + DomainID + "&UserID=" + UserID + (RootColParent !== undefined && RootColParent.length > 0 ? "&ColParentID=" + RootColParent : "") + "&ParentID=" + parent + paramList;
    console.log(eventGetDataUrl);
    console.log(jsData);
    $.ajax({
        type: "POST",
        url: eventGetDataUrl,
        data: jsData,
        success: function (response) {
            CheckResponse(response);
            RenderTree(TreeID, response, ServiceUrl);
        },
        error: function (response) {
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
        }
    });
}

function RenderTree(TreeID, arrResponsed, ServiceUrl) {
    if (arrResponsed === undefined || arrResponsed.length === 0) { return; }
    var TreeType = $('#' + TreeID + 'TreeType').val();
    var DomainID = $('#DomainID').val();
    var eventOnClickUrl = $('#' + TreeID + 'eventOnClickUrl').val();
    var eventOnClickParam = $('#' + TreeID + 'eventOnClickParam').val();
    var eventOnClickFunction = $('#' + TreeID + 'eventOnClickFunction').val();
    console.log(arrResponsed);

    $('#TotalRow-' + TreeID).text(arrResponsed.length);

    var Action = $('#' + TreeID + 'Action').val();
    $('#' + TreeID + 'ObjectCall').val(arrResponsed[0].ObjectCall);

    var arr = [];
    var obj;
    ///map data to arr


    for (var i = 0; i < arrResponsed.length; i++) {

        var nodeData = arrResponsed[i];
        var nodeIcon = "fa fa-folder-open-o";
        if (nodeData.Icon !== undefined && nodeData.Icon !== "" && nodeData.Icon !== null)
            nodeIcon = nodeData.Icon;
        else if (nodeData.NodeLevel == "0") {
            nodeIcon = "fa fa-home";

        }
        else if (nodeData.NodeLevel == "1" && nodeData.IsChild == "1")
            nodeIcon = "fa fa-folder-open-o text-warning";
        else if (nodeData.IsChild == "1")
            nodeIcon = "fa fa-file-text-o text-primary";

        obj = {
            text: nodeData.Name,
            id: nodeData.ID,
            'icon': nodeIcon,
            parent: nodeData.ParentID === "0" ? "#" : nodeData.ParentID,
            state: {
                opened: nodeData.IsOpen,
                selected: nodeData.IsCheck

            }
        };
        var pos = arr.map(function (e) { return e.id; }).indexOf(obj.id);
        if (pos < 0) {
            arr.push(obj);
        }
    }


    $('#TreeView' + TreeID).jstree("destroy").empty();
    $('#TreeView' + TreeID).jstree({
        'core': {
            'check_callback': function (op, node, par, pos, more) {
                if ((op === "move_node" || op === "copy_node") && node.type && node.type === "root") {
                    return false;
                }
                if ((op === "move_node" || op === "copy_node") && more && more.core) {
                    if (!confirm('Are you sure ...'))
                        return false;
                    else {
                        MoveNode(TreeID, node, par, pos);
                        return true;
                    }
                }

                return true;
            },
            'themes': {
                'responsive': false
            },
            'data': arr
        },
        'types': {
            'default': {
                'icon': 'fa fa-file-text-o text-primary'
            }
        },
        'search': {
            show_only_matches: true
        },
        'plugins': ['types', TreeType, 'search']
    });
    var to = false;
    $('#SearchDataTree' + TreeID).keyup(function () {
        if (to) { clearTimeout(to); }
        to = setTimeout(function () {
            var v = $('#SearchDataTree' + TreeID).val();
            $('#TreeView' + TreeID).jstree(true).search(v);
        }, 250);
    });

    $('#TreeView' + TreeID).on("changed.jstree", function (e, data) {
        if (data && data.event && data.event.type === "click" && eventOnClickUrl !== '') {
            console.log('tree click');
            var i, j, rUpload = [];
            var DataTreeString = [];

            for (i = 0, j = data.selected.length; i < j; i++) {
                rUpload.push(
                    {
                        ID: data.instance.get_node(data.selected[i]).id,
                        IsCheck: true
                    });

            }
            DataTreeString = rUpload;
            $('#' + TreeID + 'NodeID').val(data.node.id);
            $('#' + TreeID + 'NodeName').val(data.node.text);

            var ObjectCall = $('#' + TreeID + 'ObjectCall').val();
            var jsDataOnclick = "";
            if (eventOnClickUrl === 'OpenLink') {
                var FormCode = $('#FormCode').val();
                var SSID = $('#FSessionID').val();
                SetStatusAddUpdate('EDIT', 0);

                jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&DomainID=" + DomainID + "&ID=" + data.node.id;
                console.log('OpenLink');
                console.log(jsDataOnclick);

                $.ajax({
                    type: "POST",
                    url: "/Categories/CateAddupdate/GetDataByID",
                    data: jsDataOnclick,
                    success: function (response) {
                        CheckResponse(response);
                        LoadDataToForm(response);
                        $('#AddUpdateActionDelete').removeClass('d-none');
                        $('#box-right').removeClass('d-none');
                    },
                    error: function (response) {
                        notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
                    }
                });
            }
            else if (eventOnClickUrl !== '') {
                var paramList = '';
                if (eventOnClickParam !== undefined && eventOnClickParam !== '') {
                    var arrParamList = eventOnClickParam.split(',');
                    if (arrParamList.length > 0) {
                        $.map(arrParamList, function (item, i) {
                            paramList += '&' + item + '=' + $('#' + item).val();
                        });
                    }
                }
                jsDataOnclick = "ObjectCall=" + ObjectCall + "&Action=" + Action + "&DataTreeString=" + JSON.stringify(DataTreeString) + "&DomainID=" + DomainID + "&NodeID=" + data.node.id + paramList;
                console.log(jsDataOnclick);

                $.ajax({
                    type: "POST",
                    url: eventOnClickUrl,
                    data: jsDataOnclick,
                    success: function (response) {
                        CheckResponse(response);
                        console.log(response);
                        if (eventOnClickFunction !== 'dummy' && eventOnClickFunction !== '' && eventOnClickFunction !== undefined) {
                            console.log(eventOnClickFunction);

                            var arrayFun = eventOnClickFunction.split(",");
                            if (arrayFun.length === 1)
                                window[arrayFun[0]](response);
                            if (arrayFun.length === 2)
                                window[arrayFun[0]](arrayFun[1], response);
                            if (arrayFun.length === 3)
                                window[arrayFun[0]](arrayFun[1], arrayFun[2], response);
                        }
                    },
                    error: function (response) {
                        notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
                    }
                });
            }
        }
    });
}


function MoveNode(TreeID, node, par, pos) {
    console.log('drag and drop');
    var DomainID = $('#DomainID').val();
    var FormCode = $('#FormCode').val();
    var SSID = $('#FSessionID').val();

    var eventDnDUrl = $('#' + TreeID + 'eventDnDUrl').val();
    if (eventDnDUrl === undefined || eventDnDUrl === '') {
        eventDnDUrl = '/Categories/CateAddUpdate/CateSave';
    }
    console.log(eventDnDUrl);
    var parent = par.id === '#' ? '0' : par.id;

    var jsData = "FormCode=" + FormCode + "&FSessionID=" + SSID + "&Action=MoveNode&NodeID=" + node.id + "&ParentID=" + parent + "&Position=" + pos + "&DomainID=" + DomainID;
    console.log(jsData);

    $.ajax({
        type: "POST",
        url: eventDnDUrl,
        data: jsData,
        success: function (response) {
            CheckResponse(response);
            notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response);
        },
        error: function (response) {
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
        }
    });
    GetTreeFunctions(TreeID);
}
//#endregion
function LoadDataToForm(response, ProcessConfig, FormType, StepTo, ProcessConfigAction) {
    var ProcessStep = '';
    var arrData = JSON.parse(response);
    const idProcessStep =
        arrData.findIndex(
            x => x.Key === "ProcessStep"
        );
    if (idProcessStep >= 0) ProcessStep = arrData[idProcessStep].Value;
    console.log(ProcessStep);
    if (FormType != undefined && FormType.toUpperCase() == "VIEW") ProcessStep = "VIEW";
    if (FormType != undefined && (FormType.indexOf("ModalProcess") >= 0 || FormType.indexOf("VIEW") >= 0) && ProcessStep.length > 0 && ProcessConfigAction != undefined) {

        UpdateButtonFunctionApproval("btnAddModalForm", "101", ProcessConfigAction, ProcessStep);
        UpdateButtonFunctionApproval("btnUpdateModalForm", "102", ProcessConfigAction, ProcessStep);
        UpdateButtonFunctionApproval("btnAppModalApproval", "501", ProcessConfigAction, ProcessStep);
        UpdateButtonFunctionApproval("btnRejModalReject", "401", ProcessConfigAction, ProcessStep);
        UpdateButtonFunctionApproval("btnPrintModal", "601", ProcessConfigAction, ProcessStep);
        UpdateButtonFunctionApproval("btnCancelModalForm", "404", ProcessConfigAction, ProcessStep);
    }

    $.map(arrData, function (row, i) {
        LoadArrData(row);
    });
    function LoadArrData(row) {
        var valueDisplay = row[row.Key + "Display"] != undefined ? row[row.Key + "Display"] : "";
        SetDataToObject(row.Type, row.Pattern, row.Key, row.Value, row.OptionConfig, valueDisplay);
        if (ProcessConfig !== undefined && ProcessStep !== undefined) {
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
    }
}

function UpdateButtonFunctionApproval(ButtonID, ActionID, ProcessConfigAction, ProcessStep) {
    const idAction = ProcessConfigAction.findIndex(
        x => x.key === "Action" && x.val === ActionID && x.parentId === ProcessStep
    );

    if (idAction >= 0 && ProcessStep != "VIEW") {
        var idRow = ProcessConfigAction[idAction].id;
        var steptoID = ProcessConfigAction.findIndex(
            x => x.key === "StepTo" && x.id === idRow && x.parentId === ProcessStep
        );
        var stepTo = "";
        if (steptoID >= 0) {
            stepTo = ProcessConfigAction[steptoID].val;
            var caption = "";
            switch (ActionID) {
                case "101":
                    caption = "<i class='fa fa-paper-plane-o'/> Save&Sent";
                    break;
                case "102":
                    caption = "<i class='fa fa-save'/> Save";
                    break;
                case "501":
                    caption = "<i class='fa fa-pencil-square-o'/> Approval" + "<i class='fa fa-arrow-right'></i>" + stepTo;
                    break;
                case "401":
                    caption = "<i class='fa fa-recycle'/> Reject";
                    break;
                case "404":
                    caption = "<i class='fa fa-trash'/> Cancel";
                    break;
                case "601":
                    caption = "<i class='fa fa-print'/> Print";
                    break;
                default:
                    break;
            }

            $('#' + ButtonID).html(caption);
        }
        $('#' + ButtonID).removeClass('d-none');
        if (ActionID != "601") {
            $('#' + ButtonID).attr("onclick", "ApprovedModalOnClick('" + ActionID + "','" + stepTo + "')");
        }
    }
    else { $('#' + ButtonID).addClass('d-none'); }
}
function SetDataToObject(Type, Pattern, Key, Value, OptionConfig, ValueDisplay, ObjectCall) {
    var ServiceUrl = GetControlsConfig("#ServiceUrl-" + Key);
    if (Type === 'TextBox') {
        if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number2") >= 0) {
            $('#' + Key).val(FormatNumber(Value, 2));
            $('#' + Key).trigger("change");
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number4") >= 0) {
            $('#' + Key).val(FormatNumber(Value, 4));
            $('#' + Key).trigger("change");
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number") >= 0) {
            $('#' + Key).val(FormatNumber(Value));
            $('#' + Key).trigger("change");
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("jsfunction") >= 0) {
            $('#' + Key).val(FormatNumber(Value, 2));
            $('#label-' + Key).text(FormatNumber(Value, 2));
        }
        else {
            $('#' + Key).val(Value);
        }
    }
    else if (Type == "TextOnly") {
        var val = "";
        if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number2") >= 0) {
            val = FormatNumber(Value, 2);
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number4") >= 0) {
            val = FormatNumber(Value, 4);
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("number") >= 0) {
            val = FormatNumber(Value);
        }
        else if (Pattern !== undefined && Pattern !== null && Pattern.toLowerCase().indexOf("jsfunction") >= 0) {
            val = FormatNumber(Value, 2);
        }
        else val = Value;

        $('#' + Key).val(val);
        $('#labelfor-' + Key).html(val);
        //$('#' + Key).trigger("change");


    }
    else if (Type === 'Button' && Pattern === "ActionListButtonHTML") {
        $("#ActionListButton").html(Value);
    }
    else if (Type === 'Button' && Pattern === "Dropdown") {
        $("#divDropDown-" + Key).find('a[data-value=' + Value + ']').trigger('click');
    }
    else if (Type === 'HtmlEditor') {
        console.log(Value);

        download_to_textbox(Value, Key, Pattern);

        //$('#' + Key).summernote({
        //    onInit: function () {
        //        download_to_textbox(Value, Key);
        //    },
        //});
        //chưa xử lý tình trạng disable
        //$("#htmleditor@(ControlID)").load("@Value");
    }
    else if (Type === 'MultiFileUpload') {
        $('#' + Key).val(Value);
        InitObjectViewFileList(Key, 0);
    }
    else if (Type === 'OptionBox2') {
        ObjectRadioSet(Key, Value);
        ShowItemCondition(Key, Value, 'OptionBox2');
    }
    else if (Type === 'CheckBox') {
        ObjectCheckBoxSet(Key, Value);
    }
    else if (Type === 'CheckGroup') {
        ObjectCheckGroupSet(Key, Value);
    }
    else if (Type === 'Switch') {
        ObjectSwitchSet(Key, Value);
    }
    else if (Type === 'TabListSelect') {
        ShowItemCondition(Key, Value, 'TabListSelect');
    }
    else if (Type === 'SelectListAjax') {
        //$('#' + Key ).value = Value;
        ReLoadDataInitToObject(Key, Value, ValueDisplay);
        ShowItemCondition(Key, Value, 'SelectList');
        //$('select[id=' + Key + ']').val(Value).trigger('change');
        //console.log($('#' + Key).value);
    }
    else if (Type === 'SelectTree') {
        //$('#' + Key ).value = Value;
        ReLoadDataInitToObject(Key, Value, ValueDisplay);
        //$('select[id=' + Key + ']').val(Value).trigger('change');
        //console.log($('#' + Key).value);
    }
    else if (Type === 'SelectMultiListAjax') {
        //$('#' + Key ).value = Value;
        ReLoadDataInitToObject(Key, Value, ValueDisplay);
        //$('select[id=' + Key + ']').val(Value).trigger('change');
        //console.log($('#' + Key).value);
    }
    else if (Type === 'DataLists') {
        $('#' + Key).val('');
        RenderDataListFromJsonTable(Key, Value);
    }
    else if (Type === 'SelectListData') {
        $('#' + Key).val(Value);
        if (ValueDisplay?.length) {
            var jsSelectListData = JSON.parse(ValueDisplay);
            $('#Search-' + Key).val(jsSelectListData.Name);
            $('#searchbox-avatar-' + Key).attr('scr', jsSelectListData.Avatar);
            $('#searchbox-namedesc-' + Key).text(jsSelectListData.NameDesc);
            $('#searchbox-title-' + Key).text(jsSelectListData.Title);
            $('#searchbox-titledesc-' + Key).text(jsSelectListData.TitleDesc);
        }
        else if (!Value?.length) {
            $('#Search-' + Key).val("");
            $('#searchbox-avatar-' + Key).attr('scr', "");
            $('#searchbox-namedesc-' + Key).text("");
            $('#searchbox-title-' + Key).text("");
            $('#searchbox-titledesc-' + Key).text("");

        }
        ReLoadDataInitToObject(Key, Value, ValueDisplay);
        //$('select[id=' + Key + ']').val(Value).trigger('change');
    }
    else if (Type === 'DataReportEdit') {
        console.log('DataReportEdit');
        console.log(OptionConfig);
        LoadDataListsFromAjax(OptionConfig.split(',')[0], 'CateAddUpdateForm', Key, 1, null, Pattern, Value, ServiceUrl);
    }
    else if (Type === 'ItemsDetail') {
        console.log('ItemsDetail');
        console.log(OptionConfig);
        LoadDataListsFromAjax(OptionConfig.split(',')[0], 'CateAddUpdateForm', Key, 0, 'ItemsDetail', Pattern, Value, ServiceUrl);
    }
    else if (Type === 'ObjectInCharge') {
        $('#' + Key).val(Value);
        RenderListObjectIncharge(Key);
    }
    else if (Type === 'FileUpload') {
        console.log('FileUpload');
        $('#PreViewFileUpload-' + Key).attr("src", Value);
        $('#' + Key).val(Value);
    }
    else if (Type === "DateFromTo") {
        var isNulldate = 0;
        if (Value == null || Value == undefined || Value == "" || Value.indexOf("1900-01-01") >= 0 || Value.indexOf("1/1/1900") >= 0)
            isNulldate = 1;
        if (Pattern === "DateTimeFrom" || Pattern === "DateTimeTo") {
            if (isNulldate)
                Value = new Date();
            date2 = new Date(Value);
            //console.log('DateFromTo');
            //console.log(Key);
            //console.log(Value);
            //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear() + ' ' + date2.getHours() + ':' + date2.getMinutes();
            stringDate = moment(date2).format('YYYY-MM-DD HH:mm');
            $('#' + Key).val(stringDate);
        }
        else if (Pattern === "TimeFromPick" || Pattern === "TimeToPick") {
            if (isNulldate)
                Value = new Date();
            date2 = moment(Value, 'h:mm A');
            //console.log('DateFromTo');
            //console.log(Key);
            //console.log(Value);
            //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear() + ' ' + date2.getHours() + ':' + date2.getMinutes();
            stringDate = moment(date2).format('h:mm A');
            $('#' + Key).val(stringDate);
        }
        else {
            if (isNulldate)
                Value = new Date();
            date2 = new Date(Value);
            console.log('DateTimeFrom');
            console.log(Key);
            console.log(Value);
            //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear();
            stringDate = moment(date2).format('YYYY-MM-DD');
            $('#' + Key).val(stringDate);

            if (Pattern === "DateTo" && OptionConfig.toLowerCase().indexOf("noenddate") >= 0) {
                if (isNulldate) {
                    ObjectCheckBoxSet("NoEndDate" + Key, "1");
                    $('#' + Key).attr("disabled", "");
                    $('#' + Key).val(null);
                }
                else {
                    ObjectCheckBoxSet("NoEndDate" + Key, "0");
                    $('#' + Key).removeAttr("disabled");
                }
            }
        }
    }
    else if (Type === 'DateTime') {
        var date2 = new Date();
        var stringDate = '';

        if (Pattern === "DatePick") {
            if (Value !== undefined && Value != null && Value.length > 0) {
                date2 = new Date(Value);
                console.log('datepick');
                console.log(Key);
                console.log(Value);
                //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear();
                stringDate = moment(date2).format('YYYY-MM-DD');
                $('#' + Key).val(stringDate);
            }
            else {
                date2 = new Date();
                //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear();
                stringDate = moment(date2).format('YYYY-MM-DD');
                $('#' + Key).val(stringDate);
            }
        }
        else
            if (Pattern === "TimePick") {
                if (Value) {
                    date2 = moment(Value, 'h:mm A');
                    //stringDate = date2.getHours() + ':' + date2.getMinutes() + ':' + date2.setSeconds();
                    stringDate = moment(date2).format('HH:mm:ss');
                    $('#' + Key).val(stringDate);
                }
            }
            else {
                if (Value !== undefined && Value != null && Value.length > 0) {
                    date2 = new Date(Value);
                    //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear() + ' ' + date2.getHours() + ':' + date2.getMinutes() + ':' + date2.setSeconds();
                    stringDate = moment(date2).format('YYYY-MM-DD HH:mm:ss');
                    $('#' + Key).val(stringDate);
                }
                else {
                    date2 = new Date();
                    //stringDate = date2.getDate() + '/' + (date2.getMonth() + 1) + '/' + date2.getFullYear() + ' ' + date2.getHours() + ':' + date2.getMinutes() + ':' + date2.setSeconds();
                    stringDate = moment(date2).format('YYYY-MM-DD HH:mm:ss');
                    $('#' + Key).val(stringDate);
                }
            }
    }
    else if (Type === "TextArea") {
        $('#' + Key).val(Value);
    }
    else if (Type == "Line") {

    }
    else if (Type == "BarCode") {
        $('#' + Key).val(Value);
        generateBarcode(Key);

    }
    else if ($('#' + Key) != undefined) {
        $('#' + Key).val(Value);
    }
}
function generateBarcode(ControlID) {
    var value = $("#" + ControlID).val();
    var settings = {
        barWidth: 3,
        barHeight: 50,
        moduleSize: 5,
        showHRI: true,
        addQuietZone: true,
        marginHRI: 5,
        bgColor: "#FFFFFF",
        color: "#000000",
        fontSize: 10,
        output: "bmp",
        posX: 0,
        posY: 0
    };

    console.log('barcode');
    console.log(value);
    $("#barcode" + ControlID).show().barcode(value, "code128", settings);
    $("#barcode" + ControlID).css("width", "auto");
    $("#barcode" + ControlID + " object").css("width", "-webkit-fill-available");
}

function SetDisableControl(Type, Pattern, Key, Disable, pDisable) {
    if (Disable === "1") { Disable = "1"; }
    else { Disable = "0"; }
    if (pDisable === "1") { pDisable = "1"; }
    else { pDisable = "0"; }

    if (Type === 'TextBox') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'Button' && Pattern === "Dropdown") {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'OptionBox2') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'CheckBox') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'CheckGroup') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'Switch') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'SelectListAjax') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
            var valueDisplay = $("#" + Key + "Display").val();
            if (valueDisplay != undefined && valueDisplay.length) {
                $("#" + Key).parent().addClass("d-none");
                $("#" + Key + "Display").parent().removeClass("d-none");
            }
        }
        else {
            $("#" + Key).removeAttr("disabled");
            $("#" + Key).parent().removeClass("d-none");
            $("#" + Key + "Display").parent().addClass("d-none");
        }
    }
    else if (Type === 'SelectTree') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'SelectMultiListAjax') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'DataLists') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'SelectListData') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'DataReportEdit') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'FileUpload') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }
    else if (Type === "DateFromTo") {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
            $("#NoEndDate" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
            $("#NoEndDate" + Key).removeAttr("disabled");
        }
    }
    else if (Type === 'DateTime') {
        if (Disable === "1" || pDisable === "1") {
            $("#" + Key).attr("disabled", "");
        }
        else {
            $("#" + Key).removeAttr("disabled");
        }
    }

}


function ReLoadDataInitToObject(ControlID, Value, ValueDisplay) {// su dung load vao danh sach control
    const itemCall = GetControlsConfig(ControlID);
    if (itemCall !== undefined) {
        var item = JSON.parse(itemCall);
        //var ControlID = item.ControlID;
        //var Value = item.Value;
        var PlaceHolder = item.PlaceHolder;
        var DataSource = item.DataSource;
        var ColCode = item.ColCode;
        var ColName = item.ColName;
        var Condition = item.Condition;
        var IsReload = item.IsReload;
        var Action = item.Action;
        var Type = item.Type;
        var Patterm = item.Patten;
        var OptionConfig = item.OptionConfig;
        var ServiceUrl = item.ServiceUrl;

        var IsReload = 0;
        if (Condition != undefined && Condition.length > 0)
            IsReload = 1;
        if (item.Type === "SelectListData") {
            $('#' + ControlID).val(Value).trigger("change");
            SelectListData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Patterm, OptionConfig, ServiceUrl);

        }
        else if (item.Type === "SelectListAjax") {
            $('#' + ControlID).val(Value).trigger("change");
            SelectListData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Patterm, OptionConfig, ServiceUrl);
            if (ValueDisplay != undefined && ValueDisplay.length) {
                $('#' + ControlID + "Display").val(ValueDisplay);
            }
        }

        else if (item.Type === "SelectTree") {
            $('#' + ControlID).combotree('setValue', Value);
            SelectListData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Patterm, OptionConfig, ServiceUrl);
        }
        else if (item.Type === "SelectMultiListAjax") {
            var valArrSelect = Value;
            if (typeof (Value) == "string")
                valArrSelect = Value.split(',');
            $('#' + ControlID).val(valArrSelect).trigger("change");
            SelectListData(ControlID, Value, PlaceHolder, DataSource, ColCode, ColName, Condition, IsReload, Action, Type, Patterm, OptionConfig, ServiceUrl);
        }
        else if (item.type === 'checkbox') {
            ObjectCheckBoxSet(ControlID, item.Value);
        }
    }
}
function CateResetControlAll() {
    console.log("CateResetControlAll");
    statusAddUpdate = 'ADD';
    SetStatusAddUpdate(statusAddUpdate, 0);
    $("#ID").val('');

    var jsControlList = GetControlsConfig('ControlListConfig');
    if (typeof (jsControlList) == "string") {
        jsControlList = JSON.parse(jsControlList);
    }

    if (jsControlList.length) {
        $.map(jsControlList, function (item) {
            if (item.Type == "ItemsDetail") {
                item.Value = "[]";
            }
            else if (item.Type == "SelectListData") {
                item.Value = "";
            }
            //else if (item.Type == "CheckBox") { item.Value = "0"; }
            SetDataToObject(item.Type, item.Pattern, item.Key, item.Value, item.OptionConfig, item.ValueDisplay, 'CateResetControlAll');
        });
    }
    else {
        var form = $('#CateAddUpdateForm');
        var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
        var ControlList = form.find(':input');

        $.map(ControlList, function (item) {
            if (item.id.toLowerCase() !== "formcode"
                && item.id.toLowerCase() !== "fsession"
                && item.id.toLowerCase() !== "userid"
                && item.id.toLowerCase() !== "domainid"
                && item.id.toLowerCase() !== "action"
            ) {
                if (item.type === "text") {
                    $(item).val(null);
                }
                else if (item.type === "password") {
                    $(item).val(null);
                }
                else if (item.type === "hidden" && item.className === "ControlID") {
                    $(item).val(null);
                }
                //else if (item.type === "checkbox" && item.className == "js-small") {
                //    SetDataToObject("Switch", "", item.id, "0");
                //}
            }
        });


    }
    disabledListControl?.attr('disabled', 'disabled');
    SetStatusAddUpdate(statusAddUpdate, 0);
}

function CateResetControl() {
    console.log("CateResetControl");
    statusAddUpdate = 'ADD';
    SetStatusAddUpdate(statusAddUpdate, 0);

    var form = $('#CateAddUpdateForm');
    var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
    var ControlList = form.find(':input');

    $.map(ControlList, function (item) {
        if (item.id.toLowerCase() !== "formcode"
            && item.id.toLowerCase() !== "fsession"
            && item.id.toLowerCase() !== "userid"
            && item.id.toLowerCase() !== "domainid"
            && item.id.toLowerCase() !== "action"
        ) {
            if (item.type === "text") {
                $(item).val(null);
            }
            else if (item.type === "password") {
                $(item).val(null);
            }
            else if (item.type === "hidden" && item.className === "ControlID") {
                $(item).val(null);
            }
            //else if (item.type === "checkbox" && item.className == "js-small") {
            //    SetDataToObject("Switch", "", item.id, "0");
            //}
        }
    });
    disabledListControl.attr('disabled', 'disabled');
}

function CheckValidInput(ControlID) {
    var isValid = true;

    var control = $('#' + ControlID).filter('[required]:visible');

    control.each(function (i, item) {
        if (($(item).val() === '' || $(item).val() === undefined) && isValid === true) {
            //notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Please Check Data Input' + $(item).attr('name'));
            $(item).focus();
            $(item).parent().addClass("invalid-input");
            isValid = false;
            itemName = $(item).attr('name');
        }
        else $(item).parent().removeClass("invalid-input");
    });
    return isValid;
}
function IsValidInput(FormID = "") {
    var isValid = true;
    var itemName = "";
    if (!FormID) {
        FormID = document;
    }
    else FormID = '#' + FormID;

    $(FormID).find('input,textarea,select,select2').filter('[required]:visible').each(function (i, item) {
        if (($(item).val() === '' || $(item).val() == null || $(item).val() === undefined || $(item).val().length == 0) && isValid === true) {
            //notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Please Check Data Input' + $(item).attr('name'));
            $(item).focus();
            $(item).parent().addClass("invalid-input");
            isValid = false;
            itemName = $(item).parent().prev().text() ?? $(item).attr('name');
        }
        else $(item).parent().removeClass("invalid-input");
    });

    $(FormID).find('.textbox.textbox-invalid.easyui-fluid.combo').filter(':visible').each(function (i, item) {
        if (($(item).val() === '' || $(item).val() == null || $(item).val() === undefined) && isValid === true) {
            $(item).focus();
            isValid = false;
        }
    });
    if (isValid === false) {
        notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Vui lòng nhập', itemName);
    }
    return isValid;
}
function HideActionControl(ControlID) {
    $('#ActionPanelButton').addClass("d-none");
    $('#ActionPanelButton button').each(function () {
        this.disabled = true;
    });
}
function ShowActionControl(ControlID) {
    $('#ActionPanelButton').removeClass("d-none");
    $('#ActionPanelButton button').each(function () {
        this.disabled = false;
    });
}

function CateAddUpdateFunction(ActionCode, NextStep, SignPath, reloadType, targetType, Delegate) {
    var retVal = IsValidInput();
    if (retVal === false) {
        return retVal;
    }
    HideActionControl();
    if (NextStep !== undefined && NextStep.length > 0) {
        $("#Action").val(ActionCode);
    }
    var form = $('#CateAddUpdateForm');
    if (form.find("#Action").val() == "") {
        form.find("#Action").val(ActionCode);
    }
    if (form.find("#Action").val() == "EDIT" && ActionCode == "DEL") {
        form.find("#Action").val(ActionCode);
    }

    var disabledListControl = form.find(':input:disabled').removeAttr('disabled');

    var formData = form.serialize();
    console.log(formData.indexOf("Action="));
    var SignNote = $("#SignNote").val();
    if (formData.indexOf("Action=") > 0)
        formData += '&NextStep=' + NextStep + '&SignPath=' + SignPath + '&SignNote=' + SignNote;
    else
        formData += '&Action=' + ActionCode + '&NextStep=' + NextStep + '&SignPath=' + SignPath + '&SignNote=' + SignNote;
    formData += '&TargetType=' + targetType;
    formData += '&Delegate=' + Delegate;

    disabledListControl.attr('disabled', 'disabled');
    console.log(formData);
    //console.log($("#ItemCreateList").val());

    $.ajax({
        type: 'POST',
        url: '/Categories/CateAddUpdate/CateSave',
        data: formData,
        success: function (response) {
            CheckResponse(response);
            console.log(response);
            if (
                (response != undefined && response.toLowerCase().indexOf('err') >= 0) ||
                (response.StatusCode != undefined && response.StatusCode.toLowerCase().indexOf('err') >= 0)
            ) {
                notify('top', 'right', '', 'danger', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo: ', response);
            }
            else {
                var mess = "";
                var reJS = {};
                if (response.indexOf("{") >= 0) {
                    reJS = JSON.parse(response);
                    mess = reJS.StatusMess;
                    if (ActionCode.toUpperCase() == "ADD" && reJS.ID) {
                        $("#ID").val(reJS.ID);
                    }
                }
                else {
                    mess = response;
                }
                notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo:', mess);

                if (ActionCode === 'tree') {
                    console.log('tree');
                    if (formData.indexOf("Action=EDIT") >= 0) {
                        console.log('EDIT');
                    }
                    else {
                        GetTreeFunctions("");
                    }
                }
                if (ActionCode?.toLowerCase() === 'hotreload' || reloadType === 'hotreload') {
                    console.log('hotreload');
                    if (formData.indexOf("Action=EDIT") >= 0) {
                        console.log('EDIT');
                    }
                    else {
                        sleep(500);
                        window.location.reload(false);
                        return false;
                    }
                }
                if (reloadType === 'Modal') {
                    console.log('Modal');
                    CloseModalForm($('#FormCode').val());
                    SubmitFunction();//reload report
                }

                if (ActionCode?.toLowerCase().indexOf('reloadcardlist') >= 0 || reloadType?.toLowerCase().indexOf('reloadcardlist') >= 0) {
                    console.log('reloadcardlist');
                    if (formData.indexOf("Action=EDIT") >= 0) {
                        console.log('EDIT');
                        console.log("Reset control");
                        var reportKey = $('#CardList-ReportKey').val();
                        LoadCardListsFromAjax(reportKey, 'ReportForm', reportKey, 1, 'OnClickCardList()');
                    }
                    else {
                        console.log("Reset control");
                        var reportKey = $('#CardList-ReportKey').val();
                        LoadCardListsFromAjax(reportKey, 'ReportForm', reportKey, 1, 'OnClickCardList()');
                        CateResetControlAll();
                    }
                }

                if (reloadType?.toLowerCase().indexOf('printposv1') >= 0) {
                    console.log('PrintPOSv1');
                    if (formData.indexOf("Action=EDIT") >= 0) {
                        console.log('EDIT');
                        var reportKey = $('#CardList-ReportKey').val();
                        PrintPOSv1();
                        LoadCardListsFromAjax(reportKey, 'ReportForm', reportKey, 1, 'OnClickCardList()');
                    }
                    else {
                        console.log("Reset control PrintPOSv1");
                        var reportKey = $('#CardList-ReportKey').val();
                        if (reJS.Code) {
                            $("#Code").val(reJS.Code);
                            PrintPOSv1();
                            CateResetControlAll();
                        }

                        LoadCardListsFromAjax(reportKey, 'ReportForm', reportKey, 1, 'OnClickCardList()');

                    }
                }

            }
            ShowActionControl();
            retVal = true;

            var RedirectOnApproval = $("#RedirectOnApproval").val();
            if (RedirectOnApproval !== undefined && RedirectOnApproval !== "" &&
                !(
                    (response != undefined && response.toLowerCase().indexOf('err') >= 0) ||
                    (response.StatusCode != undefined && response.StatusCode.toLowerCase().indexOf('err') >= 0)
                )
            ) {
                window.location = RedirectOnApproval;
            }

        },
        error: function (response) {
            console.log('Thất bại');
            console.log(response);
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại:' + response);
            if (ActionCode === 'tree') {
                GetTreeFunctions("");
            }
            retVal = false;
        },
        async: false
    });
    return retVal;
}

function ProcessStepChange(FormCode, ActionCode, ID, redirect, maxLeng = 100) {
    var ssid = $('#FSessionID').val();
    var Action = ActionCode.split(',')[0];
    if (Action === undefined || Action.length === 0) { Action = 'EDIT'; }

    var formData = 'FormCode=' + FormCode + '&Action=' + Action + '&ActionCode=' + ActionCode + '&FSessionID=' + ssid + '&TargetType=ProcessStatus';
    if (ID.indexOf('-') > 0) {
        formData += '&ID=' + ID;
    }
    else {
        formData += '&ID=' + ID;
    }
    console.log(formData);
    var retVal = false;
    $.ajax({
        type: 'POST',
        url: '/Categories/CateAddUpdate/CateSave',
        data: formData,
        success: function (response) {
            CheckResponse(response);
            console.log(response);
            if (response.toLowerCase().indexOf('err') >= 0) {
                notify('top', 'right', '', 'danger', 'animated fadeInLeft', 'animated fadeOutLeft', 'Lỗi: ', response);
            }
            else {
                notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response);
                if (redirect !== undefined && redirect.length) {
                    window.location.href = redirect;
                }
            }
            retVal = true;
        },
        error: function (response) {
            console.log('Thất bại');
            console.log(response);
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại:' + response);
            retVal = false;
        },
        async: false
    });
    return retVal;
}
function PrintCheckList(FormCode, ActionCode, ID, redirect, maxLeng = 100) {
    var ssid = $('#FSessionID').val();
    var Action = ActionCode.split(',')[0];
    if (Action === undefined || Action.length === 0) { Action = 'EDIT'; }

    var formData = 'FormCode=' + FormCode + '&Action=' + Action + '&ActionCode=' + ActionCode + '&FSessionID=' + ssid + '&TargetType=ProcessStatus';
    if (ID.indexOf('-') > 0) {
        formData += '&ID=' + ID;
    }
    else {
        formData += '&ID=' + ID;
    }
    console.log(formData);
    var retVal = false;
    $.ajax({
        type: 'POST',
        url: '/Categories/CateAddUpdate/CateSave',
        data: formData,
        success: function (response) {
            CheckResponse(response);
            console.log(response);
            if (response.toLowerCase().indexOf('err') >= 0) {
                notify('top', 'right', '', 'danger', 'animated fadeInLeft', 'animated fadeOutLeft', 'Lỗi: ', response);
            }
            else {
                notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response);
                if (redirect !== undefined && redirect.length) {
                    window.location.href = redirect;
                }
            }
            retVal = true;
        },
        error: function (response) {
            console.log('Thất bại');
            console.log(response);
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại:' + response);
            retVal = false;
        },
        async: false
    });
    return retVal;
}


function NodeActionAdd() {
    CateResetControl();
}
function NodeActionDelete() {
    if (confirm("Bạn có chắc chắn muốn xóa dữ liệu này (" + $("#ID").val() + ")?")) {
        SetStatusAddUpdate('DELETE', 0);
        CateAddUpdateFunction("tree");
        CateResetControlAll();
    }
}
function SetStatusAddUpdate(status, isPreLoad) {
    var LangCode = $('#LangCode').val();
    var ele = document.getElementById("ActionPanelButton");
    if (ele !== undefined && ele !== null) {
        ele.style.display = "block";
    }
    $('#Action').val(status);
    if (isPreLoad === 0) {
        var span = $("#PreLoad");
        span.html('<span id="titleAddUpdate" style="color:brown;font-weight:bold">[' + status + ']</span>');
    }
    var oldClass = $('#AddUpdateAction').attr('class');
    var newClass = "btn btn-primary";

    if (status === "ADD") {
        newClass = "btn btn-primary";
        $('#AddUpdateAction').removeClass(oldClass).addClass(newClass);
        var orgtitle = $('#AddUpdateAction').attr("orgtitle");
        $('#AddUpdateAction').html('<i class="fa fa-plus"></i> ' + (orgtitle ?? (LangCode == "EN" ? "Confirm Create" : "Xác Nhận Tạo mới")));
    }
    if (status === "DELETE") {
        newClass = "btn btn-danger";
        $('#AddUpdateAction').removeClass(oldClass).addClass(newClass);
        $('#AddUpdateAction').html('<i class="fa fa-trash"></i> ' + (LangCode == "EN" ? "Confirm Delete" : "Xác Nhận Xóa"));
    }
    if (status === "EDIT") {
        newClass = "btn btn-warning";
        $('#AddUpdateAction').removeClass(oldClass).addClass(newClass);
        $('#AddUpdateAction').html('<i class="fa fa-edit"></i> ' + (LangCode == "EN" ? "Confirm Edit" : "Cập Nhật"));
    }

}


///custom todo checklist
function CreateCheckListItem(ControlID) {
    // create the new li from the form input
    var item = $('input[name=task-insert-' + ControlID + ']');
    var task = item.val();
    // Alert if the form in submitted empty
    if (task.length === 0 || task === undefined) {
        alert('please enter a task');
    } else {
        var ip = $('#' + ControlID).val();
        var jsData = [];
        if (ip.length > 0) {
            jsData = JSON.parse(ip);
        }
        var e = {};
        e.Code = jsData.length + 1;
        e.Name = task;
        e.Val = '';
        jsData.push(e);
        $('#' + ControlID).val(JSON.stringify(jsData));
        LoadCheckList(ControlID);

    }
}
function LoadCheckList(ControlID) {
    var item = $('#' + ControlID).val();
    var jsData = [];
    if (item.length > 0) {
        jsData = JSON.parse(item);
    }

    $('.to-do-list.' + ControlID).remove();
    $.map(jsData, function (e, i) {
        AddCheckListItem(ControlID, e.Code, e.Name, e.Val, i);
    });

}
function AddCheckListItem(ControlID, Code, Name, Val, i) {
    $('.task-headline').fadeIn();
    var html = '';
    html += '<div class="to-do-list ' + ControlID + '" id="' + ControlID + i + '">';
    html += '   <div class="checkbox-fade fade-in-primary">';
    html += '       <label class="check-task' + (Val === 'checked' ? 'done-task' : '') + '">';
    html += '           <input type="checkbox"' + (Val === 'checked' ? 'checked' : '') + ' onclick="check_task(\'' + ControlID + '\',' + i + ')" id="checkbox' + ControlID + i + '"/>';
    html += '           <span class="cr"><i class="cr-icon fa fa-check txt-primary"></i></span><span>' + Name + '</span>';
    html += '       </label>';
    html += '   </div>';
    html += '   <div class="f-right">';
    html += '       <a onclick="delete_todo(\'' + ControlID + '\',' + i + ');" href="#!" class="delete_todolist"><i class="fa fa-times-circle" ></i></a>';
    html += '   </div>';
    html += '</div>';
    var add_todo = $(html);
    $(add_todo).appendTo("#CheckList-" + ControlID).hide().fadeIn(300);
}
function delete_todo(ControlID, e) {
    $('#' + ControlID + e).fadeOut();
    var elem = document.getElementById(ControlID + e);
    elem.parentNode.removeChild(elem);

    var jsData = JSON.parse($('#' + ControlID).val());
    jsData.splice(e, 1);
    $('#' + ControlID).val(JSON.stringify(jsData));
    onHanderClickCheckList(ControlID)
}

function check_task(ControlID, e) {
    if ($('#checkbox' + ControlID + e).prop('checked'))
        $('#checkbox' + ControlID + e).parent().addClass('done-task');
    else
        $('#checkbox' + ControlID + e).parent().removeClass('done-task');
    onHanderClickCheckList(ControlID);
}

function onHanderClickCheckList(ControlID) {
    var i = 0;
    var arrCheckList = [];
    $('#CheckList-' + ControlID + ' input').each(function () {
        i++;
        arrCheckList.push(
            {
                Code: i,
                Name: $(this).parent().text().trim(),
                Val: $(this).is(":checked") ? "checked" : ""
            }
        );
    });
    $('#' + ControlID).val(JSON.stringify(arrCheckList));
    console.log($('#' + ControlID).val());
}
/////end todo checklist
////begin fomular
var jsFunctionRegList = [];
function jsFunction(ControlID, ParentID, Value, FXConfig) {
    if (typeof (FXConfig) == "string") FXConfig = JSON.parse(FXConfig);
    var fx = FXConfig.FX;
    var OptionConfig = FXConfig.OptionConfig;

    console.log(fx);
    fx = fx.replace(/&quot;/g, '"');
    var arrConfig = OptionConfig?.split(':');
    var PrefixControl = "";
    if (arrConfig && arrConfig[0].toLowerCase() === "prefixid") {
        PrefixControl = arrConfig[1];
    }
    var js = fx.split(':');

    if (js.length > 0) {
        var funcType = js[0];
        var paramArr = js[1].split(',');
        if (funcType.toLowerCase() === 'regular') {
            $.map(paramArr, function (item, i) {
                var eventItem = {
                    key: PrefixControl + '-' + ControlID + '-' + item + '-' + ParentID
                }

                if ((item === "*" || item === "-" || item === "+" || item === "/" || item === "(" || item === ")" || (item.indexOf('num#') >= 0)) !== true) {
                    if ($('#' + PrefixControl + item)[0].type === "select-one") {
                        if (!jsFunctionRegList.find(m => m.key == eventItem.key)) {
                            jsFunctionRegList.push(eventItem);
                            $('#' + PrefixControl + item).on('select2:select', function () {
                                fxUpdateRegular(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
                            });
                        }
                    }
                    else if ($('#' + PrefixControl + item)[0].type === "hidden") {
                        if (!jsFunctionRegList.find(m => m.key == eventItem.key)) {
                            jsFunctionRegList.push(eventItem);
                            $('#' + PrefixControl + item).on('change', function () {
                                fxUpdateRegular(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
                            });
                        }
                    }
                    else {

                        if (!jsFunctionRegList.find(m => m.key == eventItem.key)) {
                            jsFunctionRegList.push(eventItem);
                            $('#' + PrefixControl + item + '.ParentID-' + ParentID).keyup(function () {
                                fxUpdateRegular(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
                            });
                        }
                    }
                }

            });
            fxUpdateRegular(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
        }
        else if (funcType.toLowerCase() === 'sumcolumn' && paramArr.length === 1) {
            var eventItem = {
                PrefixControl,
                ControlID,
                funcType,
                paramArr,
                OptionConfig,
                ParentID
            }
            if (!jsFunctionRegList.find(m => m.key == eventItem.key)) {
                $('#' + PrefixControl).on("change", function () {
                    fxUpdateSumColumn(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
                });
            }
            fxUpdateSumColumn(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID);
        };

    }
}

function fxUpdateRegular(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID) {
    console.log("fxUpdateRegular " + PrefixControl + "-" + ControlID + "-" + funcType);
    var functionString = "";
    var ret = 0;
    if (typeof (paramArr) == "string") {
        paramArr = paramArr.split(',')
    }
    $.map(paramArr, function (item, i) {
        if (item === "*" || item === "-" || item === "+" || item === "/" || item === "(" || item === ")") {
            functionString = functionString + item;
        }
        else {
            if (item.indexOf('num#') >= 0) //is number
            {
                functionString = functionString + GetNumber(item.split('#')[1]);
            }
            else {
                var input = "";
                if ($('#' + PrefixControl + item)[0].type === "select-one") {
                    input = $('#' + PrefixControl + item).val();
                }
                else {
                    input = $('#' + PrefixControl + item + '.ParentID-' + ParentID).val();
                    if (input == undefined && (PrefixControl == null || PrefixControl == "")) {
                        input = $('#' + item).val()
                    }
                }
                if (input === "" || input === undefined || input === null)
                    input = "0";
                else if (!input.indexOf('.')) {
                    input += '.0';
                }
                input = replaceAll(input, ',', '');
                functionString = replaceAll(functionString + GetNumber(input), '--', '+');
            }

        }
    });
    //console.log("functionString");
    //console.log(functionString);
    ret = eval(functionString);
    //console.log(ret);
    ret = FormatNumber(ret, 2);
    $('#' + ControlID + '.ParentID-' + ParentID).val(ret);
    $('#' + ControlID).val(ret);
    $('#' + ControlID).trigger('change');
    $('#labelfor-' + ControlID).html(ret);
    $('#label-' + ControlID + '.ParentID-' + ParentID).html(ret);

}
function fxUpdateSumColumn(PrefixControl, ControlID, funcType, paramArr, OptionConfig, ParentID) {

    var tableID = OptionConfig.split(':')[1];
    var colID = paramArr;
    var jsListString = GetControlsConfig('list-' + tableID);
    var jsList = [];
    var ret = 0;
    if (jsListString !== undefined) {
        jsList = JSON.parse(jsListString);
    }
    if (jsList.length > 0) {
        const sum = jsList
            .map(item => item[colID])
            .reduce((prev, curr) =>
                parseFloat(replaceAll(prev ?? 0, ',', '')) +
                parseFloat(replaceAll(curr ?? 0, ',', ''))
            );

        ret = FormatNumber(sum, 2);
    } else ret = 0;
    $('#' + ControlID + '.ParentID-' + ParentID).val(ret);
    $('#' + ControlID).val(ret);
    $('#labelfor-' + ControlID).html(ret);
    $('#label-' + ControlID + '.ParentID-' + ParentID).text(ret);
    $('#' + ControlID + '.ParentID-' + ParentID).trigger('keyup');
    $('#' + ControlID).trigger('change');

}


function GetNumber(item) {
    if (typeof (item) == "string")
        item = replaceAll(item, ',', '');
    return item == "NaN" || item == "" || item == null ? 0 : Number(item);
}


function fxControlFunction(ControlID, ParentID, fx, OptionConfig, Pattern, Display, TitleConfig) {
    console.log(fx);
    fx = fx.replace(/&quot;/g, '"');
    console.log(fx);
    var arrConfig = OptionConfig.split(':');
    var PrefixControl = "";
    if (arrConfig[0].toLowerCase() === "prefixid") {
        PrefixControl = arrConfig[1];
    }
    if (Pattern === 'GroupBy') {
        var GroupColumn = fx.split(':')[0];
        var SumColumn = fx.split(':')[1];
        $('#' + PrefixControl).on("change", function () {
            fxUpdateGroupByColumn(ControlID, OptionConfig, GroupColumn, SumColumn, Display, TitleConfig);
        });
        fxUpdateGroupByColumn(ControlID, OptionConfig, GroupColumn, SumColumn, Display, TitleConfig);

    }
    if (Pattern === 'SumCol') {
        SumColumn = fx;
        $('#' + PrefixControl).on("change", function () {
            fxUpdateSumByColumn(ControlID, OptionConfig, SumColumn, Display, TitleConfig);
        });
        fxUpdateSumByColumn(ControlID, OptionConfig, SumColumn, Display, TitleConfig);
    }
}
function fxUpdateSumByColumn(ControlID, OptionConfig, SumColumn, Display) {
    var tableID = OptionConfig.split(':')[1];
    var jsListString = GetControlsConfig('list-' + tableID);

    var jsList = [];
    var ret = 0;
    if (jsListString !== undefined) {
        jsList = JSON.parse(jsListString);
    }
    if (jsList.length > 0) {
        const sum = jsList
            .map(item => item[SumColumn])
            .reduce((prev, curr) => Math.floor(replaceAll(prev, ',', '')) + Math.floor(replaceAll(curr, ',', ''), 0));
        ret = sum;
    } else ret = 0;
    $('#' + ControlID).val(ret);
    console.log('Sumcolumn');
    console.log($('#' + ControlID).val());

    var html = '';
    html += ' <div class="browser-card p-b-15 font-weight-bold border-top">';
    html += '   <p class="d-inline-block m-0" style="font-weight:bold;color:crimson">' + (Display != undefined && Display != null ? Display : ControlID) + '</p>';
    html += '   <button class="btn bg-c-pink btn-round float-right btn-browser">' + FormatNumber(ret) + '</button>';
    html += ' </div>';

    $('#fxControl-' + ControlID).html(html);
    $('#' + ControlID).trigger("change");
}

function fxUpdateGroupByColumn(ControlID, OptionConfig, GroupColumn, SumColumn, Display, TitleConfig) {
    var tableID = OptionConfig.split(':')[1];
    var jsListString = GetControlsConfig('list-' + tableID);
    if (GroupColumn == null || GroupColumn == undefined || GroupColumn == "null") {
        GroupColumn = "";
    }
    var jsList = [];
    var ret = 0;
    if (jsListString !== undefined) {
        jsList = JSON.parse(jsListString);
    }
    var result = [];
    var resultsum = {};
    var lstCol = SumColumn.split(',');
    $.map(lstCol, function (colname) {
        resultsum[colname] = 0;
    });

    jsList.reduce(function (res, value) {
        var itemName = value[GroupColumn] == null ? "-" : value[GroupColumn];
        if (!res[itemName]) {
            res[itemName] = {};
            res[itemName].Id = itemName;
            $.map(lstCol, function (colname) {
                res[itemName][colname] = 0;
            });
            result.push(res[itemName]);
        }

        $.map(lstCol, function (colname) {
            res[itemName][colname] += GetNumber(value[colname]);
            resultsum[colname] += GetNumber(value[colname]);
        });
        //res[value[GroupColumn]].val += value[SumColumn];
        return res;
    }, {});

    var html = '';
    ////header
    html += ' <div class="row">';
    html += '   <p class="d-inline-block m-0 font-weight-bold w-50">Items</p>';
    if (TitleConfig != null && TitleConfig != undefined && TitleConfig.length) {
        var listColTitleConfig = TitleConfig.split(',');
        $.map(listColTitleConfig, function (colname) {
            html += '<p class="d-inline-block m-0 font-weight-bold float-right w-25">' + colname + '</p>';
        });
    }
    else {
        $.map(lstCol, function (colname) {
            html += '<p class="d-inline-block m-0 font-weight-bold float-right w-25">' + colname + '</p>';
        });
    }
    html += ' </div>';
    ////body
    $.map(result, function (item, i) {
        html += ' <div class="row p-b-15 border-top">';
        html += '   <p class="d-inline-block m-0 font-italic w-50">' + (item.Id != undefined && item.Id != null ? item.Id : Display) + '</p>';
        $.map(lstCol, function (colname) {
            //html += '    <div class="btn bg-c-yellow btn-round float-right btn-browser w-20">' + FormatNumber(item[colname]) + '</div>';
            html += '<p class="d-inline-block m-0 font-weight-bold font-italic text-primary float-right w-25">' + FormatNumber(item[colname]) + '</p>';
        });
        html += ' </div>';
    });
    ////footer
    html += ' <div class="row p-b-15 border-top">';
    html += '   <p class="d-inline-block text-danger font-weight-bold m-0 w-50"> Summary </p>';
    $.map(lstCol, function (colname) {
        //html += '    <div class="btn bg-c-yellow btn-round float-right btn-browser w-25">' + FormatNumber(resultsum[colname]) + '</div>';
        html += '<p class="d-inline-block m-0 pr-2 font-weight-bold text-danger float-right w-25">' + FormatNumber(resultsum[colname]) + '</p>';
    });
    html += ' </div>';

    $('#fxControl-' + ControlID).html(html);
    $('#' + ControlID).val(resultsum[lstCol[lstCol.length - 1]]);
    console.log("summary");
    console.log($('#' + ControlID).val());
    $('#' + ControlID).trigger("change");
}

function replaceAll(str, find, replace) {
    if (str === undefined) return str;

    return String(str).replace(new RegExp(find, 'g'), replace);
}
////format number custom

function ConvertNumberToTextVN(SoTien) {

    var ChuSo = new Array(" không ", " một ", " hai ", " ba ", " bốn ", " năm ", " sáu ", " bảy ", " tám ", " chín ");
    var Tien = new Array("", " nghìn", " triệu", " tỷ", " nghìn tỷ", " triệu tỷ");
    var lan = 0;
    var i = 0;
    var so = 0;
    var KetQua = "";
    var tmp = "";
    var ViTri = new Array();
    if (SoTien < 0) return "Số tiền âm !";
    if (SoTien === 0) return "Không!";
    if (SoTien > 0) {
        so = SoTien;
    }
    else {
        so = -SoTien;
    }
    if (SoTien > 8999999999999999) {
        //SoTien = 0;
        return "Số quá lớn!";
    }
    ViTri[5] = Math.floor(so / 1000000000000000);
    if (isNaN(ViTri[5]))
        ViTri[5] = "0";
    so = so - parseFloat(ViTri[5].toString()) * 1000000000000000;
    ViTri[4] = Math.floor(so / 1000000000000);
    if (isNaN(ViTri[4]))
        ViTri[4] = "0";
    so = so - parseFloat(ViTri[4].toString()) * 1000000000000;
    ViTri[3] = Math.floor(so / 1000000000);
    if (isNaN(ViTri[3]))
        ViTri[3] = "0";
    so = so - parseFloat(ViTri[3].toString()) * 1000000000;
    ViTri[2] = parseInt(so / 1000000);
    if (isNaN(ViTri[2]))
        ViTri[2] = "0";
    ViTri[1] = parseInt((so % 1000000) / 1000);
    if (isNaN(ViTri[1]))
        ViTri[1] = "0";
    ViTri[0] = parseInt(so % 1000);
    if (isNaN(ViTri[0]))
        ViTri[0] = "0";
    if (ViTri[5] > 0) {
        lan = 5;
    }
    else if (ViTri[4] > 0) {
        lan = 4;
    }
    else if (ViTri[3] > 0) {
        lan = 3;
    }
    else if (ViTri[2] > 0) {
        lan = 2;
    }
    else if (ViTri[1] > 0) {
        lan = 1;
    }
    else {
        lan = 0;
    }
    for (i = lan; i >= 0; i--) {
        tmp = DocSo3ChuSo(ViTri[i]);
        KetQua += tmp;
        if (ViTri[i] > 0) KetQua += Tien[i];
        if ((i > 0) && (tmp.length > 0)) KetQua += ',';//&& (!string.IsNullOrEmpty(tmp))
    }
    if (KetQua.substring(KetQua.length - 1) === ',') {
        KetQua = KetQua.substring(0, KetQua.length - 1);
    }
    KetQua = KetQua.substring(1, 2).toUpperCase() + KetQua.substring(2);

    //xu ly phan so thap phan
    var strVal = SoTien.toString();
    var strPercent = "";
    var checkDot = strVal.indexOf(".") > -1 ? true : false;
    if (checkDot) {
        strPercent = "phẩy ";
        strVal = strVal.split(".")[1];
        if (strVal.length > 3) {
            strVal = strVal.substring(0, 3);
        }

        var tmpArr = DocSo3ChuSoDocSoKhongDauTien(strVal);
        strPercent += tmpArr;
    }
    KetQua += " " + strPercent;
    return KetQua;//.substring(0, 1);//.toUpperCase();// + KetQua.substring(1);
}

function DocSo3ChuSo(baso) {

    var ChuSo = new Array(" không ", " một ", " hai ", " ba ", " bốn ", " năm ", " sáu ", " bảy ", " tám ", " chín ");
    var Tien = new Array("", " nghìn", " triệu", " tỷ", " nghìn tỷ", " triệu tỷ");

    var tram;
    var chuc;
    var donvi;
    var KetQua = "";
    tram = parseInt(baso / 100);
    chuc = parseInt((baso % 100) / 10);
    donvi = baso % 10;
    if (tram == 0 && chuc == 0 && donvi == 0) return "";
    if (tram != 0) {
        KetQua += ChuSo[tram] + " trăm ";
        if ((chuc == 0) && (donvi != 0)) KetQua += " linh ";
    }
    if ((chuc != 0) && (chuc != 1)) {
        KetQua += ChuSo[chuc] + " mươi";
        if ((chuc == 0) && (donvi != 0)) KetQua = KetQua + " linh ";
    }
    if (chuc == 1) KetQua += " mười ";
    switch (donvi) {
        case 1:
            if ((chuc != 0) && (chuc != 1)) {
                KetQua += " mốt ";
            }
            else {
                KetQua += ChuSo[donvi];
            }
            break;
        case 5:
            if (chuc == 0) {
                KetQua += ChuSo[donvi];
            }
            else {
                KetQua += " lăm ";
            }
            break;
        default:
            if (donvi != 0) {
                KetQua += ChuSo[donvi];
            }
            break;
    }
    return KetQua;
}

function DocSo3ChuSoDocSoKhongDauTien(baso) {

    var ChuSo = new Array(" không ", " một ", " hai ", " ba ", " bốn ", " năm ", " sáu ", " bảy ", " tám ", " chín ");
    var Tien = new Array("", " nghìn", " triệu", " tỷ", " nghìn tỷ", " triệu tỷ");

    var tram;
    var chuc;
    var donvi;
    var KetQua = "";
    tram = parseInt(baso / 100);
    chuc = parseInt((baso % 100) / 10);
    donvi = baso % 10;
    if (tram === 0 && chuc === 0 && donvi === 0) return 0;
    if (tram !== 0 || baso.indexOf("0") === 0) {

        KetQua += ChuSo[tram] + " trăm ";
        if ((chuc === 0) && (donvi !== 0)) KetQua += " linh ";
    }
    if ((chuc !== 0) && (chuc !== 1)) {
        KetQua += ChuSo[chuc] + " mươi";
        if ((chuc === 0) && (donvi !== 0)) KetQua = KetQua + " linh ";
    }
    if (chuc === 1) KetQua += " mười ";
    switch (donvi) {
        case 1:
            if ((chuc !== 0) && (chuc !== 1)) {
                KetQua += " mốt ";
            }
            else {
                KetQua += ChuSo[donvi];
            }
            break;
        case 5:
            if (chuc === 0) {
                KetQua += ChuSo[donvi];
            }
            else {
                KetQua += " lăm ";
            }
            break;
        default:
            if (donvi !== 0) {
                KetQua += ChuSo[donvi];
            }
            break;
    }
    return KetQua;
}

function FormatNumber(val, nDec, type) {
    if (val === undefined || val === null) return 0;
    val = val.toString();
    val = val.replace(/,/g, "");
    val = val.replace(/%/g, "");
    if (isNaN(val) || val === "" || val == 0) {
        return "0";
    }
    val = parseFloat(val);
    var strVal = val.toString();
    var checkDot = strVal.indexOf(".") > -1 ? true : false;
    var intergerVal = "";
    var rightDot = "";
    if (checkDot) {
        intergerVal = strVal.split(".")[0];
        rightDot = strVal.split(".")[1];
        if (rightDot.length > 0 && nDec > 0)
            rightDot = "." + rightDot.substring(0, nDec);
        else rightDot = "";
    }
    else {
        intergerVal = strVal;
    }
    var arrInterger = intergerVal.split("").reverse();
    var result = "";
    for (var i = 0; i < arrInterger.length; i++) {
        result += arrInterger[i];
        if ((i + 1) % 3 === 0 && (i + 1) < arrInterger.length) {
            result += ",";
        }
    }
    result = result.split("").reverse().join("");
    result = result + rightDot;
    if (type === "PERCENT") {
        result = result + " %";
    }
    return replaceAll(result, '-,', '-');
}

function InitSchedule(ControlID) {
    console.log('InitSchedule');
    $("#IsRepeated").change(function () {
        $("#collapse-IsRepeated").toggle();
        UpdateScheduleString(ControlID);
    });

    $("#InTimeString").change(function () {
        console.log('in time');
        UpdateScheduleString(ControlID);
    });
    $("#InWeekdayString").change(function () {
        UpdateScheduleString(ControlID);
    });
    $("#InMonthdayString").change(function () {
        UpdateScheduleString(ControlID);
    });

    function UpdateScheduleString(ControlID) {
        var jsData = {};
        $('#RepeatType').val($("ul#pills-tab a.active").attr("data-type"));
        jsData.IsRepeated = $("#IsRepeated")[0].checked;
        jsData.RepeatType = $("#RepeatType").val();
        jsData.InTimeString = $("#InTimeString").val();
        jsData.InWeekdayString = $("#InWeekdayString").val();
        jsData.InMonthdayString = $("#InMonthdayString").val();
        var data = JSON.stringify(jsData);
        console.log(jsData);

        $('#' + ControlID).val(data);
        UpdateTitleSchedule();
    }
    var InTimeString = $("#InTimeString").val();
    var InWeekdayString = $("#InWeekdayString").val();
    var InMonthdayString = $("#InMonthdayString").val();

    ObjectCheckGroupSet('InTimeString', InTimeString);
    ObjectCheckGroupSet('InWeekdayString', InWeekdayString);
    ObjectCheckGroupSet('InMonthdayString', InMonthdayString);
    ObjectCheckGroupAddEventOnClick('InTimeString');
    ObjectCheckGroupAddEventOnClick('InWeekdayString');
    ObjectCheckGroupAddEventOnClick('InMonthdayString');
}

function UpdateTitleSchedule() {
    var InTimeString = $("#InTimeString").val();
    var InWeekdayString = $("#InWeekdayString").val();
    var InMonthdayString = $("#InMonthdayString").val();
    var RepeateStringTitle = "";
    if (InTimeString.length) {
        InTimeString = InTimeString + " giờ, ";
    }
    if (InWeekdayString.length) {
        RepeateStringTitle = "vào thứ " + InWeekdayString + " hàng tuần.";
    }
    if (InMonthdayString.length) {
        RepeateStringTitle = "vào ngày " + InMonthdayString + " hàng tháng.";
    }

    $('#InTimeStringTitle').html(InTimeString);
    $('#RepeateStringTitle').html(RepeateStringTitle);

}

/////////////////
function UploadFileProcess(ControlID) {
    var i = 0;
    var ins = document.getElementById('AttachFile-' + ControlID);
    var formdata = new FormData();
    var count = 0;
    for (i = 0; i < ins.files.length; i++) {
        var file = ins.files[i];
        resizeImg(file, i, function (val) {
            formdata.append('AttachFile', val);
            formdata.append('FormCode', $("#FormCode").val());
            formdata.append('ControlID', ControlID);

            count += 1;
            if (count === ins.files.length) {
                callAjaxUpload(formdata);
            }
        });
    }

    function callAjaxUpload(formdata) {
        $.ajax({
            type: "POST",
            url: "/Categories/ControlsBase/UploadFileProcess",
            contentType: false,
            processData: false,
            data: formdata,
            success: function (result) {
                CheckResponse(result);
                if (result.length) {
                    CheckUploadFileToChangeStatus = true;
                    notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thành công');
                    var fileList = [];
                    var Data = $('#' + ControlID).val();
                    if (Data.length) {
                        fileList = JSON.parse(Data);
                    }
                    var jsObject = JSON.parse(result);
                    var pos = jsObject.FileName.lastIndexOf("\/");
                    var fileName = jsObject.FileName.substr(pos + 1);
                    fileList.push(
                        {
                            Code: fileName,
                            Name: jsObject.FileNameDisplay,
                            Val: jsObject.FileName
                        }
                    );
                    $('#' + ControlID).val(JSON.stringify(fileList));
                    InitObjectViewFileList(ControlID, "0");
                } else {
                    CheckUploadFileToChangeStatus = false;
                }
            },
            error: function (xhr, status, p3, p4) {
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
            }
        });
    }
}
function InitObjectViewFileList(ControlID, Disable) {
    var fileList = [];
    var Data = $('#' + ControlID).val();
    if (Data.length) {
        fileList = JSON.parse(Data);
    }

    var html = '';
    var arrViewImage = "png,jpg,jpeg,bmp";
    for (var i = 0; i < fileList.length; i++) {
        var item = fileList[i];
        var pos = item.Name.lastIndexOf(".");
        var check = item.Name.substr(pos + 1);
        //if (arr.indexOf(check.toLowerCase()) >= 0) {
        //    html += '<div class="to-do-list file-download-list position-relative"><a href="' + item.Val + '" target="_blank" class="download" FileID="' + i + '"><img width="30" height="30" src="' + item.Val + '" /> ' + item.Name + '</a><div class="i-delete-file"><a href="javascript:void(0);" class="delete_todolist delete_todolist-file" fileid="' + i + '"><i class="fa fa-times-circle"></i></a></div></div>';
        //} else {
        //    html += '<div class="to-do-list file-download-list position-relative"><a href="' + item.Val + '" target="_blank" class="download" FileID="' + i + '"><i class="fa fa-file text-info mr-1 ml-2"></i> ' + item.Name + '</a><div class="i-delete-file"><a href="javascript:void(0);" class="delete_todolist delete_todolist-file" fileid="' + i + '"><i class="fa fa-times-circle"></i></a></div></div>';
        //}
        if (arrViewImage.indexOf(check.toLowerCase()) >= 0) {
            html += '<div class="to-do-list file-download-list position-relative">';
            html += '   <a href="' + item.Val + '" target="_blank" class="download" FileID="' + i + '">';
            html += '       <img width="80" src="' + item.Val + '"></img> ' + item.Name;
            html += '   </a>';

            if (Disable != "1" && Disable != "disable") {
                html += '<div class="i-delete-file">';
                html += '    <a href="javascript:void(0);" class="delete_todolist delete_todolist-file" fileid="' + i + '">';
                html += '        <i class="fa fa-times-circle"></i>';
                html += '    </a>';
                html += ' </div>';
            }

            html += '</div>';

        } else {
            html += '<div class="to-do-list file-download-list position-relative">';
            html += '   <a href="' + item.Val + '" target="_blank" class="download" FileID="' + i + '">';
            html += '       <i class="fa fa-file text-info mr-1 ml-2"></i> ' + item.Name;
            html += '   </a>';
            if (Disable != "1" && Disable != "disable") {
                html += '<div class="i-delete-file">';
                html += '    <a href="javascript:void(0);" class="delete_todolist delete_todolist-file" fileid="' + i + '">';
                html += '        <i class="fa fa-times-circle"></i>';
                html += '    </a>';
                html += ' </div>';
            }
            html += '</div>';
        }
    }
    $('#ListFile-' + ControlID).html(html);
    $(".delete_todolist-file").off("click");
    $(".delete_todolist-file").on("click", function () {
        console.log('ondelete');
        $(this).parent().parent().fadeOut();
        $(this).parent().parent().remove();
        var ele = $(this).attr('fileid');
        var fileid = [];
        var Data = $('#' + ControlID).val();
        if (Data.length) {
            fileid = JSON.parse(Data);
        }
        fileid.splice(ele, 1);
        $('#' + ControlID).val(JSON.stringify(fileid));
        InitObjectViewFileList(ControlID, "0");
    });
    $('#AttachFile').val('');
    $('#AttachFile-' + ControlID).val('');

}
function PreviewImageUpload(ControlID) {
    var arr = "png,jpg,jpeg,bmp";
    var item = $('#fileInput-' + ControlID)[0].files[0];
    var pos = item.name.lastIndexOf(".");
    var check = item.name.substr(pos + 1);
    if (arr.indexOf(check.toLowerCase()) >= 0) {
        var formData = new FormData();

        formData.append(ControlID, $('#fileInput-' + ControlID)[0].files[0]);
        formData.append('UserID_Check', $('#UserID_Check').val());
        formData.append('FileUploadType', $('#FileUploadType-' + ControlID).val());

        $.ajax({
            url: '/Categories/ControlsBase/UploadCompanyImage',
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function (rep) {
                CheckResponse(rep);
                if (rep !== '0' && rep !== '-1') {
                    console.log(rep);
                    //ShowMessage('success', 'Thông báo', 'Cập nhật avatar thành công.', 500, '');
                    $('#' + ControlID).val(rep);
                    $('#fileInput-' + ControlID).attr('data-default-file', rep);
                    $('#PreViewFileUpload-' + ControlID).attr('src', rep);
                }
                else {
                    if (rep === '0') {
                        ShowMessage('danger', 'Thông báo', 'File không đúng định dạng, avatar phải là file ảnh', 500, '');
                    }
                    else {
                        ShowMessage('danger', 'Thông báo', 'Có lỗi xảy ra trong quá trình xử lý dữ liệu', 500, '');
                    }
                }
            }
        });
    }
    else {
        ShowMessage('danger', 'Thông báo', 'Yêu cầu định dạng file: ' + arr, 500, '');
    }
}


//////////////Object In charge
function ObjectInChargeInit(ControlID, objectInChargeString) {
    $('#' + ControlID).val(objectInChargeString);
    var ObjectInChargeList = [];
    if (objectInChargeString.length) {
        ObjectInChargeList = JSON.parse(objectInChargeString);
    }
    $('#boxObjectInChargeList-' + ControlID).html('');
    RenderListObjectIncharge(ControlID);

    $('#ObjectInChargeType-' + ControlID).change(function () {
        console.log('ObjectInChargeType');

        $('#nameError').html('');
        if ($(this).val() !== 'SEARCH') {
            //$('#' + ControlID).val(null);
            $('#divObjectInChargeSearch-' + ControlID).addClass('d-none');
            $('#divObjectInChargeList-' + ControlID).removeClass('d-none');

            SelectListData('ObjectInChargeList-' + ControlID, '', '-select-', 'PSYS.ObjectInChargeType_GetList', '', '', '@ObjectType=\'' + $(this).val() + '\'', 1, '', 'SelectListAjax');
        } else {
            $('#divObjectInChargeSearch-' + ControlID).removeClass('d-none');
            $('#divObjectInChargeList-' + ControlID).addClass('d-none');

        }
    });

    $('#ObjectInChargeList-' + ControlID).change(function () {
        if ($(this).val() !== null && $(this).val() !== '') {
            // check isExist
            var ObjectInChargeList = [];
            var data = $('#' + ControlID).val();
            if (data.length) {
                ObjectInChargeList = JSON.parse(data);
            }
            var pos = ObjectInChargeList.map(function (e) { return e.Code; }).indexOf($(this).val());
            if (pos > -1) {
                return;
            }
            var pos2 = ObjectInChargeList.map(function (e) { return e.Code; }).indexOf("ALL");
            if (pos2 > -1) {
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Bạn đã chọn tất cả, vui lòng bỏ chọn "ALL" để chọn lại.');
                return;
            }
            var obj = {
                Name: $('#ObjectInChargeList-' + ControlID + ' option:selected').text(),
                Code: $(this).val()
            };
            if (obj.Code === "ALL") {
                ObjectInChargeList = [];
            }
            ObjectInChargeList.push(obj);
            $('#' + ControlID).val(JSON.stringify(ObjectInChargeList));
            RenderListObjectIncharge(ControlID);
            $('#ObjectInChargeList-' + ControlID).val(null).trigger('change');
            notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thành công');
        }
    });


    $('#ObjectInChargeSearch-' + ControlID).change(function () {
        if ($(this).val() !== null && $(this).val() !== '') {
            // check isExist
            var ObjectInChargeList = [];
            var data = $('#' + ControlID).val();
            if (data.length) {
                ObjectInChargeList = JSON.parse(data);
            }
            pos = ObjectInChargeList.map(function (e) { return e.Code; }).indexOf($(this).val());
            if (pos > -1) {
                return;
            }
            var obj = {
                Name: $('#ObjectInChargeSearch-' + ControlID + ' option:selected').text(),
                Code: $(this).val()
            };
            ObjectInChargeList.push(obj);
            $('#' + ControlID).val(JSON.stringify(ObjectInChargeList));
            RenderListObjectIncharge(ControlID);
            $('#ObjectInChargeSearch-' + ControlID).val(null).trigger('change');
            notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thành công');
        }
    });

    $('#ObjectInChargeSearch-' + ControlID).select2({
        ajax: {
            type: "POST",
            url: '/Categories/ControlsBase/SelectTBListAjax',
            dataType: 'json',
            delay: 250,
            data: function (params) {
                return {
                    DataSource: 'PSYS.ObjectInChargeType_GetList',
                    cd: '@KeySearch=\'' + params.term + '\',@ObjectType=\'SEARCH\''
                };
            },
            processResults: function (data, params) {
                var formatData = $.map(data, function (obj) {
                    obj.id = obj.Code;
                    obj.text = obj.Name;
                    return obj;
                });
                return {
                    results: formatData,
                };
            },
            cache: true
        },
        escapeMarkup: function (markup) {
            return markup;
        }, // let our custom formatter work
        minimumInputLength: 3
    });

    $("#btnImport-" + ControlID).on("click dblclick", function (e) {
        e.preventDefault();
        $('#fileUpload-' + ControlID).trigger('click');
        //sleep(500);
        e.stopPropagation();
        return;
    });

    $("#fileUpload-" + ControlID).change(function () {
        $("#btnImport-" + ControlID).attr("disabled", "disabled").val("Loading...");
        var fileExtension = "xlsx,xls";
        var filename = $(this).get(0).files[0].name;
        var ext = filename.substr(filename.lastIndexOf('.') + 1, filename.length - 1 - filename.lastIndexOf('.'));
        console.log(ext);
        if (fileExtension.indexOf(ext) < 0) {
            alert("Please check required format:" + fileExtension);
            $("#fileUpload-" + ControlID).val("");
            $("#btnImport-" + ControlID).removeAttr("disabled").val("Import Excel");
        }
        else {
            $("#btnImport-" + ControlID).attr("disabled", "disabled").val("Loading...");
            //$('#listObjectInCharge'+ ControlID).html("");
            strJsonUserList = "";
            var fileData = new FormData();
            fileData.append("file0", $(this).get(0).files[0]);
            fileData.append("formatType", "ObjectInCharge");
            var action = "/Categories/ControlsBase/Loadexcel";
            ShowThemeLoader(1);
            $.ajax({
                type: "POST",
                url: action,
                contentType: false,
                processData: false,
                data: fileData,
                timeout: 360000,
                success: function (result) {
                    CheckResponse(result);
                    if (result.StatusCode === "DONE") {
                        var listTempPerson = [];
                        for (var i = 0; i < result.listObjectInCharge.length; i++) {
                            var obj = {
                                Name: result.listObjectInCharge[i].Name,
                                Code: result.listObjectInCharge[i].Code
                            };
                            listTempPerson.push(obj);
                        }
                        var nameError = [];
                        for (i = 0; i < result.listError.length; i++) {
                            nameError.push(result.listError[i].Name);
                        }
                        var html = '<div class="mb-0"><span style="color:red;font-weight:bold">Có ' + result.listObjectInCharge.length + '/' + (result.listError.length + result.listObjectInCharge.length) + '</span> dòng được import</div>';
                        if (nameError && nameError.length) {
                            html += '<div class="mb-1 text-danger"> Not found: ' + nameError.join(', ') + '.</div>';
                        }
                        $('#nameError-' + ControlID).html(html);
                        $('#' + ControlID).val(JSON.stringify(listTempPerson));
                        RenderListObjectIncharge(ControlID);
                        $("#fileUpload-" + ControlID).val("");
                        $("#btnImport-" + ControlID).removeAttr("disabled").val("Import excel");
                    }
                    ShowThemeLoader(0);
                },
                error: function (xhr, status, p3, p4) {
                    $("#btnImport-" + ControlID).removeAttr("disabled").val("Import Excel");
                    notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', "Lỗi không thể đọc file excel.");
                    console.log(xhr);
                    console.log(status);
                    console.log(p3);
                    console.log(p4);
                    ShowThemeLoader(0);
                }
            });
        }
    });


}
function RemoveObjectInCharge(item) {
    var idArr = item.id.split('-');
    var ControlID = idArr[0];
    var pos = idArr[1];
    var ObjectInChargeList = [];
    var data = $('#' + ControlID).val();
    if (data.length) {
        ObjectInChargeList = JSON.parse(data);
    }
    if (pos >= 0) {
        ObjectInChargeList.splice(pos, 1);
    }
    $('#' + ControlID).val(JSON.stringify(ObjectInChargeList));
    RenderListObjectIncharge(ControlID);
}

function RenderListObjectIncharge(ControlID) {
    var list = [];
    var data = $('#' + ControlID).val();
    if (data.length) {
        list = JSON.parse(data);
    }
    if (list) {
        var strTag = '';
        var add = '';
        $.map(list, function (field, i) {
            if (i > 9) {
                add = '<span class="mt-1 f-14">+' + (list.length - 10) + '</span>';
                return false;
            }
            if (field) {
                strTag += '<div class="col-form-label m-r-10 hashTagBox" >';
                //if (1 == 1) { //nếu là tạo mới, cho phép chỉnh sửa
                strTag += '<span id ="' + ControlID + '-' + i + '" onclick="RemoveObjectInCharge(this);">×</span>';
                //}
                strTag += '<span class="temp-field-' + field.Code + '" title="">' + field.Name + '</span></div>';
            }
        });
        strTag += add;
        $('#boxObjectInChargeList-' + ControlID).html(strTag);
    }

}
function sleep(milliseconds) {
    var start = new Date().getTime();
    for (var i = 0; i < 1e7; i++) {
        if ((new Date().getTime() - start) > milliseconds) {
            break;
        }
    }
}

function init_Sign_Canvas() {
    $("#SignNote").val("");
    isSign = false;
    leftMButtonDown = false;
    var sizedWindowWidth = $("#ApprovedModal").width();
    console.log(sizedWindowWidth);

    if (sizedWindowWidth > 500)
        sizedWindowWidth = 345;
    else
        sizedWindowWidth = sizedWindowWidth - 30.5;
    console.log(sizedWindowWidth);

    $("#canvas").width(sizedWindowWidth);
    $("#canvas").height(200);
    $("#canvas").css("border", "1px solid #cccccc");

    var canvas = $("#canvas").get(0);
    canvasContext = canvas.getContext('2d');

    if (canvasContext) {//background
        canvasContext.canvas.width = sizedWindowWidth;
        canvasContext.canvas.height = 200;
        canvasContext.fillStyle = "rgba(0,0,0,0)";
        canvasContext.fillRect(0, 0, sizedWindowWidth, 200);
        //canvasContext.moveTo(50, 150);
        canvasContext.stroke();
        canvasContext.fillStyle = "#000";//black
        canvasContext.font = "20px Arial";
    }
    // Bind Mouse events
    $(canvas).on('mousedown', function (e) {
        if (e.which === 1) {
            leftMButtonDown = true;
            canvasContext.fillStyle = "#000";
            var x = e.pageX - $(e.target).offset().left;
            var y = e.pageY - $(e.target).offset().top;
            canvasContext.moveTo(x, y);
        }
        e.preventDefault();
        return false;
    });

    $(canvas).on('mouseup', function (e) {
        if (leftMButtonDown && e.which === 1) {
            leftMButtonDown = false;
            isSign = true;
        }
        e.preventDefault();
        return false;
    });

    // draw a line from the last point to this one
    $(canvas).on('mousemove', function (e) {
        if (leftMButtonDown === true) {
            canvasContext.fillStyle = "#000";
            var x = e.pageX - $(e.target).offset().left;
            var y = e.pageY - $(e.target).offset().top;
            canvasContext.lineTo(x, y);
            canvasContext.stroke();
        }
        e.preventDefault();
        return false;
    });

    //bind touch events
    $(canvas).on('touchstart', function (e) {
        leftMButtonDown = true;
        canvasContext.fillStyle = "#000";
        var t = e.originalEvent.touches[0];
        var x = t.pageX - $(e.target).offset().left;
        var y = t.pageY - $(e.target).offset().top;
        canvasContext.moveTo(x, y);

        e.preventDefault();
        return false;
    });

    $(canvas).on('touchmove', function (e) {
        canvasContext.fillStyle = "#000";
        var t = e.originalEvent.touches[0];
        var x = t.pageX - $(e.target).offset().left;
        var y = t.pageY - $(e.target).offset().top;
        canvasContext.lineTo(x, y);
        canvasContext.stroke();

        e.preventDefault();
        return false;
    });
    $(canvas).on('touchend', function (e) {
        if (leftMButtonDown) {
            leftMButtonDown = false;
            isSign = true;
        }
    });
}
function htmlEscape(str) {
    return str
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

function urlQueryEscape(str) {
    return str
        .replace(/&/g, '%26');
}


function ApprovedOnClick() {
    var canvas = $("#canvas").get(0);
    var imgData = canvas.toDataURL();
    var DocumentID = $("#ID").val();
    var FormCode = $("#FormCode").val();
    var data = "DocumentID=" + DocumentID + "&FormCode=" + FormCode + '&signDoc=' + htmlEscape(imgData);
    console.log(data);

    $.ajax({
        type: "POST",
        url: "/Categories/CategoriesBase/CreateSignPath",
        data: data,
        success: function (response) {
            CheckResponse(response);
            if (response !== "ERR" && response !== undefined) {
                var id = $('#ApprovedActionID').val();
                var step = $('#ApprovedActionStep').val();
                if (step == "Clone") {
                    notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response.StatusMess);
                    var RedirectOnApproval = $("#RedirectOnApproval").val();
                    if (RedirectOnApproval !== undefined && RedirectOnApproval !== "") {
                        window.location = RedirectOnApproval;
                    }
                    else
                        window.location = "/";
                }

                var step = $('#ApprovedActionStep').val();
                var delegate = $('#ApprovedDelegate').val();
                if (DocumentID > 0 && step.toLowerCase() != 'end') {
                    CateAddUpdateFunction(id, step, response, 'hotreload', '', delegate);
                }
                else {
                    CateAddUpdateFunction(id, step, response, '', delegate);
                    //sleep(1000);

                }

            }
            else {
                console.log('Checkloi1');
                console.log(response);
                $('#ApprovedActionID').val(null);
                $('#ApprovedActionStep').val(null);
                $('#ApprovedDelegate').val(null);
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response.StatusMess);
            }
        },
        error: function (response) {
            console.log('Checkloi2')
            console.log(response);
            $('#ApprovedActionID').val(null);
            $('#ApprovedActionStep').val(null);
            $('#ApprovedDelegate').val(null);
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
        }

    });

}

function ApprovedModalOnClick(ActionID, StepTo, ID) {
    if (ID !== undefined && ID.length > 0) {
        $("#ID").val(ID);

        var form = $('#CateAddUpdateForm');
        if (form.find("#ID") !== undefined) {
            form.find("#ID").val(ID);
        }
    }
    var DocumentID = $("#ID").val();
    var ViewCode = $("#ViewCode").val();
    var FormCode = $("#FormCode").val();
    $("#Action").val(ActionID);
    console.log($("#Action").val());
    var delegate = $('#ApprovedDelegate').val();
    if (DocumentID > 0 || ViewCode.length > 0) {
        CateAddUpdateFunction(ActionID, StepTo, '', 'Modal', 'Modal', delegate);
    }
}
function ApprovedID(ActionID, StepTo, ID, item) {
    if (ID !== undefined && (ID.length > 0 || ID > 0)) {
        $("#ID").val(ID);
        $("#DocumentID").val(ID);

        var form = $('#CateAddUpdateForm');
        if (form.find("#ID") !== undefined) {
            form.find("#ID").val(ID);
            form.find("#DocumentID").val(ID);
        }
    }
    var DocumentID = $("#ID").val();
    $("#Action").val(ActionID);
    console.log(DocumentID);

    var form = $(item).closest("tr");

    var disabledListControl = form.find(':input:disabled').removeAttr('disabled');
    var RowData = form.find(':input').serializeArray();
    RowData = JSON.stringify(RowData);
    disabledListControl.attr("disabled", "disabled");
    $("#RowData").val(RowData);
    console.log(RowData);
    CateAddUpdateFunction(ActionID, StepTo, '', 'Modal', 'Modal');

}


/////////comment

function getListMessage(idComment, sourceComment) {
    var ReferenceID = $('#CommentRefID').val();
    if (ReferenceID == undefined || ReferenceID == null || ReferenceID == 0) {
        ReferenceID = $('#ID').val();
    }
    var FormCode = $("#CommentFormID").val();
    if (FormCode == undefined || FormCode == null) {
        FormCode = $("#FormCode").val();
    }
    var DateSelect = $('#DateSelect').val();
    var SessionID = $('#FSessionID').val();
    var data = "ReferenceID=" + ReferenceID + "&ParentID=" + idComment + "&FormCode=" + FormCode + "&SessionID=" + SessionID + "&DateSelect=" + DateSelect;
    console.log(data);
    $.ajax({
        type: "POST",
        url: '/Categories/Notification/ListComment',
        data: data,
        success: function (response) {
            CheckResponse(response);
            if (response && response.length > 0) {
                var html = '';
                $("#list-message").html('');
                countMessage = response.length;
                $.map(response, function (item) {
                    html += '<div id="idMessage' + item.CommentID + '" class="media mt-2"><a class="media-left" href = "javascript:void(0);"><img class="media-object img-radius comment-img" src="' + item.Avatar + '" alt="' + item.EmployeeName + '" onerror="this.src=\'/Files/Avatar/avatarnull.png\'"></a><div class="media-body"><h6 class="media-heading">' + item.EmployeeName + '<span class="f-12 text-muted m-l-5">' + item.DateCommentStr + '</span></h6><p class="m-b-0">' + item.Message + '</p><div class="mb-0 box-reply">';
                    if (item.CountChild > 0) {
                        html += '<span class="load-comment"><a href="javascript:void(0);" onclick="loadCommentChild(' + item.CommentID + ')" class="m-r-10 f-12 text-danger">Tải bình luận(' + item.CountChild + ')</a></span>';
                    } else {
                        html += '<span class="reply-comment"><a href="javascript:void(0);" onclick="replyComment(' + item.CommentID + ')" class="m-r-10 f-12">Trả lời</a></span>';
                    }
                    html += '</div> <hr class="my-2"><div class="box-txt-child-cmt"><div class="list-message-child"></div></div></div></div >';

                });

                $("#list-message").append(html);
            }
            else if (idComment == 0) {
                $("#list-message").html('');
            }
            $('#countMessage').text(response.length);
        },
        error: function () {
            $("#list-message").html('');
        }
    });

}
function urlqueryEncode() {

}

function SendMessage(idComment) {
    var ReferenceID = $('#CommentRefID').val();
    if (ReferenceID == undefined || ReferenceID == null || ReferenceID == 0) {
        ReferenceID = $('#ID').val();
    }
    var FormCode = $("#CommentFormID").val();
    if (FormCode == undefined || FormCode == null) {
        FormCode = $("#FormCode").val();
    }

    console.log("comment begin");
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth() + 1; //January is 0!
    var yyyy = today.getFullYear();
    var hhmm = today.toLocaleTimeString().substr(0, 5);
    if (dd < 10) {
        dd = '0' + dd;
    }
    if (mm < 10) {
        mm = '0' + mm;
    }
    today = hhmm + ' ' + dd + '-' + mm + '-' + yyyy;
    console.log(ReferenceID);
    var msg = urlQueryEscape($("#txtMessage" + idComment).val());
    var SessionID = $('#FSessionID').val();
    var DateSelect = $('#DateSelect').val();

    var dataSend = "ReferenceID=" + ReferenceID + "&msg=" + msg + "&ParentID=" + idComment + "&FormCode=" + FormCode + "&SessionID=" + SessionID + "&DateSelect=" + DateSelect;
    console.log(dataSend);
    if (msg.length > 0) {
        $.ajax({
            type: "POST",
            url: '/Categories/Notification/SendMessage',
            data: dataSend,
            success: function (response) {
                CheckResponse(response);
                if (response && response[0]) {
                    var html = '';
                    if (idComment === 0 || idComment === "0") {
                        getListMessage(0, 'SendMessage');
                        $("#txtMessage" + idComment).val('');
                    } else {
                        item = response[0];
                        html = '<div class="media mt-2"><div class="media-left"><a href="javascript:void(0);"><img class="media-object img-radius comment-img" src="' + item.Avatar + '" alt="' + item.EmployeeName + '" onerror="this.src=\'/Files/Avatar/avatarnull.png\'"></a></div><div class="media-body"><h6 class="media-heading">' + item.EmployeeName + '<span class="f-12 text-muted m-l-5">' + item.DateCommentStr + '</span></h6><p class="m-b-0">' + item.Message + '</p><div class="mb-3"></div></div><hr></div>';
                        $("#idMessage" + idComment + ' .list-message-child').append(html);
                        countMessage += 1;
                        $('#countMessage').text(countMessage);
                        $("#txtMessage" + idComment).val('');
                    }

                }
            },
            error: function (ex) {
                console.log(ex);
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Thất bại');
            }
        });
    }

}
function loadCommentChild(idComment) {
    var ReferenceID = $('#CommentRefID').val();
    if (ReferenceID == undefined || ReferenceID == null) {
        ReferenceID = $('#ID').val();
    }
    var FormCode = $("#CommentFormID").val();
    if (FormCode == undefined || FormCode == null) {
        FormCode = $("#FormCode").val();
    }
    $.ajax({
        type: "POST",
        url: '/Categories/Notification/ListComment',
        data: "ReferenceID=" + ReferenceID + "&ParentID=" + idComment + "&FormCode=" + FormCode,
        success: function (response) {
            CheckResponse(response);
            if (response && response.length > 0) {
                var html = '';
                $.map(response, function (item) {
                    html += '<div class="media mt-2"><div class="media-left"><a href = "javascript:void(0);"><img class="media-object img-radius comment-img" src="' + item.Avatar + '" alt="' + item.EmployeeName + '" onerror="this.src=\'/Files/Avatar/avatarnull.png\'"></a></div><div class="media-body"><h6 class="media-heading">' + item.EmployeeName + '<span class="f-12 text-muted m-l-5">' + item.DateCommentStr + '</span></h6><p class="m-b-0">' + item.Message + '</p><div class="mb-3"></div></div><hr></div>';
                });
                $("#idMessage" + idComment + ' .list-message-child').append(html);
                $("#idMessage" + idComment + ' .load-comment').remove();
                var html2 = '<span class="reply-comment"><a href="javascript:void(0);" onclick="replyComment(' + idComment + ')" class="m-r-10 f-12"> Reply</a></span>';
                $("#idMessage" + idComment + ' .box-reply').append(html2);
            }
        },
        error: function () {
        }
    });
}
// remove child
Element.prototype.remove = function () {
    this.parentElement.removeChild(this);
}
NodeList.prototype.remove = HTMLCollection.prototype.remove = function () {
    for (var i = this.length - 1; i >= 0; i--) {
        if (this[i] && this[i].parentElement) {
            this[i].parentElement.removeChild(this[i]);
        }
    }
}
// hiện box bình luận
function replyComment(idComment) {
    var myAvatar = $('#myAvatar').attr("src");
    var myName = $('#myName').text;

    var html = '';
    $('.box-child-txt').remove();
    html =
        '<div class="media box-child-txt">' +
        '<a class="media-left" href = "javascript:void(0);">' +
        '<img class="media-object img-radius m-r-0" src="' + myAvatar + '" alt="' + myName + '" onerror="this.src=\'/Files/Avatar/avatarnull.png\'">' +
        '</a>' +
        '<div class="media-body mb-3">' +
        '<div class="pr-3 mt-1">' +
        '<input type="text" class="form-control form-rounded text-primary txt-comment" placeholder="Nhập bình luận..." idmss="' + idComment + '" id="txtMessage' + idComment + '"></input>' +
        '<div class="text-right m-t-10 visible-xs"><a href="javascript:void(0);" onclick="SendMessage(&quot;' + idComment + '&quot;);" class="btn btn-primary btn-md waves-effect waves-light">Sent</a></div></div>' +
        '</div>' +
        '</div >';
    $('#idMessage' + idComment + ' .box-txt-child-cmt').append(html);

    $(".txt-comment").keyup(function (event) {
        if (event.keyCode === 13) {
            var id = $(this).attr("idmss");
            SendMessage(id);
        }
    });
}

function ChangeTabKey(TabKey) {
    $('#TabKey').val(TabKey);
}
function LoadNameCard(ControlID, CardID, ACTION) {
    var id = $('#ID').val();
    var data = "DataSource=NTF.GetNameCardByID&cd=@CardID:" + CardID + '&ID=' + id + '&ACTION=' + ACTION;

    $.ajax({
        type: "POST",
        url: "/Categories/ControlsBase/SelectCardListAjax",
        data: data,
        success: function (response) {
            CheckResponse(response);
            var jsList = JSON.parse(response);
            if (jsList[0] && jsList[0].FullName) {
                $('#FullName-' + ControlID).text(jsList[0].FullName);

                if (jsList[0].Avatar != undefined && jsList[0].Avatar.indexOf('avatarnull') >= 0)
                    $('#Avatar-' + ControlID).addClass('d-none');
                else $('#Avatar-' + ControlID).attr("src", jsList[0].Avatar);

                $('#JobTitle-' + ControlID).text(jsList[0].JobTitle);
                $('#OrganizationName-' + ControlID).text(jsList[0].OrganizationName);
                $('#div-' + ControlID).removeClass("d-none");
            }
            else {
                $('#div-' + ControlID).addClass("d-none");
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            console.log(errorThrown);
        }
    });

}

function SetConditionActionApprovedButton(ControlID, CondAction) {
    if (ControlID.indexOf('404') > 0 || ControlID.indexOf('401') > 0) {
        if ($('#DocumentID').val().length == 0)
            $('#' + ControlID).addClass("d-none");
        else
            $('#' + ControlID).removeClass("d-none");
        return;
    }
    if (CondAction === undefined || CondAction === "") {
        $('#' + ControlID).removeClass("d-none");
        return;
    }
    var arrConfig = CondAction.split(':');
    var condType = arrConfig[0];
    var arrParam = arrConfig[1].split(',');
    var controlID = arrParam[0];
    var Operator = arrParam[1];
    var OpeVal = arrParam[2];
    var controlValue = GetControlValue($('#' + controlID), 0).val;
    if (controlValue === undefined) return;
    controlValue = replaceAll(controlValue, ',', '');
    if (jsFunctionComparisons(controlValue, Operator, OpeVal) == 0) {
        //var itemAr = document.getElementById(ControlID);
        $('#' + ControlID).addClass("d-none");

    }
    else $('#' + ControlID).removeClass("d-none");

}
function jsFunctionComparisons(controlValue, Operator, OpeVal) {
    Operator = htmlDecode(Operator);
    if (Operator === "=" && controlValue == OpeVal) return 1;
    else if (Operator === "==" && controlValue == OpeVal) return 1;
    else if (Operator === "===" && controlValue == OpeVal) return 1;
    else if (Operator === "!=" && controlValue != OpeVal) return 1;
    else if (Operator === ">" && Math.floor(controlValue) > Math.floor(OpeVal)) return 1;
    else if (Operator === "!==" && Math.floor(controlValue) != Math.floor(OpeVal)) return 1;
    else if (Operator === "<" && Math.floor(controlValue) < Math.floor(OpeVal)) return 1;
    else if (Operator === ">=" && Math.floor(controlValue) >= Math.floor(OpeVal)) return 1;
    else if (Operator === "<=" && Math.floor(controlValue) <= Math.floor(OpeVal)) return 1;
    else return 0;
}
function htmlDecode(input) {
    var doc = new DOMParser().parseFromString(input, "text/html");
    return doc.documentElement.textContent;
}
function ExportData(ControlID, Source, Pattern) {
    debugger;
    var formData = $('#' + ControlID).serialize();
    formData += "&SourceID=" + Source;
    formData += "&Action=" + Pattern;
    formData += "&Action=" + Pattern;
    console.log(formData);


    var dtType = "xlsx"
    var url = "";
    if (Pattern == "ExportDataByID") {
        url = '/Categories/SReports/ExportDataByID';
        dtType = "pdf";
        DataExport(url, dtType, "modal", undefined, undefined, Source, formData);
    }
    else if (Pattern == "ExportDataForPrint") {
        url = '/Categories/CateAddUpdate/ExportDataForPrint';
        dtType = "pdf";
        DataExport(url, dtType, "modal", undefined, undefined, Source, formData);
    }
    else if (Pattern == "ExportDataForPrintMultiFiles") {
        url = '/Categories/CateAddUpdate/ExportDataForPrintMultiFiles';
        dtType = "pdf";
        DataExport(url, dtType, "modal", undefined, undefined, Source, formData);
    }
    else {
        if (formData.indexOf("FormCode") < 0) {
            formData += "&FormCode=" + $('#FormCode').val();
        }

        url = '/Categories/SReports/ExportData';
        dtType = "xlsx";

        $.ajax({
            type: "POST",
            url: url,
            data: formData,
            success: function (rep) {
                debugger;
                CheckResponse(rep);
                if (rep && rep.indexOf('.'))
                    window.location.href = rep;
                else
                    ShowMessage('danger', 'Thông báo', 'Xuất danh sách thất bại. Lỗi truy vấn dữ liệu', 500, '');
            }
        });
    }
}

function DataExport(requestLink, dtType, opentype = "modal", formcode, ListPrint, action, formData) {

    var ID = $('#ID').val().length ? $('#ID').val() : ListPrint;
    var FormCode = formcode != undefined && formcode.length ? formcode : $('#FormCode').val();
    var Action = action != undefined && action.length ? action : $('#Action').val();
    var jsData = "fileType=" + dtType + "&FormCode=" + FormCode + "&ID=" + ID + "&ListPrint=" + ListPrint + "&Action=" + Action + "&" + formData;


    console.log(jsData);
    console.log(requestLink);

    var currentUrl = 'http://' + window.location.host; //+ (window.location.port != 80 ? ':' + window.location.port : '');
    if (dtType === "pdf") {
        $('.frame-pdf').html('<span class="ml-3 text-danger"> Đang tải thông tin...</span>');
        $.ajax({
            type: "POST",
            url: requestLink,
            data: jsData,
            success: function (rep) {
                console.log(rep);
                CheckResponse(rep);

                if (rep.indexOf("pdf") >= 0) {
                    var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || (typeof safari !== 'undefined' && safari.pushNotification));

                    if (opentype == "modal") {
                        if (rep !== '') {
                            if (isSafari) {
                                //console.log(navigator.userAgent);
                                //$('.frame-pdf').html('<span style="color:red;">Bạn có thể tải lại file: </span><a href="' + rep + '">Tại Đây</a>');
                                window.location.href = rep;
                            }
                            else {
                                var htmlStr = '<object data="' + currentUrl + rep + '" type="application/pdf" style="width:100%;height:600px;"></object>';
                                $('.frame-pdf').html(htmlStr);
                                $('#modal_PrintBill').modal("show");
                                console.log(htmlStr);
                            }
                        }
                        else {
                            $('.frame-pdf').html('<span style="color:red;">Không thể tải thông tin</span>');
                        }
                    }
                    else {
                        window.open(rep, '_blank');
                    }
                }
                else {
                    window.open(rep, '_blank');
                    //window.location.href = rep;
                }
            },
            error: function (ex) {
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', 'Không thể tải thông tin' + ex.responseText);
            }
        });
    }
    else
        if (dtType === "xlsx") {
            $.ajax({
                type: "POST",
                url: requestLink,
                data: jsData,
                success: function (rep) {
                    CheckResponse(rep);
                    console.log(rep);
                    if (rep !== '')
                        window.location.href = rep;
                    else
                        CreateAlert('error', 'Xuất danh sách thất bại. Lỗi truy vấn dữ liệu', 0);

                }
            });
        }

}

function addDays(date, days) {
    var result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
}
(function ($) {

    $.topZIndex = function (selector) {
        /// <summary>
        /// 	Returns the highest (top-most) zIndex in the document
        /// 	(minimum value returned: 0).
        /// </summary>	
        /// <param name="selector" type="String" optional="true">
        /// 	(optional, default = "*") jQuery selector specifying
        /// 	the elements to use for calculating the highest zIndex.
        /// </param>
        /// <returns type="Number">
        /// 	The minimum number returned is 0 (zero).
        /// </returns>

        return Math.max(0, Math.max.apply(null, $.map(((selector || "*") === "*") ? $.makeArray(document.getElementsByTagName("*")) : $(selector),
            function (v) {
                return parseFloat($(v).css("z-index")) || null;
            }
        )));
    };

    $.fn.topZIndex = function (opt) {
        /// <summary>
        /// 	Increments the CSS z-index of each element in the matched set
        /// 	to a value larger than the highest current zIndex in the document.
        /// 	(i.e., brings all elements in the matched set to the top of the
        /// 	z-index order.)
        /// </summary>	
        /// <param name="opt" type="Object" optional="true">
        /// 	(optional) Options, with the following possible values:
        /// 	increment: (Number, default = 1) increment value added to the
        /// 		highest z-index number to bring an element to the top.
        /// 	selector: (String, default = "*") jQuery selector specifying
        /// 		the elements to use for calculating the highest zIndex.
        /// </param>
        /// <returns type="jQuery" />

        // Do nothing if matched set is empty
        if (this.length === 0) {
            return this;
        }

        opt = $.extend({ increment: 1 }, opt);

        // Get the highest current z-index value
        var zmax = $.topZIndex(opt.selector),
            inc = opt.increment;

        // Increment the z-index of each element in the matched set to the next highest number
        return this.each(function () {
            this.style.zIndex = (zmax += inc);
        });
    };

})(jQuery);

function GetDataByID(ID, FormCode, SourceType) {
    var statusAddUpdate;
    var SSID = $('#FSessionID').val();
    var jsDataOnclick = "FormCode=" + FormCode + "&SSID=" + SSID + "&ID=" + ID + "&SourceType=" + SourceType;

    $.ajax({
        type: "POST",
        url: "/Categories/CateAddupdate/GetDataByID",
        data: jsDataOnclick,
        async: false,
        success: function (response) {
            CheckResponse(response);
            LoadDataToForm(response);
            return response;
        },
        error: function (response) {
            console.log(response);
            return null;
        }
    });
}
//html editor
function download_to_textbox(url, id, pattern) {
    var element = $("#" + id);
    if (pattern == "HtmlDB" && url != undefined && url.length) {
        var js = JSON.parse(url);
        url = js.filePath;
        element.summernote('code', js.fileContent);
    }
    else if (url != undefined && url.length > 5 && url.indexOf("html") >= 1) {
        $.get(url, null, function (data) {
            console.log('htmledit');
            console.log(element);
            element.summernote('code', data);
        }, "text");
    }
}

function sendFile(file, editor) {
    resizeImg(file, 0, function (val) {
        var data = new FormData();
        data.append("AttachFile", val);
        data.append("Folder", '@Folder');
        $.ajax({
            data: data,
            type: "POST",
            url: "/Categories/ControlsBase/UploadFileSummernote",
            cache: false,
            contentType: false,
            processData: false,
            success: function (url) {
                $(editor).summernote('editor.insertImage', url);
            }
        });
    });
}

function SendRequest(Action, OptionConfig = "", target = "", maxLeng = 100, pattern) {
    var arr = [];
    var i = 0;
    if (maxLeng == undefined || maxLeng == null || maxLeng == 0) { maxLeng = 100; }
    $('.CheckCard:checkbox:checked').map(function () {
        if (i < maxLeng) {
            arr.push(this.id);
            i = i + 1;
        }
    });
    var ViewCode = arr.join('-');
    var FormCode = $('#FormCode').val();
    var configArr = OptionConfig.split(',');

    if (configArr[0] === "ProcessStepChange") {
        if (configArr.length > 1) {
            ProcessStepChange(FormCode, Action, ViewCode, configArr[1], maxLeng);
        }
        else {
            ProcessStepChange(FormCode, Action, ViewCode, maxLeng);
            SubmitFunction();
        }
    }
    else if (configArr[0] === "PrintCheckList") {
        DataExport('/Categories/CateAddUpdate/ExportDataForPrint', 'pdf', 'newtab', FormCode, arr.join(','), Action);
    }
    else if (configArr[0] === "OpenModalProcess" || pattern == "OpenModalProcess") {
        OpenModalProcess(FormCode, 0, ViewCode);
    }
    else if (configArr[0] === "OpenModalForm" || pattern == "OpenModalForm") {
        OpenModalForm(FormCode, Action, 'EDIT');
    }
    else if (configArr[0] === "ApprovedModalOnClick") {
        $.map(arr, function (id) {
            var actionList = String(Action).split(',');
            ApprovedModalOnClick(actionList[0], actionList[1], id);
        });
    }
    else {
        var href = target + '&Action=' + Action + '&ViewCode=' + ViewCode;
        window.location.href = href;
    }
}
function initImportExcel(ControlID, DataSource, Pattern) {
    $("#btnImport-" + ControlID).on("click dblclick", function (e) {
        e.preventDefault();
        $('#fileUpload-' + ControlID).trigger('click');
        e.stopPropagation();
        return;
    });

    $("#fileUpload-" + ControlID).change(function () {
        $("#btnImport-" + ControlID).attr("disabled", "disabled").val('waiting process...');
        //$("#btnImport-" + ControlID).html('<p class="text-center"><i class="ti-reload rotate-refresh"></i> Loading...</p>');
        var fileExtension = "xlsx,xls";
        var filename = $(this).get(0).files[0].name;
        var ext = filename.substr(filename.lastIndexOf('.') + 1, filename.length - 1 - filename.lastIndexOf('.'));
        console.log(ext);
        if (fileExtension.indexOf(ext) < 0) {
            alert("Please check required format:" + fileExtension);
            $("#fileUpload-" + ControlID).val("");
            $("#btnImport-" + ControlID).removeAttr("disabled").val("Import Excel");
        }
        else {
            strJsonUserList = "";
            var fileData = new FormData();
            fileData.append("file0", $(this).get(0).files[0]);
            fileData.append("formatType", "ObjectInCharge");
            fileData.append("DataSource", DataSource);
            fileData.append("FormCode", $('#FormCode').val());
            fileData.append("FSessionID", $('#FSessionID').val());
            fileData.append("ControlID", ControlID);
            var actionURL = "";
            if (Pattern == "ImportExcelRawData") {
                actionURL = "/Categories/CategoriesBase/ImportExcelRawData";
            }
            else {
                actionURL = "/Categories/CategoriesBase/ImportExcel";
            }

            ShowLoadingOnControl(ControlID, 'FileUpload');
            $.ajax({
                type: "POST",
                url: actionURL,
                contentType: false,
                processData: false,
                data: fileData,
                timeout: 360000,
                success: function (result) {
                    CheckResponse(result);
                    //console.log(result);
                    var arrColumns = [
                        { "Key": "StatusCode", "Type": "TextBox" },
                        { "Key": "StatusMess", "Type": "TextBox" }
                    ]
                    RenderDataListFromJsonTable('', result, 0, arrColumns, ControlID);
                    $("#fileUpload-" + ControlID).val("");
                    $("#btnImport-" + ControlID).removeAttr("disabled").val("Import excel");

                },
                error: function (xhr, status, p3, p4) {
                    $("#btnImport-" + ControlID).removeAttr("disabled").val("Import Excel");
                    notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', "Lỗi không thể đọc file excel.");
                    console.log(xhr);
                    console.log(status);
                    console.log(p3);
                    console.log(p4);

                }
            });
        }
    });
}
function OpenFormConfig(domain = "") {
    var formCode = $("#FormCode").val();
    formCode = String(formCode);
    var formType = formCode.indexOf("FAC") >= 0 ? "CATE" : formCode.substring(0, 3);
    window.open(domain + "/Categories/FormConfig/CreateForm?FormType=" + formType + "&FormCode=" + formCode, '_blank');
}
function OpenHelpForm() {
    var formCode = $("#FormCode").val();
    formCode = String(formCode);
    var helpid = formCode.substring(formCode.indexOf('-') + 1, formCode.length);
    location.href = "/Categories/CateAddUpdate?FormCode=FAC-0119&ID=" + helpid;
}
function CloseModalForm(ControlID) {
    if (ControlID.indexOf("modal") >= 0) {
        $('#' + ControlID).modal('hide');
    }
    else {
        $('#modal-' + ControlID).modal('hide');
    }

}

function CheckResponse(response) {
    if (typeof (response) == "string" && response.substring(0, 20).indexOf('"ResultErrCode":440') >= 0) {
        //var ResultDesc = JSON.parse(response).ResultErrDesc;
        window.location.reload();
    }
}
function generateUUID() { // Public Domain/MIT
    var d = new Date().getTime();
    if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
        d += performance.now(); //use high-precision timer if available
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = (d + Math.random() * 16) % 16 | 0;
        d = Math.floor(d / 16);
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
}

function CheckDateFromTo(prefix, datefromid, datetoid, format, changeFrom) {
    var datefrom = moment($("#" + prefix + datefromid).val(), format);
    var dateto = moment($("#" + prefix + datetoid).val(), format);

    var isCheck = $('#NoEndDate' + prefix + datetoid)[0] != undefined ? $('#NoEndDate' + prefix + datetoid)[0].checked : false;

    if ((changeFrom == undefined || changeFrom == 1) && datefrom > dateto && dateto._i != '1900-01-01' && !(isCheck === true || String(isCheck) === "1")) {
        notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Nofify', 'From Date/Time must less than To Date/Time');
    }
    else if (changeFrom == 0 && datefrom > dateto) {//dateto
        var stringDate = moment(datefrom).format(format);
        $("#" + prefix + datetoid).val(stringDate);

    }
    UpdateTimeTotal(prefix + datefromid, datefrom, dateto, format);

}
function UpdateTimeTotal(controlID, datefrom, dateto, format) {
    var duration = moment.duration(dateto.diff(datefrom));

    if (format == "LT") {
        var Minutes = duration.asMinutes();
        var intMinutes = Math.round(Minutes % 60);
        var intHours = Math.round((Minutes - intMinutes) / 60);
        $('#' + controlID + 'Total').text(' ' + intHours + ' h, ' + intMinutes + ' m ');
    }
    else {
        var hours = duration.asHours();
        var inthour = Math.round(hours % 24);
        var intDays = Math.round((hours - inthour) / 24);
        $('#' + controlID + 'Total').text(' ' + intDays + ' Days, ' + inthour + ' Hours ');
    }


}
function ReturnURL(RedirectOnApproval) {
    if (RedirectOnApproval) {
        window.location.href = RedirectOnApproval;
    }
    if (document.referrer && window.location.href != document.referrer) {
        history.back();
    }
    else {
        window.location.href = RedirectOnApproval;
    }
}

function CallApi(url) {
    $.ajax({
        type: "POST",
        url: url,
        success: function (response) {
            if (response.length) {
                ShowMessage('success', '!Thông báo', response, 500, '');
            }
        },
        error: function (err) {
            ShowMessage('danger', '!Thông báo', err, 500, '');
        }
    });

}
function ShowItemCondition(ControlID, Value, ControlType) {
    if (ControlType == "TabListSelect") {
        $('#' + ControlID).val(Value);
        $('.Tab-' + ControlID).each(function () {
            if ($(this).attr("value") == Value) {
                $(this).addClass("active");
            }
            else $(this).removeClass("active");
        });
    }
    if (ControlType == "checkbox") {
        if (Value == true || Value == "True" || Value == "On" || Value == 1) Value = "1";
        else Value = "0";
    }

    $('[showby]').each(function () {
        var configArr = $(this).attr("showby").split(',');
        if (configArr && configArr[0] == ControlID) {
            if (configArr[1] == "=" && Value == configArr[2]) {
                $(this).removeClass("d-none");
            }
            else if (configArr[1] == "in" && configArr[2].indexOf(Value) >= 0) {
                $(this).removeClass("d-none");
            }
            else if (configArr[1] == "notin" && configArr[2].indexOf(Value) == -1) {
                $(this).removeClass("d-none");
            }
            else if (configArr[1] == "contain" && Value.indexOf(configArr[2]) >= 0) {
                $(this).removeClass("d-none");
            }
            else $(this).addClass("d-none");

        }

    });
}
function ShowMessage(type, title, message, timer, url) {
    if (typeof timer === 'undefined') {
        timer = 1000;
    }
    setTimeout(function () {
        $.notify({
            title: '<strong>' + title + '</strong>',
            message: message
        }, {
            type: type
        });
    }, timer);
    if (url !== '') {
        window.location.href = url;
    }
}

function Redirect(url) {
    window.location.href = url;
}

function RedirectWithWait(url, timeInterval = 0) {
    var tick = setInterval(function () {
        clearInterval(tick);
        window.location.href = url;
    }, timeInterval);
}

function notify(from, align, icon, type, animIn, animOut, title, message) {
    $.growl({
        icon: icon,
        title: title + ': ',
        message,
        url: ''
    }, {
        element: 'body',
        type: type,
        allow_dismiss: true,
        placement: {
            from: from,
            align: align
        },
        offset: {
            x: 30,
            y: 30
        },
        spacing: 10,
        z_index: 999999,
        delay: 2500,
        timer: 1000,
        url_target: '_blank',
        mouse_over: false,
        animate: {
            enter: animIn,
            exit: animOut
        },
        icon_type: 'class',
        template: '<div data-growl="container" class="alert" role="alert">' +
            '<button type="button" class="close" data-growl="dismiss">' +
            '<span aria-hidden="true">&times;</span>' +
            '<span class="sr-only">Close</span>' +
            '</button>' +
            '<span data-growl="icon"></span>' +
            '<span data-growl="title"></span>' +
            '<span data-growl="message"></span>' +
            '<a href="#" data-growl="url"></a>' +
            '</div>'
    });
};
function LoadCheckIn(ID, Checked) {
    console.log("LoadCheckIn!");
    $.ajax({
        type: "POST",
        url: "/User/Checkin",
        data: "Action=gethistory&Checked=" + Checked + "&ID=" + ID,
        success: function (response) {
            console.log("LoadCheckIn!success");
            if (response.StatusCode === "DONE") {
                console.log(response);
                var textTimeNote = "";
                if (response.TimeCheckin !== null)
                    textTimeNote = "" + response.TimeCheckin;
                if (response.TimeCheckout !== null)
                    textTimeNote += " - " + response.TimeCheckout;

                $("#timeCheckinOut").text(textTimeNote);

            }
        },
        error: function (response) {
            console.log(response);
        }

    });
}
function TimekeepingCheckin(ID, Action, Checked) {
    console.log("TimekeepingCheckin!");
    var statusActive = '';
    $.ajax({
        type: "POST",
        url: "/User/Checkin",
        data: "Action=" + (Action ?? "checkin") + "&Checked=" + Checked + "&ID=" + ID,
        success: function (response) {
            if (response.StatusCode === "DONE") {
                notify('top', 'right', '', 'success', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response?.StatusMess ?? response);
            } else {
                notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response?.StatusMess ?? response);
            }
        },
        error: function (response) {
            notify('top', 'right', '', 'warning', 'animated fadeInLeft', 'animated fadeOutLeft', 'Thông báo', response);
        }

    });
}




