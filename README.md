# Blinkit Sales & Customer Analytics

Exploratory data analysis and an interactive dashboard built on Blinkit's order, product, and customer data. The project has two independent deliverables that use overlapping but not identical source data — see [Data Notes](#data-notes--limitations) below.

## Project Structure

```
├── Blinkit_sales_dataset.ipynb      # Full sales/order EDA notebook (pandas + matplotlib)
├── blinkit_customer_dashboard.html  # Standalone interactive customer dashboard (Chart.js)
└── README.md
```

## 1. Sales EDA Notebook

**File:** `Blinkit_sales_dataset.ipynb`

Loads four source tables and merges them into one analysis-ready dataset:

| Table | Rows | Key columns |
|---|---|---|
| `blinkit_orders.csv` | 5,000 | order_id, customer_id, order_date, delivery times, order_total, payment_method |
| `blinkit_order_items.csv` | 5,000 | order_id, product_id, quantity, unit_price |
| `blinkit_products.csv` | 268 | product_id, product_name, category, brand, price, margin |
| `blinkit_customers.csv` | 2,500 | customer_id, area, segment, total_orders, avg_order_value |

**Pipeline:**
1. Load and inspect all 4 tables (`.info()`, `.describe()`, null/duplicate checks)
2. Parse `order_date`, `promised_delivery_time`, `actual_delivery_time` to datetime
3. Engineer `delivery_time_minutes` (actual delivery − order placement)
4. Sequential left-merges: `orders → customers → order_items → products`, producing a 5,000-row × 34-column `master_data` frame
5. Exploratory charts:
   - Payment method split (Card / Cash / Wallet / UPI — fairly even, ~1,200–1,300 orders each)
   - Order total distribution (histogram)
   - Delivery time distribution (mean ~19.4 min, range 5–50 min)
   - Monthly order volume trend
   - Top 10 products by quantity sold
   - Category-wise total sales
   - Delivery status breakdown (On Time / Late / Early)
   - Sales by customer segment

**Run it:**
```bash
pip install pandas numpy matplotlib
jupyter notebook Blinkit_sales_dataset.ipynb
```
Requires the 4 source CSVs in the same directory as the notebook.

## 2. Customer Analytics Dashboard

**File:** `blinkit_customer_dashboard.html`

A single self-contained HTML file (data + charts inlined, no server needed — just open it in a browser). Built with Chart.js from the `blinkit_customers` extract only.

**Sections:**
- **KPI cards** — total customers, total estimated spend, avg orders/customer, avg order value
- **Registration trend** — signups by month, plus new-vs-inactive momentum
- **Segment mix** — customer share and spend share by segment (Premium / Regular / New / Inactive)
- **Orders vs. order value** — scatter plot showing the two metrics move independently
- **Geographic spread** — customers across 316 areas; top 10 areas by count and by estimated spend
- **Distribution histograms** — orders per customer, average order value
- **Top 20 customers table** — ranked by estimated spend

**Run it:** just open `blinkit_customer_dashboard.html` in any browser. No install needed.

## Data Notes & Limitations

- The dashboard's customer data comes from a **separate, messier extract** than the notebook's. ~64% of rows were blank/incomplete from a bad merge and were excluded before analysis (2,500 of 6,852 rows retained).
- **No product- or profit-level data** exists in the dashboard's source, so no margin figures appear anywhere in it.
- **`Estimated Spend`** in the dashboard is a derived proxy — `total_orders × avg_order_value` — **not** actual transaction revenue. It's flagged with a `PROXY` tag everywhere it's shown.
- PII (name, email, phone, address) is excluded from all dashboard visuals.
- The notebook's `master_data`, by contrast, is built from real order-item-level transactions and product pricing, so its sales figures (e.g. total revenue, category sales) are actuals, not estimates.

## Tech Stack

- **Notebook:** Python, pandas, numpy, matplotlib
- **Dashboard:** HTML/CSS/JS, Chart.js 4.4.1 (via CDN)
