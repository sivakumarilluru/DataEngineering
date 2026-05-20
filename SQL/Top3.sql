WITH RankedProducts AS (
    -- Rank products per month
    SELECT 
        Month,
        Product,
        SUM(Sales) AS ProductSales,
        ROW_NUMBER() OVER (PARTITION BY Month ORDER BY SUM(Sales) DESC) AS Rank
    FROM SalesData
    GROUP BY Month, Product
),
Top3Products AS (
    -- Get only Top 3 products per month
    SELECT 
        Month, 
        Product, 
        ProductSales,
        Rank
    FROM RankedProducts
    WHERE Rank <= 3
),
AggregatedTop3 AS (
    -- Concatenate Top 3 products with comma + line feed, last one with period
    SELECT 
        Month,
        SUM(ProductSales) AS Top3TotalSales,
        STRING_AGG(CASE  WHEN Rank = 3 THEN Product + '.'
                ELSE Product + ','
            END, 
            CHAR(10)
        ) WITHIN GROUP (ORDER BY Rank ASC) AS Top3ProductsList
    FROM Top3Products
    GROUP BY Month
),
MonthlyTotalSales AS (
    SELECT 
        Month, 
        SUM(Sales) AS TotalSales
    FROM SalesData
    GROUP BY Month
)
-- Final Output
SELECT 
    m.Month,
    m.TotalSales AS [Sales],
    a.Top3TotalSales AS [Top 3 Sales],
    a.Top3ProductsList AS [Top 3 Products],
    CAST((a.Top3TotalSales * 1.0 / m.TotalSales) * 100 AS DECIMAL(5,2)) AS [Contribution of Top 3 %]
FROM MonthlyTotalSales m
JOIN AggregatedTop3 a ON m.Month = a.Month
ORDER BY m.Month;

