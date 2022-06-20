----Page 2--May need to select database again to be used for the following queries.
----Also refresh Intellisense local cache if needed to remove red lines (Edit menu).
--USE CapitalAreaPlantNursery;
--GO

--Practice Queries to Try

--When creating mock data to populate my Customer table, I used a function in Excel to produce random phone numbers that 
--did not ensure a lack of duplicates. I also did not format the phone numbers. I now want to format the phone numbers, 
--count how many times the same phone number is repeated in the CustomerPhoneNumber column, and count how many 
--times the same CustomerPhoneNumber and CustomerMobileNumber pair is repeated for a customer.

--Format phone numbers in Customer table.
--First, look at what will be updated (and how many records) and then check again before committing.
SELECT CustomerPhoneNumber FROM Customer;

--Not every field has a mobile number; those that do not, have a blank space.
SELECT CustomerMobileNumber FROM Customer
WHERE CustomerMobileNumber <> ' ';

--As there are many records to be changed, I will practice employing explicit transactions here. Ensure 
--COMMIT and ROLLBACK are initially commented out, and that one of those is run after the result is viewed.
BEGIN TRAN;
UPDATE Customer
SET CustomerPhoneNumber = (SELECT CONCAT(SUBSTRING(CustomerPhoneNumber,1,3),'-', SUBSTRING(CustomerPhoneNumber,4,3),'-',SUBSTRING(CustomerPhoneNumber,7,4)));
COMMIT TRAN;
--ROLLBACK TRAN;

BEGIN TRAN;
UPDATE Customer
SET CustomerMobileNumber = (SELECT CONCAT(SUBSTRING(CustomerMobileNumber,1,3),'-', SUBSTRING(CustomerMobileNumber,4,3),'-',SUBSTRING(CustomerMobileNumber,7,4))) 
WHERE (CustomerMobileNumber <> ' ');
COMMIT TRAN;
--ROLLBACK TRAN;

--Find number of times each phone number in CustomerPhoneNumber column is listed more than once.
SELECT CustomerPhoneNumber, COUNT(CustomerPhoneNumber) AS Instances
FROM Customer
GROUP BY CustomerPhoneNumber
HAVING COUNT(CustomerPhoneNumber) > 1;

--Count the occurrences of the same CustomerPhoneNumber and CustomerMobileNumber pairs.
SELECT CustomerPhoneNumber,CustomerMobileNumber, COUNT(*) Occurrences FROM Customer 
WHERE CustomerMobileNumber <> ' '
GROUP BY CustomerPhoneNumber,CustomerMobileNumber
HAVING (COUNT(*) > 1);

--I accidentally allowed inactive items in the Product table to have inventory. I will set those StockQuantity levels to "0".
--View these items/check.
SELECT * FROM Product
WHERE StockQuantity <> '0' AND IsActive = '0';

--Update the table. Note there are 13 rows needing to be changed.
BEGIN TRAN;
UPDATE Product
SET StockQuantity = '0' 
WHERE IsActive = '0';
COMMIT TRAN;
--ROLLBACK TRAN;

--Check again.
SELECT * FROM Product
WHERE StockQuantity = '0' AND IsActive = '0';

--Check to see if I calculated the OrderTotal column correctly in my mock data file for the SalesOrder table.
--Note: Last number adjacent to NULL is the total of all orders.
SELECT * FROM SalesOrderProduct;

SELECT  SalesOrderID, SUM(ProductUnitPrice * ProductQuantity) AS Total FROM SalesOrderProduct 
GROUP BY ROLLUP(SalesOrderID);

--Delete all shrubs sold by the Vendor, "Grady LLC", from the Product table.
--View the number of records to be deleted--7, then check. Not using aliases to ensure accuracy.
SELECT ProductDepartment.ProductDepartmentID, ProductDepartmentName, Product.ProductID, ProductName, Product.IsActive, Vendor.VendorID, VendorName 
FROM ProductDepartment
INNER JOIN Product 
	ON ProductDepartment.ProductDepartmentID = Product.ProductDepartmentID
INNER JOIN Vendor 
	ON Product.VendorID = Vendor.VendorID
WHERE (ProductDepartmentName = 'Shrub') AND (VendorName = 'Grady LLC');

--See what happens to tables after running following statement (when FKs disabled...see below) and before committing.
SELECT SalesOrderID, ProductID FROM SalesOrderProduct WHERE ProductID='1';
SELECT * FROM Product WHERE ProductID = '1';

--Delete records (will not work due to constraints...read on).
BEGIN TRAN;
DELETE Product
FROM ProductDepartment
INNER JOIN Product 
	ON ProductDepartment.ProductDepartmentID = Product.ProductDepartmentID
INNER JOIN Vendor 
	ON Product.VendorID = Vendor.VendorID
WHERE (ProductDepartmentName = 'Shrub') AND (VendorName = 'Grady LLC');
COMMIT TRAN;
--ROLLBACK TRAN;

--My database doesn't allow for this deletion due to the established table relationships. To see the deletion,
--disable all foreign key constraints with the statements below (enable with statements below those). Understand
--this is not a good practice. Alternatively, we can set IsActive to "0" in the Product table for those items using 
--information from the SELECT statement above.

--Disable all foreign key constraints.
ALTER TABLE Vendor  
NOCHECK CONSTRAINT FK_AddressVendor;   

ALTER TABLE Product
NOCHECK CONSTRAINT FK_ProductDeptProd,FK_VendorProduct;

ALTER TABLE Customer
NOCHECK CONSTRAINT FK_AddressCustomer;

ALTER TABLE SalesOrder
NOCHECK CONSTRAINT FK_CustomerSales;

ALTER TABLE SalesOrderProduct
NOCHECK CONSTRAINT FK_SalesOrderSOP, FK_ProductSOP;

--Enable all foreign key constraints.
ALTER TABLE Vendor  
CHECK CONSTRAINT FK_AddressVendor;   

ALTER TABLE Product
CHECK CONSTRAINT FK_ProductDeptProd,FK_VendorProduct;

ALTER TABLE Customer
CHECK CONSTRAINT FK_AddressCustomer;

ALTER TABLE SalesOrder
CHECK CONSTRAINT FK_CustomerSales;

ALTER TABLE SalesOrderProduct
CHECK CONSTRAINT FK_SalesOrderSOP, FK_ProductSOP;

--Non delete method (if keys are not disabled).
BEGIN TRAN;
UPDATE Product
SET IsActive = 0 
WHERE (ProductDepartmentID = 1) AND (VendorID = 19);
--COMMIT TRAN;
--ROLLBACK TRAN;

--Determine which customers live in "Coeymans Hollow", and display their CustomerID, full name, address, and email (via subquery).
SELECT CustomerID, CustomerFirstName AS FirstName, CustomerLastName AS LastName, CustomerEmail AS Email,
	(SELECT CONCAT(StreetAddress, ', ', City, ', ', State, ' ', ZipCode)
	FROM Address
	WHERE Address.AddressID = Customer.AddressID)
	AS HomeAddress
FROM Customer
WHERE AddressID IN(SELECT AddressID FROM Address
					WHERE City LIKE 'Coeymans Hollow');

--Create a function that returns a table with sales summary information for a given range of dates. Remember that the
--store is only open from May through September and started business in 2020.
DROP FUNCTION IF EXISTS udf_ThisPeriodSales;
GO

CREATE FUNCTION udf_ThisPeriodSales(@Day1 DATE, @Day2 DATE)
RETURNS TABLE
RETURN
	SELECT so.OrderDate, so.SalesOrderID, so.OrderTotal, p.ProductID, p.ProductName, sop.ProductUnitPrice, sop.ProductQuantity
	FROM SalesOrder so
	INNER JOIN SalesOrderProduct AS sop 
		ON so.SalesOrderID = sop.SalesOrderID
	INNER JOIN Product p 
		ON sop.ProductID = p.ProductID
	WHERE so.OrderDate BETWEEN @Day1 AND @Day2;
GO

--I chose to execute the function for one day only.
SELECT * FROM udf_ThisPeriodSales('8/1/2020', '8/1/2020') 
ORDER BY  SalesOrderID;

--Select records from SalesOrder table into temp table, CurrentSalesOrder, from the current year only.
--Store is open from May through September, and the mock data currently includes data through September of this year.
DROP TABLE IF EXISTS #TempCurrentSalesOrder;

SELECT SalesOrderID, OrderDate, CustomerID, OrderTotal
INTO #TempCurrentSalesOrder
FROM SalesOrder
WHERE OrderDate BETWEEN '2022-05-01' AND '2022-09-30';

--View temp table.
SELECT * FROM #TempCurrentSalesOrder
ORDER BY SalesOrderID;

--Create abridged temp product table using CREATE TABLE/INSERT INTO SELECT method that only contains active items from 
--the tree department.
SELECT * FROM ProductDepartment;
 
DROP TABLE IF EXISTS #TempProduct;

CREATE TABLE #TempProduct(
	ProductID INT PRIMARY KEY,
	ProductName VARCHAR(255),
	ProductDepartmentID INT,
	CurrentUnitPrice DECIMAL(18,2),
	StockQuantity INT,
	VendorID INT,
	IsActive BIT,
);

INSERT INTO #TempProduct
	SELECT * FROM Product
	WHERE ProductDepartmentID = 2 AND IsActive = 1;

--View table.
SELECT * FROM #TempProduct;

--Create the above temp table in a stored procedure that takes user inputs.
DROP PROCEDURE IF EXISTS sp_CreateTemp;
GO

CREATE PROCEDURE sp_CreateTemp(@ProductDepartmentID AS INT, @IsActive AS INT)
AS
SET NOCOUNT ON;

DROP TABLE IF EXISTS #TempProduct2;

CREATE TABLE #TempProduct2(
	ProductID INT PRIMARY KEY,
	ProductName VARCHAR(255),
	ProductDepartmentID INT,
	CurrentUnitPrice DECIMAL(18,2),
	StockQuantity INT,
	VendorID INT,
	IsActive BIT,
);

INSERT INTO #TempProduct2
SELECT * FROM Product
WHERE ProductDepartmentID = @ProductDepartmentID AND IsActive = @IsActive;

SELECT * FROM #TempProduct2
ORDER BY ProductID;

GO

--Execute procedure with two inputs.
EXEC sp_CreateTemp 2,1

--Calculate number of customers, total sales, and average sales per customer in each zip code.
SELECT Address.ZipCode, 
	COUNT(SalesOrder.CustomerID) AS Customers,
	SUM(SalesOrder.OrderTotal) AS TotalSales,
	AVG(SalesOrder.OrderTotal) AS AvgSalesPerCustomer
FROM Address
INNER JOIN Customer 
	ON Address.AddressID = Customer.AddressID
INNER JOIN SalesOrder 
	ON Customer.CustomerID = SalesOrder.CustomerID
GROUP BY Address.ZipCode;

--Calculate the number of orders and total sales per month since the business' inception. Note that the 
--nursery is only open from May to September.
SELECT YEAR(OrderDate) AS YearofSale, MONTH(OrderDate) AS MonthofSale, COUNT(*) AS NumberOfOrders,
	SUM(OrderTotal) AS TotalSales
FROM SalesOrder
GROUP BY Year(OrderDate), MONTH(OrderDate)
ORDER BY YearofSale, MonthofSale;

--Create a view with a list of active products and vendors with their respective department names.
DROP VIEW IF EXISTS v_ProductsWithVendors;
GO

CREATE VIEW v_ProductsWithVendors
AS
SELECT pd.ProductDepartmentID, pd.ProductDepartmentName, p.ProductID, p.ProductName, p.StockQuantity, v.VendorID, v.VendorName
FROM ProductDepartment pd
INNER JOIN Product AS p
	ON pd.ProductDepartmentID = p.ProductDepartmentID
INNER JOIN Vendor v
	ON p.VendorID = v.VendorID
WHERE p.IsActive = 1 AND v.IsActive = 1; 
GO

SELECT * FROM v_ProductsWithVendors
ORDER BY ProductDepartmentID;

--The price of products in the Tropical/Houseplant department need to be raised 5% for all products under $40 and
--for all products with VendorID of 91.
BEGIN TRAN;
UPDATE Product
SET CurrentUnitPrice = CurrentUnitPrice * 1.05

--Use SELECT line for checking data in table to be updated (screenshot/paste in Excel), but comment out when 
--running UPDATE.
SELECT ProductID, ProductName, CurrentUnitPrice, ProductDepartmentName, Vendor.VendorID
FROM ProductDepartment
INNER JOIN Product 
	ON ProductDepartment.ProductDepartmentID=Product.ProductDepartmentID
INNER JOIN Vendor 
	ON Product.VendorID = Vendor.VendorID
WHERE (ProductDepartmentName = 'Tropical/Houseplant' AND CurrentUnitPrice < 40.00)
	OR (Vendor.VendorID = 91);
--COMMIT;
--ROLLBACK;

--Insert information below into the Product table. You suspect a spelling mistake, so investigate/fix that
--and remove the date at end of string.
INSERT INTO Product 
VALUES('Abellio grandiflora Abby Abelia_2022_05_26 03', 1, 25.00, 15, 19, 1);

--Look for the product, then check to see if change was made.
SELECT * FROM Product
ORDER BY ProductName;

--"Abelia x" and "Abelia" are names of shrubs, but "Abellio" is not (did internet search as well). Replace Abellio 
--with Abelia.
BEGIN TRAN;
UPDATE Product
SET ProductName = REPLACE(ProductName, 'Abellio', 'Abelia')
FROM Product
WHERE ProductName = 'Abellio grandiflora Abby Abelia_2022_05_26 03';
COMMIT TRAN;
--ROLLBACK TRAN;

SELECT * FROM Product
ORDER BY ProductName;

--Now, remove the date at the end of the string.
BEGIN TRAN;
UPDATE Product
SET ProductName = REPLACE(ProductName, '_2022_05_26','')
FROM Product
WHERE ProductName = 'Abelia grandiflora Abby Abelia_2022_05_26 03';
COMMIT TRAN;
--ROLLBACK TRAN;
