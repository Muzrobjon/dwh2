--I will begin from Step 4.5: Querying the Data Mart, because I have done previous tasks
--Aggregate Sales by Month and Category
SELECT d.month, d.year, c.category_name, 
    SUM(fs.total_amount) AS total_sales
FROM fact_sales fs
JOIN dimdate d ON fs.date_id = d.date_id
JOIN dimcategory c ON fs.category_id = c.category_id
GROUP BY d.month, d.year, c.category_name
ORDER BY d.year, d.month, total_sales DESC;

--Top-Selling Products per Quarter
SELECT d.quarter, d.year, p.product_name, 
    SUM(fs.quantity_sold) AS total_quantity_sold
FROM fact_sales fs
JOIN dimdate d ON fs.date_id = d.date_id
JOIN dimproduct p ON fs.product_id = p.product_id
GROUP BY d.quarter, d.year, p.product_name
ORDER BY d.year, d.quarter, total_quantity_sold DESC
LIMIT 5;

--Sales Performance by Employee
SELECT e.first_name, e.last_name, 
    COUNT(fs.sales_id) AS number_of_sales, 
    SUM(fs.total_amount) AS total_sales
FROM fact_sales fs
JOIN dimemployee e ON fs.employee_id = e.employee_id
GROUP BY e.first_name, e.last_name
ORDER BY total_sales DESC;

--Customer Sales Overview
SELECT cu.company_name, 
    SUM(fs.total_amount) AS total_spent, 
    COUNT(DISTINCT fs.sales_id) AS transactions_count
FROM fact_sales fs
JOIN dimcustomer cu ON fs.customer_id = cu.customer_id
GROUP BY cu.company_name
ORDER BY total_spent DESC;


--Monthly Sales Growth Rate
WITH MonthlySales AS (
    SELECT d.year, d.month,
        SUM(fs.total_amount) AS total_sales
    FROM fact_sales fs
    JOIN dimdate d ON fs.date_id = d.date_id
    GROUP BY d.year, d.month
),
MonthlyGrowth AS (
    SELECT year, month,total_sales,
        LAG(total_sales) OVER (ORDER BY year, month) AS previous_month_sales,
        (total_sales - LAG(total_sales) OVER (ORDER BY year, month)) / LAG(total_sales) OVER (ORDER BY year, month) AS growth_rate
    FROM MonthlySales
)
SELECT year, month, total_sales, 
    previous_month_sales, ROUND(growth_rate, 2)
FROM MonthlyGrowth;
