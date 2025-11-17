import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from scipy import stats
from scipy.stats import mannwhitneyu
import matplotlib.pyplot as plt
import seaborn as sns

#MySQL information 
USER = "root"
PWD  = "*******"
HOST = "*******"
DB   = "superstore_db"

# 2)connexion
engine = create_engine(f"mysql+pymysql://{USER}:{PWD}@{HOST}/{DB}?charset=utf8mb4")

# 3)download views
v_orders   = pd.read_sql("SELECT * FROM v_orders;", engine, parse_dates=["order_date", "ship_date"])
v_monthly  = pd.read_sql("SELECT * FROM v_monthly;", engine)
v_customers = pd.read_sql("SELECT * FROM v_customers;", engine)
v_products = pd.read_sql("SELECT * FROM v_products;", engine)


# 4)checks
print("v_orders shape:", v_orders.shape)
print("v_monthly shape:", v_monthly.shape)
print("v_customers shape:", v_customers.shape)
print("v_products shape:", v_products.shape)


print(v_orders.columns)

#############

num_cols = ["sales", "profit", "discount", "quantity", "margin_rate", "shipping_delay_days"]
for c in num_cols:
    v_orders[c] = pd.to_numeric(v_orders[c], errors="coerce")

def discount_bucket(x):
    if x == 0:           return "0%"
    if x < 0.10:         return "0-10%"
    if x < 0.20:         return "10-20%"
    if x < 0.30:         return "20-30%"
    return ">=30%"

v_orders["discount_bucket"] = v_orders["discount"].apply(discount_bucket)


# quick data validation

print("Checking column types:")
print(v_orders.dtypes[num_cols].to_string(), "\n")

print("Sample of the new columns:")
print(v_orders[["discount", "discount_bucket", "order_date", "month"]].head())

print("Unique discount buckets:")
print(v_orders["discount_bucket"].value_counts().sort_index(), "\n")

print(" Month range in data:")
print(f"From {v_orders['month'].min().date()} to {v_orders['month'].max().date()}\n")

print("Quick descriptive stats (sales, profit, discount, margin_rate):")
print(v_orders[["sales", "profit", "discount", "margin_rate"]].describe().T.round(3))

##### Analytics 

#Subsets
profit_consumer  = v_orders.loc[v_orders["segment"]=="Consumer", "profit"].dropna()
profit_corporate = v_orders.loc[v_orders["segment"]=="Corporate", "profit"].dropna()

print(f"Consumer n={len(profit_consumer)}, Corporate n={len(profit_corporate)}")


#verify normality 
from scipy.stats import shapiro
shapiro_cons = shapiro(profit_consumer)
shapiro_corp = shapiro(profit_corporate)
print(f"Consumer normality p = {shapiro_cons.pvalue:.4f}")
print(f"Corporate normality p = {shapiro_corp.pvalue:.4f}")
##no p <0.005, then we should use a non-parametric test 


u_stat, p_val_u = mannwhitneyu(profit_consumer, profit_corporate, alternative="two-sided")

print(f"U-statistic = {u_stat:.3f}")
print(f"p-value = {p_val_u:.4f}")

print(f"Median(Consumer)  = {profit_consumer.median():.2f}")
print(f"Median(Corporate) = {profit_corporate.median():.2f}")

if p_val_u < 0.05:
    print("Significant difference between segments (reject H₀).")
else:
    print("No significant difference detected (fail to reject H₀).")


# Insight:
# Mann–Whitney test confirms no significant difference (p = 0.72)
# between Consumer and Corporate profit distributions.
# Median profits are nearly identical (~9–10 $ per order),
# suggesting similar profitability profiles despite high variance.

#######bootstrap


rng = np.random.default_rng(42)

def bootstrap_ci_mean(series, n_boot=10000, alpha=0.05):
    """Compute bootstrap confidence interval for the mean."""
    s = series.dropna().to_numpy()
    boots = rng.choice(s, size=(n_boot, s.size), replace=True).mean(axis=1)
    lo, hi = np.quantile(boots, [alpha/2, 1 - alpha/2])
    return lo, hi, boots.mean()

#apply to each segment
bootstrap_results = (
    v_orders.groupby("segment")["margin_rate"]
    .apply(lambda s: pd.Series(bootstrap_ci_mean(s), index=["ci_lo","ci_hi","boot_mean"]))
    .reset_index()
)

bootstrap_results

bootstrap_pivot = (
    bootstrap_results
    .pivot(index="segment", columns="level_1", values="margin_rate")
    .reset_index()
)
bootstrap_pivot

# Insight:
# Consumer shows a stable positive margin (~21%, CI [0.15–0.27]).
# Corporate margins are weaker and uncertain (CI crosses 0).
# Home Office margins are negative, confirming structural losses.

#plot bootstrap 
plt.figure(figsize=(6,4))
plt.errorbar(
    bootstrap_pivot["segment"],
    bootstrap_pivot["boot_mean"],
    yerr=[bootstrap_pivot["boot_mean"] - bootstrap_pivot["ci_lo"],
          bootstrap_pivot["ci_hi"] - bootstrap_pivot["boot_mean"]],
    fmt='o', capsize=5, color='darkcyan', ecolor='gray', elinewidth=2
)
plt.axhline(0, color='red', linestyle='--', alpha=0.6)
plt.title("Bootstrap 95% CI for Margin Rate by Segment")
plt.ylabel("Mean margin_rate")
plt.show()


####other visualisaitons: 

plt.figure(figsize=(6,4))
sns.boxplot(
    data=v_orders, x="segment", y="profit",
    palette="pastel", width=0.6
)
plt.axhline(0, color="red", linestyle="--", alpha=0.6)
plt.title("Profit distribution by Segment")
plt.ylabel("Profit per order ($)")
plt.xlabel("")
plt.show()


#violinplot
plt.figure(figsize=(6,4))
sns.violinplot(
    data=v_orders, x="segment", y="margin_rate",
    inner="box"   # <- on retire 'palette' pour éviter le FutureWarning
)
plt.axhline(0, color="red", linestyle="--", alpha=0.6)
plt.title("Margin rate distribution by Segment")
plt.ylabel("Margin rate")
plt.xlabel("")
plt.tight_layout()
plt.show()

#discount vs margin rate
plt.figure(figsize=(6,4))
sns.scatterplot(
    data=v_orders, x="discount", y="margin_rate",
    hue="segment", alpha=0.7
)
plt.title("Discount vs Margin rate")
plt.xlabel("Discount")
plt.ylabel("Margin rate")
plt.legend(title="Segment")
plt.tight_layout()
plt.show()

#bootstraped means 

plt.figure(figsize=(6,4))
sns.pointplot(
    data=bootstrap_pivot,
    x="segment", y="boot_mean",
    linestyle='none',  # <- remplace join=False
    markers='o'
)

#errorbar (IC 95 %)
yerr_lower = bootstrap_pivot["boot_mean"] - bootstrap_pivot["ci_lo"]
yerr_upper = bootstrap_pivot["ci_hi"] - bootstrap_pivot["boot_mean"]

plt.errorbar(
    bootstrap_pivot["segment"],
    bootstrap_pivot["boot_mean"],
    yerr=[yerr_lower, yerr_upper],
    fmt='none', ecolor='gray', elinewidth=2, capsize=5
)

plt.axhline(0, color='red', linestyle='--', alpha=0.6)
plt.title("Bootstrap 95% CI of Mean Margin Rate")
plt.ylabel("Mean margin_rate")
plt.tight_layout()
plt.show()
