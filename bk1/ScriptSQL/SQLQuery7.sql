USE [LITS]
GO

/****** Object:  Table [dbo].[bil_application]    Script Date: 10/24/2019 2:00:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[bil_application](
	[pk_id] [int] IDENTITY(1,1) NOT NULL,
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
 CONSTRAINT [PK_bil_application] PRIMARY KEY CLUSTERED 
(
	[pk_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


