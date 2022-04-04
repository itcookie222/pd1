using System;
using System.Collections.Generic;
using System.Text;

namespace Claris.Common.Ultis
{
  public static class NumberUtils
  {
    /// <summary>
    /// 
    /// </summary>
    /// <param name="amount"></param>
    /// <returns></returns>
    public static string ReadMoney(string amount)
    {
      string value = "";
      int i = 0;
      amount = DeleteZeroNumbers(amount);
      while (amount.Length > 12)
      {       
        value = UnitPrice(i) + MultiNumbers(amount.Substring(amount.Length - 12, 12), 12, 0);
        amount = amount.Substring(0, amount.Length - 12);
        i++;
      }
      if (amount.Length > 0)
      {
        value = MultiNumbers(amount, amount.Length, i) + " " + value;
      }
      value = value.ToString().TrimEnd();
      return value;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="amount"></param>
    /// <returns></returns>
    public static string ReadNumber(string amount)
    {
       string value = "";
      int i = 0;
      amount = DeleteZeroNumbers(amount);
      while (amount.Length > 12)
      {       
        value = UnitPrice(i) + MultiNumbers(amount.Substring(amount.Length - 12, 12), 12, 0);
        amount = amount.Substring(0, amount.Length - 12);
        i++;
      }
      if (amount.Length > 0)
      {
        value = MultiNumbers(amount, amount.Length, i) + " " + value;
      }
      return value;
    }

    #region Các hàm đọc số
    /// <summary>
    /// 
    /// </summary>
    /// <param name="variable"></param>
    /// <returns></returns>
    private static string OneNumber(string variable)
    {
      switch (variable)
      {
        case "0": return "không";
        case "1": return "một";
        case "2": return "hai";
        case "3": return "ba";
        case "4": return "bốn";
        case "5": return "năm";
        case "6": return "sáu";
        case "7": return "bảy";
        case "8": return "tám";
        case "9": return "chín";
      }
      return "không";
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="variable"></param>
    /// <returns></returns>
    private static string TwoNumbers(string variable)
    {
      string value = " mười ";
      if ((variable.Substring(1, 1) == "0") && (variable.Substring(0, 1) != "1"))
        value = OneNumber(variable.Substring(0, 1)) + " mươi ";
      if (variable.Substring(1, 1) != "0")
        switch (variable.Substring(1, 1))
        {
          case "5":
            if (variable.Substring(0, 1) == "1")
              value = " mười lăm";
            else
              value = OneNumber(variable.Substring(0, 1)) + " mươi lăm";
            break;
          case "1":
            if (variable.Substring(0, 1) == "1")
              value = " mười một";
            else
              value = OneNumber(variable.Substring(0, 1)) + " mươi mốt";
            break;
          default:
            if (variable.Substring(0, 1) == "1")
              value = " mười " + OneNumber(variable.Substring(1, 1));
            else
              value = OneNumber(variable.Substring(0, 1)) + " mươi " + OneNumber(variable.Substring(1, 1));
            break;
        }
      return value;
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="variable"></param>
    /// <returns></returns>
    private static string ThreeNumbers(string variable)
    {
      if (variable == "000") return "";
      string value = "trăm";
      if (variable.Substring(1, 1) == "0")
      {
        if (variable.Substring(2, 1) == "0")
          value = OneNumber(variable.Substring(0, 1)) + " trăm ";
        else
          value = OneNumber(variable.Substring(0, 1)) + " trăm lẻ " + OneNumber(variable.Substring(2, 1));
      }
      else
      {
        value = OneNumber(variable.Substring(0, 1)) + " trăm " + TwoNumbers(variable.Substring(1, 2));
      }
      return value.Trim();
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="variable"></param>
    /// <param name="length"></param>
    /// <returns></returns>
    private static string MultiNumbers(string variable, int length, int i)
    {
      string tmpAmount = "";
      string value = "", tmp = "";
     // int i =0;
      while ((length) > 3)
      {
        tmpAmount = variable.Substring(variable.Length - 3, 3);
        if (tmpAmount != "000")//|| value.Trim() != "")
        {
          tmp = ThreeNumbers(variable.Substring(variable.Length - 3, 3));
          value = tmp + UnitPrice(i) + value;
        }
        variable = variable.Substring(0, variable.Length - 3);
        i++;
        if (i > 3) i = 1;
        if (length > 3) length = length - 3;
      }
      if (length == 1) value = OneNumber(variable) + UnitPrice(i) + value;
      if (length == 2) value = TwoNumbers(variable) + UnitPrice(i) + value;
      if (length == 3) value = ThreeNumbers(variable) + UnitPrice(i) + value;
      return value.Trim();
    }
    #endregion

    /// <summary>
    /// 
    /// </summary>
    /// <param name="tam"></param>
    /// <returns></returns>
    private static string DeleteZeroNumbers(string number)
    {
      while (number[0] == '0')
      {
        if (number.Length > 1) number = number.Substring(1, number.Length - 1);
        else break;
      }
      return number;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="tam"></param>
    /// <returns></returns>
    private static string UnitPrice(int unit)
    {
      switch (unit)
      {
        case 0: return " đồng ";
        case 1: return " nghìn ";
        case 2: return " triệu ";
        case 3: return " tỷ ";
      }
      return "";
    }
  }
}
