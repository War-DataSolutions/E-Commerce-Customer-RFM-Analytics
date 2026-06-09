/*
====================================================================
E-COMMERCE CUSTOMER RFM SEGMENTATION & PERFORMANCE ANALYTICS
Author: Mamata
Description: This script creates a staging table, cleans raw 
             transactional data, and performs advanced RFM 
             customer segmentation using SQL Window Functions.
====================================================================
*/

USE online_retail_sale;

-- STEP 1: DATA CLEANING & STAGING (Safe Clone)
-- Creating a staging table to keep the original raw data safe
CREATE TABLE retail_data_staging LIKE retail_data;
INSERT retail_data_staging SELECT * FROM retail_data;

-- Removing rows with missing CustomerIDs and negative values (Cancelled/Returned Orders)
DELETE FROM retail_data_staging 
WHERE CustomerID IS NULL 
   OR CustomerID = '' 
   OR Quantity <= 0 
   OR unitPrice <= 0;


-- STEP 2: ADVANCED RFM CUSTOMER SEGMENTATION
-- Using Common Table Expressions (CTEs) and NTILE window function

with rfm_base as(
select 
CustomerID,
datediff('2011-12-10',max(InvoiceDate)) as recency_value,
count(distinct InvoiceNo) as frequency_value,
sum(Quantity*unitPrice) as monetary_value
from retail_data_staging
group by CustomerID),
rfm_scores as(
select
CustomerID,
recency_value,
frequency_value,
monetary_value,
ntile(5)over(order by recency_value asc)as r_score,
ntile(5) over(order by frequency_value desc)as f_score,
ntile(5)over(order by monetary_value desc) as m_score
from rfm_base)
select
CustomerID,
recency_value,
frequency_value,
monetary_value,
concat(r_score,f_score,m_score) as rfm_total_score,
case
when concat(r_score,f_score,m_score)in('555','554','545','455')then 'Champion'
when concat(r_score,f_score,m_score)in('544','444','435','345')then 'Loyal Customer'
when r_score=1 and f_score=1 and m_score=1 then 'Lost Customer'
else 'Regular Customer'
end as customer_segment
from rfm_scores
order by monetary_value desc;
