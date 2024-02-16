-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, 
	SUM(m.price) AS TA_spent 
from sales s
join menu m 
ON s.product_id = m.product_id 
GROUP by s.customer_id
ORDER BY TA_spent DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, 
	COUNT(DISTINCT order_date) as date_visted_no
FROM sales s
group by customer_id
ORDER BY date_visted_no DESC;

-- 3. What was the first item from the menu purchased by each customer?
SELECT s.customer_id, 
	m.product_name as first_purchased_item, 
    s.order_date
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
WHERE s.order_date = (
	SELECT MIN(order_date) 
	FROM sales)
GROUP BY s.customer_id, first_purchased_item
ORDER by s.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, 
	COUNT(*) as times_purchased
from sales s
join menu m
on s.product_id = m.product_id
group by m.product_name
ORDER by times_purchased DESC
limit 1;

-- 5. Which item was the most popular for each customer?
WITH customers_purchase_count as (
	SELECT s.customer_id, m.product_name, COUNT(*) as times_purchased
	FROM sales s
	JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
	ORDER by s.customer_id, times_purchased DESC),
ranked_purchase_count AS (
  	SELECT customer_id, product_name, times_purchased, 
  	RANK() OVER(PARTITION by customer_id ORDER by times_purchased desc) as item_rank
	from customers_purchase_count
	)
SELECT customer_id, 
	product_name, 
    times_purchased
FROM ranked_purchase_count
WHERE item_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT s.customer_id, 
	m.product_name as first_purchased_product, 
    MIN(s.order_date) as first_purchase_after_membership, 
    mem.join_date
FROM sales s
JOIN menu m
ON s.product_id = M.product_id
JOIN members mem
ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date
GROUP BY s.customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT s.customer_id, 
	s.order_date, 
    m.product_name, 
    mem.join_date
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON s.customer_id = mem.customer_id
where s.order_date < mem.join_date
GROUP by s.customer_id, 
	m.product_name;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, 
	count(*) AS total_item_before_membership, 
    sum(m.price) as total_amount_spent_before_membership 
FROM sales s
JOIN menu m
on s.product_id = m.product_id
LEFT join members mem
on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, 
	SUM(IIF(m.product_name = 'sushi', m.price * 20, m.price * 10)) AS total_point
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT  s.customer_id,
	SUM(IIF(s.order_date >= mem.join_date AND s.order_date < date(mem.join_date, '+7 days'),
            (m.price * 2) * 10, m.price * 10)) AS total_point
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
on s.customer_id = mem.customer_id
WHERE order_date <= '2023-01-31'
AND s.customer_id IN ('A', 'B')
GROUP BY s.customer_id;