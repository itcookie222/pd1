using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using Claris.Entities;
using Claris.Business;
using Scb.Framework;

namespace Claris.Common
{
  public static class AMLRules
  {

    public static WSAML.XLS_CMO_AML_LOCAL[] IsHitAMLLocalList(int exactFind, string lastName, string dob, string passports, string location,
     string countries)
    {
      WSAML.AMLServices sDataProvider = new WSAML.AMLServices();
      sDataProvider.Url = ConfigurationManager.AppSettings["ConfigWSAML"];
      sDataProvider.PreAuthenticate = true;
      sDataProvider.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;
      return sDataProvider.IsHitAMLLocalList(exactFind, lastName, dob, passports, location, countries);
    }

    public static bool GetHitListAMLLocalList(int exactFind, string[] inputList, string refNo)
    {
      WSAML.AMLServices sDataProvider = new WSAML.AMLServices();
      sDataProvider.Url = ConfigurationManager.AppSettings["ConfigWSAML"];
      sDataProvider.PreAuthenticate = true;
      sDataProvider.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;
      if (inputList != null)
      {
        WSAML.XLS_CMO_AML_LOCAL[] listAMLHit = sDataProvider.GetHitAMLLocalList(exactFind, inputList);

        if (listAMLHit != null && listAMLHit.Length > 0)
        {
          foreach (WSAML.XLS_CMO_AML_LOCAL aml in listAMLHit)
          {
            SaveAMLHitInfo(refNo, aml.LAST_NAME, aml.DOB, aml.PASSPORTS, aml.LOCATION, aml.COUNTRIES);
          }
          return true;
        }
      }
      return false;
    }

    public static bool IsILTHitThreshold(string refNo, decimal amtChecked)
    {
      WSAML.AMLServices sDataProvider = new WSAML.AMLServices();
      sDataProvider.Url = ConfigurationManager.AppSettings["ConfigWSAML"];
      sDataProvider.PreAuthenticate = true;
      sDataProvider.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;
      if (sDataProvider.IsHitILTThreshold(amtChecked))
      {
        SaveAMLHitInfo(refNo, amtChecked.ToString(), null, null, null, null);
        return true;
      }
      return false;
    }


    private static void SaveAMLHitInfo(string refNo, string lastName, string dob, string passport, string location, string countries)
    {
      try
      {
        tblPaymentLogger pl = new tblPaymentLogger();
        pl.RefNo = refNo;
        pl.Action = EnumList.LoggerAML;
        pl.ActionDate = DateTime.Now;
        pl.PreValue = string.Format("[AML:{0}_{1}_{2}_{3}_{4}]", lastName, dob, passport, location, countries);
        pl.UserId = "AMLMNT";
        tblPaymentLoggerService.CreatetblPaymentLogger(pl);
      }
      catch (Exception ex)
      {
        Logger.Error("SaveAMLHitInfo::ERROR", ex);
      }
    }
  }
}
