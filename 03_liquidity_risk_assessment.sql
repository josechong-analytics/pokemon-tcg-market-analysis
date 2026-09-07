SELECT 
    rarity_class,
    COUNT(title) AS total_transactions,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(AVG(days_since_sold), 1) AS avg_days_to_sell
FROM 
    `practicas-sql-501604.tcg_market_intel.fct_secondary_market_pricing`
WHERE 
    days_since_sold IS NOT NULL
    AND rarity_class IS NOT NULL
GROUP BY 
    rarity_class
HAVING 
    total_transactions >= 10 -- Solo consideramos rarezas con un volumen decente de ventas
ORDER BY 
    avg_days_to_sell ASC; -- Ordenamos de las que se venden más rápido a las más lentas