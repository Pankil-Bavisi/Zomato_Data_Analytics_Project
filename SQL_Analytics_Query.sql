--Table: goldusers_signup
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'09-22-2017'),
	   (3,'04-21-2017');


--Table: Users
drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

--Table: Sales

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

--Table: Product
drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

--View Table:
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Q1 - What is the total amount each customer spent on Zomato?

select a.userid, sum(b.price) total_amt_spent from sales a inner join product b on a.product_id =b.product_id
group by a.userid

-- Q2 - How many days has each customer visited Zomato?

select userid, count(distinct created_date) from sales group by userid

-- Q3 - What was the first product purchased by each customer?

select * from
(select *, rank() over (partition by userid order by created_date) rnk from sales) a where rnk=1

-- Q4 - What is the most purchased item on the menu and how many times was it purchased by all customers?

--select top 1 product_id, count(product_id) cnt from sales group by product_id order by count(product_id) desc 
-- <Gives product_id and total number of times all customers have brought this item
-- <Most purchased item is product_id '2'

select userid, count(product_id) cnt from sales where product_id = 
(select top 1 product_id from sales group by product_id order by count(product_id) desc)
group by userid

-- Q5 - Which item was the most popular for each of the customer?

select * from
(select *, rank() over(partition by userid order by cnt desc) rnk from
(select userid, product_id, count(product_id) cnt from sales group by userid, product_id) a) b
where rnk=1


-- Q6 - Which item was pruchased by the customer after they became a member?

select * from 
(select c.*, rank() over(partition by userid order by created_date) rnk from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date >= gold_signup_date) c) d
where rnk=1

-- Q7 - Which item was purchased before the customer became a member?
select * from 
(select c.*, rank() over(partition by userid order by created_date desc) rnk from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date <= gold_signup_date) c) d
where rnk=1

-- Q8 - What is the total orders and amount spent for each member before they became a member?

select userid, count(created_date) order_purchased, sum(price) total_amt_spent from
(select c.*, d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date <= gold_signup_date) c inner join
product d on c.product_id=d.product_id) e
group by userid

-- Q9 - If buying each product generates points for eg 5.Rs=2 Zomato point and each product has different purchasing points
--      for eg: for P1 5.Rs=1 Zomato point, for P2 10.Rs=5 Zomato point, and P3 5.Rs=1 Zomato point,
--      calulate points collected by each customers and for which product most points have been given till now.
-- For P2: 2.Rs=1 Zomato point | 5.Rs=2 Zomato point, so 1 Zomato point=2.5Rs

select userid, sum(total_points)*2.5 total_cashback_earned from
(select e.*, amt/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c
group by userid, product_id) d) e) f
group by userid

select * from
(select *, rank() over(order by total_point_earned desc) rnk from
(select product_id, sum(total_points) total_point_earned from
(select e.*, amt/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amt from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c
group by userid, product_id) d) e) f
group by product_id) g) h where rnk=1

-- Q10 - In the First one year after a customer joins the gold program (including their join date) irrespective of
--		 what the customer has purchased they earn 5 Zomato points for every 10.Rs spent who earned more 1 or 3
--		 and what was their points earnings in their First year?
-- 1 Zomato point=2.Rs
-- So, 0.5 Zomato point=1.Rs

select c.*, d.price*0.5 total_points_earned from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date >= gold_signup_date and created_date<=DATEADD(year,1,gold_signup_date)) c
inner join product d on c.product_id=d.product_id

-- Q11 - Rank all the transactions of the customers

select *, rank() over(partition by userid order by created_date) rnk from sales

-- Q12 - Rank all the transactions for each member whenever they are a Zomato Gold Member for every Non Gold Member transaction
--	     mark as 'NA'
--

select e.*, case when rnk=0 then 'na' else rnk end as rnkk from
(select c.*, cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as varchar) as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a left join 
goldusers_signup b on a.userid=b.userid and created_date >= gold_signup_date) c) e

































