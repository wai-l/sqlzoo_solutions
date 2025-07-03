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
