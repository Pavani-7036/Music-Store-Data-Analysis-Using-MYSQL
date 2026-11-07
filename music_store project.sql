CREATE DATABASE music_store;

USE music_store;

-- 1. Genre and MediaType
CREATE TABLE Genre (
	genre_id INT PRIMARY KEY,
	name VARCHAR(120)
);
SELECT * FROM Genre;

CREATE TABLE MediaType (
	media_type_id INT PRIMARY KEY,
	name VARCHAR(120)
);
SELECT * FROM MediaType;

-- 2. Employee
CREATE TABLE Employee (
	employee_id INT PRIMARY KEY,
	last_name VARCHAR(120),
	first_name VARCHAR(120),
	title VARCHAR(120),
	reports_to INT,
    levels VARCHAR(255),
	birthdate DATE,
	hire_date DATE,
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100)
);
SELECT * FROM employee;

-- 3. Customer
CREATE TABLE Customer (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(120),
	last_name VARCHAR(120),
	company VARCHAR(120),
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100),
	support_rep_id INT,
	FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);
SELECT * FROM Customer;

-- 4. Artist
CREATE TABLE Artist (
	artist_id INT PRIMARY KEY,
	name VARCHAR(120)
);
SELECT * FROM Artist;

-- 5. Album
CREATE TABLE Album (
	album_id INT PRIMARY KEY,
	title VARCHAR(160),
	artist_id INT,
	FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);
SELECT * FROM Album;

-- 6. Track
CREATE TABLE Track (
	track_id INT PRIMARY KEY,
	name VARCHAR(200),
	album_id INT,
	media_type_id INT,
	genre_id INT,
	composer VARCHAR(220),
	milliseconds INT,
	bytes INT,
	unit_price DECIMAL(10,2),
	FOREIGN KEY (album_id) REFERENCES Album(album_id),
	FOREIGN KEY (media_type_id) REFERENCES MediaType(media_type_id),
	FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);
SELECT * FROM track;

-- 7. Invoice  
CREATE TABLE Invoice (
	invoice_id INT PRIMARY KEY,
	customer_id INT,
	invoice_date DATE,
	billing_address VARCHAR(255),
	billing_city VARCHAR(100),
	billing_state VARCHAR(100),
	billing_country VARCHAR(100),
	billing_postal_code VARCHAR(20),
	total DECIMAL(10,2),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);
SELECT * FROM Invoice;

-- 8. InvoiceLine
CREATE TABLE InvoiceLine (
	invoice_line_id INT PRIMARY KEY,
	invoice_id INT,
	track_id INT,
	unit_price DECIMAL(10,2),
	quantity INT,
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);
SELECT * FROM Invoiceline;

-- 9. Playlist
CREATE TABLE Playlist (
 	playlist_id INT PRIMARY KEY,
	name VARCHAR(255)
);
SELECT * FROM playlist;

-- 10. PlaylistTrack
CREATE TABLE PlaylistTrack (
	playlist_id INT,
	track_id INT,
	PRIMARY KEY (playlist_id, track_id),
	FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);
SELECT * FROM playlistTrack;


-- 1. Who is the senior most employee based on job title?
SELECT employee_id,last_name,first_name,levels
FROM employee
ORDER BY levels Desc
LIMIT 1;

-- Insight : The senior-most employee is Andrew Adams, who holds the General Manager position.

-- 2. Which countries have the most Invoices?
SELECT billing_country, invoice_count
FROM (
    SELECT 
        billing_country,
        COUNT(invoice_id) AS invoice_count
    FROM Invoice
    GROUP BY billing_country
) AS country_counts
ORDER BY invoice_count DESC;

-- Insight : USA is the top-generating market, driving the highest overall sales revenue across all global regions, followed by other countries like canada, brazil.

-- 3. What are the top 3 values of total invoice?
SELECT customer_id, total
FROM Invoice
WHERE total >= (
    SELECT MIN(total)
    FROM (
        SELECT DISTINCT total
        FROM Invoice
    ) AS top_totals
)
ORDER BY total DESC
LIMIT 3;

-- Insight : The highest invoice value is 23.76 for customer 42, followed by 19.80 for customers 32 and 3.

-- 4. Which city has the best customers? - 
-- Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
SELECT 
    billing_city, 
    total_sales
FROM (
    SELECT 
        billing_city, 
        SUM(total) AS total_sales
    FROM Invoice
    GROUP BY billing_city
) AS CitySales
ORDER BY total_sales DESC
LIMIT 1;

-- Insight: Prague generated the highest total invoice sales ($273.24), making it the optimal geographic location to host the upcoming promotional music festival or live concert event

-- 5. Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.last_name,
        c.first_name,
        SUM(i.total) AS total_money_spent
    FROM customer c
    JOIN Invoice i
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.last_name, c.first_name
)

SELECT *
FROM customer_spending
ORDER BY total_money_spent DESC
LIMIT 1;
-- Insight : Identifies the customer who has spent the highest total amount, helping the business understand its highest-value customer.

-- 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 

DELIMITER $$
CREATE PROCEDURE music_listener(IN genre_name VARCHAR(50))
BEGIN
    SELECT DISTINCT
        c.email,
        c.first_name,
        c.last_name,
        g.name AS genre
    FROM Customer c
    JOIN Invoice i
        ON c.customer_id = i.customer_id
    JOIN InvoiceLine il
        ON i.invoice_id = il.invoice_id
    JOIN Track t
        ON il.track_id = t.track_id
    JOIN Genre g
        ON t.genre_id = g.genre_id
    WHERE g.name = genre_name
    ORDER BY c.email;
END $$
DELIMITER ;
CALL music_listener('Rock');

-- Insight : The analysis identifies customers who have purchased Rock music, showing their email, first name, last name, and the Rock genre.

-- 7. Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT ar.name, count(t.track_id) AS total_trackcount
FROM Artist ar
JOIN ALBUM al
ON ar.artist_id = al.artist_id
JOIN Track t
    ON al.album_id = t.album_id
JOIN Genre g
    ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_trackcount DESC
LIMIT 10;

-- Insight : AC/DC has the highest number of Rock tracks with 18 tracks, followed by Aerosmith with 15 tracks. Other leading Rock artists include Audioslave and Led Zeppelin.

-- 8. Return all the track names that have a song length longer than the average song length.- 
-- Return the Name and Milliseconds for each track. Order by the song length, with the longest songs listed first .

SELECT name, milliseconds
FROM Track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM Track
)
ORDER BY milliseconds DESC;

-- 	Insight : The analysis identifies tracks that are longer than the average song length, with “How Many More Times” having the longest duration among the displayed tracks.

-- 9. Find how much amount is spent by each customer on artists? Write a query to return  customer name, artist name and total spent.

CREATE VIEW customer_artist_spending AS
SELECT 
    c.last_name,
    c.first_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM Customer c
JOIN Invoice i
    ON c.customer_id = i.customer_id
JOIN InvoiceLine il
    ON i.invoice_id = il.invoice_id
JOIN Track t
    ON il.track_id = t.track_id
JOIN Album al
    ON t.album_id = al.album_id
JOIN Artist ar
    ON al.artist_id = ar.artist_id
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name,
    ar.artist_id,
    ar.name;
SELECT *
FROM customer_artist_spending
ORDER BY total_spent DESC;

-- Insight :  The output shows the total amount spent by each customer on individual artists, helping identify customer spending patterns and artist preferences.

-- 10.Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared, return all Genres.

DELIMITER $$

CREATE PROCEDURE top_most_genre_bycountry()
BEGIN

    SELECT *
    FROM (
        SELECT
            i.billing_country,
            g.name AS genre,
            SUM(il.quantity) AS purchases,
            RANK() OVER (
                PARTITION BY i.billing_country
                ORDER BY SUM(il.quantity) DESC
            ) AS rnk
        FROM Invoice i
        JOIN InvoiceLine il
            ON i.invoice_id = il.invoice_id
        JOIN Track t
            ON il.track_id = t.track_id
        JOIN Genre g
            ON t.genre_id = g.genre_id
        GROUP BY 
            i.billing_country,
            g.name
    ) AS x
    WHERE rnk = 1
    ORDER BY billing_country;

END $$

DELIMITER ;

CALL top_most_genre_bycountry();

-- Insight : Rock emerges as the #1 performing genre across major markets, including Argentina, Australia, Austria, Belgium, and Brazil. 

-- 11. Write a query that determines the customer that has spent the most on music for each country. 
SELECT *
FROM (
    SELECT
        i.billing_country,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(i.total) AS total_spent,
        RANK() OVER (
            PARTITION BY i.billing_country
            ORDER BY SUM(i.total) DESC
        ) AS rnk
    FROM Customer c
    JOIN Invoice i
        ON c.customer_id = i.customer_id
    GROUP BY
        i.billing_country,
        c.customer_id,
        c.first_name,
        c.last_name
) x
WHERE rnk = 1
ORDER BY billing_country;

-- Insight :  The analysis identifies the highest-spending customer in each country. For example, Diego Gutiérrez is the highest spender in Argentina with 39.60, while Mark Taylor leads Australia with 81.18.

