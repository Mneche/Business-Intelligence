-- ETL Script for DWNorthwindOrders

-- Step 1) Code used to Clear tables (Will be used with SSIS Execute SQL Tasks)

Use DWNorthwindOrders
Go

-- 1a) Drop Foreign Keys 
Alter Table [dbo].FactOrders Drop Constraint FK_FactOrders_DimCustomers
Alter Table [dbo].FactOrders Drop Constraint FK_FactOrders_DimEmployees
Alter Table [dbo].FactOrders Drop Constraint FK_FactOrders_DimProducts
Alter Table [dbo]. FactOrders Drop Constraint FK_FactOrders_DimDates_OrderDate 
Alter Table [dbo].FactOrders Drop Constraint FK_FactOrders_DimDates_RequiredDate
Alter Table [dbo].FactOrders Drop Constraint FK_FactOrders_DimDates_ShippedDate
-- You will add Foreign Keys back (At the End of the ETL Process)
Go

--1b) Clear all tables data warehouse tables and reset their Identity Auto Number 
Truncate Table dbo.[FactOrders]
Truncate Table dbo.[DimCustomers]
Truncate Table dbo.[DimProducts]
Truncate Table dbo.[DimEmployees]
Truncate Table dbo.[DimDates]
Go

-- Step 2) Code used to populate dimensions and fact tables (Will be used with SSIS Execute SQL Tasks)

-- 2a) Populate DimCustomers 
insert into dbo.DimCustomers
Select 
   CustID = CustomerID,
   CustName = Cast( CompanyName as nVarchar(100) ),
   CustCity = Cast( City as nVarchar(50) ),
   CustRegion = Cast( IsNull(Region, Country) as nVarchar(50) ),
   CustCountry = Cast( Country as nVarchar(50) )
From Northwind.dbo.Customers
Go

-- 2b) Populate DimEmployees
insert into dbo.DimEmployees
SELECT 
  [EmplID] = [EmployeeID],
  [EmplName] = Cast([FirstName] + ' ' + [LastName] as nVarchar(100))
 FROM [Northwind].[dbo].[Employees]
Go

-- 2c) Populate DimProducts 
insert into dbo.DimProducts
Select 
  ProdID = ProductId,
  ProdName = Cast( ProductName as nVarchar(100) ),
  ProdCategory = Cast( CategoryName as nVarchar(100) ),
  ProdUnitPrice =  Cast( UnitPrice as Decimal(18,4) ),
  ProdSupplier = Cast(CompanyName as nVarchar(100) )
From Northwind.dbo.Products as P
Join Northwind.dbo.Categories as C 
 On P.CategoryId  = C.CategoryId 
Join Northwind.dbo.Suppliers as S
  On P.SupplierID = S.SupplierID
Go

-- 2d) Create values for DimDates as needed.

-- Create variables to hold the start and end date
-- Create variables to hold the start and end date
Declare @StartDate datetime = '01/01/1990'
Declare @EndDate datetime = '01/01/2000' 

-- Use a while loop to add dates to the table
Declare @DateInProcess datetime
Set @DateInProcess = @StartDate

While @DateInProcess <= @EndDate
 Begin
 -- Add a row into the date dimension table for this date
 Insert Into DimDates
 ( [Date], [DateName], [Month], [MonthName], [Quarter], [QuarterName], [Year], [YearName] )
 Values ( 
  @DateInProcess -- [Date]
  , DateName( weekday, @DateInProcess )  + ', ' + Cast(@DateInProcess as nVarchar(20))  -- [DateName]  
  , Month( @DateInProcess ) -- [Month]   
  , DateName( month, @DateInProcess ) -- [MonthName]
  , DateName( quarter, @DateInProcess ) -- [Quarter]
  , 'Q' + DateName( quarter, @DateInProcess ) + ' - ' + Cast( Year(@DateInProcess) as nVarchar(50) ) -- [QuarterName] 
  , Year( @DateInProcess )
  , Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [Year] 
  )  
 -- Add a day and loop again
 Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
 End
 Go

-- 2e) Add additional lookup values to DimDates

Set Identity_Insert [DWNorthwindOrders].[dbo].[DimDates] On
Insert Into [DWNorthwindOrders].[dbo].[DimDates] 
  ( [DateKey]
  , [Date]
  , [DateName]
  , [Month]
  , [MonthName]
  , [Quarter]
  , [QuarterName]
  , [Year], [YearName] )
  Select 
    [DateKey] = -1
  , [Date] =  Cast('01/01/1900' as nVarchar(50) )
  , [DateName] = Cast('Unknown Day' as nVarchar(50) )
  , [Month] = -1
  , [MonthName] = Cast('Unknown Month' as nVarchar(50) )
  , [Quarter] =  -1
  , [QuarterName] = Cast('Unknown Quarter' as nVarchar(50) )
  , [Year] = -1
  , [YearName] = Cast('Unknown Year' as nVarchar(50) )
  Union
  Select 
    [DateKey] = -2
  , [Date] = Cast('01/02/1900' as nVarchar(50) )
  , [DateName] = Cast('Corrupt Day' as nVarchar(50) )
  , [Month] = -2
  , [MonthName] = Cast('Corrupt Month' as nVarchar(50) )
  , [Quarter] =  -2
  , [QuarterName] = Cast('Corrupt Quarter' as nVarchar(50) )
  , [Year] = -2
  , [YearName] = Cast('Corrupt Year' as nVarchar(50) )
  Set Identity_Insert [DWNorthwindOrders].[dbo].[DimDates] Off
Go

-- 2h)Get source data from OLAP and populate fact table FactOrders

insert into FactOrders
SELECT  
  Orders.OrderID
, DimCustomers.CustKey
, DimEmployees.EmplKey
, DimProducts.ProdKey
, OrderDateKey = OrderDate.DateKey
, RequiredDateKey =  RequiredDate.DateKey
, ShippedDateKey =  ShippedDate.DateKey
, [OrderItemUnitPrice] = Cast([Order Details].UnitPrice as decimal(18,4))
, [OrderItemQuantity] =[Order Details].Quantity

FROM Northwind.Dbo.[Order Details] 
INNER JOIN Northwind.Dbo.Orders 
	ON Northwind.Dbo.[Order Details].OrderID = Northwind.Dbo.Orders.OrderID
INNER JOIN dbo.DimCustomers
	ON dbo.DimCustomers.CustId = Cast(Northwind.Dbo.Orders.CustomerID as nvarchar(5))
INNER JOIN dbo.DimEmployees
	ON dbo.DimEmployees.EmplID = Northwind.Dbo.Orders.EmployeeID
INNER JOIN dbo.DimProducts
	ON dbo.DimProducts.ProdID = Northwind.Dbo.[Order Details].ProductID
INNER JOIN dbo.DimDates AS OrderDate
	ON  OrderDate.[Date] = IsNull(Northwind.Dbo.[Orders].OrderDate, '1900-01-01 00:00:00.000')
INNER JOIN dbo.DimDates AS RequiredDate
	ON  RequiredDate.[Date] = IsNull(Northwind.Dbo.[Orders].RequiredDate, '1900-01-01 00:00:00.000')
INNER JOIN dbo.DimDates AS ShippedDate
	ON  ShippedDate.[Date] = IsNull(Northwind.Dbo.[Orders].ShippedDate, '1900-01-01 00:00:00.000');


-- Step 3) Add Foreign Key s back (Will be used with SSIS Execute SQL Tasks)

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimCustomers 
FOREIGN KEY (CustKey) REFERENCES dbo.DimCustomers(CustKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimEmployees 
FOREIGN KEY (EmplKey) REFERENCES dbo.DimEmployees(EmplKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimProducts 
FOREIGN KEY (ProdKey) REFERENCES dbo.DimProducts(ProdKey) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimDates_OrderDate 
FOREIGN KEY (OrderDateKey) REFERENCES dbo.DimDates([DateKey]) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimDates_RequiredDate 
FOREIGN KEY (RequiredDateKey) REFERENCES dbo.DimDates([DateKey]) 

ALTER TABLE dbo.FactOrders ADD CONSTRAINT FK_FactOrders_DimDates_ShippedDate 
FOREIGN KEY (ShippedDateKey) REFERENCES dbo.DimDates([DateKey]) 

Go
