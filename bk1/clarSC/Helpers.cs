using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.IO;
using Scb.Framework;
using System.Net.Mail;
using System.Security.Cryptography;

namespace Claris.Common
{
  public static class Algorithms
  {
    public static readonly HashAlgorithm MD5 = new MD5CryptoServiceProvider();
    public static readonly HashAlgorithm SHA1 = new SHA1Managed();
    public static readonly HashAlgorithm SHA256 = new SHA256Managed();
    public static readonly HashAlgorithm SHA384 = new SHA384Managed();
    public static readonly HashAlgorithm SHA512 = new SHA512Managed();
    public static readonly HashAlgorithm RIPEMD160 = new RIPEMD160Managed();
  }

  public static class Helpers
  {
    public static void SaveConfig(string item, string value)
    {
      System.Configuration.Configuration config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
      config.AppSettings.Settings[item].Value = value;
      config.Save(ConfigurationSaveMode.Modified);
      ConfigurationManager.RefreshSection("appSettings");
    }

    public static string CreateDestFolderByDate(DateTime dt, string destname)
    {
      if (!CreateDir(destname))
        return "";

      destname = destname + "\\" + dt.Year.ToString();
      if (!CreateDir(destname))
        return "";

      destname = destname + "\\" + dt.Month.ToString();
      if (!CreateDir(destname))
        return "";

      destname = destname + "\\" + dt.Day.ToString();
      if (!CreateDir(destname))
        return "";

      return destname;
    }

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
          Logger.Error("CreateDir::" + foldername, ex);
        }
      }
      else
      {
        return true;
      }
      return false;
    }

    private static string GetMD5HashFromFile(string fileName)
    {
      StringBuilder sb = new StringBuilder();
      try
      {
        FileStream file = new FileStream(fileName, FileMode.Open);
        MD5 md5 = new MD5CryptoServiceProvider();

        byte[] retVal = md5.ComputeHash(file);
        file.Close();

        for (int i = 0; i < retVal.Length; i++)
        {
          sb.Append(retVal[i].ToString("x2"));
        }
        return sb.ToString();
      }
      catch (Exception ex)
      {
        Logger.Error("GetMD5HashFromFile::", ex);
      }
      return null;
    }

    public static bool IsCheckSumValid(string sourcefile, string checksumfile)
    {
      if (!File.Exists(sourcefile))
        return false;

      string checksumSrc = GetMD5HashFromFile(sourcefile);

      if (!File.Exists(checksumfile))
        return false;

      string contentDst = File.ReadAllText(checksumfile);
      string checksumDst = contentDst.Split(' ')[0].Trim();
      if (checksumSrc == checksumDst)
        return true;

      return false;
    }

    public static bool IsCheckSumValidACB(string sourcefile, string checksumfile)
    {
      if (!File.Exists(sourcefile))
        return false;

      string checksumSrc = GetMD5HashFromFile(sourcefile);

      if (!File.Exists(checksumfile))
        return false;

      string contentDst = File.ReadAllText(checksumfile);
      string checksumDst = contentDst.Trim();
      if (checksumSrc == checksumDst)
        return true;

      return false;
    }

    public static string ArchiveFile(string folderName, string filename, bool isDelete)
    {
      try
      {
        folderName = CreateDestFolderByDate(DateTime.Now, folderName);
        if (folderName != "")
        {

          if (!File.Exists(filename))
            return null;

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
        Logger.Error("ArchiveFile", ex);
        throw;
      }

      return null;
    }

    public static string GetDecimalString(string input)
    {
      string[] numbers = input.Split('.');
      Int64 no1 = 0;
      Int64 no2 = 0;
      Int64.TryParse(numbers[0], out no1);
      if (numbers.Length >= 2)
        Int64.TryParse(numbers[1], out no2);

      return no1.ToString("D18") + no2.ToString("D6");
    }

    public static decimal GetDecimalFromString(string input)
    {
      decimal output = 0;
      string[] numbers = input.Split(',');
      string number1 = "0";

      if (numbers.Length == 1)
        number1 = "0";

      if (numbers.Length >= 2 && numbers[1] == "")
        number1 = "0";

      if (numbers.Length >= 2 && numbers[1] != "")
        number1 = numbers[1];

      decimal.TryParse(numbers[0] + "." + number1, out output);

      return output;
    }

    public static void NotifyEmail(string message)
    {
      try
      {
        string[] toEmails = ConfigurationManager.AppSettings["NotifyEmail"].Split(';');

        if (toEmails.Length <= 0)
          return;

        // To
        MailMessage mailMsg = new MailMessage();
        foreach (string s in toEmails)
        {
          if (s != "")
            mailMsg.To.Add(s);
        }

        // From
        MailAddress mailAddress = new MailAddress("Rcms_Notify@sc.com");
        mailMsg.From = mailAddress;

        // Subject and Body
        mailMsg.Subject = "RCMS Notification";
        mailMsg.Body = message;

        SmtpClient smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServer"]);

        smtpClient.UseDefaultCredentials = true;
        smtpClient.Send(mailMsg);

      }
      catch (Exception ex)
      {
        Logger.Error("NotifyEmail::", ex);
      }
    }

    public static void NotifyEmailAML(string refNo, string bank, string message)
    {
      try
      {
        string[] toEmails = ConfigurationManager.AppSettings["NotifyEmail"].Split(';');

        if (toEmails.Length <= 0)
          return;

        // To
        MailMessage mailMsg = new MailMessage();
        foreach (string s in toEmails)
        {
          if (s != "")
            mailMsg.To.Add(s);
        }

        // From
        MailAddress mailAddress = new MailAddress("Rcms_Notify@sc.com");
        mailMsg.From = mailAddress;

        // Subject and Body
        mailMsg.Subject = string.Format("PMTGWT Notification - AML Claris :  {0} {1}", bank, refNo);
        mailMsg.Body = message;

        SmtpClient smtpClient = new SmtpClient(ConfigurationManager.AppSettings["SMTPServer"]);

        smtpClient.UseDefaultCredentials = true;
        smtpClient.Send(mailMsg);

      }
      catch (Exception ex)
      {
        Logger.Error("NotifyEmail::", ex);
      }
    }

    public static string GetString(string input, int from, int to)
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

    public static void AlertAMLHitRules(string refNo, string amount, string trxDate, string bank)
    {
      StringBuilder message = new StringBuilder();

      message.Append("BELOW TRANSACTION IS HIT AML RULE:" + Environment.NewLine);
      message.Append("RELATION NO:" + refNo + Environment.NewLine);
      message.Append("TRX DATE:" + trxDate + Environment.NewLine);
      message.Append("AMOUNT:" + amount + Environment.NewLine);
      message.Append("DATE TIME:" + DateTime.Now.ToString() + Environment.NewLine);

      NotifyEmailAML(refNo, bank, message.ToString());
    }

    public static bool IsASCII(string value)
    {
      // ASCII encoding replaces non-ascii with question marks, so we use UTF8 to see if multi-byte sequences are there
      return Encoding.UTF8.GetByteCount(value) == value.Length;
    }

    public static string GetHashFromString(string theString, HashAlgorithm algorithm)
    {
      return BitConverter.ToString(algorithm.ComputeHash(Encoding.UTF8.GetBytes(theString))).Replace("-", string.Empty);
    }
  }
}
