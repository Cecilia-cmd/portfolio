-- =========================================================
-- 01_data_preparation.sql
-- Project : Banking Market Insights
-- Purpose : Data quality checks, profiling, and creation of
--           analysis-ready views.
-- Author  : Cecilia Torres
-- =========================================================

USE banking_analytics;

-- =========================================================
-- 1) DATA QUALITY CHECKS — CUSTOMERS
-- =========================================================

-- 1.1 Row count
SELECT COUNT(*) AS total_customers
FROM customers;

-- 1.2 NULL checks (key columns)
SELECT
    SUM(Age IS NULL)            AS null_age,
    SUM(Customer_Type IS NULL)  AS null_customer_type,
    SUM(City IS NULL)           AS null_city,
    SUM(Region IS NULL)         AS null_region,
    SUM(Bank_Name IS NULL)      AS null_bank_name,
    SUM(Branch_ID IS NULL)      AS null_branch_id
FROM customers;

-- 1.3 Basic stats (Age)
SELECT
    MIN(Age)    AS min_age,
    MAX(Age)    AS max_age,
    AVG(Age)    AS avg_age,
    STDDEV(Age) AS std_age
FROM customers;

-- 1.4 Age distribution by customer type
SELECT
    Customer_Type,
    COUNT(*) AS customer_count,
    AVG(Age) AS avg_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age
FROM customers
GROUP BY Customer_Type
ORDER BY customer_count DESC;

-- 1.5 Uniqueness check (Customer_ID)
SELECT
    Customer_ID,
    COUNT(*) AS cnt
FROM customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

-- =========================================================
-- 2) DATA QUALITY CHECKS — BANK
-- =========================================================

-- 2.1 Row count
SELECT COUNT(*) AS total_branches
FROM bank;

-- 2.2 NULL checks (key numeric columns)
SELECT
    SUM(Firm_Revenue IS NULL)  AS null_firm_revenue,
    SUM(Expenses IS NULL)      AS null_expenses,
    SUM(Profit_Margin IS NULL) AS null_profit_margin
FROM bank;

-- 2.3 Basic stats (financial columns)
SELECT
    MIN(Firm_Revenue)    AS min_revenue,
    MAX(Firm_Revenue)    AS max_revenue,
    AVG(Firm_Revenue)    AS avg_revenue,
    STDDEV(Firm_Revenue) AS std_revenue,

    MIN(Expenses)        AS min_expenses,
    MAX(Expenses)        AS max_expenses,
    AVG(Expenses)        AS avg_expenses,
    STDDEV(Expenses)     AS std_expenses,

    MIN(Profit_Margin)    AS min_profit_margin,
    MAX(Profit_Margin)    AS max_profit_margin,
    AVG(Profit_Margin)    AS avg_profit_margin,
    STDDEV(Profit_Margin) AS std_profit_margin
FROM bank;

-- 2.4 Uniqueness check (Branch_ID)
SELECT
    Branch_ID,
    COUNT(*) AS cnt
FROM bank
GROUP BY Branch_ID
HAVING COUNT(*) > 1;

-- 2.5 Sanity check (profit margin recomputation sample)
SELECT
    Branch_ID,
    Firm_Revenue,
    Expenses,
    Profit_Margin,
    (Firm_Revenue - Expenses) / Firm_Revenue AS recomputed_margin
FROM bank
LIMIT 20;

 /*
  NOTE:
  The dataset's Profit_Margin column is inconsistent with the standard formula:
      (Firm_Revenue - Expenses) / Firm_Revenue
  We therefore ignore Profit_Margin downstream and recompute a consistent margin
  in the clean view bank_clean (true_profit_margin).
 */

-- =========================================================
-- 3) DATA QUALITY CHECKS — TRANSACTIONS
-- =========================================================

-- 3.1 Row count
SELECT COUNT(*) AS total_transactions
FROM transactions;

-- 3.2 NULL checks (key columns)
SELECT
    SUM(Customer_ID IS NULL)        AS null_customer_id,
    SUM(Transaction_Amount IS NULL) AS null_transaction_amount,
    SUM(Total_Balance IS NULL)      AS null_total_balance,
    SUM(Investment_Amount IS NULL)  AS null_investment_amount,
    SUM(Transaction_Date IS NULL)   AS null_transaction_date
FROM transactions;

-- 3.3 Basic stats (amounts & balances)
SELECT
    MIN(Transaction_Amount)    AS min_tx_amount,
    MAX(Transaction_Amount)    AS max_tx_amount,
    AVG(Transaction_Amount)    AS avg_tx_amount,
    STDDEV(Transaction_Amount) AS std_tx_amount,

    MIN(Total_Balance)         AS min_total_balance,
    MAX(Total_Balance)         AS max_total_balance,
    AVG(Total_Balance)         AS avg_total_balance,
    STDDEV(Total_Balance)      AS std_total_balance,

    MIN(Investment_Amount)     AS min_investment_amount,
    MAX(Investment_Amount)     AS max_investment_amount,
    AVG(Investment_Amount)     AS avg_investment_amount,
    STDDEV(Investment_Amount)  AS std_investment_amount
FROM transactions;

-- 3.4 Sanity checks (non-positive amounts)
SELECT COUNT(*) AS non_positive_tx_amount
FROM transactions
WHERE Transaction_Amount <= 0;

SELECT COUNT(*) AS non_positive_total_balance
FROM transactions
WHERE Total_Balance <= 0;

-- 3.5 Uniqueness check (Transaction_ID)
SELECT
    Transaction_ID,
    COUNT(*) AS cnt
FROM transactions
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- 3.6 Economic plausibility checks
SELECT COUNT(*) AS tx_amount_gt_balance
FROM transactions
WHERE Transaction_Amount > Total_Balance;

SELECT COUNT(*) AS invest_amount_gt_balance
FROM transactions
WHERE Investment_Amount > Total_Balance;

SELECT COUNT(*) AS tx_plus_invest_gt_balance
FROM transactions
WHERE Total_Balance < (Transaction_Amount + Investment_Amount);

-- Detail view: worst offenders (Investment_Amount > Total_Balance)
SELECT
    Transaction_ID,
    Total_Balance,
    Transaction_Amount,
    Investment_Amount,
    (Investment_Amount - Total_Balance) AS investment_excess
FROM transactions
WHERE Investment_Amount > Total_Balance
ORDER BY investment_excess DESC;

 /*
  DATA QUALITY NOTES — TRANSACTIONS
  The dataset contains economically inconsistent rows, e.g.:
    - Transaction_Amount > Total_Balance
    - Investment_Amount  > Total_Balance
    - Transaction_Amount + Investment_Amount > Total_Balance

  For analytical robustness, we exclude these rows in transactions_clean.
 */

-- =========================================================
-- 4) CLEAN TRANSFORMATIONS (VIEWS)
-- =========================================================

-- 4.1 BANK clean view: recompute consistent profit margin
CREATE OR REPLACE VIEW bank_clean AS
SELECT
    Branch_ID,
    City,
    Region,
    Firm_Revenue,
    Expenses,
    (Firm_Revenue - Expenses) / Firm_Revenue AS true_profit_margin
FROM bank;

-- 4.2 TRANSACTIONS clean view: remove inconsistent rows
CREATE OR REPLACE VIEW transactions_clean AS
SELECT
    Transaction_ID,
    Customer_ID,
    Account_Type,
    Total_Balance,
    Transaction_Amount,
    Investment_Amount,
    Investment_Type,
    Transaction_Date
FROM transactions
WHERE
    Transaction_Amount <= Total_Balance
    AND Investment_Amount <= Total_Balance
    AND Total_Balance >= (Transaction_Amount + Investment_Amount);

-- Quick verification (optional)
SELECT COUNT(*) AS original_transactions FROM transactions;
SELECT COUNT(*) AS cleaned_transactions  FROM transactions_clean;
SELECT * FROM bank_clean LIMIT 5;
SELECT * FROM transactions_clean LIMIT 5;

-- =========================================================
-- 5) ANALYTICAL VIEWS
-- =========================================================

-- 5.1 customers × bank_clean
CREATE OR REPLACE VIEW view_customer_bank AS
SELECT
    c.Customer_ID,
    c.Age,
    c.Customer_Type,
    c.City   AS customer_city,
    c.Region AS customer_region,
    c.Bank_Name,
    c.Branch_ID,

    b.City   AS branch_city,
    b.Region AS branch_region,
    b.Firm_Revenue,
    b.Expenses,
    b.true_profit_margin
FROM customers c
LEFT JOIN bank_clean b
    ON c.Branch_ID = b.Branch_ID;

-- 5.2 customers × transactions_clean
CREATE OR REPLACE VIEW view_customer_transactions AS
SELECT
    t.Transaction_ID,
    t.Customer_ID,
    t.Account_Type,
    t.Total_Balance,
    t.Transaction_Amount,
    t.Investment_Amount,
    t.Investment_Type,
    t.Transaction_Date,

    c.Age,
    c.Customer_Type,
    c.City   AS customer_city,
    c.Region AS customer_region,
    c.Bank_Name,
    c.Branch_ID
FROM transactions_clean t
LEFT JOIN customers c
    ON t.Customer_ID = c.Customer_ID;

-- 5.3 full analytics view: customers × bank_clean × transactions_clean
CREATE OR REPLACE VIEW view_full_analytics AS
SELECT
    t.Transaction_ID,
    t.Customer_ID,
    t.Account_Type,
    t.Total_Balance,
    t.Transaction_Amount,
    t.Investment_Amount,
    t.Investment_Type,
    t.Transaction_Date,
    YEAR(t.Transaction_Date)  AS txn_year,
    MONTH(t.Transaction_Date) AS txn_month,

    c.Age,
    c.Customer_Type,
    c.City   AS customer_city,
    c.Region AS customer_region,
    c.Bank_Name,
    c.Branch_ID,

    b.City   AS branch_city,
    b.Region AS branch_region,
    b.Firm_Revenue,
    b.Expenses,
    b.true_profit_margin
FROM transactions_clean t
LEFT JOIN customers c
    ON t.Customer_ID = c.Customer_ID
LEFT JOIN bank_clean b
    ON c.Branch_ID = b.Branch_ID;
