/*
#Sales_data SQL queries
*/

--Net price for each customer
select *, (gross_price - pre_invoice_discount_pct) Net_price_each  from sales_data

--Total net price for each customer
select *, (gross_price - pre_invoice_discount_pct) Net_price_each, 
(gross_price - pre_invoice_discount_pct)*Sold_quantity Total_net_price  from sales_data

--Profit/loss
select *, 'P/L' = case
when "Profit/loss" > 0 then 'Profit'
when "Profit/loss" < 0 then 'Loss'
else 'No profit/loss'
end 
from(select *, Gross_price-(Manufacturing_cost+Pre_invoice_discount_pct) 'Profit/loss'
from sales_data) t1

--Profit percentage
select *, round((("profit/loss"/gross_price)*100), 2)Profit_percentage
from(select *, Gross_price-(Manufacturing_cost+Pre_invoice_discount_pct) 'Profit/loss'
from sales_data) t1

--Max profit percentage by fiscal year and product
select t3.Fiscal_year,p.product,t3.Max_profit_percentage from (select Fiscal_year,product_code, max(profit_percentage) Max_profit_percentage from (select *, round((("profit/loss"/gross_price)*100), 2)Profit_percentage
from(select *, Gross_price-(Manufacturing_cost+Pre_invoice_discount_pct) 'Profit/loss'
from sales_data) t1) t2
group by Fiscal_year,Product_code
) t3
join product p
on t3.Product_code=p.Product_code
order by Fiscal_year desc, Max_profit_percentage desc

-- Max discount holding customer
select c.Customer,t2.Pre_invoice_discount_pct as Max_discount from (select distinct(Customer_code), pre_invoice_discount_pct from (select * from sales_data
where pre_invoice_discount_pct=(select  max(pre_invoice_discount_pct) max_discount from sales_data))t1)t2
join Customer c on t2.Customer_code=c.Customer_code

--Total sales in India
select c.market,sum(s.Gross_price) total from sales_data s join
Customer c on c.Customer_code=s.Customer_code
where c.Market='India'
group by c.Market

--Total gross price by total quantity per product
select s.*, sum(Sold_quantity*Gross_price) over(partition by product_code) Total_gross_price_by_total_sold_quantity_per_product 
from sales_data s

--Top selling product by quantity
with t1 as
(select product_code, sum(sold_quantity) Total_qty from sales_data
group by Product_code)
select top(1) p.product, p.variant, t1.total_qty from t1 inner join Product p on t1.Product_code=p.Product_code
order by t1.total_qty desc

--Top selling in country / total profit earn in countries

with t3 as
(select c.market as country, t2.Total_profit from (select customer_code, sum(profit) Total_profit from (select *,
gross_price-(manufacturing_cost+pre_invoice_discount_pct) profit from sales_data) t1
group by Customer_code)t2 left join Customer c
on t2.Customer_code=c.Customer_code)

select country, sum(total_profit) Total_profit from t3
group by country
order by 2 desc

--Total profit per year in all countries

with t1 as(
select * from(
select c.market as "Country",
s.fiscal_year,coalesce(((Gross_price-(Manufacturing_cost+Pre_invoice_discount_pct))* Sold_quantity),0) Total_profit 
from sales_data s left join customer c
on s.Customer_code=c.Customer_code
) as a

pivot
(
sum(total_profit)
for fiscal_year in ([2022],[2021],[2020],[2019],[2018])

)as pivot_table)
select "Country",coalesce(round("2022",2),0) "2022",coalesce(round("2021",2),0) "2021",coalesce(round("2020",2),0) "2020",coalesce(round("2019",2),0) "2019",coalesce(round("2018",2),0)"2018" from t1
order by "2022" desc,"2021" desc,"2020" desc,"2019"desc,"2018"desc
