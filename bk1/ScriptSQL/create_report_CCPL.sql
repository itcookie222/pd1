USE [LITSNEW]
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_actionlog]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_actionlog]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.Application_No,lg.Action_Date ASC) AS Seq,
ap.application_no as ApplicationNo,
lg.[action],
lg.action_by,
'' as ActionName,
CONVERT(VARCHAR(24),lg.action_date,13) as ActionDate
FROM
	[dbo].application_action_log lg 
	--left join LoginUser lu on lu.PeoplewiseID = lg.ActionBy
	inner join application_information ap on ap.pk_id = lg.fk_application_information_id
	inner join cc_application cap on ap.pk_id = cap.fk_application_information_id
	
WHERE
	cast(ap.received_date as date) >= cast(@Fromdate as date)
and cast(ap.received_date as date) <= cast(@Todate as date)
ORDER BY lg.fk_application_information_id,lg.action_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_actionlog_list_by_appno]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_cc_application_get_actionlog_list_by_appno]
	@appNo varchar(20)
AS
BEGIN

	select 
		a.[pk_id],
		--a.[ApplicationNo],
		(select top(1) ap.application_no from application_information ap
						where ap.pk_id = a.fk_application_information_id) as [ApplicationNo],
		a.[action],
		a.[action_by],
		a.[action_date],
		--u.[FullName] UserName
		'' as UserName
	from [dbo].application_action_log a WITH (NOLOCK)
	--left join [dbo].[LoginUser] u WITH (NOLOCK) 
	--on u.[PeoplewiseID] = a.[ActionBy] 
	where a.fk_application_information_id = @appNo	
	order by a.[action_date]

END

GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_admin_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_admin_audittrail]
	@Page varchar(30),
	@Table varchar(30),
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,pre_value as  prevalue
	,curr_value as  currvalue
	,CASE WHEN [log_type] LIKE (@Page + '::%::AddNew::%') THEN 'Add' 
		ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Update::%') THEN 'Update'
			ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Delete_Pending::%') THEN 'Delete'
				ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Approved::Delete::%') THEN 'Approved Delete'
					ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Approved::Active%') THEN 'Approved Active'
						ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Reject::%') THEN 'Reject'
							ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Upload::%') THEN 'Upload' END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(10), [updated_date], 101) + ' ' + CONVERT(VARCHAR(8), [updated_date], 108) as [updated_date]
	,[Updated_By] AS [Action_By]
FROM
	dbo.application_changed_log
WHERE ([log_type] LIKE (@Page + '::'+ @Table +'::%'))
	AND Cast([updated_date] as date) >= Cast(@FromDate as date)
	AND Cast([updated_date] as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_application_to_cancel_automatically]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_application_to_cancel_automatically]
	@DatetimeCancel datetime
AS

SELECT * FROM [dbo].[application_information] ap join m_status m on ap.fk_m_status_id = m.pk_id
WHERE m.name in ('SCCreated', 'OSSendBack', 'CISendbackSC') 
and DATEDIFF(D, ap.received_date, @DatetimeCancel) >= 30 
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_approved_applications]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_approved_applications]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
    ap.application_no as [Application No],
	CONVERT(VARCHAR(10), ap.Received_Date, 101) + ' ' + CONVERT(VARCHAR(8), ap.Received_Date, 108) as [Received Date],
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	ap.ProductTypeName AS [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id and m.is_active =1) as [Product Type],
--	cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--	ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as  [Channel],
--	ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
--	cc.full_name AS [Primary Card Holder Name],
cus.full_name AS [Primary Card Holder Name],
--	(
--		select top 1 IdentificationNo from CCIdentification 
--		where CustomerType='Primary' and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') and CustomerID=ap.CustomerID
--	) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],

	REPLACE(CONVERT(VARCHAR(11), cus.[DOB], 102), '.', '/') as [Primary Card Holder DOB],

--	ap.SCRemark as [SC Remark],
cap.sc_remark as [SC Remark],
--	ap.ARMCode,
ap.arm_code as ARMCode,
--	ap.SalesPWID as [Sale PWID],
ap.sale_staff_bank_id as [Sale PWID],
--	(
--		SELECT TOP 1 b.full_name FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID 
--		WHERE ap.application_no = ap.ap.application_no ORDER BY ActionDate
--	) AS [Created Name],

	'' AS [Created Name],

--	CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
CONVERT(VARCHAR(24),apr.decision_date,106) as DecisionDate,
--	cc.ResidentialAddress AS [Res Address],
cus.residential_address as [Res Address],
--	cc.ResidentialWard AS [Res ward],
cus.residential_ward as   [Res ward],
--	cc.ResidentialDistrict AS [Res District],
cus.residential_district as  [Res District],
--	cc.ResidentialCity AS [Residential City],
(select top(1) m1.name from m_city m1
							where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1) as [Residential City],
--	ccPL.Remark,
'' as Remark,
--	---------------------------------------
	SubCardfull_name.[1] AS [Subcard Full name 1],
	SubCardDOB.[1] AS [Subcard DOB 1],
	SubCardNationality.[1] AS [Subcard Nationality 1],
	---------------------------------------
	SubCardfull_name.[2] AS [Subcard Full name 2],
	SubCardDOB.[2] AS [Subcard DOB 2],
	SubCardNationality.[2] AS [Subcard Nationality 2],
	---------------------------------------
	SubCardfull_name.[3] AS [Subcard Full name 3],
	SubCardDOB.[3] AS [Subcard DOB 3],
	SubCardNationality.[3] AS [Subcard Nationality 3],
	---------------------------------------
	SubCardfull_name.[4] AS [Subcard Full name 4],
	SubCardDOB.[4] AS [Subcard DOB 4],
	SubCardNationality.[4] AS [Subcard Nationality 4]
--	---------------------------------------
	FROM [dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join m_status m on ap.fk_m_status_id = m.pk_id and m.is_active =1
	left join cc_approval_information apr on apr.fk_application_information_id = ap.pk_id
	outer apply(
		(select *
			from (select ap.application_no,ROWNUMBERS,full_name from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_subcard_application
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX(full_name) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
	) SubCardfull_name
	outer apply(
		(select *
			from (select ap.application_no,ROWNUMBERS,REPLACE(CONVERT(VARCHAR(11), [DOB], 102), '.', '/') as DOB from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_subcard_application
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX(DOB) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
	) SubCardDOB
	outer apply(
		(select *
			from (select ap.application_no,ROWNUMBERS,Nationality from 
				(select ROW_NUMBER() OVER (ORDER BY  sc.Created_Date ASC) AS ROWNUMBERS, m.name as Nationality
				  from cc_subcard_application sc inner join m_nationality m on sc.fk_nationality_id = m.pk_id and m.is_active = 1
				  where sc.fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX(Nationality) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
	) SubCardNationality

	WHERE
	   m.name in ('CIApproved', 'CIApprovedPL','LODisbursed')
	and	Cast(apr.decision_date as date) >= Cast(@FromDate as date)
	and Cast(apr.decision_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_audittrail_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_audittrail_ci]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 

ap.application_no as ApplicationNo,
CONVERT(VARCHAR(24),lg.action_date,106) as ModifiedDate,
lg.action_by as ModifiedBy,
'' as ModifiedByName,  -- from LoginUser
lg.[action] as ModifiedStatus,

--'' as verifiedposition,--cc.verifiedposition,
(select top(1)m.name from m_position m 
			   where  m.pk_id = cc.fk_verified_position_id) as verifiedposition,


--cc.occupationverified as VerifiedOccupation,
(select top(1)m.[description] from m_occupation m 
                        where m.pk_id = cc.fk_occupation_id) as VerifiedOccupation,

CONVERT(VARCHAR(24),cc.issued_date_residential_address,106) as IssuedDateOfResidentialAddress,
--cc.TypeOfContract as TypeOfContract,
(select top(1)m.name from m_labour_contract_type m
		  where m.pk_id = cc.fk_contract_type_id) as TypeOfContract,


(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as SpendingLimitSub1,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as SpendingLimitSub2,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as SpendingLimitSub3,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as SpendingLimitSub4,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as SpendingLimitSub5,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as SpendingLimitSub6,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as SpendingLimitSub7,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as SpendingLimitSub8,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as SpendingLimitSub9,

(select spending_limit from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application sc
		where sc.fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as SpendingLimitSub10


FROM
	[dbo].[application_information] ap join cc_customer_information cc on ap.pk_id = cc.fk_application_information_id
	left join _audit_application_action_log lg on lg.fk_application_information_id = ap.pk_id
    --left join dbo.LoginUser u on u.[PeoplewiseID] = lg.[ActionBy]
WHERE
	dbo._fGetShortDate(received_date) >= dbo._fGetShortDate(@FromDate)
and dbo._fGetShortDate(received_date) <= dbo._fGetShortDate(@ToDate)
ORDER BY lg.action_date
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_audittrail_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_audittrail_report]
	@FromDate datetime,
	@ToDate datetime
AS

BEGIN
	SELECT 
		ap.application_no as ApplicationNo,
		lg.pre_value as PreValue,
		lg.curr_value as CurrValue,
		lg.update_by as UpdateBy,
		lg.update_date as UpdateDate,
		lg.log_type as LodType

	FROM application_changed_log lg
		 left join application_information ap on lg.fk_application_information_id = ap.pk_id
		 left join m_type m on lg.fk_type_id = m.pk_id and m.name in('CC','CreditCard')
	WHERE (log_type like 'AuditTrailReport:CCSubCard:%'
		OR log_type like 'AuditTrailReport:CCCustomer:%'
		OR log_type like 'AuditTrailReport:CCPLApplication:%'
		OR log_type like 'AuditTrailReport:CCCustomerIncome:%'
		OR log_type like 'AuditTrailReport:CCCustomerBonu:%'
		OR log_type like 'AuditTrailReport:CCLoanBureau:%'
		OR log_type like 'AuditTrailReport:CCCreditBureau:%'
		OR log_type like 'AuditTrailReport:CCApplication:%')
	AND	Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
	ORDER BY ap.application_no, 
			CONVERT(smalldatetime, updated_date), 
			SUBSTRING(log_type, 0, LEN(log_type) - CHARINDEX(':',reverse(log_type), 0) + 1) desc
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_blacklist_company_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_blacklist_company_audittrail]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,[pre_value]
	,[curr_value]
	,CASE WHEN log_type LIKE 'BL_Manager::%::AddNew::%' THEN 'Add' 
		ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Update::%' THEN 'Update'
			ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Delete_Pending::%' THEN 'Delete'
				ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Approved::Delete::%' THEN 'Approved Delete'
					ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Approved::Active%' THEN 'Approved Active'
						ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Reject::%' THEN 'Reject'
							ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Upload::%' THEN 'Upload' END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(24),[updated_date],106) AS [updated_date]
	,[updated_by] AS [ActionBy]
FROM
	dbo.application_changed_log ML
	LEFT JOIN dbo.frm_black_list_company com 
	ON ((SELECT SUBSTRING(log_type, LEN(log_type) - 35, 36))) = CAST (com.pk_id AS VARCHAR(37))
WHERE log_type LIKE 'BL_Manager::BlackListCompany::%'
	AND Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_blacklist_customer_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_blacklist_customer_audittrail]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,[pre_value]
	,[curr_value]
	,CASE WHEN [log_type] LIKE 'BL_Manager::%::AddNew::%' THEN 'Add' 
		ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Update::%' THEN 'Update'
			ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Delete_Pending::%' THEN 'Delete'
				ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Approved::Delete::%' THEN 'Approved Delete'
					ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Approved::Active%' THEN 'Approved Active'
						ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Reject::%' THEN 'Reject'
							ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Upload::%' THEN 'Upload'
								ELSE (CASE WHEN [log_type] LIKE 'FRM_WorkInProgress::%::AddNew::%' THEN 'FRM Add' END)
							END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(24),[updated_date],106) AS [UpdatedDate]
	,[updated_by] AS [ActionBy]
FROM
	dbo.application_changed_log ML
WHERE (log_type LIKE 'BL_Manager::BlackListCustomer::%'
		OR log_type LIKE 'FRM_WorkInProgress::BlackListCustomer::%')
	AND Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_bureau_information_credit_card]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_bureau_information_credit_card]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
  CONVERT(VARCHAR(10), ap.Received_Date, 101) + ' ' + CONVERT(VARCHAR(8), ap.Received_Date, 108) as [Received Date],

--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
(Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,
--ap.Application_No,
 ap.Application_No as ApplicationNo,
--(SELECT TOP 1 ActionBy FROM AppActionLog alog WHERE alog.ap.Application_No = ap.ap.Application_No ORDER BY ActionDate DESC) AS CreatedBy,
(SELECT TOP 1 action_by FROM application_action_log alog WHERE alog.fk_application_information_id = ap.pk_id ORDER BY action_date	 DESC) AS CreatedBy,
--ap.SpecialCode,
cap.special_code as SpecialCode,
--ap.ProductTypeName AS [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id and m.is_active =1) AS [Product Type],
--ap.TypeApplicationName AS [Application Type],
cap.type_of_application as [Application Type],
--ap.CardProgramName AS [Card Program],
(select top(1) cp.name from  cc_card_program cp
				where cap.fk_card_program_id = cp.pk_id) as [Card Program],
--ap.ProgramCodeName AS [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName AS [Card Type],
(select top(1)ct.name from cc_card_type ct
				where  cap.fk_card_type_1_id = ct.pk_id) as [Card Type],
--ap.CardTypeName2 AS [Card Type 2],
(select top(1)ct.name from cc_card_type ct
				where  cap.fk_card_type_2_id = ct.pk_id) as [Card Type 2],
--cc.CustomerSegment,
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as CustomerSegment,
--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
--ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as [Channel],
--ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as  [Branch Location],
--ap.ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentType,
--cc.FullName AS [Primary Card Holder Name],
cus.full_name as [Primary Card Holder Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Type Of Identification],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary Card Holder ID],
--cc.CompanyName,
co.company_name as CompanyName,
--cc.CompanyCode,
co.company_code as CompanyCode,
--cc.RLSCompanyCode,
co.company_code_rls asRLSCompanyCode,
--ap.CreditBureauType AS [Bureau Type],
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--cc.IncomeType,
(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as incomeType,
--cc.MonthlyIncomeDeclared AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.HolderInitial AS [Initial Limit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],

--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PLFinalLoanAmountApproved ELSE ap.FinalLimitApproved END) AS [Final Approved Limit],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PL_FinalApprovalStatus ELSE ap.FinalApprovalStatus END) AS [Final Approval Status],
(select top(1)  m.name
				from cc_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],
--ap.DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,
--ap.Status AS [Current Status],
(select top(1) m.name from m_status m
					  where ap.fk_m_status_id = m.pk_id) as [Current Status],
-----------------------------------------
CCSecuredType.[1] AS [Other Credit Card Secured Type_1],
CCLimit.[1] AS [Other Credit Card Limit_1],
CCOutstanding.[1] AS [Other Credit Card Outstanding_1],
CCInterestRate.[1] AS [Interest Rate_1],
CCEMI.[1] AS [EMI_1],
CCSource.[1] AS [Source_1],
CCBank.[1] AS [Issued Bank_1],
---------------------------------------
CCSecuredType.[2] AS [Other Credit Card Secured Type_2],
CCLimit.[2] AS [Other Credit Card Limit_2],
CCOutstanding.[2] AS [Other Credit Card Outstanding_2],
CCInterestRate.[2] AS [Interest Rate_2],
CCEMI.[2] AS [EMI_2],
CCSource.[2] AS [Source_2],
CCBank.[2] AS [Issued Bank_2],
---------------------------------------
CCSecuredType.[3] AS [Other Credit Card Secured Type_3],
CCLimit.[3] AS [Other Credit Card Limit_3],
CCOutstanding.[3] AS [Other Credit Card Outstanding_3],
CCInterestRate.[3] AS [Interest Rate_3],
CCEMI.[3] AS [EMI_3],
CCSource.[3] AS [Source_3],
CCBank.[3] AS [Issued Bank_3]
-----------------------------------------

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_cc_customer_information_id = cus.pk_id
	outer apply(
		(select *
			from (select ap.Application_No, ROWNUMBERS, Secured_Type from 
				  (select ROW_NUMBER() OVER (ORDER BY br.created_date ASC) AS ROWNUMBERS,* 
				     from cc_card_bureau br  
				  where br.fk_application_information_id = ap.pk_id)x ) SourceTable
		PIVOT(MAX(Secured_Type) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSecuredType
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS, total_limit from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX(total_limit) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCLimit
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Outstanding] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Outstanding]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCOutstanding
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[interest_rate] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Interest_Rate]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInterestRate
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[EMI] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([EMI]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCEMI
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Source] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Source]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSource
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Bank] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from cc_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Bank]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCBank

WHERE Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_bureau_information_loan]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_bureau_information_loan]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
 (Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--(SELECT TOP 1 ActionBy FROM AppActionLog alog WHERE alog.ApplicationNo = ap.ApplicationNo ORDER BY ActionDate DESC) AS CreatedBy,
(SELECT TOP 1 action_by FROM Application_Action_Log alog 
					   WHERE alog.fk_application_information_id = ap.pk_id
 ORDER BY Action_Date DESC) AS CreatedBy,
--ap.SpecialCode,
  cap.special_code as SpecialCode,
--ap.ProductTypeName AS [Product Type],
   (select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id and m.is_active =1) as [Product Type],
--ap.TypeApplicationName AS [Application Type],
cap.type_of_application as [Application Type],
--ap.CardProgramName AS [Card Program],
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],
--ap.ProgramCodeName AS [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName AS [Card Type],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],
--ap.CardTypeName2 AS [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

--cc.CustomerSegment,
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as CustomerSegment,
--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
--ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as [Channel],
--ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
--ap.ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentType,
--cc.FullName AS [Primary Card Holder Name],
cus.full_name as [Primary Card Holder Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Type Of Identification],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],
--cc.CompanyName,
co.company_name as CompanyName,
--cc.CompanyCode,
co.company_code as CompanyCode,
--cc.RLSCompanyCode,
co.company_code_rls asRLSCompanyCode,
--ap.CreditBureauType AS [Bureau Type],
 (select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--cc.IncomeType,
(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as incomeType,
--cc.MonthlyIncomeDeclared AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.HolderInitial AS [Initial Limit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PLFinalLoanAmountApproved ELSE ap.FinalLimitApproved END) AS [Final Approved Limit],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PL_FinalApprovalStatus ELSE ap.FinalApprovalStatus END) AS [Final Approval Status],
(select top(1)  m.name
				from cc_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

--ap.DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,
--ap.Status AS [Current Status],
(select top(1) m.name from m_status m
					  where ap.fk_m_status_id = m.pk_id) as [Current Status],
-----------------------------------------
CCSecuredType.[1] AS [Other Loan Secured Type_1],
CCInitialLoan.[1] AS [Other Initial Loan_1],
CCTenor.[1] AS [Other Tenor_1],
CCInterestRate.[1] AS [Interest Rate_1],
CCOutstanding.[1] AS [Outstanding_1],
CCEMI.[1] AS [EMI_1],
CCSource.[1] AS [Source_1],
---------------------------------------
CCSecuredType.[2] AS [Other Loan Secured Type_2],
CCInitialLoan.[2] AS [Other Initial Loan_2],
CCTenor.[2] AS [Other Tenor_2],
CCInterestRate.[2] AS [Interest Rate_2],
CCOutstanding.[2] AS [Outstanding_2],
CCEMI.[2] AS [EMI_2],
CCSource.[2] AS [Source_2],
---------------------------------------
CCSecuredType.[3] AS [Other Loan Secured Type_3],
CCInitialLoan.[3] AS [Other Initial Loan_3],
CCTenor.[3] AS [Other Tenor_3],
CCInterestRate.[3] AS [Interest Rate_3],
CCOutstanding.[3] AS [Outstanding_3],
CCEMI.[3] AS [EMI_3],
CCSource.[3] AS [Source_3]
-----------------------------------------

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_application_information_id = ap.pk_id
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[secured_type] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id) x) SourceTable
		PIVOT(MAX([Secured_Type]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSecuredType
	outer apply(
		(select *
			from (select ApplicationNo,ROWNUMBERS,[initial_loan] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Initial_Loan]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInitialLoan
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Tenor] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Tenor]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCTenor
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Outstanding] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Outstanding]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCOutstanding
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[interest_rate] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Interest_Rate]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInterestRate
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[EMI] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([EMI]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCEMI
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Source] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from cc_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Source]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSource

WHERE 
Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_calling_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_calling_report]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo,
--CONVERT(VARCHAR(24),ckl.ExpectedDisbursedDate,106) as [Expected Disbursed Date],
--CONVERT(varchar, CAST(ckl.ExpectedDisbursedAmount AS MONEY), 1) AS [Expected Disbursed Amount],
--ckl.SalaryDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
--dis.LoanAccountNo,
--ckl.CallTimeList,
--ckl.CycleDueDay,
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],
--CONVERT(VARCHAR(24),ckl.CreatedDate,106) as [Created Date],  
--ckl.CreatedBy,
--ckl.Status,
--ckl.MSO,
--ckl.PendingReason,
--ckl.PendingMark,
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as [Disbursed Date],
--cc.FullName as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
--cc.PrimaryPhoneNo as MobilePhone,
--Convert(varchar,Convert(money,cpl.PLSuggestedInterestRate),1) AS [ECFinalLoanInterest],
--cpl.LoanTenor as [ECLoanTenor],
--Convert(varchar,Convert(money,ckl.ExpectedDisbursedAmount),1) AS [ECLoanAmountApproved],
--ap.ChannelD,
--ap.LocationBranchName
--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	LEFT JOIN CCPLApplication cpl ON cpl.CCApplicationNo = ap.ApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
--	LEFT JOIN CustomerCallCheckList ckl on ckl.ApplicationNo = ap.ApplicationNo
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_company_information]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_report_cc_application_get_company_information]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	--select cap.* into #tbl_CCApplication from [CC_Application] cap with (nolock) join application_information ap with (nolock) 
	--								   on cap.fk_application_information_id = ap.pk_id
	--  WHERE ap.received_date >= @FromDate and ap.received_date <= @ToDate	

	--select cus.* into #tbl_CCCustomer from [cc_customer_information] cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select cus.* into customer_identification from customer_identification cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Pending'
	
	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Tele'

	--select a.* into application_action_log from application_action_log a with (nolock) inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id

	--select a.* into #tbl_CCRemark from [CC_Remark] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
	(CASE WHEN ap.is_vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
	ap.Application_No as [Application No],
	(SELECT TOP 1 l.[Action_By] FROM application_action_log l 
							   WHERE l.fk_application_information_id = ap.pk_id ORDER BY l.action_date) AS CreatedBy,
	--(
	--	SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID
	--	WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
	--) AS CreatedName,
	'' AS CreatedName,

	cap.special_code as [Special Code],

	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
	--ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],

	--ap.TypeApplicationName as [Application Type],
	cap.type_of_application as [Application Type],

	--ap.CardProgramName as [Card Program],
	(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],

	--BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ci..Channe_lD as Channel,
	(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

	--ap.IsTwoCardType as [IsTwoCardType],
	cap.is_two_card_type as [IsTwoCardType],

	--cus.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cus.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

	--(select top 1 TypeOfIdentification from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of Identification],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],

	--CONVERT(VARCHAR(10), cus.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.dob, 101) as [Primary Card Holder DOB],

	--cus.Nationality as [Primary Card Holder Nationality],
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as [Primary Card Holder Nationality],

	--cus.EmailAddress1 as [Email Address 1],
	cus.email_address_1 as [Email Address 1],

	--cus.EmailAddress2 as [Email Address 2],
	cus.email_address_1 as [Email Address 2],

	--cus.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
	(select top(1) cus.primary_phone_no from cc_customer_information cus
				where cus.fk_application_information_id = ap.pk_id) as [Primary Card Holder Mobile Phone Number],

	--cus.TypeEmployment as [Type Employment], --m_employment_type ???
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

	--cus.OperationSelfEmployed as [Employment Type],
	(select top(1) m.name from cc_customer_information cus inner join m_definition_type m on 
																	cus.fk_operation_self_employed_id = m.pk_id AND m.fk_group_id = 69 and m.is_active = 1
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cus.CurrentPosition as [Current Position],
	(select top(1)m.name from  m_position m 
						 where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cus.Occupation, fk_occupation_id
	(select top(1) m.name from m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cus.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cus.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

	--cus.CompanyName as [Company Name],
	co.company_name as  [Company Name],

	--cus.CompanyCode as [Company Code],
	co.company_code as [Company Code],

	--cus.RLSCompanyCode as [Company Code RLS],
	co.company_code_rls  as [Company Code RLS],

	--cus.BusinessType as [Company Type],
	(select top(1) m.name from m_business_nature m
						 where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],

	--cus.CompanyAddress as [Company Address],
	co.company_address as [Company Address],

	--cus.CompanyPhone as [Company Office], ???
	co.office_telephone  as [Company Office],

	--ap.CreditBureauType as [Bureau Type], 
	(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = cus.pk_id) as [Bureau Type],

	--cus.IncomeType as [Income Type], cc_customer_income
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],

	--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],

	--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

	--FinalApprovalStatus as [Final Approval Status],
	(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

	--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

	--(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

	--ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],

	--ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,

	--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],

	--(select count(1) from CCSubCard sc where sc.ApplicationNo=ap.ApplicationNo) as SupplementaryCardNo, 
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and [Action]='OSSendBack') as [Times sendback by OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],
	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

	--(select Scenario from DisbursalScenario where ID = ap.DisbursementScenarioId) as [Pre-disbursement condition Scenario], cc_disbursement_condition ???
	(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
					on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition Scenario],

	--ap.DisbursementScenarioText as [Pre-disbursement condition],	 ???
	(select top(1)md.pre_condition_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
								on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					inner join m_disbursal_scenario_condition  md
								on md.fk_m_disbursal_scenario_id = m.pk_id
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=1) as [CC Remark 1], ???
	'' as  [CC Remark 1],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=2) as [CC Remark 2], ???
	'' as  [CC Remark 2],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=3) as [CC Remark 3], ???
	'' as  [CC Remark 3],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id 
								     and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)) as [Pending Log Sendback reason 1],
					
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x
	--where x.ROWNUMBERS=1) as [Pending Log Remark 1],

	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Remark 1],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--ap.SCRemark as [SC Remark],
	cap.sc_remark as [SC Remark],

	--ap.OpsRemark as [Ops Remark],
	cap.ops_remark as [Ops Remark],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101)  as [Pending Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101) as [Pending Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Response By 1],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Sendback send from 1],

	--------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)) as [Pending Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101)  as [Pending Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)  as [Pending Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101) as [Pending Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Sendback send from 2],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending') x 
		               where x.ROWNUMBERS = 3)) as [Pending Log Sendback reason 3],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101)  as [Pending Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101) as [Pending Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Sendback send from 3],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)) as [Pending Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101)  as [Pending Log Sendback date 4],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101) as [Pending Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Sendback send from 4],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)) as [Pending Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101)  as [Pending Log Sendback date 5],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101) as [Pending Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Response By 5],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	--------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Sendback send from 5],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)) as [Tele Log Sendback reason 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark 1],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark 1],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101)  as [Tele Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)  as [Tele Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101) as [Tele Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Response By 1],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Sendback send from 1],

	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)) as [Tele Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101)  as [Tele Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)  as [Tele Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101) as [Tele Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Sendback send from 2],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)) as [Tele Log Sendback reason 3],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101)  as [Tele Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)  as [Tele Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101) as [Tele Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Sendback send from 3],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)) as [Tele Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101)  as [Tele Log Sendback date 4],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)  as [Tele Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101) as [Tele Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Sendback send from 4],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)) as [Tele Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101)  as [Tele Log Sendback date 5],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)  as [Tele Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101) as [Tele Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Response By 5],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Sendback send from 5],
	--cus.Gender,
	
	(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.fk_group_id = 38) as Gender,

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID') 
	--ORDER BY TypeOfIdentification) as [Expried Date For ID],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('ID')
					order by mit.name) as [Expried Date For ID],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Visa],
	(select top(1)CONVERT(VARCHAR(10), id.identification_no, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Visa],

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Expried Date For Visa],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Expried Date For Visa],

	--cus.MaritalStatus, 
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id) as MaritalStatus,
	--cus.Nationality,
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,
	--ap.AccountNumber, 
	ap.application_no as AccountNumber, 

	--ap.PaymentMethod,
	
	(select top(1)m.name from m_payment_type m
					where ap.fk_m_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,

	--cus.OwnerResidentialAdd as [Ownership],
	cus.owner_residential_address as [Ownership],

	--ap.HolderCurrencyDepositedAmount as [Deposit Amount],
	cap.holder_currency_deposited_amount as [Deposit Amount],

	--ap.HolderCurrentAccountNo as [Current Acc],
	cap.holder_current_account_no as [Current Acc],

	--ap.HolderDepositedCurrency as [Currency],
	(select top(1)m.name from m_definition_type m
					    where cap.fk_holder_deposited_currency_id = m.pk_id 
					          and fk_group_id =77 and m.is_active = 1) as [Currency],

	--cus.CompanyGenericCode as [Company Generic Code],
	
	(select top(1) co.company_code from company_information co
					where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Generic Code],

	--cus.CompanyAddress + ' ' + cus.CompanyWard + ' ' + cus.CompanyDistrict + ' ' + CompanyCity as [Company Full Address],
	(select top(1) co.company_address + ' ' + co.company_ward + ' ' + co.company_district
					 + ' ' + co.company_city
	               from company_information co
				   where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Full Address],
	--CONVERT(varchar, CAST([FinalIncome] AS MONEY), 1)  as [Final Monthly Income]
	(select top(1)CONVERT(varchar, CAST(cin.final_income AS MONEY), 1)  from cc_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Final Monthly Income]
	FROM
		cc_application cap 
		inner join application_information ap on cap.fk_application_information_id = ap.pk_id
		inner join cc_customer_information cus on cap.fk_application_information_id = cus.fk_application_information_id 
		inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
		left join cc_company_information co on co.fk_customer_income_id = ci.pk_id

	WHERE ap.fk_m_type_id = 11
	and	cast(ap.Received_Date as date) >= cast (@FromDate as date)
	and cast (Received_Date as date) <= cast (@ToDate as date)
	ORDER BY Seq

	--drop table #tbl_CCApplication
	--drop table cc_rework
	--drop table cc_rework
	--drop table #tbl_CCCustomer
	--drop table customer_identification
	--drop table application_action_log	
	--drop table #tbl_CCRemark
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_custody_mis_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_custody_mis_report]
	@FromDate datetime,
	@ToDate datetime,
	@ProductTypeName varchar(100)
AS

SELECT ROW_NUMBER() OVER (ORDER BY custody.update_date ASC) AS Seq,
--	ap.EOpsTxnRefNo,
    ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	ap.EOpsTxnRefNo2,
	ap.eops_txn_ref_no_2 as EOpsTxnRefNo2,
--	ap.ProductTypeName AS [Product Type],
	m.name as [Product Type],
--	cust.FullName AS [Customer Name],
    cus.full_name as [Customer Name],
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,

-- ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) AS [Branch Location],

--	STUFF((SELECT '. ' + IdentificationNo AS [text()]
--				FROM CCIdentification ccID
--				WHERE ccID.CustomerID = cust.ID
--				FOR XML PATH('')), 1, 1, '' )
--	AS [IdentificationNo],

	STUFF((SELECT '. ' + ccID.identification_no AS [text()]
				FROM customer_identification ccID
				WHERE ccID.fk_customer_information_id = cus.fk_customer_information_id
				FOR XML PATH('')), 1, 1, '' )
	AS [IdentificationNo],

--	ap.TypeApplicationName AS [Type of Application],
	cap.type_of_application as [Type of Application],
--	ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS [Channel],

--	ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--	ap.Status AS [Application Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) AS [Application Status],
--	doc.DocumentName,
doc.document_name as  DocumentName,

--	(CASE WHEN IsSubmited = 1 THEN 'Yes' ELSE 'No' END) AS [IsSubmited],
(CASE WHEN is_submited = 1 THEN 'Yes' ELSE 'No' END) AS [IsSubmited],
--	(CASE WHEN IsSubmited = 1 THEN CONVERT(VARCHAR(14), doc.SubmitedDate, 107) ELSE null END) AS [Submitted Date],
(CASE WHEN is_submited = 1 THEN CONVERT(VARCHAR(14), doc.submited_date, 107) ELSE null END) AS [Submitted Date],
--	(CASE WHEN IsSubmited = 1 THEN doc.SubmitedBy ELSE null END) AS [SubmitedBy],
(CASE WHEN is_submited = 1 THEN doc.submited_by ELSE null END) AS [SubmitedBy],
--	(CASE WHEN IsReceived = 1 THEN 'Yes' ELSE 'No' END) AS [IsReceived],
(CASE WHEN Is_Received = 1 THEN 'Yes' ELSE 'No' END) AS [IsReceived],
--	(CASE WHEN IsReceived = 1 THEN CONVERT(VARCHAR(14), doc.ReceivedDate, 107) ELSE null END) AS [Received Date],
(CASE WHEN is_received = 1 THEN CONVERT(VARCHAR(14), doc.received_date, 107) ELSE null END) AS [Received Date],
--	(CASE WHEN IsReceived = 1 THEN doc.ReceivedBy ELSE NULL END) AS ReceivedBy,
(CASE WHEN is_received = 1 THEN doc.received_by ELSE NULL END) AS ReceivedBy,
--	(CASE WHEN IsRequired = 1 THEN 'Yes' ELSE 'No' END) AS [IsRequired],
(CASE WHEN is_required = 1 THEN 'Yes' ELSE 'No' END) AS [IsRequired],
--	STUFF((SELECT '. ' + Remark AS [text()]
--				FROM CustodyRemark remark
--				WHERE remark.CustodyID = Custody.ID
--				FOR XML PATH('')), 1, 1, '' )
--	AS [Remark]

	STUFF((SELECT '. ' + Remark AS [text()]
				FROM application_custody_remark remark
				WHERE remark.fk_application_custody_id = Custody.pk_id
				FOR XML PATH('')), 1, 1, '' ) AS [Remark]
FROM  application_custody custody
	  inner join cc_application cap on custody.fk_application_information_id = cap.fk_application_information_id
	  inner join application_information ap on cap.fk_application_information_id = ap.pk_id
	  inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	  inner join application_custody_document doc on doc. fk_application_custody_id = custody.pk_id
	  inner join m_type m on m.pk_id = custody.fk_type_id
	--LEFT JOIN CCApplication ap ON ap.ApplicationNo = Custody.ApplicationNo
	--LEFT JOIN CCCustomer cust ON cust.ID = ap.CustomerID
	--LEFT JOIN CustodyDocument doc ON doc.CustodyID = Custody.ID
WHERE
	Cast(custody.update_date as date) >= Cast(@FromDate as date)
AND Cast(custody.update_date as date) <= Cast(@ToDate as date)
AND m.name = @ProductTypeName
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_customers]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_customers]
	@FromDate datetime,
	@ToDate datetime
AS

  SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,

--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--cc.Full_Name as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--ap.CardTypeName as CardType1,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as CardType1,
--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,
--ap.ProgramCodeName as ProgramCodeName,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCodeName,
--cc.Full_Name as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),cus.DOB,106) as PrimaryCardHolderDOB,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select top 1  IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--cc.Gender as Gender,
(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.is_active = 1 and m.fk_group_id = 38) as Gender,
--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no AS MobilePhone,

--(cc.PermAddress + ' ' + cc.PermWard + ' ' + cc.PermDistrict + ' ' + cc.PermCity) as PrimaryCardHolderPermanentAddress,
(cus.permanent_address + ' ' + cus.permanent_ward + ' ' + cus.permanent_district + ' ' + 
(select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1)) as PrimaryCardHolderPermanentAddress,

--(cc.ResidentialAddress + ' ' + cc.ResidentialWard + ' ' + cc.ResidentialDistrict + ' ' + cc.ResidentialCity) as PrimaryCardHolderHomeAddress,
(cus.residential_address + ' ' + cus.residential_ward + ' ' + cus.residential_district + ' ' + 
(select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) as PrimaryCardHolderHomeAddress,

--cc.HomePhoneNo as HomePhoneNo,
cus.home_phone_no as  HomePhoneNo,
--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--(cc.CompanyAddress + ' ' + cc.CompanyWard + ' ' + cc.CompanyDistrict + ' ' + cc.CompanyCity) as CompanyAddress,
(co.Company_Address + ' ' + co.Company_Ward + ' ' + co.Company_District + ' ' + 
(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) as CompanyAddress,
--cc.CompanyPhone as CompanyPhone,
co.office_telephone as CompanyPhone,
--ccPL.LoanPurpose,
(select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as  LoanPurpose,
-----------1
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as SubCardFull_Name1,

CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1),106) as SubCardDOB1,	
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select fk_customer_information_id from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=1)) as SubCardHolderID1,

(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=1)) as SubCardHolderID1,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as RelationshipWithPrimary1,

---------2
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as SubCardFull_Name2,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2),106) as SubCardDOB2,	
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=2)) as SubCardHolderID2,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=2)) as SubCardHolderID2,


--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=2) as RelationshipWithPrimary2,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as RelationshipWithPrimary2,

---------3
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as SubCardFull_Name3,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3),106) as SubCardDOB3,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=3)) as SubCardHolderID3,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=3)) as SubCardHolderID3,
--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=3) as RelationshipWithPrimary3,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as RelationshipWithPrimary3,
---------4
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as SubCardFull_Name4,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4),106) as SubCardDOB4,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=4)) as SubCardHolderID4,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
											(select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=4)) as SubCardHolderID4,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
---------5
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as SubCardFull_Name5,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5),106) as SubCardDOB5,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=5)) as SubCardHolderID5,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
											(select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=5)) as SubCardHolderID5,


--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=5) as RelationshipWithPrimary5,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as RelationshipWithPrimary5,

null as RelativeName,
null as RelativeFixedPhone,
null as RelativeMobileNo
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
	    Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_customers_information]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_customers_information]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
ROW_NUMBER() OVER (ORDER BY  Received_Date ASC) AS Seq,
CONVERT(VARCHAR(24),ap.Received_Date,106) as Received_Date,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as CardType,
--ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

--ap.CardProgramName as CardProgram,
(select top(1)ca.name from cc_card_program ca
					where cap.fk_card_program_id = ca.pk_id and ca.is_active =1) as CardProgram,

--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),cus.dob,106) as PrimaryCardHolderDOB,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select top 1  IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,
--cc.Gender as Gender,
(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.fk_group_id = 38 and m.is_active =1) as Gender,
--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Nationality],
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as  MobilePhone,

--(cc.PermAddress + ' ' + cc.PermWard + ' ' + cc.PermDistrict + ' ' + cc.PermCity) as PrimaryCardHolderPermanentAddress,
(cus.permanent_address + ' ' + cus.permanent_ward + ' ' + cus.permanent_district + ' ' + 
(select top(1) m1.name from m_city m1 
					   where cus.fk_permanent_city_id = m1.pk_id 
					   and m1.is_active =1 and m1.fk_group_id =66)) as PrimaryCardHolderPermanentAddress,

--(cc.ResidentialAddress + ' ' + cc.ResidentialWard + ' ' + cc.ResidentialDistrict + ' ' + cc.ResidentialCity) as PrimaryCardHolderHomeAddress,

(cus.residential_address + ' ' + cus.residential_ward + ' ' + cus.residential_district + ' ' +
(select top(1) m1.name from m_city m1 
						where cus.fk_permanent_city_id = m1.pk_id 
						and m1.is_active =1 and m1.fk_group_id =64)) as PrimaryCardHolderHomeAddress,

--cc.HomePhoneNo as HomePhoneNo,
cus.home_phone_no as HomePhoneNo,
--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--(cc.CompanyAddress + ' ' + cc.CompanyWard + ' ' + cc.CompanyDistrict + ' ' + cc.CompanyCity) as CompanyAddress,
(co.company_address + ' ' + co.company_ward + ' ' + co.company_district + ' ' + 
	(select top(1) m1.name from m_city m1 
						   where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) as CompanyAddress,
--cc.CompanyPhone as CompanyPhone,
co.office_telephone as CompanyPhone,
-----------1

--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=1) as SubCardFullName1,
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as SubCardFullName1,

--CONVERT(VARCHAR(24), (select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=1),106) as SubCardDOB1,	
	CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1),106) as SubCardDOB1,

--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--													from CCSubCard scard
--													where ApplicationNo=ap.ApplicationNo)x 
--												where x.ROWNUMBERS=1)) as SubCardHolderID1,
(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=1)) as SubCardHolderID1,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=1) as RelationshipWithPrimary1,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_group m on m.pk_id = scard.fk_relationship_with_primary_id 
															and m.pk_id = 60 and m.is_active =1
										inner join m_definition_type md on md.fk_group_id = m.pk_id 
															and md.is_active =1
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=1) as RelationshipWithPrimary1,

-----------2
--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=2) as SubCardFullName2,
	(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as SubCardFullName2,

--CONVERT(VARCHAR(24),(select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=2),106) as SubCardDOB2,	
	CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2),106) as SubCardDOB2,
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--													from CCSubCard scard
--													where ApplicationNo=ap.ApplicationNo)x 
--												where x.ROWNUMBERS=2)) as SubCardHolderID2,
(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=2)) as SubCardHolderID2,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=2) as RelationshipWithPrimary2,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_group m on m.pk_id = scard.fk_relationship_with_primary_id 
															and m.pk_id = 60 and m.is_active =1
										inner join m_definition_type md on md.fk_group_id = m.pk_id 
															and md.is_active =1
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=2) as RelationshipWithPrimary2,

-----------3
--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=3) as SubCardFullName3,
	(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as SubCardFullName3,

--CONVERT(VARCHAR(24),(select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=3),106) as SubCardDOB3,
	CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3),106) as SubCardDOB3,
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--													from CCSubCard scard
--													where ApplicationNo=ap.ApplicationNo)x 
--												where x.ROWNUMBERS=3)) as SubCardHolderID3,
(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=3)) as SubCardHolderID3,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=3) as RelationshipWithPrimary3,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_group m on m.pk_id = scard.fk_relationship_with_primary_id 
															and m.pk_id = 60 and m.is_active =1
										inner join m_definition_type md on md.fk_group_id = m.pk_id 
															and md.is_active =1
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=3) as RelationshipWithPrimary3,

-----------4
--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=4) as SubCardFullName4,
	(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as SubCardFullName4,

--CONVERT(VARCHAR(24),(select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=4),106) as SubCardDOB4,
	CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4),106) as SubCardDOB4,
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--													from CCSubCard scard
--													where ApplicationNo=ap.ApplicationNo)x 
--												where x.ROWNUMBERS=4)) as SubCardHolderID4,

(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=4)) as SubCardHolderID4,
--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_group m on m.pk_id = scard.fk_relationship_with_primary_id 
															and m.pk_id = 60 and m.is_active =1
										inner join m_definition_type md on md.fk_group_id = m.pk_id 
															and md.is_active =1
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
-----------5
--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=5) as SubCardFullName5,
	(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as SubCardFullName5,
--CONVERT(VARCHAR(24),(select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=5),106) as SubCardDOB5,
	CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5),106) as SubCardDOB5,
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--													from CCSubCard scard
--													where ApplicationNo=ap.ApplicationNo)x 
--												where x.ROWNUMBERS=5)) as SubCardHolderID5,
(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=5)) as SubCardHolderID5,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * 
--     from CCSubCard scard
--		where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=5) as RelationshipWithPrimary5,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_group m on m.pk_id = scard.fk_relationship_with_primary_id 
															and m.pk_id = 60 and m.is_active =1
										inner join m_definition_type md on md.fk_group_id = m.pk_id 
															and md.is_active =1
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=5) as RelationshipWithPrimary5,

null as RelativeName,
null as RelativeFixedPhone,
null as RelativeMobileNo
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_disbursed_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_disbursed_reports]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as [Receiving Date],
--cc.FullName as Customer_Name,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as [Disbursed Date],
--CONVERT(varchar, CAST(cpl.SCB_PL_EMI AS MONEY), 1) AS [EMI],
--Convert(varchar,Convert(money,cpl.PLSuggestedInterestRate),1) AS Interest,
--cpl.LoanTenor AS [Tenor (month)],
--dis.LoanAccountNo,
--ckl.RepayAccount,
--ckl.CycleDueDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
--cc.PrimaryPhoneNo as MobilePhone,
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],
--cc.EmailAddress1,
--cc.EmailAddress2
--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	LEFT JOIN CCPLApplication cpl ON cpl.CCApplicationNo = ap.ApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
--	LEFT JOIN CustomerCallCheckList ckl on ckl.ApplicationNo = ap.ApplicationNo
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and ap.[Status] = 'LODisbursed'
--and	dbo._fGetShortDate(dis.DisbursedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(dis.DisbursedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_disbursement_pending]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_disbursement_pending]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as [Receiving Date],
--cc.FullName as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
--cc.PrimaryPhoneNo as MobilePhone,
----PendingReason
--cpl.LoanTenor AS [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
----AmountApproved_WithMRTA
----ApprovedDate
--cc.PaymentType as PaymentMethod,
--CONVERT(VARCHAR(24),ckl.ExpectedDisbursedDate,106) as [Expected Disbursed Date],
--CONVERT(varchar, CAST(ckl.ExpectedDisbursedAmount AS MONEY), 1) AS [Expected Disbursed Amount],
--ckl.CycleDueDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
--ckl.RepayAccount,
----Customer_Address
--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],
--ap.ProgramCodeName as ProgramCode,
--ap.LocationBranchName,
----SaleChannel	  
--ap.Status as CurrentStatus
--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	LEFT JOIN CCPLApplication cpl ON cpl.CCApplicationNo = ap.ApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
--	LEFT JOIN CustomerCallCheckList ckl on ckl.ApplicationNo = ap.ApplicationNo
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_email_verification_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_email_verification_report]
	@FromDate datetime,
	@ToDate datetime
AS
 SELECT
 CONVERT(VARCHAR(24),ap.received_date,13) as ReceivedDate,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
 --ev.CustomerName as FullName,
 cus.full_name as FullName,
  --ccId.IdentificationNo as IDPP,
  ccId.identification_no as IDPP,
-- CONVERT(VARCHAR(24),cc.DOB,105)as DOB,
CONVERT(VARCHAR(24),cus.DOB,105)as DOB,
-- ap.ProductTypeName, 
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id)  as ProductTypeName,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
-- ev.CompanyEmail,
 ev.company_email as CompanyEmail,
-- evStatus.EVStatus as EmailVerificationStatus,
  evStatus.ev_status_name as EmailVerificationStatus,
-- CONVERT(VARCHAR(24),ev.FirstSendDateEV,13)as FirstDateSentEmail, 
CONVERT(VARCHAR(24),ev.first_send_date,13)as FirstDateSentEmail, 
--ev.FirstEVResult as FirstVerificationResult,
 ev.first_result as FirstVerificationResult,
--firstrpl.ReplyContent as FirstRepliedEmailContent,
firstrpl.[description] FirstRepliedEmailContent,
--ev.CreatedBy,
ev.created_by as CreatedBy,
-- CONVERT(VARCHAR(24),ev.SecondSendDateEV,13) as SecondDateSentEmail,
CONVERT(VARCHAR(24),ev.second_send_date,13) as SecondDateSentEmail,
--CONVERT(VARCHAR(24),ev.ManualSendDateEV,13) as DateSentManual,
CONVERT(VARCHAR(24),ev.manual_send_date,13) as DateSentManual,
-- ev.ManualEVResult as ManualVerificationResult,
 ev.manual_result_name as ManualVerificationResult,
--  manualrpl.ReplyContent as ManualRepliedContent, 
 manualrpl.[description] as ManualRepliedContent, 
--ev.SendManualBy as ManualSentUser
ev.manual_send_by as ManualSentUser
FROM 
    [dbo].[CC_Application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	left join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	left join customer_information ci on ci.pk_id = cus.fk_customer_information_id 
	outer apply
	(	
		select top 1 id.fk_customer_information_id, id.identification_no 
		  from customer_identification id inner join m_identification_type m
										on id.fk_m_identification_type_id = m.pk_id and m.is_active =1
		 where id.fk_customer_information_id = ci.pk_id
			and  m.name in('ID','Passport','Previous_ID','Previous_PP')
		order by m.name
	) ccId
	 join [dbo].[ev_email_verification] ev on ev.fk_application_information_id = ap.pk_id
	 outer apply
	 (
		select top 1 mp.ev_status_name From ev_mapping_status mp
		where (ev.first_result = mp.first_ev_result_name or ev.first_result = '') and 
		      (ev.manual_result_name = mp.manual_ev_result_name or ev.manual_result_name = '')
	 ) evStatus
	 outer apply
	 (
	  select top 1 m.[description] From m_definition_type m
	  where ev.first_result =m.name	and m.fk_group_id =90 and m.is_active=1
	 )firstrpl
	 outer apply 
	 (
	  select top 1 m.[description] From m_definition_type m
	  where ev.manual_result_name = m.name and m.fk_group_id =90 and m.is_active=1
	 )manualrpl
WHERE
	Cast(ev.first_send_date as date) >= Cast(@FromDate as date)
and Cast(ev.first_send_date as date) <= Cast(@ToDate as date)
ORDER BY ap.Application_No,ap.received_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_blacklist_company]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_blacklist_company]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
ROW_NUMBER() OVER (ORDER BY Created_Date ASC) AS Seq,
Company_Name as CompanyName,
License_No as LicenseNo,
company_code as CompanyCode,
tax_code as TaxCode,
owner_name as OwnerName,
owner_id as OwnerID,
date_black_list as DateBlackList,
black_list_code as BlackListCode,
(select top(1)m.name from m_status m
				where fk_status_id = m.pk_id and m.is_active=1) as [Status],
Created_Date as CreatedDate,
created_by as CreatedBy,
Checker_Date as CheckerDate,
checker_by as CheckerBy

FROM
	FRM_Black_List_Company
	
WHERE
	Cast(Created_Date as date) >= Cast(@FromDate as date)
and Cast(Created_Date as date) <= Cast(@ToDate as date)
ORDER BY Created_Date
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_blacklist_customer]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_blacklist_customer]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY f.Created_Date ASC) AS Seq,
--CustomerName,
 f.customer_name as CustomerName, 
--IDType,
 (select top(1) m.name from m_identification_type m
				 where f.fk_m_identification_type_id = m.pk_id and m.is_active =1) as IDType,
--PreviousNo,
 previous_no as PreviousNo,
--PersonalNo,
personal_no  as PersonalNo,
--SocialNo,
social_no as SocialNo,
--DOB,
f.dob as DOB,
--DateBlackList,
date_black_list as DateBlackList,
--BlackListCode,
black_list_code as BlackListCode,
--[Status],
(select top(1)m.name from m_status m
						where f.fk_status_id = m.pk_id)  as [Status],
--CreatedDate,
f.created_date as CreatedDate,
--CreatedBy,
f.created_by  as CreatedBy,
--CheckerDate,
f.checker_date as CheckerDate,
--CheckerBy
checker_by as CheckerBy
FROM
	frm_black_list_customer f
	left join customer_information ci on f.fk_customer_information_id = ci.pk_id
	left join m_status m on f.fk_status_id = m.pk_id
	inner join m_type mt on f.fk_type_id = mt.pk_id and mt.name in('CC','CreditCard')
WHERE
	Cast(f.created_date as date) >= Cast(@FromDate as date)
and Cast(f.created_date as date) <= Cast(@ToDate as date)
ORDER BY f.created_date
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_dump]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec sp_report_cc_application_getfrauddump '2019-01-01','2019-04-20'
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_dump]
	@FromDate datetime,
	@ToDate datetime
AS

  SELECT 
  ROW_NUMBER() OVER (ORDER BY  Received_Date ASC) AS Seq,
--	[ApplicationNo],
	ap.application_no as [ApplicationNo],

--	CONVERT(VARCHAR(24),[Received_Date],106),
	CONVERT(VARCHAR(24),[Received_Date],106),
--	[ChannelD],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

--	[ARMCode],
	ap.arm_code as [ARMCode],
--	[PIDOfSaleStaff],
	ap.sale_staff_bank_id as[PIDOfSaleStaff],
--	[LocationBranchName],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [LocationBranchName],

--	[ProductTypeName],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [ProductTypeName],

--	[CardPickUpName],
	(select top(1) ca.name from cc_card_pick_up ca
					where cap.fk_card_pick_up_id = ca.pk_id and ca.is_active =1) as [CardPickUpName],
--	[ProgramCodeName],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [ProgramCodeName],
--	[TypeApplicationName],
	cap.type_of_application as [TypeApplicationName],
--	[CardProgramName],
	
	(select top(1)ca.name from cc_card_program ca
					where cap.fk_card_program_id = ca.pk_id and ca.is_active =1) as [CardProgramName],
--	[CardTypeName],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [CardTypeName],
--	[CardTypeName2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [CardTypeName2],
--	[HolderInitial],
	CONVERT(varchar, CAST(cap.holder_initial AS MONEY),1) as [HolderInitial],

--	[HolderInterestRateSuggested],
	cap.holder_interest_rate_suggested as [HolderInterestRateSuggested],
--	[HolderCurrentAccountNo],
	cap.holder_current_account_no as [HolderCurrentAccountNo],
--	[HolderDepositedCurrency],
	(select top(1) m.name from cc_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,
--	[HolderCurrencyDepositedAmount],
	CONVERT(varchar, CAST(cap.holder_currency_deposited_amount AS MONEY), 1) AS [HolderCurrencyDepositedAmount],
--	[CreditBureauType],
	(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [CreditBureauType],

--	[CIQueuedTime],
	cap.ci_queued_time as [CIQueuedTime],
--	[IsLocked],
	ap.is_locked as [IsLocked],
--	[LockedBy],
    ap.user_lock as [LockedBy],
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	[IsSecured],
	ap.is_secured as [IsSecured],
--	[IsOnline],
	cap.is_online as  [IsOnline],
--	[IsSMS],
	ap.is_sms_send as  [IsSMS],
--	[TotalOfSubCard],
     cap.total_of_subcard as [TotalOfSubCard],
--	[CurrentUnsecuredOutstanding],
	(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from cc_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [CurrentUnsecuredOutstanding],

--	[CurrentTotalEMI],
	CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0)AS MONEY), 1)   AS [CurrentTotalEMI],

--	[LimitSuggestedMUE],
	CONVERT(varchar, CAST(Isnull(apr.limit_suggested_mue,0)AS MONEY), 1)    AS [LimitSuggestedMUE],
--	[EMISuggested],
	apr.emi_suggested as [EMISuggested],
--	[InterestRateSuggested],
	CONVERT(varchar, CAST(apr.interest_rate_suggested AS MONEY), 1)  as[InterestRateSuggested],

--	[FinaIlnterestRate],
	CONVERT(varchar, CAST(apr.final_interest_rate AS MONEY), 1)   as [FinaIlnterestRate],
--	[MUE],
	CONVERT(varchar, CAST(apr.mue AS MONEY), 1)   as [MUE],
--	[MaxDSR],
	CONVERT(varchar, CAST(apr.max_dsr AS MONEY), 1)  as [MaxDSR],
--	[MaxDTI],
	CONVERT(varchar, CAST(apr.max_dti AS MONEY), 1)   as [MaxDTI],
--	[LimitSuggestedDSR],
	CONVERT(varchar, CAST(apr.limit_suggested_dsr AS MONEY), 1)   as [LimitSuggestedDSR],
--	[LimitSuggestedDTI],
	CONVERT(varchar, CAST(apr.limit_suggested_dti AS MONEY), 1) as [LimitSuggestedDTI],
--	[LTVSuggested],
	CONVERT(varchar, CAST(apr.ltv_suggested AS MONEY), 1) as [LTVSuggested],
--	[FinalLimitApproved],
	apr.final_limit_approved as [FinalLimitApproved],
--	[FinalTotalEMI],
	apr.final_total_emi as [FinalTotalEMI],
--	[FinalTotalDSR],
	apr.final_total_dsr as  [FinalTotalDSR],
--	[FinalMUEAtSCB],
	apr.final_mue_at_scb as [FinalMUEAtSCB],
--	[FinalDTI],
	apr.final_dti as [FinalDTI],
--	[FinalLTV],
	apr.final_ltv as [FinalLTV],
--	[FinalApprovalStatus],
	
	(select top(1)  m.name  from m_status m
				where apr.fk_final_approval_status = m.pk_id and m.is_active = 1) as [FinalApprovalStatus],
--	[DecisionDate],
	apr.decision_date as [DecisionDate],
--	[RejectReasonID],
	(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83) 
				 and (m.name <> '' or m.name is not null)) as  CC_Rejected_Or_Cancelled_Reason,

--	[CancelReasonID],
	(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(84) 
				 and (m.name <> '' or m.name is not null)) as [CancelReasonID],
--	[DisbursementScenarioId],
	'' as [DisbursementScenarioId],
	--(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
	--				on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
	--				where dis.fk_application_information_id = ap.pk_id) as [DisbursementScenarioId],
	'' as [DisbursementScenarioId],
--	[DisbursementScenarioText],
	'' as [DisbursementScenarioText],
	--	[DeviationCodeID],
	(select top(1)m.name from m_deviation_code m
					where apr.fk_deviation_code_id = m.pk_id)  as [DeviationCodeID],	 
--	[MUE_CC],
	apr.cc_mue as [MUE_CC],
--	[CIRecommend],
	apr.ci_recommend as [CIRecommend],
--	GrossSalary,
	(select top(1)cin.gross_salary from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as GrossSalary,
--	NetSalary,
	(select top(1)cin.net_salary from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as NetSalary,
--	MonthlyIncome,
	(select top(1)cin.monthly_income from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as MonthlyIncome,
--	PerformanceBonus,
	(select top(1)cin.performance_bonus from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as PerformanceBonus,
--	GuaranteedBonusIncome,
	(select top(1)cin.guaranteed_bonus from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as GuaranteedBonusIncome,
--	cc.[IsBankStaff],
	ci.is_staff as [IsBankStaff],
--	cc.[BankRelationship],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [BankRelationship],

--	cc.[CustomerSegment],
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [CustomerSegment],

--	cc.[Initital],
	ci.initital as Initital,
--	cc.[FullName],
	cus.full_name as [FullName],
--	cc.[EmbossingName],
	cus.embossing_name as [EmbossingName],
--	cc.[DOB],
	cus.dob as [DOB],
--	cc.[Gender],
	(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.fk_group_id = 38 and m.is_active =1) as Gender,
--	cc.[Nationality],
	(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Nationality],

--	cc.[MaritalStatus],
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id and m.is_active =1) as [MaritalStatus],
--	cc.[PermAddress],
	cus.permanent_address AS PermAddress,
--	cc.[PermWard],
	cus.permanent_ward as [PermWard],
--	cc.[PermDistrict],
	cus.permanent_district as  [PermDistrict],
--	cc.[PermCity],
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1 and m1.fk_group_id =66) as [PermCity],
--	cc.[TypePermAddress],
	cus.permanent_address as [TypePermAddress],
--	cc.[TypeResidentialAdd],
	'' as [TypeResidentialAdd],
--	cc.[ResidentialAddress],
	cus.residential_address as [ResidentialAddress],
--	cc.[ResidentialWard],
	cus.residential_ward as ResidentialWard,
--	cc.[ResidentialDistrict],
	 cus.residential_district as  ResidentialDistrict,
--	cc.[ResidentialCity],
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1 and m1.fk_group_id =64) as [PermCity],

--	cc.[DateIssuedResidentialAdd],
	cus.issued_date_residential_address as [DateIssuedResidentialAdd],
--	cc.[OwnerResidentialAdd],
	cus.owner_residential_address as [OwnerResidentialAdd],
--	cc.[PrimaryPhoneNo],
	cus.primary_phone_no as  [PrimaryPhoneNo],
--	cc.[HomePhoneNo],
	cus.home_phone_no as [HomePhoneNo],
--	cc.[BillingAddress],
	cus.billing_address as [BillingAddress],
--	cc.[EmailAddress1],
	cus.email_address_1 as [EmailAddress1],
--	cc.[EmailAddress2],
	cus.email_address_2 as [EmailAddress2],
--	cc.[EmailAddress3],
	cus.email_address_3 as [EmailAddress3],
--	cc.[RLSCompanyCode],
	co.company_code_rls as RLSCompanyCode,
--	cc.[CompanyCode],
	co.company_code as [CompanyCode],
--	cc.[CompanyName],
	co.company_name as CompanyName,
--	cc.[CompanyRemark],
	co.company_remark as[CompanyRemark],
--	cc.[TypeEmployment],
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

--	cc.[CompanyAddress],
	co.company_address as  [CompanyAddress],
--	cc.[CompanyWard],
	co.company_ward as [CompanyWard],
--	cc.[CompanyDistrict],
	co.company_district as [CompanyDistrict],
--	cc.[CompanyCity],
	(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1) as [CompanyCity],
--	cc.[CompanyPhone],
	co.office_telephone as [CompanyPhone],
--	cc.[BusinessType],
	(select top(1) m.name from m_business_nature m
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [BusinessType],

--	cc.[CompanyCAT],
	co.company_cat as [CompanyCAT],
--	cc.[Industry],
	(select top(1) m.name from m_industry m
					where co.fk_m_industry_id = m.pk_id and m.is_active =1) as [CurrentPosition],
--	cc.[CurrentPosition],
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [CurrentPosition],
--	cc.[VerifiedPosition],
	(select top(1) m.name from m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [VerifiedPosition],
--	cc.[Occupation],
	(select top(1) m.name from  m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as  [Occupation],
--	cc.[OccupationVerified],
	(select top(1) m.name from m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as  [OccupationVerified],
--	cc.[OccupationType],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [OccupationTypeVerified],
--	cc.[OccupationTypeVerified],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [OccupationTypeVerified],
--	cc.[TypeOfContract],
	(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,

--	cc.[IsPassProbation],
	cus.is_pass_probation as [IsPassProbation],
--	cc.[OperationSelfEmployed],
	(select top(1) m.name from m_definition_type m 				
					  where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 
					  and m.fk_group_id = 69) as OperationSelfEmployed,
--	cc.[IncomeType],
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [IncomeType],

--	cc.[IncomeNet],
		(select top(1) cin.income_net from cc_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as  [IncomeNet],
--	cc.[TakingLowestVarIncome],
	'' as [TakingLowestVarIncome],
--	cc.[IncomeEligible],
	(select top(1) cin.income_eligible from cc_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as [IncomeEligible],

--	cc.[IncomeTotal],
	(select top(1) cin.total_borrower_income from cc_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as [IncomeTotal],

--	cc.[PaymentType],
	(select top(1) m.name from m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id) as RepaymentType,

--	cc.[CreatedDate],
	cus.created_date as [CreatedDate],
--	cc.[BusinessNatureCode],
	
	(select top(1)m.name from m_business_nature m
					where cus.fk_business_nature_code_id = m.pk_id and m.is_active =1) as [BusinessNatureCode],
--	cc.[CurrentResidentTypeCode],
	
	(select top(1)m.name from m_current_resident_type m
					where cus.fk_current_resident_type_code_id = m.pk_id and m.fk_group_id = 40 
					     and m.is_active =1) as [CurrentResidentTypeCode],
--	cc.[OwnershipTypeCode], ???
	/*cus.fk_ownership_type_code_id*/ '' as [OwnershipTypeCode],
--	cc.[CustomerTypeCode],
	/*cus.fk_customer_type_code_id*/ '' as  [CustomerTypeCode],
--	cc.[Status] as CustomerStatus,
	(select top(1) m.name from m_status m
					where m.pk_id = cus.fk_status_id and m.is_active =1) as CustomerStatus,
--	cc.[PositionID],
	
	(select top(1)m.name from m_position m
					where m.pk_id = cus.fk_current_position_id and m.is_active =1) as [PositionID],
--	cc.[YearsInCurrentEmployment],
	cus.years_in_current_employment_id as [YearsInCurrentEmployment],
--	cc.[ResidenceName],
	cus.residence_name as[ResidenceName],
--	cc.[TimeAtCurrentAddress],
	cus.time_current_address as [TimeAtCurrentAddress],
--	cc.[EducationID],
	(select top(1)m.name from m_education m
					where m.pk_id = cus.fk_education_id and m.is_active =1) as [EducationID],
	
--	cc.[PreviousID],
	
	(select top(1) cus.identification_no
	  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
	  where cus.fk_customer_information_id = ci.pk_id) as [PreviousID],

--	cc.[NumberBankRelationship],
	/*cus.fk_bank_relationship_id*/ '' as [NumberBankRelationship],

--	cc.MonthlyIncomeDeclared,
	(select top(1)cin.monthly_income_declared from cc_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as MonthlyIncomeDeclared,
--	TradingArea
	
	(select top(1)m.name from m_trading_area m
					where m.pk_id = cus.fk_trading_area_id and m.is_active=1) as TradingArea
	
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_approval_information apr on apr.fk_application_information_id = ap.pk_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
	
WHERE
	   Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_investigation_page]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_investigation_page]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  fr.created_date ASC) AS Seq,
--ApplicationNo,
ap.application_no as  ApplicationNo,
--CustomerName,
ci.full_name as CustomerName,
--PreviousNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID' 
									   and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id)  as PreviousNo,
--PersonalNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as PersonalNo,
--PassportNo,
--PassportNo,
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as  PassportNo,
--SocialNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Social'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as SocialNo,

CONVERT(varchar, CAST(fr.loan_amount_applied AS MONEY), 1) AS LoanAmountApplied,

--ReferedChannel,
	fr.refered_channel as ReferedChannel,
--ReferedBy,
	fr.refered_by as ReferedBy,
--CONVERT(VARCHAR(24),ReferedDate,106) as ReferedDate,
	CONVERT(VARCHAR(24),refered_date,106) as ReferedDate,
--SuspiciousDocument,
(select top(1)fi.file_name from frm_investigave_file fi
				where fr.pk_id = fi.fk_frm_investigave_id and fi.is_active =1) as SuspiciousDocument,
--InvestigatorResult,
	fr.investigator_result as InvestigatorResult,
--EmployeeInvolved,
  fr.employee_involved as EmployeeInvolved,
--ExternalPartyInvolved,
  fr.external_party_involved as ExternalPartyInvolved,
--SignificantFraud,
  fr.significant_fraud as SignificantFraud,
--SummaryInvestigation,
  fr.summary_investigation as SummaryInvestigation,
--Finndings,
  fr.finndings,
--CONVERT(VARCHAR(24),DecisionDate,106) as DecisionDate,
	CONVERT(VARCHAR(24),decision_date,106) as DecisionDate,
--DecisionCode,
	fr.decision_code as DecisionCode,
--Status,
	(select top(1)m.name from m_status m
				where ap.fk_m_status_id = m.pk_id and m.is_active = 1) as Status,
--CONVERT(VARCHAR(24),fr.created_date,106) as fr.created_date,
	CONVERT(VARCHAR(24),fr.created_date,106) as createddate,
--CreatedBy,
	fr.Created_By as CreatedBy,
--CONVERT(VARCHAR(24),CheckerDate,106) as CheckerDate,
CONVERT(VARCHAR(24),fr.Checker_Date,106) as CheckerDate,
--CheckerBy
	fr.Checker_By as  CheckerBy
FROM
	frm_investigave  fr
	inner join cc_application cap on fr.fk_application_information_id = cap.fk_application_information_id
	left join application_information ap on fr.fk_application_information_id = ap.pk_id
	left join customer_information ci on fr.fk_customer_information_id = ci.pk_id
	
WHERE
	Cast(fr.created_date as date) >= Cast(@FromDate as date)
and Cast(fr.created_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_queue_page]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_cc_application_getfraudqueuepage '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_queue_page]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  fr.created_date ASC) AS Seq,
--ApplicationNo,
  ap.application_no as  ApplicationNo,
  --CustomerName,
 ci.full_name as CustomerName,
 --PreviousNo,
 (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID' 
									   and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id)  as PreviousNo,
  --PersonalNo
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as PersonalNo,
  --PassportNo,
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as  PassportNo,
--SocialNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Social'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as SocialNo,

--ReferedChannel,
  fr.refered_channel as ReferedChannel,
--ReferedBy,
  fr.refered_by as ReferedBy,
--CONVERT(VARCHAR(24),ReferedDate,106) as ReferedDate,
 CONVERT(VARCHAR(24),refered_date,106) as ReferedDate,
--InvestigatorResult,
 fr.investigator_result as InvestigatorResult,
--CONVERT(VARCHAR(24),DecisionDate,106) as DecisionDate,
CONVERT(VARCHAR(24),decision_date,106) as DecisionDate,
--DecisionCode,
fr.decision_code as DecisionCode,
--Status,
(select top(1)m.name from m_status m
				where ap.fk_m_status_id = m.pk_id and m.is_active = 1) as Status,
--CONVERT(VARCHAR(24),CreatedDate,106) as CreatedDate,
CONVERT(VARCHAR(24),fr.created_date,106) as CreatedDate,
--CreatedBy,.
fr.Created_By as CreatedBy,
--CONVERT(VARCHAR(24),CheckerDate,106) as CheckerDate,
CONVERT(VARCHAR(24),fr.Checker_Date,106) as CheckerDate,

--CheckerBy
fr.Checker_By as  CheckerBy
FROM
	frm_investigave  fr
	inner join cc_application cap on cap.fk_application_information_id = fr.fk_application_information_id
	inner join application_information ap on fr.fk_application_information_id = ap.pk_id
	inner join customer_information ci on fr.fk_customer_information_id = ci.pk_id
	
WHERE
	Cast(fr.created_date as date) >= Cast(@FromDate as date)
and Cast(fr.created_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_fraud_sas_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_fraud_sas_reports]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
CONVERT(VARCHAR(10), ap.received_date, 101) as [ReceivedDate],
--cc.BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cc.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder ID],

--cc.FullName as [Primary Card Holder Name],
ci.full_name as [Primary Card Holder Name],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary Card Holder Previous ID],

--CONVERT(VARCHAR(10), cc.DOB, 101) as [DOB],
 CONVERT(VARCHAR(10), cc.dob, 101) as [DOB],
--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

--ap.FinalApprovalStatus as [CC_FinalApprovalStatus],
 (select top(1) m.name from cc_approval_information capi inner join m_status m on capi.fk_final_approval_status = m.pk_id
															  and m.is_active = 1	
						
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [CC_FinalApprovalStatus],
--plApp.PL_FinalApprovalStatus,
  '' as PL_FinalApprovalStatus,
--CONVERT(varchar, CAST(plApp.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan amount approved],
  (select top(1) CONVERT(varchar, CAST(capi.final_limit_approved AS MONEY), 1) from cc_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [Loan amount approved],

--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
(select top(1) CONVERT(VARCHAR(10),capi.decision_date, 101) from cc_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [Date of Decision],
--ap.EMISuggested AS EMI,
(select top(1) capi.emi_suggested from cc_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as EMI,
--ap.ChannelD AS Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1)AS Channel,

--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode AS [ARM Code],
 ap.arm_code as [ARM Code],
--cc.CompanyPhone AS [Office Phone],
(select top(1) co.office_telephone from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Office Phone],
--cc.PrimaryPhoneNo AS [Mobile Phone],
cc.primary_phone_no AS [Mobile Phone],
--cc.PermAddress AS [Permanent address],
cc.permanent_address as [Permanent address],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1)  as [Company Code],
--cc.RLSCompanyCode,
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--cc.CompanyName as [Company Name],
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Name],
--cc.CompanyAddress as [Company Address],
(select top(1)co.company_address from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Address],
--cc.TypeEmployment as [Employment type], fk_m_employment_type_id
(select top(1)m.name from cc_company_information co inner join m_employment_type  m
																on m.pk_id = co.fk_m_employment_type_id and m.is_active =1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Employment type],
--cc.CurrentPosition as [Current Position],
(select top(1)m.name from cc_company_information co  inner join m_position m
																  on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Current Position],
--cc.Occupation,

(select top(1)m.name from cc_company_information co  inner join m_occupation m
																  on m.pk_id = co.fk_m_occupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Occupation,
--CONVERT(varchar, CAST(cc.TotalMonthlyIncomeViaBS AS MONEY), 1) AS [Total Income], 
(select top(1)CONVERT(varchar, CAST(cui.total_monthly_income_via_bs AS MONEY), 1) from cc_customer_income cui
				where cui.fk_cc_customer_information_id = ci.pk_id and cui.is_active= 1) as [Total Income],
--ap.CreditBureauType as [Bureau Type]
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id)  as [Bureau Type]
FROM
	
	[dbo].[cc_application] cap 
	inner join application_information ap on cap.fk_application_information_id  = ap.pk_id
	inner join cc_customer_information cc on cap.fk_application_information_id = cc.fk_application_information_id
	inner join customer_information ci on ci.pk_id = cc.fk_customer_information_id
	--Left Join CCPLApplication plApp on plApp.CCApplicationNo = ap.ApplicationNo
	
WHERE
	Cast(ap.received_date  as Date) >= Cast(@FromDate  as Date)
and Cast(ap.received_date  as Date) <= Cast(@ToDate  as Date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_imported_application_statistics]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_imported_application_statistics]
	@FromDate datetime,
	@ToDate datetime,
	@Status varchar(20)
AS

SELECT [file_name] as [FileName],
error_log as ErrorLog,
CONVERT(VARCHAR(24),lg.created_date,113) as CreatedDate ,
m.name as [Status],
vendor_id as VendorID,
--CustomerPersonalID,
(select top(1)cus.identification_no from customer_identification cus
				                   where cus.fk_customer_information_id = ci.pk_id) as CustomerPersonalID,
--CustomerName,
ci.full_name as CustomerName,
--CustomerDOB,
ci.dob as CustomerDOB,
(select top(1) ap.application_no from application_information ap
				where ap.pk_id = lg.fk_application_information_id) as CCAppNo,
mt.name as ProductTypeName,
vendor_date as VendorCreatedDate
FROM
	application_log_import lg
	left join customer_information ci on ci.fk_application_information_id = lg.fk_application_information_id
	left join m_status m on m.pk_id = lg.fk_status_id and m.is_active =1
	left join m_type mt on lg.fk_type_id = mt.pk_id and mt.name in('CC','CreditCard')
WHERE
(m.name = @Status or @Status is null)	
and Cast(@FromDate as date) <= Cast(lg.created_date as date)
and Cast(@ToDate as date) >= Cast(lg.created_date as date)

ORDER BY CreatedDate desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_lo_modify_sc_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_lo_modify_sc_reports]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--	ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS Seq,
--	ApplicationNo,
--	ARMCode,
--	PIDOfSaleStaff as [Sale Code],
--	CreatedBy,
--	CONVERT(VARCHAR(10), CreatedDate, 101) as [CreatedDate],
--	CheckerBy,
--	CONVERT(VARCHAR(10), CheckerDate, 101) as [CheckerDate],
--	[Status]

--FROM LOModifySC
	
--WHERE
--	dbo._fGetShortDate(CreatedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(CreatedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_master_acs_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_cc_application_get_master_acs_report]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
    ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--	ap.ARMCode,
	ap.arm_code as  ARMCode,
--	cc.Initital,
    ci.initital as Initital,
--	cc.Gender,
    (select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.is_active = 1 and m.fk_group_id = 38) as Gender,
--	cc.FullName,
cus.full_name as FullName,
--	cc.DOB,
cus.dob as  DOB,
--	cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--	cc.MaritalStatus,
(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id and m.is_active =1) as MaritalStatus,
--	cc.PrimaryPhoneNo,
cus.primary_phone_no AS PrimaryPhoneNo,
--	cc.HomePhoneNo,
cus.home_phone_no as  HomePhoneNo,
--	cc.BillingAddress,
	cus.billing_address as  BillingAddress,
	--cc.EmailAddress1,
	cus.email_address_1 as  EmailAddress1,

--	(select top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as IdentificationNo,

(select top(1) cus.identification_no
		from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id 
							and m.name in('ID','Passport','Previous_ID','Previous_PP')
       where cus.fk_customer_information_id = ci.pk_id) as IdentificationNo,

--	(select top 1 ExpriedDate from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as ExpriedDate,
	(select top(1) cus.expried_date
		from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id 
							and m.name in('ID','Passport','Previous_ID','Previous_PP')
       where cus.fk_customer_information_id = ci.pk_id) as ExpriedDate,

--cc.ResidentialAddress,
	cus.residential_address as ResidentialAddress,
	--cc.ResidentialWard,
	cus.residential_ward as ResidentialWard,
	--cc.ResidentialDistrict,
	 cus.residential_district as  ResidentialDistrict,
	--cc.ResidentialCity,
	(select top(1) m1.name from m_city m1
							where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1) ResidentialCity,
	--cc.PermCity,
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1) PermCity,
	--cc.PermAddress,
	cus.permanent_address AS PermAddress,
	--cc.PermWard,
	cus.permanent_ward AS PermWard,
	--cc.PermDistrict,
	cus.permanent_district  AS PermDistrict,
	--cc.CompanyName,
	co.company_name as  CompanyName,
	--cc.CompanyAddress,
	co.company_address as  CompanyAddress,
	--cc.CompanyWard,
	co.company_ward as CompanyWard,
	--cc.CompanyDistrict,
	co.company_district as CompanyDistrict,
	--cc.CompanyCity,
	(select top(1) m1.name from m_city m1
						  where co.fk_company_city_id = m1.pk_id and m1.is_active =1) CompanyCity,
	--cc.CompanyPhone,
	co.office_telephone as  CompanyPhone,
--	cc.CurrentPosition,
(select top(1)m.name from cc_company_information co  inner join m_position m
																  on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CurrentPosition,
--	cc.Occupation,
(select top(1)m.name from cc_company_information co  inner join m_occupation m
																  on m.pk_id = co.fk_m_occupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Occupation,
--	cc.OperationSelfEmployed,
(select top(1) m.name from  m_group m inner join m_definition_type md 
													on m.pk_id = md.fk_group_id and m.pk_id = 69	and md.is_active =1							where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 ) as OperationSelfEmployed,

--	cc.TypeOfContract,
(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
--	cc.MonthlyIncomeDeclared,
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,
--	cc.ResidentStatus,
'' as ResidentStatus,
--	cc.PlaceofBirth,
   cus.place_of_birth as PlaceofBirth,
--	cc.OfficeEmail,
cus.office_email as OfficeEmail,
--	cc.Qualifications,
(select top(1) m.name from  m_group m inner join m_definition_type md 
													on m.pk_id = md.fk_group_id and m.pk_id = 47	and md.is_active =1							where cus.fk_qualifications_id = m.pk_id and m.is_active=1 ) as Qualifications,

--	cc.SocialInsuranceNumber,
cus.social_insurance_number as SocialInsuranceNumber,
--cc.ThirdPartyContact1,
cus.third_party_contact_1 as ThirdPartyContact1,
	--cc.ThirdPartyContact2,
	cus.third_party_contact_2 as ThirdPartyContact2,
--	sc.Gender as [SubCardGender],
(select top(1)m.name from m_group mg inner join m_definition_type m
											on mg.pk_id = m.fk_group_id and m.pk_id = 38 and m.is_active =1
					where sc.fk_gender_id = mg.pk_id and mg.is_active = 1) as[SubCardGender],
--	sc.Intitial as [SubCardIntitial],
    sc.fk_intitial_id,
--	sc.FullName as [SubCardFullName],
	sc.full_name as [SubCardFullName],
--	sc.DOB as [SubCardDOB],
	sc.dob as [SubCardDOB],
--	sc.Nationality as [SubCardNationality],
	(select top(1)m.name from m_nationality m 
				where sc.fk_nationality_id = m.pk_id and m.is_active =1) as [SubCardNationality],
--	ap.[Status] as [CurrentStatus],
	(select top(1)m.name from m_status m
						where ap.fk_m_status_id = m.pk_id) as TeleStatus,
--	sc.[SubCardMaritalStatus] ,
(select top(1)m.name from m_marital_status m
					where sc.fk_marital_status_id = m.pk_id and m.is_active =1) as [SubCardMaritalStatus] ,
--	sc.[SubCardPrimaryPhoneNo] ,
	sc.primary_phone_no as [SubCardPrimaryPhoneNo] ,
--	sc.[SubCardEmailAddress] ,
	sc.email_address as [SubCardEmailAddress] ,
--	sc.[SubCardIdentificationNo] ,
	sc.identification_no as [SubCardIdentificationNo] ,
--	sc.[SubCardExpriedDate] ,
    sc.expried_date as [SubCardExpriedDate] ,
--	sc.[SubCardResidentialWard] ,
	sc.residential_ward as [SubCardResidentialWard] ,
--	sc.[SubCardResidentialDistrict] ,
	
	(select top(1) dis.name from m_group m inner join m_district dis on
												m.pk_id = dis.fk_group_id and m.pk_id = 65 and dis.is_active = 1
					 where sc.fk_residential_district_id = m.pk_id and m.is_active=1) as  [SubCardResidentialDistrict] ,
--	sc.[SubCardResidentialCity] ,
(select top(1) dis.name from m_group m inner join m_district dis on
												m.pk_id = dis.fk_group_id and m.pk_id = 64 and dis.is_active = 1
					 where sc.fk_residential_district_id = m.pk_id and m.is_active=1) as [SubCardResidentialCity] ,
--	sc.[SubCardPermCity] ,
(select top(1) ct.name from m_group m inner join m_city ct on
												m.pk_id = ct.fk_group_id and m.pk_id = 66 and ct.is_active = 1
					 where sc.fk_residential_district_id = m.pk_id and m.is_active=1) as [SubCardPermCity] ,
--	sc.[SubCardPermWard] ,
    sc.perm_ward as [SubCardPermWard] ,
--	sc.[SubCardPermDistrict] ,
	sc.perm_district_name as [SubCardPermDistrict] ,
--	sc.[SubCardCompanyName] ,
    sc.company_name as[SubCardCompanyName] ,
--	sc.[SubCardCurrentPosition] ,
	(select top(1)m.name from  m_position m
				where sc.fk_current_position_id = m.pk_id and m.is_active =1) as [SubCardCurrentPosition] ,
--	sc.[SubCardOccupation]
    sc.occupation  as [SubCardOccupation]
	FROM
		[dbo].[cc_application] cap 
		inner join application_information ap on ap.pk_id = cap.fk_application_information_id
		inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
		inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
		inner join m_status mt on mt.pk_id = ap.fk_m_status_id and mt.is_active=1
		left join cc_subcard_application sc on ap.pk_id = sc.fk_application_information_id
		left join pl_company_information co on co.fk_application_information_id = ap.pk_id 
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	and mt.name in ('CIApproved','LODisbursed')
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_master_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_master_ci]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  received_date ASC) AS Seq,

CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],

--ap.TypeApplicationName as [Type of Application],fk_m_product_id
cap.type_of_application as [Type of Application],

(select sum(duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE') as TATTele,

(select sum(duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI1') as TATRecommender,

(select sum(duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI2') as TATApprover,

ap.application_no as ApplicationNo,
--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType,

--ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,

--ap.HolderDepositedCurrency as [Deposited Currency],
(select top(1) m.name from cc_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as [Deposited Currency],


(select CONVERT(varchar, CAST(rs.holder_currency_deposited_amount AS MONEY), 1) 
from
    (select top(1) ca.holder_currency_deposited_amount from cc_application ca
				  where ca.fk_application_information_id = ap.pk_id) as rs) AS [DespositedAmount],
 

cc.full_name as PrimaryCardHolderName,
--fk_bank_relationship_id
(CASE WHEN cc.is_staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,

CONVERT(VARCHAR(24),cc.dob,106) as PrimaryCardHolderDOB,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,

(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
     on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where ci.fk_customer_information_id = cc.pk_id) as PrimaryCardHolderID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
     on ci.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where ci.fk_customer_information_id = cc.pk_id) as PrimaryCardHolderPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
     on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where ci.fk_customer_information_id = cc.pk_id) as PrimaryCardHolderPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
     on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where ci.fk_customer_information_id = cc.pk_id) as PrimaryCardHolderPreviousID,

--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = cc.fk_m_nationality_id_1) as Nationality,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where ApplicationNo=ap.ApplicationNo and BlackListCode<>null) as BlackList,
(select  (case when COUNT(*)>0 then 'Yes' else 'No' end) 
				from frm_black_list_log frm 
				where ap.pk_id = frm.fk_application_information_id and frm.fk_frm_black_list_code_id <> null) as BlackList,

--ap.ProgramCodeName as ProgramCode, fk_m_program_code_id
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,

--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,

--cc.PaymentType as RepaymentType, fk_payment_type_id
(select top(1) m.name from  cc_customer_information cus join m_payment_type m on cus.fk_payment_type_id = m.pk_id
			     where cus.fk_application_information_id = ap.pk_id) as RepaymentType,

--cc.PrimaryPhoneNo as MobilePhone,
(select top(1) cus.primary_phone_no from cc_customer_information cus
				where cus.fk_application_information_id = ap.pk_id) as MobilePhone,

--cc.TradingArea as TradingCity,
(select top(1) m.name from cc_customer_information cus join m_trading_area m on cus.fk_trading_area_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as TradingCity,

cc.permanent_address as [Perm Address City],

--cc.companyname as CompanyName,
co.company_name as CompanyName,

--cc.CompanyCity as CompanyCity,
(select top(1)ct.name from  m_city ct 
					  where co.fk_company_city_id = ct.pk_id) as CompanyCity,

--cc.fk_company_information_id as CompanyType, fk_company_information_id
(select top(1) m.name from m_business_nature m
					 where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as CompanyType,

--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,

null as JobTitle,
--OccupationTypeVerified as VerifiedOccupationType,
--''  as VerifiedOccupationType,

(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as VerifiedOccupationType,


--CONVERT(varchar, CAST(MonthlyIncomeDeclared AS MONEY), 1) AS [MonthlyIncomeDeclared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [MonthlyIncomeDeclared],

--CONVERT(varchar, CAST(IncomeEligible AS MONEY), 1) AS [EligibleIncome],
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [EligibleIncome],

--CONVERT(varchar, CAST(IncomeTotal AS MONEY), 1) AS [TotalMonthlyIncome],
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS  [TotalMonthlyIncome],

--CreditBureauType as [Bureau type],
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m on cb.fk_m_credit_bureau_type_id = m.pk_id and
																				 m.is_active = 1
				where cb.fk_customer_information_id = cc.pk_id) as [Bureau type],

--CONVERT(varchar, CAST(CurrentUnsecuredOutstanding AS MONEY), 1) AS [OS_At_Other_Bank (Current Unsecured Outstanding Off Us)],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_on_us AS MONEY), 1) from cc_customer_credit_bureau cb
				where  cb.fk_customer_information_id = cc.pk_id) AS [OS_At_Other_Bank (Current Unsecured Outstanding Off Us)],

--CONVERT(varchar, CAST(CurrentTotalEMI AS MONEY), 1) AS [EMI_At_Other_Bank (Current total EMI Off Us)],
(select top(1)CONVERT(varchar, CAST(cb.current_total_emi_on_us AS MONEY), 1) from cc_customer_credit_bureau cb
				where  cb.fk_customer_information_id = cc.pk_id) AS [EMI_At_Other_Bank (Current total EMI Off Us)],

--CONVERT(varchar, CAST(HolderInitial AS MONEY), 1) AS [InitialLimit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id)AS [InitialLimit],

--CONVERT(varchar, CAST(FinalLimitApproved AS MONEY), 1) AS [FinalApprovedLimit],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)AS [FinalApprovedLimit],

--InterestRateSuggested as [Interest %],
(select top(1)CONVERT(varchar, CAST(apr.interest_rate_suggested AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [Interest %],

--CONVERT(varchar, CAST((FinalTotalEMI - CurrentTotalEMI) AS MONEY), 1) AS [On-us EMI],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0) - Isnull((select top(1) cb.current_total_emi_on_us 
																	from cc_customer_credit_bureau cb
																	where  cb.fk_customer_information_id = cc.pk_id),0)
AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [On-us EMI],

--CONVERT(varchar, CAST(FinalTotalEMI AS MONEY), 1) AS [TotalEMI],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [TotalEMI],

--(CASE WHEN CardProgramName = 'Secured' THEN NULL ELSE
--	(CASE WHEN (cc.IncomeTotal IS NULL OR cc.IncomeTotal = 0) THEN CONVERT(varchar, CAST((((FinalTotalEMI - CurrentTotalEMI) / cc.FinalIncome) * 100) AS MONEY), 1)
--	 ELSE CONVERT(varchar, CAST((((FinalTotalEMI - CurrentTotalEMI) / cc.IncomeTotal) * 100) AS MONEY), 1) END) END) AS [On-us DSR (%)],
''as [On-us DSR (%)],


--FinalTotalDSR as [TotalDSR %],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_dsr,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [TotalDSR %],

--MUE_CC,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.cc_mue,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as MUE_CC,

--FinalMUEAtSCB as [MUE at SCB],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_mue_at_scb,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [MUE at SCB],

--FinalDTI as DTI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_dti,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DTI,

--(FinalLTV * 100) as TotalLTV,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_ltv *100,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as TotalLTV,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as DECISION_STATUS,

--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate, decision_date
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DecisionDate,

--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentStatus,

--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID=(select top 1 ActionBy from AppActionLog where ApplicationNo=ap.ApplicationNo and Action='Tele_Modified')) as TeleVerifier,
(select top(1)l.action_by from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'Tele_Modified') as TeleVerifier,

--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID= CIRecommend) as [UserRecommend (Underwriter)],
''as [UserRecommend (Underwriter)],

--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID= (select top 1 ActionBy from AppActionLog where ApplicationNo=ap.ApplicationNo and Action in ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD'))) as Approver,

(select top(1)l.action_by from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] in
										 ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD')) as Approver,

--(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as Rejected_Or_Cancelled_Reason,

(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) and (m.name <> '' or m.name is not null)) as Rejected_Or_Cancelled_Reason,

--(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,

(select top(1) app.remark from  cc_application app
				where app.fk_application_information_id = ap.pk_id)as Remark,
--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

--LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='OSSendBack')) as Pending_OSSendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack')  as Pending_OSSendback,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'CISendBack%')) as Pending_CISendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] like 'CISendBack%') as Pending_CISendback,

--(select COUNT(*) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='CISendBackSC' or Action='CISendBackCI')) as No_Of_CISentBack,
(select COUNT(*) from application_action_log l
				 where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI')as No_Of_CISentBack,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'Tele_SentBack%')) as Pending_TeleSentBack,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] like 'Tele_SentBack%') as Pending_TeleSentBack,

--(select COUNT(*) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='Tele_SentBack')) as No_Of_TeleSentBack,

(select COUNT(*) from application_action_log l
				 where l.fk_application_information_id = ap.pk_id and l.[action] = 'Tele_SentBack') as No_Of_TeleSentBack,

--(CASE WHEN (SELECT TOP 1 [IsPass] FROM [CCCriteria] cr WHERE cr.ApplicationNo = ap.ApplicationNo AND [CriteriaType] = 'HomeSiteVisit') = 1 THEN 'Yes' ELSE 'No' END) AS [HomeSiteVisit Result],

(CASE WHEN (SELECT TOP 1 m.Is_Pass FROM cc_criteria m 
								 WHERE cc.fk_application_information_id = ap.pk_id AND m.name = 'HomeSiteVisit') = 1 THEN 'Yes' ELSE 'No' END)AS [HomeSiteVisit Result],

--(CASE WHEN (SELECT TOP 1 [IsPass] FROM [CCCriteria] cr WHERE cr.ApplicationNo = ap.ApplicationNo AND [CriteriaType] = 'BankStatementCheck') = 1 THEN 'Yes' ELSE 'No' END) AS [BankStatementCheck Result],

(CASE WHEN (SELECT TOP 1 m.Is_Pass FROM cc_criteria m 
								 WHERE cc.fk_application_information_id = ap.pk_id AND m.name = 'BankStatementCheck') = 1 THEN 'Yes' ELSE 'No' END) AS [BankStatementCheck Result],

NULL AS [BankStatementCheck  Visitot],
--(CASE WHEN (select top 1 IsSendSMS from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_TeleVerifier,

(CASE WHEN  ap.is_sms_send = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_TeleVerifier,

--(CASE WHEN IsSMS = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_Underwriter
(CASE WHEN  ap.is_sms_send = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_Underwriter

FROM
	[dbo].[application_information] ap 
	inner join cc_application cap on  ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on ap.pk_id = cus.fk_application_information_id
	inner join customer_information cc on cc.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on  co.fk_customer_information_id = cc.pk_id
WHERE
	Cast(received_date as date) >=  cast (@FromDate as date)
and Cast (received_date as date) <= cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_mis_master_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_mis_master_report]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
ROW_NUMBER() OVER (ORDER BY  Received_Date ASC) AS Seq,
ap.application_no as  ApplicationNo,
CONVERT(VARCHAR(24),ap.Received_Date,106) as Received_Date,
--ap.TypeApplicationName as TypeApplication,
cap.type_of_application as TypeApplication,
--cc.Full_Name as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPassportID,
--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,
--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,

--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

--CONVERT(VARCHAR(24),cc.DOB,106) as HolderPrimaryDOB,
CONVERT(VARCHAR(24),cus.DOB,106) as HolderPrimaryDOB,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where ApplicationNo=ap.ApplicationNo and BlackListCode<>null) as BlackList,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) 
   from frm_black_list_log lg inner join frm_black_list_code fr 
									  on lg.fk_frm_black_list_code_id = fr.pk_id and fr.is_active =1
where fk_application_information_id = ap.pk_id and fr.[description] <>null) as BlackList,

--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from pl_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as SelfEmployed,

--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--cc.BusinessType as CompanyType,
(select top(1) m.name from m_business_nature m
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],
--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,

--cc.TypeOfContract,
(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,

--CONVERT(VARCHAR(24),cc.ContractStart,106) as [StartDate],
CONVERT(VARCHAR(24),cus.contract_start,106) as [StartDate],
--cc.ContractLength,
cus.contract_length as ContractLength,
--(SELECT TOP 1 VerifedOccupation FROM VerificationForm vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.IsTeleVerify = 0) as VerifiedOccupation,
(SELECT TOP 1 vf.verifedOccupation FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedOccupation,

--(SELECT TOP 1 VerifiedPosition FROM VerificationForm vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.IsTeleVerify = 0) as VerifiedPosition,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedPosition,

--cc.TradingArea,
(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

--cc.ResidentialCity AS [Current Address City],
(select top(1) m.name from m_city m
						 where cus.fk_residential_city_id = m.pk_id and m.is_active =1 
								and m.fk_group_id = 64) AS [Current Address City],

--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as  RepaymentType,

--CreditBureauType as CIC,
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,

--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
--CONVERT(varchar, CAST([CurrentUnsecuredOutstanding] AS MONEY), 1) AS [Current Unsecured Outstanding Off Us],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [Current Unsecured Outstanding Off Us],

--CONVERT(varchar, CAST([CurrentTotalEMI] AS MONEY), 1) AS [Current Total EMI Off Us],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_emi,0)AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  AS [Current Total EMI Off Us],

--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS MonthlyIncomeDeclared,
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,

--CONVERT(varchar, CAST([IncomeEligible] AS MONEY), 1) AS EligibleIncome,
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) EligibleIncome,

--CONVERT(varchar, CAST([IncomeTotal] AS MONEY), 1) AS TotalMonthlyIncome,
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS TotalMonthlyIncome,

--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as CardType,
--ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as  [Card Type 2],
--ap.CardProgramName as CardProgram,
(select top(1)ca.name from cc_card_program ca
					where cap.fk_card_program_id = ca.pk_id and ca.is_active =1) as CardProgram,
--(CASE WHEN ap.HolderDepositedCurrency = 'VND' THEN 'VND' ELSE 'Non-VND' END) as CurrencyDepositedAmount,
(select top(1) m.name from cc_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,
--CONVERT(varchar, CAST([HolderCurrencyDepositedAmount] AS MONEY), 1) AS DespositedAmount,
	CONVERT(varchar, CAST(cap.holder_currency_deposited_amount AS MONEY), 1) AS CurrencyDepositedAmount,

--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS InitialLimit,
CONVERT(varchar, CAST(cap.holder_initial AS MONEY),1) as InitialLimit,
--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS FinalApprovedLimit,
CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1) AS FinalApprovedLimit,
--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name  from m_status m
				where apr.fk_final_approval_status = m.pk_id and m.is_active = 1) as [FinalApprovalStatus],

--(select top 1 lu.Full_Name from Application_Action_Log lg join user_login lu on lg.Action_By=lu.Peoplewise_ID where lg.fk_application_information_id = ap.pk_id and lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by Action_Date desc) as Underwriter,
(select top 1 lu.Full_Name from Application_Action_Log lg join user_login lu on lg.Action_By=lu.Peoplewise_ID where lg.fk_application_information_id = ap.pk_id and lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by lg.Action_Date desc) as Underwriter,

(select top 1 lu.Full_Name from Application_Action_Log lg join user_login lu on lg.Action_By=lu.Peoplewise_ID where lg.fk_application_information_id = ap.pk_id and lg.[Action]  in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by lg.action_date desc) as Approver,

(SELECT TOP 1 [level_name] FROM [CC_Criteria] cr WHERE cr.fk_application_information_id = ap.pk_id ORDER BY cr.[level_name] DESC ) as LevelName,

--CONVERT(VARCHAR(24),DecisionDate,106) as Final_DecisionDate,
 CONVERT(VARCHAR(24),apr.decision_date,106) as Final_DecisionDate,

--(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as Rejected_Or_Cancelled_Reason,
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(84) 
				 and (m.name <> '' or m.name is not null)) as Rejected_Or_Cancelled_Reason,
--FinalMUEAtSCB,
apr.final_mue_at_scb as FinalMUEAtSCB,
--MUE_CC,
apr.cc_mue as [MUE_CC],
--CONVERT(varchar, CAST([FinalTotalEMI] AS MONEY), 1) AS TotalEMI,
CONVERT(varchar, CAST(apr.final_total_emi AS MONEY), 1) AS TotalEMI,
--FinalTotalDSR as [TotalDSR %],
apr.final_total_dsr as [TotalDSR %],
--FinalDTI as DTI,
apr.final_dti as DTI,
--FinalLTV as TotalLTV,
apr.final_ltv as TotalLTV,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentStatus,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--PIDOfSaleStaff as SaleCode,
ap.sale_staff_bank_id as SaleCode,
--ARMCode,
ap.arm_code as [ARMCode],
--ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

--LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as  BranchLocation,

--(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as Remark,

--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--ap.IsTwoCardType as [IsTwoCardType],
cap.is_two_card_type as [IsTwoCardType],
--ap.HardCopyAppDate
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate]

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
	left join cc_approval_information apr on apr.fk_application_information_id = ap.pk_id
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_nsg_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_nsg_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--ap.TypeApplicationName as TypeApplication,
cap.type_of_application  as TypeApplication,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_1_id = ct.pk_id and ct.is_active =1) as CardType,
--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_2_id = ct.pk_id and ct.is_active =1) as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,
--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as  DECISION_STATUS,
--(
--select top 1 u.FullName from dbo.AppActionLog a left join dbo.LoginUser u on u.PeoplewiseId=a.ActionBy
--where a.ApplicationNo = ap.ApplicationNo and a.Action='CI_NSG' order by ActionDate desc
--) User_SelectNSG,
'' as  User_SelectNSG,
--(
--select top 1 CONVERT(VARCHAR(24),ActionDate,106) from dbo.AppActionLog a 
--where a.ApplicationNo = ap.ApplicationNo and a.Action='CI_NSG' order by ActionDate desc
--)ActionDateNSG,

(select top 1 CONVERT(VARCHAR(24),Action_Date,106) from dbo.application_action_log a 
where a.fk_application_information_id = ap.pk_id and  a.Action='CI_NSG' order by action_date desc)ActionDateNSG,

--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no AS  MobilePhone,
--cc.TradingArea as TradingCity,
(select top(1) m.name from cc_customer_information cus join m_trading_area m on cus.fk_trading_area_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as TradingCity,
--cc.TypePermAddress as TypePermAddress,

(select top(1) m.name from m_definition_type m
		  where cus.fk_permanent_address_type_id= m.pk_id and m.is_active =1 and m.fk_group_id = 39) as TypePermAddress,
--cc.CompanyName as CompanyName,
(select top(1) co.company_name from cc_company_information co
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyName,
--cc.CompanyCity as CompanyCity,
(select top(1) m.name from cc_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyCity,
--cc.BusinessType as CompanyType,
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,
--cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as  RLSCompanyCode,

--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--cc.IsBankStaff as Staff,
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As  Staff,
--cc.DOB as PrimaryCardHolderDOB,
cus.dob as PrimaryCardHolderDOB,
--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where ci.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where ci.fk_customer_information_id = ci.pk_id) as  PrimaryCardHolderPreviousID,
--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as Nationality,
--(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
cap.remark    as Remark,
--(select top 1 Remark from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleVerifierRemark
(select top 1 Remark from verification_form v
		where fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1) as TeleVerifierRemark

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_nsg_report_ext]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_nsg_report_ext]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--ap.ReceivedDate,
ap.Received_Date as ReceivedDate,
--ap.TypeApplicationName as TypeApplication,
cap.type_of_application  as TypeApplication,
--ap.ApplicationNo,
 ap.Application_No  as ApplicationNo,
--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_1_id = ct.pk_id and ct.is_active =1) as CardType,
--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_2_id = ct.pk_id and ct.is_active =1) as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,
--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as DECISION_STATUS,
--ap.FinalLimitApproved,
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)AS FinalLimitApproved,
--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as MobilePhone,
--cc.TradingArea as TradingCity,
(select top(1) m.name from m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as  TradingCity,
--cc.TypePermAddress as TypePermAddress,
(select top(1) m.name from m_definition_type m
		  where cus.fk_permanent_address_type_id= m.pk_id and m.is_active =1 and m.fk_group_id = 39) as TypePermAddress,
--cc.CompanyName as CompanyName,
(select top(1) co.company_name from cc_company_information co
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyName,
--cc.CompanyCity as CompanyCity,
(select top(1) m.name from cc_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyCity,
--cc.BusinessType as CompanyType,
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,
--cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as  RLSCompanyCode,

--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--cc.IsBankStaff as Staff,
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],

cus.dob as PrimaryCardHolderDOB,

--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where ci.fk_customer_information_id = ci.pk_id) as CCIdentification,

--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where ci.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,
--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as Nationality,
--(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
cap.remark as Remark,
--(select top 1 Remark from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleVerifierRemark,
(select top 1 Remark from verification_form v
		where fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1) as TeleVerifierRemark,

CONVERT(VARCHAR(24), (
			select top 1 l.action_date from dbo.application_action_log l 
			where (l.fk_application_information_id = ap.pk_id and l.[Action] = m.name) order by l.action_date desc
		), 113) ActionTime, -- action time of current status

--		CONVERT(VARCHAR(24), (
--			select top 1 l.ActionDate from dbo.AppActionLog l 
--			where (l.ApplicationNo = ap.ApplicationNo and l.[Action] in('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD','CIRejected','CIRejectedBD')) order by l.ActionDate desc
--		), 113) ActionTime_Approved_Reject_Status -- action time of approved or rejected status

CONVERT(VARCHAR(24), (
			select top 1 l.action_date from dbo.application_action_log l 
			where (l.fk_application_information_id = ap.pk_id and l.[Action] in('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD','CIRejected','CIRejectedBD')) order by l.action_date desc
		), 113) as ActionTime_Approved_Reject_Status

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join m_status m on ap.fk_m_status_id = m.pk_id and m.is_active =1
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_office_phone_database]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_office_phone_database]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
ap.application_no,
m.name as [Status],
--cc.BusinessType as CompanyType,
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cc.pk_id)  as CompanyType,
--cc.CompanyName as CompanyName,
(select top(1) co.company_name from cc_company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyName,
--cc.CompanyAddress as CompanyAddress, 
(select top(1) co.company_address from cc_company_information co
				where co.fk_application_information_id = ap.pk_id ) as  CompanyAddress, 

--cc.CompanyWard as CompanyWard,
(select top(1)co.company_ward from cc_company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyWard,

--cc.CompanyDistrict as CompanyDistrict,
(select top(1)co.company_district from company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyDistrict,
--cc.CompanyCity as CompanyCity,
(select top(1)co.company_city from company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyCity,
--cc.CompanyPhone as CompanyPhone
(select top(1) m.company_phone from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as CompanyPhone
FROM
	[dbo].[cc_application] cap 
	inner join cc_customer_information cc on cap.fk_application_information_id = cc.fk_application_information_id
	inner join customer_information ci on cc.fk_customer_information_id = ci.pk_id
	inner join application_information ap on cap.fk_application_information_id = ap.pk_id
	inner join m_status m on cap.fk_status_id = m.pk_id 
WHERE
	cast(ap.received_date as date) >= Cast(@FromDate as date)
and Cast (ap.received_date as date) <= Cast(@ToDate as date)
and m.name in ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD')
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_pending_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_cc_application_get_cc_pendingreports '2019-01-01','2019-04-18'
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_pending_reports]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
--	select * into #tbl_CCApplication from [CCApplication] ap with (nolock) WHERE ReceivedDate >= @FromDate and ReceivedDate <= @ToDate
	
--	select a.* into #tbl_CCPLApplication from CCPLApplication a with (nolock) inner join #tbl_CCApplication b on b.ApplicationNo = a.CCApplicationNo

--	select cc.* into #tbl_CCCustomer from [CCCustomer] cc with (nolock) inner join #tbl_CCApplication ap on ap.CustomerID = cc.ID

--	select cc.* into #tbl_CCIdentification from [CCIdentification] cc with (nolock) inner join #tbl_CCApplication ap on ap.CustomerID = cc.CustomerID

--	select a.* into cc_rework from [CCRework] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
--	where [LogType] = 'Pending'
	
--	select a.* into cc_rework from [CCRework] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
--	where [LogType] = 'Tele'

--	select a.* into #tbl_CCRemark from [CCRemark] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo

--	select a.* into #tbl_AppActionLog from AppActionLog a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo

--	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
	(CASE WHEN ap.is_vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
	ap.application_no as [Application No],
	cap.special_code as [Special Code],
--	CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],

--	(SELECT TOP 1 [ActionBy] FROM [AppActionLog] WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate) AS CreatedBy,
	(SELECT TOP 1 [action_by] FROM [application_action_log] WHERE fk_application_information_id = ap.pk_id ORDER BY action_date) AS CreatedBy,
--	(
--		SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID 
--		WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
--	) AS CreatedName,
	'' AS CreatedName,

--	ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--	ap.TypeApplicationName as [Application Type],
cap.type_of_application as [Application Type],
--	ap.CardProgramName as [Card Program],
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--	BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
--	ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

--	ap.IsTwoCardType as [IsTwoCardType],
	cap.is_two_card_type as [IsTwoCardType],

	--cc.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cc.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

--	(select top 1 TypeOfIdentification from #tbl_CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of Identification],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

--	(select top 1 IdentificationNo from #tbl_CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

--	CONVERT(VARCHAR(10), cc.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.dob, 101) as [Primary Card Holder DOB],
--	cc.Nationality as [Primary Card Holder Nationality],
	(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Primary Card Holder Nationality],
--	cc.EmailAddress1 as [Email Address 1],
	cus.email_address_1 as [Email Address 1],
--	cc.EmailAddress2 as [Email Address 2],
	cus.email_address_2 as [Email Address 2],
--	cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
	cus.primary_phone_no AS [Primary Card Holder Mobile Phone Number],
--	cc.TypeEmployment as [Type Employment],
(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

--	cc.OperationSelfEmployed as [Employment Type],
(select top(1) m.name from cc_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cc.CurrentPosition as [Current Position],
	(select top(1)m.name from  m_position m 
							where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cc.Occupation, fk_occupation_id
	(select top(1) m.name from  m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cc.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						 where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cc.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

--	cc.CompanyName as [Company Name],
	(select top(1) m.company_name from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as  [Company Name],

	--cc.CompanyCode as [Company Code],
	(select top(1) mc.name from m_company_list cl inner join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = ci.fk_company_information_id) as [Company Code],

	--cc.RLSCompanyCode as [Company Code RLS],
	(select top(1) co.name from  m_company_list mc join m_company_code co on mc.fk_m_company_code_id = co.pk_id
				where mc.pk_id = ci.fk_company_information_id)  as [Company Code RLS],

	--cc.BusinessType as [Company Type],
	(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,

	--cc.CompanyAddress as [Company Address],
	(select top(1) co.company_address from cc_company_information co
				where co.fk_application_information_id = ap.pk_id ) as [Company Address],

	--cc.CompanyPhone as [Company Office], ???
	(select top(1) m.company_phone from m_company_list m 
				where ci.fk_company_information_id = m.pk_id)  as [Company Office],

--	ap.CreditBureauType as [Bureau Type], 
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--	cc.IncomeType as [Income Type],
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--	ccPL.LoanTenor,
    ''as LoanTenor,
--	ccPL.InterestRateClassification,
	''as InterestRateClassification,
--	ccPL.PLSuggestedInterestRate,
	''as PLSuggestedInterestRate,
--	ccPL.PLFinalLoanAmountApproved,
	''as PLFinalLoanAmountApproved,
--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],
--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

--	ccPL.PL_FinalApprovalStatus,
	''as PL_FinalApprovalStatus,
--	FinalApprovalStatus as [CC Final Approval Status],
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

--	ccPL.PL_DeviationCodeID as PL_DeviationCode,
	''as  PL_DeviationCode,
--	ap.DeviationCodeID as CC_DeviationCode,
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	(select LeveLBD from DeviationLevel where ccPL.DeviationLevelPL = LevelPL and LevelCC=ap.DeviationLevelCC and [Status]='Active') as BD_DeviationCode,
	'' as BD_DeviationCode,
--	CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

--	(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--	ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],
--	ccPL.LoanPurpose,
	''as  LoanPurpose,
--	cc.CleanEB,
	'' as CleanEB,
--	(select count(1) from CCSubCard sc where sc.fk_application_information_id = cap.fk_application_information_id) as SupplementaryCardNo,
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

--	(select COUNT(*) from #tbl_AppActionLog where fk_application_information_id = cap.fk_application_information_id and [Action]='OSSendBack') as [Times sendback by OS],
(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

--	---------------------------------------
--	(select Scenario from DisbursalScenario where pk_id = CCPL.PL_DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
	'' as [Pre-disbursement condition],
--	ap.DisbursementScenarioText as [PL Pre-disbursement condition],
	'' as [PL Pre-disbursement condition],
--	---------------------------------------
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=1) as [PL Remark 1],
	'' as  [PL Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=2) as [PL Remark 2],
	'' as  [PL Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=3) as [PL Remark 3],
	'' as  [PL Remark 3],
--	-----------------------------------
--	(select Scenario from DisbursalScenario where pk_id = ap.DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
--	ap.DisbursementScenarioText as [CC Pre-disbursement condition],
	''  as [CC Pre-disbursement condition],

--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=1) as [CC Remark 1],
	(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as [CC Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=2) as [CC Remark 2],
	(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 2) as [CC Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=3) as [CC Remark 3],
	(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 3) as [CC Remark 3],
--	---------------------------------------
--	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
--		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
--		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
--	where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],
(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
--		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x
--	where x.ROWNUMBERS=1) as [Pending Log Remark 1],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x
	where x.ROWNUMBERS=1) as [Pending Log Remark 1],

--	----------
--	ap.SCRemark as [SC Remark],
	cap.sc_remark as [SC Remark],
--	ap.OpsRemark as [Ops Remark],
    cap.ops_remark as [Ops Remark],
--	----------
	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Response By 1],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	------------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Response By 2],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Response By 3],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Response By 4],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],

	(select top 1 send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Response By 5],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	------------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Pending')x 
	where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark 1],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Response By 1],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Response By 2],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Response By 3],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Response By 4],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	----------
	(select [Name] from m_reason where pk_id = (select top 1 pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],

	(select top 1  send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],

	(select top 1 [Remark_Response] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 [Received_Date] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],

	(select top 1 [Received_By] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Response By 5],

	(select top 1 [User_Type] from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id  and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5]

	FROM 
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

	ORDER BY Seq

--	drop table #tbl_CCApplication
--	drop table cc_rework
--	drop table cc_rework
--	drop table #tbl_CCCustomer
--	drop table #tbl_CCIdentification
--	drop table #tbl_CCPLApplication
--	drop table #tbl_AppActionLog	
--	drop table #tbl_CCRemark
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_pending_reports_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_pending_reports_sales]
	@FromDate datetime,
	@ToDate datetime
AS
	--select cap.* into #tbl_CCApplication 
	--from [CC_Application] cap with (nolock) 
	--inner join application_information ap with (nolock) 
	--								   on cap.fk_application_information_id = ap.pk_id
	--WHERE ap.Received_Date >= @FromDate and ap.Received_Date <= @ToDate
	
	---select a.* into #tbl_CCPLApplication from CCPLApplication a with (nolock) inner join #tbl_CCApplication b on b.ApplicationNo = a.CCApplicationNo

	--select cc.* into #tbl_CCCustomer 
	--from cc_customer_information cc with (nolock) 
	--inner join #tbl_CCApplication ap on ap.fk_application_information_id = cc.fk_application_information_id

	--select cc.* into #tbl_CCIdentification 
	--from customer_identification cc with (nolock) 
	--inner join #tbl_CCApplication ap on ap.fk_application_information_id = cc.fk_application_information_id

	--select a.* into cc_rework 
	--from cc_rework a with (nolock) inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id
	--where [log_type] = 'Pending'
	
	--select a.* into cc_rework 
	--from cc_rework a with (nolock) 
	--inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id
	--where [log_type] = 'Tele'

	--select a.* into application_action_log 
	--from application_action_log a with (nolock) 
	--inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id

	--select a.* into #tbl_CCRemark 
	--from [CC_Remark] a with (nolock) 
	--inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id
--	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
	(CASE WHEN ap.Is_Vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
--	ap.ApplicationNo as [Application No],
	ap.Application_No as [Application No],
--	ap.SpecialCode as [Special Code],
	cap.special_code as [Special Code],
--	CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--	ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--	ap.TypeApplicationName as [Application Type],
	cap.type_of_application as [Application Type],
--	ap.CardProgramName as [Card Program],
	(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--	BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ci..Channe_lD as Channel,
	(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

	--ap.IsTwoCardType as [IsTwoCardType],
	cap.is_two_card_type as [IsTwoCardType],

	--cc.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cc.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

--	CONVERT(VARCHAR(10), cc.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.DOB, 101) as [Primary Card Holder DOB],
--	cc.Nationality as [Primary Card Holder Nationality],
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,

--	cc.TypeEmployment as [Type Employment],
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

--	cc.OperationSelfEmployed as [Employment Type],
(select top(1) m.name from cc_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cc.CurrentPosition as [Current Position],
	(select top(1)m.name from  m_position m 
							where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cc.Occupation, fk_occupation_id
	(select top(1) m.name from  m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cc.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						 where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cc.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

--	cc.CompanyName as [Company Name],
	(select top(1) m.company_name from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as  [Company Name],

	--cc.CompanyCode as [Company Code],
	(select top(1) mc.name from m_company_list cl inner join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = ci.fk_company_information_id) as [Company Code],

	--cc.RLSCompanyCode as [Company Code RLS],
	(select top(1) co.name from  m_company_list mc join m_company_code co on mc.fk_m_company_code_id = co.pk_id
				where mc.pk_id = ci.fk_company_information_id)  as [Company Code RLS],

	--cc.BusinessType as [Company Type],
	(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,

	--cc.CompanyAddress as [Company Address],
	(select top(1) co.company_address from cc_company_information co
				where co.fk_application_information_id = ap.pk_id ) as [Company Address],

	--cc.CompanyPhone as [Company Office], ???
	(select top(1) m.company_phone from m_company_list m 
				where ci.fk_company_information_id = m.pk_id)  as [Company Office],

--	ap.CreditBureauType as [Bureau Type], 
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],

	--cc.IncomeType as [Income Type], cc_customer_income
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--	ccPL.LoanTenor,
    ''as LoanTenor,
--	ccPL.InterestRateClassification,
	''as InterestRateClassification,
--	ccPL.PLSuggestedInterestRate,
	''as PLSuggestedInterestRate,
--	ccPL.PLFinalLoanAmountApproved,
	''as PLFinalLoanAmountApproved,
--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],
--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

--	ccPL.PL_FinalApprovalStatus,
	''as PL_FinalApprovalStatus,
--	FinalApprovalStatus as [CC Final Approval Status],
	(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

--	ccPL.PL_DeviationCodeID as PL_DeviationCode,
	''as  PL_DeviationCode,
--	ap.DeviationCodeID as CC_DeviationCode,
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	(select LeveLBD from DeviationLevel where ccPL.DeviationLevelPL = LevelPL and LevelCC=ap.DeviationLevelCC and [Status]='Active') as BD_DeviationCode,
	'' as BD_DeviationCode,
--	CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

--	(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--	ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],
--	ccPL.LoanPurpose,
	''as  LoanPurpose,
--	(select count(1) from CCSubCard sc where sc.cre.fk_application_information_id = cap.fk_application_information_id) as SupplementaryCardNo,
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and [Action]='OSSendBack') as [Times sendback by OS],
  (select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],

--	(select COUNT(*) from application_action_log where cre.fk_application_information_id = cap.fk_application_information_id and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

--	---------------------------------------
--	(select Scenario from DisbursalScenario where pk_id = CCPL.PL_DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
--	ap.DisbursementScenarioText as [PL Pre-disbursement condition],
(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
					on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition],

--	---------------------------------------
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=1) as [PL Remark 1],
	'' as  [PL Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=2) as [PL Remark 2],
	'' as  [PL Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=3) as [PL Remark 3],
	'' as  [PL Remark 3],
--	-----------------------------------
--	(select Scenario from DisbursalScenario where pk_id = ap.DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
--	ap.DisbursementScenarioText as [CC Pre-disbursement condition],
	''  as [CC Pre-disbursement condition],

--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=1) as [CC Remark 1],
	''  as [CC Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=2) as [CC Remark 2],
	'' as  [CC Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where cre.fk_application_information_id = cap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=3) as [CC Remark 3],
	'' as [CC Remark 3],
--	-----------------------------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x
	where x.ROWNUMBERS=1) as [Pending Log Remark 1],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Response By 1],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Response By 2],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Response By 3],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Response By 4],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Response By 5],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework  cre
		where cre.fk_application_information_id = cap.fk_application_information_id and cre.log_type ='Pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark 1],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Response By 1],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Response By 2],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Response By 3],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Response By 4],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Response By 5],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from cc_rework
		where fk_application_information_id = cap.fk_application_information_id and log_type ='Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5]

	FROM 
	  cc_application cap 
	  inner join application_information ap on cap.fk_application_information_id = ap.pk_id
	  inner join cc_customer_information cus on cap.fk_application_information_id = cus.fk_application_information_id 
	  inner join customer_information ci on cus.fk_customer_information_id = ci.pk_id
	  --left join #tbl_CCPLApplication ccPL on ap.ApplicationNo=ccPL.CCApplicationNo
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq

	--drop table #tbl_CCApplication
	--drop table cc_rework
	--drop table cc_rework
	--drop table #tbl_CCCustomer
	--drop table #tbl_CCIdentification
	--drop table #tbl_CCPLApplication
	--drop table application_action_log	
	--drop table #tbl_CCRemark
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_rdf_ascore_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_report_cc_application_get_rdf_ascore_reports]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	--select cap.* into #tbl_CCApplication from [CC_Application] cap with (nolock) join application_information ap with (nolock) 
	--								   on cap.fk_application_information_id = ap.pk_id
	--  WHERE ap.received_date >= @FromDate and ap.received_date <= @ToDate	

	--select cus.* into #tbl_CCCustomer from [cc_customer_information] cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select cus.* into customer_identification from customer_identification cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Pending'
	
	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Tele'

	--select a.* into application_action_log from application_action_log a with (nolock) inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id

	--select a.* into #tbl_CCRemark from [CC_Remark] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
	(CASE WHEN ap.is_vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
	ap.Application_No as [Application No],
	(SELECT TOP 1 l.[Action_By] FROM application_action_log l 
							   WHERE l.fk_application_information_id = ap.pk_id ORDER BY l.action_date) AS CreatedBy,
	--(
	--	SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID
	--	WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
	--) AS CreatedName,
	'' AS CreatedName,

	cap.special_code as [Special Code],

	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
	--ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],

	--ap.TypeApplicationName as [Application Type],
	cap.type_of_application as [Application Type],

	--ap.CardProgramName as [Card Program],
	(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],

	--BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ci..Channe_lD as Channel,
	(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

	--ap.IsTwoCardType as [IsTwoCardType],
	cap.is_two_card_type as [IsTwoCardType],

	--cus.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cus.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

	--(select top 1 TypeOfIdentification from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of Identification],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],

	--CONVERT(VARCHAR(10), cus.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.dob, 101) as [Primary Card Holder DOB],

	--cus.Nationality as [Primary Card Holder Nationality],
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as [Primary Card Holder Nationality],

	--cus.EmailAddress1 as [Email Address 1],
	cus.email_address_1 as [Email Address 1],

	--cus.EmailAddress2 as [Email Address 2],
	cus.email_address_1 as [Email Address 2],

	--cus.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
	(select top(1) cus.primary_phone_no from cc_customer_information cus
				where cus.fk_application_information_id = ap.pk_id) as [Primary Card Holder Mobile Phone Number],

	--cus.TypeEmployment as [Type Employment], --m_employment_type ???
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

	--cus.OperationSelfEmployed as [Employment Type],
	(select top(1) m.name from cc_customer_information cus inner join m_definition_type m on 
																	cus.fk_operation_self_employed_id = m.pk_id AND m.fk_group_id = 69 and m.is_active = 1
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cus.CurrentPosition as [Current Position],
	(select top(1)m.name from  m_position m 
						 where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cus.Occupation, fk_occupation_id
	(select top(1) m.name from m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cus.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cus.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

	--cus.CompanyName as [Company Name],
	co.company_name as  [Company Name],

	--cus.CompanyCode as [Company Code],
	co.company_code as [Company Code],

	--cus.RLSCompanyCode as [Company Code RLS],
	co.company_code_rls  as [Company Code RLS],

	--cus.BusinessType as [Company Type],
	(select top(1) m.name from m_business_nature m
						 where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],

	--cus.CompanyAddress as [Company Address],
	co.company_address as [Company Address],

	--cus.CompanyPhone as [Company Office], ???
	co.office_telephone  as [Company Office],

	--ap.CreditBureauType as [Bureau Type], 
	(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = cus.pk_id) as [Bureau Type],

	--cus.IncomeType as [Income Type], cc_customer_income
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],

	--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],

	--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

	--FinalApprovalStatus as [Final Approval Status],
	(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

	--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

	--(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

	--ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],

	--ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,

	--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],

	--(select count(1) from CCSubCard sc where sc.ApplicationNo=ap.ApplicationNo) as SupplementaryCardNo, 
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and [Action]='OSSendBack') as [Times sendback by OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],
	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

	--(select Scenario from DisbursalScenario where ID = ap.DisbursementScenarioId) as [Pre-disbursement condition Scenario], cc_disbursement_condition ???
	(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
					on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition Scenario],

	--ap.DisbursementScenarioText as [Pre-disbursement condition],	 ???
	(select top(1)md.pre_condition_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
								on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					inner join m_disbursal_scenario_condition  md
								on md.fk_m_disbursal_scenario_id = m.pk_id
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=1) as [CC Remark 1], ???
	'' as  [CC Remark 1],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=2) as [CC Remark 2], ???
	'' as  [CC Remark 2],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=3) as [CC Remark 3], ???
	'' as  [CC Remark 3],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id 
								     and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)) as [Pending Log Sendback reason 1],
					
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x
	--where x.ROWNUMBERS=1) as [Pending Log Remark 1],

	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Remark 1],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--ap.SCRemark as [SC Remark],
	cap.sc_remark as [SC Remark],

	--ap.OpsRemark as [Ops Remark],
	cap.ops_remark as [Ops Remark],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101)  as [Pending Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101) as [Pending Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Response By 1],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Sendback send from 1],

	--------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)) as [Pending Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101)  as [Pending Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)  as [Pending Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101) as [Pending Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Sendback send from 2],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending') x 
		               where x.ROWNUMBERS = 3)) as [Pending Log Sendback reason 3],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101)  as [Pending Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101) as [Pending Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Sendback send from 3],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)) as [Pending Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101)  as [Pending Log Sendback date 4],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101) as [Pending Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Sendback send from 4],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)) as [Pending Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101)  as [Pending Log Sendback date 5],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101) as [Pending Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Response By 5],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	--------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Sendback send from 5],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)) as [Tele Log Sendback reason 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark 1],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark 1],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101)  as [Tele Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)  as [Tele Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101) as [Tele Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Response By 1],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Sendback send from 1],

	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)) as [Tele Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101)  as [Tele Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)  as [Tele Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101) as [Tele Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Sendback send from 2],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)) as [Tele Log Sendback reason 3],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101)  as [Tele Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)  as [Tele Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101) as [Tele Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Sendback send from 3],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)) as [Tele Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101)  as [Tele Log Sendback date 4],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)  as [Tele Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101) as [Tele Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Sendback send from 4],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)) as [Tele Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101)  as [Tele Log Sendback date 5],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)  as [Tele Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101) as [Tele Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Response By 5],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Sendback send from 5],
	--cus.Gender,
	
	(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.fk_group_id = 38) as Gender,

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID') 
	--ORDER BY TypeOfIdentification) as [Expried Date For ID],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('ID')
					order by mit.name) as [Expried Date For ID],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Visa],
	(select top(1)CONVERT(VARCHAR(10), id.identification_no, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Visa],

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Expried Date For Visa],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Expried Date For Visa],

	--cus.MaritalStatus, 
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id) as MaritalStatus,
	--cus.Nationality,
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,
	--ap.AccountNumber, 
	ap.application_no as AccountNumber, 

	--ap.PaymentMethod,
	
	(select top(1)m.name from m_payment_type m
					where ap.fk_m_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,

	--cus.OwnerResidentialAdd as [Ownership],
	cus.owner_residential_address as [Ownership],

	--ap.HolderCurrencyDepositedAmount as [Deposit Amount],
	cap.holder_currency_deposited_amount as [Deposit Amount],

	--ap.HolderCurrentAccountNo as [Current Acc],
	cap.holder_current_account_no as [Current Acc],

	--ap.HolderDepositedCurrency as [Currency],
	(select top(1)m.name from m_definition_type m
					    where cap.fk_holder_deposited_currency_id = m.pk_id 
					          and fk_group_id =77 and m.is_active = 1) as [Currency],

	--cus.CompanyGenericCode as [Company Generic Code],
	
	(select top(1) co.company_code from company_information co
					where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Generic Code],

	--cus.CompanyAddress + ' ' + cus.CompanyWard + ' ' + cus.CompanyDistrict + ' ' + CompanyCity as [Company Full Address],
	(select top(1) co.company_address + ' ' + co.company_ward + ' ' + co.company_district
					 + ' ' + co.company_city
	               from company_information co
				   where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Full Address],
	--CONVERT(varchar, CAST([FinalIncome] AS MONEY), 1)  as [Final Monthly Income]
	(select top(1)CONVERT(varchar, CAST(cin.final_income AS MONEY), 1)  from cc_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Final Monthly Income]
	FROM
		cc_application cap 
		inner join application_information ap on cap.fk_application_information_id = ap.pk_id
		inner join cc_customer_information cus on cap.fk_application_information_id = cus.fk_application_information_id 
		inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
		left join cc_company_information co on co.fk_customer_income_id = ci.pk_id

	WHERE ap.fk_m_type_id = 11
	and	cast(ap.Received_Date as date) >= cast (@FromDate as date)
	and cast (Received_Date as date) <= cast (@ToDate as date)
	ORDER BY Seq

	--drop table #tbl_CCApplication
	--drop table cc_rework
	--drop table cc_rework
	--drop table #tbl_CCCustomer
	--drop table customer_identification
	--drop table application_action_log	
	--drop table #tbl_CCRemark
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_report_tracking]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_report_tracking]
	@FromDate datetime,
	@ToDate datetime,
	@TypeReport varchar(30)
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as [Receiving Date],
--cc.FullName as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
--cc.Nationality,
--cc.OperationSelfEmployed as SelfEmployed,
--cc.CurrentPosition as JobTitle,
--cc.CompanyCode as [Company Code],
--cc.CompanyName as CompanyName,
--cc.BusinessType as CompanyType,
--ap.LocationBranchName as Business_TradingArea,
--ap.CreditBureauType as CIC,
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=1) as [O/S_At_Other_Bank 1],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=1) as [EMI_At_Other_Bank 1],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=2) as [O/S_At_Other_Bank 2],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=2) as [EMI_At_Other_Bank 2],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=3) as [O/S_At_Other_Bank 3],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=3) as [EMI_At_Other_Bank 3],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=4) as [O/S_At_Other_Bank 4],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=4) as [EMI_At_Other_Bank 4],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=5) as [O/S_At_Other_Bank 5],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=5) as [EMI_At_Other_Bank 5],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=6) as [O/S_At_Other_Bank 6],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=6) as [EMI_At_Other_Bank 6],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=7) as [O/S_At_Other_Bank 7],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=7) as [EMI_At_Other_Bank 7],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=8) as [O/S_At_Other_Bank 8],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=8) as [EMI_At_Other_Bank 8],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=9) as [O/S_At_Other_Bank 9],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=9) as [EMI_At_Other_Bank 9],
----------
--(select top 1 CONVERT(varchar, CAST(InitialLoan AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=10) as [O/S_At_Other_Bank 10],
--(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
--    (select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCLoanBureau
--	where ApplicationNo=ap.ApplicationNo)x 
--where x.ROWNUMBERS=10) as [EMI_At_Other_Bank 10],
----------
--CONVERT(varchar, CAST(cpl.PersonalLoanAmountApplied AS MONEY), 1) AS [Loan_Amt_Applied],
--cpl.LoanPurpose,
--ap.ChannelD,
--ap.LocationBranchName,
--ap.ARMCode,
--cc.PaymentType as PaymentMethod,
--ap.CardProgramName as Program,
--CONVERT(varchar, CAST(cc.FinalIncome AS MONEY), 1) AS [Total Income],
--CONVERT(varchar, CAST(cc.GrossBaseSalary AS MONEY), 1) AS [Salary Income],
--CONVERT(varchar, CAST(cc.BasicAllowance AS MONEY), 1) AS [Other_Incomes (Non-salary)],
--(case when (select COUNT(*) from FRMInvestigave frm where frm.ApplicationNo = ap.ApplicationNo) > 0 then 'Yes' else 'No' end) as BlackList_Check,
--(select top 1 lu.FullName  from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and (lg.[Action]='CIApproved' or lg.[Action]='CIApprovedPL' or lg.[Action]='CIApprovedCC'  or lg.[Action]='CIApprovedBD' or lg.[Action]='CIRejected' or lg.[Action]='CIRejectedBD')) as Underwritter,
--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
--FinalApprovalStatus as DECISION_STATUS,
--cpl.DeviationLevelPL as [Level],
--(case when cpl.PL_RejectReasonID <> null or cpl.PL_RejectReasonID <> '' then cpl.PL_RejectReasonID else cpl.PL_CancelReasonID end) as [Rejected or Cancelled Reasons],
--cpl.Remark,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
--cpl.LoanTenor AS [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
--CONVERT(varchar, CAST(cpl.SCB_PL_EMI AS MONEY), 1) AS [TotalEMI],
--CONVERT(varchar, CAST(cpl.TotalDSRForPL AS MONEY), 1) AS [TotalDBR (%)],
--CONVERT(varchar, CAST(cpl.MUE_PL AS MONEY), 1) AS [TotalMUE],
--dis.DisbursalStatus,
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
--dis.LoanAccountNo,
--ap.Status as CurrentStatus,
--ap.ProgramCodeName as ProgramCode,
--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
--ap.PIDOfSaleStaff as SalesCode,
--cc.PrimaryPhoneNo as MobilePhone,
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Customer Address]
--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	LEFT JOIN CCPLApplication cpl ON cpl.CCApplicationNo = ap.ApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and ((ap.[Status] in ('CIApproved', 'LODisbursed', 'CIApprovedBD', 'CIApprovedPL') and @TypeReport='ApprovedTracking')
--	or (ap.[Status] in ('CIRejected', 'CIRejectedBD') and @TypeReport='RejectedTracking')
--	or (ap.[Status] in ('CICancelled') and @TypeReport='CancelledTracking'))
--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_rpa_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_report_cc_application_get_rpa_reports]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	--select cap.* into #tbl_CCApplication from [CC_Application] cap with (nolock) join application_information ap with (nolock) 
	--								   on cap.fk_application_information_id = ap.pk_id
	--  WHERE ap.received_date >= @FromDate and ap.received_date <= @ToDate	

	--select cus.* into #tbl_CCCustomer from [cc_customer_information] cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select cus.* into customer_identification from customer_identification cc with (nolock) inner join #tbl_CCApplication ap on ap.fk_application_information_id = cus.fk_application_information_id

	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Pending'
	
	--select a.* into cc_rework 
	--from [cc_rework] a with (nolock) 
	--where a.log_type = 'Tele'

	--select a.* into application_action_log from application_action_log a with (nolock) inner join #tbl_CCApplication b on a.fk_application_information_id = b .fk_application_information_id

	--select a.* into #tbl_CCRemark from [CC_Remark] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
	(CASE WHEN ap.is_vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
	ap.Application_No as [Application No],
	(SELECT TOP 1 l.[Action_By] FROM application_action_log l 
							   WHERE l.fk_application_information_id = ap.pk_id ORDER BY l.action_date) AS CreatedBy,
	--(
	--	SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID
	--	WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
	--) AS CreatedName,
	'' AS CreatedName,

	cap.special_code as [Special Code],

	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
	--ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],

	--ap.TypeApplicationName as [Application Type],
	cap.type_of_application as [Application Type],

	--ap.CardProgramName as [Card Program],
	(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],

	--BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ci..Channe_lD as Channel,
	(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

	--ap.IsTwoCardType as [IsTwoCardType],
	cap.is_two_card_type as [IsTwoCardType],

	--cus.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cus.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

	--(select top 1 TypeOfIdentification from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of Identification],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
	(select top(1) cid.identification_no
	   from customer_identification cid join  [m_identification_type] m 
                                          on cid.fk_m_identification_type_id = m.pk_id and m.name
										     in ('ID','Passport','Previous_ID','Previous_PP')
      where cid.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],

	--CONVERT(VARCHAR(10), cus.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.dob, 101) as [Primary Card Holder DOB],

	--cus.Nationality as [Primary Card Holder Nationality],
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as [Primary Card Holder Nationality],

	--cus.EmailAddress1 as [Email Address 1],
	cus.email_address_1 as [Email Address 1],

	--cus.EmailAddress2 as [Email Address 2],
	cus.email_address_1 as [Email Address 2],

	--cus.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
	(select top(1) cus.primary_phone_no from cc_customer_information cus
				where cus.fk_application_information_id = ap.pk_id) as [Primary Card Holder Mobile Phone Number],

	--cus.TypeEmployment as [Type Employment], --m_employment_type ???
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

	--cus.OperationSelfEmployed as [Employment Type],
	(select top(1) m.name from cc_customer_information cus inner join m_definition_type m on 
																	cus.fk_operation_self_employed_id = m.pk_id AND m.fk_group_id = 69 and m.is_active = 1
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cus.CurrentPosition as [Current Position],
	(select top(1)m.name from  m_position m 
						 where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cus.Occupation, fk_occupation_id
	(select top(1) m.name from m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cus.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cus.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

	--cus.CompanyName as [Company Name],
	co.company_name as  [Company Name],

	--cus.CompanyCode as [Company Code],
	co.company_code as [Company Code],

	--cus.RLSCompanyCode as [Company Code RLS],
	co.company_code_rls  as [Company Code RLS],

	--cus.BusinessType as [Company Type],
	(select top(1) m.name from m_business_nature m
						 where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],

	--cus.CompanyAddress as [Company Address],
	co.company_address as [Company Address],

	--cus.CompanyPhone as [Company Office], ???
	co.office_telephone  as [Company Office],

	--ap.CreditBureauType as [Bureau Type], 
	(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = cus.pk_id) as [Bureau Type],

	--cus.IncomeType as [Income Type], cc_customer_income
	(select top(1)m.name from cc_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],

	--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],

	--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

	--FinalApprovalStatus as [Final Approval Status],
	(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

	--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

	--(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from cc_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

	--ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],

	--ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,

	--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],

	--(select count(1) from CCSubCard sc where sc.ApplicationNo=ap.ApplicationNo) as SupplementaryCardNo, 
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and [Action]='OSSendBack') as [Times sendback by OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],
	--(select COUNT(*) from application_action_log where ApplicationNo=ap.ApplicationNo and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

	--(select Scenario from DisbursalScenario where ID = ap.DisbursementScenarioId) as [Pre-disbursement condition Scenario], cc_disbursement_condition ???
	(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
					on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition Scenario],

	--ap.DisbursementScenarioText as [Pre-disbursement condition],	 ???
	(select top(1)md.pre_condition_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
								on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					inner join m_disbursal_scenario_condition  md
								on md.fk_m_disbursal_scenario_id = m.pk_id
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=1) as [CC Remark 1], ???
	'' as  [CC Remark 1],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=2) as [CC Remark 2], ???
	'' as  [CC Remark 2],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=3) as [CC Remark 3], ???
	'' as  [CC Remark 3],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id 
								     and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)) as [Pending Log Sendback reason 1],
					
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x
	--where x.ROWNUMBERS=1) as [Pending Log Remark 1],

	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Remark 1],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--ap.SCRemark as [SC Remark],
	cap.sc_remark as [SC Remark],

	--ap.OpsRemark as [Ops Remark],
	cap.ops_remark as [Ops Remark],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101)  as [Pending Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1)  as [Pending Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1),101) as [Pending Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Response By 1],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 1) as [Pending Log Sendback send from 1],

	--------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)) as [Pending Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101)  as [Pending Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2)  as [Pending Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2),101) as [Pending Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 2) as [Pending Log Sendback send from 2],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending') x 
		               where x.ROWNUMBERS = 3)) as [Pending Log Sendback reason 3],
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101)  as [Pending Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3)  as [Pending Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3),101) as [Pending Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 3) as [Pending Log Sendback send from 3],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)) as [Pending Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101)  as [Pending Log Sendback date 4],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4)  as [Pending Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4),101) as [Pending Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 4) as [Pending Log Sendback send from 4],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)) as [Pending Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101)  as [Pending Log Sendback date 5],
	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],
	 (select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5)  as [Pending Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5),101) as [Pending Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Response By 5],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	--------------
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id and log_type = 'Pending')x 
		               where x.ROWNUMBERS = 5) as [Pending Log Sendback send from 5],

	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)) as [Tele Log Sendback reason 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark 1],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark 1],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101)  as [Tele Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1)  as [Tele Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1),101) as [Tele Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Response By 1],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Response By 1],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 1) as [Tele Log Sendback send from 1],

	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)) as [Tele Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark 2],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101)  as [Tele Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2)  as [Tele Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2),101) as [Tele Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Response By 2],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 2) as [Tele Log Sendback send from 2],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)) as [Tele Log Sendback reason 3],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark 3],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101)  as [Tele Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3)  as [Tele Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3),101) as [Tele Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Response By 3],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 3) as [Tele Log Sendback send from 3],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)) as [Tele Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark 4],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101)  as [Tele Log Sendback date 4],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4)  as [Tele Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4),101) as [Tele Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Response By 4],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 4) as [Tele Log Sendback send from 4],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],
	(select m.name from m_reason m 
	  where m.pk_id = (select top 1 x.fk_m_rework_reason_id 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)) as [Tele Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark 5],
	(select top 1 x.remark 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],
	CONVERT(VARCHAR(24),(select top 1 x.send_back_date 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101)  as [Tele Log Sendback date 5],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],
	(select top 1 x.send_back_by 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5)  as [Tele Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],
	(select top 1 x.remark_response 
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],
	CONVERT(VARCHAR(24),(select top 1 x.received_date
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5),101) as [Tele Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Response By 5],
	(select top 1 x.received_by
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Response By 5],
	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from cc_rework
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5],
	(select top 1 x.user_type
						from (select ROW_NUMBER() OVER (ORDER BY  cre.Send_Back_Date ASC) AS ROWNUMBERS, cre.* 
								from cc_rework cre
								where cre.fk_application_information_id = cap.fk_application_information_id  and cre.log_type = 'Tele')x 
		               where x.ROWNUMBERS = 5) as [Tele Log Sendback send from 5],
	--cus.Gender,
	
	(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.fk_group_id = 38) as Gender,

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID') 
	--ORDER BY TypeOfIdentification) as [Expried Date For ID],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('ID')
					order by mit.name) as [Expried Date For ID],

	--(select top 1 IdentificationNo from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Visa],
	(select top(1)CONVERT(VARCHAR(10), id.identification_no, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Visa],

	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from customer_identification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Expried Date For Visa],
	(select top(1)CONVERT(VARCHAR(10), id.expried_date, 101) 
					from customer_identification id inner join m_identification_type mit
												  on id.fk_m_identification_type_id = mit.pk_id
					where mit.name in('Visa')
					order by mit.name) as [Expried Date For Visa],

	--cus.MaritalStatus, 
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id) as MaritalStatus,
	--cus.Nationality,
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,
	--ap.AccountNumber, 
	ap.application_no as AccountNumber, 

	--ap.PaymentMethod,
	
	(select top(1)m.name from m_payment_type m
					where ap.fk_m_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,

	--cus.OwnerResidentialAdd as [Ownership],
	cus.owner_residential_address as [Ownership],

	--ap.HolderCurrencyDepositedAmount as [Deposit Amount],
	cap.holder_currency_deposited_amount as [Deposit Amount],

	--ap.HolderCurrentAccountNo as [Current Acc],
	cap.holder_current_account_no as [Current Acc],

	--ap.HolderDepositedCurrency as [Currency],
	(select top(1)m.name from m_definition_type m
					    where cap.fk_holder_deposited_currency_id = m.pk_id 
					          and fk_group_id =77 and m.is_active = 1) as [Currency],

	--cus.CompanyGenericCode as [Company Generic Code],
	
	(select top(1) co.company_code from company_information co
					where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Generic Code],

	--cus.CompanyAddress + ' ' + cus.CompanyWard + ' ' + cus.CompanyDistrict + ' ' + CompanyCity as [Company Full Address],
	(select top(1) co.company_address + ' ' + co.company_ward + ' ' + co.company_district
					 + ' ' + co.company_city
	               from company_information co
				   where ci.fk_company_information_id = co.pk_id and co.is_active =1) as [Company Full Address],
	--CONVERT(varchar, CAST([FinalIncome] AS MONEY), 1)  as [Final Monthly Income]
	(select top(1)CONVERT(varchar, CAST(cin.final_income AS MONEY), 1)  from cc_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Final Monthly Income]
	FROM
		cc_application cap 
		inner join application_information ap on cap.fk_application_information_id = ap.pk_id
		inner join cc_customer_information cus on cap.fk_application_information_id = cus.fk_application_information_id 
		inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
		left join cc_company_information co on co.fk_customer_income_id = ci.pk_id

	WHERE ap.fk_m_type_id = 11
	and	cast(ap.Received_Date as date) >= cast (@FromDate as date)
	and cast (Received_Date as date) <= cast (@ToDate as date)
	ORDER BY Seq

	--drop table #tbl_CCApplication
	--drop table cc_rework
	--drop table cc_rework
	--drop table #tbl_CCCustomer
	--drop table customer_identification
	--drop table application_action_log	
	--drop table #tbl_CCRemark
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_sales_master]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_sales_master]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
--ap.ApplicationNo,
ap.application_no as  ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--cc.FullName as PrimaryCardHolderName,
ci.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),ci.dob,106) as PrimaryCardHolderDOB,
--cc.OperationSelfEmployed as SelfEmployed,

(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,

--cc.CompanyName as CompanyName,
(select top(1) co.company_name from cc_company_information co
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyName,

--cc.CompanyCity as CompanyCity,
(select top(1) m.name from cc_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyCity,
--cc.BusinessType as CompanyType,

(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,

--HolderInitial as InitialLimit,
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id)AS  InitialLimit,

--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,
--ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,

--CONVERT(VARCHAR(24),DecisionDate,106) as Final_DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as Final_DecisionDate,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as DECISION_STATUS,

--FinalLimitApproved as FinalApprovedLimit,
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)AS  FinalApprovedLimit,
--InterestRateSuggested as Interest,
(select top(1)CONVERT(varchar, CAST(apr.interest_rate_suggested AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as Interest,

--ap.CardTypeName as CardType,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType,
--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,
--ap.TypeApplicationName as TypeApplication,
cap.type_of_application as TypeApplication,
--PIDOfSaleStaff as SalesCode,
ap.sale_staff_bank_id as SalesCode,
--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='OSSendBack')) as Pending_OSSendback,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log lg where lg.fk_application_information_id =ap.pk_id and (lg.action ='OSSendBack')) as Pending_OSSendback,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'CISendBack%')) as Pending_CISendback

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log lg where lg.fk_application_information_id =ap.pk_id and (lg.action like 'CISendBack%')) as Pending_CISendback
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_sales_master_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_sales_master_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
ROW_NUMBER() OVER (ORDER BY ap.[received_date] ASC) AS Seq,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as [Receiving Date],
CONVERT(VARCHAR(24),ap.[received_date],106) as [Receiving Date],
--cc.FullName as Customer_Name,
cus.full_name as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cusi.identification_no
  from customer_identification cusi join  [m_identification_type] m 
     on cusi.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cusi.fk_customer_information_id = m.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cusi.identification_no
  from customer_identification cusi join  [m_identification_type] m 
     on cusi.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cusi.fk_customer_information_id = m.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,

(select top(1) cusi.identification_no
  from customer_identification cusi join  [m_identification_type] m 
     on cusi.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cusi.fk_customer_information_id = m.pk_id) as CustomerPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cusi.identification_no
  from customer_identification cusi join  [m_identification_type] m 
     on cusi.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cusi.fk_customer_information_id = m.pk_id) as CustomerPreviousPP

--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
--cc.OperationSelfEmployed as SelfEmployed,
--cc.CurrentPosition as JobTitle,
--cc.CompanyName as CompanyName,
--cc.BusinessType as CompanyType,
--cc.RLSCompanyCode as RLSCompanyCode,

--CONVERT(VARCHAR(24),ci.DOB,106) as DOB,
--ci. as SelfEmployed,
--ci.CurrentPosition as JobTitle,
--ci.CompanyName as CompanyName,
--ci.BusinessType as CompanyType,
--ci.RLSCompanyCode as RLSCompanyCode,

--CONVERT(varchar, CAST(cpl.PersonalLoanAmountApplied AS MONEY), 1) AS [Loan_Amt_Applied],
--cpl.LoanPurpose,
--ap.ChannelD,
--ap.LocationBranchName,
--ap.ARMCode,
--cc.PaymentType as PaymentMethod,
--ap.CardProgramName as Program,
--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
--FinalApprovalStatus as DECISION_STATUS,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
--cpl.LoanTenor AS [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
--dis.DisbursalStatus,
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
--dis.LoanAccountNo,
--ap.Status as CurrentStatus,
--ap.ProgramCodeName as ProgramCode,
--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='OSSendBack')) as Pending_OSSendback,
--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'CISendBack%')) as Pending_CISendback,
--ap.PIDOfSaleStaff as SalesCode,
--cc.PrimaryPhoneNo as MobilePhone,
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Customer Address]
FROM
	[dbo].[PL_Application] PL
	inner join application_information ap on ap.pk_id = pl.fk_application_information_id 
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
--	LEFT JOIN CCPLApplication cpl ON cpl.CCApplicationNo = ap.ApplicationNo
	LEFT JOIN [dbo].[pl_disbursement_information] dis ON dis.fk_application_information_id = ap.pk_id

WHERE 
cast(ap.received_date as date) >= cast(@FromDate as date)
and cast(ap.received_date as date) <= cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_sas_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_sas_reports]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
   CONVERT(VARCHAR(10), ap.received_date, 101) as [ReceivedDate],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id
  order by m.name) as  [Primary Card Holder ID],

--cc.FullName as [Primary Card Holder Name],
cus.full_name	as [Primary Card Holder Name],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id
  order by m.name ) as  [Primary Card Holder Previous ID],

 CONVERT(VARCHAR(10), cus.dob, 101) as [DOB],

--CONVERT(varchar, CAST([ap].FinalLoanAmountSuggestedBySystem AS MONEY), 1) AS [Loan amount applied],
 CONVERT(varchar, CAST(apr.final_loan_amount_suggested_by_system AS MONEY), 1) AS [Loan amount applied],
--CONVERT(varchar, CAST([plApp].PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan amount approved],
  '0' AS [Loan amount approved],
--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as  [Date of Decision],
--CONVERT(VARCHAR(10), (SELECT TOP 1 DisbursedDate db FROM Disbursement db WHERE ApplicationNo = ap.ApplicationNo), 101) as [Disbursed date],
'' as [Disbursed date],
--ap.EMISuggested AS EMI,
(select top(1) capi.emi_suggested from cc_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as EMI,
--ap.ChannelD AS Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1)AS Channel,
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode AS [ARM Code],
 ap.arm_code as [ARM Code],
--ap.SalesPWID AS [PID of sale staff],
ap.sale_staff_bank_id as [PID of sale staff],
--cc.CompanyPhone AS [Office Phone],
co.office_telephone as  [Office Phone],

--cc.HomePhoneNo AS [Home Phone],
cus.home_phone_no as  [Home Phone],
--cc.PrimaryPhoneNo AS [Mobile Phone],
cus.primary_phone_no AS [Mobile Phone],
--cc.PermAddress AS [Permanent address],
cus.permanent_address AS [Permanent address],
--cc.CompanyCode as [Company CAT],
co.company_code as [Company CAT],

--cc.CompanyName as [Company Name],
co.company_name as CompanyName,
--cc.CompanyAddress as [Company Address],
co.Company_Address as [Company Address],
--cc.TypeEmployment as [Employment type],
(select top(1) m.name from cc_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment type],
--cc.Industry,
 '' as Industry,
--cc.CurrentPosition as [Current Position],
(select top(1)m.name from m_position m
				where m.pk_id = co.fk_m_position_id and m.is_active = 1) as [Current Position],
--cc.Occupation,
(select top(1)m.name from cc_company_information co  inner join m_occupation m
																  on m.pk_id = co.fk_m_occupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Occupation,
--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.CreditBureauType as [Bureau Type]
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type]

FROM
    [dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_approval_information apr on apr.fk_application_information_id = ap.pk_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_sms_nsg]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_sms_nsg]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
ap.application_no as ApplicationNo,
ap.received_date as ReceivedDate,
--ap.[Status] as [CurrentStatus],
(select top(1) m.name from m_status m
				where ap.fk_m_status_id = m.pk_id) as [CurrentStatus],

--apl.PL_FinalApprovalStatus as [FinalApprovalStatus],
(select top(1) m.name from approval_information apr inner join m_status 
												on apr.fk_status_id = m.pk_id and m.is_active =1
				where apr.fk_application_information_id = ap.pk_id) as [FinalApprovalStatus],

--CONVERT(VARCHAR(10),DecisionDate, 101) as [FinalDecisionDate],
(select top(1) CONVERT(VARCHAR(10),apr.date_of_decision, 101)  from approval_information apr 
				     where apr.fk_application_information_id = ap.pk_id) as [FinalDecisionDate],

--CONVERT(VARCHAR(10),al.ActionDate, 101) as [ActionDateNSG],
CONVERT(VARCHAR(10),al.action_date, 101) as [ActionDateNSG],
----QueueNSG

--al.ActionBy AS [NSG By],
al.action_by as [NSG By],
--cc.FullName,
ci.full_name as  FullName,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder ID],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder Previous ID],

--cc.PrimaryPhoneNo AS [Mobile Phone],
cc.primary_phone_no as [Mobile Phone],
--cc.EmailAddress1,
cc.email_address_1 as  EmailAddress1,
--cc.EmailAddress2,
cc.email_address_2 as  EmailAddress2,
--cc.EmailAddress3,
cc.email_address_3 as  EmailAddress3,
--cc.Nationality,

(select top(1)m.name from m_nationality m
				where cc.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--ap.ChannelD AS Channel,
 (select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS Channel,

--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],

--(SELECT TOP 1 Remark FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 1) AS [Remark_TeleVerifier],
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  [Remark_TeleVerifier],
----Remark_Underwriter
----ProductType
--cc.CompanyCode,
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CompanyCode,
----CompanyType
--cc.RLSCompanyCode,
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--ap.ProgramCodeName
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id)  as ProgramCodeName
FROM
	[dbo].[application_information] ap 
	inner join customer_information ci on ap.pk_id = ci.fk_application_information_id
	inner join cc_customer_information cc on ap.pk_id = cc.fk_application_information_id
	left join application_action_log al on al.fk_application_information_id = ap.pk_id
	inner join m_type m on ap.fk_m_type_id = m.pk_id and m.name in('CC','CreditCard')
	--left join CCPLApplication apl ON apl.CCApplicationNo = ap.ApplicationNo
	
WHERE
	al.[Action] = 'NSG'
and	Cast(ap.received_date as Date) >= Cast(@FromDate as Date)
and Cast(ap.received_date as Date) <= Cast(@ToDate as Date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tat_logs]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tat_logs]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.Application_No,lg.Action_Date ASC) AS Seq,
ap.application_no as ApplicationNo,
lg.[action],
lg.action_by,
'' as ActionName,
CONVERT(VARCHAR(10), lg.action_date, 101) + ' ' + CONVERT(VARCHAR(8), lg.action_date, 108) as [Action Date],
'' as CurrentRole,
Duration
FROM
	[dbo].cc_tat_logs lg --join LoginUser lu on lu.PeoplewiseID = lg.ActionBy
	inner join application_information ap on ap.pk_id = lg.fk_application_information_id
	inner join cc_application cap on cap.fk_application_information_id = ap.pk_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY lg.fk_application_information_id,lg.action_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tat_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tat_report]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo as [Application No],
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
--cc.FullName as [Customer Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of ID],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Customer ID],
--cc.PrimaryPhoneNo as [Customer Mobile],
--cc.CompanyCode as [Company Code],
--cc.RLSCompanyCode as RLSCompanyCode,
--ap.ProgramCodeName as ProgramCode,
--ap.Status as CurrentStatus,
--vf.[Status] as TeleStatus,
--ap.ChannelD as Channel,
--ap.LocationBranchName as City,
--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) AS [Amount Applied],
--CONVERT(varchar, CAST(ccPL.PLFinalLoanAmountApproved AS MONEY), 1) AS [Amount Approved],
--ap.ARMCode,
--'No' As [Rework to SC],
--'No' As [Rework to CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='SC')/60 as [Sale.Coor],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='OS')/60 as [Op.Supports],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('CI2','CI1'))/60 as [CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI_TELE')/60 as [Tele],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='LO')/60 as [L.Operation],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],
--ap.EOpsTxnRefNo,
--ap.EOpsTxnRefNo2,
--cc.EmailAddress1,
--cc.EmailAddress2,
--cc.EmailAddress3,
--cc.Nationality,
--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as [Application sign date]

--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	left join CCPLApplication ccPL on ap.ApplicationNo=ccPL.CCApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
--	outer apply
--	(
--		select top 1 status from VerificationForm v
--		where v.ApplicationNo = ap.ApplicationNo
--		and v.IsTeleVerify =1
--	) vf
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tat_report_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tat_report_ci]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--ap.ApplicationNo AS [Application No],
ap.application_no AS [Application No],
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
 (select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [Date of Decision],

--CONVERT(VARCHAR(10), (select top 1 action_date FROM [LITS].[dbo].[AppActionLog] al where al.ApplicationNo = ap.ApplicationNo and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 action_date FROM [LITS].[dbo].[AppActionLog] al where al.ApplicationNo = ap.ApplicationNo and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

CONVERT(VARCHAR(10), (select top 1 action_date FROM [dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and al.[Action] in ('CIApproved' ,'CIApprovedPL' ,'CIApprovedCC'  ,'CIApprovedBD' ,'CIRejected' ,'CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 action_date FROM [dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and  al.[Action] in('CIApproved' ,'CIApprovedPL' ,'CIApprovedCC'  ,'CIApprovedBD' ,'CIRejected' ,'CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

--ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--ap.TypeApplicationName as [Application Type],
 cap.type_of_application as [Application Type],
--ap.CardProgramName as [Card Program],
(select top(1) cp.name from  cc_card_program cp
				where cap.fk_card_program_id = cp.pk_id) as [Card Program],

--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName as [Card Type],
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_1_id = ct.pk_id)  as [Card Type],

--ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_2_id = ct.pk_id)  as [Card Type 2],
--ap.IsTwoCardType as [IsTwoCardType],
cap.is_two_card_type as [IsTwoCardType],
--CustomerSegment as [Customer Segment],
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
--cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as TypeOfIdentification,
(select top(1) cid.identification_no
  from customer_identification cid join  [m_identification_type] m 
									on cid.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cid.fk_customer_information_id = ci.pk_id
   ORDER BY m.name) as TypeOfIdentification,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary CardHolder ID],
(select top(1) cid.identification_no
  from customer_identification cid join  [m_identification_type] m 
									on cid.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cid.fk_customer_information_id = ci.pk_id
   ORDER BY m.name) as [Primary CardHolder ID],

--cc.Nationality as [Primary Card Holder Nationality],
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as [Primary Card Holder Nationality],
--cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
cus.primary_phone_no as [Primary Card Holder Mobile Phone Number],
--cc.EmailAddress1 as [Email Address 1],
cus.email_address_1 as [Email Address 1],
--cc.EmailAddress2 as [Email Address 2],
cus.email_address_2 as [Email Address 2],
--cc.TypeEmployment as [Employment Type],
(select top(1) m.name from cc_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment Type],

--cc.CompanyName as [Company Name],
(select top(1) co.company_name from cc_company_information co
								where co.fk_cc_customer_information_id = cus.pk_id)as [Company Name],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code],
--cc.BusinessType as [Company Type],
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id)as [Company Type],
--cc.RLSCompanyCode as [Company Code RLS],
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code RLS],
--ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS [Channel],
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode as [ARM Code],
ap.ARM_Code as [ARM Code],
--ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,
--(select top 1 [status] from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleStatus,
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  TeleStatus,

--(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[CCTATLogs] WHERE ApplicationNo = ap.ApplicationNo and CurrentRole like 'CI%') AS [Queued time at CI queue ],
(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[cc_tat_logs] WHERE fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id)AS [Initial Limit],
--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='SC')/60 as [TAT Sales Coor],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='OS')/60 as [TAT Ops Support],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI_TELE')/60 as [TAT Tele],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI1')/60 as [TAT Recommender],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI2')/60 as [TAT Approver],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('CI2','CI1'))/60 as [TATA - CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='SC')/60 as [TAT Sales Coor],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='OS')/60 as [TAT Ops Support],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI_TELE')/60 as [TAT Tele],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI1')/60 as [TAT Recommender],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI2')/60 as [TAT Approver],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('CI2','CI1'))/60 as [TATA - CI],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

FROM
	[dbo].[CC_Application] cap
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tat_report_ci_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tat_report_ci_sales]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
--ap.ApplicationNo AS [Application No],
ap.application_no AS [Application No],
--CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [Date of Decision],

CONVERT(VARCHAR(10), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

--ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id)  as [Product Type],
--ap.TypeApplicationName as [Application Type],
cap.type_of_application  as [Application Type],
--ap.CardProgramName as [Card Program],
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],
--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName as [Card Type],
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_1_id = ct.pk_id and ct.is_active =1) as [Card Type],
--ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_2_id = ct.pk_id and ct.is_active =1) as [Card Type 2],
--ap.IsTwoCardType as [IsTwoCardType],
 cap.is_two_card_type  as [IsTwoCardType],
--CustomerSegment as [Customer Segment],
(select top(1)m.name from m_customer_segment m
				where cus.fk_customer_segment_id = m.pk_id and m.is_active = 1) as [Customer Segment],
--BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

--(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],

--cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--cc.Nationality as [Primary Card Holder Nationality],

(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Primary Card Holder Nationality],
--cc.TypeEmployment as [Employment Type],
(select top(1) m.name from cc_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment Type],
--cc.CompanyName as [Company Name],
(select top(1) co.company_name from cc_company_information co
								where co.fk_cc_customer_information_id = cus.pk_id)as [Company Name],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code],
--cc.BusinessType as [Company Type],
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id)as [Company Type],
--cc.RLSCompanyCode as [Company Code RLS],
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code RLS],
--ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS Channel,
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode as [ARM Code],
 ap.ARM_Code as [ARM Code],
--ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,
--(select top 1 [status] from VerificationForm
--		where fk_application_information_id= ap.pk_id
--		and IsTeleVerify =1) as TeleStatus,
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  TeleStatus,

--(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[cc_tat_logs] WHERE fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[cc_tat_logs] lg WHERE lg.fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id)AS [Initial Limit],

--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],

(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='SC')/60 as [TAT Sales Coor],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='OS')/60 as [TAT Ops Support],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI_TELE')/60 as [TAT Tele],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI1')/60 as [TAT Recommender],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI2')/60 as [TAT Approver],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('CI2','CI1'))/60 as [TATA - CI],
(select sum(Duration) from cc_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tat_report_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tat_report_sales]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--ap.ApplicationNo as [Application No],
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
--cc.FullName as [Customer Name],
--cc.CompanyCode as [Company Code],
--cc.RLSCompanyCode as RLSCompanyCode,
--ap.ProgramCodeName as ProgramCode,
--ap.Status as CurrentStatus,
--vf.[Status] as TeleStatus,
--ap.ChannelD as Channel,
--ap.LocationBranchName as City,
--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) AS [Amount Applied],
--CONVERT(varchar, CAST(ccPL.PLFinalLoanAmountApproved AS MONEY), 1) AS [Amount Approved],
--ap.ARMCode,
--'No' As [Rework to SC],
--'No' As [Rework to CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='SC')/60 as [Sale.Coor],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='OS')/60 as [Op.Supports],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('CI2','CI1'))/60 as [CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI_TELE')/60 as [Tele],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='LO')/60 as [L.Operation],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],
--ap.EOpsTxnRefNo,
--ap.EOpsTxnRefNo2,
--cc.Nationality,
--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as [Application sign date]

--FROM
--	[dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	left join CCPLApplication ccPL on ap.ApplicationNo=ccPL.CCApplicationNo
--	LEFT JOIN Disbursement dis ON dis.ApplicationNo = ap.ApplicationNo
--	outer apply
--	(
--		select top 1 status from VerificationForm v
--		where v.ApplicationNo = ap.ApplicationNo
--		and v.IsTeleVerify =1
--	) vf
	
--WHERE ap.ProductTypeName in ('PN','BD')
--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tatlogs]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tatlogs]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.Application_No,lg.Action_Date ASC) AS Seq,
ap.application_no as ApplicationNo,

--SUBSTRING(lg.ApplicationNo,1,2) as ProductTypeName,
m.name as ProductTypeName,

lg.[action],
lg.action_by,
'' as ActionName,
CONVERT(VARCHAR(10), lg.action_date, 101) + ' ' + CONVERT(VARCHAR(8), lg.action_date, 108) as [Action Date],
lg.current_role as CurrentRole,
duration
FROM
	[dbo].cc_tat_logs lg --join LoginUser lu on lu.PeoplewiseID = lg.ActionBy
	inner join application_information ap on ap.pk_id = lg.fk_application_information_id
	inner join cc_application cap on ap.pk_id = cap.fk_application_information_id
	inner join m_type m on ap.fk_m_type_id = m.pk_id
	
WHERE
	Cast(ap.received_date as Date) >= Cast(@FromDate as Date) and
	Cast(ap.received_date as Date) <= Cast(@ToDate as Date)
ORDER BY ap.application_no, lg.action_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tatlogs_report_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 -- exec sp_report_cc_application_get_cc_tatreportci '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tatlogs_report_ci]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
	ap.application_no AS [Application No],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as [EverSendBack],
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as [EverSendBack],

	(select Top 1 CONVERT(VARCHAR(20), Action_Date, 120) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date asc) as [First Date submitted to CIs queue],


	(select Top 1 CONVERT(VARCHAR(20), Action_Date, 120) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) as [Last-time-Requeue to CIs queue],
--	--
	dbo.[fuConvertMinutesToDays]((select Top 1 Datediff(mi, Action_Date, GETDATE()) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	-(select COUNT(*)*24*60 from m_bank_holiday where bank_holiday between (select Top 1 Action_Date from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) and GETDATE())

	-(select Top 1 Datediff(wk, Action_Date, GETDATE())*48*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	-(select Top 1 Datediff(dd, Action_Date, GETDATE())*16*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	+(select Top 1 Datediff(wk, Action_Date, GETDATE())*32*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	+(select COUNT(*)*16*60 from m_bank_holiday where bank_holiday between (select Top 1 Action_Date from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) and GETDATE())
	) 
	as [Aging at CIs queue],
--	--
--	CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

	CONVERT(VARCHAR(10), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by Action_Date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by Action_Date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],


--	ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--	ap.TypeApplicationName as [Application Type],
cap.type_of_application as [Application Type],
--	ap.CardProgramName as [Card Program],
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],
--	ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

--	ap.CardTypeName as [Card Type 1],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type 1],

--	ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type 2],
--	ap.IsTwoCardType as [IsTwoCardType],
   cap.is_two_card_type as [IsTwoCardType],
--	CustomerSegment as [Customer Segment],
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--	BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--	(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
 (CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
--	cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--	(select top 1 TypeOfIdentification from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as TypeOfIdentification,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as TypeOfIdentification,

--	(select top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary CardHolder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary CardHolder ID],
--	cc.Nationality as [Primary Card Holder Nationality],
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as [Primary Card Holder Nationality],
--	cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
cus.primary_phone_no   as [Primary Card Holder Mobile Phone Number],
--	cc.EmailAddress1 as [Email Address 1],
cus.email_address_1 as [Email Address 1],
--	cc.EmailAddress2 as [Email Address 2],
cus.email_address_2 as [Email Address 2],
--	cc.TypeEmployment as [Employment Type],
(select top(1)m.name from m_employment_type m
					where co.fk_m_employment_type_id = m.pk_id) as  [Employment Type],
--	cc.CompanyName as [Company Name],
co.company_name	as [Company Name],
--	cc.CompanyCode as [Company Code],
(select top(1) mc.name from m_company_list cl inner join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = ci.fk_company_information_id) as [Company Code],
--	cc.BusinessType as [Company Type],
(select top(1) m.name from  m_business_nature m 		
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],
--	cc.RLSCompanyCode as [Company Code RLS],
co.company_code_rls as [Company Code RLS],
--	cc.CompanyPhone as [Office Phone],
co.office_telephone as [Office Phone],
--	ap.CreditBureauType as [Bureau Type],
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--	ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--	ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],

--	ap.ARMCode as [ARM Code],
ap.arm_code as [ARM Code],
--	ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Current Status],

--	ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,

--	(select top 1 [status] from VerificationForm
--			where ApplicationNo = ap.ApplicationNo
--			and IsTeleVerify =1) as TeleStatus,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as TeleStatus,

--	(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[CCTATLogs] WHERE ApplicationNo = ap.ApplicationNo and CurrentRole like 'CI%') AS [Queued time at CI queue],

(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[cc_tat_logs] WHERE fk_application_information_id = ap.pk_id and current_role like 'CI%') AS [Queued time at CI queue],

--	ccPL.PersonalLoanAmountApplied,
'' as PersonalLoanAmountApplied,
--	ccPL.PLFinalLoanAmountApproved,
'' as PLFinalLoanAmountApproved,
--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
CONVERT(varchar, CAST(cap.Holder_Initial AS MONEY), 1) AS [Initial Limit],
--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],

--	cc.[CleanEB], 
 '' as [CleanEB], 
	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='SC')/60 as [TAT Sales Coor],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='OS')/60 as [TAT Ops Support],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE')/60 as [TAT Tele],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI1')/60 as [TAT Recommender],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI2')/60 as [TAT Approver],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('CI2','CI1'))/60 as [TATA - CI],

	(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

	FROM
		[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tele_report_no_results]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_cc_application_gettelereportnoresults '2019-01-01','2019-04-20'
CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tele_report_no_results]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	CONVERT(VARCHAR(24),ap.Received_Date,103) as [ReceivingDate],
	CONVERT(VARCHAR(24),ap.Received_Date,108) as [ReceivingTime],
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	cc.FullName as CustomerName,
    cus.full_name as CustomerName,

	null as VerifiedID,

--	(select top 1 IdentificationNo from CCIdentification cccId 
--	 where cccId.CustomerID = ccId.CustomerID and IdentificationNo <> ''
--	 order by TypeOfIdentification) as IdentificationNo,
	(select top 1 i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id  and m.is_active=1
								
		where i.fk_customer_information_id = ci.pk_id and i.identification_no<>''
		order by m.name) as IdentificationNo,

	 null as VerifiedDOB,

--	 CONVERT(VARCHAR(24),cc.DOB,103) as DOB,
	CONVERT(VARCHAR(24),cus.dob,103) as DOB,
--	 null as VerifiedMobilephone,
	null as VerifiedMobilephone,
--	 cc.CurrentPosition,
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as CurrentPosition,

	 vf.verified_position,

--	 cc.Occupation,
	(select top(1) m.name from m_occupation m
						 where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	 vf.verifedOccupation,

--	 cc.TradingArea,
	(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

	 vf.Verified_Area,

--	 cc.RLSCompanyCode, 
	co.company_code_rls as RLSCompanyCode,
--	 cc.CompanyCode,
	co.company_code as CompanyCode,
--	 cc.CompanyName,
	 co.company_name as CompanyName,

	 vf.company_address as companyaddress,
	
	 null as VerifiedPhone,

	 null as NoAttemps,

	 vf.salary_customer as SalaryCustomer,

	 vf.bank_name as BankName,

	 vf.salary_on_date SalaryOnDate,

	 vf.salary_amount SalaryAmount,

	 CONVERT(VARCHAR(24),vf.result_dated,103)  as ResultDated,

	 vf.result_status as ResultStatus,

	 vf.is_send_sms as IsSendSMS,

	 vf.Remark,

	 vf.pk_id as VerificationID,

	 ( select top(1) m.name from m_status m
							where vf.fk_status_id = m.pk_id and m.is_active = 1) as TeleStatus,

	 vf.out_source_verify_name as VerifyName,

	 vf.updated_by as BankIDTeleVerify,

	 (
		select top 1 u.full_name from dbo.application_action_log a left join dbo.user_login u on u.Peoplewise_Id=a.Action_By
		where a.fk_application_information_id = ap.pk_id and a.Action='CI_NSG' order by a.action_date desc
	  ) NSG,

  vf.telephone_action as [Action]
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
	cross apply
	(
		select top 1 * from verification_form v
		where v.fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1 and v.is_upload=1
		and v.telephone_action <> 'Completed'
	) vf
	outer apply
	(	
		select top 1 i.fk_customer_information_id, i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id 
													 and m.name in('ID','Passport','Previous_ID','Previous_PP')
								
		where i.fk_customer_information_id = ci.pk_id
		order by m.name
	) ccId
WHERE
        Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_tele_report_none_outsource]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_cc_application_get_tele_report_none_outsource]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	CONVERT(VARCHAR(24),ap.Received_Date,103) as [ReceivingDate],
	CONVERT(VARCHAR(24),ap.Received_Date,108) as [ReceivingTime],
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	cc.FullName as CustomerName,
    cus.full_name as CustomerName,

	null as VerifiedID,

--	(select top 1 IdentificationNo from CCIdentification cccId 
--	 where cccId.CustomerID = ccId.CustomerID and IdentificationNo <> ''
--	 order by TypeOfIdentification) as IdentificationNo,
	(select top 1 i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id  and m.is_active=1
								
		where i.fk_customer_information_id = ci.pk_id and i.identification_no<>''
		order by m.name) as IdentificationNo,

	 null as VerifiedDOB,

--	 CONVERT(VARCHAR(24),cc.DOB,103) as DOB,
	CONVERT(VARCHAR(24),cus.dob,103) as DOB,
--	 null as VerifiedMobilephone,
	null as VerifiedMobilephone,

(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as CurrentPosition,

	 vf.verified_position,

--	 cc.Occupation,
	(select top(1) m.name from m_occupation m
						 where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	 vf.verifedOccupation,

--	 cc.TradingArea,
	(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

	 vf.Verified_Area,

--	 cc.RLSCompanyCode, 
	co.company_code_rls as RLSCompanyCode,
--	 cc.CompanyCode,
	co.company_code as CompanyCode,
--	 cc.CompanyName,
	 co.company_name as CompanyName,

	 vf.company_address as companyaddress,
	
	 null as VerifiedPhone,

	 null as NoAttemps,

	 vf.salary_customer as SalaryCustomer,

	 vf.bank_name as BankName,

	 vf.salary_on_date SalaryOnDate,

	 vf.salary_amount SalaryAmount,

	 CONVERT(VARCHAR(24),vf.result_dated,103)  as ResultDated,

	 vf.result_status as ResultStatus,

	 vf.is_send_sms as IsSendSMS,

	 vf.Remark,

	 vf.pk_id as VerificationID,

	 ( select top(1) m.name from m_status m
							where vf.fk_status_id = m.pk_id and m.is_active = 1) as TeleStatus,

	 vf.out_source_verify_name as VerifyName,

	 vf.updated_by as BankIDTeleVerify,

	 (
		select top 1 u.full_name from dbo.application_action_log a left join dbo.user_login u on u.Peoplewise_Id=a.Action_By
		where a.fk_application_information_id = ap.pk_id and a.Action='CI_NSG' order by a.action_date desc
	  ) NSG,

     vf.telephone_action as [Action]
FROM
	[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join cc_company_information co on co.fk_customer_information_id = ci.pk_id
	cross apply
	(
		select top 1 * from verification_form v
		where v.fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1 and v.is_upload=1
	) vf
	outer apply
	(	
		select top 1 i.fk_customer_information_id, i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id 
													 and m.name in('ID','Passport','Previous_ID','Previous_PP')
								
		where i.fk_customer_information_id = ci.pk_id
		order by m.name
	) ccId
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
and Cast(ap.received_date as date) <= Cast(@ToDate as date)
GO
/****** Object:  StoredProcedure [dbo].[sp_report_cc_application_get_verification_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_cc_application_get_verification_report]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
 SELECT 
    ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--	ap.ApplicationNo,
    ap.application_no as ApplicationNo,
--	CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
   CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--	ap.TypeApplicationName as TypeApplication,
    cap.type_of_application   as  TypeApplication,
--	cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--	(select top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPassportID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as  PrimaryCardHolderPreviousID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,

--	cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--	cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--	CONVERT(VARCHAR(24),cc.DOB,106) as HolderPrimaryDOB,
CONVERT(VARCHAR(24),cus.dob,106) as HolderPrimaryDOB,
--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where ApplicationNo=ap.ApplicationNo and BlackListCode<>null) as BlackList,
(select  (case when COUNT(*)>0 then 'Yes' else 'No' end) 
				from frm_black_list_log frm 
				where ap.pk_id = frm.fk_application_information_id and frm.fk_frm_black_list_code_id <> null) as BlackList,
--	cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from cc_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as SelfEmployed,
--	cc.CompanyName as CompanyName,
(select top(1) m.company_name from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as  CompanyName,
--	cc.BusinessType as CompanyType,
(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as CompanyType,
--	cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--	cc.TypeOfContract,
  
  (select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
--	CONVERT(VARCHAR(24),cc.ContractStart,106) as [StartDate],
CONVERT(VARCHAR(24),cus.contract_start,106) as [StartDate],
--	cc.ContractLength,
cus.contract_length as ContractLength,
--	(SELECT TOP 1 VerifedOccupation FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedOccupation,

(SELECT TOP 1 vf.verifedOccupation FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedOccupation,

--	(SELECT TOP 1 VerifiedPosition FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedPosition,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedPosition,

--	cc.TradingArea,
(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

--	cc.ResidentialCity AS [Current Address City],
(select top(1) m.name from m_city m
						 where cus.fk_residential_city_id = m.pk_id and m.is_active =1) AS [Current Address City],
--	cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as  RepaymentType,

--	CreditBureauType as CIC,
(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,
--	(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,

--	CONVERT(varchar, CAST([CurrentUnsecuredOutstanding] AS MONEY), 1) AS [Current Unsecured Outstanding Off Us],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from cc_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [Current Unsecured Outstanding Off Us],

--	CONVERT(varchar, CAST([CurrentTotalEMI] AS MONEY), 1) AS [Current Total EMI Off Us],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0)AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id),

--	CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS MonthlyIncomeDeclared,
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,
--	CONVERT(varchar, CAST([IncomeEligible] AS MONEY), 1) AS EligibleIncome,
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id)  AS EligibleIncome,
--	CONVERT(varchar, CAST([IncomeTotal] AS MONEY), 1) AS TotalMonthlyIncome,
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS TotalMonthlyIncome,

--	ap.CardTypeName as CardType,
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_1_id = ct.pk_id and ct.is_active =1) as CardType,
--	ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_card_type ct
				where cap.fk_card_type_2_id = ct.pk_id and ct.is_active =1) as [Card Type 2],
--	ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_card_program cp
				where cap.fk_card_program_id = cp.pk_id) as CardProgram,

--	(CASE WHEN ap.HolderDepositedCurrency = 'VND' THEN 'VND' ELSE 'Non-VND' END) as CurrencyDepositedAmount,
(select top(1) m.name from cc_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,

--	CONVERT(varchar, CAST([HolderCurrencyDepositedAmount] AS MONEY), 1) AS DespositedAmount,
  cap.holder_currency_deposited_amount  AS DespositedAmount,

--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS InitialLimit,
(select top(1) CONVERT(varchar, CAST(cap.holder_initial AS MONEY),1) ) AS InitialLimit,

--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS FinalApprovedLimit,
(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS FinalApprovedLimit,
--	FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) DECISION_STATUS,

--	(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by ActionDate desc) as Underwriter,

(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by action_date desc) as Underwriter,

--	(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action]  in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by ActionDate desc) as Approver,
(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by action_date desc) as Approver,

--	(SELECT TOP 1 [Level] FROM [CCCriteria] cr WHERE cr.[ApplicationNo] = ap.[ApplicationNo] ORDER BY cr.[Level] DESC ) as LevelName,
(SELECT TOP 1 m.[description] FROM [cc_criteria] cr inner join m_deviation_level m
													on cr.[fk_level_id] = m.pk_id and m.is_active =1
					WHERE cr.fk_application_information_id = ap.pk_id ORDER BY m.name DESC ) as LevelName,

--	CONVERT(VARCHAR(24),DecisionDate,106) as Final_DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as Final_DecisionDate,
--	(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as Rejected_Or_Cancelled_Reason,
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) and (m.name <> '' or m.name is not null)) as  Rejected_Or_Cancelled_Reason,
--	FinalMUEAtSCB,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_mue_at_scb,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as FinalMUEAtSCB,
--	MUE_CC,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.cc_mue,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as MUE_CC,

--	CONVERT(varchar, CAST([FinalTotalEMI] AS MONEY), 1) AS TotalEMI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS  TotalEMI,
--	FinalTotalDSR as [TotalDSR %],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_dsr,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [TotalDSR %],
--	FinalDTI as DTI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_dti,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DTI,
--	FinalLTV as TotalLTV,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_ltv,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as TotalLTV,

--	ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentStatus,
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	PIDOfSaleStaff as SaleCode,
ap.sale_staff_bank_id as SaleCode,
--	ARMCode,
ap.arm_code as ARMCode,
--	ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--	LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,

--	(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
cap.remark as Remark,
--	ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	ap.IsTwoCardType as [IsTwoCardType],
 cap.is_two_card_type  as [IsTwoCardType],
--	ap.HardCopyAppDate
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate
	FROM
		[dbo].[cc_application] cap 
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_appactionlog_get_report_tat]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_appactionlog_get_report_tat]
	@status1 int,
	@status2 int,
	@fdate datetime,
	@tdate datetime
AS
BEGIN

	select 
		ap.application_no as ApplicationNo,
		REPLACE(CONVERT(VARCHAR(11), ap.received_date, 106), ' ', '/') as ReceivedDate,
		st.name as Status,
		ap.arm_code as ARMCode,
		--p.[ECLoanAmountApplied] as AmountApplied,
		p.loan_amount_applied as AmountApplied,
		--p.[ECLoanAmountApproved] as AmountApproved,	.
		'' as AmountApproved,			
		st. name as StatusName,
		(select top(1)m.name from m_status m
						where ap.fk_tele_status_id = m.pk_id) as TeleStatus,
	
		--p.[TeleStatus],
		cus.full_name as CustomerName,

		--cus.[PassportID] as CustomerID,
        (select top(1)cid.identification_no from customer_identification cid
											where cid.fk_customer_information_id  = cus.pk_id) as CustomerID,

		cus.mobile_no_1 as CustomerMobile,

		--cc.[Name] as CompanyCodeName,
		(select top(1) mc.name from m_company_list cl join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = cus.fk_company_information_id) as CompanyCodeName,
						
		sc.name as ChannelName,
		--ct.[Name] as CityBranch,
		(select top(1) mc.name from m_customer_type mc
						where mc.pk_id = cus.fk_m_customer_type_id) as CityBranch,

		'' as RLSCompanyCode,

		--p.ProgramCode,
		(select top(1) m.name from m_program_code m
						where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,

		(case when (select count(*) from dbo.application_action_log l 
									where (l.fk_application_information_id = p.fk_application_information_id 
									and [action] = 'LOReworkToSC')) > 0 then 'YES' else 'NO' end) as ReworkSC,

		(case when (select count(*) from dbo.application_action_log l
									where (l.fk_application_information_id = p.fk_application_information_id  
									and [action] = 'LOReworkToCI')) > 0 then 'YES' else 'NO' end) as ReworkCI,

		cus.email_address_1,
		cus.email_address_2,
		'' as EmailAddress3,

		--c.NationalityCode,
		(select top(1) m.name from m_nationality m
						where m.pk_id = cus.fk_m_nationality_id_1) as NationalityCode,

		ap.eops_txn_ref_no_1 as EOpsTxnRefNo,

		REPLACE(CONVERT(VARCHAR(11), ap.hard_copy_app_date, 106), ' ', '/') as HardCopyAppDate,
		--REPLACE(CONVERT(VARCHAR(11), p.[ApplicationSignDate], 106), ' ', '/') as [ApplicationSignDate]
		'' as [ApplicationSignDate]

	from [dbo].[pl_application] p join application_information ap on p.fk_application_information_id = ap.pk_id
	left join [dbo].[m_status] st on st.pk_id = p.fk_status_id
	left join [dbo].m_sales_channel sc on sc.pk_id = ap.fk_m_sales_channel_id
	--left join [dbo].[CustomerType] ct on ct.[ID] = p.[CustomerInfoID]
	left join [dbo].customer_information cus on cus.fk_application_information_id = p.fk_application_information_id
	--left join [dbo].[CompanyCode] cc on cc.[ID] = c.[CompanyCodeID]
	where (st.name not in (@status1,@status2) and
			[dbo].[_fgetshortdate](ap.received_date) between [dbo].[_fgetshortdate](@fdate) and [dbo].[_fgetshortdate](@tdate))
	order by ap.received_date desc

END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_appactionlog_get_report_tat_direct_sale]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[sp_report_pl_appactionlog_get_report_tat_direct_sale]
	@saleID varchar(7),
	@status1 int,
	@status2 int,
	@fdate datetime,
	@tdate datetime
AS
BEGIN

	select 
		ap.application_no as ApplicationNo,
		REPLACE(CONVERT(VARCHAR(11), ap.received_date, 106), ' ', '/') as ReceivedDate,
		st.name as Status,
		
		ap.arm_code as ARMCode,
		p.loan_amount_applied as AmountApplied,
		--p.[ECLoanAmountApproved] as AmountApproved,	
		'' as AmountApproved,	
		--p.[TeleStatus],
		(select top(1)m.name from m_status m
						where ap.fk_tele_status_id = m.pk_id) as TeleStatus,
								
		st. name as StatusName,

		cus.full_name as CustomerName,

		--c.[PassportID] as CustomerID,
		(select top(1)cid.identification_no from customer_identification cid
											where cid.fk_customer_information_id  = cus.pk_id) as CustomerID,

		--c.[MobileNo] as CustomerMobile,
		cus.mobile_no_1 as CustomerMobile,

		--cc.[Name] as CompanyCodeName,
		(select top(1) mc.name from m_company_list cl join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = cus.fk_company_information_id) as CompanyCodeName,	
				 			
		sc.name as ChannelName,

		--ct.[Name] as CityBranch,
		(select top(1) mc.name from m_customer_type mc
						where mc.pk_id = cus.fk_m_customer_type_id) as CityBranch,

		'' as RLSCompanyCode,

		--p.ProgramCode,
		(select top(1) m.name from m_program_code m
						where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,

		(case when (select count(*) from dbo.application_action_log l 
									where (l.fk_application_information_id = p.fk_application_information_id 
									and [action] = 'LOReworkToSC')) > 0 then 'YES' else 'NO' end) as ReworkSC,

		(case when (select count(*) from dbo.application_action_log l
									where (l.fk_application_information_id = p.fk_application_information_id  
									and [action] = 'LOReworkToCI')) > 0 then 'YES' else 'NO' end) as ReworkCI,


		cus.email_address_1,
		cus.email_address_2,
		'' as EmailAddress3,

		--c.NationalityCode,
		(select top(1) m.name from m_nationality m
						where m.pk_id = cus.fk_m_nationality_id_1) as NationalityCode,

		ap.eops_txn_ref_no_1 as EOpsTxnRefNo,

		REPLACE(CONVERT(VARCHAR(11), ap.hard_copy_app_date, 106), ' ', '/') as HardCopyAppDate,
		--REPLACE(CONVERT(VARCHAR(11), p.[ApplicationSignDate], 106), ' ', '/') as [ApplicationSignDate]
		'' as [ApplicationSignDate]

	from [dbo].[pl_application] p WITH (NOLOCK) join application_information ap on p.fk_application_information_id = ap.pk_id 
	left join [dbo].[m_status] st on st.pk_id = p.fk_status_id
	left join [dbo].m_sales_channel sc on sc.pk_id = ap.fk_m_sales_channel_id
	--left join [dbo].[CustomerType] ct WITH (NOLOCK) on ct.[ID] = p.[CustomerInfoID]
	left join [dbo].customer_information cus on cus.fk_application_information_id = p.fk_application_information_id
	--left join [dbo].[CompanyCode] cc WITH (NOLOCK) on cc.[ID] = c.[CompanyCodeID]
	where (ap.sale_staff_bank_id = @saleID and st.name not in (@status1,@status2) and
			[dbo].[_fgetshortdate](ap.received_date) between [dbo].[_fgetshortdate](@fdate) and [dbo].[_fgetshortdate](@tdate))
	order by ap.received_date  desc

END






GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_actionlog_get_list_by_appno]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_pl_application_actionlog_get_list_by_appno]
	@appNo varchar(20)
AS
BEGIN

	select 
		a.[pk_id],
		--a.[ApplicationNo],
		(select top(1) ap.application_no from application_information ap
						where ap.pk_id = a.fk_application_information_id) as [ApplicationNo],
		a.[action],
		a.[action_by],
		a.[action_date],
		--u.[FullName] UserName
		'' as UserName
	from [dbo].application_action_log a WITH (NOLOCK)
	--left join [dbo].[LoginUser] u WITH (NOLOCK) 
	--on u.[PeoplewiseID] = a.[ActionBy] 
	where a.fk_application_information_id = @appNo	
	order by a.[action_date]

END

GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_actionlog]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_actionlog]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.application_no, lg.Action_Date ASC) AS Seq,
  --lg.ApplicationNo,
  ap.application_no as  ApplicationNo,
--ap.ProductTypeName,
 m.name as  ProductTypeName,
lg.[Action],
lg.action_by as ActionBy,
'' as ActionName,
CONVERT(VARCHAR(24),lg.action_date,13) as ActionDate
FROM
	[dbo].application_action_log lg --join LoginUser lu on lu.PeoplewiseID = lg.ActionBy
	inner join application_information ap on ap.pk_id = lg.fk_application_information_id
	inner join pl_application cap on ap.pk_id = cap.fk_application_information_id
	inner join m_type m on ap.fk_m_type_id = m.pk_id
	
WHERE
Cast(ap.received_date as Date) >= Cast(@FromDate as Date) and
	Cast(ap.received_date as Date) <= Cast(@ToDate as Date)
ORDER BY ap.application_no, lg.action_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_admin_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_admin_audittrail]
	@Page varchar(30),
	@Table varchar(30),
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,pre_value as  prevalue
	,curr_value as  currvalue
	,CASE WHEN [log_type] LIKE (@Page + '::%::AddNew::%') THEN 'Add' 
		ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Update::%') THEN 'Update'
			ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Delete_Pending::%') THEN 'Delete'
				ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Approved::Delete::%') THEN 'Approved Delete'
					ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Approved::Active%') THEN 'Approved Active'
						ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Reject::%') THEN 'Reject'
							ELSE (CASE WHEN [log_type] LIKE (@Page + '::%::Upload::%') THEN 'Upload' END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(10), [updated_date], 101) + ' ' + CONVERT(VARCHAR(8), [updated_date], 108) as [updated_date]
	,[Updated_By] AS [Action_By]
FROM
	dbo.application_changed_log
WHERE ([log_type] LIKE (@Page + '::'+ @Table +'::%'))
	AND Cast([updated_date] as date) >= Cast(@FromDate as date)
	AND Cast([updated_date] as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_approved_applications]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_approved_applications]
	@FromDate datetime,
	@ToDate datetime
AS
--BEGIN
--	SELECT 
--	ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
--	ap.ApplicationNo as [Application No],
--	CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
--	ap.EOpsTxnRefNo,
--	ap.ProductTypeName AS [Product Type],
--	cc.BankRelationship AS [Customer Relation],
--	ap.ChannelD AS [Channel],
--	ap.LocationBranchName AS [Branch Location],
--	cc.FullName AS [Primary Card Holder Name],
--	(
--		select top 1 IdentificationNo from CCIdentification 
--		where CustomerType='Primary' and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') and CustomerID=ap.CustomerID
--	) as [Primary Card Holder ID],
--	REPLACE(CONVERT(VARCHAR(11), cc.[DOB], 102), '.', '/') as [Primary Card Holder DOB],
--	ap.SCRemark as [SC Remark],
--	ap.ARMCode,
--	ap.SalesPWID as [Sale PWID],
--	(
--		SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID 
--		WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
--	) AS [Created Name],
--	CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
--	cc.ResidentialAddress AS [Res Address],
--	cc.ResidentialWard AS [Res ward],
--	cc.ResidentialDistrict AS [Res District],
--	cc.ResidentialCity AS [Residential City],
--	ccPL.Remark,
--	---------------------------------------
--	SubCardFullName.[1] AS [Subcard Full name 1],
--	SubCardDOB.[1] AS [Subcard DOB 1],
--	SubCardNationality.[1] AS [Subcard Nationality 1],
--	---------------------------------------
--	SubCardFullName.[2] AS [Subcard Full name 2],
--	SubCardDOB.[2] AS [Subcard DOB 2],
--	SubCardNationality.[2] AS [Subcard Nationality 2],
--	---------------------------------------
--	SubCardFullName.[3] AS [Subcard Full name 3],
--	SubCardDOB.[3] AS [Subcard DOB 3],
--	SubCardNationality.[3] AS [Subcard Nationality 3],
--	---------------------------------------
--	SubCardFullName.[4] AS [Subcard Full name 4],
--	SubCardDOB.[4] AS [Subcard DOB 4],
--	SubCardNationality.[4] AS [Subcard Nationality 4]
--	---------------------------------------
--	FROM [dbo].[CCApplication] ap join CCCustomer cc on ap.CustomerID = cc.ID
--	left join CCPLApplication ccPL on ap.ApplicationNo=ccPL.CCApplicationNo
--	outer apply(
--		(select *
--			from (select ApplicationNo,ROWNUMBERS,FullName from 
--				(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCSubCard
--				  where ApplicationNo=ap.ApplicationNo)x ) SourceTable
--		PIVOT(MAX(FullName) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
--	) SubCardFullName
--	outer apply(
--		(select *
--			from (select ApplicationNo,ROWNUMBERS,REPLACE(CONVERT(VARCHAR(11), [DOB], 102), '.', '/') as DOB from 
--				(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCSubCard
--				  where ApplicationNo=ap.ApplicationNo)x ) SourceTable
--		PIVOT(MAX(DOB) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
--	) SubCardDOB
--	outer apply(
--		(select *
--			from (select ApplicationNo,ROWNUMBERS,Nationality from 
--				(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from CCSubCard
--				  where ApplicationNo=ap.ApplicationNo)x ) SourceTable
--		PIVOT(MAX(Nationality) FOR ROWNUMBERS IN ([1],[2],[3],[4])) as pivottable)
--	) SubCardNationality
--	WHERE ap.ProductTypeName in ('PN','CC')
--	and ap.Status in ('CIApproved', 'CIApprovedPL','LODisbursed')
--	and	dbo._fGetShortDate(DecisionDate) >= dbo._fGetShortDate(@FromDate)
--	and dbo._fGetShortDate(DecisionDate) <= dbo._fGetShortDate(@ToDate)
--	ORDER BY Seq
--END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_audittrail_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_pl_application_get_pl_audittrailci '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_audittrail_ci]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
--ap.ProductTypeName,
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as ProductTypeName,
--ap.ApplicationNo,
ap.Application_No as ApplicationNo,
--CONVERT(VARCHAR(24),lg.ActionDate,106) as ModifiedDate,
 CONVERT(VARCHAR(24),lg.action_date,106) as ModifiedDate,
--ActionBy as ModifiedBy,
u.action_by as ModifiedBy,
--u.FullName as ModifiedByName,
u.full_name as ModifiedByName,
--lg.Action as ModifiedStatus,
 lg.Action as ModifiedStatus,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,
--ap.CreditBureauType,
 (select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CreditBureauType,

--ap.GroupCreditCardHistoryClassification as GroupCardHistory,

(select top 1 m.name from m_bureau_card_list m
		  where pap.fk_group_card_history_classification_id = m.pk_id and m.is_active = 1
															 and m.fk_type_id = 11 and m.fk_group_id = 15) as GroupCardHistory,
--ap.GroupLoanHistoryClassification as GroupLoanHistory,

(select top 1 m.name from m_bureau_card_list m
		  where pap.fk_group_loan_history_classification = m.pk_id and m.is_active = 1
															 and m.fk_type_id = 10 and m.fk_group_id = 15) as GroupLoanHistory,
--ccPL.LoanTenor as Tenor,
pap.loan_tenor_applied as Tenor,
--ccPL.InterestRateClassification,
(select top(1)m.name from m_interest_classification m
					 where  pap.fk_interest_classification_id = m.pk_id and m.is_active =1) as InterestRateClassification,
--ap.InterestRateSuggested,
(select top(1)CONVERT(varchar, CAST(apr.interest_rate_suggested AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as InterestRateSuggested,
--(case when ap.IsTwoCardType = 1 then 'YES' else 'NO'end) as IsTwoCardType,
'' as IsTwoCardType,
--ap.CardTypeName as CardType1,
'' as CardType1,
--ap.CardTypeName2 as CardType2,
'' as CardType2,
--cc.VerifiedPosition,
(SELECT TOP 1 vf.verified_position FROM verification_form vf 
  WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedPosition,
--cc.OccupationVerified as VerifiedOccupation,
(select top(1) m.name from pl_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],
--CONVERT(VARCHAR(24),cc.DateIssuedResidentialAdd,106) as IssuedDateOfResidentialAddress,

CONVERT(VARCHAR(24),cus.issued_date_residential_address,106) as IssuedDateOfResidentialAddress,
--cc.TypeOfContract as TypeOfContract,
(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
--ccPL.LoanPurpose,
'' as LoanPurpose,
(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as Spending_LimitSub1,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as Spending_LimitSub2,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as Spending_LimitSub3,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as Spending_LimitSub4,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as Spending_LimitSub5,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as Spending_LimitSub6,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as Spending_LimitSub7,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as Spending_LimitSub8,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as Spending_LimitSub9,

(select Spending_Limit from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as Spending_LimitSub10


FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join Application_Action_Log lg on lg.fk_application_information_id = ap.pk_id
    left join dbo.User_Login u on u.peoplewise_id = lg.[action_by]
WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY lg.Action_Date
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_audittrail_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_audittrail_report]
	@FromDate datetime,
	@ToDate datetime
AS

BEGIN
	SELECT 
		ap.application_no as ApplicationNo,
		lg.pre_value as PreValue,
		lg.curr_value as CurrValue,
		lg.update_by as UpdateBy,
		lg.update_date as UpdateDate,
		lg.log_type as LodType

	FROM application_changed_log lg
		 left join application_information ap on lg.fk_application_information_id = ap.pk_id
		 left join m_type m on lg.fk_type_id = m.pk_id and m.name in('PL','PersonalLoan')
	WHERE (log_type like 'AuditTrailReport:CCSubCard:%'
		OR log_type like 'AuditTrailReport:CCCustomer:%'
		OR log_type like 'AuditTrailReport:CCPLApplication:%'
		OR log_type like 'AuditTrailReport:CCCustomerIncome:%'
		OR log_type like 'AuditTrailReport:CCCustomerBonu:%'
		OR log_type like 'AuditTrailReport:CCLoanBureau:%'
		OR log_type like 'AuditTrailReport:CCCreditBureau:%'
		OR log_type like 'AuditTrailReport:CCApplication:%')
	AND	Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
	ORDER BY ap.application_no, 
			CONVERT(smalldatetime, updated_date), 
			SUBSTRING(log_type, 0, LEN(log_type) - CHARINDEX(':',reverse(log_type), 0) + 1) desc
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_blacklist_company_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_blacklist_company_audittrail]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,[pre_value]
	,[curr_value]
	,CASE WHEN log_type LIKE 'BL_Manager::%::AddNew::%' THEN 'Add' 
		ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Update::%' THEN 'Update'
			ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Delete_Pending::%' THEN 'Delete'
				ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Approved::Delete::%' THEN 'Approved Delete'
					ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Approved::Active%' THEN 'Approved Active'
						ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Reject::%' THEN 'Reject'
							ELSE (CASE WHEN log_type LIKE 'BL_Manager::%::Upload::%' THEN 'Upload' END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(24),[updated_date],106) AS [updated_date]
	,[updated_by] AS [ActionBy]
FROM
	dbo.application_changed_log ML
	LEFT JOIN dbo.frm_black_list_company com 
	ON ((SELECT SUBSTRING(log_type, LEN(log_type) - 35, 36))) = CAST (com.pk_id AS VARCHAR(37))
WHERE log_type LIKE 'BL_Manager::BlackListCompany::%'
	AND Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_blacklist_customer_audittrail]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_blacklist_customer_audittrail]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  [updated_date] ASC) AS Seq
	,[pre_value]
	,[curr_value]
	,CASE WHEN [log_type] LIKE 'BL_Manager::%::AddNew::%' THEN 'Add' 
		ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Update::%' THEN 'Update'
			ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Delete_Pending::%' THEN 'Delete'
				ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Approved::Delete::%' THEN 'Approved Delete'
					ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Approved::Active%' THEN 'Approved Active'
						ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Reject::%' THEN 'Reject'
							ELSE (CASE WHEN [log_type] LIKE 'BL_Manager::%::Upload::%' THEN 'Upload'
								ELSE (CASE WHEN [log_type] LIKE 'FRM_WorkInProgress::%::AddNew::%' THEN 'FRM Add' END)
							END)
						END) 
					END) 
				END) 
			END) 
		END) 
	 END AS [Action]
	,CONVERT(VARCHAR(24),[updated_date],106) AS [UpdatedDate]
	,[updated_by] AS [ActionBy]
FROM
	dbo.application_changed_log ML
WHERE (log_type LIKE 'BL_Manager::BlackListCustomer::%'
		OR log_type LIKE 'FRM_WorkInProgress::BlackListCustomer::%')
	AND Cast(updated_date as date) >= Cast(@FromDate as date)
	AND Cast(updated_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_bureau_information_cc]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_bureau_information_cc]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
  CONVERT(VARCHAR(10), ap.Received_Date, 101) + ' ' + CONVERT(VARCHAR(8), ap.Received_Date, 108) as [Received Date],

--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
(Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,
--ap.Application_No,
 ap.Application_No as ApplicationNo,
--(SELECT TOP 1 ActionBy FROM AppActionLog alog WHERE alog.ap.Application_No = ap.ap.Application_No ORDER BY ActionDate DESC) AS CreatedBy,
(SELECT TOP 1 action_by FROM application_action_log alog WHERE alog.fk_application_information_id = ap.pk_id ORDER BY action_date	 DESC) AS CreatedBy,
--ap.SpecialCode,
pap.special_code as SpecialCode,
--ap.ProductTypeName AS [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id and m.is_active =1) AS [Product Type],
--ap.TypeApplicationName AS [Application Type],
pap.type_of_application as [Application Type],
--ap.CardProgramName AS [Card Program],
'' as [Card Program],
--ap.ProgramCodeName AS [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName AS [Card Type],
'' as [Card Type],
--ap.CardTypeName2 AS [Card Type 2],
'' as [Card Type 2],
--cc.CustomerSegment,
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as CustomerSegment,
--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
--ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as [Channel],
--ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as  [Branch Location],
--ap.ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentType,
--cc.FullName AS [Primary Card Holder Name],
cus.full_name as [Primary Card Holder Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Type Of Identification],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary Card Holder ID],
--cc.CompanyName,
co.company_name as CompanyName,
--cc.CompanyCode,
co.company_code as CompanyCode,
--cc.RLSCompanyCode,
co.company_code_rls asRLSCompanyCode,
--ap.CreditBureauType AS [Bureau Type],
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--cc.IncomeType,
(select top(1)m.name from pl_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as incomeType,
--cc.MonthlyIncomeDeclared AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[cc_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.HolderInitial AS [Initial Limit],
CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1)  AS [Initial Limit],

--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PLFinalLoanAmountApproved ELSE ap.FinalLimitApproved END) AS [Final Approved Limit],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PL_FinalApprovalStatus ELSE ap.FinalApprovalStatus END) AS [Final Approval Status],
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],
--ap.DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,
--ap.Status AS [Current Status],
(select top(1) m.name from m_status m
					  where ap.fk_m_status_id = m.pk_id) as [Current Status],
-----------------------------------------
CCSecuredType.[1] AS [Other Credit Card Secured Type_1],
CCLimit.[1] AS [Other Credit Card Limit_1],
CCOutstanding.[1] AS [Other Credit Card Outstanding_1],
CCInterestRate.[1] AS [Interest Rate_1],
CCEMI.[1] AS [EMI_1],
CCSource.[1] AS [Source_1],
CCBank.[1] AS [Issued Bank_1],
---------------------------------------
CCSecuredType.[2] AS [Other Credit Card Secured Type_2],
CCLimit.[2] AS [Other Credit Card Limit_2],
CCOutstanding.[2] AS [Other Credit Card Outstanding_2],
CCInterestRate.[2] AS [Interest Rate_2],
CCEMI.[2] AS [EMI_2],
CCSource.[2] AS [Source_2],
CCBank.[2] AS [Issued Bank_2],
---------------------------------------
CCSecuredType.[3] AS [Other Credit Card Secured Type_3],
CCLimit.[3] AS [Other Credit Card Limit_3],
CCOutstanding.[3] AS [Other Credit Card Outstanding_3],
CCInterestRate.[3] AS [Interest Rate_3],
CCEMI.[3] AS [EMI_3],
CCSource.[3] AS [Source_3],
CCBank.[3] AS [Issued Bank_3]
-----------------------------------------

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_pl_customer_information_id = cus.pk_id
	outer apply(
		(select *
			from (select ap.Application_No, ROWNUMBERS, Secured_Type from 
				  (select ROW_NUMBER() OVER (ORDER BY br.created_date ASC) AS ROWNUMBERS,* 
				     from pl_card_bureau br  
				  where br.fk_application_information_id = ap.pk_id)x ) SourceTable
		PIVOT(MAX(Secured_Type) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSecuredType
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS, total_limit from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX(total_limit) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCLimit
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Outstanding] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Outstanding]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCOutstanding
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[interest_rate] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Interest_Rate]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInterestRate
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[EMI] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([EMI]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCEMI
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Source] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Source]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSource
	outer apply(
		(select *
			from (select ap.Application_No,ROWNUMBERS,[Bank] from 
				(select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_card_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Bank]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCBank

WHERE Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_bureau_information_loan]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_bureau_information_loan]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
 (Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--(SELECT TOP 1 ActionBy FROM AppActionLog alog WHERE alog.ApplicationNo = ap.ApplicationNo ORDER BY ActionDate DESC) AS CreatedBy,
(SELECT TOP 1 action_by FROM Application_Action_Log alog 
					   WHERE alog.fk_application_information_id = ap.pk_id
 ORDER BY Action_Date DESC) AS CreatedBy,
--ap.SpecialCode,
  pap.special_code as SpecialCode,
--ap.ProductTypeName AS [Product Type],
   (select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id and m.is_active =1) as [Product Type],
--ap.TypeApplicationName AS [Application Type],
pap.type_of_application as [Application Type],
--ap.CardProgramName AS [Card Program],
'' as [Card Program],
--ap.ProgramCodeName AS [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName AS [Card Type],
''  as [Card Type],
--ap.CardTypeName2 AS [Card Type 2],
'' as [Card Type 2],

--cc.CustomerSegment,
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as CustomerSegment,
--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as [Is Staff],
--ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as [Channel],
--ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
--ap.ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentType,
--cc.FullName AS [Primary Card Holder Name],
cus.full_name as [Primary Card Holder Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Type Of Identification],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of Identification],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and (TypeOfIdentification = 'ID' OR TypeOfIdentification = 'Passport') and CustomerID=ap.CustomerID) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as  [Primary Card Holder ID],
--cc.CompanyName,
co.company_name as CompanyName,
--cc.CompanyCode,
co.company_code as CompanyCode,
--cc.RLSCompanyCode,
co.company_code_rls asRLSCompanyCode,
--ap.CreditBureauType AS [Bureau Type],
 (select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--cc.IncomeType,
(select top(1)m.name from pl_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as ncomeType,
--cc.MonthlyIncomeDeclared AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.HolderInitial AS [Initial Limit],
 CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1)  AS [Initial Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PLFinalLoanAmountApproved ELSE ap.FinalLimitApproved END) AS [Final Approved Limit],
(select top(1)CONVERT(varchar, CAST(apr.Final_Loan_Amount_Approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],
--(CASE WHEN ap.ProductTypeName = 'PN' THEN ccPL.PL_FinalApprovalStatus ELSE ap.FinalApprovalStatus END) AS [Final Approval Status],
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

--ap.DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,
--ap.Status AS [Current Status],
(select top(1) m.name from m_status m
					  where ap.fk_m_status_id = m.pk_id) as [Current Status],
-----------------------------------------
CCSecuredType.[1] AS [Other Loan Secured Type_1],
CCInitialLoan.[1] AS [Other Initial Loan_1],
CCTenor.[1] AS [Other Tenor_1],
CCInterestRate.[1] AS [Interest Rate_1],
CCOutstanding.[1] AS [Outstanding_1],
CCEMI.[1] AS [EMI_1],
CCSource.[1] AS [Source_1],
---------------------------------------
CCSecuredType.[2] AS [Other Loan Secured Type_2],
CCInitialLoan.[2] AS [Other Initial Loan_2],
CCTenor.[2] AS [Other Tenor_2],
CCInterestRate.[2] AS [Interest Rate_2],
CCOutstanding.[2] AS [Outstanding_2],
CCEMI.[2] AS [EMI_2],
CCSource.[2] AS [Source_2],
---------------------------------------
CCSecuredType.[3] AS [Other Loan Secured Type_3],
CCInitialLoan.[3] AS [Other Initial Loan_3],
CCTenor.[3] AS [Other Tenor_3],
CCInterestRate.[3] AS [Interest Rate_3],
CCOutstanding.[3] AS [Outstanding_3],
CCEMI.[3] AS [EMI_3],
CCSource.[3] AS [Source_3]
-----------------------------------------

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_application_information_id = ap.pk_id
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[secured_type] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id) x) SourceTable
		PIVOT(MAX([Secured_Type]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSecuredType
	outer apply(
		(select *
			from (select ApplicationNo,ROWNUMBERS,[initial_loan] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Initial_Loan]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInitialLoan
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Tenor] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Tenor]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCTenor
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Outstanding] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Outstanding]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCOutstanding
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[interest_rate] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Interest_Rate]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCInterestRate
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[EMI] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([EMI]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCEMI
	outer apply(
		(select *
			from (select ap.application_no as ApplicationNo,ROWNUMBERS,[Source] from 
				(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from pl_loan_bureau
				  where fk_application_information_id =ap.pk_id)x ) SourceTable
		PIVOT(MAX([Source]) FOR ROWNUMBERS IN ([1],[2],[3])) as pivottable)
	) CCSource

WHERE 
Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_calling_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_calling_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
 ap.application_no as ApplicationNo,
--CONVERT(VARCHAR(24),ckl.ExpectedDisbursedDate,106) as [Expected Disbursed Date],
''as [Expected Disbursed Date],
--CONVERT(varchar, CAST(ckl.ExpectedDisbursedAmount AS MONEY), 1) AS [Expected Disbursed Amount],
 ''AS [Expected Disbursed Amount],

--ckl.SalaryDay,
'' as SalaryDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
''as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
''as [Last EMI Date],

--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
'' AS [Odd Day Interest],
--dis.LoanAccountNo,
dis.loan_account_number as LoanAccountNo,
--ckl.CallTimeList,
'' as CallTimeList,
--ckl.CycleDueDay,
'' as CycleDueDay,
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],
(select top(1) (CASE WHEN cus.billing_address = 'Company address' 
	               THEN (co.company_name + ' - ' + co.Company_Address + ' - ' + co.company_ward + ' - ' + co.company_district + ' - ' + 
					(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) 
			ELSE
	          (CASE WHEN cus.billing_address = 'Permanent address' 
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))
	  AS [Mailing Address],

--CONVERT(VARCHAR(24),ckl.CreatedDate,106) as [Created Date],  
''as [Created Date],
--ckl.CreatedBy,
'' as CreatedBy,
--ckl.Status,
'' as Status,
--ckl.MSO
'' as MSO,
--ckl.PendingReason,
'' as PendingReason,
--ckl.PendingMark,
'' as PendingMark,
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as [Disbursed Date],
CONVERT(VARCHAR(24),dis.disbursed_date,106) as [Disbursed Date],
--cc.FullName as Customer_Name,
cus.full_name as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as  CustomerID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousPP,
--cc.PrimaryPhoneNo as MobilePhone,
 cus.primary_phone_no as MobilePhone,
--Convert(varchar,Convert(money,cpl.PLSuggestedInterestRate),1) AS [ECFinalLoanInterest],
CONVERT(varchar, CAST(pap.suggested_interest_rate AS MONEY), 1) AS [ECFinalLoanInterest],
--cpl.LoanTenor as [ECLoanTenor],
pap.loan_tenor_applied as [ECLoanTenor],
--Convert(varchar,Convert(money,ckl.ExpectedDisbursedAmount),1) AS [ECLoanAmountApproved],
'' as [ECLoanAmountApproved],
--ap.ChannelD,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as ChannelD,
--ap.LocationBranchName
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as LocationBranchName
FROM
	[dbo].[pl_Application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	LEFT JOIN pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id
	--LEFT JOIN CustomerCallCheckList ckl on ckl.ApplicationNo = ap.ApplicationNo
	
WHERE 
       Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_custody_mis_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_custody_mis_report]
	@FromDate datetime,
	@ToDate datetime,
	@ProductTypeName varchar(100)
AS

SELECT ROW_NUMBER() OVER (ORDER BY custody.update_date ASC) AS Seq,
--	ap.EOpsTxnRefNo,
    ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	ap.EOpsTxnRefNo2,
	ap.eops_txn_ref_no_2 as EOpsTxnRefNo2,
--	ap.ProductTypeName AS [Product Type],
	m.name as [Product Type],
--	cust.FullName AS [Customer Name],
    cus.full_name as [Customer Name],
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,

-- ap.LocationBranchName AS [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) AS [Branch Location],

--	STUFF((SELECT '. ' + IdentificationNo AS [text()]
--				FROM CCIdentification ccID
--				WHERE ccID.CustomerID = cust.ID
--				FOR XML PATH('')), 1, 1, '' )
--	AS [IdentificationNo],

	STUFF((SELECT '. ' + ccID.identification_no AS [text()]
				FROM customer_identification ccID
				WHERE ccID.fk_customer_information_id = cus.fk_customer_information_id
				FOR XML PATH('')), 1, 1, '' )
	AS [IdentificationNo],

--	ap.TypeApplicationName AS [Type of Application],
	pap.type_of_application  as [Type of Application],
--	ap.ChannelD AS [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS [Channel],

--	ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--	ap.Status AS [Application Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) AS [Application Status],
--	doc.DocumentName,
doc.document_name as  DocumentName,

--	(CASE WHEN IsSubmited = 1 THEN 'Yes' ELSE 'No' END) AS [IsSubmited],
(CASE WHEN is_submited = 1 THEN 'Yes' ELSE 'No' END) AS [IsSubmited],
--	(CASE WHEN IsSubmited = 1 THEN CONVERT(VARCHAR(14), doc.SubmitedDate, 107) ELSE null END) AS [Submitted Date],
(CASE WHEN is_submited = 1 THEN CONVERT(VARCHAR(14), doc.submited_date, 107) ELSE null END) AS [Submitted Date],
--	(CASE WHEN IsSubmited = 1 THEN doc.SubmitedBy ELSE null END) AS [SubmitedBy],
(CASE WHEN is_submited = 1 THEN doc.submited_by ELSE null END) AS [SubmitedBy],
--	(CASE WHEN IsReceived = 1 THEN 'Yes' ELSE 'No' END) AS [IsReceived],
(CASE WHEN Is_Received = 1 THEN 'Yes' ELSE 'No' END) AS [IsReceived],
--	(CASE WHEN IsReceived = 1 THEN CONVERT(VARCHAR(14), doc.ReceivedDate, 107) ELSE null END) AS [Received Date],
(CASE WHEN is_received = 1 THEN CONVERT(VARCHAR(14), doc.received_date, 107) ELSE null END) AS [Received Date],
--	(CASE WHEN IsReceived = 1 THEN doc.ReceivedBy ELSE NULL END) AS ReceivedBy,
(CASE WHEN is_received = 1 THEN doc.received_by ELSE NULL END) AS ReceivedBy,
--	(CASE WHEN IsRequired = 1 THEN 'Yes' ELSE 'No' END) AS [IsRequired],
(CASE WHEN is_required = 1 THEN 'Yes' ELSE 'No' END) AS [IsRequired],
--	STUFF((SELECT '. ' + Remark AS [text()]
--				FROM CustodyRemark remark
--				WHERE remark.CustodyID = Custody.ID
--				FOR XML PATH('')), 1, 1, '' )
--	AS [Remark]

	STUFF((SELECT '. ' + Remark AS [text()]
				FROM application_custody_remark remark
				WHERE remark.fk_application_custody_id = Custody.pk_id
				FOR XML PATH('')), 1, 1, '' ) AS [Remark]
FROM  application_custody custody
	  inner join pl_application pap on custody.fk_application_information_id = pap.fk_application_information_id
	  inner join application_information ap on pap.fk_application_information_id = ap.pk_id
	  inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	  inner join application_custody_document doc on doc. fk_application_custody_id = custody.pk_id
	  inner join m_type m on m.pk_id = custody.fk_type_id
	--LEFT JOIN CCApplication ap ON ap.ApplicationNo = Custody.ApplicationNo
	--LEFT JOIN CCCustomer cust ON cust.ID = ap.CustomerID
	--LEFT JOIN CustodyDocument doc ON doc.CustodyID = Custody.ID
WHERE
	Cast(custody.update_date as date) >= Cast(@FromDate as date)
AND Cast(custody.update_date as date) <= Cast(@ToDate as date)
AND m.name = @ProductTypeName
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_customers]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_customers]
	@FromDate datetime,
	@ToDate datetime
AS

  SELECT 
--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,

--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--cc.Full_Name as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--ap.CardTypeName as CardType1,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as CardType1,
--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,
--ap.ProgramCodeName as ProgramCodeName,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCodeName,
--cc.Full_Name as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),cus.DOB,106) as PrimaryCardHolderDOB,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select top 1  IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--cc.Gender as Gender,
(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.is_active = 1 and m.fk_group_id = 38) as Gender,

--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no AS MobilePhone,

--(cc.PermAddress + ' ' + cc.PermWard + ' ' + cc.PermDistrict + ' ' + cc.PermCity) as PrimaryCardHolderPermanentAddress,
(cus.permanent_address + ' ' + cus.permanent_ward + ' ' + cus.permanent_district + ' ' + 
(select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1)) as PrimaryCardHolderPermanentAddress,

--(cc.ResidentialAddress + ' ' + cc.ResidentialWard + ' ' + cc.ResidentialDistrict + ' ' + cc.ResidentialCity) as PrimaryCardHolderHomeAddress,
(cus.residential_address + ' ' + cus.residential_ward + ' ' + cus.residential_district + ' ' + 
(select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) as PrimaryCardHolderHomeAddress,

--cc.HomePhoneNo as HomePhoneNo,
cus.home_phone_no as  HomePhoneNo,
--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--(cc.CompanyAddress + ' ' + cc.CompanyWard + ' ' + cc.CompanyDistrict + ' ' + cc.CompanyCity) as CompanyAddress,
(co.Company_Address + ' ' + co.Company_Ward + ' ' + co.Company_District + ' ' + 
(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) as CompanyAddress,
--cc.CompanyPhone as CompanyPhone,
co.office_telephone as CompanyPhone,
--ccPL.LoanPurpose,
(select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as  LoanPurpose,
-----------1
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as SubCardFull_Name1,

CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1),106) as SubCardDOB1,	
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select fk_customer_information_id from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=1)) as SubCardHolderID1,

(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=1)) as SubCardHolderID1,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as RelationshipWithPrimary1,

---------2
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as SubCardFull_Name2,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2),106) as SubCardDOB2,	
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=2)) as SubCardHolderID2,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=2)) as SubCardHolderID2,


--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=2) as RelationshipWithPrimary2,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as RelationshipWithPrimary2,

---------3
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as SubCardFull_Name3,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3),106) as SubCardDOB3,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=3)) as SubCardHolderID3,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=3)) as SubCardHolderID3,
--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=3) as RelationshipWithPrimary3,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as RelationshipWithPrimary3,
---------4
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as SubCardFull_Name4,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4),106) as SubCardDOB4,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=4)) as SubCardHolderID4,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
											(select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=4)) as SubCardHolderID4,

--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as RelationshipWithPrimary4,
---------5
(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as SubCardFull_Name5,
	
CONVERT(VARCHAR(24),(select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5),106) as SubCardDOB5,
	
--(select IdentificationNo from CCIdentification 
--where TypeOfIdentification='ID' and CustomerID=(select ID from 
--													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--													from cc_subcard_application scard
--													where fk_application_information_id = ap.pk_id)x 
--												where x.ROWNUMBERS=5)) as SubCardHolderID5,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = (select fk_customer_information_id from 
											(select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=5)) as SubCardHolderID5,


--(select RelationshipWithPrimary from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=5) as RelationshipWithPrimary5,
(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY scard. Created_Date ASC) AS ROWNUMBERS, m.name as RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type m on 
															scard.fk_relationship_with_primary_id = m.pk_id 
															and m.fk_group_id = 60 and m.is_active =1
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as RelationshipWithPrimary5,

null as RelativeName,
null as RelativeFixedPhone,
null as RelativeMobileNo
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
	    Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_disbursedreports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_disbursedreports]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
 ap.application_no as ApplicationNo,
 CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
 cus.full_name as Customer_Name,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1) CONVERT(varchar, CAST(inf.final_loan_amount_approved AS MONEY), 1) from pl_approval_information inf
				where inf.fk_application_information_id = ap.pk_id) AS [Loan_Amt_Approved],
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as [Disbursed Date],
 CONVERT(VARCHAR(24),dis.disbursed_date,106) as [Disbursed Date],
--CONVERT(varchar, CAST(cpl.SCB_PL_EMI AS MONEY), 1) AS [EMI],
 (select top(1)CONVERT(varchar, CAST(pl.scb_emi AS MONEY), 1) from pl_approval_information pl
			     where pl.fk_application_information_id = ap.pk_id) AS [EMI],
--Convert(varchar,Convert(money,cpl.PLSuggestedInterestRate),1) AS Interest,
 CONVERT(varchar, CAST(pap.suggested_interest_rate AS MONEY), 1) AS Interest,
--cpl.LoanTenor AS [Tenor (month)],
 pap.loan_tenor_applied as [Tenor (month)],
--dis.LoanAccountNo,
dis.loan_account_number as LoanAccountNo,
--ckl.RepayAccount,
'' as RepayAccount,
--ckl.CycleDueDay,
'' as CycleDueDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
'' as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
'' as [Last EMI Date],
--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
''  AS [Odd Day Interest],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousPP,

--cc.PrimaryPhoneNo as MobilePhone,
 cus.primary_phone_no AS [Mobile Phone],

--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],

(select top(1) (CASE WHEN cus.billing_address = 'Company address' 
	               THEN (co.company_name + ' - ' + co.Company_Address + ' - ' + co.company_ward + ' - ' + co.company_district + ' - ' + 
					(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) 
			ELSE
	          (CASE WHEN cus.billing_address = 'Permanent address' 
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))
	  AS [Mailing Address],

cus.email_address_1,
cus.email_address_2

FROM
	[dbo].[pl_Application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	inner join m_status m on pap.fk_status_id = m.pk_id and m.is_active = 1
	inner join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	left join pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id
	--left join CustomerCallCheckList ckl on ckl.ApplicationNo = ap.ApplicationNo
	
WHERE 
 m.name = 'LODisbursed'
and	cast(dis.Disbursed_Date as date) >= cast(@FromDate as date)
and cast(dis.Disbursed_Date as date) <= cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_disbursement_pending]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_disbursement_pending]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as [Receiving Date],
CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
--cc.FullName as Customer_Name,
cus.full_name as Customer_Name,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as  CustomerPreviousPP,
--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
CONVERT(VARCHAR(24),cus.dob,106) as DOB,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as MobilePhone,
----PendingReason
'' as PendingReason,
--cpl.LoanTenor AS [Tenor (month)],
 pap.loan_tenor_applied as [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
'' as Interest,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1)CONVERT(varchar, CAST(app.final_loan_amount_approved AS MONEY), 1) from pl_approval_information app
											 where app.fk_application_information_id = ap.pk_id) as [Loan_Amt_Approved],
----AmountApproved_WithMRTA

'' as AmountApproved_WithMRTA,
----ApprovedDate
--cc.PaymentType as PaymentMethod,
(select top(1) m.name from m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active =1 ) as PaymentMethod,

--CONVERT(VARCHAR(24),ckl.ExpectedDisbursedDate,106) as [Expected Disbursed Date],
'' as [Expected Disbursed Date],
--CONVERT(varchar, CAST(ckl.ExpectedDisbursedAmount AS MONEY), 1) AS [Expected Disbursed Amount],
'' as [Expected Disbursed Amount],
--ckl.CycleDueDay,
'' as CycleDueDay,
--CONVERT(VARCHAR(24),ckl.FirstEMIDate,106) as [First EMI Date],
'' as [First EMI Date],
--CONVERT(VARCHAR(24),ckl.LastEMIDate,106) as [Last EMI Date],
'' as [Last EMI Date],
--ckl.RepayAccount,
'' as RepayAccount,
----Customer_Address 
--Convert(varchar,Convert(money,ckl.OddDayInterest),1) AS [Odd Day Interest],
 Convert(varchar,Convert(money,'0'),1) as [Odd Day Interest],
--(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--	(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--	  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Mailing Address],
(select top(1) (CASE WHEN cus.billing_address = 'Company address' 
	               THEN (co.company_name + ' - ' + co.Company_Address + ' - ' + co.company_ward + ' - ' + co.company_district + ' - ' + 
					(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m.is_active =1)) 
			ELSE
	          (CASE WHEN cus.billing_address = 'Permanent address' 
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m.is_active =1)) ELSE '' END) END) END))
	  AS [Mailing Address],

--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--ap.LocationBranchName,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as LocationBranchName,
----SaleChannel	  
--ap.Status as CurrentStatus
(select top(1)m.name from m_status m
						where ap.fk_m_status_id = m.pk_id and m.is_active = 1) as CurrentStatus
FROM
[dbo].[pl_Application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join cc_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	inner join m_status m on pap.fk_status_id = m.pk_id and m.is_active = 1
	inner join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	left join pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id

	
WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_email_verification_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_email_verification_report]
	@FromDate datetime,
	@ToDate datetime
AS
 SELECT
 CONVERT(VARCHAR(24),ap.received_date,13) as ReceivedDate,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
 --ev.CustomerName as FullName,
 cus.full_name as FullName,
  --ccId.IdentificationNo as IDPP,
  ccId.identification_no as IDPP,
-- CONVERT(VARCHAR(24),cc.DOB,105)as DOB,
CONVERT(VARCHAR(24),cus.DOB,105)as DOB,
-- ap.ProductTypeName, 
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id)  as ProductTypeName,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
-- ev.CompanyEmail,
 ev.company_email as CompanyEmail,
-- evStatus.EVStatus as EmailVerificationStatus,
  evStatus.ev_status_name as EmailVerificationStatus,
-- CONVERT(VARCHAR(24),ev.FirstSendDateEV,13)as FirstDateSentEmail, 
CONVERT(VARCHAR(24),ev.first_send_date,13)as FirstDateSentEmail, 
--ev.FirstEVResult as FirstVerificationResult,
 ev.first_result as FirstVerificationResult,
--firstrpl.ReplyContent as FirstRepliedEmailContent,
firstrpl.[description] FirstRepliedEmailContent,
--ev.CreatedBy,
ev.created_by as CreatedBy,
-- CONVERT(VARCHAR(24),ev.SecondSendDateEV,13) as SecondDateSentEmail,
CONVERT(VARCHAR(24),ev.second_send_date,13) as SecondDateSentEmail,
--CONVERT(VARCHAR(24),ev.ManualSendDateEV,13) as DateSentManual,
CONVERT(VARCHAR(24),ev.manual_send_date,13) as DateSentManual,
-- ev.ManualEVResult as ManualVerificationResult,
 ev.manual_result_name as ManualVerificationResult,
--  manualrpl.ReplyContent as ManualRepliedContent, 
 manualrpl.[description] as ManualRepliedContent, 
--ev.SendManualBy as ManualSentUser
ev.manual_send_by as ManualSentUser
FROM 
    [dbo].[pl_Application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	left join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	left join customer_information ci on ci.pk_id = cus.fk_customer_information_id 
	outer apply
	(	
		select top 1 id.fk_customer_information_id, id.identification_no 
		  from customer_identification id inner join m_identification_type m
										on id.fk_m_identification_type_id = m.pk_id and m.is_active =1
		 where id.fk_customer_information_id = ci.pk_id
			and  m.name in('ID','Passport','Previous_ID','Previous_PP')
		order by m.name
	) ccId
	 join [dbo].[ev_email_verification] ev on ev.fk_application_information_id = ap.pk_id
	 outer apply
	 (
		select top 1 mp.ev_status_name From ev_mapping_status mp
		where (ev.first_result = mp.first_ev_result_name or ev.first_result = '') and 
		      (ev.manual_result_name = mp.manual_ev_result_name or ev.manual_result_name = '')
	 ) evStatus
	 outer apply
	 (
	  select top 1 m.[description] From m_definition_type m
	  where ev.first_result =m.name	and m.fk_group_id =90 and m.is_active=1
	 )firstrpl
	 outer apply 
	 (
	  select top 1 m.[description] From m_definition_type m
	  where ev.manual_result_name = m.name and m.fk_group_id =90 and m.is_active=1
	 )manualrpl
WHERE
	Cast(ev.first_send_date as date) >= Cast(@FromDate as date)
and Cast(ev.first_send_date as date) <= Cast(@ToDate as date)
ORDER BY ap.Application_No,ap.received_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_blacklist_company]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_blacklist_company]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
ROW_NUMBER() OVER (ORDER BY Created_Date ASC) AS Seq,
Company_Name as CompanyName,
License_No as LicenseNo,
company_code as CompanyCode,
tax_code as TaxCode,
owner_name as OwnerName,
owner_id as OwnerID,
date_black_list as DateBlackList,
black_list_code as BlackListCode,
(select top(1)m.name from m_status m
				where fk_status_id = m.pk_id and m.is_active=1) as [Status],
Created_Date as CreatedDate,
created_by as CreatedBy,
Checker_Date as CheckerDate,
checker_by as CheckerBy

FROM
	FRM_Black_List_Company
	
WHERE
	Cast(Created_Date as date) >= Cast(@FromDate as date)
and Cast(Created_Date as date) <= Cast(@ToDate as date)
ORDER BY Created_Date
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_blacklist_customer]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_blacklist_customer]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY f.Created_Date ASC) AS Seq,
--CustomerName,
 f.customer_name as CustomerName, 
--IDType,
 (select top(1) m.name from m_identification_type m
				 where f.fk_m_identification_type_id = m.pk_id and m.is_active =1) as IDType,
--PreviousNo,
 previous_no as PreviousNo,
--PersonalNo,
personal_no  as PersonalNo,
--SocialNo,
social_no as SocialNo,
--DOB,
f.dob as DOB,
--DateBlackList,
date_black_list as DateBlackList,
--BlackListCode,
black_list_code as BlackListCode,
--[Status],
(select top(1)m.name from m_status m
						where f.fk_status_id = m.pk_id)  as [Status],
--CreatedDate,
f.created_date as CreatedDate,
--CreatedBy,
f.created_by  as CreatedBy,
--CheckerDate,
f.checker_date as CheckerDate,
--CheckerBy
checker_by as CheckerBy
FROM
	frm_black_list_customer f
	left join customer_information ci on f.fk_customer_information_id = ci.pk_id
	left join m_status m on f.fk_status_id = m.pk_id
	inner join m_type mt on f.fk_type_id = mt.pk_id and mt.name in('PL','PersonalLoan')
WHERE
	Cast(f.created_date as date) >= Cast(@FromDate as date)
and Cast(f.created_date as date) <= Cast(@ToDate as date)
ORDER BY f.created_date

GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_dump]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 -- exec sp_report_pl_application_getfrauddump '2019-01-01','2019-04-20'

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_dump]
	@FromDate datetime,
	@ToDate datetime
AS

  SELECT 
  ROW_NUMBER() OVER (ORDER BY  Received_Date ASC) AS Seq,
--	[ApplicationNo],
	ap.application_no as [ApplicationNo],

--	CONVERT(VARCHAR(24),[Received_Date],106),
	CONVERT(VARCHAR(24),[Received_Date],106),
--	[ChannelD],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

--	[ARMCode],
	ap.arm_code as [ARMCode],
--	[PIDOfSaleStaff],
	ap.sale_staff_bank_id as[PIDOfSaleStaff],
--	[LocationBranchName],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [LocationBranchName],

--	[ProductTypeName],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [ProductTypeName],

--	[CardPickUpName],
	'' as [CardPickUpName],
--	[ProgramCodeName],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [ProgramCodeName],
--	[TypeApplicationName],
	(select top(1) m.[description] from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [TypeApplicationName],
--	[CardProgramName],
	
	(select top(1)ca.name from cc_card_program ca
					where pap.fk_card_program_id = ca.pk_id and ca.is_active =1) as [CardProgramName],
--	[CardTypeName],
	''  as [CardTypeName],
--	[CardTypeName2],
	'' as [CardTypeName2],
--	[HolderInitial],
	CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1) as [HolderInitial],

--	[HolderInterestRateSuggested],
	pap.holder_interest_rate_suggested as [HolderInterestRateSuggested],
--	[HolderCurrentAccountNo],
	pap.holder_current_account_no as [HolderCurrentAccountNo],
--	[HolderDepositedCurrency],
	(select top(1) m.name from pl_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,
--	[HolderCurrencyDepositedAmount],
	CONVERT(varchar, CAST(pap.holder_currency_deposited_amount AS MONEY), 1) AS [HolderCurrencyDepositedAmount],
--	[CreditBureauType],
	(select top(1)m.name from cc_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [CreditBureauType],

--	[CIQueuedTime],
	pap.ci_queued_time as [CIQueuedTime],
--	[IsLocked],
	ap.is_locked as [IsLocked],
--	[LockedBy],
    ap.user_lock as [LockedBy],
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	[IsSecured],
	ap.is_secured as [IsSecured],
--	[IsOnline],
	'' as  [IsOnline],
--	[IsSMS],
	ap.is_sms_send as  [IsSMS],
--	[TotalOfSubCard],
    0 as [TotalOfSubCard],
--	[CurrentUnsecuredOutstanding],
	(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from cc_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [CurrentUnsecuredOutstanding],

--	[CurrentTotalEMI],
	CONVERT(varchar, CAST(Isnull(apr.total_emi,0)AS MONEY), 1)   AS [CurrentTotalEMI],

--	[LimitSuggestedMUE],
	CONVERT(varchar, CAST(Isnull(apr.mue_suggested,0)AS MONEY), 1)    AS [LimitSuggestedMUE],
--	[EMISuggested],
	'' as [EMISuggested],
--	[InterestRateSuggested],
	'' as[InterestRateSuggested],

--	[FinaIlnterestRate],
	''   as [FinaIlnterestRate],
--	[MUE],
	CONVERT(varchar, CAST(apr.mue AS MONEY), 1)   as [MUE],
--	[MaxDSR],
	0  as [MaxDSR],
--	[MaxDTI],
	CONVERT(varchar, CAST(apr.dti AS MONEY), 1)   as [MaxDTI],
--	[LimitSuggestedDSR],
	CONVERT(varchar, CAST(apr.dsr_suggested AS MONEY), 1)   as [LimitSuggestedDSR],
--	[LimitSuggestedDTI],
	CONVERT(varchar, CAST(apr.dti_suggested AS MONEY), 1) as [LimitSuggestedDTI],
--	[LTVSuggested],
	CONVERT(varchar, CAST(apr.ltv_suggested AS MONEY), 1) as [LTVSuggested],
--	[FinalLimitApproved],
	apr.final_loan_amount_approved as [FinalLimitApproved],
--	[FinalTotalEMI],
	apr.total_emi as [FinalTotalEMI],
--	[FinalTotalDSR],
	apr.total_dsr as  [FinalTotalDSR],
--	[FinalMUEAtSCB],
	'' as [FinalMUEAtSCB],
--	[FinalDTI],
	apr.dti as [FinalDTI],
--	[FinalLTV],
	apr.ltv as [FinalLTV],
--	[FinalApprovalStatus],
	
	(select top(1)  m.name  from m_status m
				where apr.fk_final_approval_status_id = m.pk_id and m.is_active = 1) as [FinalApprovalStatus],
--	[DecisionDate],
	apr.decision_date as [DecisionDate],
--	[RejectReasonID],
	(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83) 
				 and (m.name <> '' or m.name is not null)) as  CC_Rejected_Or_Cancelled_Reason,

--	[CancelReasonID],
	(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(84) 
				 and (m.name <> '' or m.name is not null)) as [CancelReasonID],
--	[DisbursementScenarioId],
	'' as [DisbursementScenarioId],
	--(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
	--				on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
	--				where dis.fk_application_information_id = ap.pk_id) as [DisbursementScenarioId],
	'' as [DisbursementScenarioId],
--	[DisbursementScenarioText],
	'' as [DisbursementScenarioText],
	--	[DeviationCodeID],
	(select top(1)m.name from m_deviation_code m
					where apr.fk_deviation_code_id = m.pk_id)  as [DeviationCodeID],	 
--	[MUE_CC],
	apr.mue as [MUE_CC],
--	[CIRecommend],
	'' as [CIRecommend],
--	GrossSalary,
	(select top(1)cin.gross_base_salary from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as GrossSalary,
--	NetSalary,
	(select top(1)cin.income_net from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as NetSalary,
--	MonthlyIncome,
	(select top(1)cin.monthly_income_declared from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as MonthlyIncome,
--	PerformanceBonus,
	(select top(1)cin.guaranteed_bonus from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as PerformanceBonus,
--	GuaranteedBonusIncome,
	(select top(1)cin.guaranteed_bonus from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as GuaranteedBonusIncome,
--	cc.[IsBankStaff],
	ci.is_staff as [IsBankStaff],
--	cc.[BankRelationship],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [BankRelationship],

--	cc.[CustomerSegment],
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [CustomerSegment],

--	cc.[Initital],
	ci.initital as Initital,
--	cc.[FullName],
	cus.full_name as [FullName],
--	cc.[EmbossingName],
	cus.embossing_name as [EmbossingName],
--	cc.[DOB],
	cus.dob as [DOB],
--	cc.[Gender],
	(select top(1)m.name from m_definition_type m
					where cus.fk_gender_id = m.pk_id and m.is_active = 1 and m.fk_group_id = 38) as Gender,
--	cc.[Nationality],
	(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Nationality],

--	cc.[MaritalStatus],
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id and m.is_active =1) as [MaritalStatus],
--	cc.[PermAddress],
	cus.permanent_address AS PermAddress,
--	cc.[PermWard],
	cus.permanent_ward as [PermWard],
--	cc.[PermDistrict],
	cus.permanent_district as  [PermDistrict],
--	cc.[PermCity],
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1 and m1.fk_group_id =66) as [PermCity],
--	cc.[TypePermAddress],
	cus.permanent_address as [TypePermAddress],
--	cc.[TypeResidentialAdd],
	'' as [TypeResidentialAdd],
--	cc.[ResidentialAddress],
	cus.residential_address as [ResidentialAddress],
--	cc.[ResidentialWard],
	cus.residential_ward as ResidentialWard,
--	cc.[ResidentialDistrict],
	 cus.residential_district as  ResidentialDistrict,
--	cc.[ResidentialCity],
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1 and m1.fk_group_id =64) as [PermCity],

--	cc.[DateIssuedResidentialAdd],
	cus.issued_date_residential_address as [DateIssuedResidentialAdd],
--	cc.[OwnerResidentialAdd],
	cus.owner_residential_address as [OwnerResidentialAdd],
--	cc.[PrimaryPhoneNo],
	cus.primary_phone_no as  [PrimaryPhoneNo],
--	cc.[HomePhoneNo],
	cus.home_phone_no as [HomePhoneNo],
--	cc.[BillingAddress],
	cus.billing_address as [BillingAddress],
--	cc.[EmailAddress1],
	cus.email_address_1 as [EmailAddress1],
--	cc.[EmailAddress2],
	cus.email_address_2 as [EmailAddress2],
--	cc.[EmailAddress3],
	cus.email_address_3 as [EmailAddress3],
--	cc.[RLSCompanyCode],
	co.company_code_rls as RLSCompanyCode,
--	cc.[CompanyCode],
	co.company_code as [CompanyCode],
--	cc.[CompanyName],
	co.company_name as CompanyName,
--	cc.[CompanyRemark],
	co.company_remark as[CompanyRemark],
--	cc.[TypeEmployment],
	(select top(1)m.name from cc_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

--	cc.[CompanyAddress],
	co.company_address as  [CompanyAddress],
--	cc.[CompanyWard],
	co.company_ward as [CompanyWard],
--	cc.[CompanyDistrict],
	co.company_district as [CompanyDistrict],
--	cc.[CompanyCity],
	(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1) as [CompanyCity],
--	cc.[CompanyPhone],
	co.office_telephone as [CompanyPhone],
--	cc.[BusinessType],
	(select top(1) m.name from m_business_nature m
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [BusinessType],

--	cc.[CompanyCAT],
	co.company_cat as [CompanyCAT],
--	cc.[Industry],
	(select top(1) m.name from m_industry m
					where co.fk_m_industry_id = m.pk_id and m.is_active =1) as [CurrentPosition],
--	cc.[CurrentPosition],
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [CurrentPosition],
--	cc.[VerifiedPosition],
	(select top(1) m.name from m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [VerifiedPosition],
--	cc.[Occupation],
	(select top(1) m.name from  m_occupation m
						where cus.fk_occupation_id = m.pk_id and m.is_active =1) as  [Occupation],
--	cc.[OccupationVerified],
	(select top(1) m.name from m_occupation m
						where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as  [OccupationVerified],
--	cc.[OccupationType],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [OccupationTypeVerified],
--	cc.[OccupationTypeVerified],
	(select top(1) m.name from cc_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [OccupationTypeVerified],
--	cc.[TypeOfContract],
	(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,

--	cc.[IsPassProbation],
	cus.is_pass_probation as [IsPassProbation],
--	cc.[OperationSelfEmployed],
	(select top(1) m.name from  m_definition_type m
					  where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 and m.fk_group_id = 69 ) as OperationSelfEmployed,
--	cc.[IncomeType],
	(select top(1)m.name from pl_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [IncomeType],

--	cc.[IncomeNet],
		(select top(1) cin.income_net from pl_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as  [IncomeNet],
--	cc.[TakingLowestVarIncome],
	'' as [TakingLowestVarIncome],
--	cc.[IncomeEligible],
	(select top(1) cin.income_eligible from pl_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as [IncomeEligible],

--	cc.[IncomeTotal],
	(select top(1) cin.total_borrower_income from pl_customer_income cin 
					where cin.fk_customer_information_id = cus.fk_customer_information_id) as [IncomeTotal],

--	cc.[PaymentType],
	(select top(1) m.name from m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id) as RepaymentType,

--	cc.[CreatedDate],
	cus.created_date as [CreatedDate],
--	cc.[BusinessNatureCode],
	
	(select top(1)m.name from m_business_nature m
					where cus.fk_business_nature_code_id = m.pk_id and m.is_active =1) as [BusinessNatureCode],
--	cc.[CurrentResidentTypeCode],
	
	(select top(1)m.name from m_current_resident_type m
					where cus.fk_current_resident_type_code_id = m.pk_id and m.fk_group_id = 40 
					     and m.is_active =1) as [CurrentResidentTypeCode],
--	cc.[OwnershipTypeCode], ???
	/*cus.fk_ownership_type_code_id*/ '' as [OwnershipTypeCode],
--	cc.[CustomerTypeCode],
	/*cus.fk_customer_type_code_id*/ '' as  [CustomerTypeCode],
--	cc.[Status] as CustomerStatus,
	(select top(1) m.name from m_status m
					where m.pk_id = cus.fk_status_id and m.is_active =1) as CustomerStatus,
--	cc.[PositionID],
	
	(select top(1)m.name from m_position m
					where m.pk_id = cus.fk_current_position_id and m.is_active =1) as [PositionID],
--	cc.[YearsInCurrentEmployment],
	cus.years_in_current_employment_id as [YearsInCurrentEmployment],
--	cc.[ResidenceName],
	cus.residence_name as[ResidenceName],
--	cc.[TimeAtCurrentAddress],
	cus.time_current_address as [TimeAtCurrentAddress],
--	cc.[EducationID],
	(select top(1)m.name from m_education m
					where m.pk_id = cus.fk_education_id and m.is_active =1) as [EducationID],
	
--	cc.[PreviousID],
	
	(select top(1) cus.identification_no
	  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
	  where cus.fk_customer_information_id = ci.pk_id) as [PreviousID],

--	cc.[NumberBankRelationship],
	/*cus.fk_bank_relationship_id*/ '' as [NumberBankRelationship],

--	cc.MonthlyIncomeDeclared,
	(select top(1)cin.monthly_income_declared from pl_customer_income cin
								  where cin.fk_customer_information_id = ci.pk_id) as MonthlyIncomeDeclared,
--	TradingArea
	
	(select top(1)m.name from m_trading_area m
					where m.pk_id = cus.fk_trading_area_id and m.is_active=1) as TradingArea
	
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_approval_information apr on apr.fk_application_information_id = ap.pk_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	
WHERE
	   Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_investigation_page]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_investigation_page]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  fr.created_date ASC) AS Seq,
--ApplicationNo,
ap.application_no as  ApplicationNo,
--CustomerName,
ci.full_name as CustomerName,
--PreviousNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID' 
									   and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id)  as PreviousNo,
--PersonalNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as PersonalNo,
--PassportNo,
--PassportNo,
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as  PassportNo,
--SocialNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Social'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as SocialNo,

CONVERT(varchar, CAST(fr.loan_amount_applied AS MONEY), 1) AS LoanAmountApplied,

--ReferedChannel,
	fr.refered_channel as ReferedChannel,
--ReferedBy,
	fr.refered_by as ReferedBy,
--CONVERT(VARCHAR(24),ReferedDate,106) as ReferedDate,
	CONVERT(VARCHAR(24),refered_date,106) as ReferedDate,
--SuspiciousDocument,
(select top(1)fi.file_name from frm_investigave_file fi
				where fr.pk_id = fi.fk_frm_investigave_id and fi.is_active =1) as SuspiciousDocument,
--InvestigatorResult,
	fr.investigator_result as InvestigatorResult,
--EmployeeInvolved,
  fr.employee_involved as EmployeeInvolved,
--ExternalPartyInvolved,
  fr.external_party_involved as ExternalPartyInvolved,
--SignificantFraud,
  fr.significant_fraud as SignificantFraud,
--SummaryInvestigation,
  fr.summary_investigation as SummaryInvestigation,
--Finndings,
  fr.finndings,
--CONVERT(VARCHAR(24),DecisionDate,106) as DecisionDate,
	CONVERT(VARCHAR(24),decision_date,106) as DecisionDate,
--DecisionCode,
	fr.decision_code as DecisionCode,
--Status,
	(select top(1)m.name from m_status m
				where ap.fk_m_status_id = m.pk_id and m.is_active = 1) as Status,
--CONVERT(VARCHAR(24),fr.created_date,106) as fr.created_date,
	CONVERT(VARCHAR(24),fr.created_date,106) as createddate,
--CreatedBy,
	fr.Created_By as CreatedBy,
--CONVERT(VARCHAR(24),CheckerDate,106) as CheckerDate,
CONVERT(VARCHAR(24),fr.Checker_Date,106) as CheckerDate,
--CheckerBy
	fr.Checker_By as  CheckerBy
FROM
	frm_investigave  fr
	inner join pl_application pap on fr.fk_application_information_id = pap.fk_application_information_id
	left join application_information ap on fr.fk_application_information_id = ap.pk_id
	left join customer_information ci on fr.fk_customer_information_id = ci.pk_id
	
WHERE
	Cast(fr.created_date as date) >= Cast(@FromDate as date)
and Cast(fr.created_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_queue_page]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_cc_application_getfraudqueuepage '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_queue_page]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  fr.created_date ASC) AS Seq,
--ApplicationNo,
  ap.application_no as  ApplicationNo,
  --CustomerName,
 ci.full_name as CustomerName,
 --PreviousNo,
 (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID' 
									   and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id)  as PreviousNo,
  --PersonalNo
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as PersonalNo,
  --PassportNo,
  (select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as  PassportNo,
--SocialNo,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									on ci.fk_m_identification_type_id = m.pk_id and m.name ='Social'
									 and m.is_active =1
  where ci.fk_customer_information_id = ci.pk_id) as SocialNo,

--ReferedChannel,
  fr.refered_channel as ReferedChannel,
--ReferedBy,
  fr.refered_by as ReferedBy,
--CONVERT(VARCHAR(24),ReferedDate,106) as ReferedDate,
 CONVERT(VARCHAR(24),refered_date,106) as ReferedDate,
--InvestigatorResult,
 fr.investigator_result as InvestigatorResult,
--CONVERT(VARCHAR(24),DecisionDate,106) as DecisionDate,
CONVERT(VARCHAR(24),decision_date,106) as DecisionDate,
--DecisionCode,
fr.decision_code as DecisionCode,
--Status,
(select top(1)m.name from m_status m
				where ap.fk_m_status_id = m.pk_id and m.is_active = 1) as Status,
--CONVERT(VARCHAR(24),CreatedDate,106) as CreatedDate,
CONVERT(VARCHAR(24),fr.created_date,106) as CreatedDate,
--CreatedBy,.
fr.Created_By as CreatedBy,
--CONVERT(VARCHAR(24),CheckerDate,106) as CheckerDate,
CONVERT(VARCHAR(24),fr.Checker_Date,106) as CheckerDate,

--CheckerBy
fr.Checker_By as  CheckerBy
FROM
	frm_investigave  fr
	inner join pl_application pap on pap.fk_application_information_id = fr.fk_application_information_id
	inner join application_information ap on fr.fk_application_information_id = ap.pk_id
	inner join customer_information ci on fr.fk_customer_information_id = ci.pk_id
	
WHERE
	Cast(fr.created_date as date) >= Cast(@FromDate as date)
and Cast(fr.created_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_fraud_sas_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_fraud_sas_reports]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
CONVERT(VARCHAR(10), ap.received_date, 101) as [ReceivedDate],
--pl.BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where pl.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

--(select top 1 IdentificationNo from plIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder ID],

--pl.FullName as [Primary Card Holder Name],
ci.full_name as [Primary Card Holder Name],

--(select top 1 IdentificationNo from plIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary Card Holder Previous ID],

--CONVERT(VARCHAR(10), pl.DOB, 101) as [DOB],
 CONVERT(VARCHAR(10), pl.dob, 101) as [DOB],
--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

--ap.FinalApprovalStatus as [pl_FinalApprovalStatus],
 (select top(1) m.name from pl_approval_information capi inner join m_status m on capi.fk_final_approval_status_id = m.pk_id
															  and m.is_active = 1	
						
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [pl_FinalApprovalStatus],
--plApp.PL_FinalApprovalStatus,
  '' as PL_FinalApprovalStatus,
--CONVERT(varchar, CAST(plApp.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan amount approved],
  (select top(1) CONVERT(varchar, CAST(capi.final_loan_amount_approved AS MONEY), 1) from pl_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [Loan amount approved],

--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
(select top(1) CONVERT(VARCHAR(10),capi.decision_date, 101) from pl_approval_information capi
				  where capi.fk_application_information_id = ap.pk_id
				  ) as [Date of Decision],
--ap.EMISuggested AS EMI,
 '0' as EMI,
--ap.ChannelD AS Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1)AS Channel,

--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode AS [ARM Code],
 ap.arm_code as [ARM Code],
--pl.CompanyPhone AS [Office Phone],
(select top(1) co.office_telephone from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Office Phone],
--pl.PrimaryPhoneNo AS [Mobile Phone],
pl.primary_phone_no AS [Mobile Phone],
--pl.PermAddress AS [Permanent address],
pl.permanent_address as [Permanent address],
--pl.CompanyCode as [Company Code],
(select top(1) co.company_code from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1)  as [Company Code],
--pl.RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--pl.CompanyName as [Company Name],
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Name],
--pl.CompanyAddress as [Company Address],
(select top(1)co.company_address from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Address],
--pl.TypeEmployment as [Employment type], fk_m_employment_type_id
(select top(1)m.name from pl_company_information co inner join m_employment_type  m
																on m.pk_id = co.fk_m_employment_type_id and m.is_active =1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Employment type],
--pl.CurrentPosition as [Current Position],
(select top(1)m.name from pl_company_information co  inner join m_position m
																  on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Current Position],
--pl.Oplupation,

(select top(1)m.name from pl_company_information co  inner join m_oplupation m
																  on m.pk_id = co.fk_m_oplupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Oplupation,
--CONVERT(varchar, CAST(pl.TotalMonthlyIncomeViaBS AS MONEY), 1) AS [Total Income], 
(select top(1)CONVERT(varchar, CAST(cui.total_monthly_income_via_bs AS MONEY), 1) from pl_customer_income cui
				where cui.fk_pl_customer_information_id = ci.pk_id and cui.is_active= 1) as [Total Income],
--ap.CreditBureauType as [Bureau Type]
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id)  as [Bureau Type]
FROM
	
	[dbo].[pl_application] cap 
	inner join application_information ap on cap.fk_application_information_id  = ap.pk_id
	inner join pl_customer_information pl on cap.fk_application_information_id = pl.fk_application_information_id
	inner join customer_information ci on ci.pk_id = pl.fk_customer_information_id
	--Left Join plPLApplication plApp on plApp.plApplicationNo = ap.ApplicationNo
	
WHERE
	Cast(ap.received_date  as Date) >= Cast(@FromDate  as Date)
and Cast(ap.received_date  as Date) <= Cast(@ToDate  as Date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_imported_application_statistics]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_imported_application_statistics]
	@FromDate datetime,
	@ToDate datetime,
	@Status varchar(20)
AS

SELECT [file_name] as [FileName],
error_log as ErrorLog,
CONVERT(VARCHAR(24),lg.created_date,113) as CreatedDate ,
m.name as [Status],
vendor_id as VendorID,
--CustomerPersonalID,
(select top(1)cus.identification_no from customer_identification cus
				                   where cus.fk_customer_information_id = ci.pk_id) as CustomerPersonalID,
--CustomerName,
ci.full_name as CustomerName,
--CustomerDOB,
ci.dob as CustomerDOB,
(select top(1) ap.application_no from application_information ap
				where ap.pk_id = lg.fk_application_information_id) as CCAppNo,
mt.name as ProductTypeName,
vendor_date as VendorCreatedDate
FROM
	application_log_import lg
	left join customer_information ci on ci.fk_application_information_id = lg.fk_application_information_id
	left join m_status m on m.pk_id = lg.fk_status_id and m.is_active =1
	left join m_type mt on lg.fk_type_id = mt.pk_id and mt.name in('PL','PersonalLoan')
WHERE
(m.name = @Status or @Status is null)	
and Cast(@FromDate as date) <= Cast(lg.created_date as date)
and Cast(@ToDate as date) >= Cast(lg.created_date as date)

ORDER BY CreatedDate desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_lo_modify_sc_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_lo_modify_sc_reports]
	@FromDate datetime,
	@ToDate datetime
AS

--SELECT 
--	ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS Seq,
--	ApplicationNo,
--	ARMCode,
--	PIDOfSaleStaff as [Sale Code],
--	CreatedBy,
--	CONVERT(VARCHAR(10), CreatedDate, 101) as [CreatedDate],
--	CheckerBy,
--	CONVERT(VARCHAR(10), CheckerDate, 101) as [CheckerDate],
--	[Status]

--FROM LOModifySC
	
--WHERE
--	dbo._fGetShortDate(CreatedDate) >= dbo._fGetShortDate(@FromDate)
--and dbo._fGetShortDate(CreatedDate) <= dbo._fGetShortDate(@ToDate)
--ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_master_acs_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_report_pl_application_get_master_acs_report]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
	--ap.ARMCode,
	ap.arm_code as ARMCode,
	--cc.Initital,
	 ci.initital,
	--cc.Gender,
	(select top(1)m.name from m_group mg inner join m_definition_type m
											on mg.pk_id = m.fk_group_id and m.pk_id = 38 and m.is_active =1
					where cus.fk_gender_id = mg.pk_id and mg.is_active = 1) as Gender,
	--cc.FullName,
	cus.full_name as  FullName,
	--cc.DOB,
	cus.dob as  DOB,
	--cc.Nationality,
	(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
	--cc.MaritalStatus,
	
	(select top(1)m.name from m_marital_status m
					where cus.fk_marital_status_id = m.pk_id and m.is_active =1) as MaritalStatus,
	--cc.PrimaryPhoneNo,
	 cus.primary_phone_no AS PrimaryPhoneNo,
	--cc.HomePhoneNo,
	cus.home_phone_no as  HomePhoneNo,
	--cc.BillingAddress,
	cus.billing_address as  BillingAddress,
	--cc.EmailAddress1,
	cus.email_address_1 as  EmailAddress1,
	--(select top 1 IdentificationNo from CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as IdentificationNo,
	(select top(1) cus.identification_no
		from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id 
							and m.name in('ID','Passport','Previous_ID','Previous_PP')
       where cus.fk_customer_information_id = ci.pk_id) as IdentificationNo,

	--(select top 1 ExpriedDate from CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as ExpriedDate,
	(select top(1) cus.expried_date
		from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id 
							and m.name in('ID','Passport','Previous_ID','Previous_PP')
       where cus.fk_customer_information_id = ci.pk_id) as ExpriedDate,

	--cc.ResidentialAddress,
	cus.residential_address as ResidentialAddress,
	--cc.ResidentialWard,
	cus.residential_ward as ResidentialWard,
	--cc.ResidentialDistrict,
	 cus.residential_district as  ResidentialDistrict,
	--cc.ResidentialCity,
	(select top(1) m1.name from m_city m1
							where cus.fk_residential_city_id = m1.pk_id and m.is_active =1) ResidentialCity,
	--cc.PermCity,
	(select top(1) m1.name from m_city m1 
							where cus.fk_permanent_city_id = m1.pk_id and m.is_active =1) PermCity,
	--cc.PermAddress,
	cus.permanent_address AS PermAddress,
	--cc.PermWard,
	cus.permanent_ward AS PermWard,
	--cc.PermDistrict,
	cus.permanent_district  AS PermDistrict,
	--cc.CompanyName,
	co.company_name as  CompanyName,
	--cc.CompanyAddress,
	co.company_address as  CompanyAddress,
	--cc.CompanyWard,
	co.company_ward as CompanyWard,
	--cc.CompanyDistrict,
	co.company_district as CompanyDistrict,
	--cc.CompanyCity,
	(select top(1) m1.name from m_city m1
						  where co.fk_company_city_id = m1.pk_id and m.is_active =1) CompanyCity,
	--cc.CompanyPhone,
	co.office_telephone as  CompanyPhone,
	--cc.CurrentPosition,
	(select top(1)m.name from cc_company_information co  inner join m_position m
																  on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CurrentPosition,
	--cc.Occupation,
	(select top(1)m.name from cc_company_information co  inner join m_occupation m
																  on m.pk_id = co.fk_m_occupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Occupation,
	--cc.OperationSelfEmployed,
	(select top(1) m.name from  m_group m inner join m_definition_type md 
													on m.pk_id = md.fk_group_id and m.pk_id = 69	and md.is_active =1							where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 ) as OperationSelfEmployed,

	--cc.TypeOfContract,
	(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
	--cc.MonthlyIncomeDeclared,
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,
	--cc.ResidentStatus,
	'' as ResidentStatus,
	--cc.PlaceofBirth,
	cus.place_of_birth as PlaceofBirth,
	--cc.OfficeEmail,
	cus.office_email as OfficeEmail,
	--cc.Qualifications,	
	
	(select top(1) m.name from  m_group m inner join m_definition_type md 
													on m.pk_id = md.fk_group_id and m.pk_id = 47	and md.is_active =1							where cus.fk_qualifications_id = m.pk_id and m.is_active=1 ) as Qualifications,
	--cc.ThirdPartyContact1,
	cus.third_party_contact_1 as ThirdPartyContact1,
	--cc.ThirdPartyContact2,
	cus.third_party_contact_2 as ThirdPartyContact2,
	m.name as [CurrentStatus]

	FROM
		[dbo].[pl_application] pap 
		inner join application_information ap on ap.pk_id = pap.fk_application_information_id
		inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
		inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
		left join pl_company_information co on co.fk_application_information_id = ap.pk_id 
		left join m_status m on ap.fk_m_status_id = m.pk_id and m.is_active = 1
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	and m.name in ('CIApproved','LODisbursed')
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_master_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_pl_application_get_pl_masterci '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_master_ci]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
 CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
--ap.ProductTypeName,
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as ProductTypeName,
--ap.TypeApplicationName as [Type of Application],
pap.type_of_application as [Type of Application],
--ap.ApplicationNo,
ap.Application_No as ApplicationNo,
--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),cus.dob,106) as PrimaryCardHolderDOB,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,

--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as  RepaymentType,
--cc.BankRelationship as CustomerRelation,
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as CustomerRelation,
--cc.CustomerSegment,
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as CustomerSegment,
--ap.CardTypeName as CardType1,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as CardType1,

--ap.CardTypeName2 as CardType2,
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardType2,

--ap.CardProgramName as CardProgram
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as CardProgram,

--ap.HolderDepositedCurrency as [Deposited Currency],
(select top(1) m.name from pl_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as [Deposited Currency],

--CONVERT(varchar, CAST(ap.HolderCurrencyDepositedAmount AS MONEY), 1) AS [DespositedAmount],
CONVERT(varchar, CAST(pap.holder_currency_deposited_amount AS MONEY), 1)  AS [DespositedAmount],

--(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where fk_application_information_id = ap.pk_id and BlackListCode<>null) as BlackList,
(select  (case when COUNT(*)>0 then 'Yes' else 'No' end) 
				from frm_black_list_log frm 
				where ap.pk_id = frm.fk_application_information_id and frm.fk_frm_black_list_code_id <> null) as BlackList,

--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from m_position m
				where cus.fk_customer_information_id = m.pk_id) as SelfEmployed,
--cc.PrimaryPhoneNo as MobilePhone,
 cus.primary_phone_no AS MobilePhone,
--cc.TradingArea as TradingCity,
(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingCity,
--(cc.ResidentialDistrict + ' ' + cc.ResidentialWard +  ' ' + cc.ResidentialAddress) as CustomerResAddress,
(cus.residential_district + ' ' + cus.residential_ward +  ' ' + cus.residential_address) as CustomerResAddress,

--(cc.PermDistrict + ' ' + cc.PermWard +  ' ' + cc.PermAddress) as CustomerPermAddress,
(cus.permanent_district + ' ' + cus.permanent_ward  +  ' ' + cus.permanent_address) as CustomerPermAddress,
--cc.TypePermAddress as [Perm Address City],
(select top(1) m.name from m_definition_type m
		  where cus.fk_permanent_address_type_id= m.pk_id and m.is_active =1 and m.fk_group_id = 39) as[Perm Address City],
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--cc.CompanyCity as CompanyCity,
(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1) as CompanyCity,
--cc.BusinessType as CompanyCAT,
(select top(1) m.name from m_business_nature m
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as CompanyCAT,

--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,

null as JobTitle,

--OccupationTypeVerified as VerifiedOccupationType,
(select top(1) m.name from pl_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as VerifiedOccupationType,

--CONVERT(varchar, CAST(MonthlyIncomeDeclared AS MONEY), 1) AS [MonthlyIncomeDeclared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [MonthlyIncomeDeclared],

--CONVERT(varchar, CAST(IncomeEligible AS MONEY), 1) AS [TotalMonthlyVisBS],
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [TotalMonthlyVisBS],

--CONVERT(varchar, CAST(IncomeTotal AS MONEY), 1) AS [TotalFinalIncome],
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [TotalFinalIncome],
--CreditBureauType as [Bureau type],
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m on cb.fk_m_credit_bureau_type_id = m.pk_id and
																				 m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau type],
--CONVERT(varchar, CAST(CurrentUnsecuredOutstanding AS MONEY), 1) AS [OS_At_Other_Bank (Current Unsecured Outstanding Off Us)],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_on_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS [OS_At_Other_Bank (Current Unsecured Outstanding Off Us)],

--CONVERT(varchar, CAST(CurrentTotalEMI AS MONEY), 1) AS [EMI_At_Other_Bank (Current total EMI Off Us)],
(select top(1)CONVERT(varchar, CAST(cb.current_total_emi_on_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS [EMI_At_Other_Bank (Current total EMI Off Us)],

--CONVERT(varchar, CAST(CurrentUnsecuredOutstandingOnUs AS MONEY), 1) AS [Current Unsecured Outstanding on us],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_on_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS [Current Unsecured Outstanding on us],

--CONVERT(varchar, CAST(CurrentTotalEMIOnUs AS MONEY), 1) AS [Current Total EMI On Us],
(select top(1)CONVERT(varchar, CAST(cb.current_total_emi_on_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS [EMI_At_Other_Bank (Current total EMI Off Us)],
--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) 
CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)  AS [Personal Loan Amount Applied],

--ccPL.LoanTenor,
pap.loan_tenor_applied as LoanTenor,
--ccPL.LoanPurpose,
'' as LoanPurpose,
--ccPL.InterestRateClassification,
(select top(1)m.name from m_interest_classification m
					 where  pap.fk_interest_classification_id = m.pk_id and m.is_active =1) as InterestRateClassification,
--ccPL.PLSuggestedInterestRate,
CONVERT(varchar, CAST(pap.suggested_interest_rate AS MONEY), 1) as  PLSuggestedInterestRate,
--ccPL.PLFinalLoanAmountApproved,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr 
				where apr.fk_application_information_id = ap.pk_id) as PLFinalLoanAmountApproved,
--ccPL.SCB_PL_EMI,
(select top(1)CONVERT(varchar, CAST(apr.scb_emi AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as SCB_PL_EMI,
--(case when ccPL.MRTACreditLife = 1 then 'YES' else 'NO' end) as [Credit Life],
(case when pap.is_mrta_credit_life = 1 then 'YES' else 'NO' end) as [Credit Life],
--ccPL.PaymentOption as [CreditLife_PaymentOption],
(select top(1) m.name from m_payment_option m
				where pap.fk_payment_option_id = m.pk_id and m.is_active=1)  as [CreditLife_PaymentOption],
--ccPL.NonFinance as [NonFinance_CREDIT],
(select pl.is_non_finance from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id)  as [NonFinance_CREDIT],
--CONVERT(varchar, CAST(ccPL.ApprovedSinglePremium AS MONEY), 1) AS [CreditLife_SinglePremium],
(select CONVERT(varchar, CAST(pl.approved_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) AS [CreditLife_SinglePremium],
--CONVERT(varchar, CAST(ccPL.ApproveLoanAmountincludedCLPL AS MONEY), 1) AS [Approve Loan Amount Included CLPL],
(select CONVERT(varchar, CAST(pl.approve_loan_amount_included_clpl AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id)  AS [Approve Loan Amount Included CLPL],
--CONVERT(varchar, CAST(ccPL.EMIIncludedSinglePremium AS MONEY), 1) AS [EMI(include single premium)],
(select CONVERT(varchar, CAST(pl.emi_included_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) AS [EMI(include single premium)],
--CONVERT(varchar, CAST(ccPL.TotalEMIForPL AS MONEY), 1) AS [TotalEMIForPL],
(select top(1)CONVERT(varchar, CAST(apr.total_emi AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  AS [TotalEMIForPL],
--CONVERT(varchar, CAST(ccPL.TotalDSRForPL AS MONEY), 1) AS [TotalDSRForPL],
(select top(1)CONVERT(varchar, CAST(apr.total_dsr AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS  [TotalDSRForPL],
--CONVERT(varchar, CAST(ccPL.MUE_PL AS MONEY), 1) AS [MUE_PL],
(select top(1)CONVERT(varchar, CAST(apr.mue AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [MUE_PL],
--CONVERT(varchar, CAST(ccPL.PLDTI AS MONEY), 1) AS [PLDTI],
(select top(1)CONVERT(varchar, CAST(apr.dti AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [PLDTI],
--CONVERT(varchar, CAST(HolderInitial AS MONEY), 1) AS [InitialLimit],
 CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1)  AS [InitialLimit],
--CONVERT(varchar, CAST(FinalLimitApproved AS MONEY), 1) AS [FinalLimitApproved],
	(select top(1)CONVERT(varchar, CAST(apr.final_limit_approved AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS   [FinalLimitApproved],
--CONVERT(varchar, CAST(FinalTotalEMI AS MONEY), 1) AS [TotalEMI],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_emi,0) - Isnull((select top(1) cb.current_total_emi_on_us 
																	from pl_customer_credit_bureau cb
																	where  cb.fk_customer_information_id = ci.pk_id),0)
AS MONEY), 1)  from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [TotalEMI],

--FinalTotalDSR as [TotalDSR %],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_total_dsr,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [TotalDSR %],
--MUE_CC as [MUE CC],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.cc_mue,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [MUE CC],
--FinalMUEAtSCB as [MUE at SCB],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_mue_at_scb,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [MUE at SCB],
--FinalDTI as DTI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_dti,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DTI,
--(FinalLTV * 100) as TotalLTV,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.final_ltv * 100,0) AS MONEY), 1)  
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as TotalLTV,

--ccPl.PL_FinalApprovalStatus as [PL-DECISION-STATUS],
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as [PL-DECISION-STATUS],
--(case when PL_RejectReasonID is not null and PL_RejectReasonID<>''  then PL_RejectReasonID else PL_CancelReasonID end) as [PL-Rejected_Or_Cancelled_Reason],
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) 
				 and (m.name <> '' or m.name is not null))  as [PL-Rejected_Or_Cancelled_Reason], 
--(select top 1 Remark from CCRemark where fk_application_information_id = ap.pk_id and ProductTypeName='PN' order by CreatedDate) as [Remark-PL],
(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from pl_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as [Remark-PL],
--FinalApprovalStatus as  [CC-Decision Status],
(select top(1)  m.name
				from cc_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as [CC-Decision Status],
--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DecisionDate,

--ap.Status as CurrentApplicationStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentApplicationStatus,

--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID=(select top 1 action_by from application_action_log where fk_application_information_id = ap.pk_id and Action='Tele_Modified')) as TeleVerifier,
(select top 1 action_by from application_action_log where fk_application_information_id = ap.pk_id and Action='Tele_Modified') as TeleVerifier,

--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID= CIRecommend) as [UserRecommend (Underwriter)],
'' as [UserRecommend (Underwriter)],
--(select top 1 lu.FullName from LoginUser lu where lu.PeoplewiseID= (select top 1 action_by from application_action_log where fk_application_information_id = ap.pk_id and Action in ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD'))) as Approver,
(select top 1 action_by from application_action_log where fk_application_information_id = ap.pk_id and Action in ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD')) as Approver,
--(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as CC_Rejected_Or_Cancelled_Reason,
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) and (m.name <> '' or m.name is not null)) as  CC_Rejected_Or_Cancelled_Reason,

--(select top 1 Remark from CCRemark where fk_application_information_id = ap.pk_id and ProductTypeName='CC' order by CreatedDate) as CC_Remark,
(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as CC_Remark,

--ap.DeviationCodeID as LevelName,
(select top(1)m.name from pl_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as LevelName,

--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

--LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action='OSSendBack')) as Pending_OSSendback,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as Pending_CISendback,

(select COUNT(*) from application_action_log where fk_application_information_id = ap.pk_id and (Action='CISendBackSC' or Action='CISendBackCI')) as No_Of_CISentBack,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'Tele_SentBack%')) as Pending_TeleSentBack,

(select COUNT(*) from application_action_log where fk_application_information_id = ap.pk_id and (Action='Tele_SentBack')) as No_Of_TeleSentBack,

(CASE WHEN (SELECT TOP 1[Is_Pass] FROM [CC_Criteria] cr 
										inner join m_criteria m on cr.fk_m_criteria_id = m.pk_id and m.is_active =1
WHERE cr.fk_application_information_id = ap.pk_id AND m.name = 'HomeSiteVisit') = 1 THEN 'Yes' ELSE 'No' END) AS [HomeSiteVisit Result],

(CASE WHEN (SELECT TOP 1 [Is_Pass] FROM [CC_Criteria] cr 
										inner join m_criteria m on cr.fk_m_criteria_id = m.pk_id and m.is_active =1
 WHERE cr.fk_application_information_id = ap.pk_id AND m.name = 'BankStatementCheck') = 1 THEN 'Yes' ELSE 'No' END) AS [BankStatementCheck Result],

 NULL AS [BankStatementCheck  Visitot],

--(CASE WHEN (select top 1 IsSendSMS from VerificationForm
--		where fk_application_information_id = ap.pk_id
--		and IsTeleVerify =1) = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_TeleVerifier,
(CASE WHEN (select top 1 Is_Send_SMS from Verification_Form
		where fk_application_information_id = ap.pk_id
		and is_telephone_verify =1) = 1 THEN 'Yes' ELSE 'No' END)  as SMSSent_TeleVerifier,

--(CASE WHEN IsSMS = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_Underwriter,
(CASE WHEN  ap.is_sms_send = 1 THEN 'Yes' ELSE 'No' END) as SMSSent_TeleVerifier,

(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE') as TATTele,
(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI1') as TATRecommender,
(select sum(Duration) from cc_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI2') as TATApprover,
(select COUNT(*) from application_action_log where fk_application_information_id = ap.pk_id and Action='CISendBackCI') as [Times sendback by CI to CI],

--ccCB.Limit AS [CreditCardLimit], ???
bru.total_limit_credit_card,
--ccCB.Bank AS [CreditCardBank], ???
bru.bank_name_highest_active_limit AS [CreditCardBank],
------------
(select [Name] from m_reason where  pk_id = (select top 1 fk_m_rework_reason_id from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

(select top 1 Remark from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1) as [Requeue Log Remark 1],

CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1),101) as [Requeue Log Sendback date 1],

(select top 1 [send_back_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1) as [Requeue Log Sendback by 1],

(select top 1 [remark_response] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1) as [Requeue Log Remark Response 1],

CONVERT(VARCHAR(24), (select top 1 [received_date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1),101) as [Requeue Log Response Date 1],

(select top 1 [received_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=1) as [Requeue Log Response By 1],
----------
(select [Name] from m_reason where  pk_id = (select top 1 fk_m_rework_reason_id from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2)) as [Requeue Log Sendback reason 2],

(select top 1 Remark from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2) as [Requeue Log Remark 2],

CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2),101) as [Requeue Log Sendback date 2],

(select top 1 [send_back_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2) as [Requeue Log Sendback by 2],

(select top 1 [Remark_Response] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2) as [Requeue Log Remark Response 2],

CONVERT(VARCHAR(24), (select top 1 [received_date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2),101) as [Requeue Log Response Date 2],

(select top 1 [Received_By] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=2) as [Requeue Log Response By 2],
----------
(select [Name] from m_reason where  pk_id = (select top 1 fk_m_rework_reason_id from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3)) as [Requeue Log Sendback reason 3],

(select top 1 Remark from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3) as [Requeue Log Remark 3],

CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3),101) as [Requeue Log Sendback date 3],

(select top 1 [send_back_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3) as [Requeue Log Sendback by 3],

(select top 1 [Remark_Response] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3) as [Requeue Log Remark Response 3],

CONVERT(VARCHAR(24), (select top 1 [received_date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3),101) as [Requeue Log Response Date 3],

(select top 1 [Received_By] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=3) as [Requeue Log Response By 3],
----------
(select [Name] from m_reason where  pk_id = (select top 1 fk_m_rework_reason_id from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4)) as [Requeue Log Sendback reason 4],

(select top 1 Remark from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4) as [Requeue Log Remark 4],

CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4),101) as [Requeue Log Sendback date 4],

(select top 1 [send_back_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4) as [Requeue Log Sendback by 4],

(select top 1 [Remark_Response] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4) as [Requeue Log Remark Response 4],

CONVERT(VARCHAR(24), (select top 1 [received_date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4),101) as [Requeue Log Response Date 4],

(select top 1 [Received_By] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=4) as [Requeue Log Response By 4],
----------
(select [Name] from m_reason where  pk_id = (select top 1 fk_m_rework_reason_id from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5)) as [Requeue Log Sendback reason 5],

(select top 1 Remark from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5) as [Requeue Log Remark 5],

CONVERT(VARCHAR(24), (select top 1 [Send_Back_Date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5),101) as [Requeue Log Sendback date 5],

(select top 1 [send_back_by] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5) as [Requeue Log Sendback by 5],

(select top 1 [Remark_Response] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5) as [Requeue Log Remark Response 5],

CONVERT(VARCHAR(24), (select top 1 [received_date] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5),101) as [Requeue Log Response Date 5],

(select top 1 [Received_By] from 
    (select ROW_NUMBER() OVER (ORDER BY  Send_Back_Date ASC) AS ROWNUMBERS, * from [pl_Rework]
	where fk_application_information_id = ap.pk_id and [Log_Type] = 'Requeue')x 
where x.ROWNUMBERS=5) as [Requeue Log Response By 5]

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_customer_credit_bureau bru on bru.fk_customer_information_id = ci.pk_id 
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
	    Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_mis_master_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_pl_application_get_pl_mismasterreport '2019-01-01','2019-04-18'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_mis_master_report]
	@FromDate datetime,
	@ToDate datetime
AS

 SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
 --ap.ProductTypeName,
 (select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as ProductTypeName,
--ap.ApplicationNo,
	ap.Application_No as ApplicationNo,
--CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--ap.TypeApplicationName as TypeApplication,
(select top(1) m.[description] from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as TypeApplication,
--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,


--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPassportID,

--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,

--(select  top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,

--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,

--cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--CONVERT(VARCHAR(24),cc.DOB,106) as HolderPrimaryDOB,
CONVERT(VARCHAR(24),cus.DOB,106) as HolderPrimaryDOB,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where fk_application_information_id = ap.pk_id and BlackListCode<>null) as BlackList, fk_frm_black_list_code_id
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) 
   from frm_black_list_log lg inner join frm_black_list_code fr 
									  on lg.fk_frm_black_list_code_id = fr.pk_id and fr.is_active =1
where fk_application_information_id = ap.pk_id and fr.[description] <>null) as BlackList,

--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from pl_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as SelfEmployed,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--cc.BusinessType as CompanyType,
(select top(1) m.name from m_business_nature m
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],

--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,
--cc.CleanEB as CleanEB,
'' as CleanEB,
--cc.TypeOfContract,
(select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
--CONVERT(VARCHAR(24),cc.ContractStart,106) as [StartDate],
CONVERT(VARCHAR(24),cus.contract_start,106) as [StartDate],
--cc.ContractLength,
cus.contract_length as ContractLength,
--(SELECT TOP 1 VerifedOccupation FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedOccupation,
(SELECT TOP 1 vf.verifedOccupation FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedOccupation,

--(SELECT TOP 1 VerifiedPosition FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedPosition,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedPosition,

--cc.TradingArea,
(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

--	cc.ResidentialCity AS [Current Address City],
(select top(1) m.name from m_city m
						 where cus.fk_residential_city_id = m.pk_id and m.is_active =1 
						       and m.fk_group_id = 64) AS [Current Address City],
--	cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as  RepaymentType,

--	CreditBureauType as CIC,
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,
--	(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,

--CONVERT(varchar, CAST([CurrentUnsecuredOutstanding] AS MONEY), 1) AS [Current Unsecured Outstanding Off Us],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [Current Unsecured Outstanding Off Us],

--	CONVERT(varchar, CAST([CurrentTotalEMI] AS MONEY), 1) AS [Current Total EMI Off Us],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_emi,0)AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  AS [Current Total EMI Off Us],

--	CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS MonthlyIncomeDeclared,
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,

--CONVERT(varchar, CAST(IncomeEligible AS MONEY), 1) AS [TotalMonthlyVisBS],
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) [TotalMonthlyVisBS],
--CONVERT(varchar, CAST(FinalIncome AS MONEY), 1) AS [TotalFinalIncome],
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [TotalFinalIncome],
--ap.CardTypeName as CardType1,
'' as  CardType1,
--ap.CardTypeName2 as CardType2,
'' as CardType2,
--ap.CardProgramName as CardProgram,
'' as CardProgram,
--(CASE WHEN ap.HolderDepositedCurrency = 'VND' THEN 'VND' ELSE 'Non-VND' END) as CurrencyDepositedAmount,
(select top(1) m.name from cc_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,
--CONVERT(varchar, CAST([HolderCurrencyDepositedAmount] AS MONEY), 1) AS DespositedAmount,
CONVERT(varchar, CAST(pap.holder_currency_deposited_amount AS MONEY), 1) AS DespositedAmount,
 
--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) AS [PersonalLoanAmountApplied],
(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as [PersonalLoanAmountApplied],

--ccPL.PLFinalLoanAmountApproved,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr 
				where apr.fk_application_information_id = ap.pk_id)  AS PLFinalLoanAmountApproved,

--ccPL.LoanTenor,
pap.loan_tenor_applied AS LoanTenor,
--ccPL.InterestRateClassification,
(select top(1)m.name from m_interest_classification m
					 where  pap.fk_interest_classification_id = m.pk_id and m.is_active =1) as InterestRateClassification,
--ccPL.PLSuggestedInterestRate,
CONVERT(varchar, CAST(pap.suggested_interest_rate AS MONEY), 1) as PLSuggestedInterestRate,
--CONVERT(varchar, CAST(ccPL.SCB_PL_EMI AS MONEY), 1) AS [SCB PL EMI],
(select top(1)CONVERT(varchar, CAST(apr.scb_emi AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [SCB PL EMI],
--(case when ccPL.MRTACreditLife = 1 then 'YES' else 'NO' end) as [Credit Life],
(case when pap.is_mrta_credit_life = 1 then 'YES' else 'NO' end) as [Credit Life],
--ccPL.PaymentOption as [CreditLife_PaymentOption],
(select top(1) m.name from m_payment_option m
				where pap.fk_payment_option_id = m.pk_id and m.is_active=1) as  [CreditLife_PaymentOption],
--ccPL.NonFinance as [NonFinance_CREDIT],
(select pl.is_non_finance from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) as [NonFinance_CREDIT],
--CONVERT(varchar, CAST(ccPL.ApprovedSinglePremium AS MONEY), 1) AS [CreditLife_SinglePremium],
(select CONVERT(varchar, CAST(pl.approved_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id)  as [CreditLife_SinglePremium],
--CONVERT(varchar, CAST(ccPL.ApproveLoanAmountincludedCLPL AS MONEY), 1) AS [Approve Loan Amount Included CLPL],
(select CONVERT(varchar, CAST(pl.approve_loan_amount_included_clpl AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) as [Approve Loan Amount Included CLPL],
--CONVERT(varchar, CAST(ccPL.EMIIncludedSinglePremium AS MONEY), 1) AS [EMI(include single premium)],
(select CONVERT(varchar, CAST(pl.emi_included_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) as [EMI(include single premium)],
--CONVERT(varchar, CAST(ccPL.TotalEMIForPL AS MONEY), 1) AS [TotalEMIForPL],
(select top(1)CONVERT(varchar, CAST(apr.total_emi AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [TotalEMIForPL],
--CONVERT(varchar, CAST(ccPL.TotalDSRForPL AS MONEY), 1) AS [TotalDSRForPL],
(select top(1)CONVERT(varchar, CAST(apr.total_dsr AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [TotalDSRForPL],
--CONVERT(varchar, CAST(ccPL.MUE_PL AS MONEY), 1) AS [MUE_PL],
(select top(1)CONVERT(varchar, CAST(apr.mue AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [MUE_PL],
--CONVERT(varchar, CAST(ccPL.PLDTI AS MONEY), 1) AS [PLDTI],
(select top(1)CONVERT(varchar, CAST(apr.dti AS MONEY), 1) from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [PLDTI],
--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS InitialLimit,
(select top(1) CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1) ) AS InitialLimit,
--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS FinalApprovedLimit,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS FinalApprovedLimit,
--ccPl.PL_FinalApprovalStatus as [PL-DECISION-STATUS],
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [PL-DECISION-STATUS],
--(case when PL_RejectReasonID is not null and PL_RejectReasonID<>''  then PL_RejectReasonID else PL_CancelReasonID end) as [PL-Rejected_Or_Cancelled_Reason],
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) 
				 and (m.name <> '' or m.name is not null)) as  [PL-Rejected_Or_Cancelled_Reason],

--ccPL.DeviationLevelPL AS [PL Deviation Level],
(select top(1)m.name from pl_approval_information app inner join m_deviation_level m
						on app.fk_deviation_level_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id) as [PL Deviation Level],
--ccPL.PL_DeviationCodeID AS [PL Deviation Code],

(select top(1)m.name from pl_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id) as [PL Deviation Code],
--(select top 1 Remark from CCRemark where fk_application_information_id = ap.pk_id and ProductTypeName='PN' order by Created_Date) as [Remark-PL],
(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from pl_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as [Remark-PL],

--FinalApprovalStatus as CC_DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as CC_DECISION_STATUS,
--ccPL.DeviationLevelCC AS [CC Deviation Level],
''as [CC Deviation Level],
--ap.DeviationCodeID AS [CC Deviation Code],
(select top(1)m.name from pl_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [CC Deviation Code],
--(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as CC_Rejected_Or_Cancelled_Reason,
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) and (m.name <> '' or m.name is not null)) as  CC_Rejected_Or_Cancelled_Reason,

--(select top 1 Remark from CCRemark where fk_application_information_id = ap.pk_id and ProductTypeName='CC' order by Created_Date) as CC_Remark,
(select top 1 x.remark from 
		(select ROW_NUMBER() OVER (ORDER BY  dis.created_date ASC) AS ROWNUMBERS,* from cc_disbursement_condition dis
					where dis.fk_application_information_id = ap.pk_id)x
		where x.ROWNUMBERS = 1) as CC_Remark,

--(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by ActionDate desc) as Underwriter,
(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by action_date desc) as Underwriter,

--(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action]  in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by ActionDate desc) as Approver,
(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by action_date desc) as Approver,

--CONVERT(VARCHAR(24),DecisionDate,106) as CC_Final_DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from cc_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as CC_Final_DecisionDate,

--(SELECT TOP 1 [Level] FROM [CCCriteria] cr WHERE cr.[ApplicationNo] = ap.[ApplicationNo] ORDER BY cr.[Level] DESC ) as LevelName,
(SELECT TOP 1 m.[description] FROM [pl_criteria] cr inner join m_deviation_level m
													on cr.[fk_level_id] = m.pk_id and m.is_active =1
					WHERE cr.fk_application_information_id = ap.pk_id ORDER BY m.name DESC ) as LevelName,

--ap.FinalMUEAtSCB,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.mue,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as FinalMUEAtSCB,

--MUE_CC,
CONVERT(varchar, CAST(Isnull('0',0) AS MONEY), 1)  as MUE_CC,

--CONVERT(varchar, CAST([FinalTotalEMI] AS MONEY), 1) AS TotalEMI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_emi,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS  TotalEMI,
--FinalTotalDSR as [TotalDSR %],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_dsr,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [TotalDSR %],
--FinalDTI as DTI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.dti,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DTI,
--FinalLTV as TotalLTV,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.ltv,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as TotalLTV,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentStatus,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--PIDOfSaleStaff as SaleCode,
ap.sale_staff_bank_id as SaleCode,
--	ARMCode,
ap.arm_code as ARMCode,
--	ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--	LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,

--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,
--d.DisbursalStatus,,
'' as DisbursalStatus,
--CONVERT(VARCHAR(24),d.DisbursedDate,106) as DisbursedDate,
'' as DisbursedDate,
--d.LoanAccountNo,
'' as LoanAccountNo,
--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where fk_application_information_id = ap.pk_id and (Action='OSSendBack')) as Pending_OSSendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log 
where fk_application_information_id = ap.pk_id and Action='OSSendBack') as Pending_OSSendback,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as Pending_CISendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log 
where fk_application_information_id = ap.pk_id and Action like 'CISendBack%') as Pending_CISendback,

--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no AS MobilePhone,
--cc.PermAddress as CustomerAddress,
cus.permanent_address AS CustomerAddress,
--ccPL.LoanPurpose,
'' as LoanPurpose,
-----------1
--(select FullName from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=1) as SubCardFullName1,

(select Full_Name from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as SubCardFullName1,

--CONVERT(VARCHAR(24), (select DOB from 
--    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
--     from cc_subcard_application scard
--		where fk_application_information_id = ap.pk_id)x 
--where x.ROWNUMBERS=1),106) as SubCardDOB1,	
CONVERT(VARCHAR(24), (select DOB from 
    (select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
     from cc_subcard_application scard
		where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1),106) as SubCardDOB1,	

(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id =(select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=1)) as SubCardHolderID1,

(select cid.identification_no from customer_identification cid inner join m_identification_type m
													on cid.fk_m_identification_type_id = m.pk_id and m.is_active =1
				
where  m.name ='ID' and cid.fk_customer_information_id = (select x.fk_customer_information_id from 
													(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * 
													from cc_subcard_application scard
													where fk_application_information_id = ap.pk_id)x 
												where x.ROWNUMBERS=1)) as SubCardHolderPassport1,

(select RelationshipWithPrimary from 
    (select ROW_NUMBER() OVER (ORDER BY  scard.Created_Date ASC) AS ROWNUMBERS, md.name as  RelationshipWithPrimary
     from cc_subcard_application scard inner join m_definition_type md on 
												 md.pk_id = scard.fk_relationship_with_primary_id 
												 and md.is_active =1  and md.fk_group_id = 60
		where scard.fk_application_information_id = ap.pk_id)x 

where x.ROWNUMBERS=1) as RelationshipWithPrimary1

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_nsg_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_nsg_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--ap.TypeApplicationName as TypeApplication,
 pap.type_of_application as TypeApplication,
--ap.ApplicationNo,
ap.application_no as ApplicationNo,
--ap.CardTypeName as CardType,
'' as CardType,
--ap.CardTypeName2 as CardType2,
'' as CardType2,
--ap.CardProgramName as CardProgram,
'' as CardProgram,
--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as  DECISION_STATUS,
--(
--select top 1 u.FullName from dbo.AppActionLog a left join dbo.LoginUser u on u.PeoplewiseId=a.ActionBy
--where a.ApplicationNo = ap.ApplicationNo and a.Action='CI_NSG' order by ActionDate desc
--) User_SelectNSG,
'' as  User_SelectNSG,
--(
--select top 1 CONVERT(VARCHAR(24),ActionDate,106) from dbo.AppActionLog a 
--where a.ApplicationNo = ap.ApplicationNo and a.Action='CI_NSG' order by ActionDate desc
--)ActionDateNSG,

(select top 1 CONVERT(VARCHAR(24),Action_Date,106) from dbo.application_action_log a 
where a.fk_application_information_id = ap.pk_id and  a.Action='CI_NSG' order by action_date desc)ActionDateNSG,

--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no AS  MobilePhone,
--cc.TradingArea as TradingCity,
(select top(1) m.name from pl_customer_information cus join m_trading_area m on cus.fk_trading_area_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as TradingCity,
--cc.TypePermAddress as TypePermAddress,

(select top(1) m.name from m_definition_type m
		  where cus.fk_permanent_address_type_id= m.pk_id and m.is_active =1 and m.fk_group_id = 39) as TypePermAddress,
--cc.CompanyName as CompanyName,
(select top(1) co.company_name from pl_company_information co
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyName,
--cc.CompanyCity as CompanyCity,
(select top(1) m.name from pl_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyCity,
--cc.BusinessType as CompanyType,
(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyType,
--cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as  RLSCompanyCode,

--cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--cc.IsBankStaff as Staff,
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As  Staff,
--cc.DOB as PrimaryCardHolderDOB,
cus.dob as PrimaryCardHolderDOB,
--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where ci.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--(select IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where ci.fk_customer_information_id = ci.pk_id) as  PrimaryCardHolderPreviousID,
--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as Nationality,
--(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
pap.remark    as Remark,
--(select top 1 Remark from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleVerifierRemark
(select top 1 Remark from verification_form v
		where fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1) as TeleVerifierRemark

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_nsg_report_ext]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_nsg_report_ext]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--ap.ReceivedDate,
ap.Received_Date as ReceivedDate,
--ap.TypeApplicationName as TypeApplication,
 pap.type_of_application  as TypeApplication,
--ap.ApplicationNo,
 ap.Application_No  as ApplicationNo,
--ap.CardTypeName as CardType,
'' as CardType,
--ap.CardTypeName2 as CardType2,
'' as CardType2,
--ap.CardProgramName as CardProgram,
'' as CardProgram,
--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as DECISION_STATUS,
--ap.FinalLimitApproved,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)AS FinalLimitApproved,
--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--pl.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,
--pl.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--pl.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as MobilePhone,
--pl.TradingArea as TradingCity,
(select top(1) m.name from m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as  TradingCity,
--pl.TypePermAddress as TypePermAddress,
(select top(1) m.name from m_definition_type m
		  where cus.fk_permanent_address_type_id= m.pk_id and m.is_active =1 and m.fk_group_id = 39) as TypePermAddress,
--pl.CompanyName as CompanyName,
(select top(1) co.company_name from pl_company_information co
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyName,
--pl.CompanyCity as CompanyCity,
(select top(1) m.name from pl_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyCity,
--pl.BusinessType as CompanyType,
(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyType,
--pl.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as  RLSCompanyCode,

--pl.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--pl.IsBankStaff as Staff,
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],

cus.dob as PrimaryCardHolderDOB,

--(select IdentificationNo from plIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where ci.fk_customer_information_id = ci.pk_id) as plIdentification,

--(select IdentificationNo from plIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) ci.identification_no
  from customer_identification ci join  [m_identification_type] m 
									 on ci.fk_m_identification_type_id = m.pk_id and m.name ='Previous'
  where ci.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousID,
--pl.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as Nationality,
--(select top 1 Remark from plRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
pap.remark as Remark,
--(select top 1 Remark from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleVerifierRemark,
(select top 1 Remark from verification_form v
		where fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1) as TeleVerifierRemark,

CONVERT(VARCHAR(24), (
			select top 1 l.action_date from dbo.application_action_log l 
			where (l.fk_application_information_id = ap.pk_id and l.[Action] = m.name) order by l.action_date desc
		), 113) ActionTime, -- action time of current status

--		CONVERT(VARCHAR(24), (
--			select top 1 l.ActionDate from dbo.AppActionLog l 
--			where (l.ApplicationNo = ap.ApplicationNo and l.[Action] in('CIApproved','CIApprovedPL','CIApprovedpl','CIApprovedBD','CIRejected','CIRejectedBD')) order by l.ActionDate desc
--		), 113) ActionTime_Approved_Reject_Status -- action time of approved or rejected status

CONVERT(VARCHAR(24), (
			select top 1 l.action_date from dbo.application_action_log l 
			where (l.fk_application_information_id = ap.pk_id and l.[Action] in('CIApproved','CIApprovedPL','CIApprovedpl','CIApprovedBD','CIRejected','CIRejectedBD')) order by l.action_date desc
		), 113) as ActionTime_Approved_Reject_Status

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join m_status m on ap.fk_m_status_id = m.pk_id and m.is_active =1
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_office_phone_database]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_office_phone_database]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT distinct
	CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
    ap.application_no as ApplicationNo,
--	ap.[Status],
    m.name as [Status],
--	cc.RLSCompanyCode as [Code RLS],
	(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Code RLS],
--	cc.BusinessType as CompanyType,
	(select top(1)m.name from pl_company_information co  inner join m_company_type m
																	  on co.fk_m_company_type_id = m.pk_id and m.is_active =1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CompanyType,
--	cc.CompanyName as CompanyName,
	(select top(1)co.company_name from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CompanyName,
--	cc.CompanyGenericCode as [Company name -Generic code],
(select top(1)co.company_generic_code from cc_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company name -Generic code],
--	cc.CompanyAddress as CompanyAddress,
(select top(1)co.company_address from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CompanyAddress,
--	cc.CompanyWard as CompanyWard,
(select top(1)co.company_ward from pl_company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyWard,
--	cc.CompanyDistrict as CompanyDistrict,
(select top(1)co.company_district from pl_company_information co
				where co.fk_application_information_id = ap.pk_id ) as CompanyDistrict,
--	cc.CompanyCity as CompanyCity,
(select top(1)m.name from pl_company_information co inner join m_city m on
																	co.fk_company_city_id = m.pk_id and m.is_active =1
				where co.fk_application_information_id = ap.pk_id ) as CompanyCity,
--	vp.ContactNo as CompanyPhone,
	vp.contact_no as CompanyPhone,
--	(CASE WHEN vp.IsSourceInternal = 1 THEN 'Yes' ELSE 'No' END) AS [Source Internal],
--	(CASE WHEN vp.IsYellowPage = 1 THEN 'Yes' ELSE 'No' END) AS [Yellow Page],
--	(CASE WHEN vp.IsOperator = 1 THEN 'Yes' ELSE 'No' END) AS [Operator],
--	(CASE WHEN vp.IsWebsite = 1 THEN 'Yes' ELSE 'No' END) AS [Website],
--	(CASE WHEN vp.IsAbleToContact = 1 THEN 'Yes' ELSE 'No' END) AS [Able To Contact],

	(CASE WHEN vp.is_source_internal = 1 THEN 'Yes' ELSE 'No' END) AS [Source Internal],
	(CASE WHEN vp.is_yellow_page = 1 THEN 'Yes' ELSE 'No' END) AS [Yellow Page],
	(CASE WHEN vp.is_operator = 1 THEN 'Yes' ELSE 'No' END) AS [Operator],
	(CASE WHEN vp.is_website = 1 THEN 'Yes' ELSE 'No' END) AS [Website],
	(CASE WHEN vp.Is_Able_To_Contact = 1 THEN 'Yes' ELSE 'No' END) AS [Able To Contact],

--	vp.WhoAnswered AS [Answered The Call],
   vp.who_answered as [Answered The Call],
--	CONVERT(VARCHAR(24),vp.CheckingDate,106) as [Checking Date],
  CONVERT(VARCHAR(24),vp.checking_date,106) as [Checking Date],
--	vf.Remark AS [Tele-remark]
	vf.remark as [Tele-remark]

	FROM pl_verification_phone vp
	inner join pl_application cap on vp.fk_application_information_id = cap.fk_application_information_id
	inner join application_information ap on ap.pk_id = cap.fk_application_information_id
	inner join verification_form vf on vf.fk_application_information_id = cap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = cap.fk_application_information_id 
	inner join m_status m on m.pk_id = ap.fk_m_status_id and m.is_active = 1
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	and m.name in ('CIApproved','CIApprovedPL','CIApprovedCC','CIApprovedBD','LODisbursed')
	and vp.phone_type = 'Office Phone'
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_pending_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_pending_reports]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,

	ap.application_no as [Application No],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
	--(SELECT TOP 1 [ActionBy] FROM [AppActionLog] WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate) AS CreatedBy,
	--(
	--	SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID 
	--	WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
	--) AS CreatedName,
'' as CreatedName,
 cus.Full_Name as [Customer Name],

(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id
							 and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of ID],

(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id 
							and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Customer ID],

 CONVERT(VARCHAR(10), cus.DOB, 101) as [DOB],

(select top(1) m.name from m_definition_type m
					where cus.fk_operation_self_employed_id = m.pk_id 
					and m.is_active=1 and m.fk_group_id = 69) as SelfEmployed,

(select top(1)m.name from cc_company_information co  inner join m_position m
																  on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as JobTitle,

 co.company_name as  [Company Name],

 co.company_code as CompanyCode,

(select top(1) m.name from cc_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_cc_customer_information_id = cus.pk_id) as [Company Type],

(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as [Loan_Amt_Applied],
--	ccPL.LoanPurpose,
(select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as LoanPurpose,

--	ap.ChannelD,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as ChannelD,

--	ap.LocationBranchName,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as LocationBranchName,

--	ap.ARMCode,
ap.arm_code as  ARMCode,
--	cc.PaymentType as PaymentMethod,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,

--	ap.CardProgramName as Program,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as Program,
--	CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,
--	FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from cc_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as DECISION_STATUS,

--	CONVERT(varchar, CAST(ccPL.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr 
				where apr.fk_application_information_id = ap.pk_id) as [Loan_Amt_Approved],
--	ccPL.LoanTenor AS [Tenor (month)],
pap.loan_tenor_applied as [Tenor (month)],
--	Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
'' as Interest,
--	dis.DisbursalStatus,
(select top(1) m.name from m_status m
				     where dis.fk_status_id = m.pk_id) as DisbursalStatus,

--	CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
CONVERT(VARCHAR(24),dis.disbursed_date,106) as DisbursedDate,
--	dis.LoanAccountNo,
dis.loan_account_number as  LoanAccountNo,
--	ap.Status as CurrentStatus,
(select top(1) m.name from m_status m
				     where ap.fk_m_status_id = m.pk_id) asCurrentStatus,

--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--	(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
--(Case when cus.is_vip_application = 1 then 'Yes' else 'No' end) as IsVipApp,

--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where fk_application_information_id =ap.pk_id and (Action='OSSendBack')) as Pending_OSSendback,
--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where fk_application_information_id =ap.pk_id and (Action like 'CISendBack%')) as Pending_CISendback,
--	(select COUNT(*) from AppActionLog where fk_application_information_id =ap.pk_id and [Action]='OSSendBack') as [Times sendback by OS],
--	(select COUNT(*) from AppActionLog where fk_application_information_id =ap.pk_id and Action in ('CISendBackSC', 'CISendBackCI', 'CISendBackOS')) as [Times sendback by CI],
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id =ap.pk_id and (Action='OSSendBack')) as Pending_OSSendback,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id =ap.pk_id and (Action like 'CISendBack%')) as Pending_CISendback,

(select COUNT(*) from application_action_log where fk_application_information_id =ap.pk_id and [Action]='OSSendBack') as [Times sendback by OS],

(select COUNT(*) from application_action_log where fk_application_information_id =ap.pk_id and Action in ('CISendBackSC', 'CISendBackCI', 'CISendBackOS')) as [Times sendback by CI],

--	--------
--	ap.SCRemark as [SC Remark],
pap.sc_remark as [SC Remark],
--	ap.OpsRemark as [Ops Remark],
pap.ops_remark as [Ops Remark],
--	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=1) as [First Time SendBack Date],

	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=1) as [First Time SendBack Department],

	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=1)) as [First Time SendBack Reason],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=1) as [First Time SendBack Remarks],

	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=1) as [First Time Revert by Sales Date],

	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=2) as [Second Time SendBack Date],

	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=2) as [Second Time SendBack Department],

	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=2)) as [Second Time SendBack Reason],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=2) as [Second Time SendBack Remarks],

	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=2) as [Second Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=3) as [Third Time SendBack Date],

	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=3) as [Third Time SendBack Department],

	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=3)) as [Third Time SendBack Reason],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=3) as [Third Time SendBack Remarks],

	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=3) as [Third Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=4) as [Fourth Time SendBack Date],

	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=4) as [Fourth Time SendBack Department],

	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=4)) as [Fourth Time SendBack Reason],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=4) as [Fourth Time SendBack Remarks],

	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=4) as [Fourth Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=5) as [Fifth Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=5) as [Fifth Time SendBack Department],

	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=5)) as [Fifth Time SendBack Reason],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=5) as [Fifth Time SendBack Remarks],

	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Pending')x 
	where x.ROWNUMBERS=5) as [Fifth Time Revert by Sales Date],
--	---------
--	ap.PIDOfSaleStaff as SalesCode,
ap.sale_staff_bank_id as SalesCode,

--	cc.PrimaryPhoneNo as MobilePhone,
cus.primary_phone_no as MobilePhone,

--	(CASE WHEN cc.BillingAddress = 'Company address' THEN (cc.CompanyName + ' - ' + cc.CompanyAddress + ' - ' + cc.CompanyWard + ' - ' + cc.CompanyDistrict + ' - ' + cc.CompanyCity) ELSE
--		(CASE WHEN cc.BillingAddress = 'Permanent address' THEN (cc.PermAddress + ' - ' + cc.PermWard + ' - ' + cc.PermDistrict + ' - ' + cc.PermCity) ELSE
--		  ((CASE WHEN cc.BillingAddress = 'Residential address' THEN (cc.ResidentialAddress + ' - ' + cc.ResidentialWard + ' - ' + cc.ResidentialDistrict + ' - ' + cc.ResidentialCity) ELSE '' END)) END) END) AS [Customer Address],
(select top(1) (CASE WHEN cus.billing_address = 'Company address' 
	               THEN (co.company_name + ' - ' + co.Company_Address + ' - ' + co.company_ward + ' - ' + co.company_district + ' - ' + 
					(select top(1) m1.name from m_city m1 where co.fk_company_city_id = m1.pk_id and m1.is_active =1)) 
			ELSE
	          (CASE WHEN cus.billing_address = 'Permanent address' 
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))  AS [Customer Address],


--	ccPL.Remark,
pap.remark as Remark,

--	(CASE WHEN ccPL.MRTACreditLife = 1 THEN 'Yes' ELSE 'No' END) AS [Credit Life (Yes/No)],
(CASE WHEN pap.is_mrta_credit_life = 1 THEN 'Yes' ELSE 'No' END) AS [Credit Life (Yes/No)],
--	ccPL.PaymentOption AS [Credit Life Payment Option],
(select top(1) m.name from m_payment_option m
				where pap.fk_payment_option_id = m.pk_id and m.is_active=1) as [Credit Life Payment Option],

--	ccPL.NonFinance,
(select pl.is_non_finance from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) as NonFinance,

--	CONVERT(varchar, CAST(ccPl.ApprovedSinglePremium AS MONEY), 1) AS [Credit Life Single Premium],
(select CONVERT(varchar, CAST(pl.approved_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) AS [Credit Life Single Premium],

--	CONVERT(varchar, CAST(ccPl.ApproveLoanAmountincludedCLPL AS MONEY), 1) AS [Credit Life Sum Assured],
(select CONVERT(varchar, CAST(pl.approve_loan_amount_included_clpl AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) AS [Credit Life Single Premium],

--	ccPL.ApplicationNumber,
pap.application_number as ApplicationNumber,
--	CONVERT(varchar, CAST(ccPL.EMIIncludedSinglePremium AS MONEY), 1) AS [EMI Included Single Premium],
(select CONVERT(varchar, CAST(pl.emi_included_single_premium AS MONEY), 1) from pl_approval_information pl
						  where pap.fk_application_information_id = pl.fk_application_information_id) AS [EMI Included Single Premium],

--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where fk_application_information_id =ap.pk_id and (Action='LOModified')) as [LO Remodified],
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) 
  from application_action_log
 where fk_application_information_id =ap.pk_id and (Action='LOModified')) as [LO Remodified],

--	cc.RLSCompanyCode as [Company Code RLS],
co.company_code_rls as [Company Code RLS],
--	ap.TypeApplicationName,
pap.type_of_application as TypeApplicationName,

--	(SELECT TOP 1 Remark FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo and IsTeleVerify = 1) AS [Remark Tele-Verifier],
(SELECT TOP 1 Remark 
   FROM Verification_Form vf 
  WHERE vf.fk_application_information_id = ap.pk_id and is_telephone_verify = 1) AS [Remark Tele-Verifier],

--	---------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele First Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele First Time SendBack Department],
	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=1)) as [Tele First Time SendBack Reason],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele First Time SendBack Remarks],
	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele First Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Second Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Second Time SendBack Department],
	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=2)) as [Tele Second Time SendBack Reason],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Second Time SendBack Remarks],
	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Second Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Third Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Third Time SendBack Department],
	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=3)) as [Tele Third Time SendBack Reason],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Third Time SendBack Remarks],
	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Third Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Fourth Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Fourth Time SendBack Department],
	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=4)) as [Tele Fourth Time SendBack Reason],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Fourth Time SendBack Remarks],
	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Fourth Time Revert by Sales Date],
	--------
	(select top 1 CONVERT(VARCHAR(10), send_back_date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Fifth Time SendBack Date],
	(select top 1 User_Type from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Fifth Time SendBack Department],
	(select [Name] from m_reason where  pk_id = (select top 1 [pk_id] from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=5)) as [Tele Fifth Time SendBack Reason],
	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Fifth Time SendBack Remarks],
	(select top 1 CONVERT(VARCHAR(10), Received_Date, 101) from 
		(select ROW_NUMBER() OVER (ORDER BY  Created_Date ASC) AS ROWNUMBERS, * from [pl_rework]
		where fk_application_information_id =ap.pk_id and [log_type] = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Fifth Time Revert by Sales Date],
--	--------
--	cc.EmailAddress1,
cus.email_address_1 as EmailAddress1,
--	cc.EmailAddress2,
cus.email_address_2 as EmailAddress2,
--	cc.EmailAddress3,
cus.email_address_3 as EmailAddress3,
--	cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,

--	ccPL.PL_DisbursementScenarioId AS [Pre-disbursement Condition Scenario],
(select top(1)m.scenario_en from  pl_disbursement_condition dis inner join m_disbursal_scenario m
								on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement Condition Scenario],

--ccPL.PL_DisbursementScenarioText AS [Pre-disbursement Condition],
(select top(1)m.[description] from  pl_disbursement_condition dis inner join m_disbursal_scenario m
								on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement Condition],

--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as [Application sign date]
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [Application sign date]


FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	LEFT JOIN pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	
WHERE 
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
end
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_pending_reports_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_pending_reports_sales]
	@FromDate datetime,
	@ToDate datetime
AS
	--select pap.* into #tbl_PLApplication 
	--from [pl_application] pap with (nolock) 
	--inner join application_information ap with (nolock) 
	--								   on pap.fk_application_information_id = ap.pk_id
	--WHERE ap.Received_Date >= @FromDate and ap.Received_Date <= @ToDate
	
	---select a.* into #tbl_CCPLApplication from CCPLApplication a with (nolock) inner join #tbl_PLApplication b on b.ApplicationNo = a.CCApplicationNo

	--select cc.* into #tbl_PLCustomer 
	--from pl_customer_information cc with (nolock) 
	--inner join #tbl_PLApplication ap on ap.fk_application_information_id = cc.fk_application_information_id

	--select cc.* into #tbl_CCIdentification 
	--from customer_identification cc with (nolock) 
	--inner join #tbl_PLApplication ap on ap.fk_application_information_id = cc.fk_application_information_id

	--select a.* into #tbl_PLRework_Pending 
	--from pl_rework a with (nolock) 
	--where [log_type] = 'Pending'
	
	--select a.* into pl_rework 
	--from pl_rework a with (nolock) 
	--where [log_type] = 'Tele'

	--select a.* into application_action_log 
	--from application_action_log a with (nolock) 
	

	--select a.* into #tbl_CCRemark 
	--from [CC_Remark] a with (nolock) 
	--inner join #tbl_PLApplication b on a.fk_application_information_id = b .fk_application_information_id
--	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
	(CASE WHEN ap.Is_Vip = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
--	ap.ApplicationNo as [Application No],
	ap.Application_No as [Application No],
--	ap.SpecialCode as [Special Code],
	pap.special_code as [Special Code],
--	CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--	ap.ProductTypeName as [Product Type],
	(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--	ap.TypeApplicationName as [Application Type],
	(select top(1) m.[description] from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Application Type],
--	ap.CardProgramName as [Card Program],
	(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],

	--ap.ProgramCodeName as [Program Code],
	(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

	--ap.CardTypeName as [Card Type],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type],

	--ap.CardTypeName2 as [Card Type 2],
	(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Type 2],

	--CustomerSegment as [Customer Segment],
	
	(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--	BankRelationship as [Customer Relation],
	(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

	(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ci..Channe_lD as Channel,
	(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,

	--ap.LocationBranchName as [Branch Location],
	(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],
	
	--ap.ARMCode as [ARM Code],
	ap.arm_code as [ARM Code],

	--ap.IsTwoCardType as [IsTwoCardType],
	'' as [IsTwoCardType],

	--cc.PaymentType as [Payment Type],
	(select top(1) m.name from m_payment_type m 
			     where cus.fk_payment_type_id = m.pk_id) as [Payment Type],

	--cc.FullName as [Primary Card Holder Name],
	ci.full_name as [Primary Card Holder Name],

--	CONVERT(VARCHAR(10), cc.DOB, 101) as [Primary Card Holder DOB],
	CONVERT(VARCHAR(10), cus.DOB, 101) as [Primary Card Holder DOB],
--	cc.Nationality as [Primary Card Holder Nationality],
	(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as Nationality,

--	cc.TypeEmployment as [Type Employment],
	(select top(1)m.name from pl_company_information co inner join m_employment_type m
						on co.fk_m_employment_type_id = m.pk_id
					where co.fk_application_information_id = ap.pk_id) as [Type Employment],

--	cc.OperationSelfEmployed as [Employment Type],
(select top(1) m.name from pl_customer_information cus join m_position m on cus.fk_customer_information_id = m.pk_id
				where cus.fk_application_information_id = ap.pk_id) as [Employment Type],

	--cc.CurrentPosition as [Current Position],
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as [Current Position],
	--cc.Occupation, fk_occupation_id
	(select top(1) m.name from m_occupation m
						 where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	--cc.VerifiedPosition as [Verified Position], fk_verified_position_id ???
	(select top(1) m.name from  m_occupation m
						 where cus.fk_verified_position_id = m.pk_id and m.is_active =1) as [Verified Position],

	--cc.OccupationVerified as [Verified Occupation],
	(select top(1) m.name from pl_customer_information cin join m_definition_type m on cin.fk_occupation_type_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
		  where cin.fk_application_information_id = ap.pk_id) as [Verified Occupation],

--	cc.CompanyName as [Company Name],
	(select top(1) m.company_name from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as  [Company Name],

	--cc.CompanyCode as [Company Code],
	(select top(1) mc.name from m_company_list cl inner join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = ci.fk_company_information_id) as [Company Code],

	--cc.RLSCompanyCode as [Company Code RLS],
	(select top(1) co.name from  m_company_list mc join m_company_code co on mc.fk_m_company_code_id = co.pk_id
				where mc.pk_id = ci.fk_company_information_id)  as [Company Code RLS],

	--cc.BusinessType as [Company Type],
	(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyType,

	--cc.CompanyAddress as [Company Address],
	(select top(1) co.company_address from pl_company_information co
				where co.fk_application_information_id = ap.pk_id ) as [Company Address],

	--cc.CompanyPhone as [Company Office], ???
	(select top(1) m.company_phone from m_company_list m 
				where ci.fk_company_information_id = m.pk_id)  as [Company Office],

--	ap.CreditBureauType as [Bureau Type], 
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],

	--cc.IncomeType as [Income Type], pl_customer_income
	(select top(1)m.name from pl_customer_income cin inner join m_income_type m 
						  on cin.fk_m_income_type_id = m.pk_id
					where cin.fk_customer_information_id = cus.fk_customer_information_id)  as [Income Type],

	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--	ccPL.LoanTenor,
    pap.loan_tenor_applied as LoanTenor,
--	ccPL.InterestRateClassification,
	 
	 (select top(1)m.name from m_interest_classification m
					 where  pap.fk_interest_classification_id = m.pk_id and m.is_active =1) as InterestRateClassification,
--	ccPL.PLSuggestedInterestRate,
	 CONVERT(varchar, CAST(pap.suggested_interest_rate AS MONEY), 1) as PLSuggestedInterestRate,
--	ccPL.PLFinalLoanAmountApproved,
	(select top(1) CONVERT(varchar, CAST(inf.final_loan_amount_approved AS MONEY), 1) from pl_approval_information inf
				where inf.fk_application_information_id = ap.pk_id) AS PLFinalLoanAmountApproved,

--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from cc_application ca
				where ca.fk_application_information_id = ap.pk_id) AS [Initial Limit],

--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Approved Limit],

--	ccPL.PL_FinalApprovalStatus,
	(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as PL_FinalApprovalStatus,
--	FinalApprovalStatus as [CC Final Approval Status],
	(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as [Final Approval Status],

--	ccPL.PL_DeviationCodeID as PL_DeviationCode,
	''as  PL_DeviationCode,
--	ap.DeviationCodeID as CC_DeviationCode,
	(select top(1)m.name from pl_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	(select LeveLBD from DeviationLevel where ccPL.DeviationLevelPL = LevelPL and LevelCC=ap.DeviationLevelCC and [Status]='Active') as BD_DeviationCode,
	'' as BD_DeviationCode,
	
--	CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

--	(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	(select top(1)m.name from pl_approval_information app inner join m_deviation_code m
						on app.fk_deviation_code_id = m.pk_id
					where app.fk_application_information_id = ap.pk_id)  as [Deviation Code],

--	ap.[Status] as [Current Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--	ap.EOpsTxnRefNo,
	ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [HardCopyAppDate],
--	ccPL.LoanPurpose,
	 (select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				         where apr.fk_application_information_id = ap.pk_id) as LoanPurpose,
--	(select count(1) from CCSubCard sc where sc.re.fk_application_information_id = pap.fk_application_information_id) as SupplementaryCardNo,
	(select count(*) from cc_subcard_application sc
					 where sc.fk_application_information_id = ap.pk_id) as SupplementaryCardNo,

--	(select COUNT(*) from application_action_log where re.fk_application_information_id = pap.fk_application_information_id and [Action]='OSSendBack') as [Times sendback by OS],
  (select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by OS],

--	(select COUNT(*) from application_action_log where re.fk_application_information_id = pap.fk_application_information_id and Action='CISendBackSC') as [Times sendback by CI to SC],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'OSSendBack') as [Times sendback by CI to SC],

--	(select COUNT(*) from application_action_log where re.fk_application_information_id = pap.fk_application_information_id and Action='CISendBackOS') as [Times sendback by CI to OS],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackOS') as [Times sendback by CI to OS],

--	(select COUNT(*) from application_action_log where re.fk_application_information_id = pap.fk_application_information_id and Action='CISendBackCI') as [Times sendback by CI to CI],
	(select COUNT(*)from application_action_log l
				where l.fk_application_information_id = ap.pk_id and l.[action] = 'CISendBackCI') as [Times sendback by CI to CI],

--	---------------------------------------
--	(select Scenario from DisbursalScenario where pk_id = CCPL.PL_DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
--	ap.DisbursementScenarioText as [PL Pre-disbursement condition],
(select top(1)m.scenario_vn from  cc_disbursement_condition dis inner join m_disbursal_scenario m
					on dis.fk_disbursal_scenario_id = m.pk_id and m.is_active = 1
					where dis.fk_application_information_id = ap.pk_id) as [Pre-disbursement condition],

--	---------------------------------------
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=1) as [PL Remark 1],
	'' as  [CC Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=2) as [PL Remark 2],
	'' as  [CC Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='PN')x 
--	where x.ROWNUMBERS=3) as [PL Remark 3],
	'' as  [CC Remark 3],
--	-----------------------------------
--	(select Scenario from DisbursalScenario where pk_id = ap.DisbursementScenarioId) as [CC Pre-disbursement condition Scenario],
--	ap.DisbursementScenarioText as [CC Pre-disbursement condition],
	''  as [CC Pre-disbursement condition],

--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=1) as [CC Remark 1],
	''  as [CC Remark 1],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=2) as [CC Remark 2],
	'' as  [CC Remark 2],
--	(select top 1 Remark from 
--		(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
--		where re.fk_application_information_id = pap.fk_application_information_id and ProductTypeName='CC')x 
--	where x.ROWNUMBERS=3) as [CC Remark 3],
	'' as [CC Remark 3],
--	-----------------------------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  
		   from pl_rework  re
		  where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x
	where x.ROWNUMBERS=1) as [Pending Log Remark 1],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Response By 1],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Response By 2],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Response By 3],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Response By 4],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'pending')x 
	where x.ROWNUMBERS=5) as [Pending Log Response By 5],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  re.send_back_date ASC) AS ROWNUMBERS, re.*  from pl_rework  re
		where re.fk_application_information_id = pap.fk_application_information_id and re.log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	------------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark 1],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Response By 1],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark 2],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Response By 2],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark 3],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Response By 3],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark 4],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Response By 4],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	----------
	(select [Name] from m_reason m where pk_id = (select top 1 x.pk_id from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],

	(select top 1 Remark from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark 5],

	CONVERT(VARCHAR(24), (select top 1 x.Send_Back_Date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],

	(select top 1 x.send_back_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],

	(select top 1 x.remark_response from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],

	CONVERT(VARCHAR(24), (select top 1 x.received_date from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],

	(select top 1 x.received_by from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Response By 5],

	(select top 1 x.user_type from 
		(select ROW_NUMBER() OVER (ORDER BY  send_back_date ASC) AS ROWNUMBERS, * from pl_rework
		where fk_application_information_id = pap.fk_application_information_id  and log_type = 'Tele')x 
	where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5]

	FROM 
	  pl_application pap 
	  inner join application_information ap on pap.fk_application_information_id = ap.pk_id
	  inner join pl_customer_information cus on pap.fk_application_information_id = cus.fk_application_information_id 
	  inner join customer_information ci on cus.fk_customer_information_id = ci.pk_id
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq

	--drop table #tbl_PLApplication
	--drop table #tbl_PLRework_Pending
	--drop table pl_rework
	--drop table #tbl_PLCustomer
	--drop table #tbl_CCIdentification
	--drop table application_action_log	
	--drop table #tbl_CCRemark
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_report_sale_pending]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_pl_application_get_report_sale_pending]
	@fDate datetime,
	@tDate datetime,	
	@limitedIncome int
AS
--BEGIN

--DECLARE @NewLineChar AS CHAR(2) SET @NewLineChar = CHAR(13) + CHAR(10)

--select 
--	ROW_NUMBER() over (order by ml.[ReceivedDate]) as Seq, 
--	ml.[ApplicationNo], 
--	(SELECT TOP 1 [ActionBy] FROM [AppActionLog] WHERE ApplicationNo = ml.ApplicationNo ORDER BY ActionDate) AS CreatedBy,
--	REPLACE(CONVERT(VARCHAR(11), ml.[ReceivedDate], 106), ' ', '/') as ReceivedDate,
--	c.[FullName],
--	c.[PassportID],
--	REPLACE(CONVERT(VARCHAR(11), c.[DOB], 106), ' ', '/') as DOB,
--	c.[CurrentPosition],
--	c.[CompanyName],
--	(case c.[Status] when 1 then 'Yes' else 'No' end) as BlackListCheck,
--	REPLACE(CONVERT(varchar, CAST(ml.[AmountRequest] as money), 1), '.00', '') as LoanAmtApplied,
--	ml.[Tenor],
--	ml.[LoanPurposeCode] as LoanPurpose,
--	sc.[Name] as Channel,
--	ct.[Name] as BranchLocation,
--	ml.[ARMCode],
--	pt.[Name] as PaymentMethod,
--	prt.[Name] as Programs,
--	pdt.[Name] as ProductType,
--	-- TotalIncome
--	REPLACE(CONVERT(varchar, CAST((case when c1.[TotalIncome] >= @limitedIncome then (ISNULL(c1.[TotalIncome],0) + ISNULL(c2.[TotalIncome],0) + ISNULL(c3.[TotalIncome],0)) else (0 + ISNULL(c2.[TotalIncome],0) + ISNULL(c3.[TotalIncome],0)) end) as money), 1), '.00', '') as TotalIncome,
--	a1.[Status] as DecisionStatusAIP,
--	REPLACE(CONVERT(varchar, CAST(a1.[LoanAmount] as money), 1), '.00', '') as LoanAmtApprovedAIP,
--	REPLACE(CONVERT(VARCHAR(11), a1.[DecisionDate], 106), ' ', '/') as FinalDecisionDateAIP,
--	REPLACE(CONVERT(VARCHAR(11), a2.[DecisionDate], 106), ' ', '/') as FinalDecisionDate,
--	a2.[Status] as DecisionStatus,
--	a2.[Level] as FinalLevel,
--	(case rr.[Name] when NULL then rc.[Name] else rr.[Name] end) as RejectCancelReason,
--	ml.[Remarks],
--	REPLACE(CONVERT(varchar, CAST(a2.[LoanAmount] as money), 1), '.00', '') as LoanAmtApproved,
--	a2.[Tenor] as FinalTenor,
--	(CONVERT(varchar, CAST(a2.[CommercialInterest] as money), 1) + '%') as Interest,		 
--	dis.[DisbursalStatus],
--	REPLACE(CONVERT(VARCHAR(11), dis.[DisbursedDate], 106), ' ', '/') as DisbursedDate,
--	dis.[LoanAccountNo],
--	stt.[StatusName] as CurrentStatus,
--	ml.[ProgramCode],
--	(case ml.[ExpectedLoan] when 1 then 'Yes' else 'No' end) as ExpressLoan,
--	(case ml.[OSSentBack] when 1 then 'Yes' else 'No' end) as PendingOSSendback,
--	(case ml.[CISentBack] when 1 then 'Yes' else 'No' end) as PendingCISendback,
--	(select count(*) from dbo.AppActionLog al where al.[ApplicationNo] = ml.[ApplicationNo] and al.[Action] = 'CISendBack') as TimesSendbackCI,
--	(select count(*) from dbo.AppActionLog al where al.[ApplicationNo] = ml.[ApplicationNo] and al.[Action] = 'OSSendBack') as TimesSendbackOS,
--	cs.[Name] as CustomerSegment,
--	pte1.[Name] as PropertyType_Purchased1,
--	pte2.[Name] as PropertyType_Purchased2,
--	pte3.[Name] as PropertyType_Purchased3,
--	pte4.[Name] as PropertyType_Purchased4,
--	pte5.[Name] as PropertyType_Purchased5,
--	pst1.[Name] as PropertyStatus_Purchased1,
--	pst2.[Name] as PropertyStatus_Purchased2,
--	pst3.[Name] as PropertyStatus_Purchased3,
--	pst4.[Name] as PropertyStatus_Purchased4,
--	pst5.[Name] as PropertyStatus_Purchased5,
--	ptecl1.[Name] as PropertyType_Collateral1,
--	ptecl2.[Name] as PropertyType_Collateral2,
--	ptecl3.[Name] as PropertyType_Collateral3,
--	pstcl1.[Name] as PropertyStatus_Collateral1,
--	pstcl2.[Name] as PropertyStatus_Collateral2,
--	pstcl3.[Name] as PropertyStatus_Collateral3,
--	(case c1.[Over40TotalIncome] when 1 then 'YES' else 'NO' end) as CollateralOver40MB,
--	(case c2.[Over40TotalIncome] when 1 then 'YES' else 'NO' end) as CollateralOver40CB1,
--	ml.[SalesCode],
--	c.[MobileNo] as Customer_MobilePhone,
--	(ISNULL(c.ResidentialAddress,'') + '-' + ISNULL(c.Ward,'') + '-' + ISNULL(c.District,'') + '-' + ISNULL(c.City,'')) as Customer_Address,
--	c.MainAddress as MailingAddress,
--	(CONVERT(nvarchar(4000),a2pre.[Condition1]) + @NewLineChar + CONVERT(nvarchar(4000),a2pre.[Condition2]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pre.[Condition3]) + @NewLineChar + CONVERT(nvarchar(4000),a2pre.[Condition4]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pre.[Condition5]) + @NewLineChar + CONVERt(nvarchar(4000),a2pre.[Condition6]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pre.[Condition7]) + @NewLineChar + CONVERT(nvarchar(4000),a2pre.[Condition8]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pre.[Condition9]) + @NewLineChar + CONVERT(nvarchar(4000),a2pre.[Condition10]) + @NewLineChar +
--	 CONVERT(nvarchar(4000),a2pre.[Condition11]) + @NewLineChar + CONVERT(nvarchar(4000),a2pre.[Condition12])) as Pre_Disbursement,
--	(CONVERT(nvarchar(4000),a2dis.[Condition1]) + @NewLineChar + CONVERT(nvarchar(4000),a2dis.[Condition2]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2dis.[Condition3]) + @NewLineChar + CONVERT(nvarchar(4000),a2dis.[Condition4]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2dis.[Condition5]) + @NewLineChar + CONVERt(nvarchar(4000),a2dis.[Condition6]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2dis.[Condition7]) + @NewLineChar + CONVERT(nvarchar(4000),a2dis.[Condition8]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2dis.[Condition9]) + @NewLineChar + CONVERT(nvarchar(4000),a2dis.[Condition10]) + @NewLineChar +
--	 CONVERT(nvarchar(4000),a2dis.[Condition11]) + @NewLineChar + CONVERT(nvarchar(4000),a2dis.[Condition12])) as Disbursement,
--	(CONVERT(nvarchar(4000),a2pos.[Condition1]) + @NewLineChar + CONVERT(nvarchar(4000),a2pos.[Condition2]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pos.[Condition3]) + @NewLineChar + CONVERT(nvarchar(4000),a2pos.[Condition4]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pos.[Condition5]) + @NewLineChar + CONVERt(nvarchar(4000),a2pos.[Condition6]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pos.[Condition7]) + @NewLineChar + CONVERT(nvarchar(4000),a2pos.[Condition8]) + @NewLineChar + 
--	 CONVERT(nvarchar(4000),a2pos.[Condition9]) + @NewLineChar + CONVERT(nvarchar(4000),a2pos.[Condition10]) + @NewLineChar +
--	 CONVERT(nvarchar(4000),a2pos.[Condition11]) + @NewLineChar + CONVERT(nvarchar(4000),a2pos.[Condition12])) as Post_Disbursement,
--	(case a2.[MRTA] when 1 then 'Yes' else 'No' end) as MRTA,
--	(case a2.[IncludeInsuranceLoan] when 1 then 'Finance' else 'Non-Finance' end) as MRTA_PaymentOption,
--	a2.[MRTAApplicationNumber],
--	a2.[MRTALifeAssured] as MRTA_LifeAssured,
--	REPLACE(CONVERT(varchar, CAST(a2.[MRTAAppliedPremium] as money), 1), '.00', '') as MRTA_AppliedPremium,
--	REPLACE(CONVERT(varchar, CAST(a2.[MRTAAppliedSumAssured] as money), 1), '.00', '') as MRTA_AppliedSumAsured,
--	REPLACE(CONVERT(varchar, CAST(a2.[MRTAAmount] as money), 1), '.00', '') as MRTA_Amount,
--	REPLACE(CONVERT(varchar, CAST(a2.[LoanAmtMRTA] as money), 1), '.00', '') as LoanAmtApprovedWMRTA,
--	REPLACE(CONVERT(varchar, CAST(a2.[TotalEMIMRTA] as money), 1), '.00', '') as TotalEMI_WithMRTA,
--	(case (select count(*) from dbo.AppActionlog aal where aal.ApplicationNo = ml.ApplicationNo and aal.[Action]='LOApproveRemodifySC') when 0 then 'NO' else 'YES' end) as LO_ReModified_SC,
--	c.[RLSCompanyCode] as RLSCompanyCode_MB,
--	cb1.[RLSCompanyCode] as RLSCompanyCode_CB1,
--	cb2.[RLSCompanyCode] as RLSCompanyCode_CB2,
--	cb3.[RLSCompanyCode] as RLSCompanyCode_CB3,
--	bt.[Name] as NewToBank,
--	tvf.[Remarks] as RemarkTeleVerifier,
--	c.EmailAddress1,
--	c.EmailAddress2,
--	c.EmailAddress3,
--	c.NationalityCode,
--	ml.EOpsTxnRefNo,
--	REPLACE(CONVERT(VARCHAR(11), ml.[HardCopyAppDate], 106), ' ', '/') as HardCopyAppDate,
--	c.CleanEB
--from [dbo].[MLApplication] ml WITH (NOLOCK)
--left join dbo.Customer c WITH (NOLOCK) on c.[ID] = ml.[MainBorrowerID]
--left join dbo.BankType bt on bt.[ID] = c.[CustomerTypeBank]
--left join dbo.TeleVerifierForm tvf on tvf.[CustomerID] = c.[ID]
--left join dbo.Customer cb1 WITH (NOLOCK) on cb1.[ID] = ml.[CoBorrower1]	
--left join dbo.Customer cb2 WITH (NOLOCK) on cb2.[ID] = ml.[CoBorrower2]	
--left join dbo.Customer cb3 WITH (NOLOCK) on cb3.[ID] = ml.[CoBorrower3]	

--left join dbo.SalesChannel sc on sc.[ID] = ml.[ChannelID]
--left join dbo.CustomerType ct on ct.[ID] = ml.[CustomerTypeID]
--left join dbo.PaymentType pt on pt.[ID] = ml.[PaymentTypeID]
--left join dbo.ProgramType prt on prt.[ID] = ml.[ProgramTypeID]
--left join dbo.ProductType pdt on pdt.[ID] = ml.[ProductType]
--left join dbo.CICMLApplication c1 on c1.[ID] = ml.[CICMLApplicationID1]
--left join dbo.CICMLApplication c2 on c2.[ID] = ml.[CICMLApplicationID2]
--left join dbo.CICMLApplication c3 on c3.[ID] = ml.[CICMLApplicationID3]
--left join dbo.ApprovalMLApplication a1 WITH (NOLOCK) on a1.[ID] = ml.[ApprovalID1]
--left join dbo.ApprovalMLApplication a2 WITH (NOLOCK) on a2.[ID] = ml.[ApprovalID2]
--left join dbo.ApprovalMLDisbursementCondition a2pre WITH (NOLOCK) on a2pre.[ID] = a2.[PreDisbursementID]
--left join dbo.ApprovalMLDisbursementCondition a2dis WITH (NOLOCK) on a2dis.[ID] = a2.[DisbursementID]
--left join dbo.ApprovalMLDisbursementCondition a2pos WITH (NOLOCK) on a2pos.[ID] = a2.[PostDisbursementID]

--left join dbo.ReworkReason rr on rr.[ID] = a2.[RejectReasonID]
--left join dbo.ReworkReason rc on rc.[ID] = a2.[CancelReasonID]
--left join dbo.Disbursement dis on dis.[ApplicationNo] = ml.[ApplicationNo]
--left join dbo.tblStatusName stt on stt.[ID] = ml.[Status]
--left join dbo.CustomerSegment cs on cs.[ID] = ml.[CustomerSegmentID]

--left join dbo.PIMLApplication pi1 WITH (NOLOCK) on pi1.[ID] = ml.[FinalProperty1]
--left join dbo.PropertyType pte1 on pte1.[ID] = pi1.[PropertyTypeID]
--left join dbo.PropertyStat pst1 on pst1.[ID] = pi1.[PropertyStatusID]

--left join dbo.PIMLApplication pi2 WITH (NOLOCK) on pi2.[ID] = ml.[FinalProperty2]
--left join dbo.PropertyType pte2 on pte2.[ID] = pi2.[PropertyTypeID]
--left join dbo.PropertyStat pst2 on pst2.[ID] = pi2.[PropertyStatusID]

--left join dbo.PIMLApplication pi3 WITH (NOLOCK) on pi3.[ID] = ml.[FinalProperty3]
--left join dbo.PropertyType pte3 on pte3.[ID] = pi3.[PropertyTypeID]
--left join dbo.PropertyStat pst3 on pst3.[ID] = pi3.[PropertyStatusID]

--left join dbo.PIMLApplication pi4 WITH (NOLOCK) on pi4.[ID] = ml.[FinalProperty4]
--left join dbo.PropertyType pte4 on pte4.[ID] = pi4.[PropertyTypeID]
--left join dbo.PropertyStat pst4 on pst4.[ID] = pi4.[PropertyStatusID]

--left join dbo.PIMLApplication pi5 WITH (NOLOCK) on pi5.[ID] = ml.[FinalProperty5]
--left join dbo.PropertyType pte5 on pte5.[ID] = pi5.[PropertyTypeID]
--left join dbo.PropertyStat pst5 on pst5.[ID] = pi5.[PropertyStatusID]

--left join dbo.PIMLApplication cl1 WITH (NOLOCK) on cl1.[ID] = ml.[FinalCollateral1]
--left join dbo.PropertyType ptecl1 on ptecl1.[ID] = cl1.[PropertyTypeID]
--left join dbo.PropertyStat pstcl1 on pstcl1.[ID] = cl1.[PropertyStatusID]

--left join dbo.PIMLApplication cl2 WITH (NOLOCK) on cl2.[ID] = ml.[FinalCollateral2]
--left join dbo.PropertyType ptecl2 on ptecl2.[ID] = cl2.[PropertyTypeID]
--left join dbo.PropertyStat pstcl2 on pstcl2.[ID] = cl2.[PropertyStatusID]

--left join dbo.PIMLApplication cl3 WITH (NOLOCK) on cl3.[ID] = ml.[FinalCollateral3]
--left join dbo.PropertyType ptecl3 on ptecl3.[ID] = cl3.[PropertyTypeID]
--left join dbo.PropertyStat pstcl3 on pstcl3.[ID] = cl3.[PropertyStatusID]
--where 
--[dbo]._fGetShortDate([ReceivedDate]) >= [dbo]._fGetShortDate(@fDate) and
--[dbo]._fGetShortDate([ReceivedDate]) <= [dbo]._fGetShortDate(@tDate)
--order by ml.[ReceivedDate]

--END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_report_tracking]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_report_tracking]
	@FromDate datetime,
	@ToDate datetime,
	@TypeReport varchar(30)
AS

 SELECT 
  ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
  ap.application_no as ApplicationNo,
  CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
  cus.full_name as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousPP,

--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
CONVERT(VARCHAR(24),cus.dob,106) as DOB,
--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_group m inner join m_definition_type md 
													on m.pk_id = md.fk_group_id and m.pk_id = 69	and md.is_active =1							where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 ) as SelfEmployed,

--cc.CurrentPosition as JobTitle,
(select top(1)m.name from pl_company_information co  inner join m_position m
															 on m.pk_id = co.fk_m_position_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as JobTitle,
--cc.CompanyCode as [Company Code],
co.company_code as CompanyCode,
--cc.CompanyName as CompanyName,
co.company_name as CompanyName,
--cc.BusinessType as CompanyType,
(select top(1) m.name from m_business_nature m
					  where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as CompanyType,
--ap.LocationBranchName as Business_TradingArea,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as Business_TradingArea,
--ap.CreditBureauType as CIC,
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,
----------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as [O/S_At_Other_Bank 1],

(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=1) as [EMI_At_Other_Bank 1],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as [O/S_At_Other_Bank 2],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=2) as [EMI_At_Other_Bank 2],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as [O/S_At_Other_Bank 3],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=3) as [EMI_At_Other_Bank 3],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as [O/S_At_Other_Bank 4],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=4) as [EMI_At_Other_Bank 4],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as [O/S_At_Other_Bank 5],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=5) as [EMI_At_Other_Bank 5],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as [O/S_At_Other_Bank 6],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=6) as [EMI_At_Other_Bank 6],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as [O/S_At_Other_Bank 7],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=7) as [EMI_At_Other_Bank 7],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as [O/S_At_Other_Bank 8],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=8) as [EMI_At_Other_Bank 8],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as [O/S_At_Other_Bank 9],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=9) as [EMI_At_Other_Bank 9],
--------
(select top 1 CONVERT(varchar, CAST(initial_loan AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as [O/S_At_Other_Bank 10],
(select top 1 CONVERT(varchar, CAST(EMI AS MONEY), 1) from 
    (select ROW_NUMBER() OVER (ORDER BY  created_date ASC) AS ROWNUMBERS, * from pl_loan_bureau
	where fk_application_information_id = ap.pk_id)x 
where x.ROWNUMBERS=10) as [EMI_At_Other_Bank 10],
----------
--CONVERT(varchar, CAST(cpl.PersonalLoanAmountApplied AS MONEY), 1) AS [Loan_Amt_Applied],
(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as [Loan_Amt_Applied],
--cpl.LoanPurpose,
 (select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as LoanPurpose,
--ap.ChannelD,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as ChannelD,

--ap.LocationBranchName,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as LocationBranchName,
--ap.ARMCode,
ap.arm_code as  ARMCode,
--cc.PaymentType as PaymentMethod,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,
--ap.CardProgramName as Program,
(select top(1) cp.name from cc_card_program cp
				where pap.fk_card_program_id = cp.pk_id) as Program,

--CONVERT(varchar, CAST(cc.FinalIncome AS MONEY), 1) AS [Total Income],
(select top(1)CONVERT(varchar, CAST(cin.final_income AS MONEY), 1)  from pl_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Total Income],

--CONVERT(varchar, CAST(cc.GrossBaseSalary AS MONEY), 1) AS [Salary Income], 
(select top(1)CONVERT(varchar, CAST(cin.gross_base_salary AS MONEY), 1)  from pl_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Salary Income],
--CONVERT(varchar, CAST(cc.BasicAllowance AS MONEY), 1) AS [Other_Incomes (Non-salary)], 
(select top(1)CONVERT(varchar, CAST(cin.basic_allowance AS MONEY), 1)  from pl_customer_income cin
				   where cin.fk_customer_information_id = cus.fk_customer_information_id ) as [Other_Incomes (Non-salary)], 

--(case when (select COUNT(*) from FRMInvestigave frm where frm.ApplicationNo = ap.ApplicationNo) > 0 then 'Yes' else 'No' end) as BlackList_Check, 
(case when (select COUNT(*) from frm_investigave frm where frm.fk_application_information_id = ap.pk_id) > 0 then 'Yes' else 'No' end) as BlackList_Check,

--(select top 1 lu.FullName  from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and (lg.[Action]='CIApproved' or lg.[Action]='CIApprovedPL' or lg.[Action]='CIApprovedCC'  or lg.[Action]='CIApprovedBD' or lg.[Action]='CIRejected' or lg.[Action]='CIRejectedBD')) as Underwritter,

(select top 1 lg.action_by  from application_action_log lg where lg.fk_application_information_id = ap.pk_id and lg.[Action] in('CIApproved','CIApprovedPL','CIApprovedCC' ,'CIApprovedBD','CIRejected','CIRejectedBD')) as Underwritter,

--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as DECISION_STATUS,

--cpl.DeviationLevelPL as [Level],
 (select top(1) m.name from pl_approval_information apr inner join m_deviation_level m
														  on apr.fk_deviation_level_id = m.pk_id and m.is_active =1
				 where apr.fk_application_information_id = ap.pk_id) as [Level],
 
--(case when cpl.PL_RejectReasonID <> null or cpl.PL_RejectReasonID <> '' then cpl.PL_RejectReasonID else cpl.PL_CancelReasonID end) as [Rejected or Cancelled Reasons], fk_reject_reason_id
(select top(1) m.name from pl_approval_information apr inner join m_reason m
														  on apr.fk_reject_reason_id = m.pk_id and m.is_active =1
				 where apr.fk_application_information_id = ap.pk_id) as [Rejected or Cancelled Reasons],

--cpl.Remark,
pap.remark as Remark,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr
				 where apr.fk_application_information_id = ap.pk_id) as  [Loan_Amt_Approved],
--cpl.LoanTenor AS [Tenor (month)],
pap.loan_tenor_applied as [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
'' as Interest,
--CONVERT(varchar, CAST(cpl.SCB_PL_EMI AS MONEY), 1) AS [TotalEMI],
(select top(1)CONVERT(varchar, CAST(pl.scb_emi AS MONEY), 1) from pl_approval_information pl
			     where pl.fk_application_information_id = ap.pk_id) AS [TotalEMI],

--CONVERT(varchar, CAST(cpl.TotalDSRForPL AS MONEY), 1) AS [TotalDBR (%)],
(select top(1)CONVERT(varchar, CAST(apr.total_dsr AS MONEY), 1) from pl_approval_information apr
				 where apr.fk_application_information_id = ap.pk_id) as [TotalDBR (%)],

--CONVERT(varchar, CAST(cpl.MUE_PL AS MONEY), 1) AS [TotalMUE],
(select top(1)CONVERT(varchar, CAST(apr.mue AS MONEY), 1) from pl_approval_information apr
				 where apr.fk_application_information_id = ap.pk_id) as [TotalMUE],

--dis.DisbursalStatus,
(select top(1) m.name from m_status m
				     where dis.fk_status_id = m.pk_id) as DisbursalStatus,

--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
CONVERT(VARCHAR(24),dis.disbursed_date,106) as DisbursedDate,

--dis.LoanAccountNo,
dis.loan_account_number as LoanAccountNo,

--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m
				     where ap.fk_m_status_id = m.pk_id) as CurrentStatus,

--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
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
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))  AS [Customer Address]

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	LEFT JOIN pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id
	left join m_status  m on pap.fk_status_id = m.pk_id and m.is_active = 1
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE 
  ((m.name in ('CIApproved', 'LODisbursed', 'CIApprovedBD', 'CIApprovedPL') and @TypeReport='ApprovedTracking')
	or (m.name in ('CIRejected', 'CIRejectedBD') and @TypeReport='RejectedTracking')
	or (m.name in ('CICancelled') and @TypeReport='CancelledTracking'))
	and Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_rpa_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_report_pl_application_get_rpa_reports]
	@FromDate datetime,
	@ToDate datetime
AS
--BEGIN
	--select * into #tbl_CCApplication from [CCApplication] ap with (nolock) WHERE ReceivedDate >= @FromDate and ReceivedDate <= @ToDate	

	--select cc.* into #tbl_CCCustomer from [CCCustomer] cc with (nolock) inner join #tbl_CCApplication ap on ap.CustomerID = cc.ID

	--select cc.* into #tbl_CCIdentification from [CCIdentification] cc with (nolock) inner join #tbl_CCApplication ap on ap.CustomerID = cc.CustomerID

	--select a.* into #tbl_CCRework_Pending from [CCRework] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	--where [LogType] = 'Pending'
	
	--select a.* into #tbl_CCRework_Tele from [CCRework] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	--where [LogType] = 'Tele'

	--select a.* into #tbl_AppActionLog from AppActionLog a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo

	--select a.* into #tbl_CCRemark from [CCRemark] a with (nolock) inner join #tbl_CCApplication b on a.ApplicationNo = b .ApplicationNo
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--SELECT 
	--ROW_NUMBER() OVER (ORDER BY  ReceivedDate ASC) AS Seq,
	--(CASE WHEN ap.IsVipApp = 1 THEN 'Yes' ELSE 'No' END) As [Vip App],
	--ap.ApplicationNo as [Application No],
	--(SELECT TOP 1 [ActionBy] FROM [AppActionLog] WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate) AS CreatedBy,
	--(
	--	SELECT TOP 1 b.FullName FROM [AppActionLog] a inner join LoginUser b on a.ActionBy = b.PeoplewiseID
	--	WHERE ApplicationNo = ap.ApplicationNo ORDER BY ActionDate
	--) AS CreatedName,
	--ap.SpecialCode as [Special Code],
	--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
	--ap.ProductTypeName as [Product Type],
	--ap.TypeApplicationName as [Application Type],
	--ap.CardProgramName as [Card Program],
	--ap.ProgramCodeName as [Program Code],
	--ap.CardTypeName as [Card Type],
	--ap.CardTypeName2 as [Card Type 2],
	--CustomerSegment as [Customer Segment],
	--BankRelationship as [Customer Relation],
	--(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
	--ap.ChannelD as Channel,
	--ap.LocationBranchName as [Branch Location],
	--ap.ARMCode as [ARM Code],
	--ap.IsTwoCardType as [IsTwoCardType],
	--cc.PaymentType as [Payment Type],
	--cc.FullName as [Primary Card Holder Name],
	--(select top 1 TypeOfIdentification from #tbl_CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of Identification],
	--(select top 1 IdentificationNo from #tbl_CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
	--CONVERT(VARCHAR(10), cc.DOB, 101) as [Primary Card Holder DOB],
	--cc.Nationality as [Primary Card Holder Nationality],
	--cc.EmailAddress1 as [Email Address 1],
	--cc.EmailAddress2 as [Email Address 2],
	--cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
	--cc.TypeEmployment as [Type Employment],
	--cc.OperationSelfEmployed as [Employment Type],
	--cc.CurrentPosition as [Current Position],
	--cc.Occupation,
	--cc.VerifiedPosition as [Verified Position],
	--cc.OccupationVerified as [Verified Occupation],
	--cc.CompanyName as [Company Name],
	--cc.CompanyCode as [Company Code],
	--cc.RLSCompanyCode as [Company Code RLS],
	--cc.BusinessType as [Company Type],
	--cc.CompanyAddress as [Company Address],
	--cc.CompanyPhone as [Company Office],
	--ap.CreditBureauType as [Bureau Type], 
	--cc.IncomeType as [Income Type],
	--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],	
	--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
	--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Approved Limit],
	--FinalApprovalStatus as [Final Approval Status],
	--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
	--(select [Name] from DeviationCodeList where [Name] = ap.DeviationCodeID) as [Deviation Code],
	--ap.[Status] as [Current Status],
	--ap.EOpsTxnRefNo,
	--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as [HardCopyAppDate],
	--(select count(1) from CCSubCard sc where sc.ApplicationNo=ap.ApplicationNo) as SupplementaryCardNo,
	--(select COUNT(*) from #tbl_AppActionLog where ApplicationNo=ap.ApplicationNo and [Action]='OSSendBack') as [Times sendback by OS],
	--(select COUNT(*) from #tbl_AppActionLog where ApplicationNo=ap.ApplicationNo and Action='CISendBackSC') as [Times sendback by CI to SC],
	--(select COUNT(*) from #tbl_AppActionLog where ApplicationNo=ap.ApplicationNo and Action='CISendBackOS') as [Times sendback by CI to OS],
	--(select COUNT(*) from #tbl_AppActionLog where ApplicationNo=ap.ApplicationNo and Action='CISendBackCI') as [Times sendback by CI to CI],
	--(select Scenario from DisbursalScenario where ID = ap.DisbursementScenarioId) as [Pre-disbursement condition Scenario],
	--ap.DisbursementScenarioText as [Pre-disbursement condition],	
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=1) as [CC Remark 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=2) as [CC Remark 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  CreatedDate ASC) AS ROWNUMBERS, * from #tbl_CCRemark
	--	where ApplicationNo=ap.ApplicationNo and ProductTypeName='CC')x 
	--where x.ROWNUMBERS=3) as [CC Remark 3],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Pending Log Sendback reason 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x
	--where x.ROWNUMBERS=1) as [Pending Log Remark 1],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--ap.SCRemark as [SC Remark],
	--ap.OpsRemark as [Ops Remark],
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Pending Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Response By 1],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Pending Log Sendback send from 1],
	--------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Pending Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Pending Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Pending Log Sendback send from 2],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Pending Log Sendback reason 3],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Pending Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Pending Log Sendback send from 3],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Pending Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Sendback date 4],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Pending Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Pending Log Sendback send from 4],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Pending Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Sendback date 5],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Pending Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Response By 5],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Pending
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Pending Log Sendback send from 5],
	--------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1)) as [Tele Log Sendback reason 1],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark 1],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Sendback date 1],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback by 1],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Remark Response 1],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1),101) as [Tele Log Response Date 1],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Response By 1],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=1) as [Tele Log Sendback send from 1],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2)) as [Tele Log Sendback reason 2],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark 2],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Sendback date 2],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback by 2],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Remark Response 2],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2),101) as [Tele Log Response Date 2],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Response By 2],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=2) as [Tele Log Sendback send from 2],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3)) as [Tele Log Sendback reason 3],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark 3],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Sendback date 3],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback by 3],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Remark Response 3],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3),101) as [Tele Log Response Date 3],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Response By 3],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=3) as [Tele Log Sendback send from 3],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4)) as [Tele Log Sendback reason 4],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark 4],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Sendback date 4],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback by 4],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Remark Response 4],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4),101) as [Tele Log Response Date 4],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Response By 4],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=4) as [Tele Log Sendback send from 4],
	------------
	--(select [Name] from [ReworkReason] where ID = (select top 1 [ReworkReasonID] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5)) as [Tele Log Sendback reason 5],

	--(select top 1 Remark from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark 5],

	--CONVERT(VARCHAR(24), (select top 1 [SendBackDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Sendback date 5],

	--(select top 1 [SendBackBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback by 5],

	--(select top 1 [RemarkResponse] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Remark Response 5],

	--CONVERT(VARCHAR(24), (select top 1 [ReceivedDate] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5),101) as [Tele Log Response Date 5],

	--(select top 1 [ReceivedBy] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Response By 5],

	--(select top 1 [UserType] from 
	--	(select ROW_NUMBER() OVER (ORDER BY  SendBackDate ASC) AS ROWNUMBERS, * from #tbl_CCRework_Tele
	--	where ApplicationNo=ap.ApplicationNo)x 
	--where x.ROWNUMBERS=5) as [Tele Log Sendback send from 5],
	--cc.Gender,
	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from #tbl_CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID') 
	--ORDER BY TypeOfIdentification) as [Expried Date For ID],
	--(select top 1 IdentificationNo from #tbl_CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Visa],
	--(select top 1 CONVERT(VARCHAR(10), ExpriedDate, 101) from #tbl_CCIdentification 
	--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Visa') 
	--ORDER BY TypeOfIdentification) as [Expried Date For Visa],
	--cc.MaritalStatus,
	--cc.Nationality,
	--ap.AccountNumber, 
	--ap.PaymentMethod,
	--cc.OwnerResidentialAdd as [Ownership],
	--ap.HolderCurrencyDepositedAmount as [Deposit Amount],
	--ap.HolderCurrentAccountNo as [Current Acc],
	--ap.HolderDepositedCurrency as [Currency],
	--cc.CompanyGenericCode as [Company Generic Code],
	--cc.CompanyAddress + ' ' + cc.CompanyWard + ' ' + cc.CompanyDistrict + ' ' + CompanyCity as [Company Full Address],
	--CONVERT(varchar, CAST([FinalIncome] AS MONEY), 1)  as [Final Monthly Income]
	--FROM
	--	#tbl_CCApplication ap inner join #tbl_CCCustomer cc on ap.CustomerID = cc.ID	
	--WHERE ap.ProductTypeName = 'CC'
	--and	dbo._fGetShortDate(ReceivedDate) >= dbo._fGetShortDate(@FromDate)
	--and dbo._fGetShortDate(ReceivedDate) <= dbo._fGetShortDate(@ToDate)
	--ORDER BY Seq

	--drop table #tbl_CCApplication
	--drop table #tbl_CCRework_Pending
	--drop table #tbl_CCRework_Tele
	--drop table #tbl_CCCustomer
	--drop table #tbl_CCIdentification
	--drop table #tbl_AppActionLog	
	--drop table #tbl_CCRemark
--END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_sales_master]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_sales_master]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
--ap.ApplicationNo,
ap.application_no as  ApplicationNo,
--CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--cc.FullName as PrimaryCardHolderName,
ci.full_name as PrimaryCardHolderName,
--CONVERT(VARCHAR(24),cc.DOB,106) as PrimaryCardHolderDOB,
CONVERT(VARCHAR(24),ci.dob,106) as PrimaryCardHolderDOB,
--cc.OperationSelfEmployed as SelfEmployed,

(select top(1) m.name from  m_definition_type m
				where cus.fk_operation_self_employed_id = m.pk_id and m.fk_group_id = 69 and m.is_active =1) as SelfEmployed,

--cc.CompanyName as CompanyName,
(select top(1) co.company_name from pl_company_information co
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyName,

--cc.CompanyCity as CompanyCity,
(select top(1) m.name from pl_company_information co inner join m_city m on m.pk_id = co.fk_company_city_id
																and m.is_active = 1 
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyCity,
--cc.BusinessType as CompanyType,

(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyType,

--HolderInitial as InitialLimit,
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from pl_application ca
				where ca.fk_application_information_id = ap.pk_id)AS  InitialLimit,

--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,
--ARMCode,
ap.arm_code as ARMCode,
--cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as RepaymentType,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,

--CONVERT(VARCHAR(24),DecisionDate,106) as Final_DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as Final_DecisionDate,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) as DECISION_STATUS,

--FinalLimitApproved as FinalApprovedLimit,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)AS  FinalApprovedLimit,
--InterestRateSuggested as Interest,
'0' as Interest,

--ap.CardTypeName as CardType,
'' as CardType,
--ap.CardTypeName2 as CardType2,
'' as CardType2,
--ap.CardProgramName as CardProgram,
(select top(1) m.name from pl_application pa join m_program_type m on pa.fk_card_program_id = m.pk_id 
																	and m.fk_type_id =10 and m.is_active =1
				where pa.fk_application_information_id = ap.pk_id) as CardProgram,
--ap.TypeApplicationName as TypeApplication,
pap.type_of_application as TypeApplication,
--PIDOfSaleStaff as SalesCode,
ap.sale_staff_bank_id as SalesCode,
--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='OSSendBack')) as Pending_OSSendback,

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log lg where lg.fk_application_information_id =ap.pk_id and (lg.action ='OSSendBack')) as Pending_OSSendback,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'CISendBack%')) as Pending_CISendback

(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log lg where lg.fk_application_information_id =ap.pk_id and (lg.action like 'CISendBack%')) as Pending_CISendback
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_sales_master_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_sales_master_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
 ap.application_no as ApplicationNo,
 CONVERT(VARCHAR(24),ap.received_date,106) as [Receiving Date],
 cus.full_name as Customer_Name,
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as CustomerID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as CustomerPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPassportID,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as CustomerPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousID,


--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as CustomerPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as CustomerPreviousPP,

--CONVERT(VARCHAR(24),cc.DOB,106) as DOB,
CONVERT(VARCHAR(24),cus.dob,106) as DOB,
--cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from   m_definition_type m						
						where cus.fk_operation_self_employed_id = m.pk_id and m.is_active=1 
						and m.fk_group_id = 69) as SelfEmployed,
--cc.CurrentPosition as JobTitle,
(select top(1)m.name from m_position m
				where m.pk_id = co.fk_m_position_id and m.is_active = 1) as JobTitle,
--cc.CompanyName as CompanyName,
(select top(1)co.company_name from pl_company_information co 
				where co.fk_customer_information_id = ci.pk_id) as CompanyName,
--cc.BusinessType as CompanyType,
(select top(1) m.name from m_business_nature m
					  where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as CompanyType,
--cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where co.fk_customer_information_id = ci.pk_id) as RLSCompanyCode,

--CONVERT(varchar, CAST(cpl.PersonalLoanAmountApplied AS MONEY), 1) AS [Loan_Amt_Applied],
(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as [Loan_Amt_Applied],

--cpl.LoanPurpose,
(select top(1)m.name from pl_approval_information apr inner join m_loan_purpose m on apr.fk_loan_purpose_id = m.pk_id
				where apr.fk_application_information_id = ap.pk_id) as LoanPurpose,
--ap.ChannelD,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as ChannelD,
--ap.LocationBranchName,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as LocationBranchName,
--ap.ARMCode,
ap.arm_code as  ARMCode,
--cc.PaymentType as PaymentMethod,
(select top(1) m.name from  m_payment_type m
		     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as PaymentMethod,
--ap.CardProgramName as Program,
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as Program,
--CONVERT(VARCHAR(24),ap.DecisionDate,106) as DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as DecisionDate,

--FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m 
													on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id )  as DECISION_STATUS,
--CONVERT(varchar, CAST(cpl.PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan_Amt_Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr 
				where apr.fk_application_information_id = ap.pk_id) as [Loan_Amt_Approved],
--cpl.LoanTenor AS [Tenor (month)],
pap.loan_tenor_applied as [Tenor (month)],
--Convert(varchar,Convert(money,ap.FinalInterestRate),1) AS Interest,
'' as Interest,
--dis.DisbursalStatus,
(select top(1) m.name from m_status m
				     where dis.fk_status_id = m.pk_id) as DisbursalStatus,
--CONVERT(VARCHAR(24),dis.DisbursedDate,106) as DisbursedDate,
CONVERT(VARCHAR(24),dis.disbursed_date,106) as DisbursedDate,
--dis.LoanAccountNo,
dis.loan_account_number as  LoanAccountNo,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m
				     where ap.fk_m_status_id = m.pk_id) as CurrentStatus,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--(Case when ap.IsVipApp = 1 then 'Yes' else 'No' end) as IsVipApp,
(Case when ap.is_vip = 1 then 'Yes' else 'No' end) as IsVipApp,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action='OSSendBack')) as Pending_OSSendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action='OSSendBack')) as Pending_OSSendback,

--(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from AppActionLog where ApplicationNo=ap.ApplicationNo and (Action like 'CISendBack%')) as Pending_CISendback,
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and Action like 'CISendBack%') as Pending_OSSendback,

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
					THEN (cus.permanent_address + ' - ' + cus.permanent_ward + ' - ' + cus.permanent_district + ' - ' +  (select top(1) m1.name from m_city m1 where cus.fk_permanent_city_id = m1.pk_id and m1.is_active =1))
	        ELSE
	         (CASE WHEN cus.billing_address = 'Residential address' 
				   THEN (cus.residential_address + ' - ' + cus.residential_ward + ' - ' + cus.residential_district + ' - ' + (select top(1) m1.name from m_city m1 where cus.fk_residential_city_id = m1.pk_id and m1.is_active =1)) ELSE '' END) END) END))  AS [Customer Address]

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
    LEFT JOIN pl_disbursement_information dis ON dis.fk_application_information_id = ap.pk_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE 
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_sas_reports]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_sas_reports]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
   CONVERT(VARCHAR(10), ap.received_date, 101) as [ReceivedDate],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id
  order by m.name) as  [Primary Card Holder ID],

--cc.FullName as [Primary Card Holder Name],
cus.full_name	as [Primary Card Holder Name],
--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id
  order by m.name ) as  [Primary Card Holder Previous ID],

 CONVERT(VARCHAR(10), cus.dob, 101) as [DOB],

--CONVERT(varchar, CAST([ap].FinalLoanAmountSuggestedBySystem AS MONEY), 1) AS [Loan amount applied],
 CONVERT(varchar, CAST(apr.loan_amount_suggested_by_system AS MONEY), 1) AS [Loan amount applied],
--CONVERT(varchar, CAST([plApp].PLFinalLoanAmountApproved AS MONEY), 1) AS [Loan amount approved],
  CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)AS [Loan amount approved],
--CONVERT(VARCHAR(10),DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as  [Date of Decision],
--CONVERT(VARCHAR(10), (SELECT TOP 1 DisbursedDate db FROM Disbursement db WHERE ApplicationNo = ap.ApplicationNo), 101) as [Disbursed date],
(select top(1)CONVERT(VARCHAR(10),dis.disbursed_date, 101) from pl_disbursement_information dis
				where dis.fk_pl_application_information_id = ap.pk_id) as [Disbursed date],
--ap.EMISuggested AS EMI,
'' as EMI,
--ap.ChannelD AS Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1)AS Channel,
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode AS [ARM Code],
 ap.arm_code as [ARM Code],
--ap.SalesPWID AS [PID of sale staff],
ap.sale_staff_bank_id as [PID of sale staff],
--cc.CompanyPhone AS [Office Phone],
co.office_telephone as  [Office Phone],

--cc.HomePhoneNo AS [Home Phone],
cus.home_phone_no as  [Home Phone],
--cc.PrimaryPhoneNo AS [Mobile Phone],
cus.primary_phone_no AS [Mobile Phone],
--cc.PermAddress AS [Permanent address],
cus.permanent_address AS [Permanent address],
--cc.CompanyCode as [Company CAT],
co.company_code as [Company CAT],

--cc.CompanyName as [Company Name],
co.company_name as CompanyName,
--cc.CompanyAddress as [Company Address],
co.Company_Address as [Company Address],
--cc.TypeEmployment as [Employment type],
(select top(1) m.name from pl_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment type],
--cc.Industry,
 '' as Industry,
--cc.CurrentPosition as [Current Position],
(select top(1)m.name from m_position m
				where m.pk_id = co.fk_m_position_id and m.is_active = 1) as [Current Position],
--cc.Occupation,
(select top(1)m.name from pl_company_information co  inner join m_occupation m
																  on m.pk_id = co.fk_m_occupation_id and m.is_active = 1
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as Occupation,
--CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS [Monthly Income Customer Declared],
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS [Monthly Income Customer Declared],
--ap.CreditBureauType as [Bureau Type]
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type]

FROM
    [dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_approval_information apr on apr.fk_application_information_id = ap.pk_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_sms_nsg]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_sms_nsg]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
ap.application_no as ApplicationNo,
ap.received_date as ReceivedDate,
--ap.[Status] as [CurrentStatus],
(select top(1) m.name from m_status m
				where ap.fk_m_status_id = m.pk_id) as [CurrentStatus],

--apl.PL_FinalApprovalStatus as [FinalApprovalStatus],
(select top(1) m.name from approval_information apr inner join m_status 
												on apr.fk_status_id = m.pk_id and m.is_active =1
				where apr.fk_application_information_id = ap.pk_id) as [FinalApprovalStatus],

--CONVERT(VARCHAR(10),DecisionDate, 101) as [FinalDecisionDate],
(select top(1) CONVERT(VARCHAR(10),apr.date_of_decision, 101)  from approval_information apr 
				     where apr.fk_application_information_id = ap.pk_id) as [FinalDecisionDate],

--CONVERT(VARCHAR(10),al.ActionDate, 101) as [ActionDateNSG],
CONVERT(VARCHAR(10),al.action_date, 101) as [ActionDateNSG],
----QueueNSG

--al.ActionBy AS [NSG By],
al.action_by as [NSG By],
--cc.FullName,
ci.full_name as  FullName,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport') ORDER BY TypeOfIdentification) as [Primary Card Holder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
								on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder ID],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary Card Holder Previous ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id)  as [Primary Card Holder Previous ID],

--cc.PrimaryPhoneNo AS [Mobile Phone],
pl.primary_phone_no as [Mobile Phone],
--cc.EmailAddress1,
pl.email_address_1 as  EmailAddress1,
--cc.EmailAddress2,
pl.email_address_2 as  EmailAddress2,
--cc.EmailAddress3,
pl.email_address_3 as  EmailAddress3,
--cc.Nationality,

(select top(1)m.name from m_nationality m
				where pl.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--ap.ChannelD AS Channel,
 (select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS Channel,

--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],

--(SELECT TOP 1 Remark FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 1) AS [Remark_TeleVerifier],
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  [Remark_TeleVerifier],
----Remark_Underwriter
----ProductType
--cc.CompanyCode,
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as CompanyCode,
----CompanyType
--cc.RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--ap.ProgramCodeName
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id)  as ProgramCodeName
FROM
	[dbo].[application_information] ap 
	inner join customer_information ci on ap.pk_id = ci.fk_application_information_id
	inner join pl_customer_information pl on ap.pk_id = pl.fk_application_information_id
	left join application_action_log al on al.fk_application_information_id = ap.pk_id
	inner join m_type m on ap.fk_m_type_id = m.pk_id and m.name in('PL','PersonalLoan')
	--left join CCPLApplication apl ON apl.CCApplicationNo = ap.ApplicationNo
	
WHERE
	al.[Action] = 'NSG'
and	Cast(ap.received_date as Date) >= Cast(@FromDate as Date)
and Cast(ap.received_date as Date) <= Cast(@ToDate as Date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tat_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tat_report]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
ap.application_no as [Application No],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--cc.FullName as [Customer Name],
cus.full_name as [Customer Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Type Of ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Type Of ID],

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Customer ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as[Customer ID],

--cc.PrimaryPhoneNo as [Customer Mobile],
cus.primary_phone_no as [Customer Mobile],
--cc.CompanyCode as [Company Code],
co.company_code as [Company Code],
--cc.RLSCompanyCode as RLSCompanyCode,
co.company_code_rls as RLSCompanyCode,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,
--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m
					  where ap.fk_m_status_id = m.pk_id) as [Current Status],
--vf.[Status] as TeleStatus,
(select m.name from verification_form v left join m_status m on v.fk_status_id = m.pk_id and m.is_active =1
		  where v.fk_application_information_id = ap.pk_id) as TeleStatus,
--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as [Channel],
--ap.LocationBranchName as City,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as City,
--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) AS [Amount Applied],
CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1) AS [Amount Applied],
--CONVERT(varchar, CAST(ccPL.FinalLoanAmountApproved AS MONEY), 1) AS [Amount Approved],
(select top(1) CONVERT(varchar, CAST(inf.final_loan_amount_approved AS MONEY), 1) from pl_approval_information inf 
											where inf.fk_application_information_id = ap.pk_id) AS[Amount Applied],
--ap.ARMCode,
ap.arm_code as ARMCode,
'No' As [Rework to SC],

'No' As [Rework to CI],

--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='SC')/60 as [Sale.Coor],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='OS')/60 as [Op.Supports],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('CI2','CI1'))/60 as [CI],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE')/60 as [Tele],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='LO')/60 as [L.Operation],
--(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],

(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='SC')/60 as [Sale.Coor],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='OS')/60 as [Op.Supports],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('CI2','CI1'))/60 as [CI],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE')/60 as [Tele],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='LO')/60 as [L.Operation],
(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],

--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--ap.EOpsTxnRefNo2,
ap.eops_txn_ref_no_2 as EOpsTxnRefNo2,
--cc.EmailAddress1,
cus.email_address_1 as EmailAddress1,
--cc.EmailAddress2,
cus.email_address_2 as EmailAddress2,
--cc.EmailAddress3,
cus.email_address_3 as EmailAddress3,
--cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as [Application sign date]
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as [Application sign date]
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_disbursement_information dis on ap.pk_id = dis.fk_application_information_id
	left join pl_company_information co on co.fk_application_information_id = ap.pk_id
WHERE
  Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tat_report_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tat_report_sales]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
 ap.Application_No as [Application No],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--cc.FullName as [Customer Name],
 cus.full_name as [Customer Name],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code],
--cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as ProgramCode,

--ap.Status as CurrentStatus,
(select top(1) m.name from m_status m
				where ap.fk_m_status_id = m.pk_id) as CurrentStatus,
--vf.[Status] as TeleStatus,
(select top(1) m.name from verification_form vf inner join m_status m on vf.fk_status_id = m.pk_id and m.is_active =1
				where vf.fk_application_information_id = ap.pk_id) as TeleStatus,
--ap.ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1)  as Channel,
--ap.LocationBranchName as City,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as City,

--CONVERT(varchar, CAST(ccPL.PersonalLoanAmountApplied AS MONEY), 1) AS [Amount Applied],
  CONVERT(varchar, CAST(pap.loan_amount_applied as MONEY), 1) AS [Amount Applied],

--CONVERT(varchar, CAST(ccPL.PLFinalLoanAmountApproved AS MONEY), 1) AS [Amount Approved],
(select top(1) CONVERT(varchar, CAST(inf.final_loan_amount_approved AS MONEY), 1) from pl_approval_information inf 
											where inf.fk_application_information_id = ap.pk_id) AS [Amount Approved],
--ap.ARMCode,
	ap.arm_code as ARMCode,
--'No' As [Rework to SC],
'No' As [Rework to SC],
--'No' As [Rework to CI],
'No' As [Rework to CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='SC')/60 as [Sale.Coor],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role='SC')/60 as [Sale.Coor],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='OS')/60 as [Op.Supports],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role='OS')/60 as [Op.Supports],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('CI2','CI1'))/60 as [CI],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role in ('CI2','CI1'))/60 as [CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI_TELE')/60 as [Tele],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role='CI_TELE')/60 as [Tele],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='LO')/60 as [L.Operation],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role='LO')/60 as  [L.Operation],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],
(select sum(Duration) from pl_tat_logs lg 
					 where lg.fk_application_information_id = ap.pk_id and lg.current_role in ('SC','OS','CI1','CI2','LO'))/60 as [TOTAL],

--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--ap.EOpsTxnRefNo2,
ap.eops_txn_ref_no_2 as EOpsTxnRefNo2,
--cc.Nationality,
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as Nationality,
--CONVERT(VARCHAR(24),ap.HardCopyAppDate,106) as [Application sign date]
CONVERT(VARCHAR(24),ap.hard_copy_app_date,106) as [Application sign date]
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_disbursement_information dis on ap.pk_id = dis.fk_application_information_id

WHERE 
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tatlogs]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tatlogs]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.Application_No,lg.Action_Date ASC) AS Seq,
ap.application_no as ApplicationNo,

--SUBSTRING(lg.ApplicationNo,1,2) as ProductTypeName,
m.name as ProductTypeName,

lg.[action],
lg.action_by,
'' as ActionName,
CONVERT(VARCHAR(10), lg.action_date, 101) + ' ' + CONVERT(VARCHAR(8), lg.action_date, 108) as [Action Date],
lg.current_role as CurrentRole,
lg.duration
FROM
	[dbo].pl_tat_logs lg --join LoginUser lu on lu.PeoplewiseID = lg.ActionBy
	inner join application_information ap on ap.pk_id = lg.fk_application_information_id
	inner join pl_application cap on ap.pk_id = cap.fk_application_information_id
	inner join m_type m on ap.fk_m_type_id = m.pk_id
	
WHERE
	Cast(ap.received_date as Date) >= Cast(@FromDate as Date) and
	Cast(ap.received_date as Date) <= Cast(@ToDate as Date)
ORDER BY ap.application_no, lg.action_date desc
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tatlogs_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 -- exec sp_report_pl_application_get_pl_tatreportci '2019-01-01','2019-04-19'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tatlogs_ci]
	@FromDate datetime,
	@ToDate datetime
AS
BEGIN
	SELECT 
	ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
	ap.application_no AS [Application No],
	CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as [EverSendBack],
(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'CISendBack%')) as [EverSendBack],

	(select Top 1 CONVERT(VARCHAR(20), Action_Date, 120) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date asc) as [First Date submitted to CIs queue],


	(select Top 1 CONVERT(VARCHAR(20), Action_Date, 120) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) as [Last-time-Requeue to CIs queue],
--	--
	dbo.[fuConvertMinutesToDays]((select Top 1 Datediff(mi, Action_Date, GETDATE()) from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	-(select COUNT(*)*24*60 from m_bank_holiday where bank_holiday between (select Top 1 Action_Date from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) and GETDATE())

	-(select Top 1 Datediff(wk, Action_Date, GETDATE())*48*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	-(select Top 1 Datediff(dd, Action_Date, GETDATE())*16*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	+(select Top 1 Datediff(wk, Action_Date, GETDATE())*32*60 from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc)

	+(select COUNT(*)*16*60 from m_bank_holiday where bank_holiday between (select Top 1 Action_Date from application_action_log where fk_application_information_id = ap.pk_id and (Action like 'OSApproved%') order by Action_Date desc) and GETDATE())
	) 
	as [Aging at CIs queue],
--	--
--	CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as [Date of Decision],

	CONVERT(VARCHAR(10), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by Action_Date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by Action_Date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],


--	ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--	ap.TypeApplicationName as [Application Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Application Type],
--	ap.CardProgramName as [Card Program],
(select top(1) cp.name from cc_application ca join cc_card_program cp on ca.fk_card_program_id = cp.pk_id
				where ca.fk_application_information_id = ap.pk_id) as [Card Program],
--	ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],

--	ap.CardTypeName as [Card Type 1],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_1_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type 1],

--	ap.CardTypeName2 as [Card Type 2],
(select top(1)ct.name from cc_application ca join cc_card_type ct on ca.fk_card_type_2_id = ct.pk_id
				where ca.fk_application_information_id = ap.pk_id)  as [Card Type 2],
--	ap.IsTwoCardType as [IsTwoCardType],
   '' as [IsTwoCardType],
--	CustomerSegment as [Customer Segment],
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--	BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--	(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
 (CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
--	cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--	(select top 1 TypeOfIdentification from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as TypeOfIdentification,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as TypeOfIdentification,

--	(select top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary CardHolder ID],
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cus.fk_customer_information_id = ci.pk_id) as [Primary CardHolder ID],
--	cc.Nationality as [Primary Card Holder Nationality],
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1 and m.is_active = 1) as [Primary Card Holder Nationality],
--	cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
cus.primary_phone_no   as [Primary Card Holder Mobile Phone Number],
--	cc.EmailAddress1 as [Email Address 1],
cus.email_address_1 as [Email Address 1],
--	cc.EmailAddress2 as [Email Address 2],
cus.email_address_2 as [Email Address 2],
--	cc.TypeEmployment as [Employment Type],
(select top(1)m.name from m_employment_type m
					where co.fk_m_employment_type_id = m.pk_id) as  [Employment Type],
--	cc.CompanyName as [Company Name],
co.company_name	as [Company Name],
--	cc.CompanyCode as [Company Code],
(select top(1) mc.name from m_company_list cl inner join m_company_code mc on cl.fk_m_company_code_id = mc.pk_id
				 where cl.pk_id = ci.fk_company_information_id) as [Company Code],
--	cc.BusinessType as [Company Type],
(select top(1) m.name from  m_business_nature m 		
								where co.fk_m_business_nature_id = m.pk_id and m.is_active = 1) as [Company Type],
--	cc.RLSCompanyCode as [Company Code RLS],
co.company_code_rls as [Company Code RLS],
--	cc.CompanyPhone as [Office Phone],
co.office_telephone as [Office Phone],
--	ap.CreditBureauType as [Bureau Type],
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
															on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as [Bureau Type],
--	ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--	ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as [Branch Location],

--	ap.ARMCode as [ARM Code],
ap.arm_code as [ARM Code],
--	ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Current Status],

--	ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,

--	(select top 1 [status] from VerificationForm
--			where ApplicationNo = ap.ApplicationNo
--			and IsTeleVerify =1) as TeleStatus,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as TeleStatus,

--	(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[CCTATLogs] WHERE ApplicationNo = ap.ApplicationNo and CurrentRole like 'CI%') AS [Queued time at CI queue],

(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[pl_tat_logs] WHERE fk_application_information_id = ap.pk_id and current_role like 'CI%') AS [Queued time at CI queue],

--	ccPL.PersonalLoanAmountApplied,
(select top(1)CONVERT(varchar, CAST(pap.loan_amount_applied AS MONEY), 1)) as PersonalLoanAmountApplied,
--	ccPL.PLFinalLoanAmountApproved,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1) from pl_approval_information apr 
				where apr.fk_application_information_id = ap.pk_id)  AS PLFinalLoanAmountApproved,

--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
CONVERT(varchar, CAST(pap.holder_initial AS MONEY), 1) AS [Initial Limit],
--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],

--	cc.[CleanEB], 
 '' as [CleanEB], 
	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='SC')/60 as [TAT Sales Coor],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='OS')/60 as [TAT Ops Support],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI_TELE')/60 as [TAT Tele],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI1')/60 as [TAT Recommender],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role='CI2')/60 as [TAT Approver],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('CI2','CI1'))/60 as [TATA - CI],

	(select sum(Duration) from pl_tat_logs where fk_application_information_id = ap.pk_id and current_role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

	FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq
END
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tatlogs_report_ci]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tatlogs_report_ci]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--ap.ApplicationNo AS [Application No],
ap.application_no AS [Application No],
--CONVERT(VARCHAR(10), ap.ReceivedDate, 101) + ' ' + CONVERT(VARCHAR(8), ap.ReceivedDate, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
 (select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [Date of Decision],

--CONVERT(VARCHAR(10), (select top 1 action_date FROM [LITS].[dbo].[AppActionLog] al where al.ApplicationNo = ap.ApplicationNo and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 action_date FROM [LITS].[dbo].[AppActionLog] al where al.ApplicationNo = ap.ApplicationNo and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

CONVERT(VARCHAR(10), (select top 1 action_date FROM [dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and al.[Action] in ('CIApproved' ,'CIApprovedPL' ,'CIApprovedCC'  ,'CIApprovedBD' ,'CIRejected' ,'CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 action_date FROM [dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and  al.[Action] in('CIApproved' ,'CIApprovedPL' ,'CIApprovedCC'  ,'CIApprovedBD' ,'CIRejected' ,'CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

--ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id) as [Product Type],
--ap.TypeApplicationName as [Application Type],
pap.type_of_application as [Application Type],
--ap.CardProgramName as [Card Program],
'' as [Card Program],

--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName as [Card Type],
''  as [Card Type],

--ap.CardTypeName2 as [Card Type 2],
''  as [Card Type 2],
--ap.IsTwoCardType as [IsTwoCardType],
'' as [IsTwoCardType],
--CustomerSegment as [Customer Segment],
(select top(1) m.name from m_customer_segment m
					where cus.fk_customer_segment_id = m.pk_id) as [Customer Segment],
--BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
--cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--(select top 1 TypeOfIdentification from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as TypeOfIdentification,
(select top(1) cid.identification_no
  from customer_identification cid join  [m_identification_type] m 
									on cid.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cid.fk_customer_information_id = ci.pk_id
   ORDER BY m.name) as TypeOfIdentification,

--(select top 1 IdentificationNo from CCIdentification 
--where CustomerType='Primary' and CustomerID=ap.CustomerID and TypeOfIdentification in ('ID','Passport','Previous_ID','Previous_PP') ORDER BY TypeOfIdentification) as [Primary CardHolder ID],
(select top(1) cid.identification_no
  from customer_identification cid join  [m_identification_type] m 
									on cid.fk_m_identification_type_id = m.pk_id and m.name in ('ID','Passport','Previous_ID','Previous_PP')
  where cid.fk_customer_information_id = ci.pk_id
   ORDER BY m.name) as [Primary CardHolder ID],

--cc.Nationality as [Primary Card Holder Nationality],
(select top(1) m.name from m_nationality m
				where m.pk_id = ci.fk_m_nationality_id_1) as [Primary Card Holder Nationality],
--cc.PrimaryPhoneNo as [Primary Card Holder Mobile Phone Number],
cus.primary_phone_no as [Primary Card Holder Mobile Phone Number],
--cc.EmailAddress1 as [Email Address 1],
cus.email_address_1 as [Email Address 1],
--cc.EmailAddress2 as [Email Address 2],
cus.email_address_2 as [Email Address 2],
--cc.TypeEmployment as [Employment Type],
(select top(1) m.name from pl_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment Type],

--cc.CompanyName as [Company Name],
(select top(1) co.company_name from pl_company_information co
								where co.fk_pl_customer_information_id = cus.pk_id)as [Company Name],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code],
--cc.BusinessType as [Company Type],
(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id)as [Company Type],
--cc.RLSCompanyCode as [Company Code RLS],
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code RLS],
--ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS [Channel],
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode as [ARM Code],
ap.ARM_Code as [ARM Code],
--ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,
--(select top 1 [status] from VerificationForm
--		where ApplicationNo = ap.ApplicationNo
--		and IsTeleVerify =1) as TeleStatus,
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  TeleStatus,

--(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[CCTATLogs] WHERE ApplicationNo = ap.ApplicationNo and CurrentRole like 'CI%') AS [Queued time at CI queue ],
(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[pl_tat_logs] WHERE fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
 CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1) AS [Initial Limit],
--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='SC')/60 as [TAT Sales Coor],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='OS')/60 as [TAT Ops Support],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI_TELE')/60 as [TAT Tele],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI1')/60 as [TAT Recommender],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole='CI2')/60 as [TAT Approver],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('CI2','CI1'))/60 as [TATA - CI],
--(select sum(Duration) from CCTATLogs where ApplicationNo = ap.ApplicationNo and CurrentRole in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='SC')/60 as [TAT Sales Coor],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='OS')/60 as [TAT Ops Support],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI_TELE')/60 as [TAT Tele],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI1')/60 as [TAT Recommender],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI2')/60 as [TAT Approver],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('CI2','CI1'))/60 as [TATA - CI],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

FROM
	[dbo].[pl_Application] pap
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_tatlogs_report_ci_sales]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_report_pl_application_get_tatlogs_report_ci_sales]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
 ROW_NUMBER() OVER (ORDER BY  ap.Received_Date ASC) AS Seq,
--ap.ApplicationNo AS [Application No],
ap.application_no AS [Application No],
--CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
CONVERT(VARCHAR(10), ap.received_date, 101) + ' ' + CONVERT(VARCHAR(8), ap.received_date, 108) as [Received Date],
--CONVERT(VARCHAR(10), ap.DecisionDate, 101) as [Date of Decision],
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [Date of Decision],

CONVERT(VARCHAR(10), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 101) + ' ' + CONVERT(VARCHAR(8), (select top 1 Action_Date FROM [LITS].[dbo].[application_action_log] al where al.fk_application_information_id = ap.pk_id and (al.[Action]='CIApproved' or al.[Action]='CIApprovedPL' or al.[Action]='CIApprovedCC'  or al.[Action]='CIApprovedBD' or al.[Action]='CIRejected' or al.[Action]='CIRejectedBD') order by action_date desc), 108) as [Date of CI Checker's final decision (Approve / Reject)],

--ap.ProductTypeName as [Product Type],
(select top(1) m.name from [m_type] m
				 where m.pk_id = ap.fk_m_type_id)  as [Product Type],
--ap.TypeApplicationName as [Application Type],
pap.type_of_application  as [Application Type],
--ap.CardProgramName as [Card Program],
'' as [Card Program],
--ap.ProgramCodeName as [Program Code],
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as [Program Code],
--ap.CardTypeName as [Card Type],
'' as [Card Type],
--ap.CardTypeName2 as [Card Type 2],
'' as [Card Type 2],
--ap.IsTwoCardType as [IsTwoCardType],
'' as [IsTwoCardType],
--CustomerSegment as [Customer Segment],
(select top(1)m.name from m_customer_segment m
				where cus.fk_customer_segment_id = m.pk_id and m.is_active = 1) as [Customer Segment],
--BankRelationship as [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],

--(CASE WHEN IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],
(CASE WHEN ci.is_staff = 1 THEN 'Yes' ELSE 'No' END) As [Is Staff],

--cc.FullName as [Primary Card Holder Full Name],
cus.full_name as [Primary Card Holder Full Name],
--cc.Nationality as [Primary Card Holder Nationality],

(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as [Primary Card Holder Nationality],
--cc.TypeEmployment as [Employment Type],
(select top(1) m.name from pl_company_information com inner join m_employment_type m
												on com.fk_m_employment_type_id = m.pk_id and m.is_active = 1
				where com.fk_customer_information_id = ci.pk_id) as [Employment Type],
--cc.CompanyName as [Company Name],
(select top(1) co.company_name from pl_company_information co
								where co.fk_pl_customer_information_id = cus.pk_id)as [Company Name],
--cc.CompanyCode as [Company Code],
(select top(1) co.company_code from company_information co
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code],
--cc.BusinessType as [Company Type],
(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id)as [Company Type],
--cc.RLSCompanyCode as [Company Code RLS],
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as [Company Code RLS],
--ap.ChannelD as [Channel],
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) AS Channel,
--ap.LocationBranchName as [Branch Location],
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1) as [Branch Location],
--ap.ARMCode as [ARM Code],
 ap.ARM_Code as [ARM Code],
--ap.[Status] as [Current Status],
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id) as [Current Status],
--ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--CONVERT(VARCHAR(10), ap.HardCopyAppDate, 101) as HardCopyAppDate,
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate,
--(select top 1 [status] from VerificationForm
--		where fk_application_information_id= ap.pk_id
--		and IsTeleVerify =1) as TeleStatus,
(select top(1) v.remark from verification_form v
				where ap.pk_id = v.fk_application_information_id and v.is_active = 1) as  TeleStatus,

--(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[cc_tat_logs] WHERE fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
(SELECT ISNULL(SUM(Duration),0) FROM [dbo].[pl_tat_logs] lg WHERE lg.fk_application_information_id= ap.pk_id and Current_Role like 'CI%') AS [Queued time at CI queue ],
--CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS [Initial Limit],
(select top(1) CONVERT(varchar, CAST(ca.holder_initial AS MONEY),1) from pl_application ca
				where ca.fk_application_information_id = ap.pk_id)AS [Initial Limit],

--CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS [Final Limit Approved],
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS [Final Limit Approved],

(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='SC')/60 as [TAT Sales Coor],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='OS')/60 as [TAT Ops Support],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI_TELE')/60 as [TAT Tele],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI1')/60 as [TAT Recommender],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role='CI2')/60 as [TAT Approver],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('CI2','CI1'))/60 as [TATA - CI],
(select sum(Duration) from pl_tat_logs where fk_application_information_id= ap.pk_id and Current_Role in ('SC','OS','CI1','CI2'))/60 as [Decision TAT]

FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
WHERE
	Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
ORDER BY Seq
GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_telephone_report_no_results]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_pl_application_gettelereportnoresults '2019-01-01','2019-04-20'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_telephone_report_no_results]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	CONVERT(VARCHAR(24),ap.Received_Date,103) as [ReceivingDate],
	CONVERT(VARCHAR(24),ap.Received_Date,108) as [ReceivingTime],
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	cc.FullName as CustomerName,
    cus.full_name as CustomerName,

	null as VerifiedID,

--	(select top 1 IdentificationNo from CCIdentification cccId 
--	 where cccId.CustomerID = ccId.CustomerID and IdentificationNo <> ''
--	 order by TypeOfIdentification) as IdentificationNo,
	(select top 1 i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id  and m.is_active=1
								
		where i.fk_customer_information_id = ci.pk_id and i.identification_no<>''
		order by m.name) as IdentificationNo,

	 null as VerifiedDOB,

--	 CONVERT(VARCHAR(24),cc.DOB,103) as DOB,
	CONVERT(VARCHAR(24),cus.dob,103) as DOB,
--	 null as VerifiedMobilephone,
	null as VerifiedMobilephone,
--	 cc.CurrentPosition,
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as CurrentPosition,

	 vf.verified_position,

--	 cc.Occupation,
	(select top(1) m.name from m_occupation m
						 where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	 vf.verifedOccupation,

--	 cc.TradingArea,
	(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

	 vf.Verified_Area,

--	 cc.RLSCompanyCode, 
	co.company_code_rls as RLSCompanyCode,
--	 cc.CompanyCode,
	co.company_code as CompanyCode,
--	 cc.CompanyName,
	 co.company_name as CompanyName,

	 vf.company_address as companyaddress,
	
	 null as VerifiedPhone,

	 null as NoAttemps,

	 vf.salary_customer as SalaryCustomer,

	 vf.bank_name as BankName,

	 vf.salary_on_date SalaryOnDate,

	 vf.salary_amount SalaryAmount,

	 CONVERT(VARCHAR(24),vf.result_dated,103)  as ResultDated,

	 vf.result_status as ResultStatus,

	 vf.is_send_sms as IsSendSMS,

	 vf.Remark,

	 vf.pk_id as VerificationID,

	 ( select top(1) m.name from m_status m
							where vf.fk_status_id = m.pk_id and m.is_active = 1) as TeleStatus,

	 vf.out_source_verify_name as VerifyName,

	 vf.updated_by as BankIDTeleVerify,

	 (
		select top 1 u.full_name from dbo.application_action_log a left join dbo.user_login u on u.Peoplewise_Id=a.Action_By
		where a.fk_application_information_id = ap.pk_id and a.Action='CI_NSG' order by a.action_date desc
	  ) NSG,

  vf.telephone_action as [Action]
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	cross apply
	(
		select top 1 * from verification_form v
		where v.fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1 and v.is_upload=1
		and v.telephone_action <> 'Completed'
	) vf
	outer apply
	(	
		select top 1 i.fk_customer_information_id, i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id 
													 and m.name in('ID','Passport','Previous_ID','Previous_PP')
								
		where i.fk_customer_information_id = ci.pk_id
		order by m.name
	) ccId
WHERE
        Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_telephone_report_none_out_source]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec sp_report_pl_application_gettelereportnoresults '2019-01-01','2019-04-20'
CREATE PROCEDURE [dbo].[sp_report_pl_application_get_telephone_report_none_out_source]
	@FromDate datetime,
	@ToDate datetime
AS

SELECT 
	CONVERT(VARCHAR(24),ap.Received_Date,103) as [ReceivingDate],
	CONVERT(VARCHAR(24),ap.Received_Date,108) as [ReceivingTime],
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	ap.ApplicationNo,
	ap.application_no as ApplicationNo,
--	ap.[Status],
	(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as [Status],
--	cc.FullName as CustomerName,
    cus.full_name as CustomerName,

	null as VerifiedID,

--	(select top 1 IdentificationNo from CCIdentification cccId 
--	 where cccId.CustomerID = ccId.CustomerID and IdentificationNo <> ''
--	 order by TypeOfIdentification) as IdentificationNo,
	(select top 1 i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id  and m.is_active=1
								
		where i.fk_customer_information_id = ci.pk_id and i.identification_no<>''
		order by m.name) as IdentificationNo,

	 null as VerifiedDOB,

--	 CONVERT(VARCHAR(24),cc.DOB,103) as DOB,
	CONVERT(VARCHAR(24),cus.dob,103) as DOB,
--	 null as VerifiedMobilephone,
	null as VerifiedMobilephone,
--	 cc.CurrentPosition,
	(select top(1)m.name from m_position m 
						where cus.fk_current_position_id = m.pk_id and m.is_active =1) as CurrentPosition,

	 vf.verified_position,

--	 cc.Occupation,
	(select top(1) m.name from m_occupation m
						 where cus.fk_occupation_id = m.pk_id and m.is_active =1) as Occupation,

	 vf.verifedOccupation,

--	 cc.TradingArea,
	(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

	 vf.Verified_Area,

--	 cc.RLSCompanyCode, 
	co.company_code_rls as RLSCompanyCode,
--	 cc.CompanyCode,
	co.company_code as CompanyCode,
--	 cc.CompanyName,
	 co.company_name as CompanyName,

	 vf.company_address as companyaddress,
	
	 null as VerifiedPhone,

	 null as NoAttemps,

	 vf.salary_customer as salarycustomer,

	 vf.bank_name as bankname,

	 vf.salary_on_date as salaryondate,

	 vf.salary_amount as salaryamount,

	 CONVERT(VARCHAR(24),vf.result_dated,103)  as ResultDated,

	 vf.result_status as resultstatus,

	 vf.is_send_sms as issendsms,

	 vf.Remark,

	 vf.pk_id as VerificationID,

	 ( select top(1) m.name from m_status m
							where vf.fk_status_id = m.pk_id and m.is_active = 1) as TeleStatus,

	 vf.out_source_verify_name as VerifyName,

	 vf.updated_by as BankIDTeleVerify,

	 (
		select top 1 u.full_name from dbo.application_action_log a left join dbo.user_login u on u.Peoplewise_Id=a.Action_By
		where a.fk_application_information_id = ap.pk_id and a.Action='CI_NSG' order by a.action_date desc
	  ) NSG,

  vf.telephone_action as [Action]
FROM
	[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	left join pl_company_information co on co.fk_customer_information_id = ci.pk_id
	cross apply
	(
		select top 1 * from verification_form v
		where v.fk_application_information_id = ap.pk_id
		and v.is_telephone_verify =1 and v.is_upload=1
	) vf
	outer apply
	(	
		select top 1 i.fk_customer_information_id, i.identification_no from customer_identification i 
													inner join  [m_identification_type] m 
													 on i.fk_m_identification_type_id = m.pk_id 
													 and m.name in('ID','Passport','Previous_ID','Previous_PP')
								
		where i.fk_customer_information_id = ci.pk_id
		order by m.name
	) ccId
WHERE
        Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)

GO
/****** Object:  StoredProcedure [dbo].[sp_report_pl_application_get_verification_report]    Script Date: 5/14/2019 3:04:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_report_pl_application_get_verification_report]
	@FromDate datetime,
	@ToDate datetime
AS
Begin

SELECT 
    ROW_NUMBER() OVER (ORDER BY  ap.received_date ASC) AS Seq,
--	ap.ApplicationNo,
    ap.application_no as ApplicationNo,
--	CONVERT(VARCHAR(24),ap.ReceivedDate,106) as ReceivedDate,
   CONVERT(VARCHAR(24),ap.received_date,106) as ReceivedDate,
--	ap.TypeApplicationName as TypeApplication,
    pap.type_of_application  as  TypeApplication,
--	cc.FullName as PrimaryCardHolderName,
cus.full_name as PrimaryCardHolderName,
--	(select top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='ID'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Passport' and CustomerID=ap.CustomerID) as PrimaryCardHolderPassportID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Passport'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPassportID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Previous_ID' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousID,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_ID'
  where cus.fk_customer_information_id = ci.pk_id) as  PrimaryCardHolderPreviousID,

--	(select  top 1 IdentificationNo from CCIdentification 
--	where CustomerType='Primary' and TypeOfIdentification='Previous_PP' and CustomerID=ap.CustomerID) as PrimaryCardHolderPreviousPP,
(select top(1) cus.identification_no
  from customer_identification cus join  [m_identification_type] m 
							on cus.fk_m_identification_type_id = m.pk_id and m.name ='Previous_PP'
  where cus.fk_customer_information_id = ci.pk_id) as PrimaryCardHolderPreviousPP,

--	cc.Nationality,
(select top(1)m.name from m_nationality m 
				where cus.fk_nationality_id = m.pk_id and m.is_active =1) as Nationality,
--	cc.BankRelationship AS [Customer Relation],
(select top(1) m.name from m_customer_relationship m
					where cus.fk_bank_relationship_id = m.pk_id) as [Customer Relation],
--	CONVERT(VARCHAR(24),cc.DOB,106) as HolderPrimaryDOB,
CONVERT(VARCHAR(24),cus.dob,106) as HolderPrimaryDOB,
--	(select (case when COUNT(*)>0 then 'Yes' else 'No' end) from FRMBlackListLog where ApplicationNo=ap.ApplicationNo and BlackListCode<>null) as BlackList,
(select  (case when COUNT(*)>0 then 'Yes' else 'No' end) 
				from frm_black_list_log frm 
				where ap.pk_id = frm.fk_application_information_id and frm.fk_frm_black_list_code_id <> null) as BlackList,
--	cc.OperationSelfEmployed as SelfEmployed,
(select top(1) m.name from  m_position m
				where cus.fk_customer_information_id = m.pk_id and m.is_active =1) as SelfEmployed,
--	cc.CompanyName as CompanyName,
(select top(1) m.company_name from m_company_list m 
				where ci.fk_company_information_id = m.pk_id) as  CompanyName,
--	cc.BusinessType as CompanyType,
(select top(1) m.name from pl_company_information co inner join m_business_nature m on
													co.fk_m_business_nature_id = m.pk_id and m.is_active = 1
								where co.fk_pl_customer_information_id = cus.pk_id) as CompanyType,
--	cc.RLSCompanyCode as RLSCompanyCode,
(select top(1)co.company_code_rls from pl_company_information co 
				where ap.pk_id = co.fk_application_information_id and co.is_active = 1) as RLSCompanyCode,
--	cc.TypeOfContract,
  
  (select top(1) m.name from m_labour_contract_type m 
				  where cus.fk_contract_type_id = m.pk_id and m.is_active =1) as TypeOfContract,
--	CONVERT(VARCHAR(24),cc.ContractStart,106) as [StartDate],
CONVERT(VARCHAR(24),cus.contract_start,106) as [StartDate],
--	cc.ContractLength,
cus.contract_length as ContractLength,
--	(SELECT TOP 1 VerifedOccupation FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedOccupation,

(SELECT TOP 1 vf.verifedOccupation FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedOccupation,

--	(SELECT TOP 1 VerifiedPosition FROM VerificationForm vf WHERE vf.ApplicationNo = ap.ApplicationNo AND vf.IsTeleVerify = 0) as VerifiedPosition,
(SELECT TOP 1 vf.verified_position FROM verification_form vf WHERE vf.fk_application_information_id = ap.pk_id AND vf.is_telephone_verify = 0) as VerifiedPosition,

--	cc.TradingArea,
(select top(1) m.name from  m_trading_area m 
				where cus.fk_trading_area_id = m.pk_id and m.is_active =1) as TradingArea,

--	cc.ResidentialCity AS [Current Address City],
(select top(1) m.name from m_city m
						 where cus.fk_residential_city_id = m.pk_id and m.is_active =1) AS [Current Address City],
--	cc.PaymentType as RepaymentType,
(select top(1) m.name from  m_payment_type m
			     where cus.fk_payment_type_id = m.pk_id and m.is_active = 1) as  RepaymentType,

--	CreditBureauType as CIC,
(select top(1)m.name from pl_customer_credit_bureau cb join m_credit_bureau_type m 
														on cb.fk_m_credit_bureau_type_id = m.pk_id and m.is_active = 1
				where cb.fk_customer_information_id = ci.pk_id) as CIC,
--	(CASE WHEN cc.IsBankStaff = 1 THEN 'Yes' ELSE 'No' END) as Staff,
(CASE WHEN ci.Is_Staff = 1 THEN 'Yes' ELSE 'No' END) as Staff,

--	CONVERT(varchar, CAST([CurrentUnsecuredOutstanding] AS MONEY), 1) AS [Current Unsecured Outstanding Off Us],
(select top(1)CONVERT(varchar, CAST(cb.current_unsecured_outstanding_off_us AS MONEY), 1) from pl_customer_credit_bureau cb
				where  cb.fk_customer_information_id = ci.pk_id) AS   [Current Unsecured Outstanding Off Us],

--	CONVERT(varchar, CAST([CurrentTotalEMI] AS MONEY), 1) AS [Current Total EMI Off Us],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_emi,0)AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id),

--	CONVERT(varchar, CAST([MonthlyIncomeDeclared] AS MONEY), 1) AS MonthlyIncomeDeclared,
(select CONVERT(varchar, CAST(inc.monthly_income_declared AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS MonthlyIncomeDeclared,
--	CONVERT(varchar, CAST([IncomeEligible] AS MONEY), 1) AS EligibleIncome,
(select CONVERT(varchar, CAST(inc.eligible_fixed_income_in_lc AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id)  AS EligibleIncome,
--	CONVERT(varchar, CAST([IncomeTotal] AS MONEY), 1) AS TotalMonthlyIncome,
(select CONVERT(varchar, CAST(inc.income_total AS MONEY), 1) from [dbo].[pl_customer_income]  as inc
				where inc.fk_application_information_id = ap.pk_id) AS TotalMonthlyIncome,

--	ap.CardTypeName as CardType,
'' as CardType,
--	ap.CardTypeName2 as [Card Type 2],
'' as [Card Type 2],
--	ap.CardProgramName as CardProgram,
'' as CardProgram,

--	(CASE WHEN ap.HolderDepositedCurrency = 'VND' THEN 'VND' ELSE 'Non-VND' END) as CurrencyDepositedAmount,
(select top(1) m.name from pl_application ca join m_definition_type m on ca.fk_holder_deposited_currency_id = m.pk_id and
																	 m.fk_group_id = 42 and m.fk_type_id = 11 and
																	 m.is_active = 1
				where ca.fk_application_information_id = ap.pk_id) as CurrencyDepositedAmount,

--	CONVERT(varchar, CAST([HolderCurrencyDepositedAmount] AS MONEY), 1) AS DespositedAmount,
  pap.holder_currency_deposited_amount  AS DespositedAmount,

--	CONVERT(varchar, CAST([HolderInitial] AS MONEY), 1) AS InitialLimit,
(select top(1) CONVERT(varchar, CAST(pap.holder_initial AS MONEY),1) ) AS InitialLimit,

--	CONVERT(varchar, CAST([FinalLimitApproved] AS MONEY), 1) AS FinalApprovedLimit,
(select top(1)CONVERT(varchar, CAST(apr.final_loan_amount_approved AS MONEY), 1)  from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS FinalApprovedLimit,
--	FinalApprovalStatus as DECISION_STATUS,
(select top(1)  m.name
				from pl_approval_information apr join m_status m on apr.fk_status_id = m.pk_id and m.is_active = 1	
				where apr.fk_application_information_id = ap.pk_id ) DECISION_STATUS,

--	(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by ActionDate desc) as Underwriter,

(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIRecommend', 'CISendBackOS', 'CISendBackSC', 'CIModified') order by action_date desc) as Underwriter,

--	(select top 1 lu.FullName from AppActionLog lg join LoginUser lu on lg.ActionBy=lu.PeoplewiseID where lg.ApplicationNo = ap.ApplicationNo and lg.[Action]  in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by ActionDate desc) as Approver,
(select top 1 lg.action_by from application_action_log lg 
						 where lg.fk_application_information_id = ap.pk_id and  lg.[Action] in ('CIApproved','CIApprovedPL', 'CIApprovedCC', 'CIApprovedBD') order by action_date desc) as Approver,

--	(SELECT TOP 1 [Level] FROM [CCCriteria] cr WHERE cr.[ApplicationNo] = ap.[ApplicationNo] ORDER BY cr.[Level] DESC ) as LevelName,
(SELECT TOP 1 m.[description] FROM [pl_criteria] cr inner join m_deviation_level m
													on cr.[fk_level_id] = m.pk_id and m.is_active =1
					WHERE cr.fk_application_information_id = ap.pk_id ORDER BY m.name DESC ) as LevelName,

--	CONVERT(VARCHAR(24),DecisionDate,106) as Final_DecisionDate,
(select top(1)  CONVERT(VARCHAR(24),apr.decision_date,106) 
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id)  as Final_DecisionDate,
--	(case when RejectReasonID is null then CancelReasonID else RejectReasonID end) as Rejected_Or_Cancelled_Reason,
(select top(1) m.name from m_reason m
				 where m.pk_id = ap.fk_m_reason_rework_id and m.fk_group_id in(83, 84) and (m.name <> '' or m.name is not null)) as  Rejected_Or_Cancelled_Reason,
--	FinalMUEAtSCB, final_mue_at_scb
'' as FinalMUEAtSCB,
--	MUE_CC,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.mue,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as MUE_CC,

--	CONVERT(varchar, CAST([FinalTotalEMI] AS MONEY), 1) AS TotalEMI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_emi,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) AS  TotalEMI,
--	FinalTotalDSR as [TotalDSR %],
(select top(1)CONVERT(varchar, CAST(Isnull(apr.total_dsr,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as [TotalDSR %],
--	FinalDTI as DTI,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.dti,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as DTI,
--	FinalLTV as TotalLTV,
(select top(1)CONVERT(varchar, CAST(Isnull(apr.ltv,0) AS MONEY), 1)  
				from pl_approval_information apr
				where apr.fk_application_information_id = ap.pk_id) as TotalLTV,

--	ap.Status as CurrentStatus,
(select top(1) m.name from m_status m where ap.fk_m_status_id = m.pk_id)  as CurrentStatus,
--	ap.ProgramCodeName as ProgramCode,
(select top(1) m.name from m_program_code m
		  where m.pk_id = ap.fk_m_program_code_id) as  ProgramCode,
--	PIDOfSaleStaff as SaleCode,
ap.sale_staff_bank_id as SaleCode,
--	ARMCode,
ap.arm_code as ARMCode,
--	ChannelD as Channel,
(select top(1) m.name from m_sales_channel m
				where ap.fk_m_sales_channel_id = m.pk_id and m.is_active = 1) as Channel,
--	LocationBranchName as BranchLocation,
(select top(1) m.name from m_branch_location m
					  where ap.fk_m_branch_location_id = m.pk_id and m.is_active = 1)as BranchLocation,

--	(select top 1 Remark from CCRemark where ApplicationNo=ap.ApplicationNo order by CreatedDate) as Remark,
pap.remark as Remark,
--	ap.EOpsTxnRefNo,
ap.eops_txn_ref_no_1 as EOpsTxnRefNo,
--	ap.IsTwoCardType as [IsTwoCardType],
'' as [IsTwoCardType],
--	ap.HardCopyAppDate
CONVERT(VARCHAR(10), ap.hard_copy_app_date, 101) as HardCopyAppDate
	FROM
		[dbo].[pl_application] pap 
	inner join application_information ap on ap.pk_id = pap.fk_application_information_id
	inner join pl_customer_information cus on cus.fk_application_information_id = ap.pk_id
	inner join customer_information ci on ci.pk_id = cus.fk_customer_information_id
	
	WHERE
		Cast(ap.received_date as date) >= Cast(@FromDate as date)
	and Cast(ap.received_date as date) <= Cast(@ToDate as date)
	ORDER BY Seq
END
GO
