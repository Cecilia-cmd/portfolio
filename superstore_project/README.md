# 🛒 Superstore Analytics Project

### *End-to-end Data Pipeline*

This project replicates a real-world analytics workflow:
starting from a raw CSV dataset, cleaning and modeling it in SQL, performing additional validation in Python, and finally building business-ready dashboards in Tableau.

It demonstrates my ability to **clean data**, **build KPIs**, **perform exploratory analysis**, and **design visual business insights**.

---

## 🧭 Workflow Overview

### **1. Data Preparation (Python)**

* Converted the raw CSV to UTF-8 to ensure SQL compatibility.

### **2. Data Cleaning & KPI Modeling (SQL)**

* Standardized and cleaned all fields (dates, IDs, categorical variables).
* Built analytical tables for sales, profit, margin, shipping delays, and customer behavior.
* Computed key business metrics:

  * Total Sales & Profit
  * Weighted Margin
  * Items Sold
  * Number of Orders
  * Top Customers / Top Cities
  * Shipping Delay Performance
  * Profit by State
  * Category contribution (2014–2017)

### **3. Post-SQL Validation (Python)**

* Ran additional sanity checks and descriptive statistics on cleaned data.

### **4. Visual Analytics (Tableau)**

Two dashboards were created:

* **Sales & Customers Overview**
  → `tableau/01.dashboard-sales_customers.png`

* **Operational Efficiency**
  → `tableau/02.dashboard-operational_efficiency.png`

---

## 📥 Dataset Source

Kaggle - Superstore Dataset (public):
[https://www.kaggle.com/datasets/vivek468/superstore-dataset-final](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)

---
