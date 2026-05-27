-- ============================================================
--   NETFLIX CONTENT ANALYSIS - SQL PROJECT
--   Dataset : Netflix Titles (Kaggle) | ~8,800 rows
--   Tools   : PostgreSQL / MySQL / SQLite compatible
--   Author  : [Your Name]
-- ============================================================


-- ============================================================
-- SECTION 1 : DATABASE SETUP & TABLE CREATION
-- ============================================================

CREATE TABLE netflix_titles (
    show_id       VARCHAR(10)   PRIMARY KEY,
    type          VARCHAR(10),          -- 'Movie' or 'TV Show'
    title         VARCHAR(300),
    director      VARCHAR(300),
    cast          TEXT,
    country       VARCHAR(200),
    date_added    VARCHAR(50),
    release_year  INT,
    rating        VARCHAR(20),
    duration      VARCHAR(20),          -- '90 min' or '2 Seasons'
    listed_in     VARCHAR(300),         -- genres
    description   TEXT
);

-- NOTE FOR INTERVIEW:
-- I chose VARCHAR lengths based on actual data inspection.
-- 'listed_in' holds comma-separated genres so TEXT/VARCHAR(300) is needed.
-- show_id is the natural primary key since every row has a unique id like s1, s2 ...


-- ============================================================
-- SECTION 2 : DATA EXPLORATION (always do this first)
-- ============================================================

-- 2.1  Total number of titles
SELECT COUNT(*) AS total_titles
FROM netflix_titles;
-- Result: 8807


-- 2.2  How many Movies vs TV Shows?
SELECT type,
       COUNT(*) AS total
FROM netflix_titles
GROUP BY type;
-- Result: Movie → 6131 | TV Show → 2676


-- 2.3  Check for NULL values in important columns
SELECT
    COUNT(*) - COUNT(director) AS missing_director,
    COUNT(*) - COUNT(cast)     AS missing_cast,
    COUNT(*) - COUNT(country)  AS missing_country,
    COUNT(*) - COUNT(rating)   AS missing_rating
FROM netflix_titles;
-- Result: director→2634, cast→825, country→831, rating→4
-- NOTE FOR INTERVIEW:
-- This is important before writing any analysis query so we know
-- which columns need NULL handling (using COALESCE or IS NOT NULL filters).


-- ============================================================
-- SECTION 3 : BASIC SELECT & FILTERING
-- ============================================================

-- 3.1  All Indian movies added to Netflix
SELECT title, director, release_year, rating
FROM netflix_titles
WHERE country = 'India'
  AND type    = 'Movie'
ORDER BY release_year DESC;


-- 3.2  Top 10 most recent titles added on Netflix
SELECT title, type, date_added, country
FROM netflix_titles
WHERE date_added IS NOT NULL
ORDER BY date_added DESC
LIMIT 10;


-- 3.3  All TV Shows with more than 1 season
-- The duration column stores values like '1 Season', '2 Seasons'
SELECT title, duration, country
FROM netflix_titles
WHERE type     = 'TV Show'
  AND duration != '1 Season'
ORDER BY title;


-- 3.4  Content rated TV-MA (most mature) -- what is available?
SELECT title, type, country, release_year
FROM netflix_titles
WHERE rating = 'TV-MA'
ORDER BY release_year DESC
LIMIT 20;


-- ============================================================
-- SECTION 4 : AGGREGATE FUNCTIONS
-- ============================================================

-- 4.1  Count of titles per country (Top 10 content-producing countries)
SELECT country,
       COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10;
-- Result: United States→2818, India→972, United Kingdom→419 ...


-- 4.2  Number of titles added each year (content growth trend)
SELECT release_year,
       COUNT(*) AS titles_released
FROM netflix_titles
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 15;


-- 4.3  Most common content ratings on Netflix
SELECT rating,
       COUNT(*) AS count
FROM netflix_titles
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY count DESC;
-- Result: TV-MA→3207, TV-14→2160, TV-PG→863 ...


-- 4.4  Average number of titles added per country (only countries with 10+ titles)
SELECT country,
       COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
HAVING COUNT(*) >= 10
ORDER BY total_titles DESC;
-- NOTE FOR INTERVIEW:
-- HAVING filters AFTER grouping. WHERE filters BEFORE grouping.
-- You cannot use WHERE COUNT(*) >= 10 — that's a common mistake.


-- ============================================================
-- SECTION 5 : STRING FUNCTIONS & PATTERN MATCHING
-- ============================================================

-- 5.1  Search for titles related to 'Love' (using LIKE)
SELECT title, type, release_year
FROM netflix_titles
WHERE title LIKE '%Love%';


-- 5.2  Find all titles directed by Christopher Nolan
SELECT title, release_year, rating, duration
FROM netflix_titles
WHERE director LIKE '%Christopher Nolan%';


-- 5.3  Titles where a specific actor appears in the cast
SELECT title, cast, country
FROM netflix_titles
WHERE cast LIKE '%Shah Rukh Khan%';


-- 5.4  Extract only the numeric part of duration for Movies
-- (so '90 min' becomes 90 — useful for finding longest movies)
SELECT title,
       duration,
       CAST(REPLACE(duration, ' min', '') AS UNSIGNED) AS minutes
FROM netflix_titles
WHERE type     = 'Movie'
  AND duration IS NOT NULL
ORDER BY minutes DESC
LIMIT 10;
-- NOTE FOR INTERVIEW:
-- I used REPLACE() to strip the ' min' text and CAST() to convert to a number.
-- This is a common data-cleaning trick when numeric data is stored as text.


-- ============================================================
-- SECTION 6 : JOINS  (using a self-created directors table)
-- ============================================================

-- First, create a separate directors table to demonstrate JOIN
CREATE TABLE directors (
    director_id   INT           PRIMARY KEY AUTO_INCREMENT,
    director_name VARCHAR(300),
    nationality   VARCHAR(100)
);

INSERT INTO directors (director_name, nationality) VALUES
('Rajkumar Hirani',    'Indian'),
('Anurag Kashyap',     'Indian'),
('Zack Snyder',        'American'),
('David Fincher',      'American'),
('Bong Joon-ho',       'South Korean'),
('Quentin Tarantino',  'American'),
('Kirsten Johnson',    'American'),
('Julien Leclercq',    'French');


-- 6.1  INNER JOIN — titles where we have director info in BOTH tables
-- Returns only rows that have a match in both tables
SELECT n.title,
       n.type,
       n.release_year,
       d.nationality
FROM netflix_titles n
INNER JOIN directors d
    ON n.director = d.director_name
ORDER BY n.release_year DESC;

-- NOTE FOR INTERVIEW:
-- INNER JOIN returns only matching rows from both tables.
-- If a director is in netflix_titles but NOT in our directors table,
-- that title will NOT appear in the result.


-- 6.2  LEFT JOIN — all Netflix titles, with director nationality where available
-- Returns ALL rows from the left table (netflix_titles),
-- and matching rows from directors (NULL if no match)
SELECT n.title,
       n.director,
       n.release_year,
       d.nationality
FROM netflix_titles n
LEFT JOIN directors d
    ON n.director = d.director_name
ORDER BY n.release_year DESC
LIMIT 20;

-- NOTE FOR INTERVIEW:
-- LEFT JOIN keeps every row from the LEFT table (netflix_titles).
-- If there is no matching director in our directors table, the
-- nationality column shows NULL — but the title still appears.
-- This is useful when you don't want to lose data that has no match.


-- 6.3  Find directors in our directors table who have NO titles on Netflix
SELECT d.director_name
FROM directors d
LEFT JOIN netflix_titles n
    ON d.director_name = n.director
WHERE n.director IS NULL;

-- NOTE FOR INTERVIEW:
-- This is a classic "find unmatched rows" pattern using LEFT JOIN + WHERE IS NULL.


-- ============================================================
-- SECTION 7 : SUBQUERIES
-- ============================================================

-- 7.1  Titles released in the same year as the most recent title on Netflix
SELECT title, type, release_year
FROM netflix_titles
WHERE release_year = (
    SELECT MAX(release_year) FROM netflix_titles
);
-- NOTE FOR INTERVIEW:
-- The inner query runs first and finds the maximum year.
-- The outer query then uses that result as a filter.


-- 7.2  Countries that produce MORE titles than the average country
SELECT country,
       COUNT(*) AS total
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
HAVING COUNT(*) > (
    SELECT AVG(country_count)
    FROM (
        SELECT COUNT(*) AS country_count
        FROM netflix_titles
        WHERE country IS NOT NULL
        GROUP BY country
    ) AS country_stats
);
-- NOTE FOR INTERVIEW:
-- This is a nested subquery (subquery inside a subquery).
-- The innermost query counts titles per country.
-- The middle subquery finds the average of those counts.
-- The outer query keeps only countries above that average.


-- ============================================================
-- SECTION 8 : VIEWS  (saving a query as a reusable virtual table)
-- ============================================================

-- 8.1  Create a view for Indian content only
CREATE VIEW indian_content AS
SELECT show_id, title, type, director, release_year, rating, duration, listed_in
FROM netflix_titles
WHERE country = 'India';

-- Now you can query it like a normal table:
SELECT * FROM indian_content
WHERE type = 'Movie'
ORDER BY release_year DESC;

-- NOTE FOR INTERVIEW:
-- A VIEW does not store data. It stores the SELECT query.
-- Every time you query the view, it runs the underlying query.
-- It's useful for simplifying complex queries and controlling what data users can access.


-- 8.2  View for content added after 2019
CREATE VIEW recent_content AS
SELECT title, type, country, date_added, rating
FROM netflix_titles
WHERE release_year >= 2019;

SELECT * FROM recent_content
WHERE country = 'India';


-- ============================================================
-- SECTION 9 : CASE STATEMENT (conditional logic in SQL)
-- ============================================================

-- 9.1  Categorize content by rating into age groups
SELECT title,
       rating,
       CASE
           WHEN rating IN ('G', 'TV-G', 'TV-Y')           THEN 'Kids'
           WHEN rating IN ('PG', 'TV-Y7', 'TV-PG')        THEN 'Family'
           WHEN rating IN ('PG-13', 'TV-14')               THEN 'Teens'
           WHEN rating IN ('R', 'TV-MA', 'NC-17')          THEN 'Adults'
           ELSE                                                  'Unknown'
       END AS age_group
FROM netflix_titles
WHERE rating IS NOT NULL
ORDER BY age_group;

-- NOTE FOR INTERVIEW:
-- CASE WHEN is like an if-else statement in SQL.
-- It lets you create a new column based on conditions in existing columns.


-- 9.2  Count how many titles fall in each age group
SELECT
    CASE
        WHEN rating IN ('G', 'TV-G', 'TV-Y')        THEN 'Kids'
        WHEN rating IN ('PG', 'TV-Y7', 'TV-PG')     THEN 'Family'
        WHEN rating IN ('PG-13', 'TV-14')            THEN 'Teens'
        WHEN rating IN ('R', 'TV-MA', 'NC-17')       THEN 'Adults'
        ELSE                                              'Unknown'
    END AS age_group,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY age_group
ORDER BY total DESC;


-- ============================================================
-- SECTION 10 : BUSINESS INSIGHT QUERIES
-- (These are the ones to highlight in your resume!)
-- ============================================================

-- 10.1  Which director has the most titles on Netflix?
SELECT director,
       COUNT(*) AS total_titles
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total_titles DESC
LIMIT 10;


-- 10.2  What percentage of Netflix content is Movies vs TV Shows?
SELECT type,
       COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix_titles), 2) AS percentage
FROM netflix_titles
GROUP BY type;


-- 10.3  Top 5 genres (listed_in) on Netflix
-- Note: genres are comma-separated in one column, so we count raw appearances
SELECT listed_in,
       COUNT(*) AS count
FROM netflix_titles
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY count DESC
LIMIT 10;


-- 10.4  How has Netflix content grown year over year? (Movies only)
SELECT release_year,
       COUNT(*) AS movies_added
FROM netflix_titles
WHERE type = 'Movie'
  AND release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 15;


-- 10.5  Countries that produce BOTH Movies and TV Shows
SELECT country,
       SUM(CASE WHEN type = 'Movie'   THEN 1 ELSE 0 END) AS movies,
       SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
HAVING movies > 0 AND tv_shows > 0
ORDER BY (movies + tv_shows) DESC
LIMIT 10;

-- NOTE FOR INTERVIEW:
-- This combines CASE WHEN inside SUM() — a technique called "conditional aggregation".
-- It's a clean way to pivot / summarize data across categories in one query.


-- ============================================================
-- END OF PROJECT
-- ============================================================
