/* Question Set 1 - Easy */

-- 1. Who is the senior most employee based on job title?

select * from employee
order by levels desc
limit 1;

-- 2. Which countries have the most Invoices?

select billing_country, count(*) as invoice_count
from invoice
group by billing_country
order by invoice_count desc
limit 1;

-- 3. What are top 3 values of total invoice?

select * from invoice
order by total desc
limit 3;

-- 4. Which city has the best customers? 
-- We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals.

select billing_city as city,
		round(sum(total)::numeric,2) as total_invoice
from invoice
group by billing_city
order by total_invoice desc
limit 1;

-- 5. Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money.

select * from customer;
select * from invoice;

select c.customer_id,
		concat(c.first_name, ' ', c.last_name) as best_customer,
		round(sum(i.total)::numeric,2) as total_invoice
from customer c
join invoice i
using (customer_id)
group by c.customer_id
order by total_invoice desc
limit 1;

/* Question Set 2 - Moderate */

-- 1. Write query to return the email, first name, last name & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A

-- method 1
select distinct c.first_name,
		c.last_name,
		c.email,
		g.name as genre_name
from customer c
join invoice i
using (customer_id)
join invoice_line il
using (invoice_id)
join track t
using (track_id)
join genre g
using (genre_id)
where g.name like 'Rock'
order by c.email;

-- method 2
select distinct c.first_name,
		c.last_name,
		c.email
from customer c
join invoice i
using (customer_id)
join invoice_line il
using (invoice_id)
where track_id in (
	select t.track_id
	from track t
	join genre g
	using (genre_id)
	where g.name like 'Rock'
)
order by email;

-- 2. Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

select ar.name,
		count(track_id) as total_track_count
from artist ar
join album al
using (artist_id)
join track t
using (album_id)
join genre g
using (genre_id)
where g.name like 'Rock'
group by ar.name
order by total_track_count desc
limit 10;

-- 3. Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first

select name, milliseconds
from track
where milliseconds > (select avg(milliseconds) as avg_song_length from track)
order by milliseconds desc;


/* Question Set 2 - Advance */

-- 1. Find how much amount spent by each customer on artists?
-- Write a query to return customer name, artist name and total spent.

select concat(c.first_name, ' ', c.last_name) as customer_name,
		round(sum(il.unit_price * il.quantity)::numeric, 2) as total_spent
from customer c
join invoice i
using (customer_id)
join invoice_line il
using (invoice_id)
join track t
using (track_id)
join album al
using (album_id)
join artist ar
using (artist_id)
group by c.customer_id
order by total_spent desc;

-- how much each customer on every artist?

select concat(c.first_name, ' ', c.last_name) as customer_name,
		ar.artist_id as artist_id,
		ar.name as artist_name,
		round(sum(il.unit_price * il.quantity)::numeric, 2) as total_spent
from customer c
join invoice i
using (customer_id)
join invoice_line il
using (invoice_id)
join track t
using (track_id)
join album al
using (album_id)
join artist ar
using (artist_id)
group by c.customer_id, ar.artist_id
order by customer_name, total_spent desc;

-- how much each customer spent on best-selling artist?

with best_selling_artist as 
(
	select ar.artist_id as artist_id,
		ar.name as artist_name,
		round(sum(il.unit_price * il.quantity)::numeric, 2) as total_spent
	from invoice_line il
	join track t
	using (track_id)
	join album al
	using (album_id)
	join artist ar
	using (artist_id)
	group by ar.artist_id, ar.name
	order by total_spent desc
	limit 1
) 
select concat(c.first_name, ' ', c.last_name) as customer_name,
		bsa.artist_name,
		round(sum(il.unit_price * il.quantity)::numeric, 2) as amount_spent
from customer c
join invoice i
using (customer_id)
join invoice_line il
using (invoice_id)
join track t
using (track_id)
join album al
using (album_id)
join best_selling_artist bsa
using (artist_id)
group by customer_name, artist_name
order by amount_spent desc;

-- 2. We want to find out the most popular music Genre for each country.
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres.

with most_popular_genre as 
(
	select sum(il.quantity) as total_quantity_purchased,
			c.country,
			g.name as genre_name,
			g.genre_id,
			rank() over(partition by c.country order by sum(il.quantity) desc) as rank_no
	from invoice_line il
	join invoice i
	using (invoice_id)
	join customer c
	using (customer_id)
	join track t
	using (track_id)
	join genre g
	using (genre_id)
	group by c.country, g.name, g.genre_id
) 
select * from most_popular_genre 
where rank_no = 1;

-- 3. Write a query that determines the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

select country,
		customer_name,
		total_spent
from (
	select c.country,
		c.customer_id,
		concat(c.first_name, ' ', c.last_name) as customer_name,
		round(sum(il.unit_price * il.quantity)::numeric, 2) as total_spent,
		rank() over(partition by c.country order by sum(il.unit_price * il.quantity) desc) as rank_no
	from customer c
	join invoice i
	using (customer_id)
	join invoice_line il
	using (invoice_id)
	group by c.country, c.customer_id, customer_name
)t
where rank_no = 1;



