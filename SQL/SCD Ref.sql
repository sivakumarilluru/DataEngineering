SCD 1
-- Or via MERGE
MERGE dim_customer AS target
USING staging_customer AS source
ON target.customer_id = source.customer_id
WHEN MATCHED AND target.phone_number <> source.phone_number THEN
    UPDATE SET target.phone_number = source.phone_number,
               target.updated_date = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (customer_id, phone_number, updated_date)
    VALUES (source.customer_id, source.phone_number, GETDATE());

#practies SCD 1
Merge Dim_Customer As Target
Using staging_customer As Source 
On Target.Customer_id = Source.Customer_id
When Matched And Target.phone_number <> Source.Phone_number Then
 Update Set Target.phone_number = Source.Phone_number,
            Target.Updated_date = Getdate()
When Not Mached Then 
Insert (Customer_id,Phone_number,Updated_date)
values(Source.Customer_id,Source.phone_number,Getdate()) 

-- Full SCD2 MERGE pattern (T-SQL style)
MERGE dim_customer AS T
USING staging_customer AS S
ON T.customer_id = S.customer_id AND T.is_current = 'Y'

WHEN MATCHED AND (T.address <> S.address OR T.account_tier <> S.account_tier OR T.customer_name <> S.customer_name) THEN
    UPDATE SET T.end_date = GETDATE(), T.is_current = 'N'

WHEN NOT MATCHED BY TARGET THEN
    INSERT (customer_id, address, account_tier, start_date, end_date, is_current)
    VALUES (S.customer_id, S.address, S.account_tier, GETDATE(), '9999-12-31', 'Y');

-- Note: A second INSERT pass is needed for the new version of changed records,
-- since MERGE can't UPDATE+INSERT for the same source row in one pass.
INSERT INTO dim_customer (customer_id, address, account_tier, start_date, end_date, is_current)
SELECT S.customer_id, S.address, S.account_tier, GETDATE(), '9999-12-31', 'Y'
FROM staging_customer S
JOIN dim_customer T ON S.customer_id = T.customer_id
WHERE T.end_date = CAST(GETDATE() AS DATE) AND T.is_current = 'N';


#practies
MERGE Dim_Customer As Target
Using Staging_customer As Source
On Target.Customer_id = Source.Customer_id And Targget.is_current = 'Y'
When Matched And (Target.Address <> Source.Address OR Target.Account_tier <> Source.Account_tier) Then
    Update Set Target.end_date = getdate(), Target.is_current = 'N'
    When not matched by target then
    insert (customer_id,Address,Account_tier,Start_date,End_date,is_current)
    values(source.Customer_id,Source.Address,Source.Account_tier,getdate(),"9999-12-31","Y")
