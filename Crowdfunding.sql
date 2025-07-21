CREATE DATABASE Kickstarter_Crowdfunding_Analysis;
USE Kickstarter_Crowdfunding_Analysis;

CREATE TABLE crowdfunding_projects (project_id BIGINT PRIMARY KEY, state VARCHAR(50), name TEXT, country VARCHAR(10), creator_id BIGINT, location_id BIGINT, 
category_id BIGINT, created_at BIGINT, deadline BIGINT, successful_at BIGINT, launched_at BIGINT, goal DECIMAL(20, 2), pledged DECIMAL(20, 2), currency VARCHAR(10), 
currency_symbol VARCHAR(5), usd_pledged DECIMAL(20, 2), static_usd_rate DECIMAL(10, 5), backers_count INT);
TRUNCATE TABLE crowdfunding_projects;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_projects_utf.8.csv'
IGNORE INTO TABLE crowdfunding_projects
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS (project_id, state, name, country, creator_id, location_id, category_id, created_at, deadline, successful_at, launched_at, goal, pledged, 
currency, currency_symbol, usd_pledged, static_usd_rate, backers_count);

SELECT DEFAULT_CHARACTER_SET_NAME 
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'Kickstarter_Crowdfunding_Analysis';

CREATE TABLE crowdfunding_category (category_id INT PRIMARY KEY, category_name VARCHAR(255), parent_id INT, position INT);
SHOW VARIABLES LIKE 'secure_file_priv';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/crowdfunding_category.csv'
INTO TABLE crowdfunding_category
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS (category_id, category_name, parent_id, position);

CREATE TABLE crowdfunding_creator (creator_id BIGINT PRIMARY KEY, creator_name VARCHAR(255));
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_Creator_utf8.csv'
INTO TABLE crowdfunding_creator
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS (creator_id, creator_name);
SHOW FULL COLUMNS FROM crowdfunding_creator;
ALTER TABLE crowdfunding_creator
MODIFY creator_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE crowdfunding_location (location_id BIGINT PRIMARY KEY, displayable_name VARCHAR(255), type VARCHAR(100), name VARCHAR(255), state VARCHAR(100), country VARCHAR(100));
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/crowdfunding_location.csv'
INTO TABLE crowdfunding_location
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'   -- try '\n' if '\r\n' fails
IGNORE 1 ROWS (location_id, displayable_name, type, name, state, country);
# For displayable_name, name in crowdfunding_location
ALTER TABLE crowdfunding_location
MODIFY displayable_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
MODIFY name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

Select *from crowdfunding_category;
Select *from crowdfunding_location;
Select *from crowdfunding_creator;
Select *from crowdfunding_projects;

# Add converted date columns for readability 
ALTER TABLE crowdfunding_projects
ADD COLUMN created_date DATE,
ADD COLUMN deadline_date DATE,
ADD COLUMN successful_date DATE,
ADD COLUMN launched_date DATE;
SET SQL_SAFE_UPDATES = 0;
# Adds and updates readable date columns from epoch timestamps
ALTER TABLE crowdfunding_projects
MODIFY created_date DATETIME,
MODIFY deadline_date DATETIME,
MODIFY successful_date DATETIME,
MODIFY launched_date DATETIME;
SHOW COLUMNS FROM crowdfunding_projects LIKE '%date';
UPDATE crowdfunding_projects
SET
  created_date = FROM_UNIXTIME(created_at),
  deadline_date = FROM_UNIXTIME(deadline),
  successful_date = CASE 
      WHEN successful_at > 0 THEN FROM_UNIXTIME(successful_at)
      ELSE NULL
  END,
  launched_date = FROM_UNIXTIME(launched_at)
WHERE project_id > 0;
Select *from crowdfunding_projects;

CREATE TABLE calendar_table AS SELECT DISTINCT created_date AS date, 
YEAR(created_date) AS year, 
MONTH(created_date) AS month_no, 
MONTHNAME(created_date) AS month_name,
CONCAT(YEAR(created_date), '-', LEFT(MONTHNAME(created_date), 3)) AS `year_month`, 
QUARTER(created_date) AS quarter, 
WEEKDAY(created_date) + 1 AS weekday_no,
DAYNAME(created_date) AS weekday_name,
CASE 
    WHEN MONTH(created_date) = 4 THEN 'FM1'
    WHEN MONTH(created_date) = 5 THEN 'FM2'
    WHEN MONTH(created_date) = 6 THEN 'FM3'
    WHEN MONTH(created_date) = 7 THEN 'FM4'
    WHEN MONTH(created_date) = 8 THEN 'FM5'
    WHEN MONTH(created_date) = 9 THEN 'FM6'
    WHEN MONTH(created_date) = 10 THEN 'FM7'
    WHEN MONTH(created_date) = 11 THEN 'FM8'
    WHEN MONTH(created_date) = 12 THEN 'FM9'
    WHEN MONTH(created_date) = 1 THEN 'FM10'
    WHEN MONTH(created_date) = 2 THEN 'FM11'
    WHEN MONTH(created_date) = 3 THEN 'FM12'
  END AS financial_month,
  CASE 
    WHEN MONTH(created_date) BETWEEN 4 AND 6 THEN 'FQ1'
    WHEN MONTH(created_date) BETWEEN 7 AND 9 THEN 'FQ2'
    WHEN MONTH(created_date) BETWEEN 10 AND 12 THEN 'FQ3'
    ELSE 'FQ4'
  END AS financial_quarter
FROM crowdfunding_projects
WHERE created_date IS NOT NULL;
Select *from calendar_table;

#Adds a column for goal converted to USD
ALTER TABLE crowdfunding_projects ADD COLUMN goal_usd DECIMAL(20, 2);
UPDATE crowdfunding_projects SET goal_usd = goal * static_usd_rate;

#Projects by Outcome
SELECT state,
  CASE 
    WHEN COUNT(*) >= 1000000 THEN CONCAT(ROUND(COUNT(*) / 1000000, 1), 'M')
    WHEN COUNT(*) >= 1000 THEN CONCAT(ROUND(COUNT(*) / 1000, 1), 'K')
    ELSE COUNT(*)
  END AS total_projects
FROM crowdfunding_projects
GROUP BY state
ORDER BY COUNT(*) DESC;

# Projects by Location
SELECT l.country,
  CASE 
    WHEN COUNT(*) >= 1000000 THEN CONCAT(ROUND(COUNT(*) / 1000000, 1), 'M')
    WHEN COUNT(*) >= 1000 THEN CONCAT(ROUND(COUNT(*) / 1000, 1), 'K')
    ELSE COUNT(*)
  END AS total_projects
FROM crowdfunding_projects p
JOIN crowdfunding_location l ON p.location_id = l.location_id
GROUP BY l.country
ORDER BY COUNT(*) DESC;

# Projects by Category
SELECT c.category_name,
  CASE 
    WHEN COUNT(*) >= 1000000 THEN CONCAT(ROUND(COUNT(*) / 1000000, 1), 'M')
    WHEN COUNT(*) >= 1000 THEN CONCAT(ROUND(COUNT(*) / 1000, 1), 'K')
    ELSE COUNT(*)
  END AS total_projects
FROM crowdfunding_projects p
JOIN crowdfunding_category c ON p.category_id = c.category_id
GROUP BY c.category_name;

# Projects by Year/Quarter/Month
SELECT YEAR(created_date) AS year, QUARTER(created_date) AS quarter, MONTHNAME(created_date) AS month,
CASE 
    WHEN COUNT(*) >= 1000000 THEN CONCAT(ROUND(COUNT(*) / 1000000, 1), 'M')
    WHEN COUNT(*) >= 1000 THEN CONCAT(ROUND(COUNT(*) / 1000, 1), 'K')
    ELSE COUNT(*)
  END AS total_projects
FROM crowdfunding_projects
GROUP BY year, quarter, month
ORDER BY year, quarter;

#KPI: Successful Projects Analysis
# Amount Raised & Backers
SELECT 
  CONCAT('$', ROUND(SUM(usd_pledged) / 1000000000, 2), ' bn') AS total_amount_raised,
  CONCAT(ROUND(SUM(backers_count) / 1000000, 2), ' M') AS total_backers
FROM crowdfunding_projects
WHERE state = 'successful';

# Avg Number of Days to Success
SELECT 
  ROUND(AVG(DATEDIFF(successful_date, launched_date)), 2) AS avg_days_to_success
FROM crowdfunding_projects
WHERE state = 'successful' 
  AND successful_date IS NOT NULL 
  AND launched_date IS NOT NULL;

# Top Successful Projects by Number of Backers
SELECT name,
CASE
    WHEN usd_pledged >= 1000000 THEN CONCAT(ROUND(usd_pledged / 1000000, 2), 'M')
    WHEN usd_pledged >= 1000 THEN CONCAT(ROUND(usd_pledged / 1000, 2), 'K')
    ELSE ROUND(usd_pledged, 2)
  END AS usd_pledged_display,
  CASE
    WHEN backers_count >= 1000000 THEN CONCAT(ROUND(backers_count / 1000000, 2), 'M')
    WHEN backers_count >= 1000 THEN CONCAT(ROUND(backers_count / 1000, 2), 'K')
    ELSE backers_count
  END AS backers_count_display
FROM crowdfunding_projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;

# Top Successful Projects by Amount Raised
SELECT name,
CASE
    WHEN usd_pledged >= 1000000 THEN CONCAT('$', ROUND(usd_pledged / 1000000, 2), 'M')
    WHEN usd_pledged >= 1000 THEN CONCAT('$', ROUND(usd_pledged / 1000, 2), 'K')
    ELSE ROUND(usd_pledged, 2)
  END AS usd_pledged_display,
  CASE
    WHEN backers_count >= 1000000 THEN CONCAT(ROUND(backers_count / 1000000, 2), 'M')
    WHEN backers_count >= 1000 THEN CONCAT(ROUND(backers_count / 1000, 2), 'K')
    ELSE backers_count
  END AS backers_count_display
FROM crowdfunding_projects
WHERE state = 'successful'
ORDER BY usd_pledged DESC
LIMIT 10;

# Overall Percentage of Successful Projects
SELECT CONCAT(FORMAT(
      (SELECT COUNT(*) FROM crowdfunding_projects WHERE state = 'successful') * 100.0 /
      (SELECT COUNT(*) FROM crowdfunding_projects), 2), '%') AS success_percentage;

  
# Percentage of Successful Projects by Category
SELECT c.category_name,
  CONCAT(ROUND(COUNT(CASE WHEN p.state = 'successful' THEN 1 END) * 100.0 / COUNT(*), 2), '%') AS success_rate
FROM crowdfunding_projects p
JOIN crowdfunding_category c ON p.category_id = c.category_id
GROUP BY c.category_name;

# Percentage of Successful Projects by Year
SELECT 
  YEAR(created_date) AS year,
  CONCAT(ROUND(COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(*),2), '%') AS success_rate
FROM crowdfunding_projects
GROUP BY year;

# Percentage of Successful Projects by Goal Range
SELECT 
  CASE 
    WHEN goal_usd < 1000 THEN '< $1K'
    WHEN goal_usd BETWEEN 1000 AND 10000 THEN '$1K–$10K'
    WHEN goal_usd BETWEEN 10000 AND 50000 THEN '$10K–$50K'
    ELSE '> $50K'
  END AS goal_range,
  CONCAT(ROUND(COUNT(CASE WHEN state = 'successful' THEN 1 END) * 100.0 / COUNT(*),2), '%') AS success_rate
FROM crowdfunding_projects
GROUP BY goal_range;

#Project Duration Analysis
SELECT ROUND(AVG(DATEDIFF(deadline_date, launched_date)), 2) AS avg_project_duration_days FROM crowdfunding_projects;

# Failure Rate by Country or Category
SELECT 
  l.country,
  COUNT(*) AS total_projects,
  COUNT(CASE WHEN p.state = 'failed' THEN 1 END) AS failed_projects,
  CONCAT(ROUND(COUNT(CASE WHEN p.state = 'failed' THEN 1 END) * 100.0 / COUNT(*), 2), '%') AS failure_rate
FROM crowdfunding_projects p
JOIN crowdfunding_location l ON p.location_id = l.location_id
GROUP BY l.country
ORDER BY failure_rate DESC;

#Currency-wise Campaigns
SELECT currency, 
CASE 
    WHEN COUNT(*) >= 1000000 THEN CONCAT(ROUND(COUNT(*) / 1000000, 1), 'M')
    WHEN COUNT(*) >= 1000 THEN CONCAT(ROUND(COUNT(*) / 1000, 1), 'K')
    ELSE COUNT(*)
  END AS total_projects
FROM crowdfunding_projects
GROUP BY currency;

#Projects with Zero Backers or Funding
SELECT COUNT(*) AS zero_backers_projects
FROM crowdfunding_projects
WHERE backers_count = 0 OR usd_pledged = 0;



















