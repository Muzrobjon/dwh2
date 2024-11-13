--Step 3.1 Staging Tables
--Step 3.2: Dimension Table
--have already done
CREATE TABLE fact_customer_sales (
    fact_customer_sales_id SERIAL PRIMARY KEY,
    date_id VARCHAR(50), 
    customer_id VARCHAR(5), 
    total_amount DECIMAL(10,2),
    total_quantity INT,
    number_of_transactions INT,
    FOREIGN KEY (date_id) REFERENCES dimdate(date_id),
    FOREIGN KEY (customer_id) REFERENCES dimcustomer(customer_id)
);


--Step 3.4: Populating the Fact Table

INSERT INTO fact_customer_sales (date_id, customer_id, total_amount, total_quantity, number_of_transactions)
SELECT d.date_id, c.customer_id,
    SUM((od.unit_price * od.quantity) - (od.unit_price * od.quantity * od.discount)) AS total_amount, -- Computing the total amount 
    SUM(od.quantity) AS total_quantity,         
    COUNT(DISTINCT o.order_id) AS number_of_transactions
FROM staging.staging_orders AS o
JOIN staging.staging_order_details AS od ON o.order_id = od.order_id
JOIN dimdate AS d ON d.date = o.order_date
JOIN dimcustomer AS c ON c.customer_id = o.customer_id 
GROUP BY d.date_id, c.customer_id;


--Step 3.5: Querying the Data Mart
--Customer Sales Overview
SELECT c.customer_id, c.company_name, 
    SUM(fcs.total_amount) AS total_spent,
    SUM(fcs.total_quantity) AS total_items_purchased,
    SUM(fcs.number_of_transactions) AS transaction_count
FROM fact_customer_sales fcs
JOIN dimcustomer c ON fcs.customer_id = c.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_spent DESC;

--Top Five Customers by Total Sales
SELECT c.company_name,
    SUM(fcs.total_amount) AS total_spent
FROM fact_customer_sales fcs
JOIN dimcustomer c ON fcs.customer_id = c.customer_id
GROUP BY c.company_name
ORDER BY total_spent DESC
LIMIT 5;

--Customers by Region
--when i run this commands region cloumn gives null and i changed to "city"
SELECT c.city, 
    COUNT(*) AS number_of_customers,
    SUM(fcs.total_amount) AS total_spent_in_region
FROM fact_customer_sales fcs
JOIN dimcustomer c ON fcs.customer_id = c.customer_id
GROUP BY c.city
ORDER BY number_of_customers DESC;

--Customer Segmentation Analysis
SELECT c.customer_id, c.company_name,
    CASE
        WHEN SUM(fcs.total_amount) > 10000 THEN 'VIP'
        WHEN SUM(fcs.total_amount) BETWEEN 5000 AND 10000 THEN 'Premium'
        ELSE 'Standard'
    END AS customer_segment
FROM fact_customer_sales fcs
JOIN dim_customer c ON fcs.customer_id = c.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY SUM(fcs.total_amount) DESC;