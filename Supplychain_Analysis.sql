use classicmodels;
/*1)	Show customer number, customer name, state and credit limit from customers table for below conditions. Sort the results by highest to lowest values of creditLimit. 
●	State should not contain null values
●	credit limit should be between 50000 and 100000 */
select customerName, customerNumber, State, creditLimit from customers
where state is not null
and creditLimit between 50000 and 100000
order by creditLimit desc;

/*2)	Show the unique productline values containing the word cars at the end from products table.*/
select distinct(productLine) from productlines
where productLine like '%cars%';


/* 3)Show the orderNumber, status and comments from orders table for shipped status only. If some comments are having null values then show them as “-“. */

SELECT orderNumber, 
       status, 
       COALESCE(comments, '-') as comments
FROM orders
WHERE status = 'Shipped';

/* 4)	Select employee number, first name, job title and job title abbreviation from employees table based on following conditions.
If job title is one among the below conditions, then job title abbreviation column should show below forms.
●	President then “P”
●	Sales Manager / Sale Manager then “SM”
●	Sales Rep then “SR”
●	Containing VP word then “VP”  */

SELECT 
    employeeNumber,
    firstName,
    jobTitle,
    CASE 
        WHEN jobTitle = 'President' THEN 'P'
        WHEN jobTitle LIKE 'Sales Manager%' THEN 'SM'
		WHEN jobTitle LIKE 'Sale Manager%' THEN 'SM'
        WHEN jobTitle = 'Sales Rep' THEN 'SR'
        WHEN jobTitle LIKE '%VP%' THEN 'VP'
        ELSE 'Unknown'
    END AS jobTitleAbbreviation
FROM 
    employees;


/* 5)For every year, find the minimum amount value from payments table. */

SELECT
    YEAR(paymentDate) AS paymentYear,
    MIN(amount) AS minimumAmount
FROM
    payments
GROUP BY
    YEAR(paymentDate);

/* 6)For every year and every quarter, find the unique customers and total orders from orders table. 
I will show the quarters as Q1,Q2 etc.*/

select year(orderDate) order_year, concat("Q",Quarter(orderDate)) order_quarter, 
count(distinct customerNumber) unique_customers, 
count(orderNumber) total_orders
from orders 
group by 
order_year, order_quarter
order by order_year, order_quarter;

/*7)	Show the formatted amount in thousands unit (e.g. 500K, 465K etc.) for every month (e.g. Jan, Feb etc.) with filter on total amount as 500000 to 1000000. 
Sort the output by total amount in descending mode. [ Refer. Payments Table]*/
SELECT 
	left(monthname(paymentDate),3) as month,
    concat(round(sum(amount)/1000),'k') AS formatted_amount
FROM 
    payments
group by
    month
having
     SUM(amount) BETWEEN 500000 AND 1000000
ORDER BY 
    sum(amount) DESC;

/*8) Show employee number, Sales Person (combination of first and last names of employees), 
unique customers for each employee number and sort the data by highest to lowest unique customers.
Tables: Employees, Customers*/
SELECT
    e.employeeNumber,
    CONCAT(e.firstName, ' ', e.lastName) AS SalesPerson,
    COUNT(DISTINCT c.customerNumber) AS UniqueCustomers
FROM
    Employees e
JOIN
    Customers c ON e.employeeNumber = c.salesRepEmployeeNumber
GROUP BY
    e.employeeNumber, SalesPerson
ORDER BY
    UniqueCustomers DESC;

/*9) Show total quantities, total quantities in stock, left over quantities for each product and each customer. 
Sort the data by customer number.

Tables: Customers, Orders, Orderdetails, Products*/    

SELECT
    c.customerNumber,
    c.customerName,
    p.productCode,
    p.productName,
    SUM(od.quantityOrdered) AS totalQuantities,
    p.quantityInStock AS totalQuantitiesInStock,
    (p.quantityInStock - SUM(od.quantityOrdered)) AS leftOverQuantities
FROM
    Customers c
JOIN
    Orders o ON c.customerNumber = o.customerNumber
JOIN
    Orderdetails od ON o.orderNumber = od.orderNumber
JOIN
    Products p ON od.productCode = p.productCode
GROUP BY
    c.customerNumber,
    p.productCode
ORDER BY
    c.customerNumber;

/*10)Create the view products status. Show year wise total products sold. Also find the percentage of total value for each year. 
The output should look as shown in below figure.*/

CREATE VIEW products_status AS
select year(orderDate) year,
concat(count(orders.orderNumber),'(',round(count(orders.orderNumber)*100/sum(count(orders.orderNumber)) over()),'%',')') as value
from orders
left join
orderdetails on orders.orderNumber=orderdetails.orderNumber
group by 
year;
    
select * from products_status;

/*11) Create a stored procedure GetCustomerLevel which takes input as customer number and gives the output as either Platinum, Gold or Silver as per below criteria.

Table: Customers

●	Platinum: creditLimit > 100000
●	Gold: creditLimit is between 25000 to 100000
●	Silver: creditLimit < 25000
*/

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCustomerLevel`(in customerNumbers int,out customerLevel varchar(50))
BEGIN
    declare totalPurchaseAmount Decimal(10,2);
    
    SELECT sum(amount) into totalPurchaseAmount
    FROM payments
    WHERE customerNumber = customerNumbers;

    SET customerLevel =
        CASE
            WHEN totalPurchaseAmount >= 100000 THEN 'Platinum'
            WHEN totalPurchaseAmount >= 50000 THEN 'Gold'
            ELSE 'Silver'
            End;
END

CALL GetCustomerLevel(456, @level);
SELECT @level;

/*12)	Create a stored procedure Get_country_payments which takes in year and country as inputs and gives year wise, 
country wise total amount as an output. Format the total amount to nearest thousand unit (K)
Tables: Customers, Payments*/

CREATE DEFINER=`root`@`localhost` PROCEDURE `Get_country_payments`(IN p_year INT, IN p_country VARCHAR(50))
BEGIN
    -- Create a temporary table to store the results
    CREATE TEMPORARY TABLE temp_results (
        Year INT,
        Country VARCHAR(50),
        TotalAmountFormatted VARCHAR(20)
    );

    -- Calculate the total payment amounts for the specified year and country
    INSERT INTO temp_results (Year, Country, TotalAmountFormatted)
    SELECT
        YEAR(P.paymentDate) AS Year,
        C.country AS Country,
        CONCAT(ROUND(SUM(P.amount) / 1000, 0), 'K') AS TotalAmountFormatted
    FROM Payments P
    JOIN Customers C ON P.customerNumber = C.customerNumber
    WHERE YEAR(P.paymentDate) = p_year AND C.country = p_country
    GROUP BY Year, Country;

CALL Get_country_payments(2004, 'USA');


/*13)	Calculate year wise, month name wise count of orders and year over year (YoY) percentage change. 
Format the YoY values in no decimals and show in % sign.
Table: Orders
*/

SELECT
    YEAR(orderDate) AS OrderYear,
    DATE_FORMAT(orderDate, '%b') AS MonthName,
    COUNT(*) AS OrderCount,
    IFNULL(
        CONCAT(
            FORMAT(
                (COUNT(*) - LAG(COUNT(*)) OVER(PARTITION BY YEAR(orderDate) ORDER BY MONTH(orderDate))) / LAG(COUNT(*)) OVER(PARTITION BY YEAR(orderDate) ORDER BY MONTH(orderDate)) * 100,
                0
            ),
            '%'
        ),
        'NA'
    ) AS YoYChange
FROM
    Orders
GROUP BY
    OrderYear, MonthName
ORDER BY
    OrderYear, MONTH(orderDate);

/*14)	Display the customer numbers and customer names 
from customers table who have not placed any orders using subquery*/

select customerNumber,
customerName
from customers where customerNumber not in (
select customerNumber from orders);

/*15)	Write a full outer join between customers and orders using union 
and get the customer number, customer name, count of orders for every customer.
Table: Customers, Orders
*/

SELECT c.customerNumber, c.customerName, COUNT(o.orderNumber) AS orderCount
FROM Customers c
LEFT JOIN Orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName
UNION
SELECT c.customerNumber, c.customerName, COUNT(o.orderNumber) AS orderCount
FROM Customers c
RIGHT JOIN Orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName;

/*16)	Show the second highest quantity ordered value for each order number.
Table: Orderdetails
*/

select orderNumber,
max(quantityOrdered) as quantityOrdered
from orderdetails where
quantityOrdered<
(select max(quantityOrdered)
from orderdetails)
group by orderNumber;

/*17)	For each order number count the number of products and then find the min and max of the values among count of orders.
Table: Orderdetails*/

with t as 
(select orderNumber,
count(productCode) as number_of_products
from orderdetails
group by orderNumber)
select max(number_of_products) Max_Total,
min(number_of_products) Min_Total
from t;

/*18)	Find out how many product lines are there for which the buy price value is 
greater than the average of buy price value. 
Show the output as product line and its count.*/

select productLine,
count(productLine) as product_Lines
from products
where buyPrice>
(select avg(buyPrice)
from products)
group by productLine;
