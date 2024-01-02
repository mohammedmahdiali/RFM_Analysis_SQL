USE sales0;

SELECT * FROM sales;

SELECT DISTINCT STATUS FROM sales;
SELECT DISTINCT QTR_ID FROM sales;
SELECT DISTINCT YEAR_ID FROM sales;
SELECT DISTINCT PRODUCTLINE FROM sales;
SELECT DISTINCT CITY FROM sales;
SELECT DISTINCT COUNTRY FROM sales;
SELECT DISTINCT DEALSIZE FROM sales;

SELECT PRODUCTLINE, SUM(SALES) as Revenue
FROM sales
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;

SELECT YEAR_ID, SUM(SALES) as Revenue
FROM sales
GROUP BY YEAR_ID
ORDER BY 2 DESC;

SELECT DISTINCT MONTH_ID
FROM sales
WHERE YEAR_ID = 2005;

SELECT DEALSIZE, SUM(SALES) as Revenue
FROM sales
GROUP BY DEALSIZE
ORDER BY 2 DESC;

-- What was the best month for sales in a specific year? How much was earned that month?
SELECT MONTH_ID, SUM(SALES) as Revenue, COUNT(ORDERNUMBER) as Frequency
FROM sales
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC;

-- What product do the sell in November?
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) as Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

-- Who is our best customer?
DROP TABLE IF EXISTS new_rfm_table;
CREATE TABLE new_rfm_table AS
WITH rfm AS (
    SELECT
        CUSTOMERNAME,
        COUNT(ORDERNUMBER) AS Frequency,
        SUM(SALES) AS MonetaryValue,
        AVG(SALES) AS AVGMonetaryValue,
        MAX(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i')) AS LastOrderDate,
        (SELECT MAX(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i')) FROM sales) AS MaxOrderDate,
        DATEDIFF((SELECT MAX(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i')) FROM sales), MAX(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i'))) AS Recency
    FROM
        sales
    GROUP BY
        CUSTOMERNAME
),
rfm_calc AS (
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
    FROM rfm AS r
)
SELECT
    c.*,
    rfm_recency + rfm_frequency + rfm_monetary AS rfm_score,
    CONCAT(
        CAST(rfm_recency AS CHAR),
        CAST(rfm_frequency AS CHAR),
        CAST(rfm_monetary AS CHAR)
    ) AS rfm_score_string
FROM rfm_calc AS c;

SELECT CUSTOMERNAME, rfm_score, rfm_score_string,
	CASE 
		WHEN rfm_score_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  -- lost customers
		WHEN rfm_score_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- Big spenders who haven’t purchased lately
		WHEN rfm_score_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_score_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_score_string in (323, 333,321, 422, 332, 432) THEN 'active' -- Customers who buy often & recently, but at low price points
		WHEN rfm_score_string in (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment
FROM new_rfm_table
ORDER BY rfm_score DESC;

-- تجربة لمعرفة فورمات التاريخ
-- SELECT STR_TO_DATE('2/24/2003 0:00', '%m/%d/%Y %H:%i') AS converted_date;

-- What products are most often sold together?
SELECT ORDERNUMBER, GROUP_CONCAT(PRODUCTCODE SEPARATOR ',') AS PRODUCTCODE, GROUP_CONCAT(PRODUCTLINE SEPARATOR ',') AS ConcatenatedProductLines
FROM sales
WHERE ORDERNUMBER IN (
	SELECT ORDERNUMBER
	FROM (
		SELECT ORDERNUMBER, COUNT(*) AS cnt
		FROM sales
		WHERE STATUS = "Shipped"
		GROUP BY ORDERNUMBER
		) AS PT
	WHERE cnt = 2
	)
GROUP BY ORDERNUMBER;