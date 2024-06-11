CREATE DATABASE Retail_Sale_Data

USE Retail_Sale_Data
GO

--Creating table Customer
CREATE TABLE Customer (
customer_id int,
DOB varchar(50),
Gender char(1),
City_code int
);

--Inserting data into table Customer
BULK INSERT Customer
FROM 'D:\Anlaytixlab\Project Sheet\SQL\SQL - Retail data analysis\Customer.csv'
WITH(
FIRSTROW = 2 ,
FIELDTERMINATOR = ',' ,
ROWTERMINATOR = '\n' ,
BATCHSIZE = 1000
);

SELECT * FROM Customer

--Creating table Prod_cat_info
CREATE TABLE prod_cat_info (
prod_cat_code int ,
prod_cat varchar(50) ,
prod_sub_cat_code int ,
prod_subcat varchar(50) 
);

--Inserting data into table Prod_cat_info
BULK INSERT prod_cat_info
FROM 'D:\Anlaytixlab\Project Sheet\SQL\SQL - Retail data analysis\prod_cat_info.csv'
WITH (
FIRSTROW = 2 ,
FIELDTERMINATOR = ',' ,
ROWTERMINATOR = '\n' 
);

SELECT * FROM Prod_cat_info ;

--Creating table Transactions
CREATE TABLE Transactions (
transaction_id varchar(50) ,
cust_id int ,
tran_date varchar(50) ,
prod_subcat_code int ,
prod_cat_code int ,
Qty int ,
Rate int ,
Tax float(10) ,
total_amt float(10) ,
store_type varchar(50)
);

BULK INSERT Transactions
FROM 'D:\Anlaytixlab\Project Sheet\SQL\SQL - Retail data analysis\Transactions.csv'
WITH (
FIRSTROW = 2 ,
FIELDTERMINATOR = ',' ,
ROWTERMINATOR = '\n' ,
BATCHSIZE = 1000
);

SELECT * FROM Transactions;

--1.What is the total number of rows in each of the 3 tables in the database?
SELECT 'Customer' AS 'Tables', COUNT(*) as Total_Rows FROM Customer 
UNION ALL
SELECT 'Transactions' , COUNT(*) FROM Transactions
UNION ALL
SELECT 'Prod_cat_info' , COUNT(*) FROM prod_cat_info;

--2.What is the total number of transactions that have a return?
SELECT COUNT(*) AS Total_retunred_Transactions
FROM Transactions
WHERE Qty <0;

--3. As you would have noticed, the dates provided across the datasets are not in a correct format.As first steps, pls convert the date variables into valid date formats before proceeding ahead.
UPDATE Customer
SET DOB = CONVERT ( date , DOB , 103 ) ;

ALTER TABLE Customer
ALTER COLUMN DOB DATE ;

SELECT * FROM Customer ;

UPDATE Transactions
SET tran_date = CONVERT ( DATE , tran_date , 103) ;

ALTER TABLE Transactions
ALTER COLUMN tran_date DATE ;

SELECT * FROM Transactions ;

--4. What is the time range of the transaction data available for analysis?Show the output in number of days, months and years simultaneously in different columns.
SELECT
MIN ( tran_date ) AS MIN_DATE,
MAX	 ( tran_date ) AS MAX_DATE,
DATEDIFF(DAY,MIN(tran_date),MAX(tran_date)) AS DAYS_RANGE,
DATEDIFF(MONTH,MIN(tran_date),MAX(tran_date)) AS MONTHS_RANGE,
DATEDIFF(YEAR,MIN(tran_date),MAX(tran_date)) AS YEARS_RANGE
FROM Transactions ;

--5. Which product category does the sub-category “DIY” belong to?
SELECT DISTINCT Prod_cat
FROM Prod_cat_info
WHERE prod_subcat = 'DIY' ;

-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
--1. Which channel is most frequently used for transactions?
SELECT TOP 1 store_type AS MOST_FREQUENTLY_USED_CHANNEL , COUNT(*) AS TOTAL_TRANSACTION
FROM Transactions
GROUP BY store_type
ORDER BY TOTAL_TRANSACTION DESC;

--2. What is the count of Male and Female customers in the database?
SELECT Gender , COUNT(*) AS COUNT_OF_CUSTOMER
FROM Customer
WHERE Gender IS NOT NULL
GROUP BY Gender ;

--3. From which city do we have the maximum number of customers and how many?
SELECT TOP 1 city_code AS MAX_CUSTOMER_CITY , COUNT(*) AS COUNT_OF_CUSTOMER
FROM Customer
GROUP BY City_code
ORDER BY COUNT_OF_CUSTOMER DESC;

--4. How many sub-categories are there under the Books category?
SELECT COUNT(DISTINCT(prod_sub_cat_code)) AS SUBCATEGORIES_OF_BOOK
FROM Prod_cat_info
WHERE prod_cat = 'Books' ;

--5. What is the maximum quantity of products ever ordered?
SELECT MAX(Qty) AS MAX_ORDERED_QTY
FROM Transactions ;

--6. What is the net total revenue generated in categories Electronics and Books?
SELECT ROUND(SUM(Transactions.total_amt), 2) AS Net_Total_Revenue
FROM Transactions 
JOIN prod_cat_info ON Transactions.prod_cat_code = prod_cat_info.prod_cat_code 
WHERE prod_cat IN ('Electronics', 'Books');

--7. How many customers have >10 transactions with us, excluding returns?
SELECT COUNT(*) AS CustomerCount
FROM(SELECT cust_id,COUNT(DISTINCT transaction_id) AS TransactionCount
FROM Transactions
WHERE total_amt > 0
GROUP BY cust_id
HAVING COUNT(DISTINCT transaction_id) > 10) AS SUBQUERY;

--8. What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
SELECT ROUND(SUM ( total_amt ),2) AS COMBINED_REVENUE
FROM Transactions
JOIN Prod_cat_info ON Transactions.prod_cat_code = Prod_cat_info.prod_cat_code 
WHERE Prod_cat_info.prod_cat IN ('Electronics' , 'Clothing')
AND Transactions.store_type = 'Flagship store' ;

--9. What is the total revenue generated from “Male” customers in “Electronics” category?Output should display total revenue by prod sub-cat.?
SELECT Prod_cat_info.prod_subcat ,ROUND(SUM(total_amt),2) AS TOTAL_REVENUE
FROM Customer
JOIN Transactions ON Customer.customer_id = Transactions.cust_id
JOIN Prod_cat_info ON Transactions.prod_cat_code = Prod_cat_info.prod_cat_code AND
Transactions.prod_subcat_code = Prod_cat_info.prod_sub_cat_code
WHERE Customer.Gender = 'M' AND prod_cat='Electronics'
GROUP BY prod_subcat ;

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
SELECT TOP 5 prod_subcat,
ROUND((SALES/SUM(SALES) OVER()) * 100,2) AS PERCENTAGE_OF_SALES,
ROUND((RETURNS/SUM(RETURNS) OVER()) * 100,2) AS PERCENTAGE_OF_RETURNS
FROM (SELECT Prod_cat_info.prod_subcat,
SUM(CASE WHEN total_amt >= 0 THEN total_amt ELSE '0' END ) AS SALES,
SUM(ABS(CASE WHEN total_amt < 0 THEN total_amt ELSE '0' END )) AS RETURNS
FROM Transactions 
JOIN Prod_cat_info ON Transactions.prod_cat_code = Prod_cat_info.prod_cat_code 
AND Transactions.prod_subcat_code = Prod_cat_info.prod_sub_cat_code
GROUP BY Prod_cat_info.prod_subcat ) AS T1
ORDER BY PERCENTAGE_OF_SALES DESC;


--11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?
SELECT Customer.customer_id , Customer.DOB , Transactions.tran_date ,
ROUND(SUM(total_amt),2) AS REVENUE,
DATEDIFF(DAY,DOB,GETDATE())/365 AS CURRENT_AGE
FROM Customer
JOIN Transactions ON Customer.customer_id = Transactions.cust_id
WHERE tran_date BETWEEN DATEADD( DAY , -30 , ( SELECT MAX ( tran_date ) FROM Transactions)) AND
(SELECT  MAX( tran_date ) FROM Transactions )
GROUP BY Customer.customer_id , Customer.DOB , Transactions.tran_date
HAVING DATEDIFF(DAY , DOB , GETDATE())/365 BETWEEN 25 AND 35 ;


--12. Which product category has seen the max value of returns in the last 3 months of transactions?
SELECT TOP 1 Prod_cat_info.prod_cat,
ABS(SUM( Transactions.Qty)) AS NO_OF_RETURNED_UNITS
FROM Transactions
JOIN Prod_cat_info ON Transactions.prod_cat_code = Prod_cat_info.prod_cat_code
WHERE Qty<0 AND tran_date BETWEEN DATEADD(MONTH, -3,(SELECT MAX( tran_date )
FROM Transactions)) AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY Prod_cat_info.prod_cat
ORDER BY NO_OF_RETURNED_UNITS DESC ;

--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
SELECT TOP 1 Transactions.store_type,
ROUND(SUM(total_amt),2) AS TOTAL_SALES_AMOUNT,
SUM(Qty) AS TOTAL_SOLD_QTY
FROM Transactions
WHERE Qty>0 AND total_amt>0
GROUP BY Transactions.store_type
ORDER BY TOTAL_SALES_AMOUNT DESC , TOTAL_SOLD_QTY DESC ;

--14. What are the categories for which average revenue is above the overall average.
SELECT Prod_cat_info.prod_cat
FROM ( SELECT Transactions.prod_cat_code , Transactions.total_amt FROM Transactions)
AS TRANSACTION_DATA
JOIN Prod_cat_info ON TRANSACTION_DATA.prod_cat_code = Prod_cat_info.prod_cat_code
GROUP BY Prod_cat_info.prod_cat
HAVING AVG( TRANSACTION_DATA.total_amt) > (SELECT AVG( total_amt) FROM Transactions);

--15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
SELECT Prod_cat_info.prod_subcat,
ROUND(AVG( Transactions.total_amt),2) AS AVG_REVENUE,
ROUND(SUM( Transactions.total_amt),2) AS TOTAL_REVENUE
FROM Transactions
INNER JOIN Prod_cat_info ON Transactions.prod_cat_code = Prod_cat_info.prod_cat_code
WHERE prod_cat_info.prod_cat_code IN ( SELECT TOP 5 Transactions.prod_cat_code FROM Transactions
GROUP BY Transactions.prod_cat_code
ORDER BY SUM(Transactions.Qty)DESC)
GROUP BY prod_cat_info.prod_subcat;


