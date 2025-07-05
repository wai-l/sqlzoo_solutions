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