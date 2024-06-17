--CONSTRAINT ON INVENTORY
alter table inventory
add constraint chk_lessthan0 Check (Quantity>=0)
insert into Inventory values(-1,1)
select * from Inventory


--DELETION TRIGGER FOR HISTORY TABLES
--For Order History
create trigger trg1
on orders
for update,delete
as 
begin
insert into order_history(order_id,customer_id,employee_id,order_date,order_time)
select order_id,customer_id,employee_id,order_date,order_time from deleted
select * from order_history
end
update Orders set Customer_ID=20 where Order_ID=20
select * from orders
select * from order_history

--For Payment History
create trigger trg2
on payments
for update,delete
as 
begin
insert into payment_history(payment_id,supplier_payment,paid_date,supplier_id)
select payment_id,supplier_payment,paid_date,supplier_id from deleted
select * from payment_history
end
update Payments set Supplier_Payment=80000 where Payment_ID=1
update Payments set Paid_Date='2023-05-15' where Payment_ID=10
select * from Payments

--For Salaries History
create trigger trg_3
on salaries
for update, delete 
as 
begin
insert into salaries_history(salary_id,employee_salary,paid_date,employee_id)
select salary_id,employee_salary,paid_date,employee_id from deleted
select * from salaries_history
end
update Salaries set Employee_Salary=12500 where salary_id = 3
select * from salaries

--For sales_history
create trigger trg4
on sales
for update, delete
as 
begin 
insert into sales_history(sales_id,amount,order_id)
select sale_id,amount,order_id from deleted
select * from sales_history
end
update sales set amount =300 where sale_id = 1
select * from sales
select * from Orders

--INSERTION TRIGGER FOR INVENTORY UPDATE
alter trigger updatehistory
on orderdetails
after insert
as
begin
 UPDATE Inventory set Quantity=Quantity-(select Quantity from inserted) where Product_ID=(select Product_ID from inserted)
end
insert into OrderDetails values 
(1,2,3)
select * from Inventory
select * from OrderDetails

--PROCEDURES
create proc proc1 @value int
as
begin
select sum(Price*Quantity) as total_amount from Products 
join OrderDetails on OrderDetails.Product_ID= Products.Product_ID
WHERE products.Product_ID = @value
end
exec proc1 @value=4

--PROCEDURE TO GET customer product and quantity against specific order_id
alter PROCEDURE GetOrderDetails @OrderID INT
AS
BEGIN
    SELECT distinct orders.Order_ID, orders.Order_Date, customers.Customer_Name, products.Product_Name, OrderDetails.Quantity FROM Orders    
	JOIN Customers  ON orders.Customer_ID = Customers.Customer_ID
    JOIN OrderDetails  ON orders.Order_ID = OrderDetails.Order_ID
    JOIN Products  ON OrderDetails.Product_ID = Products.Product_ID
	WHERE orders.Order_ID = @OrderID
	order by Order_ID
    
END
exec GetOrderDetails @OrderID=12

--Total products ordered by any customer and their price.
CREATE PROCEDURE GetCustomerOrderSummary @CustomerID INT
AS
BEGIN
    SELECT Customers.Customer_Name, SUM(OrderDetails.Quantity) AS TotalQuantity, SUM(Products.Price * OrderDetails.Quantity) AS TotalPrice FROM Customers 
    JOIN Orders  ON Customers.Customer_ID = orders.Customer_ID
    JOIN OrderDetails ON OrderDetails.Order_ID = orders.Order_ID
    JOIN Products ON OrderDetails.Product_ID = products.Product_ID
    WHERE Customers.Customer_ID = @CustomerID
    GROUP BY Customers.Customer_Name
END
exec GetCustomerOrderSummary @CustomerID= 10

--ALL DETAILS OF ORDER AGAINST SPEICIFC CATEGORY
CREATE PROCEDURE GetOrdersByCategory
    @CategoryID INT
AS
BEGIN
    SELECT orders.Order_ID, orders.Order_Date, customers.Customer_Name, products.Product_Name, suppliers.Supplier_Name FROM Orders 
    JOIN Customers  ON orders.Customer_ID = Customers.Customer_ID
    JOIN OrderDetails ON orders.Order_ID = OrderDetails.Order_ID
    JOIN Products ON OrderDetails.Product_ID = Products.Product_ID
    JOIN Suppliers  ON Products.Supplier_ID = Suppliers.Supplier_ID
    WHERE Products.Category_ID = @CategoryID
END
ExEC GetOrdersByCategory @categoryid = 5

--TOTAL REVENUE OF A SPECIFIC SUPPLIER
alter PROCEDURE GetSupplierRevenue @SUPPLIER int
AS
BEGIN
    SELECT suppliers.Supplier_ID, SUM(Products.Price * OrderDetails.Quantity) AS TotalRevenue FROM Suppliers 
    JOIN Products  ON Suppliers.Supplier_ID = Products.Supplier_ID
    JOIN OrderDetails ON Products.Product_ID = OrderDetails.Product_ID
    GROUP BY Suppliers.Supplier_Name,Suppliers.Supplier_ID
	having suppliers.supplier_id = @SUPPLIER
END
exec  GetSupplierRevenue @supplier=10


CREATE PROCEDURE Getcustorders @CustomerID INT
AS
BEGIN
    SELECT orders.Order_ID, orders.Order_Date, products.Product_Name, OrderDetails.Quantity FROM Orders 
    JOIN OrderDetails ON orders.Order_ID = OrderDetails.Order_ID
    JOIN Products ON OrderDetails.Product_ID = Products.Product_ID
    WHERE orders.Customer_ID = @CustomerID
END
EXEC GetCustOrders @CustomerID=30


CREATE PROCEDURE GenerateReport
AS
BEGIN
    -- Task 1: Get the list of customers and their total order amounts
    SELECT customers.Customer_Name, SUM(sales.Amount) AS TotalOrderAmount FROM Customers 
    JOIN Orders  ON customers.Customer_ID = orders.Customer_ID
    JOIN Sales ON orders.Order_ID = sales.Order_ID
    GROUP BY customers.Customer_Name;

    -- Task 2: Get the list of products and their total sales quantities
    SELECT products.Product_Name, SUM(od.Quantity) AS TotalSalesQuantity FROM Products
    JOIN OrderDetails od ON products.Product_ID = od.Product_ID
    JOIN Orders ON Orders.Order_ID = orders.Order_ID
    GROUP BY Products.Product_Name;

    -- Task 3: Get the list of customers and their average order amounts
    SELECT customers.Customer_Name, AVG(sales.Amount) AS AverageOrderAmount FROM Customers
    JOIN Orders ON customers.Customer_ID = orders.Customer_ID
    JOIN Sales ON orders.Order_ID = sales.Order_ID
    GROUP BY customers.Customer_Name;
END;
exec GenerateReport


--Sales according to product
Create proc GenerateReport2 @startdate date, @enddate date , @customerID int 
as
begin
select Products.Product_ID,Products.Product_Name, 
sum(OrderDetails.Quantity) as totalQuantity, sum(orderdetails.quantity*products.price) as totalPrice from Products
join OrderDetails on OrderDetails.Product_ID= Products.Product_ID
join orders on Orders.Order_ID= OrderDetails.Order_ID
where orders.Order_Date>= @startdate and Orders.Order_Date<=@enddate
and orders.Customer_ID=@customerID
group by Products.product_id,Products.Product_Name
end
select * from orders
exec GenerateReport2 @startdate='2023-05-23', @enddate ='2023-06-01' , @customerID = 13

--Give all Triggers
select * from sys.triggers

CREATE PROCEDURE GenerateLedger
AS
BEGIN
    -- Create a temporary table to store the ledger data
    CREATE TABLE #Ledger (
        TransactionDate DATE,
        AccountName VARCHAR(50),
        Debit DECIMAL(18, 2),
        Credit DECIMAL(18, 2),
        Balance DECIMAL(18, 2)
    );

    -- Insert initial balances into the ledger
    INSERT INTO #Ledger (TransactionDate, AccountName, Debit, Credit, Balance)
    SELECT NULL AS TransactionDate, a.AccountName, NULL AS Debit, NULL AS Credit, ab.Balance
    FROM Accounts a
    JOIN AccountBalances ab ON a.AccountID = ab.AccountID;

    -- Insert transactions into the ledger
    INSERT INTO #Ledger (TransactionDate, AccountName, Debit, Credit, Balance)
    SELECT t.TransactionDate, a.AccountName, t.Amount AS Debit, NULL AS Credit, ab.Balance + t.Amount AS Balance
    FROM Transactions t
    JOIN Accounts a ON t.AccountID = a.AccountID
    JOIN AccountBalances ab ON a.AccountID = ab.AccountID
    WHERE t.TransactionType = 'Debit';

    INSERT INTO #Ledger (TransactionDate, AccountName, Debit, Credit, Balance)
    SELECT t.TransactionDate, a.AccountName, NULL AS Debit, t.Amount AS Credit, ab.Balance - t.Amount AS Balance
    FROM Transactions t
    JOIN Accounts a ON t.AccountID = a.AccountID
    JOIN AccountBalances ab ON a.AccountID = ab.AccountID
    WHERE t.TransactionType = 'Credit';

    -- Retrieve the ledger data
    SELECT *
    FROM #Ledger
    ORDER BY TransactionDate;

    -- Drop the temporary table
    DROP TABLE #Ledger;
END;

exec GenerateLedger
--Sales Table
INSERT INTO Sales (Amount, Order_ID)
SELECT SUM(p.Price * od.Quantity) AS Amount, o.Order_ID
FROM Orders o
JOIN OrderDetails od ON o.Order_ID = od.Order_ID
JOIN Products p ON od.Product_ID = p.Product_ID
GROUP BY o.Order_ID;

select * from sales


