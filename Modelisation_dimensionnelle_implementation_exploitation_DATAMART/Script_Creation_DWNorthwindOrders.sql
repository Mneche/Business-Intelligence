
-- Create the DWNorthwindOrders Data Warehouse 
USE [master] 
GO
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'DWNorthwindOrders')
  BEGIN
     -- Close connections to the DWNorthwindOrders database 
    ALTER DATABASE [DWNorthwindOrders] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE [DWNorthwindOrders]
  END
GO

CREATE DATABASE [DWNorthwindOrders] ON  PRIMARY 
( NAME = N'DWNorthwindOrders'
, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\DWNorthwindOrders.mdf'  )
 LOG ON 
( NAME = N'DWNorthwindOrders_log'
, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\DWNorthwindOrders_log.ldf' 
)
--COLLATE SQL_Latin1_General_CP1_CI_AS
GO


-- Create the DWNorthwindOrders Tables
USE [DWNorthwindOrders]
GO




-- Create the DWNorthwindOrders Tables
USE [DWNorthwindOrders]
GO

/****** Create the Fact Tables ******/
CREATE TABLE [dbo].[FactOrders](
	[OrderID] [int] NOT NULL,
	[CustKey] [int] NOT NULL,
	[EmplKey] [int] NOT NULL,
	[ProdKey] [int] NOT NULL,
	[OrderDateKey] [int] NOT NULL,
	[RequiredDateKey] [int] NOT NULL,
	[ShippedDateKey] [int] NOT NULL,
	[OrderItemUnitPrice] [decimal](18,4) NOT NULL,
	[OrderItemQuantity] [int] NOT NULL
	CONSTRAINT [PK_FactOrders] PRIMARY KEY CLUSTERED
	(
	[OrderID],
	[CustKey],
	[EmplKey],
	[ProdKey],
	[OrderDateKey],
	[RequiredDateKey],
	[ShippedDateKey]
	)
) 
GO

/****** Create the Dimension Tables ******/
-- DimCustomers 
CREATE TABLE [dbo].[DimCustomers](
	[CustKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[CustID] [nvarchar](5) NOT NULL,
	[CustName] [nvarchar](100) NOT NULL,
	[CustCity] [nvarchar](50) NOT NULL,
	[CustRegion] [nvarchar](50) NOT NULL,
	[CustCountry] [nvarchar](50) NOT NULL
) 
GO

CREATE TABLE [dbo].[DimProducts](
	[ProdKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ProdID] [int] NOT NULL,
	[ProdName] [nvarchar](100) NOT NULL,
	[ProdCategory] [nvarchar](100) NOT NULL,
	[ProdUnitPrice] [decimal](18,4) NOT NULL,
	[ProdSupplier] [nvarchar](100) NOT NULL
)
GO

CREATE TABLE [dbo].[DimEmployees](
	[EmplKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY, 
	[EmplID] [int] NOT NULL,
	[EmplName] [nvarchar](100) NOT NULL
)
GO


CREATE TABLE [dbo].[DimDates](
	[DateKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Date] [datetime] NOT NULL,
	[DateName] [nvarchar](50) NULL,
	[Month] [int] NOT NULL,
	[MonthName] [nvarchar](50) NOT NULL,
	[Quarter] [int] NOT NULL,
	[QuarterName] [nvarchar](50) NOT NULL,
	[Year] [int] NOT NULL,
	[YearName] [nvarchar](50) NOT NULL
)

GO

-- Create the DWNorthwindOrders Foreign Key Constraints


ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimCustomers FOREIGN KEY
	(CustKey) REFERENCES dbo.DimCustomers(CustKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimEmployees FOREIGN KEY
	(EmplKey) REFERENCES dbo.DimEmployees(EmplKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimProducts FOREIGN KEY
	(ProdKey) REFERENCES dbo.DimProducts(ProdKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimDates_OrderDate FOREIGN KEY
	(OrderDateKey) REFERENCES dbo.DimDates([DateKey]) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimDates_RequiredDate FOREIGN KEY
	(RequiredDateKey) REFERENCES dbo.DimDates([DateKey]) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT
	FK_FactOrders_DimDates_ShippedDate FOREIGN KEY
	(ShippedDateKey) REFERENCES dbo.DimDates([DateKey]) 
GO
/*
-- review the current design
USE [DWNorthwindOrders]
GO
Select 
TABLE_NAME
, COLUMN_NAME
, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
order by TABLE_NAME, COLUMN_NAME desc;


USE [DWNorthwindOrders]
--USE [Northwind]
SELECT
C.TABLE_NAME,
C.COLUMN_NAME,
C.DATA_TYPE,
A.CONSTRAINT_NAME,
A.CONSTRAINT_TYPE,
C.IS_NULLABLE,
A.CHECK_CLAUSE,
C.COLUMN_DEFAULT
FROM  INFORMATION_SCHEMA.COLUMNS C LEFT OUTER JOIN
(
 SELECT
 CCU.TABLE_CATALOG,
 CCU.TABLE_SCHEMA,
 CCU.TABLE_NAME,
 CCU.COLUMN_NAME,
 CT.CONSTRAINT_TYPE,
 CT.CONSTRAINT_NAME,
 CHK.CHECK_CLAUSE
 FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CCU
 INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS CT
 ON CCU.CONSTRAINT_NAME = CT.CONSTRAINT_NAME
 LEFT OUTER JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS CHK
 ON CT.CONSTRAINT_NAME = CHK.CONSTRAINT_NAME
) A
ON A.COLUMN_NAME = C.COLUMN_NAME
AND A.TABLE_NAME = C.TABLE_NAME
AND A.TABLE_SCHEMA = C.TABLE_SCHEMA
order by TABLE_NAME, COLUMN_NAME desc;
Print 'The DWNorthwindOrders data warehouse is created!'
USE [Northwind]
GO
Select [ShippedDate]
from [dbo].[Orders]
order by 1 desc;
GO */