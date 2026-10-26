
select 
month(order_date) as Order_Month,
year(order_date) as Order_Year,
count(distinct customer_key) as Customers,
sum(sales_amount) as Total_Sales,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by YEAR(order_date),MONTH(order_date)
order by Year(order_date),MONTH(order_date)

-- DATEETRUNC() FUNCTION RETURN 1ST DATE OF EVERY MONTH


select 
DATETRUNC(MONTH,order_date) as Order_Month,
count(distinct customer_key) as Customers,
sum(sales_amount) as Total_Sales,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by DATETRUNC(MONTH,order_date)
ORDER BY Order_Month

-- fORMAT 

select 
FORMAT(order_date,'yyyy-MMM') as Order_Month,
count(distinct customer_key) as Customers,
sum(sales_amount) as Total_Sales,
sum(quantity) as Total_Quantity
from fact_sales
where order_date is not null
group by FORMAT(order_date,'yyyy-MMM')
ORDER BY Order_Month


-- CUMULATIVE ANALYSIS

-- Running total sales by month 

select
order_date,
total_sales,
sum(total_sales) over (order by order_date) as Running_Total
from (
select
DATETRUNC (YEAR,order_date) as order_date,
sum(sales_amount) as total_sales
from fact_sales 
where order_date is not null
group by DATETRUNC (YEAR,order_date)
) t


-- Running avg of sales over time
select 
order_date,
AVG_SALES,
avg(AVG_SALES) over (order by order_date) as Running_Avg
from
(
select 
datetrunc(YEAR,order_date)as order_date,
avg(sales_amount) as AVG_SALES
from fact_sales
where order_date is not null
group by datetrunc(YEAR,order_date)
) t


-- Performance Analysis


/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales*/
 
-- Find the diff between curr sales and avg sales

with yearly_product_sales as(
select 
Year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as curr_sales
from fact_sales f
left join dim_products p
on f.product_key = p.product_key
where Year(f.order_date) is not null
group by Year(f.order_date), p.product_name
)

select 
order_year,
product_name,
curr_sales,
AVG(curr_sales) over (partition by product_name) as avg_sales,
curr_sales - AVG(curr_sales) over (partition by product_name) as diff_avg,
Case 
	when (curr_sales - AVG(curr_sales) over (partition by product_name)) > 0 then 'Above Avg'
	when (curr_sales - AVG(curr_sales) over (partition by product_name)) < 0 then 'Below Avg'
	Else 'Avg'
End as Avg_change,

-- Year of Year Analysis

LAG(curr_sales) over (partition by product_name order by order_year) as prev_sales,
(curr_sales - LAG(curr_sales) over (partition by product_name order by order_year)) as diff_py,
Case 
	when (curr_sales - LAG(curr_sales) over (partition by product_name order by order_year)) > 0 then 'Increase'
	when (curr_sales - LAG(curr_sales) over (partition by product_name order by order_year)) < 0 then 'Decrease'
	Else 'No Change'
End as Prev_Change
from yearly_product_sales
order by product_name,order_year


-- MONTH OF MONTH ANALYSIS OF SALES

With monthly_sales  as (
select 
Datetrunc(MONTH,f.order_date) as order_month,
p.product_name,
sum(f.sales_amount) as curr_sales
from fact_sales f
left join dim_products p
on f.product_key = p.product_key
where  Datetrunc(MONTH,f.order_date) is not null
group by Datetrunc(MONTH,f.order_date),p.product_name
)

select 
order_month,
product_name,
lag(curr_sales) over (partition by product_name order by order_month) as Previou_month_sale,
curr_sales,
(curr_sales - lag(curr_sales) over (partition by product_name order by order_month)) as Prev_Diff,
Case 
	when (curr_sales - LAG(curr_sales) over (partition by product_name order by order_month)) > 0 then 'Increase'
	when (curr_sales - LAG(curr_sales) over (partition by product_name order by order_month)) < 0 then 'Decrease'
	Else 'No Change'
End as Prev_Change
from monthly_sales
order by product_name,order_month


-- Part-to-Whole-Analysis

-- Which categories contribute the most to overall sales?
with category_sales as (
select 
p.category,
sum(f.sales_amount) as Total_Sales
from fact_sales f
left join dim_products p
on f.product_key = p.product_key
group by category
)

select 
category,
Total_Sales,
sum(Total_Sales) over () overall_sales,
Concat(round((cast(Total_Sales as float) / sum(Total_Sales) over () ) * 100,2), '%') as percentage_of_total 
from category_sales
order by Total_Sales desc

-- Bikes are dominating and we need to focus on Accessories and clothing.


--- Data Segmentation

-- Segment products into cost ranges and count how many products fall into each segment.

with cost_segment as (
select 
product_key,
product_name,
cost,
case 
	when cost < 100 then 'Below 100'
	when cost between 100 and 500 then '100-500'
	when cost between 500 and 1000 then '500-1000'
	else 'Above 1000'
	end as cost_range
from dim_products
)

select 
cost_range,
count(product_key) as total_products
from cost_segment
group by cost_range
order by total_products


/* Group customer based on their spending behaviour :

-- Vip : At least 12 months of history and spending more then 5000 
-- Regular : At least 12 months of history but spending 5000 or less
-- New : lifespan less than 12 months

And find total number of customers by each group. 
*/

with customer_spending as(
select 
c.customer_key,
sum(f.sales_amount) as total_spending,
MIN(order_date) as first_order,
MAX(order_date) as last_order,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as lifespan
from fact_sales f
left join dim_customers c
on f.customer_key = c.customer_key
group by c.customer_key
)

select 
segment,
count(customer_key) as total_customer
from
(
select 
customer_key,
case
	when total_spending > 5000 and lifespan >= 12 then 'Vip'
	when total_spending <= 5000 and lifespan >=12 then 'Regular'
	else 'New'
end as segment
from customer_spending
) x
group by segment
order by total_customer desc

                   -- Reporting

-- Base Query : Select core columns from customer and sales table

CREATE VIEW final_report_customers AS

with base_result as (
select 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) as customer_name,
DATEDIFF(YEAR,c.birthdate,GETDATE()) as age
from fact_sales f
left join dim_customers c
on f.customer_key = c.customer_key
where f.order_date is not null
)
, customer_aggregation as (
select 
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_order,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	max(order_date) as last_order_date,
	DATEDIFF(month, min(order_date),max(order_date)) as lifespan

from base_result
group by 
	customer_key,
	customer_number,
	customer_name,
	age
)

select 
	customer_key,
	customer_number,
	customer_name,
	age,
	case
		 when age < 20 then 'Under 20'
		 when age between 20 and 29 then '20-29'
		 when age between 30 and 39 then '30-39'
		 when age between 40 and 49 then '40-49'
		 else '50 and Above'
	end as age_group,
	case
		when total_sales > 5000 and lifespan >= 12 then 'Vip'
		when total_sales <= 5000 and lifespan >=12 then 'Regular'
		else 'New'
    end as segment,	
	last_order_date,
	DATEDIFF(MONTH,last_order_date,GETDATE()) as recancy,
	total_order,
	total_sales,
	total_products,
	lifespan,

	-- compute average order value (AVO)
	case 
		when total_order = 0 then 0
		else (total_sales/total_order) 
	end as AOV,
	-- AVG monthly spend
	case 
		when lifespan = 0 then 0
		else (total_sales/lifespan) 
	end as AVG_MONTHLY_SPEND
from customer_aggregation


-- View
select *
from final_report_customers