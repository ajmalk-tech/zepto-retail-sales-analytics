# Zepto Retail Sales Analytics

## Project overview

This project uses MySQL to analyze retail order data. It explores monthly net revenue, product sales, repeat customers, store performance, order outcomes, and profit.

## Dataset

- **Dataset:** Zepto Retail Business Analytics Dataset
- **Source:** [Zepto Retail Business Analytics Dataset](https://www.kaggle.com/datasets/adwaitdatir/zepto-retail-data-analytics?resource=download)
- **Format:** CSV extracted from the downloaded ZIP file

## Tools

- MySQL
- MySQL Workbench

## Data import

The CSV was imported into the `raw_zepto_sales` staging table using MySQL Workbench's Table Data Import Wizard. The raw table was kept unchanged so the original imported values remain available for reference.

## Data checks and cleaning decisions

Before building the analysis tables, I used SQL to check for:

- Blank order statuses and missing order fields
- Duplicate order IDs
- Amount values that could not be read as numbers
- Dates that could not be converted to MySQL `DATETIME`
- Quantities with fractional values

One incomplete row had a blank order status and no amount data. It was excluded from the relational tables by loading only rows with `Delivered`, `Cancelled`, or `Returned` statuses.

Some `NetAmount` values were negative. I inspected sample rows and found that they matched `GrossAmount - DiscountAmount`; I kept those source values rather than changing them.

## Database schema

- `raw_zepto_sales` stores the original CSV data as imported.
- `customers` stores customer IDs.
- `products` stores product IDs.
- `stores` stores store IDs.
- `payment_methods` stores payment IDs.
- `sales_orders` stores order dates, statuses, and links to customers, stores, and payment methods.
- `order_items` stores product IDs, quantities, and financial values for each order.

The lookup tables connect to `sales_orders` through foreign keys. `sales_orders` connects to `order_items`, which connects to `products`.

## Analysis questions

1. What is the monthly net revenue from delivered orders?
2. Which products sold the most units, and what net revenue and profit did they generate?
3. Which customers placed more than one delivered order?
4. Which stores had the highest net revenue, and what profit did they make?
5. How does each store rank by net revenue compared with its rank by profit?
6. What share of all orders were delivered, cancelled, or returned?
7. Which delivered products had the largest total losses
8. Which stores had the highest share of cancelled or returned orders?
9. How did gross amount, discounts, net revenue, and profit vary by month for delivered orders?

## How to reproduce

1. Create the database and the `raw_zepto_sales` table using the setup statements in the SQL script.
2. Import the CSV into `raw_zepto_sales` with MySQL Workbench's Table Data Import Wizard.
3. Run the data-quality checks.
4. Create and populate the relational tables.
5. Run the analysis queries.

The CSV import is a manual Workbench step. Run the setup statements before importing the CSV, then continue with the checks and table-loading statements. The table-creation and insert statements are intended for a fresh database; don't rerun them against an already populated database.

## Limitations

- The dataset contains product, customer, and store IDs, but not their names or product categories. Results therefore use IDs.
- The dataset does not include stock-on-hand information, so low-stock analysis is not possible.
- The currency is not specified in the available data.
- Promotion IDs are present in the raw table but were left out of the relational analysis tables.


