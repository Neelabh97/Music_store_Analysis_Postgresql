# Music Store Analysis PostgreSQL Project

This repository contains SQL code for setting up a PostgreSQL database for music analysis purposes. The database schema includes tables for artists, albums, tracks, genres, playlists, customers, employees, invoices, and invoice lines. Additionally, it provides SQL queries to perform various analyses on the data.

## Database Schema Diagram
![Database Schema](/Music_Analysis_Schema.png)


## Schema

### Artist
```sql
CREATE TABLE public.Artist_id
(
    artist_id int8 PRIMARY KEY,
    name varchar(100)
);
```

### Album
```sql
CREATE TABLE public.album2
(
    album_id int8 PRIMARY KEY,
    title character varying,
    artist_id int8 references Artist_id (artist_id)
);
```

### Media Type
```sql
CREATE TABLE Media 
(
 Media_Type int8 primary key,
 Name varchar(180)
);
```

### Genre
```sql
CREATE TABLE Genre
(
    Genre_id int8 PRIMARY KEY,
    name varchar(100)
);
```

### Track
```sql
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
```

### Playlist
```sql
Create Table playlist
(
  Playlist_Id int8 primary key,
  Name Varchar(180)
);
```

### Playlist Track
```sql
create table playlist_track
(
  Playlist_id int8 references playlist (playlist_id),
  Track_id int8  references track (Track_id)
);
```

### Customer
```sql
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
```

### Employee
```sql
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
```

### Invoice
```sql
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
```

### Invoice Line
```sql
CREATE TABLE invoice_line
(
    Invoice_line int8 primary key,
    Invoice_id int8 references Invoice (Invoice_id),
    Track_id int8,
    Unit_price Decimal,
    Quantity int8
);
```

## SQL Queries

Below are some SQL queries to perform various analyses on the music data:

1. **Senior Most Employee Based on Job Title**
```sql
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;
```

2. **Countries with the Most Invoices**
```sql
SELECT COUNT(*), billing_country
FROM invoice
GROUP BY billing_country 
ORDER BY COUNT(*) DESC;
```

3. **Top 3 Values of Total Invoice**
```sql
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;
```

4. **City with the Best Customer Base**
```sql
SELECT billing_city, SUM(total) AS total_invoice
FROM invoice
GROUP BY billing_city 
ORDER BY total_invoice DESC
LIMIT 1;
```

5. **Customer Who Spent the Most Amount of Money**
```sql
SELECT first_name, last_name, SUM(i.total) AS invoice_total
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY first_name, last_name
ORDER BY invoice_total DESC
LIMIT 1;
```

6. **Rock Music Listeners (Without Using Subquery)**
```sql
SELECT DISTINCT email, first_name, last_name, g.name AS genre
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON i.invoice_id = il.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
WHERE g.name = 'Rock' 
ORDER BY c.email;
```

7. **Rock Music Listeners (With Subquery)**
```sql
SELECT DISTINCT email, first_name, last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id  
JOIN invoice_line il  ON il.invoice_id = i.invoice_id
WHERE track_id IN 
    (SELECT track_id FROM track t JOIN genre g ON t.genre_id = g.genre_id WHERE g.name = 'Rock')
ORDER BY email;
```

8. **Top 10 Rock Bands**
```sql
SELECT a.artist_id, ai.name, COUNT(a.artist_id) AS total_song
FROM album2 a
JOIN track t ON a.album_id = t.album_id
JOIN Artist_id ai ON ai.artist_id = a.artist_id
WHERE genre_id IN 
    (SELECT g.genre_id FROM track t JOIN genre g ON t.genre_id = g.genre_id WHERE g.name ='Rock')
GROUP BY a.artist_id, ai.name
ORDER BY total_song DESC
LIMIT 10;
```

9. **Tracks with Song Length More Than Average**
```sql
SELECT track_id, name, milliseconds
FROM track 
WHERE milliseconds < (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;
```

10. **Customers' Spending on Best Selling Artist**
```sql
WITH best_selling_artist AS (
    SELECT ai.artist_id AS artist_id, ai.name AS artist_name, SUM(il.unit_price * il.quantity) AS total_spent
    FROM artist_id ai
    JOIN album2 a ON ai.artist_id = a.artist_id
    JOIN track t ON a.album_id = t.album_id
    JOIN invoice_line il ON il.track_id = t.track_id
    GROUP BY 1 , 2
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_id, SUM(il.unit_price * il.quantity) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 a ON a.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = a.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_id
ORDER BY total_spent DESC;
```

11. **Most Popular Music Genre for Each Country**
```sql


WITH popular_genre AS (
    SELECT COUNT(il.quantity) AS purchase, c.country, g.name, g.genre_id,
    ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS rank
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id 
    GROUP BY 2, 3, 4
    ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE rank <= 1;
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Feel free to customize and extend this SQL code according to your specific requirements. If you have any questions or suggestions, please feel free to reach out. 
[![LinkedIn](https://img.shields.io/badge/-LinkedIn-blue?style=flat-square&logo=linkedin&logoColor=white)]([https://www.linkedin.com/in/your-profile-url](https://www.linkedin.com/in/neelabh-bhardwaj-525aa2113/))

