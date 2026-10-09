-- Clean and standardize DOB NOW job filing data
-- One row per job filing
WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),
cleaned AS (
    SELECT
        CAST(job_filing_number AS STRING) AS job_filing_number,

        CAST(filing_date AS TIMESTAMP) AS filing_date,
        CAST(filing_status AS STRING) AS current_status,
        SAFE_CAST(current_status_date AS DATE) AS current_status_date,
        SAFE_CAST(first_permit_date AS DATE) AS first_permit_date,
        SAFE_CAST(approved_date AS DATE) AS approved_date,
        SAFE_CAST(signoff_date AS DATE) AS signoff_date,

        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,
        CAST(council_district AS STRING) AS council_district,

        CAST(house_no AS STRING) AS house_no,
        CAST(street_name AS STRING) AS street_name,
        CAST(job_type AS STRING) AS job_type,
        CAST(job_description AS STRING) AS job_description,
        CAST(initial_cost AS NUMERIC) AS initial_cost,
        CAST(total_fee AS NUMERIC) AS total_fee,

        CAST(filing_representative_first_name AS STRING) AS filing_representative_first_name,
        CAST(filing_representative_middle_initial AS STRING) AS filing_representative_middle_initial,
        CAST(filing_representative_last_name AS STRING) AS filing_representative_last_name,
        CAST(filing_representative_business_name AS STRING) AS filing_representative_business_name,
        CAST(filing_representative_street_name AS STRING) AS filing_representative_street_name,
        CAST(filing_representative_city AS STRING) AS filing_representative_city,
        CAST(filing_representative_state AS STRING) AS filing_representative_state,
        CAST(filing_representative_zip AS STRING) AS filing_representative_zip,

        CURRENT_TIMESTAMP() AS _stg_loaded_at
    FROM source
    WHERE job_filing_number IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)
SELECT * FROM cleaned