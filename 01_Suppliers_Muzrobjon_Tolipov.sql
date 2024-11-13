--we already created staging_products, staging_suppliers, staging_order_details, dim_supplier
--Step 1.3: Fact Table
CREATE TABLE fact_supplier_purchases (
    purchase_id SERIAL PRIMARY KEY,
    supplier_id INT,
    total_purchase_amount DECIMAL,
    purchase_date DATE,
    number_of_products INT,
    FOREIGN KEY (supplier_id) REFERENCES dimsupplier(supplier_id)
);

--Step 1.4: Populating the Fact Table

INSERT INTO fact_supplier_purchases (supplier_id, total_purchase_amount, purchase_date, number_of_products)
SELECT p.supplier_id, 
    SUM(od.unit_price * od.quantity) AS total_purchase_amount, 
    o.order_date AS purchase_date, 
    COUNT(DISTINCT od.product_id) AS number_of_products
FROM staging.staging_order_details od
JOIN staging.staging_orders o ON od.order_id = o.order_id
JOIN staging.staging_products p ON od.product_id = p.product_id
GROUP BY p.supplier_id, o.order_date;


--Step 1.5: Querying the Data Mart
--Supplier Performance Report
SELECT s.company_name,
    COUNT(fsp.purchase_id) AS total_orders,
    SUM(fsp.total_purchase_amount) AS total_purchase_value,
    ROUND(AVG(fsp.number_of_products), 2) AS average_products_per_order
FROM fact_supplier_purchases fsp
JOIN dimsupplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_orders DESC, total_purchase_value DESC;


--Supplier Spending Analysis
SELECT s.company_name,
    SUM(fsp.total_purchase_amount) AS total_spend,
    EXTRACT(YEAR FROM fsp.purchase_date) AS Year,
    EXTRACT(MONTH FROM fsp.purchase_date) AS Month
FROM fact_supplier_purchases fsp
JOIN dimsupplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name, Year, Month
ORDER BY total_spend DESC;

--Product Cost Breakdown by Supplier
SELECT s.company_name,
    p.product_name,
    ROUND(AVG(od.unit_price), 2) AS average_unit_price,
    SUM(od.quantity) AS total_quantity_purchased,
    SUM(od.unit_price * od.quantity) AS total_spend
FROM staging.staging_order_details od
JOIN staging.staging_products p ON od.product_id = p.product_id
JOIN dimsupplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name, p.product_name
ORDER BY s.company_name, total_spend DESC;

--Supplier Reliability Evaluation Report
SELECT s.company_name,
    COUNT(fsp.purchase_id) AS total_transactions,
    SUM(fsp.total_purchase_amount) AS total_spent
FROM fact_supplier_purchases fsp
JOIN dimsupplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_transactions DESC, total_spent DESC;

--Top Five Products by Total Purchases per Supplier
SELECT s.company_name,
    p.product_name,
    SUM(od.unit_price * od.quantity) AS total_spend
FROM staging.staging_order_details od
JOIN staging.staging_products p ON od.product_id = p.product_id
JOIN dimsupplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name, p.product_name
ORDER BY s.company_name, total_spend DESC
LIMIT 5;