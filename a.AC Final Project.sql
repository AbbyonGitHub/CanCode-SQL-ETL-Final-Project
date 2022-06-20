/*	CREATED BY: Abby Cooper
	DATE: 5/26/22
	ASSIGNMENT: Final Project  */

--Create a new SQL database.
CREATE DATABASE CapitalAreaPlantNursery;
GO

--Select database to be used for the following queries.
USE CapitalAreaPlantNursery;
GO

--Create a new table with address info. Foreign keys for all tables should be added after data is ingested.
CREATE TABLE Address(
	AddressID INT IDENTITY(1,1) NOT NULL,
	StreetAddress VARCHAR(100) NOT NULL,
	City VARCHAR(25) NOT NULL,
	State VARCHAR(25) NULL,
	ZipCode VARCHAR(20) NULL,
	PRIMARY KEY (AddressID)
);

--Create a new table with basic vendor info.
CREATE TABLE Vendor(
	VendorID INT IDENTITY(1,1) NOT NULL,
	VendorName VARCHAR(255) NOT NULL,
	AddressID INT NOT NULL,
	VendorPhoneNumber VARCHAR(25) NOT NULL,
	VendorEmail VARCHAR(50) NOT NULL,
	IsActive BIT NOT NULL DEFAULT 1,
	PRIMARY KEY (VendorID)
);  

--Create a new table with product departments.
CREATE TABLE ProductDepartment(
	ProductDepartmentID INT IDENTITY(1,1) NOT NULL,
	ProductDepartmentName VARCHAR(255) NOT NULL,
	PRIMARY KEY (ProductDepartmentID)
);

--Create a new table with product info.
CREATE TABLE Product(
	ProductID INT IDENTITY(1,1) NOT NULL,
	ProductName VARCHAR(255) NOT NULL,
	ProductDepartmentID INT NOT NULL,
	CurrentUnitPrice DECIMAL(18,2) NOT NULL,
	StockQuantity INT NOT NULL,
	VendorID INT NOT NULL, 
	IsActive BIT NOT NULL,
	PRIMARY KEY (ProductID)
);

--Create a new table with customer info.
CREATE TABLE Customer(
	CustomerID INT IDENTITY(1,1) NOT NULL,
	CustomerFirstName VARCHAR(50) NOT NULL,
	CustomerLastName VARCHAR(50) NOT NULL,
	AddressID INT NOT NULL,
	CustomerPhoneNumber VARCHAR(25) NOT NULL,
	CustomerMobileNumber VARCHAR(25) NULL,
	CustomerEmail VARCHAR(50) NOT NULL,
	PRIMARY KEY (CustomerID)
);

--Create a new table with sales order details (not product specific).
CREATE TABLE SalesOrder(
	SalesOrderID INT IDENTITY(1,1) NOT NULL,
	OrderDate DATE NOT NULL,
	CustomerID INT NOT NULL, 
	OrderTotal DECIMAL(18,2) NOT NULL,
	PRIMARY KEY (SalesOrderID)
);

--Create a new table with product specific sales order details (similar to lines on an invoice).
CREATE TABLE SalesOrderProduct
	(
		SalesOrderID INT NOT NULL,
		ProductID INT NOT NULL,
		ProductQuantity INT NOT NULL,
		ProductUnitPrice DECIMAL(18,2) NOT NULL,
		PRIMARY KEY (SalesOrderID, ProductID)
	);

--Ingest mock data into tables using SSIS packages now. Change path in each file connection for both packages, 
--change file path in Load Remainder Loop Editor (double click on container, go to Collection), and change the 
--"FolderPath" variable in that package as well. Make sure ACLoadProduct-4 is loaded first (must be run in 32 bit mode), 
--then ACLoadRemainder. 

--Add foreign keys to tables. Foreach in ACLoadRemainder would not have worked with FKs defined before loading 
--mock data into tables.
ALTER TABLE Vendor
ADD CONSTRAINT FK_AddressVendor
FOREIGN KEY (AddressID) REFERENCES Address(AddressID);

ALTER TABLE Product 
ADD CONSTRAINT FK_ProductDeptProd FOREIGN KEY (ProductDepartmentID) REFERENCES ProductDepartment(ProductDepartmentID),
	CONSTRAINT FK_VendorProduct FOREIGN KEY (VendorID) REFERENCES Vendor(VendorID);

ALTER TABLE Customer
ADD CONSTRAINT FK_AddressCustomer
FOREIGN KEY (AddressID) REFERENCES Address(AddressID);

ALTER TABLE SalesOrder
ADD CONSTRAINT FK_CustomerSales
FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID);

ALTER TABLE SalesOrderProduct 
ADD CONSTRAINT FK_SalesOrderSOP FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder(SalesOrderID),
	CONSTRAINT FK_ProductSOP FOREIGN KEY (ProductID) REFERENCES Product(ProductID);

--Add UNIQUE constraint on CustomerEmail in Customer table (by default will create a unique nonclustered index to enforce).
ALTER TABLE Customer
ADD CONSTRAINT UC_CustEmail UNIQUE(CustomerEmail);

--Verify that tables were created and loaded correctly.
SELECT * FROM Address;
SELECT * FROM Vendor;
SELECT * FROM ProductDepartment;
SELECT * FROM Product;
SELECT * FROM Customer;
SELECT * FROM SalesOrder;
SELECT * FROM SalesOrderProduct;

--These "clean up" commands will remove all tables from the database (use while testing SSIS packages), and the 
--database from the server.
DROP TABLE SalesOrderProduct;
DROP TABLE SalesOrder;
DROP TABLE Customer;
DROP TABLE Product;
DROP TABLE ProductDepartment;
DROP TABLE Vendor;
DROP TABLE Address;

--USE master
--DROP DATABASE CapitalAreaPlantNursery;