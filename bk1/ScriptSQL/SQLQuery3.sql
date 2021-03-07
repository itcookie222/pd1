USE [LITS]
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_report_tracking]    Script Date: 11/7/2019 2:26:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Phan Duy Thong>
-- Create date: <2018-06-15>
-- Updated by: <Tran Van Nhat> - <8/30/2019>
-- Description:	<sp_report_pl_application_get_report_tracking>
-- =============================================
-- exec  [sp_report_pl_application_get_report_tracking] '2018-01-01','2019-09-01','CancelledTracking',0 
ALTER PROCEDURE [dbo].[sp_report_pl_application_get_report_tracking]
	@FromDate datetime,
	@ToDate datetime, 
	@TypeReport varchar(30),
	@StatusID int
AS
SET FMTONLY OFF
 SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
  ap.application_no as ApplicationNo,
  CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
  cus.full_name as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus WITH(NOLOCK) join  [m_identification_type] m 
							 WITH(NOLOCK) on cus.fk_m_identification_type_id = m.pk_id and m.code ='01'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus WITH(NOLOCK) join  [m_identification_type] m 
							 WITH(NOLOCK) on cus.fk_m_identification_type_id = m.pk_id and m.code ='02'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus WITH(NOLOCK) join  [m_identification_type] m 
							 WITH(NOLOCK) on cus.fk_m_identification_type_id = m.pk_id and m.code ='03'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus WITH(NOLOCK) join  [m_identification_type] m 
							 WITH(NOLOCK) on cus.fk_m_identification_type_id = m.pk_id and m.code ='04'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousPP,

--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
CONVERT(VARCHAR(24),cus.dob,106) as DOB,
--cc.Nationality,
(select top(1)m.name from m_nationality m WITH(NOLOCK) 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_group m WITH(NOLOCK) inner join m_definition_type md 
													 WITH(NOLOCK) on m.pk_id = md.fk_group_id and m.pk_id = 69	and md.is_active =1							where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 ) as SelfEmployed,

--cc.CurrentPosition as JobTitle,
(select top(1)m.name from pl_company_information co WITH(NOLOCK)  inner join m_position m
															 WITH(NOLOCK) on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as JobTitle,
--cc.CompanyCode as [Company Code],
co.company_code as CompanyCode,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--cc.BusinessType as CompanyType,
(select top(1) m.name from m_business_nature m WITH(NOLOCK)
					  where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as CompanyType,
--ap.LocationBranchName as Business_TradingArea,
(select top(1) m.name from m_branch_location m WITH(NOLOCK)
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as Business_TradingArea,
--ap.CreditBureauType as CIC,
(select top(1)m.name from pl_customer_credit_bureau cb WITH(NOLOCK) join m_credit_bureau_type m 
														 WITH(NOLOCK) on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,
----------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as [O/S_At_Other_Bank 1],

(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as [EMI_At_Other_Bank 1],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as [O/S_At_Other_Bank 2],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as [EMI_At_Other_Bank 2],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as [O/S_At_Other_Bank 3],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as [EMI_At_Other_Bank 3],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as [O/S_At_Other_Bank 4],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as [EMI_At_Other_Bank 4],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as [O/S_At_Other_Bank 5],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as [EMI_At_Other_Bank 5],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as [O/S_At_Other_Bank 6],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as [EMI_At_Other_Bank 6],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as [O/S_At_Other_Bank 7],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as [EMI_At_Other_Bank 7],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as [O/S_At_Other_Bank 8],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as [EMI_At_Other_Bank 8],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as [O/S_At_Other_Bank 9],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as [EMI_At_Other_Bank 9],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as [O/S_At_Other_Bank 10],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau WITH(NOLOCK)
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as [EMI_At_Other_Bank 10],
----------
--CONVERT(varchar, CAST(cpl.PersonalLoanAmountApplied AS MONEY), 1) AS [Loan_Amt_Applied],
(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as [Loan_Amt_Applied],
--cpl.LoanPurpose,
 (select top(1) Substring(m.name, 4, Len(m.name) -3) from pl_approval_information apr WITH(NOLOCK) inner join m_loan_purpose m WITH(NOLOCK) on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as LoanPurpose,
--ap.ChannelD,
(select top(1) Substring(m.name, 4, Len(m.name) -3) from m_sales_channel m WITH(NOLOCK)
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as ChannelD,

--ap.LocationBranchName,
(select top(1) Substring(m.name, 4, Len(m.name) -3) from m_branch_location m WITH(NOLOCK)
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as LocationBranchName,
--ap.ARMCode,
ap.arm_code as  ARMCode,
--cc.PaymentType as PaymentMethod,
(select top(1) Substring(m.name,4,Len(m.name)-3) from  m_payment_type m WITH(NOLOCK)
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,
--ap.CardProgramName as Program,
(select top(1) cp.name from cc_card_program cp WITH(NOLOCK)
				where pap.fk_card_program_id = cp.pk_id) as Program,

--CONVERT(varchar, CAST(cc.FinalIncome AS MONEY), 1) AS [Total Income],
(select top(1)CONVERT(varchar, CAST(cin.final_income AS MONEY), 1)  from pl_customer_income cin WITH(NOLOCK)
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Total Income],

--CONVERT(varchar, CAST(cc.GrossBaseSalary AS MONEY), 1) AS [Salary Income], 
(select top(1)CONVERT(varchar, CAST(cin.gross_base_salary AS MONEY), 1)  from pl_customer_income cin WITH(NOLOCK)
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Salary Income],
--CONVERT(varchar, CAST(cc.BasicAllowance AS MONEY), 1) AS [Other_Incomes (Non-salary)], 
(select top(1)CONVERT(varchar, CAST(cin.basic_allowance AS MONEY), 1)  from pl_customer_income cin WITH(NOLOCK)
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Other_Incomes (Non-salary)], 

--(case when (select COUNT(*) from FRMInvestigave frm where frm.ApplicationNo = ap.ApplicationNo) > 0 then 'Yes' else 'No' end) as BlackList_Check, 
(case when (select COUNT(*) from frm_investigave frm WITH(NOLOCK) where frm.fk_application_information_id = ap.pk_id) > 0 then 'Yes' else 'No' end) as BlackList_Check,

--(select top 1 lu.FullName  from AppActionLog lg join LoginUser lu WITH(NOLOCK) on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and (lg.[Action]='CIApproved' or lg.[Action]='CIApprovedPL' or lg.[Action]='CIApprovedCC'  or lg.[Action]='CIApprovedBD' or lg.[Action]='CIRejected' or lg.[Action]='CIRejectedBD')) as Underwritter,

(select top 1 lg.action_by  from application_action_log lg where lg.fk_application_information_id = ap.pk_id and lg.[Action] in('CIApproved','CIApprovedPL','CIApprovedCC' ,'CIApprovedBD','CIRejected','CIRejectedBD')) as Underwritter,

--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr WITH(NOLOCK)
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr WITH(NOLOCK) join m_status m 
													 WITH(NOLOCK) on apr.fk_final_approval_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as DECISION_STATUS,

--cpl.DeviationLevelPL as [Level],
 (select top(1) m.name from pl_approval_information apr WITH(NOLOCK) inner join m_deviation_level m
														  WITH(NOLOCK) on apr.fk_deviation_level_id = m.pk_id and m.is_active =1
				 where apr.fk_application_information_id = ap.pk_id) as [Level],
 
--(case when cpl.PL_RejectReasonID <> null or cpl.PL_RejectReasonID <> '' then cpl.PL_RejectReasonID else cpl.PL_CancelReasonID end) as [Rejected or Cancelled Reasons], fk_reject_reason_id
(select top(1) m.name from pl_approval_information apr WITH(NOLOCK) inner join m_reason m
														  WITH(NOLOCK) on apr.fk_reject_reason_id = m.pk_id and m.is_active =1
				 where apr.fk_application_information_id = ap.pk_id) as [Rejected or Cancelled Reasons],

--cpl.Remark,
pap.remark as Remark,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr WITH(NOLOCK)
				 where apr.fk_application_information_id = ap.pk_id) as  [Loan_Amt_Approved],
--cpl.LoanTenor AS [Tenor (month)],
pap.loan_tenor_applied as [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
'' as Interest,
--CONVERT(varchar, CAST(cpl.SCB_PL_EMI AS MONEY), 1) AS [TotalEMI],
(select top(1)CONVERT(varchar, CAST(pl.scb_emi AS MONEY), 1) from pl_approval_information pl WITH(NOLOCK)
			     where pl.fk_application_information_id = ap.pk_id) AS [TotalEMI],

--CONVERT(varchar, CAST(cpl.TotalDSRForPL AS MONEY), 1) AS [TotalDBR (%)],
(select top(1)CONVERT(varchar, CAST(apr.total_dsr AS MONEY), 1) from pl_approval_information apr WITH(NOLOCK)
				 where apr.fk_application_information_id = ap.pk_id) as [TotalDBR (%)],

--CONVERT(varchar, CAST(cpl.MUE_PL AS MONEY), 1) AS [TotalMUE],
(select top(1)CONVERT(varchar, CAST(apr.mue AS MONEY), 1) from pl_approval_information apr WITH(NOLOCK)
				 where apr.fk_application_information_id = ap.pk_id) as [TotalMUE],

--dis.DisbursalStatus,
(select top(1) m.name from m_status m WITH(NOLOCK)
				     where dis.fk_status_id = m.pk_id) as DisbursalStatus,

--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
CONVERT(VARCHAR(24),dis.disbursed_date,106) as DisbursedDate,

--dis.LoanAccountNo,
dis.loan_account_number as LoanAccountNo,

--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m WITH(NOLOCK)
				     where ap.fk_m_status_id = m.pk_id) as CurrentStatus,

--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m WITH(NOLOCK)
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,

(Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,

--ap.PIDOfSaleStaff as SalesCode,
ap.sale_staff_bank_id as SalesCode,

--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as MobilePhone,

--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Customer Address]
(select top(1) (CASE WHEN cus.billing_address = 'Company address' 
	               THEN (co.company_name + ' - ' + co.Company_Address + ' - ' + co.company_ward + ' - ' + co.company_district + ' - ' + 
					(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) 
			ELSE
	          (CASE WHEN cus.billing_address = 'Permanent address' 
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 WITH(NOLOCK) where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 WITH(NOLOCK) where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))  AS [Customer Address]

FROM
	[dbo].[pl_application] pap  WITH(NOLOCK)
	inner join application_information ap WITH(NOLOCK) on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus WITH(NOLOCK) on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci WITH(NOLOCK) on ci.pk_id = cus.fk_customer_information_id
	LEFT JOIN pl_disbursement_information dis WITH(NOLOCK) ON dis.fk_application_information_id = ap.pk_id
	left join m_status  m WITH(NOLOCK) on pap.fk_status_id = m.pk_id and m.is_active = 1
	left join pl_company_information co WITH(NOLOCK) on co.fk_customer_information_id = ci.pk_id
WHERE 
  ((m.name in ('CIApproved', 'LODisbursed', 'CIApprovedBD', 'CIApprovedPL') and @TypeReport='ApprovedTracking')
	or (m.name in ('CIRejected', 'CIRejectedBD') and @TypeReport='RejectedTracking')
	or (m.name in ('CICancelled') and @TypeReport='CancelledTracking'))
	and Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	and (ap.fk_m_status_id = @StatusID or @StatusID = 0)
ORDER BY Seq





