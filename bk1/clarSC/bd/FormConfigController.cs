using BussinessModels;
using BussinessObjects;
using Categories.Models;
using Helpers.Functions;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.Caching;
using System.Web.Mvc;

namespace Categories.Controllers
{
    public class FormConfigController : BaseController
    {
        protected string serviceUrl_Config = Helpers.Functions.ConfigFunctions.GetConfigByDomain("ServiceUrl_Config");
        protected string serviceUrl_Base = Helpers.Functions.ConfigFunctions.GetConfigByDomain("serviceUrl_Base");

        #region Create Form 
        public ActionResult CreateForm(int DomainID = 0, string FormCode = "", string FormType = "", string GetList = "", string TableSave = "")
        {
            if (SEmployee.UserID != 1) 
                return Redirect("/User/Login?returnUrl=/");
            ViewBag.DomainID = DomainID == 0 ? Convert.ToInt32(SEmployee.DomainID) : DomainID;
            ViewBag.TreeID = "FormConfigTree";
            ViewBag.FormCode = FormCode;
            ViewBag.FormType = FormType;
            ViewBag.GetList = GetList;
            ViewBag.TableSave = TableSave;
            ViewBag.serviceUrl_Config = serviceUrl_Config;
           

            return View();
        }
        public ActionResult CreateFlow(int DomainID = 0, string FormCode = "", string FormType = "", string GetList = "", string TableSave = "")
        {
            if (SEmployee.UserID != 1)
                return Redirect("/User/Login?returnUrl=/");
            ViewBag.DomainID = DomainID == 0 ? Convert.ToInt32(SEmployee.DomainID) : DomainID;
            ViewBag.TreeID = "FormConfigTree";
            ViewBag.FormCode = FormCode;
            ViewBag.FormType = FormType;
            ViewBag.GetList = GetList;
            ViewBag.TableSave = TableSave;

            return View();
        }
        public JsonResult CreateForm_GetList(string Action = "", int DomainID = 0, string NodeID = "", string FormCode = "", string FormType = "")
        {
            List<TreeViewModel> dataList = DataFunction.GetCustomObjectListFromService<TreeViewModel>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                           "@SSID", "", "@ACTION", Action, "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(),"@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );
            return Json(dataList, JsonRequestBehavior.AllowGet);
        }
        public JsonResult CreateFormItems_GetList(string Action = "", int DomainID = 0, string NodeID = "", string FormCode = "", string FormType = "")
        {
            if (SEmployee.UserID != 1)
                 return Json("ERR", JsonRequestBehavior.AllowGet);

            List<FormConfigModel> dataList = DataFunction.GetCustomObjectListFromService<FormConfigModel>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                           "@SSID", "", "@ACTION", Action, "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(),"@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );
            return Json(dataList, JsonRequestBehavior.AllowGet);
        }
        public JsonResult CreateFormItems_Save(FormConfigModel model, string Action = "", string DomainID = "", string NodeID = "", string ParentID = "", string FormCode = "", string IsReCreate = "", string FormType = "")
        {
            if (SEmployee.UserID != 1)
                return Json("ERR", JsonRequestBehavior.AllowGet);
            List<ColumnItem> DataResponse = DataFunction.GetDataColumns(
                serviceUrl_Config, 
                new List<string>() {
                "@SSID", "",
                "@ACTION", Action,
                "@OBJECTID", "",
                "@USERID", SEmployee.UserID.ToString(),
                "@DomainID", DomainID,
                "@ItemID", model.ItemID.ToString()??"",
                "@ItemName", model.ItemName??"",
                "@ItemStatus", model.ItemStatus??"",
                "@ItemType", model.ItemType??"",
                "@ItemParent", model.ItemParent??"",
                "@NodeID",NodeID??"",
                "@ParentID", ParentID??"",
                "@FormCode", FormCode,
                "@Value",model.Value,
                "@Index", model.Index ,
                "@Col", model.Col ,
                "@Key", model.Key ,
                "@Holder", model.Holder ,
                "@Display", model.Display ,
                "@DisplayVN", model.DisplayVN ,
                "@DisplayCdn", model.DisplayCdn ,
                "@OptionConfig", model.OptionConfig ,
                "@DefaultValue", model.DefaultValue ,
                "@MaxLength", model.MaxLength ,
                "@IsRequire", model.IsRequire ,
                "@Note", model.Note ,
                "@Pattern", model.Pattern ,
                "@Disable", model.Disable ,
                "@DataSource", model.DataSource ,
                "@ColCode", model.ColCode ,
                "@ColName", model.ColName ,
                "@Condition", model.Condition ,
                "@SourceCondition", model.SourceCondition,
                "@DBSource", model.DBSource,
                "@ServiceUrl", model.ServiceUrl,
                "@RowNum", model.RowNum,
                "@IsReCreate", IsReCreate,
                "@FormType", FormType,
                "@StepControl", model.StepControl,
                "@StepAction", model.StepAction,
                "@ObjectInCharge", model.ObjectInCharge,
                "@Assigner", model.Assigner,
                "@CP", model.CP,
                "@JsData", model.JsData,
                "@StepOption", model.StepOption,
                "@TitleIcon", model.TitleIcon,
                "@TitleConfig", model.TitleConfig,
                "@ParentColSize", model.ParentColSize,
                "@Scripts", model.Scripts,
                "@TabKey", model.TabKey,
                "@EditOnList", model.EditOnList,
                "@NotSaveDB", model.NotSaveDB,
                "@NotRender", model.NotRender,
                "@ETLConfig", model.ETLConfig


            }, "PSYS.FormConfig_Save", true
            );
            if (model.ItemName!= null && model.ItemName.ToUpper() == "FORM")
             {
                string columnString = Newtonsoft.Json.JsonConvert.SerializeObject(DataResponse);
                PutDataResponse re = DataFunction.PutDataToService(serviceUrl_Config, "Request/GetData", "", new List<string>() {
                    "@ItemID", model.ItemID.ToString(),
                    "@ColumnLists", columnString

                }, "PSYS.ExecProcHelper_save", true
            );

            }
            ObjectCache cache = MemoryCache.Default;
            List<string> cacheKeys = cache.Select(kvp => kvp.Key).ToList();
            foreach (string cacheKey in cacheKeys)
            {
                cache.Remove(cacheKey);
            }
            return Json("DONE", JsonRequestBehavior.AllowGet);
        }
       
        #endregion
        public JsonResult CreateSaveProc(string Action = "", int DomainID = 0, string NodeID = "", string FormCode = "")
        {
            if (SEmployee.UserID != 1)
                return Json("ERR", JsonRequestBehavior.AllowGet);

            List<StatusResponseModel> dataList = DataFunction.GetCustomObjectListFromService<StatusResponseModel>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                       "@SSID", "", "@ACTION", "Create_Save", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(),
                       "@FormCode", FormCode.ToString()
                   }, "[UTIL].[sp_GenerateProcSave]", true
                );
            return Json(dataList, JsonRequestBehavior.AllowGet);
        }

        public JsonResult CreateSelectProc(string Action = "", int DomainID = 0, string NodeID = "", string FormCode = "")
        {
            if (SEmployee.UserID != 1)
                return Json("ERR", JsonRequestBehavior.AllowGet);

            List<StatusResponseModel> dataList = DataFunction.GetCustomObjectListFromService<StatusResponseModel>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                       "@SSID", "", "@ACTION", "Create_GetList", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(),
                       "@FormCode", FormCode.ToString()
                   }, "[UTIL].[sp_GenerateProcSelect]", true
                );
            return Json(dataList, JsonRequestBehavior.AllowGet);
        }

        public JsonResult CreateFormConfig(FormConfigModel model, string Action = "", string DomainID = "", string NodeID = "", string ParentID = "", string FormCode = "", string FormType = "")
        {
            if (SEmployee.UserID != 1)
                return Json("ERR", JsonRequestBehavior.AllowGet);
            NodeID = "";
            string DataString = "";
            CategoriesItemModel CateModel = new CategoriesItemModel();

            List<FormConfigModel> dataList = DataFunction.GetCustomObjectListFromService<FormConfigModel>
               (
                  serviceUrl_Config, "Request/GetData", "", new List<string>() {
                           "@SSID", "", "@ACTION", "FormHeader", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                  }, "PSYS.FormConfig_GetList", true
               );
            if (dataList != null && dataList.Count > 1)
            {
                CateModel.FormCode = dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault().Value ?? "";
                CateModel.ObjectID = dataList.Where(m => m.ItemName.ToUpper().Equals("OBJECTID")).FirstOrDefault().Value ?? "";
                
                CateModel.FixRequestID = 
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("FIXREQUESTID"))!=null && 
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("FIXREQUESTID")).FirstOrDefault()!=null 
                    ? dataList.Where(m => m.ItemName !=null && m.ItemName.ToUpper().Equals("FIXREQUESTID")).FirstOrDefault().Value : "";
                CateModel.PublicRequest = 
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST"))!=null &&
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST")).FirstOrDefault() != null
                    ? dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST")).FirstOrDefault().Value : "";

                CateModel.Title = dataList.Where(m => m.ItemName.ToUpper().Equals("TITLE")).FirstOrDefault().Display;
                CateModel.TitleVN = dataList.Where(m => m.ItemName.ToUpper().Equals("TITLE")).FirstOrDefault().DisplayVN;
                CateModel.Description = dataList.Where(m => m.ItemName.ToUpper().Equals("DESCRIPTION")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("DESCRIPTION")).FirstOrDefault().Display : "";
                CateModel.DescriptionVN = dataList.Where(m => m.ItemName.ToUpper().Equals("DESCRIPTION")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("DESCRIPTION")).FirstOrDefault().DisplayVN : "";

                CateModel.CP = dataList.Where(m => m.ItemName.ToUpper().Equals("CP")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("CP")).FirstOrDefault().DisplayVN : "";
                CateModel.JsData = dataList.Where(m => m.ItemName.ToUpper().Equals("JsData")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("JsData")).FirstOrDefault().DisplayVN : "";

                CateModel.BreadCrumb = dataList.Where(m => m.ItemName.ToUpper().Equals("BREADCRUMB")).FirstOrDefault().Value ?? "";
                CateModel.SourceType = dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCETYPE")).FirstOrDefault() != null?
                            dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCETYPE")).FirstOrDefault().Value : "Table";
                

                CateModel.Source = dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCE")).FirstOrDefault().Value ?? "";
                CateModel.ColID = dataList.Where(m => m.ItemName.ToUpper().Equals("COLID")).FirstOrDefault().Value ?? "";
                CateModel.Layout = dataList.Where(m => m.ItemName.ToUpper().Equals("LAYOUT")).FirstOrDefault().Value ?? "";
                CateModel.Target = dataList.Where(m => m.ItemName.ToUpper().Equals("TARGET")).FirstOrDefault().Value ?? "";
                CateModel.TargetType = dataList.Find(m => m.ItemName.ToUpper().Equals("TARGET"))?.Pattern ?? "FormDataSave";
                List<FItem> LayoutConfig = DataFunction.GetCustomObjectListFromService<FItem>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Layout", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );
                CateModel.LayoutConfig = LayoutConfig;

                List<FItem> SourceConfig = DataFunction.GetCustomObjectListFromService<FItem>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Source", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );
                CateModel.SourceConfig = SourceConfig;

                List<FItem> FormItem = DataFunction.GetCustomObjectListFromService<FItem>
                  (
                     serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Form", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                     }, "PSYS.FormConfig_GetList", true
                  );

                FormItem.Where(m => m.Type.ToUpper().Equals("DATALISTS")).ToList().ForEach(val =>
                {
                    List<FItem> data = DataFunction.GetCustomObjectListFromService<FItem>
                    (
                       serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                   "@SSID", "", "@ACTION", "DataLists", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",val.ID.ToString() , "@FormCode", FormCode.ToString(), "@FormType", FormType
                       }, "PSYS.FormConfig_GetList", true
                    );
                    val.DataLists = data;
                });
                CateModel.Form = FormItem;

                List<FItem> ReportItem = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Report", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.Report = ReportItem;

                List<FItem> ActionList = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "ActionList", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.ActionList = ActionList;

            }
            List<FItem> ProcessItem = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Process", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

            CateModel.Process = ProcessItem;
            /////////////////////////////////////
            List<FItem> TabList = DataFunction.GetCustomObjectListFromService<FItem>
            (
               serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "TabList", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
               }, "PSYS.FormConfig_GetList", true
            );

            CateModel.TabList = TabList;

            /////////////////////////////////////
            List<FItem> ETLConfig = DataFunction.GetCustomObjectListFromService<FItem>
            (
                serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                "@SSID", "", "@ACTION", "ETL", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                }, "PSYS.FormConfig_GetList", true
            );

            CateModel.ETL = ETLConfig;
            /////////////////////////////////////
            List<FItem> ModalForm = DataFunction.GetCustomObjectListFromService<FItem>
            (
                serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                "@SSID", "", "@ACTION", "ModalForm", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                }, "PSYS.FormConfig_GetList", true
            );

            CateModel.ModalForm = ModalForm;
            /////////////////////////////////////
            List<FItem> Footer = DataFunction.GetCustomObjectListFromService<FItem>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Footer", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );

            CateModel.Footer = Footer;

            bool status = ReaderTools.SerializationObjetTolJson(CateModel, FormCode + ".jconfig", "Categories");
            if (status)
            {
                DataString = "DONE";
            }
            else
            {
                DataString = "ERR";
            }
            ObjectCache cache = MemoryCache.Default;
            List<string> cacheKeys = cache.Select(kvp => kvp.Key).ToList();
            foreach (string cacheKey in cacheKeys)
            {
                cache.Remove(cacheKey);
            }
            return Json(DataString, JsonRequestBehavior.AllowGet);
        }

        public JsonResult CreateReportConfig(FormConfigModel model, string ActionType = "", string DomainID = "", string NodeID = "", string ParentID = "", string FormCode = "", string FormType = "")
        {
            if (SEmployee.UserID != 1)
                return Json("ERR", JsonRequestBehavior.AllowGet);
            string DataString = "";
            CategoriesItemModel CateModel = new CategoriesItemModel();

            List<FormConfigModel> dataList = DataFunction.GetCustomObjectListFromService<FormConfigModel>
               (
                  serviceUrl_Config, "Request/GetData", "", new List<string>() {
                           "@SSID", "", "@ACTION", "FormHeader", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                  }, "PSYS.FormConfig_GetList", true
               );
            if (dataList != null && dataList.Count > 1)
            {
                CateModel.ObjectID = dataList.Where(m => m.ItemName.ToUpper().Equals("OBJECTID")).FirstOrDefault().Value ?? "";
                
                CateModel.FormCode = dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault().Value ?? "";
                CateModel.FixRequestID =
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("FIXREQUESTID")) != null &&
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("FIXREQUESTID")).FirstOrDefault() != null
                    ? dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("FIXREQUESTID")).FirstOrDefault().Value : "";
                CateModel.PublicRequest =
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST")) != null &&
                    dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST")).FirstOrDefault() != null
                    ? dataList.Where(m => m.ItemName != null && m.ItemName.ToUpper().Equals("PUBLICREQUEST")).FirstOrDefault().Value : "";

                CateModel.Title = dataList.Where(m => m.ItemName.ToUpper().Equals("TITLE")).FirstOrDefault().Display;
                CateModel.TitleVN = dataList.Where(m => m.ItemName.ToUpper().Equals("TITLE")).FirstOrDefault().DisplayVN;
                CateModel.Description = dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault() !=null? dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault().Display:"";
                CateModel.DescriptionVN = dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault()!=null? dataList.Where(m => m.ItemName.ToUpper().Equals("FORMCODE")).FirstOrDefault().DisplayVN:"";

                CateModel.CP = dataList.Where(m => m.ItemName.ToUpper().Equals("CP")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("CP")).FirstOrDefault().DisplayVN : "";
                CateModel.JsData = dataList.Where(m => m.ItemName.ToUpper().Equals("JsData")).FirstOrDefault() != null ? dataList.Where(m => m.ItemName.ToUpper().Equals("JsData")).FirstOrDefault().DisplayVN : "";


                CateModel.BreadCrumb = dataList.Where(m => m.ItemName.ToUpper().Equals("BREADCRUMB")).FirstOrDefault().Value ?? "";
                CateModel.Source = dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCE")).FirstOrDefault().Value ?? "";
                CateModel.SourceType = dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCETYPE")).FirstOrDefault() != null ?
                             dataList.Where(m => m.ItemName.ToUpper().Equals("SOURCETYPE")).FirstOrDefault().Value : "Table";
                CateModel.TargetType = dataList.Where(m => m.ItemName.ToUpper().Equals("TARGETTYPE")).FirstOrDefault() != null ?
                           dataList.Where(m => m.ItemName.ToUpper().Equals("TARGETTYPE")).FirstOrDefault().Value : "Table";

                CateModel.ColID = dataList.Where(m => m.ItemName.ToUpper().Equals("COLID")).FirstOrDefault().Value ?? "";
                CateModel.Layout = dataList.Where(m => m.ItemName.ToUpper().Equals("LAYOUT")).FirstOrDefault().Value ?? "";
                CateModel.Target = dataList.Where(m => m.ItemName.ToUpper().Equals("TARGET")).FirstOrDefault().Value ?? "";
                List<FItem> LayoutConfig = DataFunction.GetCustomObjectListFromService<FItem>
                  (
                     serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                   "@SSID", "", "@ACTION", "Layout", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                     }, "PSYS.FormConfig_GetList", true
                  );
                CateModel.LayoutConfig = LayoutConfig;
                List<FItem> SourceConfig = DataFunction.GetCustomObjectListFromService<FItem>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Source", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );
                CateModel.SourceConfig = SourceConfig;
                List<FItem> FormItem = DataFunction.GetCustomObjectListFromService<FItem>
                  (
                     serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Form", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                     }, "PSYS.FormConfig_GetList", true
                  );

                CateModel.Form = FormItem;

                List<FItem> ReportItem = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Report", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.Report = ReportItem;

                List<FItem> ActionList = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "ActionList", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.ActionList = ActionList;

                List<FItem> Footer = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "Footer", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID", NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.Footer = Footer;
                /////////////////////////////////////
                List<FItem> ETLConfig = DataFunction.GetCustomObjectListFromService<FItem>
                (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                "@SSID", "", "@ACTION", "ETL", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                );

                CateModel.ETL = ETLConfig;
                /////////////////////////////////////
                List<FItem> ModalForm = DataFunction.GetCustomObjectListFromService<FItem>
                (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                "@SSID", "", "@ACTION", "ModalForm", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                );

                CateModel.ModalForm = ModalForm;

                List<FItem> ProcessItem = DataFunction.GetCustomObjectListFromService<FItem>
                 (
                    serviceUrl_Config, "Request/GetData", "", new List<string>() {
                                       "@SSID", "", "@ACTION", "Process", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                    }, "PSYS.FormConfig_GetList", true
                 );

                CateModel.Process = ProcessItem;

                ////////////////////////////////////////

                List<FItem> TabList = DataFunction.GetCustomObjectListFromService<FItem>
                (
                   serviceUrl_Config, "Request/GetData", "", new List<string>() {
                               "@SSID", "", "@ACTION", "TabList", "@OBJECTID", "", "@USERID", SEmployee.UserID.ToString(),"@DomainID", DomainID.ToString(), "@NodeID",  NodeID.ToString(), "@FormCode", FormCode.ToString(), "@FormType", FormType
                   }, "PSYS.FormConfig_GetList", true
                );

                CateModel.TabList = TabList;
                /////////////////////////////////////
            }

            bool status = ReaderTools.SerializationObjetTolJson(CateModel, FormCode + ".jconfig", "SReports");
            if (status)
            {
                DataString = "DONE";
            }
            else
            {
                DataString = "ERR";
            }
            ObjectCache cache = MemoryCache.Default;
            List<string> cacheKeys = cache.Select(kvp => kvp.Key).ToList();
            foreach (string cacheKey in cacheKeys)
            {
                cache.Remove(cacheKey);
            }
            return Json(DataString, JsonRequestBehavior.AllowGet);
        }

    }
}