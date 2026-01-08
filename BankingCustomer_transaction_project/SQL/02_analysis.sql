-- ============================================================
-- 02_analysis.sql
-- Project : Banking Market Insights
-- Purpose :
--   - Explore customer behaviours, transaction patterns,
--     investment trends, and branch performance.
--   - Prepare datasets for dashboards (Tableau) and modelling (Python).
--
-- Sources :
--   - view_customer_bank
--   - view_customer_transactions
--   - view_full_analytics
-- ============================================================

USE banking_analytics;

-- ============================================================
-- 1) CUSTOMER ANALYSIS
-- ============================================================

-- 1.1 Customers by type
SELECT
    Customer_Type,
    COUNT(*) AS num_customers
FROM customers
GROUP BY Customer_Type
ORDER BY num_customers DESC;

-- 1.2 Age distribution by type
SELECT
    Customer_Type,
    COUNT(*) AS num_customers,
    AVG(Age) AS avg_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age
FROM customers
GROUP BY Customer_Type
ORDER BY avg_age;

-- 1.3 Customers by region (useful for Tableau maps)
SELECT
    Region,
    COUNT(*) AS num_customers
FROM customers
GROUP BY Region
ORDER BY num_customers DESC;

-- 1.4 Average investment by customer type (cleaned transactions)
SELECT
    Customer_Type,
    AVG(Investment_Amount) AS avg_investment
FROM view_full_analytics
WHERE Investment_Amount > 0
GROUP BY Customer_Type
ORDER BY avg_investment DESC;

-- ============================================================
-- 2) TRANSACTION BEHAVIOUR
-- ============================================================

-- 2.1 Monthly transaction volume
SELECT
    txn_year,
    txn_month,
    COUNT(*) AS num_transactions
FROM view_full_analytics
GROUP BY txn_year, txn_month
ORDER BY txn_year, txn_month;

-- 2.2 Average transaction amount by account type
SELECT
    Account_Type,
    AVG(Transaction_Amount) AS avg_transaction_amount,
    COUNT(*)                AS num_transactions
FROM transactions_clean
GROUP BY Account_Type
ORDER BY avg_transaction_amount DESC;

-- 2.3 Transaction amount distribution (summary stats)
SELECT
    MIN(Transaction_Amount)    AS min_tx,
    MAX(Transaction_Amount)    AS max_tx,
    AVG(Transaction_Amount)    AS avg_tx,
    STDDEV(Transaction_Amount) AS std_tx
FROM transactions_clean;

-- 2.4 Ratio of transactions that include an investment
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN Investment_Amount > 0 THEN 1 ELSE 0 END) AS num_investments,
    SUM(CASE WHEN Investment_Amount > 0 THEN 1 ELSE 0 END) / COUNT(*) AS investment_ratio
FROM transactions_clean;

-- ============================================================
-- 3) INVESTMENT ANALYSIS (MARKET BEHAVIOUR)
-- ============================================================

-- 3.1 Total investment amount per month
SELECT
    YEAR(Transaction_Date)  AS year,
    MONTH(Transaction_Date) AS month,
    SUM(Investment_Amount)  AS total_invested
FROM transactions_clean
GROUP BY year, month
ORDER BY year, month;

-- 3.2 Investment type popularity
SELECT
    Investment_Type,
    COUNT(*)            AS num_operations,
    SUM(Investment_Amount) AS total_amount
FROM transactions_clean
WHERE Investment_Amount > 0
GROUP BY Investment_Type
ORDER BY total_amount DESC;

-- 3.3 Average & total investment by customer type
SELECT
    Customer_Type,
    AVG(Investment_Amount) AS avg_invest,
    SUM(Investment_Amount) AS total_invest
FROM view_full_analytics
WHERE Investment_Amount > 0
GROUP BY Customer_Type
ORDER BY avg_invest DESC;

-- 3.4 Investment intensity (Investment_Amount / Total_Balance)
SELECT
    Customer_Type,
    AVG(Investment_Amount / Total_Balance) AS avg_intensity
FROM view_full_analytics
WHERE Investment_Amount > 0
GROUP BY Customer_Type
ORDER BY avg_intensity DESC;

-- ============================================================
-- 4) BRANCH PERFORMANCE
-- ============================================================

-- 4.1 Branch profitability ranking
SELECT
    Branch_ID,
    AVG(true_profit_margin) AS avg_profit_margin
FROM bank_clean
GROUP BY Branch_ID
ORDER BY avg_profit_margin DESC;

-- 4.2 Total investment per branch
SELECT
    f.Branch_ID,
    SUM(f.Investment_Amount) AS total_invested
FROM view_full_analytics f
GROUP BY f.Branch_ID
ORDER BY total_invested DESC;

-- 4.3 Investment per customer per branch
SELECT
    Branch_ID,
    SUM(Investment_Amount) / COUNT(DISTINCT Customer_ID) AS avg_invest_per_customer
FROM view_full_analytics
GROUP BY Branch_ID
ORDER BY Branch_ID ASC;

-- 4.4 Relationship: branch revenue vs total investments
SELECT
    Branch_ID,
    Firm_Revenue,
    SUM(Investment_Amount) AS total_investments
FROM view_full_analytics
GROUP BY Branch_ID, Firm_Revenue
ORDER BY Firm_Revenue DESC;

-- ============================================================
-- 5) DATA PREP FOR PYTHON MODELLING (VIEWS)
-- ============================================================

-- 5.1 Customer-level features (1 row per customer)
CREATE OR REPLACE VIEW python_customer_features AS
SELECT
    Customer_ID,
    Age,
    Customer_Type,
    customer_region,
    Branch_ID,
    branch_region,

    COUNT(*) AS num_transactions,
    AVG(Total_Balance) AS avg_balance,
    AVG(Transaction_Amount) AS avg_tx_amount,
    AVG(Investment_Amount) AS avg_investment,
    SUM(CASE WHEN Investment_Amount > 0 THEN 1 ELSE 0 END) AS num_investment_operations,

    CASE
        WHEN SUM(CASE WHEN Investment_Amount > 0 THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
    END AS is_investor
FROM view_full_analytics
GROUP BY
    Customer_ID,
    Age,
    Customer_Type,
    customer_region,
    Branch_ID,
    branch_region;

-- 5.2 Transaction-level features (1 row per transaction)
CREATE OR REPLACE VIEW python_transaction_features AS
SELECT
    Transaction_ID,
    Customer_ID,
    Age,
    Customer_Type,
    customer_region,
    Branch_ID,
    branch_region,
    Account_Type,
    Investment_Type,

    Total_Balance,
    Transaction_Amount,
    Investment_Amount,
    txn_year,
    txn_month,

    CASE WHEN Investment_Amount > 0 THEN 1 ELSE 0 END AS will_invest
FROM view_full_analytics;

-- 5.3 Branch-level features (1 row per branch)
CREATE OR REPLACE VIEW python_branch_features AS
SELECT
    Branch_ID,
    branch_region,
    Firm_Revenue,
    Expenses,
    true_profit_margin,

    COUNT(DISTINCT Customer_ID) AS num_customers,
    COUNT(*) AS num_transactions,
    SUM(Transaction_Amount) AS total_tx_amount,
    SUM(Investment_Amount) AS total_investment_amount,
    AVG(Total_Balance) AS avg_customer_balance
FROM view_full_analytics
GROUP BY
    Branch_ID,
    branch_region,
    Firm_Revenue,
    Expenses,
    true_profit_margin;
