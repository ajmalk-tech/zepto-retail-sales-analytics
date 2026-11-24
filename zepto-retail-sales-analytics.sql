-- 1. Database and raw table
create database zepto_analytics;
use zepto_analytics;
create table raw_zepto_sales(OrderID varchar(50), OrderDateTime varchar(50), CustomerID varchar(50), ProductID varchar(50), StoreID varchar(50), PaymentID varchar(50), PromotionID varchar(50), Quantity varchar(50), UnitPrice varchar(50), GrossAmount varchar(50), DiscountAmount varchar(50), NetAmount varchar(50), DeliveryMinutes varchar(50), OrderStatus varchar(50), OperationCharges varchar(50), OrderProfit varchar(50));

-- 2. Import CSV in MySQL Workbench before continuing
select count(*) as row_count from raw_zepto_sales;
select*from raw_zepto_sales limit 5;

-- 3. Data quality checks
select OrderStatus, count(*) as row_count from raw_zepto_sales group by OrderStatus order by row_count desc;
select*from raw_zepto_sales where OrderStatus is null or trim(OrderStatus) = '';
select count(*) as missing_sales_values from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (NetAmount is null or trim(NetAmount) = '');
select OrderID, count(*) as how_many from raw_zepto_sales group by OrderID having count(*) > 1 limit 10;
select count(*) as incomplete_orders from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (OrderID is null or trim(OrderID) = '' or OrderDateTime is null or trim(OrderDateTime) = '' or ProductID is null or trim(ProductID) = '' or Quantity is null or trim(Quantity) = '');
select count(*) as invalid_amounts from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (NetAmount is null or trim(NetAmount) = '' or trim(NetAmount) not regexp '^-?[0-9]+([.][0-9]+)?$');
select count(*) as invalid_amount_rows from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (UnitPrice not regexp '^-?[0-9]+([.][0-9]+)?$' or GrossAmount not regexp '^-?[0-9]+([.][0-9]+)?$' or DiscountAmount not regexp '^-?[0-9]+([.][0-9]+)?$' or OperationCharges not regexp '^-?[0-9]+([.][0-9]+)?$' or OrderProfit not regexp '^-?[0-9]+([.][0-9]+)?$');
select count(*) as missing_amount_rows from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (UnitPrice is null or trim(UnitPrice) = '' or GrossAmount is null or trim(GrossAmount) = '' or DiscountAmount is null or trim(DiscountAmount) = '' or OperationCharges is null or trim(OperationCharges) = '' or OrderProfit is null or trim(OrderProfit) = '');
select count(*) as unreadable_dates from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and str_to_date(OrderDateTime, '%Y-%m-%d %H:%i:%s') is null;
select count(*) as missing_store_ids from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (StoreID is null or trim(StoreID) = '');
select count(*) as missing_customer_ids from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (CustomerID is null or trim(CustomerID) = '');
select count(*) as missing_payment_ids from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (PaymentID is null or trim(PaymentID) = '');
select count(*) as invalid_quantity_values from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and (Quantity is null or trim(Quantity) = '' or trim(Quantity) not regexp '^[0-9]+([.][0-9]+)?$' );
select count(*) as fractional_quantities from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned') and cast(trim(Quantity) as decimal(12,2)) <> floor(cast(trim(Quantity) as decimal(12,2)));


-- 4. Relational tables
create table customers(CustomerID varchar(50) primary key);
insert into customers(CustomerID) select distinct trim(CustomerID) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as customer_count from customers;

create table products(ProductID varchar(50) primary key);
insert into products(ProductID) select distinct trim(ProductID) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as product_count from products;

create table stores(StoreID varchar(50) primary key);
insert into stores(StoreID) select distinct trim(StoreID) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as store_count from stores;

create table payment_methods(PaymentID varchar(50) primary key);
insert into payment_methods(PaymentID) select distinct trim(PaymentID) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as payment_method_counts from payment_methods;

create table sales_orders(OrderID varchar(50) primary key, OrderDateTime datetime not null, CustomerID varchar(50) not null, StoreID varchar(50) not null, PaymentID varchar(50) not null, OrderStatus varchar(50) not null, foreign key(CustomerID) references customers(CustomerID), foreign key(StoreID) references stores(StoreID), foreign key(PaymentID) references payment_methods(PaymentID));
insert into sales_orders(OrderID, OrderDateTime, CustomerID, StoreID, PaymentID, OrderStatus) select trim(OrderID), str_to_date(trim(OrderDateTime), '%Y-%m-%d %H:%i:%s'), trim(CustomerID), trim(StoreID), trim(PaymentID), trim(OrderStatus) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as order_count from sales_orders;

create table order_items(OrderID varchar(50) not null, ProductID varchar(50) not null, Quantity int not null, UnitPrice decimal(12,2) not null, GrossAmount decimal(12,2) not null, DiscountAmount decimal(12,2) not null, NetAmount decimal(12,2) not null, OperationCharges decimal(12,2) not null, OrderProfit decimal(12,2) not null, primary key(OrderID, ProductID), foreign key(OrderID) references sales_orders(OrderID), foreign key(ProductID) references products(ProductID));
insert into order_items(OrderID, ProductID, Quantity, UnitPrice, GrossAmount, DiscountAmount, NetAmount, OperationCharges, OrderProfit) select trim(OrderID), trim(ProductID), cast(cast(trim(Quantity) as decimal(12,2)) as unsigned), cast(trim(UnitPrice) as decimal(12,2)), cast(trim(GrossAmount) as decimal(12,2)), cast(trim(DiscountAmount) as decimal(12,2)), cast(trim(NetAmount) as decimal(12,2)), cast(trim(OperationCharges) as decimal(12,2)), cast(trim(OrderProfit) as decimal(12,2)) from raw_zepto_sales where OrderStatus in ('Delivered', 'Cancelled', 'Returned');
select count(*) as item_count from order_items;

-- 5. Business analysis queries
-- Question 1. What is the monthly net revenue from delivered orders?
select date_format(OrderDateTime, '%Y-%m') as sales_month, sum(order_items.NetAmount) as net_revenue from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by date_format(OrderDateTime, '%Y-%m') order by sales_month;  

-- Question 2. Which products sold the most units, and what net revenue and profit did they generate?
select order_items.ProductID, sum(order_items.Quantity) as units_sold, sum(order_items.NetAmount) as net_revenue, sum(order_items.OrderProfit) as total_profit from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by order_items.ProductID order by units_sold desc limit 10;

-- Question 3. Which customers placed more than one delivered order?
select sales_orders.CustomerID, count(distinct sales_orders.OrderID) as delivered_orders, sum(order_items.NetAmount) as net_spend from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by sales_orders.CustomerID having count(distinct sales_orders.OrderID) > 1 order by net_spend desc limit 10;

-- Question 4. Which stores had the highest net revenue, and what profit did they make?
select sales_orders.StoreID, sum(order_items.NetAmount) as net_revenue, sum(order_items.OrderProfit) as total_profit from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by sales_orders.StoreID order by net_revenue desc limit 10;

-- Question 5. How does each store rank by net revenue compared with its rank by profit?
select store_id, net_revenue, total_profit, rank() over (order by net_revenue desc) as revenue_rank, rank() over (order by total_profit desc) as profit_rank from (select sales_orders.StoreID as store_id, sum(order_items.NetAmount) as net_revenue, sum(order_items.OrderProfit) as total_profit from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by store_id) as store_totals order by revenue_rank;

-- Question 6. What share of all orders were delivered, cancelled, or returned?
select OrderStatus, count(*) as order_count, round(count(*) * 100.0 / (select count(*) from sales_orders), 2) as percent_of_orders from sales_orders group by OrderStatus order by order_count desc;

-- Question 7. Which delivered products had the largest total losses?
select order_items.ProductID, sum(order_items.NetAmount) as net_revenue, sum(order_items.OrderProfit) as total_profit from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by order_items.ProductID having sum(order_items.OrderProfit) < 0 order by total_profit asc limit 10;

-- Question 8. Which stores had the highest share of cancelled or returned orders?
select StoreID, count(*) as total_orders, sum(case when OrderStatus in ('Cancelled', 'Returned') then 1 else 0 end) as cancelled_or_returned_orders, round(100.0 * sum(case when OrderStatus in ('Cancelled', 'Returned') then 1 else 0 end) / count(*), 2) as problem_order_rate_percent from sales_orders group by StoreID order by problem_order_rate_percent desc limit 10;

-- Question 9. How did gross amount, discounts, net revenue, and profit vary by month for delivered orders?
select date_format(sales_orders.OrderDateTime, '%Y-%m') as sales_month, sum(order_items.GrossAmount) as gross_amount, sum(order_items.DiscountAmount) as total_discount, sum(order_items.NetAmount) as net_revenue, sum(order_items.OrderProfit) as total_profit from sales_orders join order_items on sales_orders.OrderID = order_items.OrderID where sales_orders.OrderStatus = 'Delivered' group by date_format(sales_orders.OrderDateTime, '%Y-%m') order by sales_month;




