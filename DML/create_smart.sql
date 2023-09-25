CREATE MATERIALIZED VIEW smart_sales AS
WITH table_sales_promo AS (
    SELECT 
        sales.product_id AS product_id,
        pr.product_name AS product_name, 
        sales.shop_id AS shop_id, 
        sales.date_sales AS date_sales,
        sales.sales_cnt AS sales_cnt, 
        coalesce(promo.discount, 0.0) AS discount, 
        case when promo.discount is null then 0 else 1 end as is_promo,
        pr.price AS price	
    FROM sales
    LEFT JOIN promo ON 
        sales.product_id = promo.product_id AND 
        sales.shop_id = promo.shop_id AND 
        sales.date_sales = promo.promo_date 
    LEFT JOIN products AS pr ON sales.product_id = pr.product_id 
),
total_sales AS (
    SELECT 
        EXTRACT(MONTH FROM date_sales) AS month_sales, 
        product_id, product_name,
        shop_id, 
        SUM(sales_cnt) AS sales_fact, 
        sum(sales_cnt * price * (1 - discount)) as income_fact,
        AVG(sales_cnt) as avg_sales_date,
        max(sales_cnt) as max_sales,
        AVG(sales_cnt) / max(sales_cnt) as avg_sls_to_max_sls,
        sum(is_promo) as promo_len      
    FROM table_sales_promo
    GROUP BY EXTRACT(MONTH FROM date_sales), product_id, product_name, shop_id
),
sales_in_promo as (select 
	EXTRACT(MONTH FROM date_sales) AS month_sales, 
    product_id,
    shop_id,
    sum(sales_cnt) AS promo_sales_cnt,
    sum(sales_cnt * price * (1 - discount)) as promo_income
from table_sales_promo 
where is_promo = 1
group by EXTRACT(MONTH FROM date_sales), product_id,  shop_id
),
date_max_sales as (select month_sales, date_sales as date_max_sales,
	product_id, shop_id  from (select EXTRACT(MONTH FROM date_sales) AS month_sales,
	date_sales, product_id, shop_id, row_number() over(partition by EXTRACT(MONTH FROM date_sales), 
	product_id, shop_id 
	order by sales_cnt desc) as n_row
	from sales) Z where n_row = 1),
promo_in_max_sales as (
	select dms.month_sales, dms.product_id, dms.shop_id, dms.date_max_sales, 
	case when pr.product_id is null then 0 else 1 end as date_max_sales_is_promo
	from date_max_sales as dms
	left join promo as pr on dms.date_max_sales = pr.promo_date and dms.product_id = pr.product_id and 
	dms.shop_id  = pr.shop_id 
),
plan_revenue as (
	select EXTRACT(MONTH FROM pl.plan_date) AS month_sales,
	pl.product_id, pr.product_name, pl.shop_id, sh.shop_name,  pl.plan_cnt as sales_plan,  
	pl.plan_cnt * pr.price as income_plan
	from plan as pl 
	left join products as pr on pl.product_id = pr.product_id 
	left join shops as sh on pl.shop_id = sh.shop_id 
)
SELECT 
    pr.month_sales, pr.product_name, pr.shop_name, coalesce(ts.sales_fact, 0) as sales_fact,
    pr.sales_plan, 
    coalesce(ts.sales_fact, 0) / pr.sales_plan as sales_fact_to_sales_plan,
    coalesce(ts.income_fact, 0) as income_fact,
    pr.income_plan,
    coalesce(ts.income_fact, 0) / pr.income_plan as income_fact_to_income_plan,
    coalesce(ts.avg_sales_date, 0) as avg_sales_date, 
    coalesce(ts.max_sales, 0) as max_sales,
    dms.date_max_sales,
    dms.date_max_sales_is_promo,
    ts.avg_sales_date / ts.max_sales as avg_sales_to_max_sales,
    ts.promo_len,
    sip.promo_sales_cnt,
    sip.promo_sales_cnt / ts.sales_fact as sales_in_promo_to_total_sales,
    sip.promo_income,
    sip.promo_income / ts.income_fact as promo_income_to_total_income
FROM plan_revenue as pr
left join total_sales as ts on pr.month_sales = ts.month_sales and pr.product_id = ts.product_id and 
	pr.shop_id = ts.shop_id
left join promo_in_max_sales as dms on pr.month_sales = dms.month_sales and pr.product_id = dms.product_id and 
	pr.shop_id = dms.shop_id
left join sales_in_promo as sip on pr.month_sales = sip.month_sales and pr.product_id = sip.product_id and 
	pr.shop_id = sip.shop_id
WITH DATA
;