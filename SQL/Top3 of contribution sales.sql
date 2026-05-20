
WITH RankedProducts AS (
    -- Calculate total sales for each product per month and rank them
    SELECT 
        Month, 
        Product, 
        SUM(Sales) AS ProductSales,
        ROW_NUMBER() OVER(PARTITION BY Month ORDER BY SUM(Sales) DESC) as Rank
    FROM SalesData
    GROUP BY Month, Product
),
Top3Products AS (
    -- Filter down to only the Top 3 products per month
    SELECT Month, Product, ProductSales, Rank
    FROM RankedProducts
    WHERE Rank <= 3
),
AggregatedTop3 AS (
    -- Sum the Top 3 sales and concatenate the names with a comma + line feed
    SELECT 
        Month,
        SUM(ProductSales) AS Top3TotalSales,
        -- STRING_AGG handles the comma and line feed, the + '.' adds the final period
        STRING_AGG(Product, ',' + CHAR(10)) WITHIN GROUP (ORDER BY Rank ASC) + '.' AS Top3ProductsList
    FROM Top3Products
    GROUP BY Month
),
MonthlyTotalSales AS (
    -- Calculate overall total sales per month for the percentage
    SELECT Month, SUM(Sales) AS TotalSales 
    FROM SalesData 
    GROUP BY Month
)
-- Join it all together
SELECT 
    m.Month, 
    m.TotalSales AS [Sales], 
    a.Top3TotalSales AS [Top 3 Sales], 
    a.Top3ProductsList AS [Top 3 Products],
    CAST((a.Top3TotalSales * 1.0 / m.TotalSales) AS DECIMAL(5,2)) AS [Contribution of Top 3 %]
FROM MonthlyTotalSales m
JOIN AggregatedTop3 a ON m.Month = a.Month;