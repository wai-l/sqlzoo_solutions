-- Adventure Works
-- Easy Questions
-- 3. How many items with ListPrice more than $1000 have been sold?
-- using SUM instead of COUNT DISTINCT to get the total number of items sold
-- if we are counting the no. of product that were sold, we can use COUNT DISTINCT
SELECT SUM(OrderQty) 
FROM Product JOIN SalesOrderDetail ON Product.ProductID = SalesOrderDetail.ProductID
WHERE Product.ListPrice > 1000;

-- 4. Give the CompanyName of those customers with orders over $100000. Include the subtotal plus tax plus freight.
SELECT c.CompanyName, s.SalesOrderID, s.SubTotal, s.TaxAmt, s.Freight
FROM SalesOrderHeader s
LEFT JOIN Customer c 
ON s.CustomerID = c.CustomerID
WHERE s.SubTotal + s.TaxAmt + s.Freight > 100000

-- 5. Find the number of left racing socks ('Racing Socks, L') ordered by CompanyName 'Riding Cycles'
-- Using SUM and GROUP BY so if there are multiple order details rows, they will be summed up. 
SELECT c.CompanyName, p.Name, SUM(sod.OrderQty)
FROM SalesOrderDetail AS sod
LEFT JOIN SalesOrderHeader s ON sod.SalesOrderID = s.SalesOrderID
LEFT JOIN Customer c ON s.CustomerID = c.CustomerID
LEFT JOIN Product p ON sod.ProductID = p.ProductID
GROUP BY c.CompanyName, p.Name
HAVING 
    c.CompanyName = 'Riding Cycles'
    AND p.Name = 'Racing Socks, L'

-- Medium Questions
-- 6. A "Single Item Order" is a customer order where only one item is ordered. Show the SalesOrderID and the UnitPrice for every Single Item Order.
SELECT 
    SalesOrderID, 
    COUNT(DISTINCT SalesOrderDetailID) AS items, 
    AVG(UnitPrice) -- as there is only one item, both AVG and SUM should return the same value
FROM SalesOrderDetail
GROUP BY SalesOrderID
HAVING COUNT(DISTINCT SalesOrderDetailID) = 1
ORDER BY COUNT(DISTINCT SalesOrderDetailID)

-- 7. Where did the racing socks go? List the product name and the CompanyName for all Customers who ordered ProductModel 'Racing Socks'.
SELECT c.CompanyName AS company_name, p.Name AS product_name
FROM SalesOrderDetail AS sod
JOIN SalesOrderHeader AS so ON sod.SalesOrderID = so.SalesOrderID
JOIN Customer AS c ON so.CustomerID = c.CustomerID
JOIN Product AS p ON sod.ProductID = p.ProductID
JOIN ProductModel AS pm ON p.ProductModelID = pm.ProductModelID
WHERE pm.name = 'Racing Socks'

-- 8. Show the product description for culture 'fr' for product with ProductID 736.
-- skip joining ProductModel as we can directly link ProductModelID between Product and ProductModelProductDescription
SELECT p.Name, p.ProductID, pmpd.Culture, pd.Description
FROM Product AS p
JOIN ProductModelProductDescription AS pmpd ON p.ProductModelID = pmpd.ProductModelID
JOIN ProductDescription AS pd ON pmpd.ProductDescriptionID = pd.ProductDescriptionID
WHERE 
    p.ProductID = 736
    AND pmpd.Culture = 'fr'

-- 9. Use the SubTotal value in SaleOrderHeader to list orders from the largest to the smallest. 
-- For each order show the CompanyName and the SubTotal and the total weight of the order.

WITH order_weight AS (
    SELECT SalesOrderID, SUM(p.weight * sod.OrderQty) AS total_weight
    FROM SalesOrderDetail AS sod
    LEFT JOIN Product AS p ON sod.ProductID = p.ProductID
    GROUP BY SalesOrderID
)
SELECT
    c.CompanyName, 
    so.SubTotal, 
    w.total_weight
FROM SalesOrderHeader AS so
LEFT JOIN order_weight AS w ON so.SalesOrderID = w.SalesOrderID
LEFT JOIN Customer AS c ON so.CustomerID = c.CustomerID
ORDER BY so.SubTotal DESC

-- 10. How many products in ProductCategory 'Cranksets' have been sold to an address in 'London'?
-- What does sold to means? it could be the customer's address, shipping address or billing address. 
-- this query will check all three addresses, however in reality that will be something the business stakeholders need to clarify.
WITH london_customers AS (
    SELECT AddressID, City
    FROM Address
    WHERE City = 'London' -- This is assuming London only appears in the City column, which is not always true in real-world data
), 
cranksets_products AS (
    SELECT 
        Product.ProductID, 
        ProductCategory.Name
    FROM Product
    LEFT JOIN ProductCategory ON Product.ProductCategoryID = ProductCategory.ProductCategoryID
    WHERE ProductCategory.Name = 'Cranksets'
), 
cranksets_orders_london AS (
    SELECT 
        so.SalesOrderID, 
        sod.SalesOrderDetailID, 
        sod.ProductID, 
        p.Name, 
        sod.OrderQty, 
        billing_address.City AS billing_city, 
        shipping_address.City AS shipping_city, 
        customer_address.City AS customer_city
    FROM SalesOrderDetail AS sod
    LEFT JOIN SalesOrderHeader AS so ON sod.SalesOrderID = so.SalesOrderID
    LEFT JOIN cranksets_products AS p ON sod.ProductID = p.ProductID
    LEFT JOIN london_customers AS billing_address ON so.BillToAddressID = billing_address.AddressID
    LEFT JOIN london_customers AS shipping_address ON so.ShipToAddressID = shipping_address.AddressID
    -- also join customers that has a company address in London
    LEFT JOIN CustomerAddress ON so.CustomerID = CustomerAddress.CustomerID
    LEFT JOIN london_customers AS customer_address ON CustomerAddress.AddressID = customer_address.AddressID
    WHERE 
        p.Name = 'Cranksets'
        AND (
            billing_address.City = 'London' 
            OR shipping_address.City = 'London'
            OR customer_address.City = 'London'
        )
)
SELECT name, sum(OrderQty) AS total_sold
FROM cranksets_orders_london
GROUP BY name

-- 11. For every customer with a 'Main Office' in Dallas show AddressLine1 of the 'Main Office' and AddressLine1 of the 'Shipping' address - if there is no shipping address leave it blank. Use one row per customer.
-- Here we define Main Office as the customer address with the address type shown as 'Main Office'. 
-- We also assume that 'Dallas' only appears in the City column, which is not always true in real-world data.
-- There is also just one shipping address, may have to tweak the query if there's more than one
-- Another way is to find the shipping address from the ShipToAdressID in the SalesOrderHeader table, which we do not know if it will match the shipping address in the CustomerAddress table.
WITH dallas_customers AS (
    SELECT ca.CustomerID, ca.AddressID, ca.AddressType, a.AddressLine1, a.City, a.StateProvince
    FROM CustomerAddress AS ca
    LEFT JOIN Address AS a ON ca.AddressID = a.AddressID
    WHERE a.City = 'Dallas' AND ca.AddressType = 'Main Office'
), 
sa_dallas_cust AS (
    SELECT ca.CustomerID, ca.AddressID, a.AddressLine1, a.City
    FROM CustomerAddress AS ca
    LEFT JOIN Address AS a ON ca.AddressID = a.AddressID
    WHERE ca.CustomerID IN (SELECT CustomerID FROM dallas_customers)
        AND AddressType = 'Shipping'
)
SELECT 
dallas_customers.CustomerID, 
dallas_customers.AddressLine1 AS mo_address_line_1, 
dallas_customers.City AS mo_city, 
sa_dallas_cust.AddressLine1 AS shipping_address_line_1, 
sa_dallas_cust.City AS shipping_city
FROM dallas_customers
LEFT JOIN sa_dallas_cust ON dallas_customers.CustomerID = sa_dallas_cust.CustomerID

-- 12. For each order show the SalesOrderID and SubTotal calculated three ways:
-- A) From the SalesOrderHeader
-- B) Sum of OrderQty*UnitPrice
-- C) Sum of OrderQty*ListPrice
-- notes: 
-- while the logic is correct, the sub total does not match the qty * unit price or qty * discounted unit price; the sub total is larger then the two calculations
-- there is no field in the two tables that explain this difference
WITH sod_summary AS (
SELECT 
    sod.SalesOrderID, 
    SUM(sod.OrderQty * sod.UnitPrice) AS total_unit_price, 
    SUM(sod.OrderQty * p.ListPrice) AS total_list_price, 
    SUM(sod.OrderQty * sod.UnitPrice * (1 - sod.UnitPriceDiscount)) AS total_discounted_unit_price
FROM SalesOrderDetail AS sod
LEFT JOIN Product AS p ON sod.ProductID = p.ProductID
GROUP BY sod.SalesOrderID
)
SELECT 
    so.SalesOrderID, 
    so.SubTotal AS sub_total, -- it does not match qty*unitprice
    sod_summary.total_unit_price, 
    sod_summary.total_list_price,
    sod_summary.total_discounted_unit_price
FROM SalesOrderHeader AS so LEFT JOIN sod_summary ON so.SalesOrderID = sod_summary.SalesOrderID

-- an additional query to compare the sub total with the calculated values

WITH sod_summary AS (
SELECT 
    sod.SalesOrderID, 
    SUM(sod.OrderQty * sod.UnitPrice) AS total_unit_price, 
    SUM(sod.OrderQty * p.ListPrice) AS total_list_price, 
    SUM(sod.OrderQty * sod.UnitPrice * (1 - sod.UnitPriceDiscount)) AS total_discounted_unit_price
FROM SalesOrderDetail AS sod
LEFT JOIN Product AS p ON sod.ProductID = p.ProductID
GROUP BY sod.SalesOrderID
), 
total_price_summary AS (
    SELECT 
        so.SalesOrderID, 
        so.SubTotal AS sub_total, -- it does not match qty*unitprice, this need further investigation
        sod_summary.total_unit_price, 
        sod_summary.total_list_price,
        sod_summary.total_discounted_unit_price, 
        CASE 
            WHEN so.SubTotal > total_discounted_unit_price THEN 'SubTotal is greater'
            WHEN so.SubTotal < total_discounted_unit_price THEN 'SubTotal is less'
            ELSE 'SubTotal matches'
        END AS comparison_result
    FROM SalesOrderHeader AS so LEFT JOIN sod_summary ON so.SalesOrderID = sod_summary.SalesOrderID
)
SELECT
    comparison_result, 
    COUNT(*) AS count
FROM total_price_summary
GROUP BY comparison_result
ORDER BY count DESC;

-- 13. Show the best selling item by value.
-- what is the definition of value and item? 
-- item: product
-- value: currently define as total discounted unit price, we can change it to total quantity sold, other pricing figures or any other product figures available in the product table
WITH sales_order_summary AS (
SELECT 
ProductID, 
OrderQty * UnitPrice * (1 - UnitPriceDiscount) AS value -- we can change this line to change the definition of value
FROM SalesOrderDetail
)
SELECT 
sos.ProductID, 
p.Name, 
SUM(sos.value) AS total_value
FROM sales_order_summary AS sos
LEFT JOIN Product AS p ON sos.ProductID = p.ProductID
GROUP BY sos.ProductID, p.Name
ORDER BY total_value DESC
LIMIT 1