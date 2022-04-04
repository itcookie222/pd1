using BussinessObjects;
using GemBox.Spreadsheet;
using Helpers.Functions;
using iTextSharp.text.pdf;
using Newtonsoft.Json.Linq;
using QRCoder;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;

namespace Categories.Controllers
{
    public class CateAddUpdateController : CategoriesBaseController
    {
        // GET: AddUpdate
        [HttpGet]
        public ActionResult Index(string FormCode = "", long ID = 0, string ViewCode = "", long ViewID = 0, string ViewPermission = "", string ViewFormID = "", string ViewDataLink = "")
        {
            ViewBag.DomainID = SEmployee.DomainID;
            ViewBag.FormCode = FormCode;
            ViewBag.ViewID = ViewID; //
            ViewBag.ViewPermission = ViewPermission;//sử dụng để xem form khác, thường dùng trong workflow
            ViewBag.UserID = SEmployee.UserID;
            ViewBag.ViewFormID = ViewFormID;

            if (ViewID != 0) { ID = ViewID; }
            CategoriesItemModel model = GetFormModelCache(FormCode);
            if (SEmployee.LangCode == "VN")
            {
                model.LangCode = "VN";
            }
            else
            {
                model.LangCode = "EN";
            }

            if (ViewCode != "")
            {
                ViewBag.ViewCode = ViewCode;
                ID = FindIDFromCodeString(FormCode, ViewCode);
            }

            if (model != null)
            {
                model.ColVal = ID.ToString();
                model.SessionID = Guid.NewGuid().ToString();
                model.ViewDataLink = ViewDataLink;
            }
            if (!(model.PublicRequest == "1") && !IsAuthorization(model.ObjectID))
            {
                TempData["error"] = "ERRCATE-001: Đang kiểm tra phân quyền, vui lòng thử lại sau." + model.FormCode;
                DataFunction.WriteLog("CateAddUpdateController-Index", TempData["error"].ToString(), model.PublicRequest.ToString(), model.ObjectID);
                return View(model);
            }
            ViewBag.IsAdd = IsAuthorizationAction(model.ObjectID, "ADD");
            ViewBag.IsEdit = IsAuthorizationAction(model.ObjectID, "EDIT");
            ViewBag.IsDelete = IsAuthorizationAction(model.ObjectID, "DELETE");

            //if (model.PublicRequest == "1" && model.FixRequestID == "1" && ID!= 0 )
            //{
            //    //Không load dữ liệu trực tiếp từ Get mà lấy từ POST
            //    Session[model.SessionID] = ID;
            //    return View(model);
            //}
            if (ID != 0)
            {
                DataTable dataload = GetFormData(model);
                if (dataload != null)
                {
                    SetFormData(model, dataload);
                }
                if (model.FixRequestID == "1")
                {
                    //Session[model.SessionID] = ID;
                }
            }

            return View(model);

        }

        private long FindIDFromCodeString(string formCode, string ViewCode)
        {
            List<string> parms = new List<string>
            {
                "@SSID",
                "",
                "@DomainID",
                SEmployee.DomainID.ToString(),
                "@USERID",
                SEmployee.UserID.ToString(),
                "@FormCode",
                formCode,
                "@ViewCode",
                ViewCode
            };

            DataTable dt = DataFunction.GetDataReportFromService(ServiceUrl_Report, "", parms, formCode, "PSYS.FindIDByCode", SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
            long ret = 0;
            if (dt != null && dt.Rows.Count > 0 && dt.Rows[0][0] != null)
            {
                ret = Convert.ToInt32(dt.Rows[0][0]);
            }
            return ret;
        }

        public JsonResult GetDataByID(string FormCode, string SSID, long ID, string SID, string SourceType, string ViewCode = "")
        {
            if (Request.UrlReferrer == null)
            {
                TempData["error"] = "ERRCATE-002.01: Đang cập nhật phân quyền, vui lòng thử lại sau.";
                return Json("ERRCATE-002.01", JsonRequestBehavior.AllowGet);
            }

            CategoriesItemModel model = GetFormModelCache(FormCode);
            if (model != null)
            {
                model.ColVal = ID.ToString();
                model.SessionID = SSID;
                model.ViewCode = ViewCode;
            }
            if ((model.PublicRequest ?? "0") != "1" && !IsAuthorization(model.ObjectID))
            {
                TempData["error"] = "ERRCATE-002: Đang kiểm tra phân quyền, vui lòng thử lại sau.";
                return Json("ERRCATE-002", JsonRequestBehavior.AllowGet);
            }
            //if (model.FixRequestID == "1" && (Session[SSID] == null || (int)Session[SSID] != ID))
            //{
            //    TempData["error"] = "ERRCATE-002.1: Vượt quyền hạn truy cập!!!";
            //    DataFunction.WriteLog("GetDataByID", TempData["error"].ToString(), FormCode, "SSID: " + SSID + " ID:" + ID.ToString());
            //    return Json("RRCATE-002.1", JsonRequestBehavior.AllowGet);
            //}
            List<FItem> lstP = new List<FItem>();
            if (SourceType == "ModalForm")
            {
                lstP = model.ModalForm;
            }
            else
            {
                lstP = model.Form;
            }
            //List<string> para = MapSubmitParamsReport(lstP);
            DataTable dataload = GetFormData(model, SourceType);
            string jr = Newtonsoft.Json.JsonConvert.SerializeObject(ConvertDatatableToFormItems(lstP, dataload));
            return Json(jr, JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public JsonResult CateSave(string SourceType = "")
        {
            TempData["error"] = null;

            string FormCode = Request["FormCode"] != null ? Request["FormCode"] : "";
            string sessionId = Request["FSessionID"] != null ? Request["FSessionID"] : "";
            string id = Request["ID"] != null ? Request["ID"].ToString() : "";
            if (id == "")
            {
                id = Request["NodeID"] != null ? Request["NodeID"].ToString() : "";
            }
            if (FormCode == "")
            {
                TempData["error"] = "ERRCATE-003: Không tìm thấy file cấu hình danh mục. Vui lòng kiểm tra lại";
                return Json(TempData["error"], JsonRequestBehavior.AllowGet);
            }
            if (sessionId == "")
            {
                TempData["error"] = "ERRCATE-004: Không thể khởi tạo danh mục. Vui lòng kiểm tra lại";
                return Json(TempData["error"], JsonRequestBehavior.AllowGet);
            }
            if (SEmployee == null || SEmployee.DomainID == "" || SEmployee.DomainID == "0" || SEmployee.UserID == 0)
            {
                TempData["error"] = "ERRCATE-444: Session timeout, please login again!";
                return Json(TempData["error"], JsonRequestBehavior.AllowGet);
            }

            try
            {
                CategoriesItemModel model = GetFormModelCache(FormCode);
                if (model != null)
                {
                    model.ColVal = id;
                    model.SessionID = sessionId;

                    if (!IsAuthorizationAction(model.ObjectID) && !(model.PublicRequest == "1"))
                    {
                        TempData["error"] = "ERRCATE-005: Đang kiểm tra phân quyền, vui lòng thử lại sau! Form:" + model.FormCode + " Action:" + Request["Action"].ToUpper();
                        DataFunction.WriteLog("ERRCATE-005", Newtonsoft.Json.JsonConvert.SerializeObject(model), Request["Action"], IsAuthorizationAction(model.ObjectID).ToString());
                        return Json(TempData["error"], JsonRequestBehavior.AllowGet);
                    }

                    DataTable dtResponse = SaveFormData(model, sessionId, id);
                    if (dtResponse != null && dtResponse.Rows.Count > 0)
                    {
                        DataRow row = dtResponse.Rows[0];
                        if (row[0] != null && row[0].ToString().ToLower() == "done" && row[1] != null)
                        {
                            TempData["success"] = row[1].ToString();
                            return Json(TempData["success"].ToString(), JsonRequestBehavior.AllowGet);
                        }
                        else
                        {
                            string err = "ERRCATE-006: Cập nhật thất bại|" + row[1] != null ? row[1].ToString() : "";
                            TempData["error"] = err;
                            DataFunction.WriteLog("CateSave", err, "", "");
                            return Json(err, JsonRequestBehavior.AllowGet);
                        }
                    }
                    else
                    {
                        TempData["error"] = "ERRCATE-007: Cập nhật thất bại";
                        DataFunction.WriteLog("CateSave", TempData["error"].ToString(), "", "");
                        return Json(TempData["error"], JsonRequestBehavior.AllowGet);
                    }
                }
                else
                {
                    TempData["error"] = "ERRCATE-008: Không tìm thấy cấu hình danh mục trước đó";
                    DataFunction.WriteLog("CateSave", TempData["error"].ToString(), "", "");
                    return Json(TempData["error"], JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                TempData["error"] = ex.Message;
                DataFunction.WriteLog("CateSave", TempData["error"].ToString(), "", "");
                return Json(TempData["error"], JsonRequestBehavior.AllowGet);
            }
        }
        [HttpPost]

        private static string HtmlToPlainText(string html)
        {
            const string tagWhiteSpace = @"(>|$)(\W|\n|\r)+<";//matches one or more (white space or line breaks) between '>' and '<'
            const string stripFormatting = @"<[^>]*(>|$)";//match any character between '<' and '>', even when end tag is missing
            const string lineBreak = @"<(br|BR)\s{0,1}\/{0,1}>";//matches: <br>,<br/>,<br />,<BR>,<BR/>,<BR />
            Regex lineBreakRegex = new Regex(lineBreak, RegexOptions.Multiline);
            Regex stripFormattingRegex = new Regex(stripFormatting, RegexOptions.Multiline);
            Regex tagWhiteSpaceRegex = new Regex(tagWhiteSpace, RegexOptions.Multiline);

            string text = html;
            //Decode html specific characters
            text = System.Net.WebUtility.HtmlDecode(text);
            //Remove tag whitespace/line breaks
            text = tagWhiteSpaceRegex.Replace(text, "><");
            //Replace <br /> with line breaks
            text = lineBreakRegex.Replace(text, Environment.NewLine);
            //Strip formatting
            text = stripFormattingRegex.Replace(text, string.Empty);

            return text;
        }
        [HttpGet]
        public ActionResult ExportDataOTP(string FormCode = "", string Action = "601", long ID = 0, string ListPrint = "", string fileType = "pdf")
        {
            JsonResult jr = ExportDataForPrint(FormCode, Action, ID, ListPrint, "pdf", SEmployee.OTP);

            if (jr.Data != null)
                return Redirect(jr.Data.ToString());
            return View();
        }

        [HttpPost]
        public JsonResult ExportDataForPrint(string FormCode = "", string Action = "", long ID = 0, string ListPrint = "", string fileType = "pdf", string otp = "")
        {
            string exmess = "";
            if (string.IsNullOrWhiteSpace(Action)) Action = "601";

            try
            {
                ////Get Modal
                ViewBag.DomainID = SEmployee.DomainID;
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
                if ((model.PublicRequest ?? "0") != "1" && !IsAuthorization(model.ObjectID))
                {
                    exmess = "ERRPRT-001: Đang kiểm tra phân quyền, vui lòng thử lại sau." + model.FormCode;
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                DataTable dataload = new DataTable();
                //if (ID != 0)  //print tai sao can load cai nay
                //{
                //    dataload = GetFormData(model);
                //    if (dataload != null)
                //    {
                //        SetFormData(model, dataload);
                //    }
                //}

                if (model == null)
                {
                    exmess = "ERRPRT-002: Lỗi cấu hình In.";
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                if (!model.ETL.Exists(m => m.Key == Action)) Action = "601";

                if (model.ETL == null || model.ETL.Count == 0 || !model.ETL.Exists(m => m.Key == Action))
                {
                    exmess = "ERRPRT-003: Chưa cấu hình In:" + Action;
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                BussinessObjects.FItem configModel = model.ETL.Find(m => m.Key == Action);
                if (configModel == null || string.IsNullOrWhiteSpace(configModel.ETLConfig))
                {
                    exmess = "ERRPRT-003.1: Chưa cấu hình dữ liệu In:" + Action;
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }

                string pathIn = configModel.OptionConfig;
                string pathInFull = Server.MapPath(configModel.OptionConfig);

                string DataSource = configModel.DataSource;

                List<string> parms;
                if (configModel.DefaultValue != null && configModel.DefaultValue.ToLower().IndexOf("allparam") >= 0)
                {
                    parms = MapSubmitParamsReport(model.Form, "ExportData");
                }
                else
                {
                    parms = new List<string>
                    {
                        "@SSID",
                        "",
                        "@DomainID",
                        SEmployee.DomainID.ToString(),
                        "@USERID",
                        SEmployee.UserID.ToString(),
                        "@FormCode",
                        FormCode,
                        "@ID",
                        (!string.IsNullOrWhiteSpace(ListPrint) && ListPrint != "undefined" && ListPrint != "null" ? ListPrint: ID.ToString())
                    };
                }
                if (!string.IsNullOrWhiteSpace(otp))
                {
                    parms.Add("@OTP");
                    parms.Add(otp);
                }

                if (configModel.DefaultValue != null && configModel.DefaultValue.ToLower().IndexOf("excel") >= 0)
                {
                    fileType = "xlsx";
                }

                DataTable exportData = DataFunction.GetDataReportFromService(ServiceUrl_Report, "", parms, FormCode, DataSource, SEmployee.DomainID.ToString().ToString(), SEmployee.UserID.ToString());
                if (exportData == null)
                {
                    exmess = "ERRPRT-004: Lỗi dữ liệu.";
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                if (exportData.Rows == null || exportData.Rows.Count == 0)
                {
                    exmess = "ERRPRT-005: Không có dữ liệu trả về.";
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                ////
                string fileOne = PrintOneDocument(FormCode, fileType, pathInFull, configModel, exportData, otp);

                return Json(fileOne, JsonRequestBehavior.AllowGet);
                //ws.Cells[21, 0].Value = HtmlToPlainText((model.Form.Find(m => m.Key == "BudgetType") ?? item).Value.ToString());
                //ws.Cells[21, 0].Style.WrapText = true;
                //ws.Cells[21, 0].Row.AutoFit(true);
            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ExportDataForPrint", exmess + ex.ToString(), Action, ID.ToString());
                return Json(ex.ToString(), JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public JsonResult ExportDataForPrintMultiFiles(string FormCode, string Action, string ListPrint, string fileType = "pdf")
        {
            string exmess = "";
            if (string.IsNullOrWhiteSpace(Action)) Action = "601";
            try
            {
                ////Get Modal
                ViewBag.DomainID = SEmployee.DomainID;
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
                    //model.ColVal = ID.ToString();
                    model.SessionID = Guid.NewGuid().ToString();
                }
                if ((model.PublicRequest ?? "0") != "1" && !IsAuthorization(model.ObjectID))
                {
                    exmess = "ERRPRT-001: Đang kiểm tra phân quyền, vui lòng thử lại sau.";
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                //begin load list document
                string[] listID = ListPrint.Split(',');
                List<string> fileList = new List<string>();
                for (int i = 0; i < listID.Length; i++)
                {
                    long ID = Convert.ToInt64(string.IsNullOrWhiteSpace(listID[i]) ? "0" : listID[i]);
                    DataTable dataload = new DataTable();
                    if (ID != 0)
                    {
                        dataload = GetFormData(model);
                        if (dataload != null)
                        {
                            SetFormData(model, dataload);
                        }
                    }
                    else
                    {
                        continue;
                    }
                    if (model == null)
                    {
                        exmess = "ERRPRT-002: Lỗi cấu hình In.";
                        throw new System.ArgumentException(exmess, "ExportDataForPrint");
                    }
                    if (!model.ETL.Exists(m => m.Key == Action)) Action = "601";

                    if (model.ETL == null || model.ETL.Count == 0 || !model.ETL.Exists(m => m.Key == Action))
                    {
                        exmess = "ERRPRT-003: Chưa cấu hình In.";
                        throw new System.ArgumentException(exmess, "ExportDataForPrint");
                    }
                    BussinessObjects.FItem configModel = model.ETL.Find(m => m.Key == Action);
                    if (configModel == null || string.IsNullOrWhiteSpace(configModel.ETLConfig))
                    {
                        exmess = "ERRPRT-003.1: Chưa cấu dữ liệu In.";
                        throw new System.ArgumentException(exmess, "ExportDataForPrint");
                    }
                    string pathIn = configModel.OptionConfig;
                    string pathInFull = Server.MapPath(configModel.OptionConfig);
                    string DataSource = configModel.DataSource;
                    List<string> parms = new List<string>
                    {
                        "@SSID",
                        "",
                        "@DomainID",
                        SEmployee.DomainID.ToString(),
                        "@USERID",
                        SEmployee.UserID.ToString(),
                        "@FormCode",
                        FormCode,
                        "@ID",
                        ID.ToString()
                    };
                    DataTable exportData = DataFunction.GetDataReportFromService(ServiceUrl_Report, "", parms, FormCode, DataSource, SEmployee.DomainID.ToString(), SEmployee.UserID.ToString());
                    if (exportData == null)
                    {
                        exmess = "ERRPRT-003: Lỗi dữ liệu.";
                        throw new System.ArgumentException(exmess, "ExportDataForPrint");
                    }
                    if (exportData.Rows == null || exportData.Rows.Count == 0)
                    {
                        exmess = "ERRPRT-004: Không có dữ liệu trả về.";
                        throw new System.ArgumentException(exmess, "ExportDataForPrint");
                        //continue;
                    }
                    ////
                    string fileOne = PrintOneDocument(FormCode, fileType, pathInFull, configModel, exportData);
                    fileList.Add(fileOne);
                }
                string fileOut = MergePDF(FormCode, fileList);
                //end load list document
                return Json(fileOut, JsonRequestBehavior.AllowGet);

            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("ExportDataForPrint", exmess + ex.ToString(), Action, ListPrint);
                return Json(ex.ToString(), JsonRequestBehavior.AllowGet);
            }
        }
        string PrintOneDocument(string FormCode, string fileType, string pathInFull, BussinessObjects.FItem configModel, DataTable exportData, string otp = "")
        {
            string exmess = "";
            try
            {
                ////
                SpreadsheetInfo.SetLicense("FREE-LIMITED-KEY");
                ExcelFile ef = new ExcelFile();
                ef = ExcelFile.Load(pathInFull, LoadOptions.XlsxDefault);
                ExcelWorksheet ws = ef.Worksheets.FirstOrDefault();

                //string fileApproved = model.Form.Exists(m => m.Key == "ProcessStep" && m.Value.ToLower() == "end") ? Server.MapPath("/Content/Custom/approved-stamp.png") : Server.MapPath("/Content/Custom/reject-stamp.png");
                //if (!string.IsNullOrEmpty(fileApproved))
                //{
                //    ws.Pictures.Add(fileApproved, "K4", "L7").Position.Mode = PositioningMode.FreeFloating;
                //}
                List<BussinessObjects.IDKeyValModel> ETLConfig = configModel.ETLConfig != "" ? Newtonsoft.Json.JsonConvert.DeserializeObject<List<BussinessObjects.IDKeyValModel>>(configModel.ETLConfig) : new List<BussinessObjects.IDKeyValModel>();
                if (ETLConfig == null || ETLConfig.Count == 0)
                {
                    exmess = "ERRPRT-005: Không có dữ liệu trả về từ cấu hình in";
                    throw new System.ArgumentException(exmess, "ExportDataForPrint");
                }
                ////fill header first
                IDKeyValModel itemNUll = new IDKeyValModel
                {
                    val = ""
                };
                if (exportData.Rows.Count > 0)
                {
                    exmess = "P 1";
                    int rowAdd = 0;
                    foreach (DataColumn itemColumns in exportData.Columns)
                    {
                        exmess = "P 2";
                        IDKeyValModel colID = ETLConfig.Find(m => m.key == "ItemName" && m.val.Split('.')[0] == itemColumns.ColumnName);
                        if (colID != null)
                        {
                            exmess = "P 3";
                            string id = colID.id;
                            string Col = (ETLConfig.Find(m => m.id == id && m.key == "Col") ?? itemNUll).val;
                            string Row = (ETLConfig.Find(m => m.id == id && m.key == "Row") ?? itemNUll).val;
                            string ColP = (ETLConfig.Find(m => m.id == id && m.key == "ColP") ?? itemNUll).val;
                            string RowP = (ETLConfig.Find(m => m.id == id && m.key == "RowP") ?? itemNUll).val;


                            int iCol = Convert.ToInt16(Col);
                            int iRow = Convert.ToInt16(Row);
                            int iColP = Convert.ToInt16(string.IsNullOrWhiteSpace(ColP) ? "0" : ColP);
                            int iRowP = Convert.ToInt16(string.IsNullOrWhiteSpace(RowP) ? "0" : RowP);



                            string DataType = (ETLConfig.Find(m => m.id == id && m.key == "DataType") ?? itemNUll).val;
                            string ItemName = (ETLConfig.Find(m => m.id == id && m.key == "ItemName") ?? itemNUll).val;
                            ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = "";
                            if (DataType == "Header")
                            {
                                exmess = "P 4";
                                if (ItemName.IndexOf("Image") >= 0 || ItemName.IndexOf("Sign") >= 0)
                                {
                                    exmess = "P 4.1";
                                    ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = "";
                                    try
                                    {
                                        string imagePath = Server.MapPath(exportData.Rows[0].Field<object>(itemColumns.ColumnName).ToString());
                                        if (imagePath.ToLower().IndexOf("sign-tick.png") > 0)
                                        {
                                            ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = "digitally signed";
                                            ws.Pictures.Add(imagePath,
                                           new AnchorCell(ws.Columns[iCol - 1], ws.Rows[iRow - 1 + rowAdd], 2, 2, LengthUnit.Pixel),
                                           new AnchorCell(ws.Columns[iCol + iColP], ws.Rows[iRow + iRowP + rowAdd],
                                           2, 2, LengthUnit.Pixel)).Position.Mode = PositioningMode.FreeFloating;
                                        }
                                        else
                                        {

                                            ws.Pictures.Add(imagePath,
                                            new AnchorCell(ws.Columns[iCol - 1], ws.Rows[iRow - 1 + rowAdd], 2, 2, LengthUnit.Pixel),
                                            new AnchorCell(ws.Columns[iCol + iColP], ws.Rows[iRow + iRowP + rowAdd],
                                            2, 2, LengthUnit.Pixel)).Position.Mode = PositioningMode.MoveAndSize;
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        DataFunction.WriteLog("ExportDataForPrint P10", ex.Message);
                                    }

                                }
                                else if (ItemName.IndexOf("QRCode") >= 0 || ItemName.IndexOf("QRCode") >= 0)
                                {
                                    exmess = "P 4.1";
                                    ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = "";
                                    try
                                    {
                                        QRCodeGenerator qrGenerator = new QRCodeGenerator();
                                        QRCodeData qrCodeData = qrGenerator.CreateQrCode(exportData.Rows[0].Field<object>(itemColumns.ColumnName).ToString(), QRCodeGenerator.ECCLevel.Q);
                                        QRCode qrCode = new QRCode(qrCodeData);
                                        Bitmap qrCodeImage = qrCode.GetGraphic(20);

                                        MemoryStream memoryStream = new MemoryStream();
                                        qrCodeImage.Save(memoryStream, System.Drawing.Imaging.ImageFormat.Png);
                                        ws.Pictures.Add(memoryStream, ExcelPictureFormat.Png,
                                        new AnchorCell(ws.Columns[iCol - 1], ws.Rows[iRow - 1 + rowAdd], 2, 2, LengthUnit.Pixel),
                                        new AnchorCell(ws.Columns[iCol + iColP], ws.Rows[iRow + iRowP + rowAdd],
                                        2, 2, LengthUnit.Pixel)).Position.Mode = PositioningMode.Move;

                                        qrCodeImage.Dispose();
                                    }
                                    catch (Exception ex)
                                    {
                                        DataFunction.WriteLog("QRCode Print P10.1", ex.Message);
                                    }

                                }
                                else if (ItemName.IndexOf("VNDText") >= 0)
                                {
                                    exmess = "P 4.2";
                                    string amount = exportData.Rows[0].Field<object>(itemColumns.ColumnName).ToString();
                                    amount = StaticFunc.ConvertCurrencyToString(amount);
                                    ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = amount;
                                }
                                else
                                {
                                    exmess = "P 5 ";
                                    ws.Cells[iRow - 1 + rowAdd, iCol - 1].Value = exportData.Rows[0].Field<object>(itemColumns.ColumnName) != null ? exportData.Rows[0].Field<object>(itemColumns.ColumnName).ToString() : "";
                                }
                            }
                            else if (DataType == "List" && exportData.Rows[0].Field<object>(itemColumns.ColumnName) != null)
                            {
                                exmess = "P 6";
                                string jsonData = exportData.Rows[0].Field<object>(itemColumns.ColumnName).ToString();
                                foreach (JObject jObject in JArray.Parse(jsonData))
                                {
                                    exmess = "P 7";
                                    ExcelRow rowCopy = ws.Rows[iRow - 1 + rowAdd];
                                    ws.Rows.InsertCopy(iRow + rowAdd, rowCopy);
                                    foreach (JProperty p in jObject.Properties())
                                    {
                                        exmess = "P 8";
                                        IDKeyValModel itemList = ETLConfig.Find(m => m.key == "ItemName" && m.val == (itemColumns.ColumnName + "." + p.Name));
                                        if (itemList != null)
                                        {
                                            exmess = "P 9";
                                            string idList = itemList.id;
                                            string ColList = (ETLConfig.Find(m => m.id == idList && m.key == "Col") ?? itemNUll).val;
                                            string RowList = (ETLConfig.Find(m => m.id == idList && m.key == "Row") ?? itemNUll).val;
                                            int iColList = Convert.ToInt16(ColList);
                                            int iRowList = Convert.ToInt16(RowList);

                                            if (p.Name.IndexOf("SignTick") >= 0)
                                            {
                                                exmess = "P 10";
                                                string signPath = Server.MapPath(p.Value.ToString().Replace(",", ""));
                                                try
                                                {
                                                    ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Value = "";
                                                    ws.Pictures.Add(signPath, new AnchorCell(ws.Columns[iColList - 1], ws.Rows[iRowList - 1 + rowAdd], 2, 2, LengthUnit.Pixel), 16, 16, LengthUnit.Pixel).Position.Mode = PositioningMode.FreeFloating;
                                                }
                                                catch (Exception ex)
                                                {
                                                    DataFunction.WriteLog("ExportDataForPrint P10", signPath, ex.Message);
                                                }
                                            }
                                            else if (p.Name.IndexOf("Sign") >= 0)
                                            {
                                                exmess = "P 10";
                                                string signPath = Server.MapPath(p.Value.ToString().Replace(",", ""));
                                                try
                                                {
                                                    ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Value = "";
                                                    if (signPath.ToLower().IndexOf("sign-tick.png") > 0)
                                                    {
                                                        ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Value = "digitally signed";
                                                        ws.Pictures.Add(signPath,
                                                           new AnchorCell(ws.Columns[iColList - 1], ws.Rows[iRowList - 1 + rowAdd], 2, 2, LengthUnit.Pixel),
                                                           new AnchorCell(ws.Columns[iColList], ws.Rows[iRowList + rowAdd], 2, 2, LengthUnit.Pixel)).Position.Mode = PositioningMode.Move;
                                                        //ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Value = "Signed digitally by";
                                                    }
                                                    else
                                                    {
                                                        ws.Pictures.Add(signPath,
                                                        new AnchorCell(ws.Columns[iColList - 1], ws.Rows[iRowList - 1 + rowAdd], 2, 2, LengthUnit.Pixel),
                                                        new AnchorCell(ws.Columns[iColList], ws.Rows[iRowList + rowAdd], 2, 2, LengthUnit.Pixel)).Position.Mode = PositioningMode.FreeFloating;
                                                    }
                                                }
                                                catch (Exception ex)
                                                {
                                                    DataFunction.WriteLog("ExportDataForPrint P10", signPath, ex.Message);
                                                }
                                            }

                                            else
                                            {
                                                exmess = "P 11";
                                                var IsBold = jObject.Properties().FirstOrDefault(m => m.Name == "IsBold")?.Value?.ToString();
                                                var Color = jObject.Properties().FirstOrDefault(m => m.Name == "Color")?.Value?.ToString();

                                                ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Value = p.Value.ToString();
                                                if (IsBold != null && IsBold.ToString() == "True") ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Weight = ExcelFont.BoldWeight;

                                                if (Color != null && Color.ToString().Length > 0)
                                                {
                                                    switch (Color.ToString())
                                                    {
                                                        case "Red":
                                                            ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Color = SpreadsheetColor.FromName(ColorName.Red);
                                                            break;
                                                        case "Green":
                                                            ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Color = SpreadsheetColor.FromName(ColorName.Green);
                                                            break;
                                                        case "Blue":
                                                            ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Color = SpreadsheetColor.FromName(ColorName.Blue);
                                                            break;
                                                        case "Yellow":
                                                            ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Color = SpreadsheetColor.FromName(ColorName.Yellow);
                                                            break;
                                                        default:
                                                            ws.Cells[iRowList - 1 + rowAdd, iColList - 1].Style.Font.Color = SpreadsheetColor.FromName(ColorName.Black);
                                                            break;
                                                    }
                                                }

                                            }
                                        }
                                    }
                                    rowAdd += 1;
                                }
                                exmess = "P 12";
                                ws.Rows[iRow - 1 + rowAdd].Hidden = true;
                            }

                        }

                    }
                }
                exmess = "P 13";
                string fileName = GenerateExportFileName(FormCode, fileType);
                string pathOutFull = Server.MapPath(fileName);
                string pin = exportData.Rows[0] != null && exportData.Columns.Contains("OTP") ? exportData.Rows[0]["OTP"].ToString() : otp;

                if (!string.IsNullOrWhiteSpace(pin))
                {
                    var saveoptions = new PdfSaveOptions()
                    {
                        DocumentOpenPassword = pin,
                        PermissionsPassword = Helpers.Functions.ConfigFunctions.GetConfigByDomain("pdfmasterkey"),
                        Permissions = PdfPermissions.None
                    };
                    ef.Save(pathOutFull, saveoptions);
                }
                else
                {
                    ef.Save(pathOutFull);
                }
                exmess = "P 14";
                return fileName;

            }
            catch (Exception ex)
            {
                DataFunction.WriteLog("PrintOneDoucment", exmess + ex.ToString());
                return "";
            }

        }

        protected string GenerateExportFileName(string formCode = "", string fileType = "pdf")
        {
            string folder = "/Files/Exports/" + SEmployee.DomainCode + "/" + formCode + "/";
            if (!System.IO.Directory.Exists(Server.MapPath(folder)))
            {
                System.IO.Directory.CreateDirectory(Server.MapPath(folder));
            }

            string fileName = folder + DateTime.Now.ToString("yyMMddhhmmss") + "-" + new Random().Next(1000, 9999).ToString() + "-" + SEmployee.UserID.ToString() + "." + fileType;
            return fileName;
        }

        private string MergePDF(string FormCode, List<string> filesList)
        {
            string fileout = GenerateExportFileName(FormCode, "pdf");
            string outputPdfPath = Server.MapPath(fileout);

            PdfReader reader = null;
            iTextSharp.text.Document sourceDocument = null;
            PdfCopy pdfCopyProvider = null;
            PdfImportedPage importedPage;

            sourceDocument = new iTextSharp.text.Document();
            pdfCopyProvider = new PdfCopy(sourceDocument, new System.IO.FileStream(outputPdfPath, System.IO.FileMode.Create));

            //output file Open  
            sourceDocument.Open();

            //files list wise Loop  
            foreach (string filename in filesList)
            {
                string file = Server.MapPath(filename);

                int pages = TotalPageCountPdf(file);

                reader = new PdfReader(file);
                //Add pages in new file  
                for (int i = 1; i <= pages; i++)
                {
                    importedPage = pdfCopyProvider.GetImportedPage(reader, i);
                    pdfCopyProvider.AddPage(importedPage);
                }

                reader.Close();
            }
            //save the output file  
            sourceDocument.Close();

            return fileout;
        }

        private static int TotalPageCountPdf(string file)
        {
            using (StreamReader sr = new StreamReader(System.IO.File.OpenRead(file)))
            {
                Regex regex = new Regex(@"/Type\s*/Page[^s]");
                MatchCollection matches = regex.Matches(sr.ReadToEnd());

                return matches.Count;
            }
        }


    }
}