
CREATE TABLE public.Artist_id
(
    artist_id int8 PRIMARY KEY,
    name varchar(100)
    
);



CREATE TABLE public.album2
(
    album_id int8 PRIMARY KEY,
    title character varying,
    artist_id int8 references Artist_id (artist_id)
);

CREATE TABLE  Media 
(
 Media_Type int8 primary key,
 Name varchar(180)
);

CREATE TABLE Genre
(
    Genre_id int8 PRIMARY KEY,
    name varchar(100)
    
);

create table track 
( 
	Track_id int8 primary key,
	Name varchar(230),
	album_id int8 references album2 (album_id),
	media_type int8 references Media (Media_type),
	Genre_id int8 references Genre (Genre_id),
	Composer varchar(230),
	milliseconds int8,
	Bytes int8,
	unit_price Decimal
);



Create Table playlist
(
  Playlist_Id int8 primary key,
  Name Varchar(180)
	
);

create table playlist_track
(
  Playlist_id int8 references playlist (playlist_id),
  Track_id int8  references track (Track_id)

)


create table customer 
(
	customer_id int8 PRIMARY KEY,
	first_name varchar(100),
	last_name varchar(100),
	company varchar(180),
	address varchar(180),
	city varchar(190),
	state varchar(10),
	country varchar(80),
	postal_code varchar(90),
	phone varchar(100),
	fax varchar(100),
	email varchar(100),
	support_rep_id int
);


create table employee
(
	employee_id int8 PRIMARY KEY,
	last_name varchar(100),
	first_name varchar(100),
	Title varchar(100),
	reports_to int,
	Levels varchar(10),
	Birthdate date,
	Hire_date date,
	address varchar(180),
	city varchar(190),
	state varchar(10),
	Country varchar(180),
	postal_code varchar(90),
	phone varchar(100),
	fax varchar(100),
	email varchar(100),
	CONSTRAINT emp_id_fk FOREIGN KEY (reports_to) REFERENCES employee(employee_id)	
);





create table Invoice
(
  Invoice_id int8 PRIMARY KEY,
  Customer_id int8 references customer (customer_id),
  Invoice_date date,
  Billing_address varchar(190),
  Billing_city varchar(180),
  Billing_state varchar(180),
  Billing_country varchar(180),
  Billing_postal_code varchar(190),
  Total Decimal
);



CREATE TABLE invoice_line
(
    Invoice_line int8 primary key,
    Invoice_id int8 references Invoice (Invoice_id),
	Track_id int8,
	Unit_price Decimal,
	Quantity int8
    
);

-- Senior Most employee based on job title.

select * from employee
order by levels desc
limit 1;

-- Which countries have the most invoices
select count(*), billing_country
from invoice
group by billing_country 
order by count(*) desc

-- Top 3 values of total Invoice

select * from invoice
order by total desc
limit 3

-- Find out the city with best customer base, so that the company can throw a promotionl festival event in that city
-- Write a query for that one city that returns highest sum of invoice totals. 
-- Return both city name & sum of invoice total.

select * from invoice

select billing_city, sum(total)as total_invoice
from invoice
group by billing_city 
order by total_invoice desc
limit 1;

-- Which customer has spent the most amount of money.

select * from customer;
select * from invoice;

select first_name, last_name, sum(i.total) as invoice_total
from 
customer c join invoice i  on 
c.customer_id = i.customer_id
group by first_name, last_name
order by invoice_total desc
limit 1;

-- write a querry to return the email, first_name, last_name and genre of all rock music listeners 
--return the listed order alphabetically by email starting with A.

-- Without using Subquerry 
select Distinct email, first_name, last_name, g.name
from genre g join track t on 
g.genre_id = t.genre_id join invoice_line il on 
t.track_id = il.track_id join invoice i on 
i.invoice_id = il.invoice_id join customer c on 
c.customer_id = i.customer_id
where  g.name = 'Rock' 
order by c.email 


-- With Subquerry
select Distinct email, first_name, last_name
from customer c join invoice i on 
c.customer_id = i.customer_id  join invoice_line il  on
il.invoice_id = i.invoice_id
where track_id in 
( select track_id from 
 track t join genre g  on
 t. genre_id = g.genre_id
 where g.name = 'Rock'
)
order by email;

-- Lets invite the artist who have written the most number of rock music
-- Write a query that returns the artist name and total track count of top 10 rock bands.


select a.artist_id, ai.name, count(a.artist_id) as Total_song
from album2 a join track t on
a.album_id = t.album_id join Artist_id ai on 
ai. artist_id = a.artist_id
where genre_id in 
(
select g.genre_id 
from track t join genre g on 
t.genre_id = g.genre_id
where g.name ='Rock'
)
group by a.artist_id, ai.name
order by Total_song desc
limit 10;

-- Return all the track names that have song length more than average song length.
--Return the name and millisecond for each track.
--order by the song legth with longest song listed first.


select * from track

select track_id, name, milliseconds
from track 
where milliseconds < 
(select avg(milliseconds)
from track)
order by milliseconds desc


-- Find how much money spent by each customer on best selling artist? Write a querry to return customer name, artist name and 
-- total spent.




With best_selling_artist as
(
	select ai.artist_id as artist_id, ai.name as artist_name, sum(il.unit_price * il.quantity) as total_spent
 	from artist_id ai join album2 a on 
    ai.artist_id = a.artist_id join track t on 
 	a.album_id = t.album_id join invoice_line il on
 	il.track_id = t.track_id
 	group by 1 , 2
 	order by 3 desc
 	limit 1
)
	select c.customer_id, c.first_name, c.last_name, bsa.artist_id , sum(il.unit_price * il.quantity) as total_spent
 	from customer c join invoice i on 
	c.customer_id = i.customer_id join invoice_line il on
	i.invoice_id = il.invoice_id join track t  on
	t.track_id = il.track_id join album2 a on 
	a.album_id = t.album_id join best_selling_artist  bsa on 
	bsa.artist_id = a.artist_id
	group by c.customer_id,c.first_name, c.last_name, bsa.artist_id
	order by total_spent desc


-- We want to find out the most popular music genre for each country
-- we determine the most popular music genre as the genre with the highest number of purchase.
-- Write a query that returns each country along with the top genre.
-- for the countries where the maximum number of purchases is shared return all genres.
select * from customer

with popular_genre as (
						select count(il.quantity) as purchase, c.country, g.name, g.genre_id,
						ROW_NUMBER() over (partition by c.country order by count(il.quantity) desc) as rank
						from invoice_line il join invoice i on
						il.invoice_id = i.invoice_id join customer c  on
						i.customer_id = c.customer_id join track t on 
						t.track_id = il.track_id join genre g on 
						g.genre_id = t.genre_id 
						group by 2,3,4
						Order by 2 asc, 1 desc
)

select * from popular_genre where rank <= 1






