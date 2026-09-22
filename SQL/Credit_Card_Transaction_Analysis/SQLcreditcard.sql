/*=============================================================
Project : Credit Card Transaction Analysis using SQL Server
Author  : Shivani Malik
Database: Project1

Description:
This project analyzes credit card transaction data to answer
 real-world business questions using SQL.

Skills Demonstrated:
- Common Table Expressions (CTEs)
- Window Functions
- Aggregate Functions
- Ranking Functions
- Running Totals
- Date Functions
- Conditional Aggregation
==============================================================*/

/*=============================================================
STEP 1 : DATA EXPLORATION
==============================================================*/

-- View complete dataset

use Project1;
SELECT *
FROM credit_card_transcations;

-- Check transaction date range
SELECT
MIN(transaction_date) AS First_Transaction,
MAX(transaction_date) AS Last_Transaction
FROM credit_card_transcations;

-- Dataset contains transactions from April 2013 to May 2015

-- Available Card Types
SELECT DISTINCT card_type
FROM credit_card_transcations;
----4 types(silver,signature,gold,platinum)

-- Available Expense Categories
SELECT DISTINCT exp_type
FROM credit_card_transcations;
---- 6 types 


/*=============================================================
QUESTION 1

Business Problem:
Find the Top 5 cities with the highest total credit card spends
and calculate each city's percentage contribution to overall spending.
==============================================================*/

with cte1 as (
select city,sum(amount) as total_spend
from credit_card_transcations
group by city)
,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transcations)
select top 5 cte1.*, round(total_spend*1.0/total_amount * 100,2) as percentage_contribution from 
cte1 inner join total_spent on 1=1
order by total_spend desc


/*=============================================================
QUESTION 2

Business Problem:
Identify the month with the highest spending for each card type.
==============================================================*/
with cte as (
select card_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,datepart(year,transaction_date),datepart(month,transaction_date)
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

/*=============================================================
QUESTION 3

Business Problem:
Retrieve the transaction where cumulative spending first exceeds
1,000,000 for each card type.
==============================================================*/

with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1

/*=============================================================
QUESTION 4

Business Problem:
Identify the city with the lowest percentage contribution of
Gold card spending compared to the total spending in that city.
==============================================================*/

with cte as (
select city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transcations
group by city,card_type)
select top 1
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio;

/*=============================================================
QUESTION 5

Business Problem:
For every city, identify the highest and lowest spending
expense categories.

SQL Concepts Used:
- CTE
- RANK()
- CASE WHEN
- Window Functions
==============================================================*/

with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

/*=============================================================
QUESTION 6

Business Problem:
Calculate the percentage contribution of female spending for
each expense category.

SQL Concepts Used:
- CASE WHEN
- Aggregate Functions
- GROUP BY
==============================================================*/
select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

/*=============================================================
QUESTION 7

Business Problem:
which card and expense type combination saw highest month over month growth in Jan-2014


SQL Concepts Used:
- CTE
- LAG()
- Window Functions
==============================================================*/
with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

/*=============================================================
QUESTION 8

Business Problem:
during weekends which city has highest total spend to total no of transcations ratio 

SQL Concepts Used:
- Aggregate Functions
- GROUP BY
- DATEPART()
==============================================================*/

select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

/*=============================================================
QUESTION 9

Business Problem:
which city took least number of days to reach its
500th transaction after the first transaction in that city;

SQL Concepts Used:
- ROW_NUMBER()
- DATEDIFF()
- Window Functions
==============================================================*/

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 