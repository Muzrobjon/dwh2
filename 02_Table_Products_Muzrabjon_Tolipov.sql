--Step 2.1 Staging Tables (done)
--Step 2.2: Dimension Table (done)
--in last lesson

--Step 2.3: Fact Table
CREATE TABLE fact_product_sales (
    fact_sales_id SERIAL PRIMARY KEY,
    date_id VARCHAR(50),
    product_id INT,
    quantity_sold INT,
    total_sales DECIMAL(10,2),
    FOREIGN KEY (date_id) REFERENCES dimdate(date_id),
    FOREIGN KEY (product_id) REFERENCES dimproduct(product_id)
);

--Step 2.4: Populating the Fact Table

--this task already have done in last lesson
INSERT INTO DimProduct (Product_ID, Product_Name, Supplier_ID, Category_ID, Quantity_Per_Unit, Unit_Price, Units_In_Stock)
SELECT Product_ID, Product_Name, Supplier_ID, Category_ID, Quantity_Per_Unit, Unit_Price, Units_In_Stock
FROM staging.staging_products
WHERE Discontinued = FALSE;



INSERT INTO fact_product_sales (date_id, product_id, quantity_sold, total_sales)
SELECT dd.date_id, p.product_id, sod.quantity, (sod.quantity * sod.unit_price) AS total_sales
FROM staging.staging_order_details sod
JOIN staging.staging_orders s ON sod.order_id = s.order_id
JOIN dimdate dd ON s.order_date = dd.date 
JOIN staging.staging_products p ON sod.product_id = p.product_id;


--Top-Selling Products


SELECT p.product_name,
    SUM(fps.quantity_sold) AS total_quantity_sold,
    SUM(fps.total_sales) AS total_revenue
FROM fact_product_sales fps
JOIN dimproduct p ON fps.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

--Products With Low Stock Levels

SELECT 
    Product_ID,
    Product_Name,
    Units_In_Stock
FROM 
    DimProduct
WHERE 
    Units_In_Stock < 10;  -- Assumes a critical low stock level threshold of 10 units


--Sales Trends by Product Category
SELECT c.category_name, 
    EXTRACT(YEAR FROM d.date) AS year,
    EXTRACT(MONTH FROM d.date) AS month,
    SUM(fps.quantity_sold) AS total_quantity_sold,
    SUM(fps.total_sales) AS total_revenue
FROM fact_product_sales fps
JOIN dimproduct p ON fps.product_id = p.product_id
JOIN dimcategory c ON p.category_id = c.category_id
JOIN dimdate d ON fps.date_id = d.date_id
GROUP BY c.category_name,  year, month, d.date
ORDER BY year, month, total_revenue DESC;

--Inventory Valuation
SELECT p.product_name, p.units_in_stock, p.unit_price,
    (p.units_in_stock * p.unit_price) AS inventory_value
FROM dimproduct p
ORDER BY inventory_value DESC;

--Supplier Performance Based on Product Sales
SELECT s.company_name,
    COUNT(DISTINCT fps.fact_sales_id) AS number_of_sales_transactions,
    SUM(fps.quantity_sold) AS total_products_sold,
    SUM(fps.total_sales) AS total_revenue_generated
FROM fact_product_sales fps
JOIN dimproduct p ON fps.product_id = p.product_id
JOIN dimsupplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_revenue_generated DESC;