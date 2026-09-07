# Pokemon TCG: Market Valuation & Liquidity Analysis
**Data Analytics Capstone Project**

## Project Overview
The secondary market for the Pokemon Trading Card Game (TCG) has grown into a highly active alternative asset class. However, navigating it requires moving past nostalgia and looking at actual transaction data to understand where the real financial value lies. 

This project follows the **Ask, Prepare, Process, Analyze, Share, Act** framework to analyze historical e-commerce transactions. The goal was to identify market liquidity patterns, compare value retention between vintage and modern sets, and quantify the actual return on investment (ROI) of third-party condition grading.

---

## 1. Phase 1: Ask

**The Business Problem:** 
A boutique investment firm wants to integrate TCG collectibles into their portfolio but needs a data-driven strategy to minimize inventory risk (unsold assets) and maximize short-term returns.

**Key Questions to Answer:**
1. What is the average market liquidity (days to sell), and do more expensive cards take longer to sell?
2. Which expansions hold the highest concentration of portfolio value?
3. What is the true financial impact of submitting raw cards to grading services (e.g., PSA, CGC), and which rarity classes see the biggest benefit?

---

## 2. Phase 2: Prepare

**Data Sourcing:**
I utilized the "E-commerce Pokemon Card Pricing Data" dataset from Kaggle (authored by Kanchana1990). This dataset is highly valuable because it logs actual completed sales from international sellers, rather than speculative asking prices.

**Data Profile:**
- **Size:** 542 rows and 32 columns.
- **Scope:** Covers singles from the original Base Set through the modern Scarlet & Violet era.
- **Integrity (ROCCC):** The data is Reliable (real completed sales), Original (e-commerce API aggregation), Comprehensive (includes rarity, condition, and pricing metadata), Current, and properly Cited. All prices were normalized to USD.

---

## 3. Phase 3: Process

To prepare the dataset for visualization, I engineered a data cleaning and transformation pipeline using **Python (Pandas)** and **SQL**.

### Python Data Cleaning
The initial cleaning phase focused on standardizing categorical variables, managing duplicates, and casting financial datatypes. Key steps included enforcing primary key constraints, parsing monetary columns from string artifacts to float arrays, and standardizing temporal data.

```python
# Snippet: Data Wrangling & Integrity Checks (Pandas)

import pandas as pd
import numpy as np

def clean_pokemon_data(input_csv):
    # 1. Load data
    df = pd.read_csv(input_csv)

    # 2. Enforce Primary Key integrity (Remove exact duplicates)
    df = df.drop_duplicates(subset=['card_id'], keep='first')

    # 3. String normalization (strip whitespace)
    df['card_name'] = df['card_name'].astype(str).str.strip()
    df['set_name'] = df['set_name'].astype(str).str.strip()
    df['rarity'] = df['rarity'].astype(str).str.strip()

    # 4. Financial column cleanup (Strip currency symbols and cast to Float)
    df['price_usd'] = df['price_usd'].astype(str).str.replace('$', '', regex=False)
    df['price_usd'] = pd.to_numeric(df['price_usd'], errors='coerce')

    # 5. Temporal data casting (Ensure YYYY-MM-DD format while preserving valid NULLs)
    df['release_date'] = pd.to_datetime(df['release_date'], errors='coerce').dt.strftime('%Y-%m-%d')

    # 6. Null imputation for inventory tracking
    df['stock'] = df['stock'].fillna(0).astype(int)
    
    return df
``` (The complete Data Wrangling notebook is available in the .ipynb file included in this repository).

### SQL: Exploratory Data Analysis (EDA) & Validation
Before building the BI dashboard, I loaded the cleaned dataset into Google BigQuery to perform exploratory data analysis and validate business logic.

Instead of pre-aggregating the data for Tableau (which would destroy the row-level granularity needed for interactive cross-filtering), I used SQL exclusively to verify data integrity, test assumptions, and establish baseline metrics.

```SQL
-- Snippet: Validating Market Capitalization and Volume by Set (BigQuery)

SELECT 
    set_name,
    COUNT(title) AS total_cards_sold,
    ROUND(AVG(price_usd), 2) AS average_price_usd,
    ROUND(SUM(price_usd), 2) AS total_market_value
FROM
    `practicas-sql-501604.tcg_market_intel.fct_secondary_market_pricing`
WHERE
    set_name IS NOT NULL
    AND price_usd > 0 -- Filtering out anomalies and zero-dollar listings
GROUP BY
    set_name
ORDER BY
    total_market_value DESC
LIMIT 10;
```  <--- ESTAS TRES COMILLAS INVERTIDAS SON LAS QUE DEBES AGREGAR AQUÍ

## ## 4. Phase 4: Analyze

During the exploratory data analysis (EDA), several clear patterns emerged...
```

Market Liquidity: The market moves extremely fast. The overall average time a card spends listed before selling is just 3.7 Days.

Value Concentration: Nostalgia dictates total market cap. The vintage Base Set accounts for a dominant $2,934.61 of the sample's value, proving that historical scarcity outperforms modern volume.

The Grading Arbitrage: Comparing Raw vs. Graded prices revealed a massive margin opportunity in modern cards. Grading a card does not just add a flat premium; for certain rarities, it acts as an aggressive multiplier.

5. Phase 5: Share
To present these findings, I designed an interactive business intelligence dashboard in Tableau Public.

UI/UX Design Approach:
I implemented a strict "Dark Mode" aesthetic using a deep midnight blue (#06061E) background paired with a high-contrast Orange and dark Red/Brown palette. To keep the interface clean, maximize the data-ink ratio, and focus the user's attention directly on the data points, I systematically removed all unnecessary gridlines and axis rulers.

Visual Breakdown:

Top 10 Sets (Bar Chart): Clearly highlights the heavy financial weighting of the Base Set compared to the rest of the market.

Liquidity Risk (Column Chart): Shows that rarity does not slow down sales. The highly sought-after SAR (Special Illustration Rare) cards are actually the fastest movers, selling in just 2.8 days.

Valuation Drivers (Heatmap): This is the core insight tool. Using a custom color gradient, it illustrates the condition arbitrage opportunity. A raw SAR card averages $184.88, but jumps to a dark-red intensity of $1,454.15 once graded.

Price vs. Liquidity (Scatter Plot): Plots sale price against days on market. It shows that high-ticket cards (>$1,000) sell in roughly 4 days, effectively the exact same timeframe as $200 cards.

6. Phase 6: Act
Strategic Recommendations
Based on the data, here is the recommended approach for an alternative-asset portfolio:

Prioritize Condition Arbitrage: The most efficient short-term ROI comes from the modern market. The firm should acquire highly liquid, raw SAR cards and submit them for grading to capture the significant price multiplier.

Acquire High-Ticket Items with Confidence: The scatter plot proves that expensive assets do not inherently tie up capital. The firm can safely invest in $1,000+ graded assets knowing they clear the market in less than a week.

Hold Vintage for Stability: While modern graded cards are great for active flipping, vintage Base Set cards should be used as the portfolio's anchor to preserve wealth long-term against market volatility.

Future Scope:
For future iterations, I plan to incorporate a Python time-series forecasting model (utilizing libraries such as Prophet or ARIMA) to analyze how the announcement and release dates of new expansions affect the pricing of older sets.
