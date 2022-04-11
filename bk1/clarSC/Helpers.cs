using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.IO;
using Scb.Framework;
using System.Data.OleDb;
using System.Globalization;
using System.Data.SqlTypes;
using System.Configuration;
using System.Net.Mail;
using Microsoft.Practices.EnterpriseLibrary.Data;
using Microsoft.Practices.EnterpriseLibrary.Common.Configuration;
using System.Data.SqlClient;
using System.Xml;
using Entities;
using System.ServiceProcess;
using Business;
using System.Net;
using System.Web;
using System.Net.Cache;
using Aspose.Cells;
using System.Drawing;

namespace SCB.PMTGWT.Utils
{
  #region File
  public class FileHelpers
  {
    public static bool CreateDir(string foldername)
    {
      DirectoryInfo info = null;
      if (!Directory.Exists(foldername))
      {
        try
        {
          info = Directory.CreateDirectory(foldername);
          if (info.Exists)
            return true;
        }
        catch (Exception ex)
        {
          Logger.Error("Utilities.FileHelpers::CreateDir", ex);
          throw;
        }
      }
      else
      {
        return true;
      }
      return false;
    }

    public static string CreateDestFolderByDate(DateTime dt, string destname)
    {
      if (!CreateDir(destname))
        return string.Empty;

      destname = Path.Combine(destname, dt.Year.ToString());
      if (!CreateDir(destname))
        return string.Empty;

      destname = Path.Combine(destname, dt.Month.ToString());
      if (!CreateDir(destname))
        return string.Empty;

      destname = Path.Combine(destname, dt.Day.ToString());
      if (!CreateDir(destname))
        return string.Empty;

      return destname;
    }

    public static string ArchiveFile(string folderName, string filename, bool isDelete)
    {
      try
      {
        folderName = CreateDestFolderByDate(DateTime.Now, folderName);
        if (!string.IsNullOrEmpty(folderName))
        {
          string f = Path.Combine(folderName, Path.GetFileName(filename));
          if (File.Exists(f))
            f += "_" + DateTime.Now.Ticks.ToString();

          File.Copy(filename, f);

          if (isDelete)
            File.Delete(filename);

          return f;
        }
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.FileHelpers::ArchiveFile", ex);
        throw;
      }

      return null;
    }

    public static DataTable GetDataFromXLS(string path, string sheet, bool isHeader)
    {
      try
      {
        string strConnectionString = string.Empty;

        if (isHeader)
          strConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;" +
          "Data Source=" + path + ";" +
          "Extended Properties=" + (char)34 + "Excel 8.0;HDR=Yes;IMEX=1;" + (char)34;
        else
          strConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;" +
        "Data Source=" + path + ";" +
        "Extended Properties=" + (char)34 + "Excel 8.0;HDR=No;IMEX=1;" + (char)34;

        OleDbConnection cnCSV = new OleDbConnection(strConnectionString);
        cnCSV.Open();
        OleDbCommand cmdSelect = new OleDbCommand(@"SELECT * FROM [" + sheet + "]", cnCSV);
        OleDbDataAdapter daCSV = new OleDbDataAdapter();
        daCSV.SelectCommand = cmdSelect;
        DataTable dtCSV = new DataTable();
        daCSV.Fill(dtCSV);
        cnCSV.Close();
        daCSV = null;
        return dtCSV;
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.FileHelpers::GetDataFromXLS", ex);
        throw;
      }
    }

    public static bool GetFileByPattern(string directory, string pattern, out string absolutePath)
    {
      try
      {
        if (Directory.Exists(directory))
        {
          string patternName = Path.GetFileNameWithoutExtension(pattern);
          string ext = Path.GetExtension(pattern);
          string[] foundList = Directory.GetFiles(directory, string.Format("{0}*", patternName), SearchOption.TopDirectoryOnly);
          if (foundList.Length > 0 && Path.GetExtension(foundList[0]) == ext)
          {
            absolutePath = foundList[0];
            return true;
          }
        }

        absolutePath = null;
        return false;
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.FileHelpers::GetFileByPattern", ex);
        throw;
      }
    }
  }
  #endregion

  #region Data
  public enum SqlDateTimeStatus
  {
    VALID,
    OVERFLOWING,
    INVALID
  }

  public static class DataHelpers
  {
    private static List<string> m_dateTimeFormats;
    public static List<string> DateTimeFormats
    {
      get
      {
        if (m_dateTimeFormats == null || m_dateTimeFormats.Count < 0)
        {
          m_dateTimeFormats = new List<string>(new string[] { "d-MMM", "M/d/yyyy", "yyyyMMdd", "MM/dd/yyyy", "MM-dd-yyyy", "d-MMM-yy", "dd/MM/yyyy", "dd-MMM-yy", "dd MMM yy", "dd/MMM/yy", "dd-MM-yyyy", "d-MMM-yyyy", "M/dd/yyyy hh:mm:ss tt", "000000" });
        }

        return m_dateTimeFormats;
      }

      set
      {
        m_dateTimeFormats = value;
      }
    }


    private static List<string> m_ignoredDateTimes;
    public static List<string> IgnoredDateTimes
    {
      get
      {
        if (m_ignoredDateTimes == null || m_ignoredDateTimes.Count < 0)
        {
          m_ignoredDateTimes = new List<string>(new string[] { "00/00/0000" });
        }

        return m_ignoredDateTimes;
      }

      set
      {
        m_ignoredDateTimes = value;
      }
    }

    public static SqlDateTimeStatus TryParseSQLDateTime(string text, List<string> ignoredText, List<string> formats, out DateTime? dateTime)
    {
      try
      {
        dateTime = null;
        if (!string.IsNullOrEmpty(text.Trim()) && !ignoredText.Contains(text.Trim()))
        {
          DateTime result;
          if (DateTime.TryParseExact(text.Trim(), formats.ToArray(), null, DateTimeStyles.None, out result))
          {
            if (result >= (DateTime)SqlDateTime.MinValue && result <= (DateTime)SqlDateTime.MaxValue)
            {
              dateTime = result;
              return SqlDateTimeStatus.VALID;
            }

            return SqlDateTimeStatus.OVERFLOWING;
          }

          return SqlDateTimeStatus.INVALID;
        }

        return SqlDateTimeStatus.VALID;
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.DataHelpers::TryParseSQLDateTime", ex);
        throw;
      }
    }

    public static bool TryPaseDecimal(string text, List<string> ignoredText, out decimal? dec)
    {
      try
      {
        dec = null;
        if (!string.IsNullOrEmpty(text.Trim()) && !ignoredText.Contains(text.Trim()))
        {
          decimal result;
          if (decimal.TryParse(text.Trim(), NumberStyles.Any, null, out result))
          {
            dec = result;
            return true;
          }

          return false;
        }

        return true;
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.DataHelpers::TryPaseDecimal", ex);
        throw;
      }
    }

    public static bool TryPaseInt(string text, List<string> ignoredText, out int? interger)
    {
      try
      {
        interger = null;
        if (!string.IsNullOrEmpty(text.Trim()) && !ignoredText.Contains(text.Trim()))
        {
          int result;
          if (int.TryParse(text.Trim(), NumberStyles.Any, null, out result))
          {
            interger = result;
            return true;
          }

          return false;
        }

        return true;
      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.DataHelpers::TryPaseInt", ex);
        throw;
      }
    }

    public static Workbook ImportWorkBook(Workbook wb, DataSet ds)
    {
      Worksheet sheet = wb.Worksheets[0];

      DataTable table = ds.Tables[0];
      sheet.Cells.ImportDataTable(table, true, "A1");
      sheet.AutoFitColumns();

      Workbook b = new Workbook();

      SetBackgroundColorForRow(b, sheet, 0);

      b.Worksheets[0].Copy(sheet);
      b.Worksheets[0].Name = sheet.Name;

      return b;
    }

    public static void SetBackgroundColorForRow(Workbook wb, Worksheet sheet, int idxRow)
    {
      Aspose.Cells.Style style = wb.Styles[1];

      style.BackgroundColor = Color.Gray;
      style.Font.Color = Color.White;
      style.Font.IsBold = true;
      style.Pattern = BackgroundType.Gray6;

      StyleFlag styleFlag = new StyleFlag();
      styleFlag.All = true;

      Row row = sheet.Cells.Rows[idxRow];
      row.ApplyStyle(style, styleFlag);
    }
  }
  #endregion

  #region Common
  public class CommonHelpers
  {
    public static void NotifyEmail(string receiptListName, string section, string message)
    {
      SmtpClient smtpClient;
      MailMessage mailMsg = new MailMessage();

      try
      {
        string[] toEmails = ConfigurationManager.AppSettings["NotifyEmail"].Split(';');

        if (toEmails.Length <= 0 || ConfigurationManager.AppSettings["NotifyEmail"] == null
          || ConfigurationManager.AppSettings["NotifyEmail"].ToString() == "")
        {
          PMT_CONFIG config = PMT_CONFIGService.GetByName(receiptListName,
            EnumList.ConfigurationType.PRD.ToString());

          if (config == null)
            return;

          if (!string.IsNullOrEmpty(config.ConfigValue))
          {
            toEmails = config.ConfigValue.Split(';');
          }
          else
          {
            if (!string.IsNullOrEmpty(config.ConfigBKValue))
            {
              toEmails = config.ConfigBKValue.Split(';');
            }

            return;
          }
        }

        // To
        foreach (string s in toEmails)
        {
          if (s != "")
            mailMsg.To.Add(s.Trim());
        }

        if (mailMsg.To.Count > 0)
        {

          // From
          MailAddress mailAddress = new MailAddress("PMTGWT@sc.com");
          mailMsg.From = mailAddress;

          // Subject and Body
          mailMsg.Subject = string.Format("PMTGWT Notification - {0}", section);
          mailMsg.Body = message;

          smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServer"]);

          smtpClient.UseDefaultCredentials = true;
          smtpClient.Send(mailMsg);
        }

      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.CommonHelpers::NotifyEmail", ex);

        try
        {
          if (mailMsg.To.Count > 0)
          {
            smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServerBK"]);
            smtpClient.Send(mailMsg);
          }
        }
        catch (Exception ext)
        {

          Logger.Error("Utilities.CommonHelpers::NotifyEmail", ext);
        }
      }
    }

    public static void NotifyEmailWithAttach(string receiptListName, string section, string message, string[] attachFiles)
    {
      SmtpClient smtpClient;
      MailMessage mailMsg = new MailMessage();

      try
      {
        string[] toEmails = null;

        PMT_CONFIG config = PMT_CONFIGService.GetByName(receiptListName,
          EnumList.ConfigurationType.PRD.ToString());

        if (config == null)
        {
          toEmails = ConfigurationManager.AppSettings["NotifyEmail"].Split(';');
        }

        if (!string.IsNullOrEmpty(config.ConfigValue))
        {
          toEmails = config.ConfigValue.Split(';');
        }
        else
        {
          if (!string.IsNullOrEmpty(config.ConfigBKValue))
          {
            toEmails = config.ConfigBKValue.Split(';');
          }

          return;
        }

        if (toEmails == null || toEmails.Length == 0)
          return;

        // To
        foreach (string s in toEmails)
        {
          if (s != "")
            mailMsg.To.Add(s.Trim());
        }

        if (mailMsg.To.Count > 0)
        {

          // From
          MailAddress mailAddress = new MailAddress("PMTGWT@sc.com");
          mailMsg.From = mailAddress;

          // Subject and Body
          mailMsg.Subject = string.Format("PMTGWT Notification - {0}", section);
          mailMsg.Body = message;

          foreach (string file in attachFiles)
          {
            if (File.Exists(file.Trim()))
              mailMsg.Attachments.Add(new Attachment(file.Trim()));
          }

          smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServer"]);

          smtpClient.UseDefaultCredentials = true;
          smtpClient.Send(mailMsg);
        }

      }
      catch (Exception ex)
      {
        Logger.Error("Utilities.CommonHelpers::NotifyEmail", ex);

        try
        {
          if (mailMsg.To.Count > 0)
          {
            smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServerBK"]);
            smtpClient.Send(mailMsg);
          }
        }
        catch (Exception ext)
        {

          Logger.Error("Utilities.CommonHelpers::NotifyEmail", ext);
        }
      }
    }

    public static void BulkCopyToImport(DataTable dt, object[] mappings, string tableName)
    {
      try
      {
        DatabaseConfigurationView view = new DatabaseConfigurationView(new SystemConfigurationSource());
        ConnectionStringSettings settings = view.GetConnectionStringSettings(view.DefaultName);

        using (SqlConnection destinationConnection = new SqlConnection(settings.ConnectionString))
        {
          // open the connection
          destinationConnection.Open();
          using (SqlBulkCopy bulkCopy =
                      new SqlBulkCopy(settings.ConnectionString))
          {
            bulkCopy.BulkCopyTimeout = 3600000;
            bulkCopy.BatchSize = 500;

            // column mappings
            if (mappings != null)
            {
              for (int i = 0; i < mappings.Length; i++)
              {
                SqlBulkCopyColumnMapping mapping = (SqlBulkCopyColumnMapping)mappings[i];
                bulkCopy.ColumnMappings.Add(mapping);
              }
            }

            bulkCopy.DestinationTableName = tableName;
            bulkCopy.WriteToServer(dt);
          }
        }
      }
      catch (Exception ex)
      {
        Logger.Error(string.Format("Utilities.CommonHelpers::BulkCopyToImport{0}", tableName), ex);
        throw;
      }
    }

    public static string FindValueByKey(IDictionary<string, string> dictionary, string key)
    {
      if (dictionary == null)
        return null;

      foreach (KeyValuePair<string, string> pair in dictionary)
        if (key.Equals(pair.Key)) return pair.Value;

      return null;
    }

    public static void SaveActionLog(string paymentID, string messageID,
      string action, string actionBy)
    {
      string logAction = ConfigurationManager.AppSettings["LogAction"];
      if (logAction == "1")
      {
        PMT_ACTION p = new PMT_ACTION();
        p.PMT_ID = paymentID;
        p.MSG_ID = messageID;
        p.Action = action;
        p.ActionBy = actionBy;
        p.ActionDate = DateTime.Now;

        PMT_ACTIONService.CreatePMT_ACTION(p);
      }
    }
  }
  #endregion

  #region Date
  public class DateUtil
  {
    /// <summary>
    /// return the previous business date of the date specified.
    /// </summary>
    /// <param name="today"></param>
    /// <returns></returns>
    public static DateTime PreviousBusinessDay(DateTime today)
    {
      DateTime result;
      switch (today.DayOfWeek)
      {
        case DayOfWeek.Sunday:
          result = today.AddDays(-2);
          break;

        case DayOfWeek.Monday:
          result = today.AddDays(-3);
          break;

        case DayOfWeek.Tuesday:
        case DayOfWeek.Wednesday:
        case DayOfWeek.Thursday:
        case DayOfWeek.Friday:
          result = today.AddDays(-1);
          break;

        case DayOfWeek.Saturday:
          result = today.AddDays(-1);
          break;

        default:
          throw new ArgumentOutOfRangeException("DayOfWeek=" + today.DayOfWeek);
      }
      return ScreenHolidays(result, -1);
    }
    /// <summary>
    /// Return the previous or next business day of the date specified.
    /// </summary>
    /// <param name="today"></param>
    /// <param name="addValue"></param>
    /// <returns></returns>
    public static DateTime GetBusinessDay(DateTime today, int addValue)
    {
      #region Sanity Checks
      if ((addValue != -1) && (addValue != 1))
        throw new ArgumentOutOfRangeException("addValue must be -1 or 1");
      #endregion

      if (addValue > 0)
        return NextBusinessDay(today);
      else
        return DateUtil.PreviousBusinessDay(today);
    }



    /// <summary>
    /// return the next business date of the date specified.
    /// </summary>
    /// <param name="today"></param>
    /// <returns></returns>
    public static DateTime NextBusinessDay(DateTime today)
    {
      DateTime result;
      switch (today.DayOfWeek)
      {
        case DayOfWeek.Sunday:
        case DayOfWeek.Monday:
        case DayOfWeek.Tuesday:
        case DayOfWeek.Wednesday:
        case DayOfWeek.Thursday:
          result = today.AddDays(1);
          break;

        case DayOfWeek.Friday:
          result = today.AddDays(3);
          break;

        case DayOfWeek.Saturday:
          result = today.AddDays(2);
          break;

        default:
          throw new ArgumentOutOfRangeException("DayOfWeek=" + today.DayOfWeek);
      }
      return ScreenHolidays(result, 1);
    }


    /// <summary>
    /// return the mm/dd string of the date specified.
    /// </summary>
    /// <param name="time"></param>
    /// <returns></returns>
    public static string MonthDay(DateTime time)
    {
      return String.Format("{0:00}/{1:00}", time.Month, time.Day);
    }

    /// <summary>
    /// screen for holidays 
    /// (simple mode)
    /// </summary>
    /// <param name="result"></param>
    /// <param name="addValue"></param>
    /// <returns></returns>
    public static DateTime ScreenHolidays(DateTime result, int addValue)
    {
      #region Sanity Checks
      if ((addValue != -1) && (addValue != 1))
        throw new ArgumentOutOfRangeException("addValue must be -1 or 1");
      #endregion

      // holidays on fixed date
      switch (MonthDay(result))
      {
        case "01/01":  // Happy New Year
        case "04/30":  // Independent Day
        case "09/02":  // Independent Day
        case "12/25":  // Christmas
          return GetBusinessDay(result, addValue);
        default:
          return result;
      }
    }
  }
  #endregion

  #region XMLUtil
  public class XMLUtil
  {
    #region XML
    public string GetValue(XmlDocument source, string xpath)
    {
      StringBuilder sb = new StringBuilder();
      XmlNodeList nodeList = source.SelectNodes(xpath);
      if (nodeList.Count == 0)
      {
        return "";
      }

      foreach (XmlNode n in nodeList)
      {
        sb.Append(n.InnerText + " ");
      }

      return sb.ToString().Trim();
    }

    public string GetValueByNamespace(XmlDocument source, string methodName)
    {
      XmlNamespaceManager namespMan = new XmlNamespaceManager(new NameTable());
      namespMan.AddNamespace("foo", "http://tempuri.org/");
      XmlNodeList webMethodResult = source.SelectNodes("//foo:" + methodName, namespMan);
      if (webMethodResult[0].NodeType == XmlNodeType.Element)
      {
        return webMethodResult[0].InnerXml.ToString();
      }
      return null;
    }

    public void SetValue(XmlDocument source, string xpath, string value)
    {
      StringBuilder sb = new StringBuilder();
      XmlNodeList nodeList = source.SelectNodes(xpath);
      if (nodeList.Count == 0)
      {
        return;
      }

      foreach (XmlNode n in nodeList)
      {
        n.InnerText = value;
      }
    }

    public XmlNode MakeXPath(XmlDocument doc, string xpath, bool isMulti)
    {
      string[] partsOfXPath = xpath.Split('/');
      XmlNode node = null;
      for (int xpathPos = partsOfXPath.Length; xpathPos > 0; xpathPos--)
      {
        string subXpath = string.Join("/", partsOfXPath, 0, xpathPos);
        node = doc.SelectSingleNode(subXpath);

        if (node != null)
        {
          // append new descendants
          if (!isMulti)
          {
            for (int newXpathPos = xpathPos; newXpathPos < partsOfXPath.Length; newXpathPos++)
            {
              node = node.AppendChild(doc.CreateElement(partsOfXPath[newXpathPos]));
            }
            break;
          }
          else
          {
            node = node.ParentNode.AppendChild(doc.CreateElement(partsOfXPath[xpathPos - 1]));
            break;
          }
        }
      }

      return node;
    }

    public string GetString(string value, int length)
    {
      if (value == null)
        return "";

      if (value.Length == 0)
        return "";

      return value.Length > length ? value.Substring(0, length) : value;
    }

    public string GetString(string input, int from, int to)
    {
      int length = to - from;

      if (input == null)
        return "";

      if (length <= 0 || input.Length < from)
        return "";

      if (input.Length - from >= length)
        return input.Substring(from, length);

      return input.Substring(from, input.Length - from);
    }
    #endregion
  }
  #endregion

  #region GlobalCache
  public class GlobalCacheUtil
  {
    public static CITAD_BRANCH GetBranchCode(string r_ci_code)
    {
      try
      {
        CITAD_BRANCH branch = GlobalCache.CitadBranches.Find(delegate(CITAD_BRANCH temp) { return temp.R_CI_CODE == r_ci_code; });
        return branch;
      }
      catch (Exception ex)
      {
        Logger.Error("SCB.PMTGWT.Utils.GlobalCacheUtil::GetBranchCode", ex);
        return null;
      }
    }

    public static CITAD_BRANCH GetOCICODE(string branchCode)
    {
      try
      {
        CITAD_BRANCH branch = GlobalCache.CitadBranches.Find(delegate(CITAD_BRANCH temp) { return temp.BRANCH_CODE == branchCode; });
        return branch;
      }
      catch (Exception ex)
      {
        Logger.Error("SCB.PMTGWT.Utils.GlobalCacheUtil::GetOCICODE", ex);
        return null;
      }
    }


    public static CHECK_CODE_MAPPING GetCheckCode(string checkCode)
    {
      try
      {
        CHECK_CODE_MAPPING checkCodeMapping = GlobalCache.CheckCodeCol.Find(delegate(CHECK_CODE_MAPPING temp) { return temp.CHECK_CODE == checkCode; });
        return checkCodeMapping;
      }
      catch (Exception ex)
      {
        Logger.Error("SCB.PMTGWT.Utils.GlobalCacheUtil::GetCheckCode", ex);
        return null;
      }
    }
  }
  #endregion

  #region Converter
  public class Converter
  {
    private static char[] tcvnchars = {
        'µ', '¸', '¶', '·', '¹', 
        '¨', '»', '¾', '¼', '½', 'Æ', 
        '©', 'Ç', 'Ê', 'È', 'É', 'Ë', 
        '®', 'Ì', 'Ð', 'Î', 'Ï', 'Ñ', 
        'ª', 'Ò', 'Õ', 'Ó', 'Ô', 'Ö', 
        '×', 'Ý', 'Ø', 'Ü', 'Þ', 
        'ß', 'ã', 'á', 'â', 'ä', 
        '«', 'å', 'è', 'æ', 'ç', 'é', 
        '¬', 'ê', 'í', 'ë', 'ì', 'î', 
        'ï', 'ó', 'ñ', 'ò', 'ô', 
        '­', 'õ', 'ø', 'ö', '÷', 'ù', 
        'ú', 'ý', 'û', 'ü', 'þ', 
        '¡', '¢', '§', '£', '¤', '¥', '¦'
    };

    private static char[] unichars = {
        'à', 'á', 'ả', 'ã', 'ạ', 
        'ă', 'ằ', 'ắ', 'ẳ', 'ẵ', 'ặ', 
        'â', 'ầ', 'ấ', 'ẩ', 'ẫ', 'ậ', 
        'đ', 'è', 'é', 'ẻ', 'ẽ', 'ẹ', 
        'ê', 'ề', 'ế', 'ể', 'ễ', 'ệ', 
        'ì', 'í', 'ỉ', 'ĩ', 'ị', 
        'ò', 'ó', 'ỏ', 'õ', 'ọ', 
        'ô', 'ồ', 'ố', 'ổ', 'ỗ', 'ộ', 
        'ơ', 'ờ', 'ớ', 'ở', 'ỡ', 'ợ', 
        'ù', 'ú', 'ủ', 'ũ', 'ụ', 
        'ư', 'ừ', 'ứ', 'ử', 'ữ', 'ự', 
        'ỳ', 'ý', 'ỷ', 'ỹ', 'ỵ', 
        'Ă', 'Â', 'Đ', 'Ê', 'Ô', 'Ơ', 'Ư'
    };

    private static char[] convertTable;

    static Converter()
    {
      convertTable = new char[256];
      for (int i = 0; i < 256; i++)
        convertTable[i] = (char)i;
      for (int i = 0; i < tcvnchars.Length; i++)
        convertTable[tcvnchars[i]] = unichars[i];
    }

    public static string TCVN3ToUnicode(string value)
    {
      char[] chars = value.ToCharArray();
      for (int i = 0; i < chars.Length; i++)
        if (chars[i] < (char)256)
          chars[i] = convertTable[chars[i]];
      return new string(chars);
    }

    public static string ConvertVietNameLang(string value)
    {
      if (!string.IsNullOrEmpty(value))
      {
        try
        {
          //ConvertDB.ConvertFont convertFont = new ConvertDB.ConvertFont();
          //convertFont.Convert(ref value, ConvertDB.FontIndex.iNotKnown, ConvertDB.FontIndex.iNOSIGN);
          //value = Converter.TCVN3ToUnicode(value);
          //replace trunk characters
          value = ReplaceSpecialCharacters(value);

          if (value == "")
            value = ".";

          return value;
        }
        catch (Exception ex)
        {
          Logger.Error("SCB.PMTGWT.GWT.OUT.Common::ConvertVietNameLang", ex);
          return ".";
        }
      }
      else
      {
        return ".";
      }
    }

    public static string RemoveSpecialCharacters(string str)
    {
      StringBuilder sb = new StringBuilder();
      foreach (char c in str)
      {
        if ((c >= '0' && c <= '9')
          || (c >= 'A' && c <= 'Z')
          || (c >= 'a' && c <= 'z')
          || c == '.' || c == '_'
          || c == '[' || c == ']'
          || c == '/' || c == '\\'
          || c == ' ' || c == '%')
        {
          sb.Append(c);
        }
      }
      return sb.ToString();
    }

    public static string ReplaceSpecialCharacters(string str)
    {
      if (!string.IsNullOrEmpty(str))
        return str.Replace("", "").Replace("'", "");

      return "";
    }

    public static string ConvertToUnsign(string inputString)
    {
      if (string.IsNullOrEmpty(inputString))
        return null;

      string stFormD = inputString.Normalize(NormalizationForm.FormD);
      StringBuilder sb = new StringBuilder();
      for (int ich = 0; ich < stFormD.Length; ich++)
      {
        System.Globalization.UnicodeCategory uc = System.Globalization.CharUnicodeInfo.GetUnicodeCategory(stFormD[ich]);
        if (uc != System.Globalization.UnicodeCategory.NonSpacingMark)
        {
          sb.Append(stFormD[ich]);
        }
      }
      return (sb.ToString().Normalize(NormalizationForm.FormD));
    }

    public static string RemoveSignCharacter(string value)
    {
      if (!string.IsNullOrEmpty(value))
      {
        try
        {
          ConvertDB.ConvertFont convertFont = new ConvertDB.ConvertFont();
          convertFont.Convert(ref value, ConvertDB.FontIndex.iNotKnown, ConvertDB.FontIndex.iNOSIGN);
          value = Converter.ConvertToUnsign(value);

          if (value == "")
            value = ".";

          return value;
        }
        catch (Exception ex)
        {
          Logger.Error("SCB.PMTGWT.GWT.OUT.Common::RemoveSignCharacter", ex);
          return ".";
        }
      }
      else
      {
        return ".";
      }
    }


  }


  #endregion

  #region Chilkat
  public static class SecureCom
  {
    public static string Base64Encode(string inputString, ref string outString)
    {
      Chilkat.Crypt2 crypt = new Chilkat.Crypt2();

      //  Any string argument automatically begins the 30-day trial.
      bool success;
      success = crypt.UnlockComponent(ConfigurationManager.AppSettings["CYPT"]);
      if (success != true)
      {
        return crypt.LastErrorText;
      }

      //  Indicate that no encryption should be performed,
      //  only encoding/decoding.
      crypt.CryptAlgorithm = "none";
      crypt.EncodingMode = "base64";

      //  Other possible EncodingMode settings are:
      //  "quoted-printable", "hex", "uu", "base32", and "url"
      outString = crypt.EncryptStringENC(inputString);

      return "";
    }

    public static string Base64Decode(string inputString, ref string outString)
    {
      Chilkat.Crypt2 crypt = new Chilkat.Crypt2();

      //  Any string argument automatically begins the 30-day trial.
      bool success;
      success = crypt.UnlockComponent(ConfigurationManager.AppSettings["CYPT"]);
      if (success != true)
      {
        return crypt.LastErrorText;
      }

      //  Indicate that no encryption should be performed,
      //  only encoding/decoding.
      crypt.CryptAlgorithm = "none";
      crypt.EncodingMode = "base64";

      //  Other possible EncodingMode settings are:
      //  "quoted-printable", "hex", "uu", "base32", and "url"
      outString = crypt.DecryptStringENC(inputString);

      return "";
    }

    public static string AESStringEncryption(string passPhrase, string inputString, ref string outString)
    {
      Chilkat.Crypt2 crypt = new Chilkat.Crypt2();

      bool success;
      success = crypt.UnlockComponent(ConfigurationManager.AppSettings["CYPT"]);
      if (success != true)
      {
        return crypt.LastErrorText;
      }

      crypt.CryptAlgorithm = "aes";
      crypt.CipherMode = "cbc";
      crypt.KeyLength = 128;

      //  Generate a binary secret key from a password string
      //  of any length.  For 128-bit encryption, GenEncodedSecretKey
      //  generates the MD5 hash of the password and returns it
      //  in the encoded form requested.  The 2nd param can be
      //  "hex", "base64", "url", "quoted-printable", etc.
      string hexKey;
      hexKey = crypt.GenEncodedSecretKey(passPhrase, "hex");
      crypt.SetEncodedKey(hexKey, "hex");

      crypt.EncodingMode = "base64";

      //  Encrypt a string and return the binary encrypted data
      //  in a base-64 encoded string.
      outString = crypt.EncryptStringENC(inputString);

      return "";
    }

    public static string AESStringDecryption(string passPhrase, string inputString, ref string outString)
    {
      Chilkat.Crypt2 crypt = new Chilkat.Crypt2();

      bool success;
      success = crypt.UnlockComponent(ConfigurationManager.AppSettings["CYPT"]);
      if (success != true)
      {
        return crypt.LastErrorText;
      }

      crypt.CryptAlgorithm = "aes";
      crypt.CipherMode = "cbc";
      crypt.KeyLength = 128;

      //  Generate a binary secret key from a password string
      //  of any length.  For 128-bit encryption, GenEncodedSecretKey
      //  generates the MD5 hash of the password and returns it
      //  in the encoded form requested.  The 2nd param can be
      //  "hex", "base64", "url", "quoted-printable", etc.
      string hexKey;
      hexKey = crypt.GenEncodedSecretKey(passPhrase, "hex");
      crypt.SetEncodedKey(hexKey, "hex");

      crypt.EncodingMode = "base64";

      //  Encrypt a string and return the binary encrypted data
      //  in a base-64 encoded string.
      outString = crypt.DecryptStringENC(inputString);

      return "";
    }
  }
  #endregion

  #region Services Controller
  public static class MyServiceController
  {
    public static void RestartService(string serviceName, int timeoutMilliseconds)
    {
      ServiceController service = new ServiceController(serviceName);
      try
      {

        int millisec1 = Environment.TickCount;
        TimeSpan timeout = TimeSpan.FromMilliseconds(timeoutMilliseconds);
        service.Stop();
        //service.WaitForStatus(ServiceControllerStatus.Stopped, timeout);

        // count the rest of the timeout
        int millisec2 = Environment.TickCount;
        timeout = TimeSpan.FromMilliseconds(timeoutMilliseconds - (millisec2 - millisec1));

        service.Start();
        //service.WaitForStatus(ServiceControllerStatus.Running, timeout);
      }
      catch (Exception ex)
      {
        throw ex;
      }
    }

    public static void StopService(string serviceName, int timeoutMilliseconds)
    {
      ServiceController service = new ServiceController(serviceName);
      try
      {

        int millisec1 = Environment.TickCount;
        TimeSpan timeout = TimeSpan.FromMilliseconds(timeoutMilliseconds);
        service.Stop();
        //service.WaitForStatus(ServiceControllerStatus.Stopped, timeout);
      }
      catch (Exception ex)
      {
        throw ex;
      }
    }

    public static void StartService(string serviceName, int timeoutMilliseconds)
    {
      ServiceController service = new ServiceController(serviceName);
      try
      {
        TimeSpan timeout = TimeSpan.FromMilliseconds(timeoutMilliseconds);

        service.Start();
        //service.WaitForStatus(ServiceControllerStatus.Running, timeout);
      }
      catch (Exception ex)
      {
        throw ex;
      }
    }
  }
  #endregion

  #region WS
  public static class WSHelper
  {
    static string _soapMSG = "<env:Envelope xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"><env:Body><xuLyTruyVanMsg xmlns=\"http://gip.com/\"><in_msg xmlns=\"\">{0}</in_msg></xuLyTruyVanMsg></env:Body></env:Envelope>";

    private static string CreateSoapEnvelope(string content)
    {
      string message;
      message = string.Format(_soapMSG, System.Web.HttpUtility.HtmlEncode(content));

      return message;
    }

    private static HttpWebRequest CreateWebRequest(string url)
    {
      HttpWebRequest webRequest = (HttpWebRequest)WebRequest.Create(url);

      webRequest.Accept = "text/xml";
      webRequest.ContentType = "text/xml;charset=\"utf-8\"";
      webRequest.Method = "POST";
      webRequest.KeepAlive = true;
      webRequest.Timeout = 480000;
      webRequest.CachePolicy = new HttpRequestCachePolicy(HttpRequestCacheLevel.NoCacheNoStore);
      return webRequest;
    }

    public static string WebServiceCall(string url, string action, string paraName, string para)
    {
      string results;
      try
      {
        System.Net.ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

        HttpWebRequest request = CreateWebRequest(url);

        string soapEnvelopeXml = CreateSoapEnvelope(para);

        using (StreamWriter sw = new StreamWriter(request.GetRequestStream()))
        {
          sw.Write(soapEnvelopeXml);
        }

        //sync
        //HttpWebResponse response;
        //try
        //{
        //  response = (HttpWebResponse)request.GetResponse();
        //}
        //catch (WebException ex)
        //{
        //  using (StreamReader sr = new StreamReader(ex.Response.GetResponseStream()))
        //  {
        //    string result = sr.ReadToEnd();
        //    sr.Close();
        //  }
        //  return null;
        //}

        //using (StreamReader sr = new StreamReader(response.GetResponseStream()))
        //{
        //  results = System.Web.HttpUtility.HtmlDecode(sr.ReadToEnd());
        //}

        //response.Close();

        //async
        IAsyncResult asyncResult = request.BeginGetResponse(null, null);

        asyncResult.AsyncWaitHandle.WaitOne();

        string soapResult;
        using (WebResponse webResponse = request.EndGetResponse(asyncResult))
        using (StreamReader rd = new StreamReader(webResponse.GetResponseStream()))
        {
          soapResult = rd.ReadToEnd();
        }
        results = System.Web.HttpUtility.HtmlDecode(soapResult);

        return ExtractResults(results);
      }
      catch (WebException webex)
      {
        Logger.Error("WSHelper::WebServiceCall", webex);
        WebResponse errResp = webex.Response;
        if (webex.Response != null)
        {
          using (Stream respStream = errResp.GetResponseStream())
          {
            StreamReader reader = new StreamReader(respStream);
            string text = reader.ReadToEnd();
            Logger.Error("WSHelper::WebServiceCall::WebException::" + text);
          }
        }
        throw webex;
      }
      catch (Exception ex)
      {
        Logger.Error("WSHelper::WebServiceCall", ex);
        throw ex;
      }
      return null;
    }

    private static string ExtractResults(string results)
    {
      if (!string.IsNullOrEmpty(results))
      {
        int indexofData = results.IndexOf("<DATA>");
        int indexofEndData = results.IndexOf("</DATA>");
        int length = indexofEndData - indexofData + 7;

        if (indexofData < results.Length &&
          indexofEndData < results.Length)
        {
          results = results.Substring(indexofData, length);
        }
      }
      return results;
    }
  }
  #endregion
}
