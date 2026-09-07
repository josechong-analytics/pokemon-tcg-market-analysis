SELECT 
    rarity_class,
    is_graded,
    COUNT(title) AS volume_sold,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(MAX(price_usd), 2) AS max_price_recorded
FROM 
    `practicas-sql-501604.tcg_market_intel.fct_secondary_market_pricing`
WHERE 
    rarity_class IS NOT NULL
    AND price_usd > 0
GROUP BY 
    rarity_class, 
    is_graded
HAVING 
    volume_sold >= 5 -- Filtramos rarezas con muy pocas ventas para no sesgar el promedio
ORDER BY 
    avg_price DESC;