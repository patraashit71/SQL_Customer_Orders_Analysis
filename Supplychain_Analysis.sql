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
