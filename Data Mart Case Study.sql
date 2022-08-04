/* In this Case Retail is the offline store 
and Online store is shopify  */

use casestudy;
select * from weekly_sales;
select * from weekly_sales limit 10 ;

#Data Cleansing 
/*1. Add a week_number as the second column for each week_date value, for
example any value from the 1st of January to 7th of January will be 1, 8th to
14th will be 2, etc.
2. Add a month_number with the calendar month for each week_date value as
the 3rd column
3. Add a calendar_year column as the 4th column containing either 2018, 2019
or 2020 values
4. Add a new column called age_band after the original segment column using
the following mapping on the number inside the segment value
segment age_band

1 Young Adults

2 Middle Aged

3 or 4 Retirees

5. Add a new demographic column using the following mapping for the first
letter in the segment values:
segment | demographic |
C | Couples |
F | Families |
6. Ensure all null string values with an "unknown" string value in the
original segment column as well as the
new age_band and demographic columns
7. Generate a new avg_transaction column as the sales value divided
by transactions rounded to 2 decimal places for each record */


create table clean_weekly_sales as select week_date , week(week_date) as week_number ,
month(week_date) as month_number , year(week_date) as calendar_year ,
region,platform ,
case 
	when segment =null then 'Unknown'
    else segment 
    end as segment,

case 
	when right(segment,1)='1' then 'Young Adult'
    when right(segment,1)='2' then 'Middle Aged'
	when right(segment,1) in ('3','4') then 'Retirees'
    else 'Unknown'
    end as age_band, 
case
	when left(segment,1)='C' then 'Couples'
    when left(segment,1)='F' then 'Families'
    else 'Unknown'
    end as demographic,
customer_type,transactions,sales,
round(sales/transactions,2) as avg_transaction from weekly_sales ;
    
select * from clean_weekly_sales ;

## Data Exploration ##
/*
1. How many total transactions were there for each year in the dataset?
2. What are the total sales for each region for each month?
3. What is the total count of transactions for each platform
4. What is the percentage of sales for Retail vs Shopify for each month?
5. What is the percentage of sales by demographic for each year in the dataset?
6. Which age_band and demographic values contribute the most to Retail
sales?
*/

select calendar_year ,sum(transactions) as total_transaction from clean_weekly_sales group by calendar_year ;

select region ,month_number,
sum(sales) as total_sales 
from clean_weekly_sales group by month_number ,region ;

select platform,
sum(transactions) as total_transactions
from clean_weekly_sales group by platform;

WITH cte_monthly_platform_sales AS (
  SELECT
    month_number,calendar_year,
    platform,
    SUM(sales) AS monthly_sales
  FROM clean_weekly_sales
  GROUP BY month_number,calendar_year, platform
)
SELECT
  month_number,calendar_year,
  ROUND(
    100 * MAX(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) /
      SUM(monthly_sales),
   2
  ) AS retail_percentage,
  ROUND(
    100 * MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END) /
      SUM(monthly_sales),
    2
  ) AS shopify_percentage
FROM cte_monthly_platform_sales
GROUP BY month_number,calendar_year
ORDER BY month_number,calendar_year;

select platform,calendar_year ,demographic,sum(sales) as yearly_sales,
round(100*sum(sales)/sum(sum(sales))
over (partition by demographic),2) as percentage
from clean_weekly_sales group by calendar_year ,demographic , platform;

select region,age_band ,demographic ,sum(sales) as total_sales
from clean_weekly_sales where platform ='Retail' 
group by age_band ,demographic ,region
order by total_sales desc;
