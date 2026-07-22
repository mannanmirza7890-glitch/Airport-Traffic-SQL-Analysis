
-- AIRPORT PASSENGER TRAFFIC - CASE STUDY SOLUTION




-- 1. Analyze total passenger traffic per route and over time


-- 1a. Top 5 busiest routes by total passenger traffic
-- Result: 
--   Miami, FL        -> New York, NY
--   New York, NY     -> Miami, FL
--   Orlando, FL      -> New York, NY
--   New York, NY     -> Orlando, FL
--   New York, NY     -> Chicago, IL
SELECT
    ORIGIN_CITY_NAME,
    DEST_CITY_NAME,
    SUM(PASSENGERS) AS total_passengers
FROM airport_data
GROUP BY ORIGIN_CITY_NAME, DEST_CITY_NAME
ORDER BY total_passengers DESC
LIMIT 5;


-- 1b. Least busiest routes (excluding routes with zero passengers and same origin/destination)
SELECT
    ORIGIN_CITY_NAME,
    DEST_CITY_NAME,
    SUM(PASSENGERS) AS total_passengers
FROM airport_data
WHERE ORIGIN_CITY_NAME <> DEST_CITY_NAME
GROUP BY ORIGIN_CITY_NAME, DEST_CITY_NAME
HAVING SUM(PASSENGERS) > 0
ORDER BY total_passengers ASC
LIMIT 5;


-- =====================================================================
-- 2. Determine average passengers per flight for various routes and airports
-- =====================================================================

-- 2a. Average passengers per flight, by route
SELECT
    ORIGIN_CITY_NAME,
    DEST_CITY_NAME,
    AVG(PASSENGERS) AS avg_passengers
FROM airport_data
GROUP BY ORIGIN_CITY_NAME, DEST_CITY_NAME
ORDER BY avg_passengers DESC;


-- 2b. Average passengers per flight, by airport (combining outbound + inbound averages)
WITH outgoing_passengers AS (
    SELECT ORIGIN_AIRPORT_ID, AVG(PASSENGERS) AS avg_passengers
    FROM airport_data
    GROUP BY ORIGIN_AIRPORT_ID
),
incoming_passengers AS (
    SELECT DEST_AIRPORT_ID, AVG(PASSENGERS) AS avg_passengers
    FROM airport_data
    GROUP BY DEST_AIRPORT_ID
),
all_airports AS (
    SELECT DISTINCT ORIGIN_AIRPORT_ID AS airport_id FROM airport_data
    UNION
    SELECT DISTINCT DEST_AIRPORT_ID AS airport_id FROM airport_data
)
SELECT
    aa.airport_id,
    op.avg_passengers + ip.avg_passengers AS total_passenger_travelling
FROM all_airports aa
LEFT JOIN outgoing_passengers op ON aa.airport_id = op.ORIGIN_AIRPORT_ID
LEFT JOIN incoming_passengers ip ON aa.airport_id = ip.DEST_AIRPORT_ID
WHERE op.avg_passengers + ip.avg_passengers IS NOT NULL
ORDER BY total_passenger_travelling DESC;


-- =====================================================================
-- 3. Assess flight frequency and identify high-traffic corridors
-- =====================================================================

SELECT
    ORIGIN_CITY_NAME,
    DEST_CITY_NAME,
    COUNT(AIRLINE_ID) AS total_flights
FROM airport_data
GROUP BY ORIGIN_CITY_NAME, DEST_CITY_NAME
ORDER BY total_flights DESC
LIMIT 10;


-- =====================================================================
-- 5. Evaluate available seat capacity to understand seat utilization for each airline
-- =====================================================================

WITH seating_capacity AS (
    SELECT AIRLINE_ID, MAX(PASSENGERS) AS seat_capacity
    FROM airport_data
    GROUP BY AIRLINE_ID
    HAVING MAX(PASSENGERS) > 0
),
seat_utilization AS (
    SELECT
        ad.AIRLINE_ID,
        ad.PASSENGERS * 100.00 / sc.seat_capacity AS seat_utilization
    FROM airport_data ad
    JOIN seating_capacity sc ON ad.AIRLINE_ID = sc.AIRLINE_ID
)
SELECT
    AIRLINE_ID,
    ROUND(AVG(seat_utilization), 2) AS avg_seat_utilization
FROM seat_utilization
GROUP BY AIRLINE_ID
ORDER BY avg_seat_utilization DESC;


-- =====================================================================
-- 6. Identify popular destination airports based on inbound passenger counts
-- =====================================================================

SELECT
    DEST_AIRPORT_ID,
    DEST_CITY_NAME,
    SUM(PASSENGERS) AS inbound_passengers
FROM airport_data
GROUP BY DEST_AIRPORT_ID, DEST_CITY_NAME
ORDER BY inbound_passengers DESC
LIMIT 10;  -- Top 10


-- =====================================================================
-- 7. Examine the relationship between city population and airport passenger traffic
-- =====================================================================

WITH outgoing_passengers AS (
    SELECT ORIGIN_AIRPORT_ID, SUM(PASSENGERS) AS TOT_passengers
    FROM airport_data
    GROUP BY ORIGIN_AIRPORT_ID
),
incoming_passengers AS (
    SELECT DEST_AIRPORT_ID, SUM(PASSENGERS) AS TOT_passengers
    FROM airport_data
    GROUP BY DEST_AIRPORT_ID
),
all_airports AS (
    SELECT DISTINCT ORIGIN_AIRPORT_ID AS airport_id, ORIGIN_CITY_NAME AS city_name
    FROM airport_data
    UNION
    SELECT DISTINCT DEST_AIRPORT_ID AS airport_id, DEST_CITY_NAME AS city_name
    FROM airport_data
),
passenger_traffic AS (
    SELECT
        SUBSTRING(aa.city_name, 1, INSTR(aa.city_name, ',') - 1) AS city_name,
        op.TOT_passengers + ip.TOT_passengers AS total_passenger_travelling
    FROM all_airports aa
    LEFT JOIN outgoing_passengers op ON aa.airport_id = op.ORIGIN_AIRPORT_ID
    LEFT JOIN incoming_passengers ip ON aa.airport_id = ip.DEST_AIRPORT_ID
    WHERE op.TOT_passengers + ip.TOT_passengers IS NOT NULL
)
SELECT
    cp.city_name,
    cp.Population,
    pt.total_passenger_travelling
FROM passenger_traffic pt
JOIN city_population cp ON pt.city_name = cp.city_name
WHERE cp.Population IS NOT NULL
  AND pt.total_passenger_travelling IS NOT NULL
  AND cp.Population <> 0
ORDER BY cp.Population ASC;
