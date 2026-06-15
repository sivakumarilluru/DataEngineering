--Dimension Table

CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1),
    CustomerID INT,
    Name VARCHAR(100),
    City VARCHAR(100),
    LastUpdated DATETIME
)

---CREATE TABLE StgCustomer (
    CustomerID INT,
    Name VARCHAR(100),
    City VARCHAR(100)
)

---SCD1

--MERGE Query for SCD1

MERGE DimCustomer AS TARGET
USING StgCustomer AS SOURCE
ON TARGET.CustomerID = SOURCE.CustomerID

-- If matched and changed, update existing row
WHEN MATCHED AND (
       TARGET.Name <> SOURCE.Name
    OR TARGET.City <> SOURCE.City
)
THEN UPDATE SET
    TARGET.Name = SOURCE.Name,
    TARGET.City = SOURCE.City,
    TARGET.LastUpdated = GETDATE()

-- If not matched, insert new row
WHEN NOT MATCHED THEN
INSERT (CustomerID, Name, City, LastUpdated)
VALUES (SOURCE.CustomerID, SOURCE.Name, SOURCE.City, GETDATE());

-------------------------------------------------------------------------------------------


--SCD Type 2 (Keep Full History)
-- Dimension table with history
CREATE TABLE DimCustomer_SCD2 (
    SurrogateKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    Name VARCHAR(100),
    City VARCHAR(100),
    StartDate DATETIME,
    EndDate DATETIME,
    CurrentFlag BIT
);

-- Staging table
CREATE TABLE StgCustomer (
    CustomerID INT,
    Name VARCHAR(100),
    City VARCHAR(100)
);


---Step 1: Expire old rows if changed
UPDATE D
SET 
    EndDate = GETDATE(),
    CurrentFlag = 0
FROM DimCustomer_SCD2 D
INNER JOIN StgCustomer S ON D.CustomerID = S.CustomerID
WHERE D.CurrentFlag = 1
AND (D.Name != S.Name OR D.City <> S.City);


---Step 2: Insert new version

INSERT INTO DimCustomer_SCD2 (CustomerID, Name, City, StartDate, EndDate, CurrentFlag)
SELECT
    S.CustomerID,
    S.Name,
    S.City,
    GETDATE(),      -- StartDate = now
    NULL,           -- EndDate = unknown
    1               -- CurrentFlag = active
FROM StgCustomer S
LEFT JOIN DimCustomer_SCD2 D
    ON S.CustomerID = D.CustomerID
    AND D.CurrentFlag = 1
WHERE D.CustomerID IS NULL   -- new customer
   OR (D.Name <> S.Name OR D.City <> S.City);  -- changed customer