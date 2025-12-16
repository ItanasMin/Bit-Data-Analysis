-- Užduotis 3: Produktų kategorijų pelningumo analizė per laiką, teritorijose ir pardavimo kanaluose 
-- Naudok Production_Product, Production_ProductSubcategory, Production_ProductCategory, 
-- Sales_SalesOrderDetail, Sales_SalesTerritory ir Sales_SalesOrderHeader lenteles. 
-- 1. Susiek produktus su jų subkategorijomis, kategorijomis, teritorijomis ir pardavimo kanalais.
SELECT 
	pc.ProductCategoryID,
    pc.name Category,
    st.name Territory,
    CASE 
		WHEN soh.onlineorderflag = 1 THEN 'Online'
        ELSE 'Direct'
	END AS Channel,
    YEAR(soh.orderdate) metai,
    QUARTER(soh.orderdate) ketvirtis,
    ROUND(SUM(sod.linetotal),2) revenue
FROM production_product pp
LEFT JOIN production_productsubcategory ps ON pp.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN production_productcategory pc ON ps.ProductCategoryID = pc.productCategoryID
JOIN sales_salesorderdetail sod ON pp.productID = sod.productid
JOIN sales_salesorderheader soh ON sod.salesorderid = soh.salesorderid
JOIN sales_salesterritory st ON soh.territoryid = st.territoryid
GROUP BY pc.productcategoryid, category, territory, channel, metai, ketvirtis;


-- 2. Apskaičiuok bendras pajamas bei runningtotal kiekvienai kategorijai pagal metus ir ketvirčius.
SELECT
    PC.Name AS Category,
    YEAR(SOH.OrderDate) AS SalesYear,
    QUARTER(SOH.OrderDate) AS SalesQuarter,
    
    -- 1. Agreguotos Pajamos per Ketvirtį (TotalRevenue)
    SUM(SOD.LineTotal) AS TotalRevenue,
    
    -- 2. Einamoji Suma (RunningTotal)
    SUM(SUM(SOD.LineTotal)) OVER (
        PARTITION BY PC.Name, YEAR(SOH.OrderDate) -- Skaičiuoti atskirai kiekvienai Kategorijai ir kiekvieniems Metams
        ORDER BY QUARTER(SOH.OrderDate)           -- Kaupti sumą pagal Ketvirčius
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- Nuo metų pradžios iki dabartinio ketvirčio
    ) AS RunningTotal
FROM
    Sales_SalesOrderDetail AS SOD
JOIN
    Sales_SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN
    Production_Product AS PP ON SOD.ProductID = PP.ProductID
JOIN
    Production_ProductSubcategory AS PS ON PP.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN
    Production_ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY
    PC.Name,
    SalesYear,
    SalesQuarter
ORDER BY
    PC.Name,
    SalesYear,
    SalesQuarter;