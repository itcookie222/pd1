USE [LITSUATHISTORY]
GO
/****** Object:  Table [dbo].[_audit_bil_application]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Drop table [dbo].[_audit_bil_application]
GO
CREATE TABLE [dbo].[_audit_bil_application](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[fk_m_loan_tenor_id] [int] NULL,
	[fk_m_program_type_id] [int] NULL,
	[fk_m_floating_interest_rate_id] [int] NULL,
	[fk_m_loan_purpose_id] [int] NULL,
	[fk_repayment_type_id] [int] NULL,
	[fk_m_payment_type_id] [int] NULL,
	[fk_m_campaign_code_id] [int] NULL,
	[fk_m_credit_deviation_id] [int] NULL,
	[fk_m_reason_for_deviation_id] [int] NULL,
	[total_income] [decimal](18, 4) NULL,
	[ltv] [decimal](18, 4) NULL,
	[dsr] [decimal](18, 4) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_type_of_application_id] [int] NULL,
	[queued_date] [datetime] NULL,
	[loan_tenor_applied] [int] NULL,
	[loan_amount_applied] [decimal](18, 4) NULL,
	[exisiting_account_number] [nvarchar](500) NULL,
	[date_of_monthly_repayment] [int] NULL,
	[fk_level_approval_id] [int] NULL,
	[floating_interest_rate] [decimal](18, 4) NULL,
	[is_deviation_flag] [bit] NULL,
	[remark] [nvarchar](2000) NULL,
	[fk_copy_from_application_id] [int] NULL,
	[warning_message] [nvarchar](2000) NULL,
	[error_message] [nvarchar](2000) NULL,
	[special_code] [nvarchar](500) NULL,
	[sc_remark] [nvarchar](2000) NULL,
	[ops_remark] [nvarchar](2000) NULL,
	[ci_remark] [nvarchar](2000) NULL,
	[eb_cs_code] [nvarchar](500) NULL,
 CONSTRAINT [PK_audit_bil_application] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_approval_disbursement_condition]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_approval_disbursement_condition](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_approval_information_id] [int] NULL,
	[fk_bil_approval_information_id] [int] NULL,
	[fk_m_disbursal_scenario_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[remark] [nvarchar](4000) NULL,
	[condition_other] [nvarchar](4000) NULL,
	[condition_1] [nvarchar](4000) NULL,
	[condition_2] [nvarchar](4000) NULL,
	[condition_3] [nvarchar](4000) NULL,
	[condition_4] [nvarchar](4000) NULL,
	[condition_5] [nvarchar](4000) NULL,
	[condition_6] [nvarchar](4000) NULL,
	[condition_7] [nvarchar](4000) NULL,
	[condition_8] [nvarchar](4000) NULL,
	[condition_9] [nvarchar](4000) NULL,
	[condition_10] [nvarchar](4000) NULL,
	[condition_11] [nvarchar](4000) NULL,
	[condition_12] [nvarchar](4000) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_approval_disbursement_condition] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_approval_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_approval_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_approval_information_id] [int] NULL,
	[fk_m_payment_option_id] [int] NULL,
	[fk_m_payment_type_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[arta_credit_life] [decimal](18, 4) NULL,
	[application_number] [nvarchar](50) NULL,
	[life_assured] [decimal](18, 4) NULL,
	[applied_sum_assured] [decimal](18, 4) NULL,
	[applied_premium] [decimal](18, 4) NULL,
	[mrta_amount] [decimal](18, 4) NULL,
	[loan_amt_with_mrta] [decimal](18, 4) NULL,
	[ltv_percent_with_mrta] [decimal](18, 4) NULL,
	[emi_with_mrta] [decimal](18, 4) NULL,
	[emi_with_mrta_percent_added] [decimal](18, 4) NULL,
	[dbr_with_mrta_percent_added] [decimal](18, 4) NULL,
	[fk_decision_status_id] [int] NULL,
	[date_of_decision] [datetime] NULL,
	[fk_reject_reason_id] [int] NULL,
	[fk_cancel_reason_id] [int] NULL,
	[remark] [nvarchar](2000) NULL,
	[fk_final_case_deviation_id] [int] NULL,
	[total_on_us_emi] [decimal](18, 4) NULL,
	[total_off_us_emi] [decimal](18, 4) NULL,
	[total_on_us_and_off_us_emi] [decimal](18, 4) NULL,
	[total_off_us_outstanding] [decimal](18, 4) NULL,
	[total_on_us_outstanding] [decimal](18, 4) NULL,
	[total_on_us_and_off_us_outstanding] [decimal](18, 4) NULL,
	[loan_amount_approved_aip] [decimal](18, 4) NULL,
	[tenor_approved_aip] [decimal](18, 4) NULL,
	[commercial_interest] [decimal](18, 4) NULL,
	[emi_com_int] [decimal](18, 4) NULL,
	[percentage_added] [decimal](18, 4) NULL,
	[emi_percentage_added] [decimal](18, 4) NULL,
	[dbr_percentage_added] [decimal](18, 4) NULL,
	[ltv_aip] [decimal](18, 4) NULL,
	[total_exposure] [decimal](18, 4) NULL,
	[total_emi] [decimal](18, 4) NULL,
	[approver_comments] [nvarchar](2000) NULL,
	[pre_disbursement_conditions] [nvarchar](2000) NULL,
	[disbursement_conditions] [nvarchar](2000) NULL,
	[post_disbursement_conditions] [nvarchar](2000) NULL,
	[is_arta] [bit] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[loan_amount_approved] [decimal](18, 4) NULL,
	[loan_tenor_approved] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_approval_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_card_bureau]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_card_bureau](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_credit_bureau_id] [int] NULL,
	[fk_bil_customer_credit_bureau_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_company_obligation_id] [int] NULL,
	[fk_bil_company_obligation_id] [int] NULL,
	[secured_type] [nvarchar](50) NULL,
	[group_loan_name] [nvarchar](500) NULL,
	[no_of_delinquency] [int] NULL,
	[initial_loan] [decimal](18, 4) NULL,
	[interest_rate] [decimal](18, 4) NULL,
	[outstanding] [decimal](18, 4) NULL,
	[emi] [decimal](18, 4) NULL,
	[source] [nvarchar](50) NULL,
	[fk_m_tenor_id] [int] NULL,
	[bank] [nvarchar](500) NULL,
	[is_auto_cal_emi] [bit] NULL,
	[is_scb_card] [bit] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[date_of_cic_results] [datetime] NULL,
	[total_limit] [decimal](18, 4) NULL,
	[percent_current_card_utilization] [decimal](18, 4) NULL,
	[percent_utilization_ratio_benchmark] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_card_bureau] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_collateral_appraisal_detail]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_collateral_appraisal_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_collateral_information_id] [int] NULL,
	[fk_bil_collateral_information_id] [int] NULL,
	[fk_bil_collateral_appraisal_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_collateral_id] [int] NULL,
	[fk_collateral_type_id] [int] NULL,
	[fk_valuer_name_id] [int] NULL,
	[date_of_valuation_report] [datetime] NOT NULL,
	[unit_price_land] [decimal](18, 4) NULL,
	[appraisal_land_value] [decimal](18, 4) NULL,
	[unit_price_construction] [decimal](18, 4) NULL,
	[appraisal_construction_value] [decimal](18, 4) NULL,
	[appraisal_final_value] [decimal](18, 4) NULL,
	[discount] [decimal](18, 4) NULL,
	[final_collateral_value] [decimal](18, 4) NULL,
	[describe_current_status] [nvarchar](500) NULL,
	[is_company_premise_office] [bit] NULL,
	[percentage_of_company_premise_office] [decimal](18, 4) NULL,
	[fk_residential_utilization_purpose_id] [int] NULL,
	[percentage_of_residential_utilization purpose] [decimal](18, 4) NULL,
	[fk_commercial_utilization_purpose_id] [int] NULL,
	[percentage_of_commercial_utilization_purpose] [decimal](18, 4) NULL,
	[other_utilization_purpose] [nvarchar](500) NULL,
	[percentage_of_other_utilization_purpose] [decimal](18, 4) NULL,
	[remark] [nvarchar](500) NULL,
	[fk_ligitimate_note_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_collateral_appraisal_detail] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_collateral_appraisal_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_collateral_appraisal_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_collateral_information_id] [int] NULL,
	[fk_bil_collateral_information_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_collateral_id] [int] NULL,
	[fk_collateral_type_id] [int] NULL,
	[land_area] [decimal](18, 4) NULL,
	[residential_area] [decimal](18, 4) NULL,
	[non_residential_area] [decimal](18, 4) NULL,
	[other_land_area] [decimal](18, 4) NULL,
	[construction_area] [decimal](18, 4) NULL,
	[total_construction_area] [decimal](18, 4) NULL,
	[remark] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_collateral_appraisal_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_collateral_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_collateral_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_collateral_information_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_collateral_id] [int] NULL,
	[fk_collateral_type_id] [int] NULL,
	[fk_property_type_id] [int] NULL,
	[fk_property_status_id] [int] NULL,
	[address_no] [nvarchar](2000) NULL,
	[address_street] [nvarchar](2000) NULL,
	[address_ward] [nvarchar](500) NULL,
	[fk_m_district_id] [int] NULL,
	[address_district] [nvarchar](500) NULL,
	[fk_m_city_id] [int] NULL,
	[address_city] [nvarchar](500) NULL,
	[fk_title_deed_no_id] [int] NULL,
	[sp_contract_no] [nvarchar](500) NULL,
	[collateral_owner] [nvarchar](500) NULL,
	[fk_developer_code_id] [int] NULL,
	[developer_name] [nvarchar](500) NULL,
	[fk_project_code_id] [int] NULL,
	[project_name] [nvarchar](500) NULL,
	[fk_guarantor_relationship_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_collateral_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_collateral_owner]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_collateral_owner](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_collateral_information_id] [int] NULL,
	[fk_bil_collateral_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_collateral_id] [int] NULL,
	[fk_collateral_type_id] [int] NULL,
	[owner_name] [nvarchar](500) NULL,
	[owner_id_card] [nvarchar](500) NULL,
	[year_of_birth] [int] NULL,
 CONSTRAINT [PK_audit_bil_collateral_owner] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_company_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_company_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_company_income_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_m_company_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[remark] [nvarchar](2000) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[fk_m_trading_area_id] [int] NULL,
	[company_income] [decimal](18, 4) NULL,
	[company_other_income] [decimal](18, 4) NULL,
	[total_company_income] [decimal](18, 4) NULL,
	[fk_m_borrower_type_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_company_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_company_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_company_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_bil_customer_salaried_income_id] [int] NULL,
	[fk_bil_customer_seft_employed_income_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[company_code] [nvarchar](50) NULL,
	[company_name] [nvarchar](500) NULL,
	[company_address] [nvarchar](500) NULL,
	[company_ward] [nvarchar](500) NULL,
	[fk_company_district_id] [int] NULL,
	[fk_company_city_id] [int] NULL,
	[office_telephone] [nvarchar](50) NULL,
	[business_licence_number] [nvarchar](50) NULL,
	[tax_code] [nvarchar](50) NULL,
	[company_cat] [nvarchar](50) NULL,
	[fk_main_company_industry_1_id] [int] NULL,
	[fk_main_company_industry_2_id] [int] NULL,
	[fk_other_company_industry_id] [int] NULL,
	[fk_seasonal_industry_id] [int] NULL,
	[established_year] [datetime] NULL,
	[total_years_in_operation] [int] NULL,
	[percent_shareholding_in_company] [decimal](18, 4) NULL,
	[profit_loss_in_latest_year] [decimal](18, 4) NULL,
	[fk_type_of_self_employment_income_id] [int] NULL,
	[company_code_rls] [nvarchar](50) NULL,
	[is_clean_eb] [bit] NULL,
	[fk_clean_eb_id] [int] NULL,
	[fk_m_business_nature_id] [int] NULL,
	[fk_m_industry_id] [int] NULL,
	[fk_m_occupation_id] [int] NULL,
	[fk_m_position_id] [int] NULL,
	[fk_m_employment_type_id] [int] NULL,
	[fk_company_location_id] [int] NULL,
	[company_remark] [nvarchar](2000) NULL,
	[fk_m_company_list_id] [int] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_company_type_id] [int] NULL,
	[company_short_name] [nvarchar](500) NULL,
	[investment_code] [nvarchar](500) NULL,
	[date_of_incorporate] [datetime] NULL,
	[latest_date_update_on_bl] [datetime] NULL,
	[number_of_update_on_bl] [int] NULL,
	[registered_capital] [nvarchar](500) NULL,
	[number_of_banks_relationship] [int] NULL,
	[business_registration_number] [nvarchar](500) NULL,
	[fk_customer_relationship_id] [int] NULL,
	[fk_industry_isic_1_id] [int] NULL,
	[fk_industry_isic_2_id] [int] NULL,
	[fk_industry_isic_other_id] [int] NULL,
	[fk_billing_address_id] [int] NULL,
	[fk_trading_area_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_company_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_company_obligation]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_company_obligation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_company_obligation_id] [int] NULL,
	[fk_m_credit_bureau_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[remark] [nvarchar](2000) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[total_loan_emi] [decimal](18, 4) NULL,
	[total_credit_card_emi] [decimal](18, 4) NULL,
	[total_outstanding_balance_credit_card] [decimal](18, 4) NULL,
	[total_limit_credit_card] [decimal](18, 4) NULL,
	[total_percent_current_card_utilization] [decimal](18, 4) NULL,
	[total_emi] [decimal](18, 4) NULL,
	[fk_bureau_data_loan_current_id] [int] NULL,
	[fk_bureau_data_loan_history_id] [int] NULL,
	[fk_bureau_data_card_current_id] [int] NULL,
	[fk_bureau_data_dard_history_id] [int] NULL,
	[is_auto_calculation_emi] [bit] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_company_type_id] [int] NULL,
	[total_on_us_exposure] [decimal](18, 4) NULL,
	[total_off_us_exposure] [decimal](18, 4) NULL,
	[mue] [decimal](18, 4) NULL,
	[dti] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_company_obligation] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_company_other_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_company_other_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_company_income_id] [int] NULL,
	[fk_bil_company_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[discount_rate] [decimal](18, 4) NULL,
	[income_order] [int] NULL,
	[date_of_bank_statement] [datetime] NULL,
	[remark] [nvarchar](2000) NULL,
	[other_income] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_company_other_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_company_seft_employed_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_company_seft_employed_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_company_income_id] [int] NULL,
	[fk_bil_company_income_id] [int] NULL,
	[fk_m_company_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[income_order] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[total_turnover_in_fs] [decimal](18, 4) NULL,
	[monthly_turnover_in_year] [decimal](18, 4) NULL,
	[igm_vat_date_of_bank_statement] [datetime] NULL,
	[igm_vat_is_validity] [bit] NULL,
	[igm_vat_average_monthly_updated_turnover] [decimal](18, 4) NULL,
	[igm_vat_compared_with_turnover] [decimal](18, 4) NULL,
	[igm_vat_average_monthly_turnover] [decimal](18, 4) NULL,
	[igm_vat_monthly_company_profit] [decimal](18, 4) NULL,
	[igm_vat_customer_monthly_self_employed_income] [decimal](18, 4) NULL,
	[igm_vat_sum_of_monthly_turnover_via_bank_statement] [decimal](18, 4) NULL,
	[igm_vat_percentage_income_via_bank_statement] [decimal](18, 4) NULL,
	[igm_vat_remark] [nvarchar](2000) NULL,
	[cpp_profit_after_tax_pat] [decimal](18, 4) NULL,
	[cpp_depreciation_amount] [decimal](18, 4) NULL,
	[cpp_monthly_company_profit] [decimal](18, 4) NULL,
	[cpp_customer_monthly_self_employed_income] [decimal](18, 4) NULL,
	[cpp_remark] [nvarchar](500) NULL,
	[cpp_date_of_bank_statement] [datetime] NULL,
	[cpp_is_validity] [bit] NULL,
	[remark] [nvarchar](2000) NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[igm_vat_total_updated_turnover] [decimal](18, 4) NULL,
	[cpp_monthly_turnover_in_year] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_company_seft_employed_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_current_on_us_monthly_emi]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_current_on_us_monthly_emi](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[fk_emi_type_id] [int] NULL,
	[loan_account_no] [nvarchar](50) NULL,
	[remark] [nvarchar](2000) NULL,
	[total_on_us_emi] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_current_on_us_monthly_emi] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_current_out_standing]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_current_out_standing](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[fk_out_standing_type_id] [int] NULL,
	[loan_account_no] [nvarchar](50) NULL,
	[remark] [nvarchar](2000) NULL,
	[total_on_us_outstanding] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_current_out_standing] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_aum_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_aum_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NOT NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[income_order] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[date_of_bank_statement] [datetime] NULL,
	[average_monthly_balance] [decimal](18, 4) NULL,
	[average_monthly_income] [decimal](18, 4) NULL,
	[average_monthly_balance_in_last_180_days_1] [decimal](18, 4) NULL,
	[average_monthly_balance_in_last_180_days_2] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_1] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_2] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_3] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_4] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_5] [decimal](18, 4) NULL,
	[average_monthly_balance_in_month_6] [decimal](18, 4) NULL,
	[remark] [nvarchar](500) NULL,
	[beginning_date] [datetime] NULL,
	[latest_date] [datetime] NULL,
	[discount_rate] [decimal](18, 4) NULL,
	[average_monthly_balance_in_last_6_months] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_customer_aum_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_credit_bureau]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_credit_bureau](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_credit_bureau_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_credit_bureau_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[remark] [nvarchar](2000) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[total_loan_emi] [decimal](18, 4) NULL,
	[total_credit_card_emi] [decimal](18, 4) NULL,
	[total_outstanding_balance_credit_card] [decimal](18, 4) NULL,
	[total_limit_credit_card] [decimal](18, 4) NULL,
	[total_percent_current_card_utilization] [decimal](18, 4) NULL,
	[total_emi] [decimal](18, 4) NULL,
	[fk_bureau_data_loan_current_id] [int] NULL,
	[fk_bureau_data_loan_history_id] [int] NULL,
	[fk_bureau_data_card_current_id] [int] NULL,
	[fk_bureau_data_card_history_id] [int] NULL,
	[is_auto_calculation_emi] [bit] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_cdd_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_customer_credit_bureau] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[remark] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[total_borrower_income] [decimal](18, 4) NULL,
	[fk_m_trading_area_id] [int] NULL,
	[total_borrower_salaried_income] [decimal](18, 4) NULL,
	[total_borrower_rental_income] [decimal](18, 4) NULL,
	[total_borrower_car_rental_income] [decimal](18, 4) NULL,
	[total_borrower_self_employed_income] [decimal](18, 4) NULL,
	[total_borrower_other_income] [decimal](18, 4) NULL,
	[average_borrower_aum_income] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_customer_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_income_monthly]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_income_monthly](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_bil_customer_rental_income_id] [int] NULL,
	[fk_bil_customer_salaried_income_id] [int] NULL,
	[fk_bil_customer_seft_employed_income_id] [int] NULL,
	[fk_bil_customer_other_income_id] [int] NULL,
	[fk_bil_customer_aum_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[monthly] [decimal](18, 4) NULL,
	[remark] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[first_time] [decimal](18, 4) NULL,
	[second_time] [decimal](18, 4) NULL,
	[third_time] [decimal](18, 4) NULL,
	[input_verification] [nvarchar](50) NULL,
	[fourth_time] [decimal](18, 4) NULL,
	[fifth_time] [decimal](18, 4) NULL,
	[from_date] [datetime] NULL,
	[to_date] [datetime] NULL,
	[free_balance] [decimal](18, 4) NULL,
	[beginning_date] [datetime] NULL,
	[latest_date] [datetime] NULL,
	[average_monthly_balance] [decimal](18, 4) NULL,
	[total_deduction_amount] [decimal](18, 4) NULL,
	[total_credit_in_balance] [decimal](18, 4) NULL,
	[eligible_credit_in] [decimal](18, 4) NULL,
	[discount_rate] [decimal](18, 4) NULL,
	[average_income] [decimal](18, 4) NULL,
	[fk_input_verification_id] [int] NULL,
	[date_of_bank_statement] [datetime] NULL,
	[account] [nvarchar](50) NULL,
	[balance] [decimal](18, 4) NULL,
	[deduction] [decimal](18, 4) NULL,
	[total_monthly_turnover] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_customer_income_monthly] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[created_date] [datetime] NULL,
	[created_by] [nvarchar](50) NULL,
	[is_active] [bit] NULL,
	[remark] [nvarchar](2000) NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_initital_id] [int] NULL,
	[fk_gender_id] [int] NULL,
	[fk_billing_address_id] [int] NULL,
	[fk_position_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_customer_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_interview]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_interview](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_application_verification_id] [int] NULL,
	[name] [nvarchar](500) NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[remarks] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_customer_interview] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_other_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_other_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[discount_rate] [decimal](18, 4) NULL,
	[income_order] [int] NULL,
	[date_of_bank_statement] [datetime] NULL,
	[remark] [nvarchar](2000) NULL,
	[other_income] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_customer_other_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_rental_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_rental_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[is_active] [bit] NULL,
	[details_of_property_for_rent] [nvarchar](500) NULL,
	[rental_property_ownership_name] [nvarchar](500) NULL,
	[lessee_name_address_contact] [nvarchar](500) NULL,
	[rental_property_address] [nvarchar](500) NULL,
	[rental_property_ward] [nvarchar](500) NULL,
	[fk_rental_property_district_id] [int] NULL,
	[fk_rental_property_city_id] [int] NULL,
	[rental_contract_tenure] [nvarchar](50) NULL,
	[monthly_rental_fee] [decimal](18, 4) NULL,
	[fk_rental_purpose_id] [nvarchar](500) NULL,
	[repayment_cycle] [decimal](18, 4) NULL,
	[total_rental_income] [decimal](18, 4) NULL,
	[fk_m_payment_method_id] [int] NULL,
	[income_order] [int] NULL,
	[date_of_bank_statement] [datetime] NULL,
	[total_income_before_dr] [decimal](18, 4) NULL,
	[total_income_after_dr] [decimal](18, 4) NULL,
	[remark] [nvarchar](500) NULL,
	[fk_repayment_cycle_id] [int] NULL,
	[discount_rate] [decimal](18, 4) NULL,
	[total_rental_income_before_discount_rate] [decimal](18, 4) NULL,
	[total_rental_income_after_discount_rate] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_customer_rental_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_salaried_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_salaried_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[working_address] [nvarchar](500) NULL,
	[working_ward] [nvarchar](500) NULL,
	[fk_working_district_id] [int] NULL,
	[fk_working_city_id] [int] NULL,
	[percent_shares_in_company] [decimal](18, 4) NULL,
	[fk_m_labour_contract_type_id] [int] NULL,
	[contract_length] [int] NULL,
	[start_date_at_current_company] [datetime] NULL,
	[total_months_in_current_company] [int] NULL,
	[total_months_in_working_experience] [int] NULL,
	[monthly_income] [decimal](18, 4) NULL,
	[freelance_income] [decimal](18, 4) NULL,
	[gross_base_salary] [decimal](18, 4) NULL,
	[basic_allowance] [decimal](18, 4) NULL,
	[eligible_fixed_income_on_lc] [decimal](18, 4) NULL,
	[fixed_income_via_bs] [decimal](18, 4) NULL,
	[total_monthly_income_via_bs] [decimal](18, 4) NULL,
	[performance_bonus] [decimal](18, 4) NULL,
	[final_income] [decimal](18, 4) NULL,
	[income_order] [int] NULL,
	[date_of_bank_statement] [datetime] NULL,
	[remark] [nvarchar](2000) NULL,
	[fk_period_of_submitted_bs_id] [int] NULL,
	[labor_contract_13th_salary] [decimal](18, 4) NULL,
	[fk_payment_method_id] [int] NULL,
	[monthly_income_from_base_salary] [decimal](18, 4) NULL,
	[monthly_income_from_bonus] [decimal](18, 4) NULL,
	[average_income_via_bank_statement] [decimal](18, 4) NULL,
	[is_freelance] [bit] NULL,
	[eligible_monthly_income] [decimal](18, 4) NULL,
	[date_of_confirmation_letter] [datetime] NULL,
	[average_income_by_cash] [decimal](18, 4) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_customer_salaried_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_customer_seft_employed_income]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_customer_seft_employed_income](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[income_order] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[total_turnover_in_fs] [decimal](18, 4) NULL,
	[monthly_turnover_in_year] [decimal](18, 4) NULL,
	[igm_vat_date_of_bank_statement] [datetime] NULL,
	[igm_vat_is_validity] [bit] NULL,
	[igm_vat_average_monthly_updated_turnover] [decimal](18, 4) NULL,
	[igm_vat_compared_with_turnover] [decimal](18, 4) NULL,
	[igm_vat_average_monthly_turnover] [decimal](18, 4) NULL,
	[igm_vat_monthly_company_profit] [decimal](18, 4) NULL,
	[igm_vat_customer_monthly_self_employed_income] [decimal](18, 4) NULL,
	[igm_vat_remark] [nvarchar](2000) NULL,
	[igm_bs_date_of_bank_statement] [datetime] NULL,
	[igm_bs_is_validity] [bit] NULL,
	[igm_bs_average_eligible_credit_balance] [decimal](18, 4) NULL,
	[igm_bs_other_monthly_turnover] [decimal](18, 4) NULL,
	[igm_bs_total_eligible_monthly_income] [decimal](18, 4) NULL,
	[igm_bs_compared_with_turnover] [decimal](18, 4) NULL,
	[igm_bs_average_monthly_turnover] [decimal](18, 4) NULL,
	[igm_bs_monthly_company_profit] [decimal](18, 4) NULL,
	[igm_bs_customer_monthly_self_employed_income] [decimal](18, 4) NULL,
	[igm_bs_remark] [nvarchar](2000) NULL,
	[cpp_profit_after_tax_pat] [decimal](18, 4) NULL,
	[cpp_depreciation_amount] [decimal](18, 4) NULL,
	[cpp_monthly_company_profit] [decimal](18, 4) NULL,
	[cpp_customer_monthly_self_employed_income] [decimal](18, 4) NULL,
	[cpp_remark] [nvarchar](500) NULL,
	[cpp_date_of_bank_statement] [datetime] NULL,
	[cpp_is_validity] [bit] NULL,
	[remark] [nvarchar](2000) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[igm_vat_sum_of_monthly_turnover_via_bank_statement] [decimal](18, 4) NULL,
	[igm_vat_percentage_income_via_bank_statement] [decimal](18, 4) NULL,
	[igm_vat_total_updated_turnover] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_customer_seft_employed_income] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_deviation]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_deviation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_m_credit_deviation_id] [int] NULL,
	[fk_m_reason_deviation_id] [int] NULL,
	[remark_deviation] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_deviation] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_disbursement_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_disbursement_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_disbursement_information_id] [int] NULL,
	[fk_m_customer_relationship_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[remark] [nvarchar](2000) NULL,
	[disbursed_date] [datetime] NULL,
	[disbursed_amount] [decimal](18, 4) NULL,
	[loan_account_number] [nvarchar](50) NULL,
	[insurance_company_name] [nvarchar](500) NULL,
	[insurance_amount] [decimal](18, 4) NULL,
	[insurance_expiry_date] [datetime] NULL,
	[post_disbursement_condition_expiry_date] [datetime] NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_disbursement_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_industry_margin]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_industry_margin](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_customer_income_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_company_income_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_bil_customer_income_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_bil_company_income_id] [int] NULL,
	[fk_bil_customer_seft_employed_income_id] [int] NULL,
	[fk_bil_company_seft_employed_income_id] [int] NULL,
	[fk_m_borrower_type_id] [int] NULL,
	[fk_m_company_type_id] [int] NULL,
	[fk_m_income_type_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[remark] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[fk_m_industry_id] [int] NULL,
	[percentage_on_turnover] [decimal](18, 4) NULL,
	[industrial_margin] [decimal](18, 4) NULL,
	[total_monthly_turnover] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_industry_margin] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_loan_bureau]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_loan_bureau](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_customer_credit_bureau_id] [int] NULL,
	[fk_bil_customer_credit_bureau_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_company_obligation_id] [int] NULL,
	[fk_bil_company_obligation_id] [int] NULL,
	[secured_type] [nvarchar](50) NULL,
	[group_loan_name] [nvarchar](500) NULL,
	[no_of_delinquency] [int] NULL,
	[initial_loan] [decimal](18, 4) NULL,
	[interest_rate] [decimal](18, 4) NULL,
	[outstanding] [decimal](18, 4) NULL,
	[emi] [decimal](18, 4) NULL,
	[source] [nvarchar](50) NULL,
	[fk_m_tenor_id] [int] NULL,
	[bank] [nvarchar](500) NULL,
	[is_auto_cal_emi] [bit] NULL,
	[is_scb_loan] [bit] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[date_of_cic_results] [datetime] NULL,
	[total_limit] [decimal](18, 4) NULL,
 CONSTRAINT [PK_audit_bil_loan_bureau] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_purchasing_property_information]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_purchasing_property_information](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[fk_company_information_id] [int] NULL,
	[fk_bil_company_information_id] [int] NULL,
	[fk_collateral_information_id] [int] NULL,
	[fk_purchasing_property_information_id] [int] NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[fk_m_collateral_id] [int] NULL,
	[fk_property_type_id] [int] NULL,
	[fk_property_status_id] [int] NULL,
	[fk_developer_code_id] [int] NULL,
	[developer_name] [nvarchar](500) NULL,
	[fk_project_code_id] [int] NULL,
	[project_name] [nvarchar](500) NULL,
	[address_no] [nvarchar](2000) NULL,
	[address_street] [nvarchar](2000) NULL,
	[address_ward] [nvarchar](500) NULL,
	[fk_m_district_id] [int] NULL,
	[address_district] [nvarchar](500) NULL,
	[fk_m_city_id] [int] NULL,
	[address_city] [nvarchar](500) NULL,
	[fk_title_deed_no_id] [int] NULL,
	[sp_contract_no] [nvarchar](500) NULL,
	[property_owner] [nvarchar](500) NULL,
	[purchasing_price] [decimal](18, 4) NULL,
	[property_transaction_price] [decimal](18, 4) NULL,
	[property_code] [nvarchar](500) NULL,
	[remark] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_purchasing_property_information] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_rework]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_rework](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_m_rework_reason_id] [int] NULL,
	[remark] [nvarchar](50) NULL,
	[remark_response] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[send_back_date] [datetime] NULL,
	[send_back_by] [nvarchar](50) NULL,
	[received_date] [datetime] NULL,
	[received_by] [nvarchar](50) NULL,
	[response_date] [datetime] NULL,
	[user_type] [nvarchar](50) NULL,
	[log_type] [nvarchar](50) NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_rework] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_send_back]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_send_back](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_send_back_reason_id] [int] NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[send_back_date] [datetime] NULL,
	[send_back_by] [nvarchar](50) NULL,
	[received_date] [datetime] NULL,
	[received_by] [nvarchar](50) NULL,
	[response_date] [datetime] NULL,
	[response_by] [nvarchar](50) NULL,
	[user_type] [nvarchar](50) NULL,
	[log_type] [nvarchar](50) NULL,
	[fk_queue_send_back_id] [int] NULL,
	[queue_send_back] [nvarchar](50) NULL,
	[fk_queue_response_id] [int] NULL,
	[queue_response] [nvarchar](50) NULL,
	[remark_send_back] [nvarchar](2000) NULL,
	[remark_response] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_send_back] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_site_visit_result]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_site_visit_result](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_application_site_visit_result_id] [int] NULL,
	[name] [nvarchar](500) NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[checked_by] [nvarchar](50) NULL,
	[checked_date] [datetime] NULL,
	[fk_criteria_id] [int] NULL,
	[request_date] [datetime] NULL,
	[customer_name] [nvarchar](50) NULL,
	[company_name] [nvarchar](500) NULL,
	[customer_id] [nvarchar](50) NULL,
	[tax_code] [nvarchar](50) NULL,
	[application_number] [nvarchar](50) NULL,
	[customer_phone] [nvarchar](50) NULL,
	[content_to_check] [nvarchar](500) NULL,
	[contact_person] [nvarchar](500) NULL,
	[full_address] [nvarchar](500) NULL,
	[number_street] [nvarchar](500) NULL,
	[ward] [nvarchar](500) NULL,
	[fk_district_id] [int] NULL,
	[fk_city_id] [int] NULL,
	[requester] [nvarchar](50) NULL,
	[site_visitor] [nvarchar](50) NULL,
	[site_visit_date] [datetime] NULL,
	[site_visit_result] [nvarchar](2000) NULL,
	[remarks] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_site_visit_result] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_tat_logs]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_tat_logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[action] [nvarchar](50) NULL,
	[action_date] [datetime] NULL,
	[action_by] [nvarchar](50) NULL,
	[current_role] [nvarchar](50) NULL,
	[duration] [decimal](18, 4) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
 CONSTRAINT [PK_audit_bil_tat_logs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_telephone_verification]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_telephone_verification](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_application_verification_id] [int] NULL,
	[name] [nvarchar](500) NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[remarks] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_telephone_verification] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_verification_phone]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_verification_phone](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_bil_application_information_id] [int] NOT NULL,
	[fk_application_verification_id] [int] NULL,
	[name] [nvarchar](500) NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[phone_type] [nvarchar](50) NULL,
	[contact_no] [nvarchar](50) NULL,
	[is_source_internal] [bit] NULL,
	[is_yellow_page] [bit] NULL,
	[is_operator] [bit] NULL,
	[is_website] [bit] NULL,
	[is_able_to_contact] [bit] NULL,
	[who_answered] [nvarchar](50) NULL,
	[is_confimation] [bit] NULL,
	[checking_date] [datetime] NULL,
	[checking_time] [time](7) NULL,
	[hr_contact] [nvarchar](50) NULL,
	[hr_comments] [nvarchar](50) NULL,
	[remarks] [nvarchar](2000) NULL,
 CONSTRAINT [PK_audit_bil_verification_phone] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_audit_bil_wealth_demonstration]    Script Date: 10/24/2019 1:43:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[_audit_bil_wealth_demonstration](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pk_id] [int] NOT NULL,
	[is_latest] [bit] NULL,
	[fk_queue_id] [int] NOT NULL,
	[fk_application_information_id] [int] NOT NULL,
	[fk_customer_information_id] [int] NULL,
	[fk_bil_application_information_id] [int] NULL,
	[fk_bil_customer_information_id] [int] NULL,
	[total_fd_value] [decimal](18, 4) NULL,
	[total_property_owned] [decimal](18, 4) NULL,
	[is_active] [bit] NULL,
	[fk_type_id] [int] NULL,
	[fk_status_id] [int] NULL,
	[created_date] [datetime] NOT NULL,
	[created_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NULL,
	[update_by] [nvarchar](50) NULL,
	[other_asset] [nvarchar](50) NULL,
	[total_car_owned] [decimal](18, 4) NULL,
	[monthly_expenditure] [decimal](18, 4) NULL,
	[is_company] [bit] NULL,
	[is_legal_ref] [bit] NULL,
	[is_owner] [bit] NULL,
	[fk_m_borrower_type_id] [int] NULL,
 CONSTRAINT [PK_audit_bil_wealth_demonstration] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
