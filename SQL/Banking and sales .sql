--SQL Developer Interview Prep — Sales & Banking Domain
--1. Customers with Consecutive Month Purchases
sql
WITH monthly_purchases AS (
    SELECT DISTINCT 
        customer_id,
        DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS purchase_month
    FROM sales_transactions
),
ranked AS (
    SELECT 
        customer_id,
        purchase_month,
        LAG(purchase_month) OVER (PARTITION BY customer_id ORDER BY purchase_month) AS prev_month
    FROM monthly_purchases
)
SELECT DISTINCT customer_id
FROM ranked
WHERE purchase_month = DATEADD(month, 1, prev_month);

-- Trick: LAG/LEAD + date arithmetic is the standard "gap and island" / 
-- consecutive pattern approach. Always normalize dates 
-- first with DATE_TRUNC or FORMAT(date,'yyyy-MM') before comparing.

2. Find the Second Highest Salary/Transaction (without TOP/LIMIT tricks)
sqlSELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Or using window function (handles ties properly):
-- sql
SELECT salary FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
) t
WHERE rnk = 2;

-- Trick: Use DENSE_RANK not ROW_NUMBER when duplicates should share rank 
-- (e.g., two employees with same salary = same rank).

-- 3. Detect Duplicate Transactions (Banking fraud check)
-- sql

SELECT account_id, transaction_amount, transaction_date, COUNT(*) AS cnt
FROM transactions
GROUP BY account_id, transaction_amount, transaction_date
HAVING COUNT(*) > 1;

--To delete duplicates keeping one:
--sql
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY account_id, transaction_amount, transaction_date 
        ORDER BY transaction_id
    ) AS rn
    FROM transactions
)
DELETE FROM cte WHERE rn > 1;

-- Trick: ROW_NUMBER() is the go-to for "keep first/remove rest" duplicate cleanup.

-- 4. Running Balance / Account Balance Over Time
-- sql
SELECT 
    account_id,
    transaction_date,
    transaction_amount,
    SUM(transaction_amount) OVER (PARTITION BY account_id ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM transactions;

-- How to count? ➡️ ROWS BETWEEN
-- Where to start? ➡️ UNBOUNDED PRECEDING
-- Where to stop? ➡️ AND CURRENT ROW

-- 5. Customers Who Haven't Made a Purchase in Last 90 Days (Churn)
-- sql
SELECT c.customer_id, c.customer_name, MAX(t.purchase_date) AS last_purchase
FROM customers c
LEFT JOIN sales_transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING MAX(t.purchase_date) < DATEADD(DAY, -90, GETDATE()) OR MAX(t.purchase_date) IS NULL;

--Trick: Always handle the NULL case (customers with zero transactions) using LEFT JOIN + checking for NULL in HAVING.

6. Month-over-Month Growth (Sales)
sqlWITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', sale_date) AS month,
        SUM(amount) AS total_sales
    FROM sales
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY month)) * 100.0 
        / LAG(total_sales) OVER (ORDER BY month), 2
    ) AS growth_pct
FROM monthly_sales;
Trick: Avoid division by zero — wrap denominator with NULLIF(LAG(...),0) in production code.

-- 7. Top N Products per Category (Sales)
-- sqlS
SELECT category, product_name, total_sales
FROM (
    SELECT 
        category, 
        product_name, 
        SUM(sales_amount) AS total_sales,
        RANK() OVER (PARTITION BY category ORDER BY SUM(sales_amount) DESC) AS rnk
    FROM sales
    GROUP BY category, product_name
) ranked
WHERE rnk <= 3;

-- Trick: "Top N per group" = PARTITION BY group ORDER BY metric + filter on rank. Interviewers love this pattern — practice variants (top customer per region, top transaction per account, etc.).

--8. Detect Suspicious High-Value Transactions (Banking)
-- sql
SELECT t.*
FROM transactions t
JOIN (
    SELECT account_id, AVG(transaction_amount) AS avg_amt, STDDEV(transaction_amount) AS sd
    FROM transactions
    GROUP BY account_id
) stats ON t.account_id = stats.account_id
WHERE t.transaction_amount > stats.avg_amt + (3 * stats.sd);
--Trick: "Outlier detection" using mean + N*standard deviation is a common conceptual banking-fraud question — shows statistical thinking, not just SQL syntax.

-- 9. Customers Who Purchased Product A but NOT Product B
-- sql
SELECT DISTINCT customer_id
FROM sales_transactions
WHERE product_id = 'A'AND 
customer_id NOT IN (SELECT customer_id FROM sales_transactions WHERE product_id = 'B'
);
-- Or with EXCEPT:
-- sql
SELECT customer_id FROM sales_transactions WHERE product_id = 'A'
EXCEPT
SELECT customer_id FROM sales_transactions WHERE product_id = 'B';
-- Trick: NOT IN fails silently if subquery returns NULLs — prefer NOT EXISTS or EXCEPT in production.
-- sql
SELECT DISTINCT customer_id FROM sales_transactions a
WHERE product_id = 'A'
AND NOT EXISTS (
    SELECT 1 FROM sales_transactions b 
    WHERE b.customer_id = a.customer_id AND b.product_id = 'B'
);

-- 10. SCD Type 2 — Track Historical Changes (Customer Address)
-- sql-- Insert new record and close old one
UPDATE customer_dim
SET end_date = CURRENT_DATE - 1, is_current = 'N'
WHERE customer_id = @cust_id AND is_current = 'Y';

INSERT INTO customer_dim (customer_id, address, start_date, end_date, is_current)
VALUES (@cust_id, @new_address, CURRENT_DATE, '9999-12-31', 'Y');
-- Trick: Always discuss MERGE as the production-grade single-statement alternative:
-- sql
MERGE INTO customer_dim AS target
USING (SELECT @cust_id AS customer_id, @new_address AS address) AS source
ON target.customer_id = source.customer_id AND target.is_current = 'Y'
WHEN MATCHED AND target.address <> source.address THEN
    UPDATE SET end_date = CURRENT_DATE - 1, is_current = 'N'
WHEN NOT MATCHED THEN
    INSERT (customer_id, address, start_date, end_date, is_current)
    VALUES (source.customer_id, source.address, CURRENT_DATE, '9999-12-31', 'Y');

-- 11. First Transaction Per Customer (Earliest Activity)
-- sql
SELECT customer_id, transaction_date, transaction_amount
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_date) AS rn
    FROM transactions
) t
WHERE rn = 1;

-- 12. Customers with No Activity but Active Account (NULL handling)
-- sql
SELECT a.account_id, a.customer_id
FROM accounts a
WHERE a.status = 'ACTIVE'
AND a.account_id NOT IN (SELECT DISTINCT account_id FROM transactions WHERE account_id IS NOT NULL);
--Trick: Always add WHERE account_id IS NOT NULL inside NOT IN subqueries — a classic interview gotcha.

-- 13. Pivot Transaction Types into Columns (Banking statement)
-- sql
SELECT 
    account_id,
    SUM(CASE WHEN txn_type = 'CREDIT' THEN amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN txn_type = 'DEBIT' THEN amount ELSE 0 END) AS total_debit
FROM transactions
GROUP BY account_id;
-- Trick: CASE WHEN inside SUM/COUNT = conditional aggregation, very frequently asked instead of actual PIVOT syntax (which is DB-specific).

-- 14. Customers Who Made Purchases Every Month This Year
-- sql
SELECT customer_id
FROM sales_transactions
WHERE YEAR(purchase_date) = 2026
GROUP BY customer_id
HAVING COUNT(DISTINCT MONTH(purchase_date)) = 12;
