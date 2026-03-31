-- dim_customer.sql

-- Create the dimension table
WITH customer_cte_2 AS (
	SELECT DISTINCT
	    {{ dbt_utils.generate_surrogate_key(['CustomerID', 'Country']) }} as customer_id,
	    Country AS country
	FROM {{ source('retail_ague', 'raw_invoice') }}
	WHERE CustomerID IS NOT NULL
)
SELECT
    t.*,
	cm.iso
FROM customer_cte_2 t
LEFT JOIN {{ source('retail_ague', 'raw_country') }} cm ON t.country = cm.nicename