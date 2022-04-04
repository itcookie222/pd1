using System;
using System.Collections.Generic;
using System.Text;

namespace Claris.Common
{
  public static class ClarisRules
  {
    public static bool IsVAAccount(string accountNo)
    {
      if (string.IsNullOrEmpty(accountNo) || accountNo.Length < 5)
        return false;

      if (accountNo.Trim().StartsWith("33"))
        return true;

      return false;
    }

    public static bool IsVAAccountPartAOnly(string accountNo)
    {
      if (string.IsNullOrEmpty(accountNo) || accountNo.Length < 5)
        return false;

      if (accountNo.Trim().StartsWith("33") && accountNo.Length == 5)
        return true;

      return false;
    }
  }
}
