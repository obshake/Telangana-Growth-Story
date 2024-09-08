CREATE TABLE dim_date (
    month DATE NOT NULL,
    Mmm VARCHAR(3),
    quarter VARCHAR(2),
    fiscal_year INT
);

CREATE TABLE dim_districts (
	dist_code VARCHAR(5) NOT NULL,
	district VARCHAR(30)
);


CREATE TABLE fact_stamps (
    dist_code VARCHAR(5) NOT NULL,
    month DATE NOT NULL,
    documents_registered_cnt INT,
    documents_registered_rev BIGINT,
    estamps_challans_cnt INT,
    estamps_challans_rev BIGINT
);

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



