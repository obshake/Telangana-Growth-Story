![Telangana Growth Story](https://raw.githubusercontent.com/obshake/Telangana-Growth-Story/main/tgs.png)
# Analyse Growth Trends in Telangana using Sql

## Overview
This project demonstrates the analysis of Telangana's growth across various sectors using SQL. It covers data extraction, management, and querying to provide insights into the state's economic and social progress. The primary goal is to showcase skills in data analysis, query optimization, and deriving actionable insights from real-time government data.

## Project Title
Telengana Growth Story

## Database
telengana_db

### Database Setup

**Creating Database**
```sql
CREATE DATABASE telangana_db;
```

**Creating Table**
```sql
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    month DATE NOT NULL,
    Mmm VARCHAR(3),
    quarter VARCHAR(2),
    fiscal_year INT
);

DROP TABLE IF EXISTS dim_districts;
CREATE TABLE dim_districts (
	dist_code VARCHAR(5) NOT NULL,
	district VARCHAR(30)
);

DROP TABLE IF EXISTS fact_stamps;
CREATE TABLE fact_stamps (
    dist_code VARCHAR(5) NOT NULL,
    month DATE NOT NULL,
    documents_registered_cnt INT,
    documents_registered_rev BIGINT,
    estamps_challans_cnt INT,
    estamps_challans_rev BIGINT
);

DROP TABLE IF EXISTS fact_transport;
CREATE TABLE fact_transport (
    dist_code VARCHAR(5) NOT NULL,
    month DATE NOT NULL,
    fuel_type_petrol INT,
    fuel_type_diesel INT,
    fuel_type_electric INT,
    fuel_type_others INT,
    vehicleClass_MotorCycle INT,
    vehicleClass_MotorCar INT,
    vehicleClass_AutoRickshaw INT,
    vehicleClass_Agriculture INT,
    vehicleClass_others INT,
    seatCapacity_1_to_3 INT,
    seatCapacity_4_to_6 INT,
    seatCapacity_above_6 INT,
    Brand_new_vehicles INT,
    Pre_owned_vehicles INT,
    category_Non_Transport INT,
    category_Transport INT
);

DROP TABLE IF EXISTS fact_TS_iPASS;
CREATE TABLE fact_TS_iPASS (
    dist_code VARCHAR(5) NOT NULL,
    month DATE NOT NULL,
    sector VARCHAR(100),
    investment_in_cr NUMERIC(10, 2),
    number_of_employees INT
);
```

**Copying data**
```sql
COPY dim_date
FROM 'D:\AssignMents\Sql Projects\Telengana Government\dataset\dim_date.csv'
DELIMITER ','
CSV HEADER;

COPY dim_districts
FROM 'D:\AssignMents\Sql Projects\Telengana Government\dataset\dim_districts.csv'
DELIMITER ','
CSV HEADER;

COPY fact_stamps
FROM 'D:\AssignMents\Sql Projects\Telengana Government\dataset\fact_stamps.csv'
DELIMITER ','
CSV HEADER;

COPY fact_transport
FROM 'D:\AssignMents\Sql Projects\Telengana Government\dataset\fact_transport.csv'
DELIMITER ','
CSV HEADER;

COPY fact_TS_iPASS
FROM 'D:\AssignMents\Sql Projects\Telengana Government\dataset\fact_TS_iPASS.csv'
DELIMITER ','
CSV HEADER;
```
### Stamp Registration

**1. How does the revenue generated from document registration vary across districts in Telangana? List down the top 5 districts that showed the highest revenue growth between FY 2019 and 2022.**
```sql
SELECT 
    district, 
    ROUND(((doc_rev_2022 - doc_rev_2019) / doc_rev_2019) * 100, 2) AS doc_rev_growth
FROM (
    SELECT 
        district,
        SUM(documents_registered_rev) FILTER(WHERE fiscal_year = 2019) AS doc_rev_2019,
        SUM(documents_registered_rev) FILTER(WHERE fiscal_year = 2022) AS doc_rev_2022
    FROM 
        fact_stamps
    LEFT JOIN 
        dim_districts USING (dist_code)
    LEFT JOIN 
        dim_date USING (month)
    GROUP BY 
        district
) AS revenue_growth
ORDER BY 
    doc_rev_growth DESC
LIMIT 5;

```
**2. How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts? List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?**
```sql
SELECT 
    district, 
    SUM(documents_registered_rev) AS doc_rev,
    SUM(estamps_challans_rev) AS estamps_rev
FROM 
    fact_stamps
LEFT JOIN 
    dim_districts USING (dist_code)
LEFT JOIN 
    dim_date USING (month)
WHERE 
    fiscal_year = 2022
GROUP BY 
    district
HAVING 
    SUM(documents_registered_rev) < SUM(estamps_challans_rev)
ORDER BY 
    estamps_rev DESC;
```
**3. Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan? If so, what suggestions would you propose to the government?**
```sql
SELECT 
    month, 
    SUM(documents_registered_cnt) AS doc_cnt, 
    SUM(estamps_challans_cnt) AS estamps_cnt
FROM 
    fact_stamps
GROUP BY 
    month
ORDER BY 
    month;
```
**4. Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.**
```sql
SELECT 
    district, 
    estamps_rev AS estamps_rev_Cr, 
    CASE 
        WHEN estamps_rev > 1000 THEN 'High'
        WHEN estamps_rev > 100 THEN 'Medium'
        ELSE 'Low' 
    END AS Segment
FROM (
    SELECT 
        district, 
        ROUND(SUM(estamps_challans_rev) / 10000000, 2) AS estamps_rev
    FROM 
        fact_stamps
    LEFT JOIN 
        dim_districts USING (dist_code)
    LEFT JOIN 
        dim_date USING (month)
    WHERE 
        fiscal_year = 2021 OR fiscal_year = 2022
    GROUP BY 
        district
) AS estamp_data
ORDER BY 
    estamps_rev DESC;
```
### Transportation
**5. Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. Are there any months or seasons that consistently show higher sale rates, and if yes, what could be the driving factors?**
```sql
SELECT
    EXTRACT(MONTH FROM month) AS month_num,
    TO_CHAR(month, 'mon') AS month_name, 
    SUM(fuel_type_petrol + fuel_type_diesel + fuel_type_electric + fuel_type_others) AS vehicles_sold
FROM 
    fact_transport
GROUP BY 
    month_num, month_name
ORDER BY 
    month_num;
```
**6. How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts? Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.**
```sql
SELECT 
    district,
    SUM(fuel_type_petrol + fuel_type_diesel + fuel_type_electric + fuel_type_others) AS vehicles_sold,
    SUM(vehicleclass_motorcycle) AS motorcycle,
    SUM(vehicleclass_motorcar) AS motorcar,
    SUM(vehicleclass_autorickshaw) AS autorickshaw,
    SUM(vehicleclass_agriculture) AS agriculture,
    SUM(vehicleclass_others) AS others
FROM
    fact_transport
LEFT JOIN 
    dim_districts USING (dist_code)
LEFT JOIN
    dim_date USING (month)
WHERE
    fiscal_year = 2022
GROUP BY
    district
ORDER BY
    vehicles_sold DESC;

```
**7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 2021? (Consider and compare categories: Petrol, Diesel and Electric)**
```sql
CREATE TEMP TABLE growth_data AS (
    SELECT
        district,
        ROUND(((vehicles_sold_2022 - vehicles_sold_2021)::DECIMAL / vehicles_sold_2021) * 100, 2) AS total_growth_rate,
        ROUND(((petrol_2022 - petrol_2021)::DECIMAL / petrol_2021) * 100, 2) AS petrol_growth_rate,
        ROUND(((diesel_2022 - diesel_2021)::DECIMAL / diesel_2021) * 100, 2) AS diesel_growth_rate,
        ROUND(((electric_2022 - electric_2021)::DECIMAL / electric_2021) * 100, 2) AS electric_growth_rate
    FROM (
        SELECT
            district,
            SUM(fuel_type_petrol + fuel_type_diesel + fuel_type_electric) FILTER (WHERE fiscal_year = 2021) AS vehicles_sold_2021,
            SUM(fuel_type_petrol + fuel_type_diesel + fuel_type_electric) FILTER (WHERE fiscal_year = 2022) AS vehicles_sold_2022,
            
            SUM(fuel_type_petrol) FILTER (WHERE fiscal_year = 2021) AS petrol_2021,
            SUM(fuel_type_diesel) FILTER (WHERE fiscal_year = 2021) AS diesel_2021,
            SUM(fuel_type_electric) FILTER (WHERE fiscal_year = 2021) AS electric_2021,
        
            SUM(fuel_type_petrol) FILTER (WHERE fiscal_year = 2022) AS petrol_2022,
            SUM(fuel_type_diesel) FILTER (WHERE fiscal_year = 2022) AS diesel_2022,
            SUM(fuel_type_electric) FILTER (WHERE fiscal_year = 2022) AS electric_2022
        FROM
            fact_transport
        LEFT JOIN 
            dim_districts USING (dist_code)
        LEFT JOIN
            dim_date USING (month)
        GROUP BY
            district
    ) AS data
);

-- Top 3 districts with highest total growth
SELECT 
    district, 
    total_growth_rate
FROM 
    growth_data
ORDER BY 
    total_growth_rate DESC
LIMIT 3;

-- Bottom 3 districts with lowest (or negative) total growth
SELECT 
    district, 
    total_growth_rate
FROM 
    growth_data
ORDER BY 
    total_growth_rate ASC
LIMIT 3;

-- Top 3 districts with highest petrol vehicle growth
SELECT 
    district, 
    petrol_growth_rate
FROM 
    growth_data
ORDER BY 
    petrol_growth_rate DESC
LIMIT 3;

-- Bottom 3 districts with lowest (or negative) petrol vehicle growth
SELECT 
    district, 
    petrol_growth_rate
FROM 
    growth_data
ORDER BY 
    petrol_growth_rate ASC
LIMIT 3;

-- Top 3 districts with highest diesel vehicle growth
SELECT 
    district, 
    diesel_growth_rate
FROM 
    growth_data
ORDER BY 
    diesel_growth_rate DESC
LIMIT 3;

-- Bottom 3 districts with lowest (or negative) diesel vehicle growth
SELECT 
    district, 
    diesel_growth_rate
FROM 
    growth_data
ORDER BY 
    diesel_growth_rate ASC
LIMIT 3;

-- Top 3 districts with highest electric vehicle growth
SELECT 
    district, 
    electric_growth_rate
FROM 
    growth_data
ORDER BY 
    electric_growth_rate DESC
LIMIT 3;

-- Bottom 3 districts with lowest (or negative) electric vehicle growth
SELECT 
    district, 
    electric_growth_rate
FROM 
    growth_data
ORDER BY 
    electric_growth_rate ASC
LIMIT 3;

```
## Ts-Ipass (Telangana State Industrial Project Approval and Self Certification System)

**8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.**
```sql
SELECT 
    sector, 
    SUM(investment_in_cr) AS total_investment
FROM 
    fact_ts_ipass
LEFT JOIN 
    dim_date USING (month)
WHERE 
    fiscal_year = 2022
GROUP BY 
    sector
ORDER BY 
    total_investment DESC
LIMIT 5;
```
**9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022? What factors could have led to the substantial investments in these particular districts?**
```sql
SELECT 
    district, 
    SUM(investment_in_cr) AS total_investment
FROM 
    fact_ts_ipass
LEFT JOIN 
    dim_districts USING (dist_code)
GROUP BY 
    district
ORDER BY 
    total_investment DESC
LIMIT 5;
```
**10. Is there any relationship between sector investments, vehicles sales and stamps revenue in the same district between FY 2021 and 2022.**
```sql
WITH invest_cte AS (
    SELECT 
        dist_code,
        SUM(investment_in_cr) AS investment
    FROM 
        fact_ts_ipass
    LEFT JOIN 
        dim_date USING (month)
    WHERE 
        fiscal_year = 2021 OR fiscal_year = 2022
    GROUP BY 
        dist_code
),

stamps_cte AS (
    SELECT 
        dist_code,
        SUM(documents_registered_rev + estamps_challans_rev) AS stamps_rev
    FROM 
        fact_stamps
    LEFT JOIN 
        dim_date USING (month)
    WHERE 
        fiscal_year = 2021 OR fiscal_year = 2022
    GROUP BY 
        dist_code
),

transport_cte AS (
    SELECT 
        dist_code,
        SUM(fuel_type_petrol + fuel_type_diesel + fuel_type_electric + fuel_type_others) AS vehicles_sold
    FROM 
        fact_transport
    LEFT JOIN 
        dim_date USING (month)
    WHERE 
        fiscal_year = 2021 OR fiscal_year = 2022
    GROUP BY 
        dist_code
)

SELECT 
    district, 
    investment AS investment_in_cr, 
    ROUND((stamps_rev / 10000000) * 100, 2) AS stamps_rev_in_cr, 
    vehicles_sold
FROM 
    invest_cte
JOIN 
    stamps_cte USING (dist_code)
JOIN 
    transport_cte USING (dist_code)
JOIN 
    dim_districts USING (dist_code)
ORDER BY 
    investment_in_cr DESC;
```
**11. Are there any particular sectors that have shown substantial growth in multiple districts in FY 2022?**
```sql
SELECT 
    sector, 
    COUNT(DISTINCT dist_code) AS dist_cnt, 
    SUM(investment_in_cr) AS total_investment
FROM 
    fact_ts_ipass
LEFT JOIN 
    dim_date USING (month)
WHERE 
    fiscal_year = 2022
GROUP BY 
    sector
ORDER BY 
    dist_cnt DESC;
```
**12. Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? Do certain sectors experience higher investments during particular months?**
```sql
SELECT
    sector,
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Jan' THEN investment_in_cr ELSE 0 END) AS "January",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Feb' THEN investment_in_cr ELSE 0 END) AS "February",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Mar' THEN investment_in_cr ELSE 0 END) AS "March",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Apr' THEN investment_in_cr ELSE 0 END) AS "April",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'May' THEN investment_in_cr ELSE 0 END) AS "May",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Jun' THEN investment_in_cr ELSE 0 END) AS "June",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Jul' THEN investment_in_cr ELSE 0 END) AS "July",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Aug' THEN investment_in_cr ELSE 0 END) AS "August",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Sep' THEN investment_in_cr ELSE 0 END) AS "September",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Oct' THEN investment_in_cr ELSE 0 END) AS "October",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Nov' THEN investment_in_cr ELSE 0 END) AS "November",
    SUM(CASE WHEN TO_CHAR(month, 'FMMon') = 'Dec' THEN investment_in_cr ELSE 0 END) AS "December"
FROM
    fact_ts_ipass
GROUP BY
    sector
ORDER BY
    sector;
```
