=====================================================================================================================

--What is the typical order of SQL clauses in a SELECT statement?
SELECT – FROM – JOIN – ON – WHERE – GROUP BY – HAVING – ORDER BY – LIMIT

=====================================================================================================================
--In which order does the interpreter execute the common statements in the SELECT query?
--Here is the SQL order of execution: 

FROM → ON → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT/OFFSET (FETCH)
=====================================================================================================================
80. How do you delete a column from a table?
ALTER TABLE table_name
DROP COLUMN column_name;
=====================================================================================================================
--How do you rename a column of a table?
ALTER TABLE table_name
RENAME COLUMN old_column_name TO new_column_name;
=====================================================================================================================
--How do you change the data type of a column?
ALTER TABLE table_name
ALTER COLUMN column_name new_data_type;
=====================================================================================================================
--How do you add a new column to an existing table?
ALTER TABLE table_name
ADD column_name data_type;
=====================================================================================================================
--How do you delete a table from the database?
DROP TABLE table_name;
=====================================================================================================================
--How do you rename a table?
ALTER TABLE old_table_name
RENAME TO new_table_name;
=====================================================================================================================
--How do you create a new table in SQL?
CREATE TABLE table_name (
    column1 data_type constraints,
    column2 data_type constraints,
    ...)    
=====================================================================================================================
--How do you select all even or all odd records in a table?
SELECT * FROM table_name
WHERE MOD(ID_column, 2) = 0;
=====================================================================================================================

View:
CREATE VIEW vw_IndianCustomers AS
SELECT customer_id, customer_name, Country
FROM Customer_Table
WHERE Country = 'India';

-- Usage
SELECT * FROM vw_IndianCustomers;
=====================================================================================================================
Store Procedure:
CREATE PROCEDURE GetCustomersByCountry
    @CountryName VARCHAR(50)
AS
BEGIN
    SELECT customer_id, customer_name, Country
    FROM Customer_Table
    WHERE Country = @CountryName;
END;

-- Usage
EXEC GetCustomersByCountry @CountryName = 'India';
=====================================================================================================================
select col1, col2 from table1
intersect 
select col1,col2 from table2

=====================================================================================================================

WITH sales_summary AS (
  SELECT product_id, SUM(amount) AS total_sales
  FROM sales
  GROUP BY product_id
)
SELECT p.product_name, s.total_sales
FROM products p
JOIN sales_summary s ON p.id = s.product_id
WHERE s.total_sales > 10000;

=====================================================================================================================
Key window functions include:

ROW_NUMBER() – assigns a unique sequential number to each row
RANK() – assigns a rank with gaps for ties
DENSE_RANK() – assigns a rank without gaps for ties
LAG() / LEAD() – access data from previous/next rows
SUM() OVER(), AVG() OVER() – running or cumulative calculations

=====================================================================================================================
#running Totals
SELECT 
  order_date,
  amount,
  SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;
=====================================================================================================================

ROW_NUMBER() – always assigns unique sequential numbers (1, 2, 3, 4...), even for ties
RANK() – assigns the same rank to ties, then skips numbers (1, 2, 2, 4...)
DENSE_RANK() – assigns the same rank to ties, without skipping (1, 2, 2, 3...)
=====================================================================================================================

SELECT 
  name, 
  score,
  ROW_NUMBER() OVER (ORDER BY score DESC) AS row_num,
  RANK() OVER (ORDER BY score DESC) AS rank,
  DENSE_RANK() OVER (ORDER BY score DESC) AS dense_rank
FROM students;
=====================================================================================================================

--What SQL aggregate functions do you know?
AVG() – returns the average value

SUM() – returns the sum of values

MIN() – returns the minimum value

MAX() – returns the maximum value

COUNT() – returns the number of rows, including those with null values
=====================================================================================================================

What SQL scalar functions do you know?
LEN() (in other SQL dialects – LENGTH()) – returns the length of a string, including the blank spaces

UCASE() (in other SQL dialects – UPPER()) – returns a string converted to the upper case

LCASE() (in other SQL dialects – LOWER()) – returns a string converted to the lower case

INITCAP() – returns a string converted to the title case (i.e., each word of the string starts from a capital letter)

MID() (in other SQL dialects – SUBSTR()) – extracts a substring from a string

ROUND() – returns the numerical value rounded to a specified number of decimals

NOW() – returns the current date and time
=====================================================================================================================
What are SQL set operators?
UNION – returns the records obtained by at least one of two queries (excluding duplicates)

UNION ALL – returns the records obtained by at least one of two queries (including duplicates)

INTERSECT – returns the records obtained by both queries

EXCEPT (called MINUS in MySQL and Oracle) – returns only the records obtained by the first query but not the second one
=====================================================================================================================