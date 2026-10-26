# 📊 Advanced SQL Analytics — Sales & Customer Intelligence

## 📌 Project Overview

This project demonstrates how **Microsoft SQL Server** can be used to transform raw sales, product, and customer data into meaningful business insights.

The analysis goes beyond basic SQL queries and focuses on **advanced analytical techniques** commonly used by Data Analysts and BI Analysts, including:

- 📅 Time-series analysis
- 📈 Cumulative / running analysis
- 🔄 Year-over-Year (YoY) analysis
- 📊 Month-over-Month (MoM) analysis
- 📦 Product performance analysis
- 🧩 Part-to-whole analysis
- 🎯 Customer segmentation
- 💰 Customer spending analysis
- 👥 Customer behavior analysis
- 🪟 Window functions
- 🧱 CTEs
- 👁️ SQL Views
- 📑 Analytical reporting

The goal was not simply to write SQL queries, but to answer **real business questions using SQL**.

---

# 🎯 Business Objective

The main objective of this project is to understand:

> **How are sales, products, and customers performing over time, and which customers/products/categories should the business focus on?**

The analysis answers questions such as:

- How do sales change over time?
- What is the running total of sales?
- How does product performance compare with its historical average?
- Which products are increasing or decreasing compared with the previous year?
- How are products performing month-over-month?
- Which product categories contribute the most to total sales?
- How are products distributed across different cost ranges?
- Who are the VIP, Regular, and New customers?
- What is each customer's total spending, order count, product count, and lifespan?
- How recently did customers purchase?
- What is the customer's Average Order Value?
- What is the customer's average monthly spending?

---

# 🗂️ Data Model

The project works with three main tables:

```text
                 ┌─────────────────────┐
                 │    DIM_CUSTOMERS    │
                 ├─────────────────────┤
                 │ customer_key       │
                 │ customer_number    │
                 │ first_name         │
                 │ last_name          │
                 │ birthdate          │
                 └──────────┬──────────┘
                            │
                            │ customer_key
                            │
                     ┌──────▼───────┐
                     │  FACT_SALES  │
                     ├──────────────┤
                     │ order_number │
                     │ order_date   │
                     │ customer_key │
                     │ product_key  │
                     │ sales_amount │
                     │ quantity     │
                     └──────┬───────┘
                            │
                            │ product_key
                            │
                 ┌──────────▼──────────┐
                 │    DIM_PRODUCTS    │
                 ├─────────────────────┤
                 │ product_key        │
                 │ product_name       │
                 │ category           │
                 │ cost               │
                 └─────────────────────┘
```

### Tables

**FACT_SALES**

Contains transactional sales information such as:

- Order number
- Order date
- Customer
- Product
- Sales amount
- Quantity

**DIM_CUSTOMERS**

Contains customer information such as:

- Customer key
- Customer number
- First name
- Last name
- Birthdate

**DIM_PRODUCTS**

Contains product information such as:

- Product key
- Product name
- Category
- Cost

---

# 🛠️ Tools & Technologies

| Tool                 | Purpose                          |
| -------------------- | -------------------------------- |
| Microsoft SQL Server | Data analysis                    |
| SQL                  | Data querying and transformation |
| CTEs                 | Query organization               |
| Window Functions     | Advanced analytics               |
| SQL Views            | Reporting layer                  |
| CASE Statements      | Business segmentation            |
| Date Functions       | Time-series analysis             |

---

# 🔎 Analysis Workflow

The project follows this analytical workflow:

```text
Raw Sales Data
      ↓
Data Preparation
      ↓
Time-Series Analysis
      ↓
Cumulative Analysis
      ↓
Product Performance
      ↓
YoY / MoM Analysis
      ↓
Part-to-Whole Analysis
      ↓
Product Segmentation
      ↓
Customer Segmentation
      ↓
Customer Analytics
      ↓
Reporting View
```

---

# 1️⃣ Time-Series Analysis

The first part of the project analyzes sales performance over time.

Monthly metrics include:

- Number of customers
- Total sales
- Total quantity

### Techniques Used

```sql
YEAR()
MONTH()
DATETRUNC()
FORMAT()
GROUP BY
ORDER BY
COUNT(DISTINCT)
SUM()
```

Three different approaches were explored for grouping sales by month:

### Using YEAR() and MONTH()

```sql
SELECT 
    MONTH(order_date) AS Order_Month,
    YEAR(order_date) AS Order_Year,
    COUNT(DISTINCT customer_key) AS Customers,
    SUM(sales_amount) AS Total_Sales,
    SUM(quantity) AS Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);
```

### Using DATETRUNC()

```sql
SELECT 
    DATETRUNC(MONTH, order_date) AS Order_Month,
    COUNT(DISTINCT customer_key) AS Customers,
    SUM(sales_amount) AS Total_Sales,
    SUM(quantity) AS Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY Order_Month;
```

### Using FORMAT()

```sql
FORMAT(order_date, 'yyyy-MMM')
```

This demonstrates different ways of performing **date-based aggregation in SQL Server**.

---

# 2️⃣ Cumulative Analysis

The project then moves from simple aggregation to **running calculations**.

## Running Total Sales

The running total shows how sales accumulate over time.

```sql
SUM(total_sales) OVER (
    ORDER BY order_date
) AS Running_Total
```

This is useful for understanding:

- Cumulative revenue growth
- Sales progression
- Business performance over time

---

## Running Average Sales

A running average was also calculated:

```sql
AVG(AVG_SALES) OVER (
    ORDER BY order_date
) AS Running_Avg
```

This helps identify the long-term movement of average sales.

---

# 3️⃣ Product Performance Analysis

One of the most important parts of the project is **product performance analysis**.

The analysis compares each product's yearly sales against:

1. Its average historical sales
2. Its previous year's sales

This allows the business to identify whether a product is:

- Above average
- Below average
- Increasing
- Decreasing
- Showing no change

---

# 4️⃣ Year-over-Year (YoY) Analysis

The `LAG()` window function is used to compare the current year's sales with the previous year.

```sql
LAG(curr_sales) OVER (
    PARTITION BY product_name
    ORDER BY order_year
) AS prev_sales
```

The difference is calculated using:

```sql
curr_sales - prev_sales
```

Then a business-friendly status is created:

```sql
CASE
    WHEN difference > 0 THEN 'Increase'
    WHEN difference < 0 THEN 'Decrease'
    ELSE 'No Change'
END
```

### Business Question

> Which products are improving or declining compared with the previous year?

This is much more useful than simply knowing the total sales of a product.

---

# 5️⃣ Product Performance vs Average

The project also compares yearly product sales with the product's historical average.

```sql
AVG(curr_sales) OVER (
    PARTITION BY product_name
) AS avg_sales
```

Then:

```sql
curr_sales - avg_sales AS diff_avg
```

Products are classified as:

```text
Above Avg
Below Avg
Avg
```

### Business Value

This helps identify products that are performing unusually well or poorly relative to their historical performance.

---

# 6️⃣ Month-over-Month (MoM) Analysis

The project performs monthly product-level performance analysis.

For every product, the current month's sales are compared with the previous month's sales.

```sql
LAG(curr_sales) OVER (
    PARTITION BY product_name
    ORDER BY order_month
)
```

The difference is calculated as:

```sql
Current Month Sales - Previous Month Sales
```

And categorized into:

```text
Increase
Decrease
No Change
```

### Business Question

> Which products are gaining or losing sales from one month to the next?

This can help identify:

- Seasonal changes
- Demand fluctuations
- Declining products
- Growing products
- Short-term sales trends

---

# 7️⃣ Part-to-Whole Analysis

The project analyzes how much each product category contributes to total sales.

A CTE is used to calculate category-level sales:

```sql
WITH category_sales AS (
    SELECT 
        p.category,
        SUM(f.sales_amount) AS Total_Sales
    FROM fact_sales f
    LEFT JOIN dim_products p
        ON f.product_key = p.product_key
    GROUP BY category
)
```

Then the percentage contribution is calculated using a window function:

```sql
SUM(Total_Sales) OVER ()
```

The percentage is calculated as:

```text
Category Sales
────────────── × 100
Overall Sales
```

### Business Insight

The analysis indicates that **Bikes dominate overall sales**, suggesting that the business may need to examine opportunities to strengthen the contribution of **Accessories and Clothing**.

---

# 8️⃣ Product Cost Segmentation

Products are divided into different cost ranges using a `CASE` statement.

### Segments

|     Cost | Segment    |
| -------: | ---------- |
|    < 100 | Below 100  |
|  100–500 | 100–500    |
| 500–1000 | 500–1000   |
|   > 1000 | Above 1000 |

Example:

```sql
CASE
    WHEN cost < 100 THEN 'Below 100'
    WHEN cost BETWEEN 100 AND 500 THEN '100-500'
    WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
    ELSE 'Above 1000'
END
```

The analysis then counts how many products belong to each segment.

### Business Question

> What does the company's product portfolio look like across different price/cost ranges?

---

# 9️⃣ Customer Segmentation

The project introduces a business-oriented customer segmentation model.

Customers are divided into three groups:

### 🏆 VIP

Customers who:

- Have at least 12 months of history
- Spend more than 5,000

### 👤 Regular

Customers who:

- Have at least 12 months of history
- Spend 5,000 or less

### 🆕 New

Customers whose:

- Customer lifespan is less than 12 months

The customer lifespan is calculated using:

```sql
DATEDIFF(
    MONTH,
    MIN(order_date),
    MAX(order_date)
)
```

Total customer spending is calculated using:

```sql
SUM(sales_amount)
```

---

# 🔟 Customer Reporting Layer

The final section creates a reusable SQL View:

```sql
CREATE VIEW final_report_customers AS
```

This creates a structured customer-level reporting dataset.

The view combines transactional data with customer information and calculates important customer KPIs.

---

# 📊 Customer KPIs

The final reporting view contains:

### Customer Information

- Customer Key
- Customer Number
- Customer Name
- Age
- Age Group
- Customer Segment

### Purchase Behavior

- Last Order Date
- Recency
- Total Orders
- Total Sales
- Total Products
- Customer Lifespan

### Calculated Metrics

- Average Order Value
- Average Monthly Spend

---

# 👥 Age Segmentation

Customers are grouped into age categories:

```text
Under 20
20–29
30–39
40–49
50 and Above
```

This allows the business to analyze customer behavior across demographic groups.

---

# ⏱️ Recency Analysis

Customer recency is calculated using:

```sql
DATEDIFF(
    MONTH,
    last_order_date,
    GETDATE()
)
```

This answers:

> How many months has it been since the customer's last purchase?

Recency is an important metric for identifying customers who may need:

- Re-engagement campaigns
- Promotional offers
- Personalized communication

---

# 💰 Average Order Value (AOV)

Average Order Value is calculated as:

```text
Total Sales
───────────
Total Orders
```

SQL implementation:

```sql
CASE 
    WHEN total_order = 0 THEN 0
    ELSE total_sales / total_order
END AS AOV
```

AOV helps understand how much revenue the business generates per order.

---

# 📈 Average Monthly Spend

The project also calculates average monthly customer spending:

```text
Total Sales
───────────
Customer Lifespan
```

SQL implementation:

```sql
CASE 
    WHEN lifespan = 0 THEN 0
    ELSE total_sales / lifespan
END AS AVG_MONTHLY_SPEND
```

This provides another way to evaluate customer value.

---

# 🧠 Advanced SQL Concepts Demonstrated

This project demonstrates practical knowledge of:

### Aggregation

```sql
SUM()
AVG()
COUNT()
COUNT(DISTINCT)
MIN()
MAX()
```

### Date Functions

```sql
YEAR()
MONTH()
DATETRUNC()
FORMAT()
DATEDIFF()
GETDATE()
```

### Window Functions

```sql
LAG()
SUM() OVER()
AVG() OVER()
PARTITION BY
ORDER BY
```

### Query Structuring

```sql
WITH ... AS
```

CTEs were used to break complex analytical problems into manageable steps.

### Conditional Logic

```sql
CASE WHEN
```

Used for:

- Customer segmentation
- Age groups
- Performance classification
- Product cost ranges

### Joins

```sql
LEFT JOIN
```

Used to combine:

```text
FACT_SALES
    +
DIM_PRODUCTS
    +
DIM_CUSTOMERS
```

### SQL Views

```sql
CREATE VIEW
```

Used to create a reusable customer reporting layer.

---

# 💼 Business Questions Answered

This project demonstrates how SQL can answer practical business questions:

| Business Question                                  | SQL Technique          |
| -------------------------------------------------- | ---------------------- |
| How are sales changing over time?                  | Date aggregation       |
| What are cumulative sales?                         | `SUM() OVER()`         |
| What is the running average?                       | `AVG() OVER()`         |
| Is a product performing above its average?         | Window functions       |
| Is product performance improving YoY?              | `LAG()`                |
| Is product performance improving MoM?              | `LAG()`                |
| Which category contributes most to sales?          | Part-to-whole analysis |
| What percentage of sales comes from each category? | Window functions       |
| How are products distributed by cost?              | `CASE` segmentation    |
| Who are the VIP customers?                         | Customer segmentation  |
| How recently did customers purchase?               | `DATEDIFF()`           |
| What is the average order value?                   | Calculated KPI         |
| What is average monthly customer spending?         | Customer KPI           |

---

# 🔄 End-to-End Analytical Approach

The project follows a realistic Data Analyst workflow:


Business Question
       ↓
Understand Data
       ↓
Join Fact & Dimension Tables
       ↓
Aggregate Data
       ↓
Analyze Trends
       ↓
Compare Performance
       ↓
Segment Customers & Products
       ↓
Calculate KPIs
       ↓
Create Reporting View
       ↓
Generate Business Insights


This approach demonstrates that SQL is not only about writing queries.

It is about turning:

**Business Question → Data → Analysis → Insight → Decision**

---

# 📁 Project Structure

```text
Advanced-SQL-Analytics/
│
├── Advance SQL Analytics.sql
│
└── README.md
```

---

# 🚀 Key Learning Outcomes

Through this project, I strengthened my ability to:

- Analyze transactional sales data
- Work with fact and dimension tables
- Perform time-series analysis
- Use SQL Server date functions
- Build cumulative calculations
- Perform YoY and MoM analysis
- Use `LAG()` for previous-period comparisons
- Use window functions for analytical calculations
- Perform part-to-whole analysis
- Build customer segmentation logic
- Create customer-level KPIs
- Create reusable SQL reporting views
- Translate business questions into SQL analysis

---

# 🎯 Why This Project Matters for Data Analytics

A Data Analyst is not only expected to know SQL syntax.

The real value comes from being able to answer:

> **What is happening in the business?**

> **Why is it happening?**

> **Which customers or products require attention?**

> **What should the business focus on next?**

This project focuses on that mindset by using SQL to move from **raw transactional data to analytical insights and reporting-ready data**.

---

# 👨‍💻 Author

**Taha Parvaiz**

linked In : www\.linkedin.com/in/taha-parvaiz-939705321&#x20;

Aspiring / Entry-Level Data Analyst focused on:


SQL
Python
Power BI
Excel
Data Visualization
Business Analytics


Currently building practical analytics projects focused on solving **real business problems with data**.

---

## ⭐ Project Highlight

> **Advanced SQL Analytics — transforming sales and customer data into actionable business insights using SQL Server.**

If you find this project useful, feel free to ⭐ the repository.
