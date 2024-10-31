use swiggy_db;

-- Q1. Find customers who have never ordered?
select user_id, name from users u
where 
u.user_id not in (select user_id from orders);
select user_id from Orders;

-- Q2. Average Price/dish
select * from 
(select distinct m.f_id,f_name, avg(price) over( partition by f_id) as Avg_Price
from menu m
join food f on m.f_id = f.f_id) as avg_price_per_dish 
order by Avg_Price desc;

-- or

select m.f_id,f.f_name, avg(m.price) as Avg_price
from menu m
left join food f on m.f_id = f.f_id
group by m.f_id,f.f_name
order by Avg_price desc;

-- Q3. Find the top restaurant in terms of the number of orders for a given month
with max_orders_cte as (
select distinct o.r_id,r.r_name, count(order_id) as Total_orders_in_Month, 
monthname(date) as months ,
ROW_NUMBER() OVER (PARTITION BY MONTHNAME(o.date) ORDER BY COUNT(o.order_id) DESC) AS rn
from Orders o
join restaurants r on o.r_id = r.r_id 
group by months, o.r_id, r.r_name 
order by months, Total_orders_in_Month desc)

select r_name,months,Total_orders_in_Month
 from max_orders_cte where rn =1;

-- Q4. Restaurants with monthly sales greater than x for
with max_orders_cte as (
select distinct r.r_name, sum(o.amount) as Total_sales_in_Month, 
monthname(date) as months 
from Orders o
join restaurants r on o.r_id = r.r_id 
group by months, o.r_id, r.r_name 
order by months, Total_sales_in_Month desc)

select r_name,months,Total_sales_in_Month
 from max_orders_cte where Total_sales_in_Month >= 600;


-- Q5. Show all orders with order details for a particular customer in a particular date range
with order_details_cte as
(
select u.name, r.r_name,f.f_name, o.order_id, o.date, o.amount 
from orders o
join users u on u.user_id = o.user_id
join restaurants r on r.r_id = o.r_id
join order_details od on od.order_id = o.order_id
join food f on f.f_id = od.f_id order by o.order_id
)
select * from order_details_cte 
where name like 'Ankit' and date between '2022-06-10' and '2022-07-10';

-- Q6. Month over month revenue growth of Swiggy
select month_name, revenue, monthly_growth, 
(((revenue - monthly_growth )/monthly_growth) * 100) as growth_percentage
from(
	with revenue_per_month as
		(
			select  sum(amount) as revenue, monthname(date) as 'month_name' 
			from orders
			group by month_name
		)
	select month_name, revenue, lag(revenue,1) over(order by revenue) as monthly_growth
	from revenue_per_month
) moving_revenue_percentage;



-- Q7. Customer — favourite food
select f.f_id, f_name, count(f.f_id) as frequency_of_ordered_item
from food f 
join order_details od on od.f_id = f.f_id
group by f.f_id,f_name
order by count(f.f_id) desc
limit 1;

-- or
with favourite_item as
	(
		select f.f_id, f_name, count(f.f_id) as frequency_of_ordered_item,
        dense_rank() over(order by count(f.f_id) desc) as ranking
		from food f 
		join order_details od on od.f_id = f.f_id
		group by f.f_id,f_name
	)
select f_name, frequency_of_ordered_item from favourite_item 
where ranking = 1; 

-- Q8. Find the most loyal customers for all restaurant
WITH customer_visits AS (
    SELECT r_id, user_id, COUNT(*) AS total_visits
    FROM orders
    GROUP BY r_id, user_id
    HAVING COUNT(*) > 1
)
SELECT r.r_name, COUNT(cv.user_id) AS total_loyal_customers
FROM customer_visits cv
JOIN restaurants r ON cv.r_id = r.r_id
GROUP BY r.r_name
ORDER BY total_loyal_customers DESC;

-- Q9. Month-over-month revenue growth of a restaurant

-- Q10. Find restaurants with max repeteated customers
with loyal_customers as
(
	select u.user_id,u.name,r.r_id, r.r_name,count(o.user_id) as frequency_of_visits 
	from orders o 
	join users u on u.user_id = o.user_id
	join restaurants r on r.r_id = o.r_id 
	group by u.user_id,u.name, r.r_id,r.r_name
	having frequency_of_visits >1
	order by count(o.user_id) desc
), 
restaurant_with_max_repeated_customers as
(
	select r_id, r_name,frequency_of_visits,count(r_id), 
	dense_rank() over(order by  count(r_id) desc) as Ranking_Restaurant_having_loyal_custmers
	from loyal_customers 
	group by r_id, r_name,frequency_of_visits
)
select * from restaurant_with_max_repeated_customers where Ranking_Restaurant_having_loyal_custmers=1;