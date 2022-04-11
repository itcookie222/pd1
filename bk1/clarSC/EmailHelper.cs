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
using PdfSharp.Pdf.Security;
using PdfSharp.Pdf;
using System.Text.RegularExpressions;

namespace SCB.PMTGWT.Utils
{
  public static class EmailHelper
  {
    public static string CreateDir(string name)
    {
      try
      {
        string currname = name + "\\" + DateTime.Now.Month.ToString() + DateTime.Now.Year.ToString();
        DateTime lastMonthDate = DateTime.Now.AddMonths(-3);

        string oldname = name + "\\" + lastMonthDate.Month.ToString() + lastMonthDate.Year.ToString();
        if (!Directory.Exists(currname))
        {
          Directory.CreateDirectory(currname);
        }

        //DeletePreviousMonth
        if (Directory.Exists(oldname))
        {
          Directory.Delete(oldname, true);
        }
        return currname;
      }
      catch (Exception ex)
      {
        Logger.Error("AMS::CreateDirectory::", ex);
      }
      return "";
    }

    public static void SetPDFPassword(PdfDocument doc, string userpassword, string owerpassword)
    {
      PdfSecuritySettings securitySettings = doc.SecuritySettings;

      // Setting one of the passwords automatically sets the security level to 
      // PdfDocumentSecurityLevel.Encrypted128Bit.
      securitySettings.UserPassword = userpassword;
      securitySettings.OwnerPassword = owerpassword;

      // Restrict some rights.
      securitySettings.PermitAccessibilityExtractContent = true;
      securitySettings.PermitAnnotations = true;
      securitySettings.PermitAssembleDocument = true;
      securitySettings.PermitExtractContent = true;
      securitySettings.PermitFormsFill = true;
      securitySettings.PermitFullQualityPrint = true;
      securitySettings.PermitModifyDocument = true;
      securitySettings.PermitPrint = true;
    }

    public static bool IsValidEmail(string inputEmail)
    {
      string strRegex = @"^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$";
      Regex re = new Regex(strRegex);
      if (re.IsMatch(inputEmail))
        return (true);
      else
        return (false);
    }

    public static bool SendEmailWithImages(string templateFile, string emailAddress, string[] attachFiles,
      string processDate, string relationNo, string accountNo, string clientName, string savedFolder)
    {
      Chilkat.MailMan mailman = new Chilkat.MailMan();

      bool success;
      success = mailman.UnlockComponent("SCBANKMAILQ_5Ls8ZS6LnSpg");
      if (success != true)
      {
        return false;
      }

      mailman.SmtpHost = ConfigurationManager.AppSettings["SMTPServer"];

      //  Create a new email object
      Chilkat.Email email = new Chilkat.Email();

      email.From = ConfigurationManager.AppSettings["EmailFrom"];

      foreach (string attachfile in attachFiles)
      {
        if (attachfile != null && File.Exists(attachfile))
        {
          email.AddFileAttachment(attachfile);
        }
      }

      if (success != true)
      {
        return false;
      }

      string htmlBody = File.ReadAllText(templateFile);

      email.SetTextBody(htmlBody, null);
      email.Subject = string.Format("SCB VN TAX ADVICE - {0} - {1} - {2}", processDate, relationNo, "XXXXXXX" + accountNo.Substring(10, 4));

      string[] emailList = emailAddress.Split(';');
      foreach (string address in emailList)
      {
        if (IsValidEmail(address.Trim()))
        {
          email.AddTo(clientName, address.Trim());
        }
      }

      try
      {
        success = mailman.SendEmail(email);

        if (Directory.Exists(savedFolder))
        {
          email.SaveEml(Path.Combine(savedFolder, Path.GetFileNameWithoutExtension(attachFiles[0]) + ".eml"));
        }
      }
      catch (Exception)
      {
        try
        {
          mailman.SmtpHost = ConfigurationManager.AppSettings["SMTPServer"];
          success = mailman.SendEmail(email);
        }
        catch (Exception)
        {
          mailman.SmtpHost = ConfigurationManager.AppSettings["SMTPServerBK"];
          success = mailman.SendEmail(email);

          throw;
        }
      }

      if (success != true)
      {
        Logger.Error("SendEmailWithImages" + mailman.LastErrorText);
        return false;
      }
      else
      {
        return true;
      }
    }
  }
}
