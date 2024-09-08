SELECT * 
FROM fact_stamps;

SELECT *
FROM dim_date;

SELECT *
FROM dim_districts;

SELECT *
FROM fact_transport;

SELECT *
FROM fact_ts_ipass;

/* 
How does the revenue generated from document registration vary
across districts in Telangana? List down the top 5 districts that showed
the highest revenue growth between FY 2019 and 2022. 
*/
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


/*
How does the revenue generated from document registration compare
to the revenue generated from e-stamp challans across districts? List
down the top 5 districts where e-stamps revenue contributes
significantly more to the revenue than the documents in FY 2022?
*/
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
    estamps_rev DESC
LIMIT 5;



/*
Is there any alteration of e-Stamp challan count and document
registration count pattern since the implementation of e-Stamp
challan? If so, what suggestions would you propose to the
government?
*/

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

/*
Categorize districts into three segments based on their stamp
registration revenue generation during the fiscal year 2021 to 2022.
*/

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


-- Transportation

/*
Investigate whether there is any correlation between vehicle sales and
specific months or seasons in different districts. Are there any months
or seasons that consistently show higher sale rates, and if yes, what
could be the driving factors?
*/

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


/*
How does the distribution of vehicles vary by vehicle class
(MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different
districts? Are there any districts with a predominant preference for a
specific vehicle class? Consider FY 2022 for analysis.
*/

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

/*
List down the top 3 and bottom 3 districts that have shown the highest
and lowest vehicle sales growth during FY 2022 compared to FY
2021? (Consider and compare categories: Petrol, Diesel and Electric)
*/
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


/*
List down the top 5 sectors that have witnessed the most significant
investments in FY 2022
*/
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

/*
List down the top 3 districts that have attracted the most significant
sector investments during FY 2019 to 2022? What factors could have
led to the substantial investments in these particular districts?
*/
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
LIMIT 3;

/*
Is there any relationship between sector investments, vehicles
sales and stamps revenue in the same district between FY 2021
and 2022
*/

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

/*
Are there any particular sectors that have shown substantial
growth in multiple districts in FY 2022?
*/
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

/*
Can we identify any seasonal patterns or cyclicality in the
investment trends for specific sectors? Do certain sectors
experience higher investments during particular months?
*/

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

