WITH MonthlyProductSales AS (
    -- Calculate total sales for each product per month
    SELECT 
        Month, 
        Product, 
        SUM(Sales) AS ProductSales
    FROM SalesData
    GROUP BY Month, Product
),
RankedProducts AS (
    -- Rank the products within each month based on sales
    SELECT 
        Month, 
        Product, 
        ProductSales,
        ROW_NUMBER() OVER(PARTITION BY Month ORDER BY ProductSales DESC) as Rank
    FROM MonthlyProductSales
),
MonthlyTotalSales AS (
    -- Calculate the overall total sales per month
    SELECT 
        Month, 
        SUM(Sales) AS TotalSales
    FROM SalesData
    GROUP BY Month
)
-- Join everything together, filtering for only the #1 ranked product
SELECT 
    t.Month,
    t.TotalSales AS [Sales],
    r.ProductSales AS [Top Sales],
    r.Product AS [Top Sale Product],
    -- Calculate percentage and format it
    CAST((r.ProductSales * 1.0 / t.TotalSales) AS DECIMAL(5,2)) AS [Contribution of the product %]
FROM MonthlyTotalSales t
JOIN RankedProducts r ON t.Month = r.Month AND r.Rank = 1
ORDER BY 
    -- Assuming you want calendar order, you might need a MonthNumber column in reality.
    -- If relying on text, it will order alphabetically. 
    t.Month;