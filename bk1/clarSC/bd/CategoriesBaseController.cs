using BussinessObjects;
using Helpers.Functions;
using Newtonsoft.Json;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Runtime.Caching;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Mvc;

namespace Categories.Controllers
{
    public class CategoriesBaseController : Controller
    {
        public string ServiceUrl_Config = Helpers.Functions.ConfigFunctions.GetConfigByDomain("ServiceUrl_Config");
        public string ServiceUrl_Data = Helpers.Functions.ConfigFunctions.GetConfigByDomain("ServiceUrl_Data");
        public string ServiceUrl_Report = Helpers.Functions.ConfigFunctions.GetConfigByDomain("ServiceUrl_Report");
        public bool IsAuthorization(string ObjectID = "")
        {
            if (Session["UserFunctions"] == null)
            {
                Thread.Sleep(1000);
            }
            if (Session["UserFunctions"] == null)
            {
                Thread.Sleep(1000);
            }
            ObjectID = ObjectID.ToLower();
            List<UserMenu> userFunctions = (List<UserMenu>)Session["UserFunctions"];
            if (userFunctions != null && userFunctions.Exists(m => m.ObjectID.ToLower().IndexOf(ObjectID) >= 0))
            {
                return true;
            }
            if (SEmployee.UserID == 1)
            {
                return true;
            }

            return false;
        }
        public bool IsAuthorizationAction(string ObjectID = "", string action = "")
        {
            if (SEmployee.UserID == 1)
            {
                return true;
            }

            if (string.IsNullOrWhiteSpace(action) && Request["Action"] != null)
            {
                action = Request["Action"].ToUpper();
            }
            ObjectID = ObjectID.ToLower();
            List<UserMenu> userFunctions = (List<UserMenu>)Session["UserFunctions"];
            if (userFunctions != null)
            {
                UserMenu menu = userFunctions.Where(m => m.ObjectID.ToLower().IndexOf(ObjectID) >= 0 && m.IsAuthorizationAction == true).FirstOrDefault();

                if (menu == null)
                {
                    if (SEmployee.IsAdmin == true)
                    {
                        return true;
                    }
                    else if (string.IsNullOrWhiteSpace(action)) return true;
                    else return false;
                    //Lỗ hổng lớn, cần fix sau này.
                    //Cần xét đến các trường hợp sau:
                    //1. Save dữ liệu từ link không có Menu
                    //2. Save dữ liệu từ Link không có config
                    //3. Save dữ liệu từ workflow, không check quy trình.
                }

                if (menu != null)
                {
                    switch (action.Split(',')[0].ToUpper())
                    {
                        case "ISCHECK":
                            return menu.IsCheck == true ? true : false;
                        case "ADD":
                            return menu.Add == true ? true : false;
                        case "101":
                            return menu.Add == true ? true : false;
                        case "EDIT":
                            return menu.Edit == true ? true : false;
                        case "102":
                            return menu.Edit == true ? true : false;
                        case "501":
                            return menu.Edit == true ? true : false;
                        case "500":
                            return menu.Edit == true ? true : false;
                        case "MOVENODE":
                            return menu.Edit == true ? true : false;
                        case "DEL":
                            return menu.Del == true ? true : false;
                        case "404":
                            return menu.Del == true ? true : false;
                        case "401":
                            return menu.Del == true ? true : false;
                        case "DELETE":
                            return menu.Del == true ? true : false;
                        default:
                            return false;
                    }
                }
            }

            return false;
        }

        public List<string> MapSubmitParamsReport(List<FItem> fitems, string sessionId = "", string id = "", string Action = null)
        {
            try
            {
                List<string> parms = new List<string>();

                #region 'Set Default Param'
                parms.Add("@SSID");
                parms.Add(sessionId);
                parms.Add("@DomainID");
                parms.Add(SEmployee.DomainID.ToString());
                parms.Add("@USERID");
                parms.Add(SEmployee.UserID.ToString());
                //parms.Add("@FormCode");
                //parms.Add(Request["FormCode"].ToString());

                #endregion
                if (fitems != null && fitems.Count() > 0)
                {
                    string _action = Request["Action"]?.ToString();
                    parms.Add("@Action");
                    parms.Add(Action ?? _action);
                    MapParamFromRequest(fitems, parms, Request);
                }
                return parms;
            }
            catch (Exception ex)
            {
                throw (ex);
            }
        }

        public List<string> MapSubmitParamsCate(List<FItem> fitems, string sessionId = "", string id = "", string FormCode = "")
        {
            try
            {
                List<string> parms = new List<string>();

                #region 'Set Default Param'
                parms.Add("@SSID");
                parms.Add(sessionId);
                parms.Add("@DomainID");
                parms.Add(SEmployee.DomainID.ToString());
                parms.Add("@USERID");
                parms.Add(SEmployee.UserID.ToString());

                #endregion

                if (fitems != null && fitems.Count() > 0)
                {
                    if (Request["FormCode"] != null && !fitems.Exists(m => m.Key == "FormCode"))
                    {
                        parms.Add("@FormCode");
                        parms.Add(Request["FormCode"].ToString());
                    }

                    if (Request["LocationID"] == null && fitems.Exists(m => m.Key == "LocationID"))
                    {
                        parms.Add("@LocationID");
                        parms.Add(SEmployee.LocationID);
                    }

                    if (Request["Action"] != null && !fitems.Exists(m => m.Key == "Action"))
                    {
                        parms.Add("@Action");
                        parms.Add(Request["Action"].ToString());
                    }
                    if (Request["ID"] != null && !fitems.Exists(m => m.Key.ToUpper() == "ID"))
                    {
                        parms.Add("@ID");
                        parms.Add(Request["ID"].ToString());
                    }

                    if (Request["NodeID"] != null && !fitems.Exists(m => m.Key == "NodeID"))
                    {
                        parms.Add("@NodeID");
                        parms.Add(Request["NodeID"].ToString());
                    }
                    if (Request["ParentID"] != null && !fitems.Exists(m => m.Key == "ParentID"))
                    {
                        parms.Add("@ParentID");
                        parms.Add(Request["ParentID"].ToString());
                    }

                    if (Request["Redirect-ObjectInCharge-701"] != null && !fitems.Exists(m => m.Key == "Delegate"))
                    {
                        parms.Add("@Delegate");
                        parms.Add(Request["Redirect-ObjectInCharge-701"].ToString());
                    }

                    if (Request["Redirect-ObjectInCharge-702"] != null && !fitems.Exists(m => m.Key == "AssignTo"))
                    {
                        parms.Add("@AssignTo");
                        parms.Add(Request["Redirect-ObjectInCharge-702"].ToString());
                    }
                    MapParamFromRequest(fitems, parms, Request);
                }
                return parms;
            }
            catch (Exception ex)
            {
                throw (ex);
            }
        }

        private void MapParamFromRequest(List<FItem> fitems, List<string> pList, HttpRequestBase request)
        {
            try
            {

                int idJsData = 0;
                List<IDKeyValModel> jsData = new List<IDKeyValModel>();
                foreach (FItem item in fitems)
                {
                    if (item.NotSaveDB == "1" || item.NotSaveDB == "on" || item.NotSaveDB == "true"
                        || item.Type == "Line" || item.Type == "ViewLinkList"
                        || item.Key.ToLower() == "jsdata"
                        || pList.Exists(m=>m == item.Key)
                    )
                    {
                        continue;
                    }
                    bool isJSData = (item.JsData == "1" || item.JsData == "True" || item.JsData == "On" ? true : false);

                    if (item.Type == null)
                    {
                        item.Type = "TextBox";
                        item.Pattern = "";
                    }
                    string val = "";
                    bool isAddParam = true;

                    if (Request.Unvalidated[item.Key] != null)
                    {
                        switch (item.Type.ToLower())
                        {
                            case "checkbox":
                                val = Request[item.Key].ToString();
                                if (val.ToLower() == "on" || val.ToLower() == "true" || val.ToLower() == "1")
                                {
                                    val = "1";
                                }
                                else
                                {
                                    val = "0";
                                }

                                break;
                            case "switch":
                                val = Request[item.Key].ToString();
                                if (val.ToLower() == "on" || val.ToLower() == "true" || val.ToLower() == "1")
                                {
                                    val = "1";
                                }
                                else
                                {
                                    val = "0";
                                }

                                break;
                            case "textbox":
                                switch (item.Pattern.ToLower())
                                {
                                    case "numberonly":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "number2":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "number4":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "percent":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "percent2":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "percent4":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "mobileno":
                                        val = Request[item.Key].ToString().Replace("-", "");
                                        break;
                                    case "jsfunction":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    default:
                                        if (item.Key.IndexOf("Display") >= 0)
                                        {
                                            val = (Request.Unvalidated[item.Key].ToString());
                                        }
                                        else
                                        {
                                            val = (Request[item.Key].ToString());
                                        }
                                        break;
                                }
                                break;
                            case "textonly":
                                switch (item.Pattern.ToLower())
                                {
                                    case "numberonly":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "number2":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "number4":
                                        val = (Request[item.Key].ToString().Replace(",", ""));
                                        break;
                                    case "percent":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "percent2":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "percent4":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    case "mobileno":
                                        val = Request[item.Key].ToString().Replace("-", "");
                                        break;
                                    case "jsfunction":
                                        val = Request[item.Key].ToString().Replace(",", "").Replace("%", "");
                                        break;
                                    default:
                                        if (item.Key.IndexOf("Display") >= 0)
                                        {
                                            val = (Request.Unvalidated[item.Key].ToString());
                                        }
                                        else
                                        {
                                            val = (Request[item.Key].ToString());
                                        }
                                        break;
                                }
                                break;
                            case "datetime":
                                switch (item.Pattern.ToLower())
                                {
                                    case "datepick":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDD(Request[item.Key]).ToString("yyyy-MM-dd");

                                        break;
                                    case "datetimepick":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDDhhmmss(Request[item.Key]).ToString("yyyy-MM-dd HH:mm:ss");

                                        break;
                                    default:
                                        val = (Request[item.Key].ToString());
                                        break;
                                }
                                break;
                            case "datefromto":
                                switch (item.Pattern.ToLower())
                                {
                                    case "datefrom":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDD(Request[item.Key]).ToString("yyyy-MM-dd");

                                        break;
                                    case "dateto":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDD(Request[item.Key]).ToString("yyyy-MM-dd");

                                        break;
                                    case "datetimefrom":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDDhhmmss(Request[item.Key]).ToString("yyyy-MM-dd HH:mm:ss");

                                        break;
                                    case "datetimeto":
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDDhhmmss(Request[item.Key]).ToString("yyyy-MM-dd HH:mm:ss");

                                        break;
                                    case "timefrompick":
                                        val = Request[item.Key].ToString();

                                        break;
                                    case "timetopick":
                                        val = Request[item.Key].ToString();

                                        break;
                                    case "noenddate":
                                        val = Request[item.Key].ToString();
                                        if (val.ToLower() == "on" || val.ToLower() == "true" || val.ToLower() == "1")
                                        {
                                            val = "1";
                                        }
                                        else
                                        {
                                            val = "0";
                                        }

                                        break;
                                    default:
                                        val = StaticFunc.ConvertToDateFromStringYYYYMMDD(Request[item.Key]).ToString("yyyy-MM-dd");

                                        break;
                                }
                                break;
                            case "htmleditor":
                                string filePath = "";
                                if (!(item.Value.EndsWith(".html") && item.Value.StartsWith("/Files/Domains/")))
                                {
                                    filePath = GetFileNameByUserDomain(".html", "Contents/" + Request["FormCode"].ToString());
                                }
                                else
                                {
                                    filePath = item.Value;
                                }

                                System.IO.File.WriteAllText(Server.MapPath(filePath), Request.Unvalidated[item.Key].ToString());
                                if (item.Pattern == "HtmlDB")
                                {
                                    string filejs = "{\"filePath\":\"" + filePath + "\",";
                                    filejs += "\"fileContent\":" + JsonConvert.ToString(Request.Unvalidated[item.Key].ToString()) + "}";
                                    val = (filejs);
                                }
                                else val = (filePath);
                                break;
                            case "datareportedit":
                                string datastring = Request.Unvalidated[item.Key].ToString();
                                datastring.Replace("\'", "\'\'");
                                val = (datastring);
                                break;
                            case "itemsdetail":
                                string itemsdetail = Request.Unvalidated[item.Key].ToString();
                                itemsdetail.Replace("\'", "\'\'");
                                val = (itemsdetail);
                                break;
                            case "line":
                                isAddParam = false;
                                break;
                            default:
                                val = (Request[item.Key].ToString());
                                break;
                        }

                    }

                    if (isAddParam)
                    {
                        if (isJSData == true)
                        {
                            jsData.Add(new IDKeyValModel()
                            {
                                id = (idJsData++).ToString(),
                                key = item.Key,
                                val = val,
                                type = item.Type,
                                format = item.Pattern

                            });
                        }
                        else
                        {
                            pList.Add("@" + item.Key);
                            pList.Add(val);
                        }
                    }
                }
                if (jsData.Count > 0)
                {
                    pList.Add("@JsData");
                    pList.Add(JsonConvert.SerializeObject(jsData));
                }
            }
            catch (Exception ex)
            {
                throw (ex);
            }
        }

        private string ConvertDataTabletoStringNotDisplay(DataTable table)
        {
            throw new NotImplementedException();
        }
        public DataTable GetFormData(CategoriesItemModel cate, string SourceType = "")
        {
            DataTable data;
            string ServiceURl = cate.SourceConfig?.Find(m => m.Key == "ServiceUrl")?.ServiceUrl;
            if (string.IsNullOrWhiteSpace(ServiceURl))
            {
                ServiceURl = ServiceUrl_Data;
            }
            else
            {
                ServiceURl = Helpers.Functions.ConfigFunctions.GetConfigByDomain(ServiceURl);
            }

            if (SourceType == "ModalForm")
            {

                string DataSource = cate.SourceConfig != null && cate.SourceConfig.Find(m => m.Key == "ModalSource") != null ? cate.SourceConfig.Find(m => m.Key == "ModalSource").Value ?? "" : "";
                data = DataFunction.GetCategoriesItemFromService(SEmployee.DomainID.ToString(), SEmployee.UserID.ToString(), ServiceURl, "", DataSource, "PROC", cate.ColID, cate.ColVal, "", cate.FormCode, cate.SessionID, "", "", cate.ViewCode, cate.ViewDataLink);
            }
            else
            {
                data = DataFunction.GetCategoriesItemFromService(SEmployee.DomainID.ToString(), SEmployee.UserID.ToString(), ServiceURl, "", cate.Source, cate.SourceType, cate.ColID, cate.ColVal, "", cate.FormCode, cate.SessionID, "", "", cate.ViewCode, cate.ViewDataLink);
            }
            return data;
        }
        public DataTable SaveFormData(CategoriesItemModel model, string sessionId, string id)
        {
            List<FItem> listControl = new List<FItem>();
            string target = "";
            string ClientTargetType = Request["TargetType"];
            string targetUrl = model.SourceConfig?.Find(m => m.Key == "ServiceUrl")?.ServiceUrl;

            if (string.IsNullOrWhiteSpace(targetUrl))
                targetUrl = ServiceUrl_Data;
            else targetUrl = Helpers.Functions.ConfigFunctions.GetConfigByDomain(targetUrl);

            if (!string.IsNullOrWhiteSpace(ClientTargetType))
            {
                if (ClientTargetType.IndexOf("ModalForm") >= 0)
                {
                    listControl = model.ModalForm;
                    target = model.SourceConfig != null && model.SourceConfig.Find(m => m.Key == "ModalTarget") != null ? model.SourceConfig.Find(m => m.Key == "ModalTarget").Value ?? model.Target : model.Target;

                }
                else if (ClientTargetType.IndexOf("ProcessStatus") >= 0)
                {
                    target = model.Target;
                    listControl.Add(new FItem() { Key = "ID" });
                    listControl.Add(new FItem() { Key = "FormCode" });
                    listControl.Add(new FItem() { Key = "Action" });
                    listControl.Add(new FItem() { Key = "ActionCode" });
                }
            }
            DataFunction.TargetType SaveDataTargetType = model.TargetType== "FormDataSaveV2"? DataFunction.TargetType.SaveFormDataV2: DataFunction.TargetType.SaveFormData;
            if (string.IsNullOrWhiteSpace(target))
            {
                listControl = model.Form;
                target = model.Target;
            }
            if (string.IsNullOrWhiteSpace(target))
            {
                throw new ArgumentException("ERR|SaveFormData: Datasource is null");
            }
            List<string> Params = MapSubmitParamsCate(listControl, sessionId, id);
            DataTable data = DataFunction.SaveCategoriesItemFromService(targetUrl, "", Params, model.FormCode, target, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString(), SaveDataTargetType);
            return data;
        }

        private string GetFileNameByUserDomain(string ext, string Categories = "")
        {
            string folder = "/Files/Domains/" + SEmployee.DomainCode + (Categories == "" ? "/" : "/" + Categories + "/");
            bool exists = System.IO.Directory.Exists(Server.MapPath(folder));
            if (!exists)
            {
                System.IO.Directory.CreateDirectory(Server.MapPath(folder));
            }
            return folder + Guid.NewGuid().ToString() + ext;
        }
        public void SetFormData(CategoriesItemModel model, DataTable dataMap)
        {
            if (dataMap != null && dataMap.Rows.Count > 0)
            {
                DataRow row = dataMap.Rows[0];

                string strJSData = "";
                List<IDKeyValModel> jsFields = new List<IDKeyValModel>();
                if (dataMap.Columns.Contains("JsData"))
                {
                    strJSData = row["JsData"].ToString();
                    jsFields = JsonConvert.DeserializeObject<List<IDKeyValModel>>(strJSData);
                }

                if (model.Form != null)
                {
                    foreach (FItem item in model.Form)
                    {
                        bool isJSData = item.JsData == "True" ? true : false;

                        if (isJSData == true)
                        {
                            IDKeyValModel jsItem = jsFields?.FirstOrDefault(m => m.key == item.Key);
                            item.Value = jsItem?.val ?? "";
                        }
                        else
                            for (int c = 0; c < dataMap.Columns.Count; c++)
                            {
                                if (item.Key == dataMap.Columns[c].ColumnName)
                                {
                                    if (item.Type == "ListDetailTable")
                                    {
                                        DataTable table = (DataTable)JsonConvert.DeserializeObject(row[item.Key].ToString(), (typeof(DataTable)));
                                        //Session[item.Key + "_" + model.SessionID] = table;
                                    }
                                    else if (item.Type == "FxControl" || item.Pattern == "jsFunction")
                                    {
                                        //not replace data
                                    }
                                    else
                                    {
                                        item.Value = row[item.Key].ToString();
                                        if (dataMap.Columns.IndexOf(item.Key + "Display") >= 0)
                                        {
                                            item.ValueDisplay = row[item.Key + "Display"].ToString();
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }

        public List<FItemValue> ConvertDatatableToFormItems(List<FItem> Form, DataTable dataMap)
        {
            List<FItemValue> itemsValue = new List<FItemValue>();
            if (dataMap != null && dataMap.Rows.Count > 0)
            {
                DataRow row = dataMap.Rows[0];

                List<IDKeyValModel> jsDataList = new List<IDKeyValModel>();
                if (dataMap.Columns.Contains("JsData"))
                {
                    string jsData = row["JsData"].ToString();
                    if (jsData.Length > 0)
                        jsDataList = JsonConvert.DeserializeObject<List<IDKeyValModel>>(jsData);
                }
                else jsDataList = new List<IDKeyValModel>();

                if (Form != null)
                {
                    foreach (FItem item in Form)
                    {
                        string value = "";
                        string valueDisplay = "";
                        if (item.JsData == "True" && jsDataList.Count > 0)
                        {
                            IDKeyValModel jsDataItem = jsDataList.FirstOrDefault(m => m.key == item.Key);
                            IDKeyValModel jsDataItemDisplay = jsDataList.FirstOrDefault(m => m.key == item.Key+"Display");

                            if (jsDataItem != null)
                            {
                                value = jsDataItem.val;
                                valueDisplay = jsDataItemDisplay?.val;
                            }
                        }
                        else if (dataMap.Columns.Contains(item.Key))
                        {
                            value = row[item.Key].ToString();
                            valueDisplay = dataMap.Columns.Contains(item.Key + "Display")? row[item.Key+"Display"]?.ToString():null;
                        }
                        //// add to list itemsValue
                        FItemValue newItem = new FItemValue
                        {
                            Key = item.Key, 
                            Value = value,
                            Type = item.Type,
                            Pattern = item.Pattern,
                            OptionConfig = item.OptionConfig,
                            JsData = item.JsData,
                            ValueDisplay = valueDisplay

                        };
                        itemsValue.Add(newItem);
                    }
                }
            }
            return itemsValue;
        }
        public UserProfile SEmployee
        {
            get
            {
                if (Session != null)
                {
                    return (UserProfile)Session["UserProfile"];
                }
                return null;
            }

        }
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            try
            {
                if (!filterContext.IsChildAction)
                {
                    string actionName = filterContext.ActionDescriptor.ActionName;
                    if (Session["UserProfile"] == null)
                    {
                        string currentUrl = Server.UrlEncode(HttpContext.Request.Url.PathAndQuery);
                        string urlEncode = string.Format("/User/Login?returnUrl={0}", currentUrl);
                        JsonResult js = new JsonResult()
                        {
                            Data = "{\"ResultErrCode\":440,\"ResultErrDesc\":\"Session Timeout\"}"
                        };
                        if (((ReflectedActionDescriptor)filterContext.ActionDescriptor).MethodInfo.ReturnType == typeof(JsonResult))
                        {
                            filterContext.Result = js;
                        }
                        else
                        {
                            filterContext.Result = new RedirectResult(urlEncode);
                        }
                    }
                    DataFunction.RegisterAction(Request.Url.PathAndQuery);
                }
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("OnActionExecuting", ex.Message, "", "");
            }
        }
        protected string GenerateReportName(string rkey = "", string title = "")
        {
            string rName = "/Files/Exports/" + SEmployee.DomainCode + "/";
            try
            {
                if (!string.IsNullOrEmpty(rkey))
                {
                    rName += title + "_" + (SEmployee != null ? SEmployee.EmployeeCode : "") + "_" + DateTime.Now.ToString("yyMMddhhmmss") + "_" + rkey + "_" + Guid.NewGuid().ToString().Substring(0, 4) + ".xlsx";
                }
                else
                {
                    rName += title + "_" + DateTime.Now.ToString("yyMMddhhmmss") + "_" + Guid.NewGuid().ToString().Substring(0, 4) + ".xlsx";
                }
            }
            catch (Exception ex)
            {
                Helpers.Functions.DataFunction.WriteLog("GenerateReportName", ex.Message, rkey);
                rName += title + "_" + DateTime.Now.ToString("yyMMddhhmmss") + "_" + Guid.NewGuid().ToString().Substring(0, 4) + ".xlsx";
            }
            return rName;
        }
        public JsonResult CreateSignPath(string signDoc = "", string DocumentID = "", string FormCode = "unknow")
        {
            //string currentController = Request.RequestContext.RouteData.Values["controller"].ToString();
            signDoc = HttpUtility.UrlDecode(signDoc);
            string[] signArr = signDoc.Split(',');
            if (signArr.Count() == 2)
            {
                string folder = GetFolderNameByUserDomain("Signs/" + FormCode + "/" + SEmployee.DomainCode + "/" + DateTime.Now.ToString("yyMM"));
                string filename = DateTime.Now.ToString("yyMMddHHmmss") + "-" + SEmployee.UserID.ToString() + ".png";
                if (Helpers.Functions.StaticFunc.SaveBase64ToImage(signArr[1], filename, folder))
                {
                    string fullSignPath = folder + filename;
                    return Json(fullSignPath, JsonRequestBehavior.AllowGet);
                }
            }
            return Json("ERR", JsonRequestBehavior.AllowGet);
        }
        private string GetFolderNameByUserDomain(string Categories = "")
        {
            string folder = "/Files/Domains/" + SEmployee.DomainCode + (Categories == "" ? "/" : "/" + Categories + "/");
            bool exists = System.IO.Directory.Exists(Server.MapPath(folder));
            if (!exists)
            {
                System.IO.Directory.CreateDirectory(Server.MapPath(folder));
            }
            return folder;
        }
        public bool CreateEmail(string DocumentObjectType = "", string DocumentObjectCode = "", string currentUrl = "")
        {
            string mailAlertBody = "";
            mailAlertBody = "<div><h3>" + DocumentObjectType + " số : " + DocumentObjectCode + "  đang chờ bạn duyệt. Xem chi tiết tại <a href='" + currentUrl + "'>đây</a></h3></div>";
            string mailAlertBodyEncode = Helpers.Functions.StaticFunc.EncodeTo64UTF8(mailAlertBody);
            EmailModel alertMail = new EmailModel(DocumentObjectCode, " Số : " + DocumentObjectCode + "  đang chờ bạn duyệt", "", SEmployee.EmailAddress, "", mailAlertBody, "", 0, 1, DateTime.Now, DateTime.Now, SEmployee.UserID);
            return true;
        }

        public CategoriesItemModel GetFormModelCache(string FormCode)
        {
            bool saveToCache = false;
            ObjectCache cache = MemoryCache.Default;
            CategoriesItemModel model = cache.Get(FormCode) as CategoriesItemModel;
            if (model == null && (FormCode.IndexOf("FAC") >= 0 || FormCode.IndexOf("WFL") >= 0))
            {
                model = ReaderTools.DeserializeJsonFileToObject<CategoriesItemModel>(Server.MapPath("/Files/Categories/" + FormCode + ".jconfig"));
                saveToCache = true;
            }
            else
            if (model == null && FormCode.IndexOf("RPT") >= 0)
            {
                model = ReaderTools.DeserializeJsonFileToObject<CategoriesItemModel>(Server.MapPath("/Files/SReports/" + FormCode + ".jconfig"));
                saveToCache = true;
            }
            else if (model == null)
            {
                model = ReaderTools.DeserializeJsonFileToObject<CategoriesItemModel>(Server.MapPath("/Files/Categories/" + FormCode + ".jconfig"));
                saveToCache = true;
            }
            if (saveToCache == true && !string.IsNullOrWhiteSpace(FormCode) && model != null)
            {
                CacheItemPolicy policy = new CacheItemPolicy
                {
                    //policy.SlidingExpiration = new TimeSpan(0,5,0);
                    AbsoluteExpiration = DateTimeOffset.Now.AddMinutes(5)
                };
                cache.Set(FormCode, model, policy);
            }
            return model.CloneObject();

        }

        [HttpPost]
        public ActionResult ImportExcel(string formatType = "", string FormCode = "", string DataSource = "", string FSessionID = "", string ControlID = "")
        {
            string stepDebug = "Imp:1";
            try
            {
                List<BussinessObjects.IDKeyValModel> dataLoad = new List<BussinessObjects.IDKeyValModel>();
                string jsString = "[";

                ////load model
                if (FormCode == "")
                {
                    throw new System.InvalidOperationException("FormCode Is null");
                };
                CategoriesItemModel model = GetFormModelCache(FormCode);

                if (model.ETL == null || model.ETL.Count == 0)
                {
                    throw new System.InvalidOperationException("Model Not Load(Is null)");
                }

                stepDebug = "Imp:2";
                BussinessObjects.FItem importConfig = model.ETL.Find(m => m.Key == ControlID);
                if (importConfig == null)
                {
                    throw new System.InvalidOperationException("Import Config(Is null)");
                }

                stepDebug = "Imp:3";
                List<BussinessObjects.IDKeyValModel> importModel = importConfig != null && importConfig.ETLConfig != null ? Newtonsoft.Json.JsonConvert.DeserializeObject<List<BussinessObjects.IDKeyValModel>>(importConfig.ETLConfig) : new List<BussinessObjects.IDKeyValModel>();
                if (importModel == null || importModel.Count == 0)
                {
                    throw new System.InvalidOperationException("Import Model(Is null)");
                }

                stepDebug = "Imp:4";

                List<SelectListModel> listCheck = new List<SelectListModel>();
                List<SelectListModel> listError = new List<SelectListModel>();
                //load excel
                foreach (string file in Request.Files)
                {
                    HttpPostedFileBase fileContent = Request.Files[file];
                    stepDebug = "Imp:5";
                    if (fileContent != null && fileContent.ContentLength > 0)
                    {
                        Stream stream = fileContent.InputStream;
                        stepDebug = "Imp:6";
                        using (ExcelPackage package = new ExcelPackage(stream))
                        {
                            stepDebug = "Imp:7";
                            ExcelWorkbook workBook = package.Workbook;
                            if (workBook != null)
                            {
                                if (workBook.Worksheets.Count > 0)
                                {
                                    stepDebug = "Imp:8";
                                    ExcelWorksheet ws = workBook.Worksheets.FirstOrDefault(m => m.Hidden == eWorkSheetHidden.Visible);
                                    ////select column to load data
                                    foreach (BussinessObjects.IDKeyValModel item in importModel.Where(m => m.key == "ItemName").ToList())
                                    {
                                        int StartCol = 1;
                                        int StartRow = 1;
                                        string ItemName = item.key;
                                        string DataType = "TextBox";
                                        stepDebug = "Imp:9";
                                        BussinessObjects.IDKeyValModel ColModel = importModel.Where(m => m.id == item.id && m.key == "Col").ToList().FirstOrDefault();
                                        if (ColModel != null && !string.IsNullOrWhiteSpace(ColModel.val))
                                        {
                                            StartCol = Convert.ToInt32(ColModel.val);
                                        }

                                        BussinessObjects.IDKeyValModel RowModel = importModel.Where(m => m.id == item.id && m.key == "Row").ToList().FirstOrDefault();
                                        if (ColModel != null && !string.IsNullOrWhiteSpace(ColModel.val))
                                        {
                                            StartRow = Convert.ToInt32(RowModel.val);
                                        }

                                        BussinessObjects.IDKeyValModel DataTypeModel = importModel.Where(m => m.id == item.id && m.key == "DataType").ToList().FirstOrDefault();
                                        if (ColModel != null && !string.IsNullOrWhiteSpace(ColModel.val))
                                        {
                                            DataType = DataTypeModel.val;
                                        }
                                        ////end load config, begin load excel to json string
                                        if (StartRow == 0)
                                        {
                                            StartRow = 1;
                                        }

                                        if (StartCol == 0)
                                        {
                                            StartCol = 1;
                                        }

                                        stepDebug = "row:col";
                                        for (int rowNum = StartRow; rowNum <= ws.Dimension.End.Row; rowNum++)
                                        {
                                            stepDebug = "dataload";
                                            if (ws.Cells[rowNum, StartCol] != null && ws.Cells[rowNum, StartCol].Value != null && ws.Cells[rowNum, StartCol].Value.ToString().Trim() != "")
                                            {
                                                stepDebug = "add";
                                                string value = "";
                                                string format = ws.Cells[rowNum, StartCol].Style.Numberformat.Format;
                                                if (format.IndexOf("yy") >= 0 || format.IndexOf("mm") >= 0 || format.IndexOf("hh") >= 0)
                                                {
                                                    long datenum = 0;
                                                    string cellVal = ws.Cells[rowNum, StartCol].Value.ToString();
                                                    long.TryParse(cellVal, out datenum);
                                                    if (datenum > 0)
                                                        value = DateTime.FromOADate(datenum).ToString();
                                                    else value = cellVal;
                                                }
                                                else
                                                {
                                                    value = ws.Cells[rowNum, StartCol].Value.ToString().Trim();
                                                }

                                                value = HttpUtility.JavaScriptStringEncode(value);
                                                value = DataFunction.SQLStringEcodẹ̣(value);
                                                //if (value.IndexOf("'") >= 0) { //debug only
                                                //    value.Replace("'", "\'\'");
                                                //}
                                                dataLoad.Add(new IDKeyValModel
                                                {
                                                    id = rowNum.ToString(),
                                                    key = item.val,
                                                    val = value
                                                });
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ////save data to db
                List<string> parms = new List<string>();
                stepDebug = "Param";

                parms.Add("@SSID");
                parms.Add(FSessionID);
                parms.Add("@DomainID");
                parms.Add(SEmployee.DomainID.ToString());
                parms.Add("@USERID");
                parms.Add(SEmployee.UserID.ToString());
                parms.Add("@FORMCODE");
                parms.Add(FormCode);

                parms.Add("@jsString");
                parms.Add(Newtonsoft.Json.JsonConvert.SerializeObject(dataLoad));

                stepDebug = "Param end";
                DataTable response = DataFunction.GetImportDataFromService(ServiceUrl_Report, "", parms, FormCode, DataSource, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                if (response == null)
                {
                    response = new DataTable();
                }
                stepDebug = "Param response";
                string JSONresult = Newtonsoft.Json.JsonConvert.SerializeObject(response);
                stepDebug = "return";
                return Json(JSONresult, JsonRequestBehavior.AllowGet);

            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ImportExcel", ex.Message, FormCode + ":" + ControlID + ":" + stepDebug, DataSource);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public ActionResult ImportExcelRawData(string formatType = "", string FormCode = "", string DataSource = "", string FSessionID = "", string ControlID = "")
        {
            string stepDebug = "Imp:1";
            try
            {
                StringBuilder jsString = new StringBuilder();
                jsString.Append("[");
                StringBuilder jsStringHeader = new StringBuilder();
                jsStringHeader.Append("{");
                ////load model
                if (FormCode == "")
                {
                    throw new System.InvalidOperationException("FormCode Is null");
                };
                CategoriesItemModel model = GetFormModelCache(FormCode);

                if (model.ETL == null || model.ETL.Count == 0)
                {
                    throw new System.InvalidOperationException("Model Not Load(Is null)");
                }

                stepDebug = "Imp:2";
                BussinessObjects.FItem importConfig = model.ETL.Find(m => m.Key == ControlID);
                if (importConfig == null)
                {
                    throw new System.InvalidOperationException("Import Config(Is null)");
                }

                stepDebug = "Imp:3";
                List<BussinessObjects.IDKeyValModel> importModel = importConfig != null && importConfig.ETLConfig != null ? Newtonsoft.Json.JsonConvert.DeserializeObject<List<BussinessObjects.IDKeyValModel>>(importConfig.ETLConfig) : new List<BussinessObjects.IDKeyValModel>();
                if (importModel == null || importModel.Count == 0)
                {
                    throw new System.InvalidOperationException("Import Model(Is null)");
                }

                stepDebug = "Imp:4";

                List<SelectListModel> listCheck = new List<SelectListModel>();
                List<SelectListModel> listError = new List<SelectListModel>();
                //load excel
                foreach (string file in Request.Files)
                {
                    HttpPostedFileBase fileContent = Request.Files[file];
                    stepDebug = "Imp:5";
                    if (fileContent != null && fileContent.ContentLength > 0)
                    {
                        Stream stream = fileContent.InputStream;
                        stepDebug = "Imp:6";
                        using (ExcelPackage package = new ExcelPackage(stream))
                        {
                            stepDebug = "Imp:7";
                            ExcelWorkbook workBook = package.Workbook;
                            if (workBook != null)
                            {
                                if (workBook.Worksheets.Count > 0)
                                {
                                    stepDebug = "Imp:8";
                                    ExcelWorksheet ws = workBook.Worksheets.FirstOrDefault(m => m.Hidden == eWorkSheetHidden.Visible);
                                    ////select column to load data
                                    List<BussinessObjects.IDKeyValModel> listColumn = new List<IDKeyValModel>();
                                    List<BussinessObjects.IDKeyValModel> listID = importModel.Where(m => m.key == "DataType" && m.val == "List").ToList();

                                    var queryColumnsList = (
                                            from DataType in importModel.Where(m => m.key == "DataType" && m.val == "List")
                                            join ItemName in importModel.Where(m => m.key == "ItemName") on DataType.id equals ItemName.id
                                            join Col in importModel.Where(m => m.key == "Col") on DataType.id equals Col.id
                                            join Row in importModel.Where(m => m.key == "Row") on DataType.id equals Row.id
                                            join FormatType in importModel.Where(m => m.key == "FormatType") on DataType.id equals FormatType.id into lj
                                            from ft in lj.DefaultIfEmpty()
                                            select new
                                            {
                                                id = DataType.id,
                                                DataType = DataType.val,
                                                ItemName = ItemName.val,
                                                FormatType = ft?.val ?? "TextBox",
                                                Col = Col.val,
                                                Row = Row.val,
                                                ColP = 0,
                                                RowP = 0
                                            }
                                        ).ToList();

                                    var queryHeaderList = (
                                            from DataType in importModel.Where(m => m.key == "DataType" && m.val == "Header")
                                            join ItemName in importModel.Where(m => m.key == "ItemName") on DataType.id equals ItemName.id
                                            join Col in importModel.Where(m => m.key == "Col") on DataType.id equals Col.id
                                            join Row in importModel.Where(m => m.key == "Row") on DataType.id equals Row.id
                                            join FormatType in importModel.Where(m => m.key == "FormatType") on DataType.id equals FormatType.id into lj
                                            from ft in lj.DefaultIfEmpty()
                                            select new
                                            {
                                                id = DataType.id,
                                                DataType = DataType.val,
                                                ItemName = ItemName.val,
                                                FormatType = ft?.val ?? "TextBox",
                                                Col = Col.val,
                                                Row = Row.val,
                                                ColP = 0,
                                                RowP = 0,
                                                val = ""
                                            }
                                        ).ToList();

                                    //for header item

                                    foreach (var item in queryHeaderList)
                                    {
                                        int row = Convert.ToInt32(item.Row);
                                        int col = Convert.ToInt32(item.Col);
                                        var value = "";
                                        if (item.FormatType.IndexOf("Date") >= 0)
                                        {
                                            long datenum = 0;
                                            string cellVal = ws.Cells[row, col].Value.ToString();
                                            long.TryParse(cellVal, out datenum);
                                            value = DateTime.FromOADate(datenum).ToString();
                                            if (datenum > 0)
                                                value = DateTime.FromOADate(datenum).ToString();
                                            else value = cellVal;
                                        }
                                        else
                                        {
                                            value = ws.Cells[row, col].Value.ToString().Trim();
                                        }
                                        value = HttpUtility.JavaScriptStringEncode(value.Replace("'", "''"));
                                        jsStringHeader.Append("\"" + item.ItemName + "\":\"" + value + "\",");
                                    }
                                    jsStringHeader.Append("}");
                                    jsString.Append("{\"id\": \"0\",\"Header\":" + jsStringHeader.ToString().Replace(",}", "}") + "}");


                                    int StartRow = 2;
                                    for (int rowNum = StartRow; rowNum <= ws.Dimension.End.Row; rowNum++)
                                    {
                                        stepDebug = "dataload";
                                        if (rowNum > 1)
                                        {
                                            jsString.Append(",{\"id\":" + rowNum.ToString());
                                            foreach (var item in queryColumnsList)
                                            {

                                                string colName = item.ItemName;
                                                int colNum = Convert.ToInt32(item.Col);

                                                if (ws.Cells[rowNum, colNum] != null && ws.Cells[rowNum, colNum].Value != null && ws.Cells[rowNum, colNum].Value.ToString().Trim() != "")
                                                {
                                                    stepDebug = "add";
                                                    string value = "";
                                                    string format = ws.Cells[rowNum, colNum].Style.Numberformat.Format;
                                                    if (item.FormatType.IndexOf("Date") >= 0 || format.IndexOf("yy") >= 0 || format.IndexOf("mm") >= 0 || format.IndexOf("hh") >= 0)
                                                    {
                                                        long datenum = 0;
                                                        string cellVal = ws.Cells[rowNum, colNum].Value.ToString();
                                                        long.TryParse(cellVal, out datenum);
                                                        value = DateTime.FromOADate(datenum).ToString();
                                                        if (datenum > 0)
                                                            value = DateTime.FromOADate(datenum).ToString();
                                                        else value = cellVal;
                                                    }
                                                    else
                                                    {
                                                        value = ws.Cells[rowNum, colNum].Value.ToString().Trim();
                                                    }
                                                    value = HttpUtility.JavaScriptStringEncode(value.Replace("'", "''"));
                                                    jsString.Append(",\"" + colName + "\":\"" + value + "\"");
                                                }
                                            }
                                            jsString.Append("}");
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
                jsString.Append("]");
                ////save data to db
                List<string> parms = new List<string>();
                stepDebug = "Param";


                parms.Add("@SSID");
                parms.Add(FSessionID);
                parms.Add("@DomainID");
                parms.Add(SEmployee.DomainID.ToString());
                parms.Add("@USERID");
                parms.Add(SEmployee.UserID.ToString());
                parms.Add("@FORMCODE");
                parms.Add(FormCode);

                parms.Add("@jsString");
                parms.Add(jsString.ToString());

                stepDebug = "Param end";
                DataTable response = DataFunction.GetImportDataFromService(ServiceUrl_Report, "", parms, FormCode, DataSource, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                if (response == null)
                {
                    response = new DataTable();
                }
                stepDebug = "Param response";
                string JSONresult = Newtonsoft.Json.JsonConvert.SerializeObject(response);
                stepDebug = "return";
                return Json(JSONresult, JsonRequestBehavior.AllowGet);

            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ImportExcel", ex.Message, FormCode + ":" + ControlID + ":" + stepDebug, DataSource);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }


        [HttpPost]
        public ActionResult ImportExcelConfig(string formatType = "", string FormCode = "", string DataSource = "", string FSessionID = "", string ControlID = "", string ItemID = "")
        {
          

            string stepDebug = "Imp:1";
            try
            {
                List<BussinessObjects.IDKeyValModel> dataLoad = new List<BussinessObjects.IDKeyValModel>();
                //load excel
                foreach (string file in Request.Files)
                {
                    HttpPostedFileBase fileContent = Request.Files[file];
                    stepDebug = "Imp:5";
                    if (fileContent != null && fileContent.ContentLength > 0)
                    {
                        Stream stream = fileContent.InputStream;
                        stepDebug = "Imp:6";
                        using (ExcelPackage package = new ExcelPackage(stream))
                        {
                            stepDebug = "Imp:7";
                            ExcelWorkbook workBook = package.Workbook;
                            if (workBook != null)
                            {
                                if (workBook.Worksheets.Count > 0)
                                {
                                    stepDebug = "Imp:8";
                                    ExcelWorksheet ws = workBook.Worksheets.FirstOrDefault(m => m.Hidden == eWorkSheetHidden.Visible);
                                    ////select column to load data

                                    for (int rowNum = 1; rowNum <= ws.Dimension.End.Row; rowNum++)
                                    {
                                        for (int colNum = 1; colNum <= ws.Dimension.End.Column; colNum++)
                                        {
                                            stepDebug = "dataload";
                                            if (ws.Cells[rowNum, colNum] != null && ws.Cells[rowNum, colNum].Value != null && ws.Cells[rowNum, colNum].Value.ToString().Trim() != "")
                                            {
                                                string cellVal = ws.Cells[rowNum, colNum].Value.ToString().Trim();
                                                string[] cellValArr = cellVal.Split('.');
                                                if (cellVal.IndexOf("#") >= 0 && cellValArr.Length > 0)
                                                {
                                                    stepDebug = "add";
                                                    dataLoad.Add(new IDKeyValModel
                                                    {
                                                        id = (rowNum * 10000 + colNum).ToString(),
                                                        key = "ItemName",
                                                        val = cellVal.Substring(cellVal.IndexOf('.') + 1, cellVal.Length - cellVal.IndexOf('.') - 1)
                                                    });
                                                    dataLoad.Add(new IDKeyValModel
                                                    {
                                                        id = (rowNum * 10000 + colNum).ToString(),
                                                        key = "DataType",
                                                        val = cellValArr[0].Replace("#", "")
                                                    });
                                                    dataLoad.Add(new IDKeyValModel
                                                    {
                                                        id = (rowNum * 10000 + colNum).ToString(),
                                                        key = "Col",
                                                        val = colNum.ToString(),
                                                    });
                                                    dataLoad.Add(new IDKeyValModel
                                                    {
                                                        id = (rowNum * 10000 + colNum).ToString(),
                                                        key = "Row",
                                                        val = rowNum.ToString(),
                                                    });
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ////save data to db
                List<string> parms = new List<string>();
                stepDebug = "Param";


                parms.Add("@SSID");
                parms.Add(FSessionID);
                parms.Add("@DomainID");
                parms.Add(SEmployee.DomainID.ToString());
                parms.Add("@USERID");
                parms.Add(SEmployee.UserID.ToString());
                parms.Add("@FORMCODE");
                parms.Add(FormCode);
                parms.Add("@ID");
                parms.Add(ItemID);

                parms.Add("@jsString");
                parms.Add(Newtonsoft.Json.JsonConvert.SerializeObject(dataLoad));

                stepDebug = "Param end";
                DataTable response = DataFunction.SaveCategoriesItemFromService(ServiceUrl_Config, "", parms, FormCode, DataSource, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                if (response == null)
                {
                    response = new DataTable();
                }
                stepDebug = "Param response";
                string JSONresult = Newtonsoft.Json.JsonConvert.SerializeObject(response);
                stepDebug = "return";
                return Json(JSONresult, JsonRequestBehavior.AllowGet);

            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ImportExcel", ex.Message, FormCode + ":" + ControlID + ":" + stepDebug, DataSource);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }
    }

}