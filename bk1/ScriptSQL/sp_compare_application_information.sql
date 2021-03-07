USE [LITSNEW]
GO

--/****** Object:  StoredProcedure [dbo].[sp_compare_application_information]    Script Date: 5/14/2019 9:48:09 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

---- =============================================
---- Author:		<Phan Duy Thong>
---- Create date: <26-07-2018>
---- Description:	<Description,,>
---- sp_compare_application_information 1045
---- =============================================
--CREATE PROCEDURE [dbo].[sp_compare_application_information]
--	@pk_id int,
--	@fk_queue_id Int
--AS
--BEGIN
	SET FMTONLY OFF

	DECLARE	@pk_id int=20
	DECLARE @fk_queue_id Int=2
	create table #tblResult
	(
	    ApplicationInformationID int,

		IsChangedChannel int,
		_ChangedChannel nvarchar(50),

		IsChangedPeoplewiseIDofSaleStaf int,
		_ChangedPeoplewiseIDofSaleStaf nvarchar(50),

		IsChangedProgramType int,
		_ChangedProgramType nvarchar(50),

		IsChangedCustomerSegment int,
		_ChangedCustomerSegment nvarchar(50),
	
		IsChangedTradingArea int,
		_ChangedTradingArea nvarchar(50),

		IsChangedEOpsTxnReference int,
		_ChangedEOpsTxnReference nvarchar(50),

		IsChangedARMCode int,
		_ChangedARMCode nvarchar(50),

		IsChangedProductType int,
		_ChangedProductType nvarchar(50),

		IsChangedSaleTMPWID int,
		_ChangedSaleTMPWID nvarchar(50),

		IsChangedExpectingDisbursedDate int,
		_ChangedExpectingDisbursedDate nvarchar(50),

		IsChangedRework int,
		_ChangedRework nvarchar(50),

		IsChangedReasonForRework int,
		_ChangedReasonForRework nvarchar(50),

		IsChangedICT int,
		_ChangedICT nvarchar(50),

		IsChangedExisting int,
		_ChangedExisting nvarchar(50),

		IsChangedCDD int,
		_ChangedCDD nvarchar(50),

		IsChangedBranchCode int,
		_ChangedBranchCode nvarchar(50),

		IsChangedBranchLocation int,
		_ChangedBranchLocation nvarchar(50),

		IsChangedCustomerType int,
		_ChangedCustomerType nvarchar(50),

		IsChangedHardCopyApplicationDate int,
		_ChangedHardCopyApplicationDate nvarchar(50),        

		IsChangedSalesCode int,
		_ChangedSalesCode nvarchar(50),        

		IsChangedApplicationNo int,
		_ChangedApplicationNo nvarchar(50),     

		IsChangedReceivingDate int,
		_ChangedReceivingDate nvarchar(50),   

		IsChangedApplicationStatus int,
		_ChangedApplicationStatus nvarchar(50),  

		IsChangedIsBlackList int,
		_ChangedIsBlackList nvarchar(50),  

		IsChangedSalePWID int,
		_ChangedSalePWID nvarchar(50),

		IsChangedIsVipApp int,
		_ChangedIsVipApp nvarchar(50),

		IsChangedTypeOfApplication int,
		_ChangedTypeOfApplication nvarchar(50),

		IsChangedIsSMSSend int,
		_ChangedIsSMSSend nvarchar(50),

		IsChangedPaymentType int,
		_ChangedPaymentType nvarchar(50),

		IsChangedIsStaff int,
		_ChangedIsStaff nvarchar(50),

		IsChangedLoanPurpose int,
		_ChangedLoanPurpose nvarchar(50),
	)

	create table #tblResult_Detail
	(
		IsChanged int,
		_Changed nvarchar(500)
	)

	insert into #tblResult (ApplicationInformationID)
	select @pk_id

	declare @column nvarchar(128)
	declare @cmd nvarchar(500) 
	declare @text nvarchar(500) 
	declare _cursor cursor for
	SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'application_information'
	open _cursor
	fetch next from _cursor into @column
	while @@fetch_status = 0
	BEGIN
		truncate table #tblResult_Detail

		if(@column = 'fk_m_sales_channel_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_sales_channel c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedChannel = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedChannel = (select top 1 _Changed from #tblResult_Detail)
		end
		
		if(@column = 'fk_m_program_type_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_program_type c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedProgramType = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedProgramType = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_customer_segment_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_customer_segment c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedCustomerSegment = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedCustomerSegment = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_trading_area_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_trading_area c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedTradingArea = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedTradingArea = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_product_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_product c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedProductType = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedProductType = (select top 1 _Changed from #tblResult_Detail)
		end
		  
		if(@column = 'fk_m_reason_rework_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_reason c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedReasonForRework = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedReasonForRework = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_cdd_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_cdd c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedCDD = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedCDD = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_branch_code_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_branch_code c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedBranchCode = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedBranchCode = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_branch_location_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_branch_location c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedBranchLocation = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedBranchLocation = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_customer_type_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ', 0) <> ISNULL(b.' + @column + ', 0) then c.[name] end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' left join m_customer_type c on a.' + @column + ' = c.pk_id'
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedCustomerType = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedCustomerType = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'sale_staff_bank_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))				
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedPeoplewiseIDofSaleStaf = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedPeoplewiseIDofSaleStaf = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'eops_txn_ref_no_1')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))		
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedEOpsTxnReference = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedEOpsTxnReference = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'arm_code')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedARMCode = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedARMCode = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'sales_team_manager_bank_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedSaleTMPWID = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedSaleTMPWID = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'expecting_disbursed_date')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedExpectingDisbursedDate = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedExpectingDisbursedDate = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'ict')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedICT = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedICT = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'hard_copy_app_date')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedHardCopyApplicationDate = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedHardCopyApplicationDate = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'sales_code')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedSalesCode = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedSalesCode = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'application_no')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedApplicationNo = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedApplicationNo = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'received_date')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedReceivingDate = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedReceivingDate = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'is_black_list')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedIsBlackList = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedIsBlackList = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'is_vip')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedIsVipApp = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedIsVipApp = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_payment_type_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedPaymentType = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedPaymentType = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_staff_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedIsStaff = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedIsStaff = (select top 1 _Changed from #tblResult_Detail)
		end

		if(@column = 'fk_m_loan_purpose_id')    
		begin
			set @cmd = N'select case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then 1 else 0 end,'
			+ 'case when ISNULL(a.' + @column + ',' + '''' + ''''  + ') <> ISNULL(b.' + @column + ',' + '''' + '''' + ') then b.' + @column + ' end'
			+ ' from application_information a inner join _audit_application_information b on a.pk_id = b.pk_id and b.is_latest = 1 and b.fk_queue_id ='+  cast(@fk_queue_id as nvarchar(50))	
			+ ' where a.pk_id = ' + cast(@pk_id as nvarchar(50))					

			insert into #tblResult_Detail
			exec(@cmd)

			update #tblResult set IsChangedLoanPurpose = (select top 1 IsChanged from #tblResult_Detail)
			update #tblResult set _ChangedLoanPurpose = (select top 1 _Changed from #tblResult_Detail)
		end

	fetch next from _cursor into @column
	END

	close _cursor 
	deallocate _cursor

	select * from #tblResult

	drop table #tblResult
	drop table #tblResult_Detail
--END
--GO


