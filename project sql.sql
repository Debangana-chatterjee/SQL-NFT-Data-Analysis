USE cryptopunk;
SELECT * FROM cryptopunkdata;
ALTER TABLE cryptopunkdata
RENAME COLUMN ï»¿buyer_address to buyer_address;

-- Q1. How many sales occurred during this time period? 
SELECT COUNT(*) FROM cryptopunkdata;

-- Q2.Return the top 5 most expensive transactions (by USD price) for this data set. 
--  Return the name, ETH price, and USD price, as well as the date.
SELECT name, eth_price, usd_price, day
FROM cryptopunkdata
ORDER BY usd_price DESC
LIMIT 5;

-- Q3. Return a table with a row for each transaction with an event column, a USD price column,
-- and a moving average of USD price that averages the last 50 transactions.
SELECT transaction_hash AS event, usd_price, 
AVG(usd_price)OVER(ORDER BY day ROWS BETWEEN 49 preceding AND CURRENT ROW) AS usd_mov_avg
FROM cryptopunkdata;

-- Q4.Return all the NFT names and their average sale price in USD. Sort descending. 
-- Name the average column as average_price.
SELECT name, AVG(usd_price) AS average_price
FROM cryptopunkdata
GROUP BY name
ORDER BY average_price DESC;

-- Q5.Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. 
-- Order by the count of transactions in ascending order.
SELECT dayofweek(day) AS day_of_week, COUNT(*) AS num_of_sales, AVG(eth_price)
FROM cryptopunkdata
GROUP BY day_of_week
ORDER BY num_of_sales;

-- Q6.Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date,
-- and what price it was sold for in USD rounded to the nearest thousandth.
SELECT CONCAT(name," ", 'was sold for $'," ", 
ROUND(usd_price,-3)," ",'to'," ", seller_address," ",'from'," ", buyer_address," ", 'on'," ", day) AS summary
FROM cryptopunkdata;

-- Q7.Create a view called “1919_purchases” and contains any sales
--  where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
CREATE VIEW 1919_purchases AS 
SELECT * FROM cryptopunkdata
WHERE buyer_address="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

-- Q8.Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT ROUND(eth_price,-2) AS bucket,
COUNT(*) AS count,
RPAD(' ', COUNT(*),'*') AS bar
FROM cryptopunkdata
GROUP BY bucket
ORDER BY bucket DESC;

-- Q9.Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying 
-- “highest” with a query that has the lowest price each NFT was bought for and 
-- the status column saying “lowest”. The table should have a name column, 
-- a price column called price, and a status column. Order the result set by the name of the NFT, 
-- and the status, in ascending order. 
SELECT name,MAX(eth_price) AS price,
'Highest' AS status
FROM cryptopunkdata
GROUP BY name
UNION
SELECT name, MIN(eth_price) AS price,
'Lowest' AS status
FROM cryptopunkdata
GROUP BY name
ORDER BY name,status;

-- Q10.What NFT sold the most each month / year combination? 
-- Also, what was the name and the price in USD? Order in chronological format. 
SELECT name,usd_price,sale_year,sale_month,sales_count,rank_of_month 
FROM
(SELECT name, MAX(usd_price) AS usd_price, YEAR(day) AS sale_year,MONTH(day) AS sale_month,
COUNT(*) AS sales_count,
DENSE_RANK() OVER(PARTITION BY YEAR(day), MONTH(day) ORDER BY COUNT(*)DESC) AS rank_of_month
FROM cryptopunkdata
GROUP BY name, YEAR(day),MONTH(day)) AS most_sold
WHERE rank_of_month=1;

-- Q11.Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).
SELECT YEAR(day) AS sale_year,MONTH(day) AS sale_month, COUNT(*) AS total_volume
FROM cryptopunkdata
GROUP BY YEAR(day), MONTH(day)
ORDER BY YEAR(day), MONTH(day);

-- Q12.Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period
SELECT COUNT(*) FROM cryptopunkdata
WHERE buyer_address='0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
OR seller_address='0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- Q13.Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 -- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 -- Take the daily average of remaining transactions
 -- a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
-- b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value
-- which is just the daily average of the filtered data.
 CREATE TEMPORARY TABLE avg_usd_price_per_day AS
 SELECT day,usd_price, AVG(usd_price)OVER(PARTITION BY day) AS daily_avg
 FROM cryptopunkdata;
 
 SELECT*,AVG(usd_price)OVER(PARTITION BY day) AS new_estimated_value
 FROM avg_usd_price_per_day
 WHERE usd_price>(0.9*daily_avg);