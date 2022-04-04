using BussinessObjects;
using Helpers.Functions;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web.Mvc;

namespace Categories.Controllers
{
    public class SReportsController : CategoriesBaseController
    {
        // GET: Report
        //public ActionResult Index(string key = "", int currentPage = 1,int DomainID =0)
        //{
        //    return GetViewSReportBase(key , currentPage, DomainID);
        //}
        public ActionResult Index(string FormCode = "", long ID = 0, long ViewID = 0, string ViewCode="")
        {
            ViewBag.ViewID = ViewID;
            ViewBag.ViewCode = ViewCode;
            CategoriesItemModel model = GetFormModelCache(FormCode);
            if (SEmployee.LangCode == "VN")
            {
                model.LangCode = "VN";
            }
            else
            {
                model.LangCode = "EN";
            }
            if (model != null)
            {
                model.ColVal = ID.ToString();
                model.SessionID = Guid.NewGuid().ToString();
            }

            if (!(model.PublicRequest == "1") && !IsAuthorization(model.ObjectID))
            {
                TempData["error"] = "ERRRPT-001: Đang kiểm tra phân quyền, vui lòng thử lại sau:" + model.FormCode;
                DataFunction.WriteLog("SReportsController-Index", TempData["error"].ToString(), model.PublicRequest.ToString(), model.ObjectID);
                return View(model);
            }
            ViewBag.IsAdd = IsAuthorizationAction(model.ObjectID, "ADD");
            ViewBag.IsEdit = IsAuthorizationAction(model.ObjectID, "EDIT");
            ViewBag.IsDelete = IsAuthorizationAction(model.ObjectID, "DELETE");

            return View(model);
        }
        private static string GetServicesURLLinkFromName(string ServiceUrlName)
        {
            if (string.IsNullOrWhiteSpace(ServiceUrlName) || ServiceUrlName == "undefined") 
                return Helpers.Functions.ConfigFunctions.GetConfigByDomain("ServiceUrl_Report");
            if (ServiceUrlName.ToLower().IndexOf("http") >= 0)
            {
                return ServiceUrlName;
            }
            else
            {
                return Helpers.Functions.ConfigFunctions.GetConfigByDomain(ServiceUrlName);
            }
        }
        [HttpPost]
        public JsonResult GetDataReports(string ReportCode = "", string ObjectID = "", string ServiceUrl="")
        {
            try
            {
                ServiceUrl = GetServicesURLLinkFromName(ServiceUrl);
                if (ReportCode == "")
                {
                    return Json("ReportCode is null", JsonRequestBehavior.AllowGet);
                }
                CategoriesItemModel model = GetFormModelCache(ReportCode);
                if (!IsAuthorization(model.ObjectID) && !(model.PublicRequest == "1"))
                {
                    TempData["error"] = "ERRRPT-002: Đang kiểm tra phân quyền, vui lòng thử lại sau." + ReportCode;
                    return Json("", JsonRequestBehavior.AllowGet);
                }

                List<string> para = MapSubmitParamsReport(model.Form);
                if (!string.IsNullOrEmpty(model.Source))
                {
                    model.ReportData = DataFunction.GetDataReportFromService(ServiceUrl, "", para, model.FormCode, model.Source, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                    if (model.Report == null)
                    {
                        DataTable newDT = new DataTable();
                    }
                    string JSONresult = Newtonsoft.Json.JsonConvert.SerializeObject(model.ReportData);
                    var js = Json(JSONresult, JsonRequestBehavior.AllowGet);
                    js.MaxJsonLength = int.MaxValue;
                    return js;
                }
                else
                {
                    DataFunction.WriteLog("GetDataReports", "DataSource IsNull", ReportCode,model.Source);
                }
                return Json("[{'StatusCode':'Source Empty"+ ReportCode + "'}]", JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("GetDataReports", ex.Message, ReportCode);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }
        [HttpPost]
        public JsonResult GetDataReportsByID(string ReportCode = "", string ObjectID = "", long ID=0,string SourceType ="")
        {
            try
            {
                if (ReportCode == "")
                {
                    return Json("ReportCode is null", JsonRequestBehavior.AllowGet);
                }
                CategoriesItemModel model = GetFormModelCache(ReportCode);
                if (!IsAuthorization(model.ObjectID) && !(model.PublicRequest == "1"))
                {
                    TempData["error"] = "ERRRPT-002: Đang kiểm tra phân quyền, vui lòng thử lại sau." + ReportCode;
                    return Json("", JsonRequestBehavior.AllowGet);
                }

                List<string> para = MapSubmitParamsReport(model.Form);
                if(!para.Exists(m=>m == "ID"))
                {
                    para.Add("@ID");
                    para.Add(ID.ToString());
                }
                //string dtsource = ""; 
                //if(SourceType == "ModalForm")
                //{
                //    dtsource = (model.SourceConfig.Find(m => m.Key == "ModalSource") ?? new FItem()).Value?? "";
                //}
                //else
                //{
                //    dtsource = model.Source;
                //}

                model.ReportData = DataFunction.GetDataReportFromService(ServiceUrl_Report, "", para, model.FormCode, model.Source, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                if (model.Report == null)
                {
                    DataTable newDT = new DataTable();
                }
                string JSONresult = Newtonsoft.Json.JsonConvert.SerializeObject(model.ReportData);
                var js = Json(JSONresult, JsonRequestBehavior.AllowGet);
                js.MaxJsonLength = int.MaxValue;
                return js;
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("GetDataReports", ex.Message, ReportCode);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public JsonResult ExportData(string FormCode = "", string SourceID = "")
        {
            try
            {
                CategoriesItemModel model = GetFormModelCache(FormCode);
                List<string> para = MapSubmitParamsReport(model.Form, null, null,"ExportData");

                string Source = "";
                string title = "";
                FItem columnsItem = new FItem();
                if (SourceID == "")
                {
                    Source = model.Source;
                    title = model.Title ?? "";
                }
                else if (model.ETL != null && model.ETL.Count > 0 && model.ETL.Find(m => m.Key == SourceID) != null)
                {
                    columnsItem = model.ETL.Find(m => m.Key == SourceID);
                    Source = columnsItem.DataSource;
                    title = columnsItem.Display ?? "";
                }

                model.ReportData = DataFunction.GetDataReportFromService(ServiceUrl_Report, "ExportData", para, model.FormCode, Source,SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                ReDisplayTable(model.ReportData, model.Report);

                return Json(ExportToExcel(columnsItem, FormCode, model.ReportData,title), JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ExportData", ex.Message, FormCode, SourceID);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }
        [HttpPost]
        public JsonResult ExportDataByID(string FormCode = "", string SourceID = "", long ID = 0, string ViewDataLink="")
        {
            try
            {
                CategoriesItemModel model = GetFormModelCache(FormCode);
                List<string> para = new List<string>();
                para.Add("@SSID");
                para.Add(new Guid().ToString());
                para.Add("@DomainID");
                para.Add(SEmployee.DomainID.ToString());
                para.Add("@USERID");
                para.Add(SEmployee.UserID.ToString());
                para.Add("@ID");
                para.Add(ID.ToString());
                if (!string.IsNullOrWhiteSpace(ViewDataLink) && ViewDataLink != "undefined")
                {
                    para.Add("@ViewDataLink");
                    para.Add(ViewDataLink);
                }
                string Source = "";
                string title = "";
                FItem columnsItem = new FItem();
                if (SourceID == "")
                {
                    Source = model.Source;
                    title = model.Title ?? "";
                }
                else if (model.ETL != null && model.ETL.Count > 0 && model.ETL.Find(m => m.Key == SourceID) != null)
                {
                    columnsItem = model.ETL.Find(m => m.Key == SourceID);
                    Source = columnsItem.DataSource;
                    title = columnsItem.Display ?? "";
                }

                model.ReportData = DataFunction.GetDataReportFromService(ServiceUrl_Report, "ExportData", para, model.FormCode, Source,SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                ReDisplayTable(model.ReportData, model.Report);

                return Json(ExportToExcel(columnsItem, FormCode, model.ReportData, title), JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ExportDataByID", ex.Message, FormCode, SourceID);
                return Json(ex.Message, JsonRequestBehavior.AllowGet);
            }
        }

        public string ExportToExcel(FItem Model, string FormCode, DataTable dataSource,string title="")
        {
            try
            {
                string filepath = GenerateReportName(FormCode,title);

                using (ExcelPackage excelPackage = new ExcelPackage())
                {
                    //create a new Worksheet
                    OfficeOpenXml.ExcelWorksheet worksheet = excelPackage.Workbook.Worksheets.Add("Sheet 1");

                    FileInfo fi = new FileInfo(Server.MapPath(filepath));
                    if (!fi.Directory.Exists)
                    {
                        fi.Directory.Create();
                    }
                    BindingFormatForExcel(Model, worksheet, dataSource,title);
                    excelPackage.SaveAs(fi);
                    return filepath;
                }
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ExportToExcel", ex.Message, FormCode);
                return ex.Message;
            }
        }

        private void BindingFormatForExcel(FItem Model, OfficeOpenXml.ExcelWorksheet worksheet, DataTable dataSource,string title)
        {
            List<string> DECIMAL2CHARACTIER = new List<string>();
            // Set default width cho tất cả column
            worksheet.DefaultColWidth = 15;
            // Tự động xuống hàng khi text quá dài
            //worksheet.Cells.Style.WrapText = true;
            //
            worksheet.Cells[1,2].Style.Font.Size = 16;
            worksheet.Cells[1,2].Style.Font.Bold = true;
            worksheet.Cells[1,2].Value = title ?? "";
            worksheet.Cells[1, 2].Style.WrapText = false;

            worksheet.Cells[2, 2].Value = "Date Created:";
            worksheet.Cells[2, 2].Style.Font.Italic = true;
            worksheet.Cells[2, 3].Value = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss");
            worksheet.Cells[2, 5].Style.Font.Italic = true;
            worksheet.Cells[2, 5].Style.WrapText = false;
            List<BussinessObjects.IDKeyValModel> ETLConfig = Model.ETLConfig != "" ? Newtonsoft.Json.JsonConvert.DeserializeObject<List<BussinessObjects.IDKeyValModel>>(Model.ETLConfig) : new List<BussinessObjects.IDKeyValModel>();

            // create row header
            if (dataSource != null)
            {
                int startRow = 4;
                for (int c = 0; c < dataSource.Columns.Count; c++)
                {
                    worksheet.Cells[startRow, c + 1].Value = dataSource.Columns[c].ColumnName;
                    Color colFromHex = System.Drawing.ColorTranslator.FromHtml("#B7DEE8");
                    worksheet.Cells[startRow, c + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[startRow, c + 1].Style.Fill.BackgroundColor.SetColor(colFromHex);
                    worksheet.Cells[startRow, c + 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                    worksheet.Cells[startRow, c + 1].Style.VerticalAlignment = ExcelVerticalAlignment.Center;

                }
                startRow++;
                 
                for (int r = 0; r < dataSource.Rows.Count; r++)
                {
                    int iRow = r + startRow;
                    for (int c = 0; c < dataSource.Columns.Count; c++)
                    {
                        IDKeyValModel colID = ETLConfig.Find(m => m.key == "ItemName" && m.val.Split('.')[0] == dataSource.Columns[c].ColumnName);
                        string id = colID?.id ?? "-1";
                        string Format = id != "-1" ? ETLConfig?.Find(m => m.id == id && m.key == "FormatType")?.val ?? "string" : "string";
                        var val = dataSource.Rows[r][dataSource.Columns[c]];
                        if (Format == "DateTime")
                        {
                            worksheet.Cells[iRow, c + 1].Style.Numberformat.Format = DateTimeFormatInfo.CurrentInfo.ShortDatePattern;
                            if (val != DBNull.Value)
                            {
                                worksheet.Cells[iRow, c + 1].Value = Convert.ToDateTime(val);
                            }
                        }
                        else
                        {
                            worksheet.Cells[iRow, c + 1].Value = val;
                        }
                    }
                }
                 

                worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

            }
        }
        public void ReDisplayTable(DataTable dataTable, List<FItem> litems)
        {
            try
            {
                if (litems == null || litems.Count() == 0)
                {
                    return;
                }
                if (dataTable != null)
                {
                    if (dataTable.Columns.Count > 0)
                    {
                        foreach (DataColumn col in dataTable.Columns)
                        {
                            FItem item = litems.Where(m => m.Key.Trim() == col.ColumnName).FirstOrDefault();
                            if (item != null)
                            {
                                col.ColumnName = item.Display;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ReDisplayTable", ex.Message, string.Join(",", litems));
            }
        }

    }
}