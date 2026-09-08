# Pokémon TCG: Market Valuation & Liquidity Analysis
### *Data Analytics Capstone Project*

## Project Overview
The secondary market for the Pokémon Trading Card Game (TCG) has grown into a highly active alternative asset class. However, navigating it requires moving past nostalgia and looking at actual transaction data to understand where the real financial value lies.

This project follows the **Ask, Prepare, Process, Analyze, Share, Act** framework to analyze historical e-commerce transactions. The goal was to identify market liquidity patterns, compare value retention between vintage and modern sets, and quantify the actual return on investment (ROI) of third-party condition grading.

---

## 1. Phase 1: Ask

### The Business Problem
A boutique investment firm wants to integrate TCG collectibles into their portfolio but needs a data-driven strategy to minimize inventory risk (unsold assets) and maximize short-term returns.

### Key Questions to Answer
1. What is the average market liquidity (days to sell), and do more expensive cards take longer to sell?
2. Which expansions hold the highest concentration of portfolio value?
3. What is the true financial impact of submitting raw cards to grading services (e.g., PSA, CGC), and which rarity classes see the biggest benefit?

---

## 2. Phase 2: Prepare

### Data Sourcing
I utilized the **"E-commerce Pokemon Card Pricing Data"** dataset from Kaggle (authored by Kanchana1990). This dataset is highly valuable because it logs actual completed sales from international sellers, rather than speculative asking prices.

### Data Profile
* **Size:** 537 rows and 34 columns (spanning from Column A to AH).
* **Scope:** Covers singles from the original Base Set through the modern Scarlet & Violet era.
* **Integrity (ROCCC):** The data is Reliable (real completed sales), Original (e-commerce API aggregation), Comprehensive (includes pricing and condition metadata), Current, and properly Cited. All prices were normalized to USD.
* **Data Quality Note:** An initial structural audit revealed a significant volume of missing classification metadata within the `rarity_class` column, preserved as **"Unknown"**. To maintain financial sample size and avoid distorting aggregate market value or sales velocity calculations, these rows were preserved during processing rather than dropped.

---

## 3. Phase 3: Process

To prepare the dataset for enterprise-grade data warehousing and BI visualization, I developed a dual-stage data processing strategy using Python (Pandas & Regex).

### Stage 1: Exploratory Data Cleaning & Deduplication
In the initial processing stage (documented in `data_cleaning_process.ipynb`), I focused on auditing data quality and establishing structural integrity.
* **Deduplication:** Instead of relying on missing or inconsistent arbitrary IDs, I enforced a compound constraint using `subset=['title', 'card_number']` to effectively eliminate identical listing duplicates and ensure row-level uniqueness.
* **String Normalization:** Whitespace and structural text anomalies were stripped across core fields.
* **Type Casting:** Financial values were cleaned of string symbols and converted to float arrays, and temporal data was standardized to standard date formats.

### Stage 2: Automated ETL Pipeline (BigQuery Compatibility)
To scale the ingestion process, I engineered an automated, dynamic pipeline (documented in `etl_pipeline.ipynb`) utilizing `kagglehub` to directly orchestrate data retrieval via the Kaggle API.

```python
# Snippet: Dynamic Schema Standardization & Parsing (etl_pipeline.ipynb)
import pandas as pd
import numpy as np

def clean_pokemon_market_data(input_filepath, output_filepath):
    df = pd.read_csv(input_filepath)

    # Schema standardization for Data Warehouse compliance
    df.columns = (df.columns
                  .str.strip()
                  .str.lower()
                  .str.replace(' ', '_', regex=False)
                  .str.replace('[^a-z0-9_]', '', regex=True))

    # Dynamic pricing column detection and float parsing
    price_cols = [col for col in df.columns if 'price' in col or 'usd' in col or 'cost' in col]
    for col in price_cols:
        if df[col].dtype == 'object':
            df[col] = df[col].str.replace('\$', '', regex=False).str.replace(',', '', regex=False)
            df[col] = pd.to_numeric(df[col], errors='coerce')

    df.to_csv(output_filepath, index=False)
```

*(Both notebooks are fully documented and available in the main directory of this repository: use `data_cleaning_process.ipynb` for the business logic validation and `etl_pipeline.ipynb` for the automated API ingestion workflow).*

### SQL: Exploratory Data Analysis (EDA) & Validation
Before building the BI dashboard, I loaded the cleaned dataset into **Google BigQuery** to perform exploratory data analysis and validate business logic.

Instead of pre-aggregating the data for Tableau (which would destroy the row-level granularity needed for interactive cross-filtering), I used SQL exclusively to verify data integrity, test assumptions, and establish baseline metrics.

```sql
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
```

*(The full suite of EDA queries is available in the individual SQL files included in this repository: `01_market_capitaliz.sql`, `02_valuation_drivers.sql`, etc.).*

---

## 4. Phase 4: Analyze

During the exploratory data analysis (EDA), several clear patterns emerged regarding how buyers interact with different card types:

* **Market Liquidity:** The market moves extremely fast. The overall average time a card spends listed before selling is just **3.7 Days**.
* **Value Concentration:** Nostalgia dictates total market cap. The vintage **Base Set** accounts for a dominant **$2,934.61** of the sample's value, proving that historical scarcity outperforms modern volume.
* **The Grading Arbitrage:** Comparing Raw vs. Graded prices revealed a massive margin opportunity in modern cards. Grading a card does not just add a flat premium; for certain rarities, it acts as an aggressive multiplier.
* **Metadata Limitation Segment:** The high frequency of **"Unknown"** labels within the rarity column represents lower-tier bulk items. Exploratory analysis confirms that these records do not distort premium asset behavior, shifting the high-yield analytical scope strictly toward verified tiers.

---

## 5. Phase 5: Share

To present these findings, I designed an interactive business intelligence dashboard in **Tableau Public**.

[![View Interactive Dashboard](https://shields.io)](https://public.tableau.com/app/profile/jos.antonio.chong.contreras/viz/Pokemon_TCG_Market_Analysis/Dashboard1)

***[Click here to view the live interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/jos.antonio.chong.contreras/viz/Pokemon_TCG_Market_Analysis/Dashboard1)***

### UI/UX Design Approach
I implemented a strict "Dark Mode" aesthetic using a deep midnight blue (`#06061E`) background paired with a high-contrast Orange and dark Red/Brown palette. To keep the interface clean, maximize the data-ink ratio, and focus the user's attention directly on the data points, I systematically removed all unnecessary gridlines and axis rulers.

### Visual Breakdown
* **Top 10 Sets (Bar Chart):** Clearly highlights the heavy financial weighting of the Base Set compared to the rest of the market.
* **Liquidity Risk (Column Chart):** Shows that rarity does not slow down sales. The highly sought-after **SAR (Special Illustration Rare)** cards are actually the fastest movers, selling in just **2.857 days**. Unclassified **"Unknown"** card segments cluster tightly around the baseline market average of 3.4 days.
* **Valuation Drivers (Heatmap):** This is the core insight tool. Using a custom color gradient, it illustrates the condition arbitrage opportunity. A raw SAR card averages **$184.88**, but jumps to a dark-red intensity of **$1,454.15** once graded.
* **Price vs. Liquidity (Scatter Plot):** Plots sale price against days on market. It shows that high-ticket cards (>$1,000) sell in roughly **4 days**, effectively the exact same timeframe as $200 cards.

### Dashboard Preview
![Tableau Dashboard](Dashboard%201.png)

---

## 6. Phase 6: Act

### Strategic Recommendations
The core value of this data analysis is transforming raw metrics into high-yield, risk-mitigated investment strategies. Based on the insights extracted from the Tableau dashboard, I recommend the following execution framework for the alternative-asset portfolio:

1. **Capitalize on Modern Grading Arbitrage (High ROI/High Velocity)**
   * **The Insight:** The Valuation Drivers heatmap reveals that raw Special Illustration Rare (SAR) cards hold a modest market baseline of ~$184.88. However, upon receiving third-party professional grading, their realized value surges exponentially to an average of **$1,454.15**. Furthermore, the Liquidity Risk chart confirms that SAR cards are the absolute fastest-moving assets in the entire market, clearing inventory constraints in just **2.857 days**.
   * **The Action:** The firm must establish an active acquisition pipeline focusing on high-grade, raw modern SAR cards to execute third-party grading submissions, capturing massive arbitrage margins with zero structural liquidity risk.
   * 
   * 2. **Deploy Capital into High-Ticket Assets with Velocity Confidence**
   * **The Insight:** Traditional asset management assumes that luxury or high-ticket items suffer from severe liquidity traps (longer days on market). However, the Price vs. Liquidity scatter plot invalidates this assumption for the Pokémon TCG space. High-valuation assets valued above $1,000 exhibit a market clearance velocity of approximately **4 days**—effectively mirroring the liquidation timeline of low-tier $200 items.
   * **The Action:** Capital can be deployed into premier, high-value assets (>$1,000) without fear of locking up firm capital in illiquid inventory, enabling the acquisition of blue-chip collectibles that maintain rapid liquidation speeds.

3. **Establish a Risk-Mitigation Anchor in Vintage Scarcity**
   * **The Insight:** While modern sets offer aggressive velocity, the Top 10 Sets volume distribution proves that market capitalization is overwhelmingly dictated by historical nostalgia. The vintage **Base Set** completely dominates total asset value within the sample at **$2,934.61**, heavily outperforming the aggregate value of modern modern expansions like Scarlet & Violet (SV2A) despite their higher transaction volume.
   * **The Action:** To hedge against the natural volatility and potential print-run inflation of modern sets, the firm should utilize 40% of the portfolio capital to acquire and hold vintage Base Set, Jungle, and Fossil assets as a long-term wealth preservation anchor.
     
### Future Scope & Data Limitations

1. **Dataset Scope and Temporal Limitations:** During the data audit phase, it was identified that the dataset's temporal range is highly concentrated (primarily logging transactions from May 2026). Due to this narrow date range and small sample size, the data is structurally unsuited for traditional macro-level time-series forecasting (such as ARIMA) or deep learning modeling. 
2. **Metadata Enrichment Pipeline:** To expand the analytical scope and resolve the high volume of "Unknown" records within the `rarity_class` column, the next iteration of this project will focus on data enrichment. I plan to build a Python script to interface directly with an external official TCG API. This will programmatically backfill missing classification metrics and expand the transaction history baseline beyond the current seasonal constraint, enabling future price prediction modeling.


