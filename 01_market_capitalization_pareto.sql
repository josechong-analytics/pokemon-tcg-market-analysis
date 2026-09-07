SELECT 
    set_name,
    COUNT(title) AS total_cards_sold,
    ROUND(AVG(price_usd), 2) AS average_price_usd,
    ROUND(SUM(price_usd), 2) AS total_market_value
FROM 
    `practicas-sql-501604.tcg_market_intel.fct_secondary_market_pricing`
WHERE 
    set_name IS NOT NULL
    AND price_usd > 0  -- Evitamos cartas gratuitas o errores de datos
GROUP BY 
    set_name
ORDER BY 
    total_market_value DESC
LIMIT 10;