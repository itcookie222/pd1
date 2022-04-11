using System;
using System.Collections.Generic;
using System.Text;
using Entities;
using Business;

namespace SCB.PMTGWT.Utils
{
  public class GlobalCache
  {
    #region Properties
    // LOAD_BALANCE_CONFIG
    private static LOAD_BALANCE_CONFIGCollection m_outBranches = null;
    public static LOAD_BALANCE_CONFIGCollection OutBranches
    {
      get
      {
        if (m_outBranches == null)
        {
          m_outBranches = LOAD_BALANCE_CONFIGService.GetByOutStatus((int)EnumList.LoadBalanceConfigStatus.ACTIVE,
            EnumList.GwtOption.PER.ToString());
        }

        return m_outBranches;
      }
    }

    private static LOAD_BALANCE_CONFIGCollection m_inBranchesPerCent = null;
    public static LOAD_BALANCE_CONFIGCollection InBranchesPerCent
    {
      get
      {
        if (m_inBranchesPerCent == null)
        {
          m_inBranchesPerCent = LOAD_BALANCE_CONFIGService.GetByInStatus((int)EnumList.LoadBalanceConfigStatus.ACTIVE,
            EnumList.GwtOption.PER.ToString());
        }

        return m_inBranchesPerCent;
      }
    }

    private static LOAD_BALANCE_CONFIGCollection m_inBranchesSTS = null;
    public static LOAD_BALANCE_CONFIGCollection InBranchesSTS
    {
      get
      {
        if (m_inBranchesSTS == null)
        {
          m_inBranchesSTS = LOAD_BALANCE_CONFIGService.GetByInStatus((int)EnumList.LoadBalanceConfigStatus.ACTIVE,
            EnumList.GwtOption.STS.ToString());
        }

        return m_inBranchesSTS;
      }
    }

    // CHECK_CODE_MAPPING
    private static CHECK_CODE_MAPPINGCollection m_checkCodeCol = null;
    public static CHECK_CODE_MAPPINGCollection CheckCodeCol
    {
      get
      {
        if (m_checkCodeCol == null)
        {
          m_checkCodeCol = CHECK_CODE_MAPPINGService.GetCHECK_CODE_MAPPINGList(CHECK_CODE_MAPPINGColumns.CHECK_CODE, Scb.Framework.OrderDirection.ASC);
        }

        return m_checkCodeCol;
      }
    }

    // CITAD_BRANCH
    private static CITAD_BRANCHCollection m_citadBranches = null;
    public static CITAD_BRANCHCollection CitadBranches
    {
      get
      {
        if (m_citadBranches == null)
        {
          m_citadBranches = CITAD_BRANCHService.GetCITAD_BRANCHList(CITAD_BRANCHColumns.BRANCH_CODE, Scb.Framework.OrderDirection.ASC);
        }

        return m_citadBranches;
      }
    }

    //STS Load Balance
    private static STS_CUSTOMERCollection m_stsCustomerPri = null;
    public static STS_CUSTOMERCollection STSCustomerPRI
    {
      get
      {
        if (m_stsCustomerPri == null)
        {
          m_stsCustomerPri = STS_CUSTOMERService.GetActiveByType(EnumList.StsCustomerType.PRI.ToString());
        }

        return m_stsCustomerPri;
      }
    }

    private static STS_CUSTOMERCollection m_stsCustomerNRM = null;
    public static STS_CUSTOMERCollection STSCustomerNRM
    {
      get
      {
        if (m_stsCustomerNRM == null)
        {
          m_stsCustomerNRM = STS_CUSTOMERService.GetActiveByType(EnumList.StsCustomerType.NRM.ToString());
        }

        return m_stsCustomerNRM;
      }
    }

    //STS M
    private static STS_CUSTOMERCollection m_stsCustomerSTSM = null;
    public static STS_CUSTOMERCollection STSCustomerSTSM
    {
      get
      {
        if (m_stsCustomerSTSM == null)
        {
          m_stsCustomerSTSM = STS_CUSTOMERService.GetActiveByType(EnumList.StsCustomerType.STSM.ToString());
        }

        return m_stsCustomerSTSM;
      }
    }

    //STS CASH
    private static STS_CUSTOMERCollection m_stsCustomerCASH = null;
    public static STS_CUSTOMERCollection STSCustomerCASH
    {
      get
      {
        if (m_stsCustomerCASH == null)
        {
          m_stsCustomerCASH = STS_CUSTOMERService.GetActiveByType(EnumList.StsCustomerType.CASHD.ToString());
        }

        return m_stsCustomerCASH;
      }
    }

    // R_INDIRECT_CODE REPLACE
    private static PMT_CAD_REPLACE_INDR_CODECollection m_rInDirectCode = null;
    public static PMT_CAD_REPLACE_INDR_CODECollection R_INDIRECT_CODE_LIST
    {
      get
      {
        if (m_rInDirectCode == null)
        {
          m_rInDirectCode = PMT_CAD_REPLACE_INDR_CODEService.GetByStatus(EnumList.RICStatus.APPROVED.ToString());
        }

        return m_rInDirectCode;
      }
    }

    // TAX BANK CODE
    private static TAX_BANKCODECollection m_taxBankCode = null;
    public static TAX_BANKCODECollection TAX_BANK_CODE_LIST
    {
      get
      {
        if (m_taxBankCode == null)
        {
          m_taxBankCode = TAX_BANKCODEService.GetByStatus(EnumList.TAXStatus.APPROVED.ToString());
        }

        return m_taxBankCode;
      }
    }

    //STS TAXG
    private static STS_CUSTOMERCollection m_stsCustomerTAXG = null;
    public static STS_CUSTOMERCollection STSCustomerTAXG
    {
      get
      {
        if (m_stsCustomerTAXG == null)
        {
          m_stsCustomerTAXG = STS_CUSTOMERService.GetActiveByType(EnumList.StsCustomerType.TAXG.ToString());
        }

        return m_stsCustomerTAXG;
      }
    }
    #endregion
  }
}
