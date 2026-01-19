-- vim:fenc=utf-8:tw=79:nu:ai:si:et:ts=4:sw=4

-- ==============================================================
-- ADV Practice (Intermediate) — Užduotys praktikai
-- Duomenų bazė: AdventureWorks2019 (MySQL)
-- ==============================================================

USE adv;

-- --------------------------------------------------------------
-- [1] LEFT JOIN kartojimas
--
-- Išvesti produkto pavadinimą ir užsakymo numerį (SalesOrderID) visiems
-- produktams.
--
-- Lentelės:
--   ● Production_Product
--   ● LEFT JOIN Sales_SalesOrderDetail
-- --------------------------------------------------------------

SELECT
    p.Name,
    sod.SalesOrderID
FROM production_product AS p
LEFT JOIN sales_salesorderdetail AS sod
    ON p.ProductID = sod.ProductID
ORDER BY p.Name;

-- --------------------------------------------------------------
-- [2] RIGHT JOIN kartojimas
--
-- Išvesti teritorijos pavadinimą ir BusinessEntityID. Rezultate turi būti
-- visi pardavėjai, nesvarbu, ar jie dirba toje teritorijoje.
--
-- Lentelės:
--   ● Sales_SalesTerritory
--   ● Sales_SalesPerson
-- --------------------------------------------------------------

/*
-- Solution with RIGHT JOIN
SELECT
    st.Name AS TerritoryName,
    sp.BusinessEntityID
FROM sales_salesterritory AS st
RIGHT JOIN sales_salesperson AS sp
    ON st.TerritoryID = sp.TerritoryID;
*/

-- Actually, use LEFT JOIN to silence SQLFluff's rule CV08
SELECT
    st.Name AS TerritoryName,
    sp.BusinessEntityID
FROM sales_salesperson AS sp
LEFT JOIN sales_salesterritory AS st
    ON sp.TerritoryID = st.TerritoryID;

-- --------------------------------------------------------------
-- [3] JOIN kartojimas
--
-- Išvesti kontaktus, kurie nėra iš US ir gyvena miestuose, kurių pavadinimas
-- prasideda 'Pa'.
--
-- Lentelės:
--   ● Person_Address
--   ● Person_StateProvince
--
-- Išvesti:
--   ● AddressLine1
--   ● AddressLine2
--   ● City
--   ● PostalCode
--   ● CountryRegionCode
-- --------------------------------------------------------------

SELECT
    a.AddressLine1,
    a.AddressLine2,
    a.City,
    a.PostalCode,
    s.CountryRegionCode
FROM person_address AS a
INNER JOIN person_stateprovince AS s
    ON a.StateProvinceID = s.StateProvinceID
WHERE
    s.CountryRegionCode NOT IN ('US')
    AND a.City LIKE 'Pa%';

-- --------------------------------------------------------------
-- [4] JOIN kartojimas su subquery arba CTE
--
-- Išvesti darbuotojų vardą ir pavardę (kartu) ir jų gyvenamą miestą.
--
-- Lentelės:
--   ● Person_Person
--   ● HumanResources_Employee
--   ● Person_Address
--   ● Person_BusinessEntityAddress
-- --------------------------------------------------------------

WITH employee_cities AS (
    SELECT
        bea.BusinessEntityID,
        a.City
    FROM person_address AS a
    INNER JOIN person_businessentityaddress AS bea
        ON a.AddressID = bea.AddressID
)

SELECT
    ec.City,
    CONCAT(p.FirstName, ' ', p.LastName) AS full_name
FROM person_person AS p
INNER JOIN humanresources_employee AS e
    ON p.BusinessEntityID = e.BusinessEntityID
INNER JOIN employee_cities AS ec
    ON p.BusinessEntityID = ec.BusinessEntityID
ORDER BY
    p.LastName,
    p.FirstName;

-- --------------------------------------------------------------
-- [5] UNION ALL kartojimas
--
-- Parašyti SQL užklausą, kuri pateiktų visų raudonos arba mėlynos spalvos
-- produktų sąrašą.
--
-- Lentelės:
--   ● Production_Product
--
-- Išvesti:
--   ● Pavadinimą
--   ● Spalvą
--   ● Katalogo kainą (ListPrice)
--
-- Surikiuoti pagal ListPrice.
-- --------------------------------------------------------------

SELECT
    Name,
    Color,
    ListPrice
FROM production_product
WHERE Color = 'Red'
UNION ALL
SELECT
    Name,
    Color,
    ListPrice
FROM production_product
WHERE Color = 'Blue'
ORDER BY ListPrice ASC;

-- --------------------------------------------------------------
-- [6] CTE kartojimas
--
-- Rasti, kiek užsakymų per metus įvykdo kiekvienas pardavėjas.
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
-- --------------------------------------------------------------

WITH sales_per_year AS (
    SELECT
        SalesPersonID,
        YEAR(OrderDate) AS SalesYear
    FROM sales_salesorderheader
    WHERE SalesPersonID IS NOT NULL
)

SELECT
    SalesPersonID,
    SalesYear,
    COUNT(*) AS total_orders
FROM sales_per_year
GROUP BY SalesYear, SalesPersonID;

-- --------------------------------------------------------------
-- [7] Aritmetiniai skaičiavimai
--
-- Apskaičiuoti bendros metų pardavimų sumos (SalesYTD) padalijimą iš
-- komisinių procentinės dalies (CommissionPCT).
--
-- Lentelės:
--   ● Sales_SalesPerson
--
-- Išvesti:
--   ● SalesYTD
--   ● CommissionPCT
--   ● Apskaičiuotą reikšmę, suapvalintą iki artimiausio sveikojo skaičiaus
-- --------------------------------------------------------------

SELECT
    SalesYTD,
    CommissionPCT,  -- Pastaba: CommissionPCT yra dalis (pvz. 0.1 = 10%)
    FLOOR(SalesYTD / CommissionPCT) AS Computed
FROM sales_salesperson
WHERE CommissionPCT != 0;

-- --------------------------------------------------------------
-- [8] STRING duomenų tipo manipuliavimas
--
-- Išvesti produktų pavadinimus, kurių kainos yra tarp 1000 ir 1220.
-- Pavadinimus išvesti trimis būdais: naudojant LOWER(), UPPER() ir
-- LOWER(UPPER()).
--
-- Lentelės:
--   ● Production_Product
-- --------------------------------------------------------------

SELECT
    LOWER(Name) AS lower_name,
    UPPER(Name) AS upper_name,
    LOWER(UPPER(Name)) AS lower_upper_name
FROM
    production_product
WHERE
    ListPrice BETWEEN 1000.00 AND 1220.00;

-- --------------------------------------------------------------
-- [9] Wildcards kartojimas
--
-- Iš Production_Product lentelės išrinkti ProductID ir pavadinimą produktų,
-- kurių pavadinimas prasideda 'Lock %'.
--
-- Lentelės:
--   ● Production_Product
-- --------------------------------------------------------------

SELECT
    ProductID,
    Name
FROM production_product
WHERE Name LIKE 'Lock %'
ORDER BY ProductID;

-- --------------------------------------------------------------
-- [10] CASE ir loginių sąlygų kartojimas
--
-- Iš lentelės HumanResources_Employee parašyti SQL užklausą, kuri grąžintų
-- darbuotojų ID ir reikšmę, ar darbuotojas gauna pastovų atlyginimą
-- (SalariedFlag) kaip TRUE arba FALSE.
--
-- Lentelės:
--   ● HumanResources_Employee
--
-- Rezultatus surikiuoti taip:
--   ● Pirmiausia darbuotojai su pastoviu atlyginimu, mažėjančia ID tvarka;
--   ● Po jų kiti darbuotojai, didėjančia ID tvarka.
--
-- Naudoti CASE tiek stulpelio konvertavimui, tiek rikiavimui.
-- --------------------------------------------------------------

SELECT
    BusinessEntityID,
    CASE WHEN SalariedFlag = 1 THEN 'TRUE' ELSE 'FALSE' END AS SalariedFlag
FROM humanresources_employee
ORDER BY
    CASE WHEN SalariedFlag = 1 THEN BusinessEntityID END DESC,
    CASE WHEN SalariedFlag = 0 THEN BusinessEntityID END;

-- --------------------------------------------------------------
-- [11] Window Functions kartojimas
--
-- Parašyti SQL užklausą, kuri atrinktų asmenis, gyvenančius bent kažkurioje
-- teritorijoje (NOT NULL) ir kurių SalesYTD reikšmė nelygi 0.
--
-- Lentelės:
--   ● Sales_SalesPerson
--   ● Person_Person
--   ● Person_Address
--
-- Išvesti:
--   ● Vardą
--   ● Pavardę
--   ● Pardavimų sumą SalesYTD
--   ● Pašto kodą PostalCode
--   ● Eilučių numeraciją (row_num)
--   ● Reitingą (rank_num)
--   ● Glaustą reitingą (dense_rank_num)
--   ● Padalijimą į kvartilius (quartile)
--
-- Rikiuoti pagal PostalCode stulpelį.
-- Naudoti ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE() funkcijas.
-- --------------------------------------------------------------

SELECT
    p.FirstName,
    p.LastName,
    s.SalesYTD,
    a.PostalCode,
    ROW_NUMBER() OVER (ORDER BY a.PostalCode) AS row_num,
    RANK() OVER (ORDER BY a.PostalCode) AS rank_num,
    DENSE_RANK() OVER (ORDER BY a.PostalCode) AS dense_rank_num,
    NTILE(4) OVER (ORDER BY a.PostalCode) AS quartile
FROM sales_salesperson AS s
INNER JOIN person_person AS p
    ON s.BusinessEntityID = p.BusinessEntityID
INNER JOIN person_address AS a
    ON p.BusinessEntityID = a.AddressID
WHERE
    s.TerritoryID IS NOT NULL
    AND s.SalesYTD != 0;

-- --------------------------------------------------------------
-- [12] Agregacijų kartojimas su Window Functions
--
-- Iš lentelės Sales_SalesOrderDetail parašyti SQL užklausą, kuri
-- apskaičiuotų:
--   ● suminį kiekį
--   ● vidurkį
--   ● užsakymų skaičių
--   ● mažiausią ir didžiausią užsakytą kiekį (OrderQty) kiekvienam
--     SalesOrderID.
--
-- Atrinkti tik tuos užsakymus, kurių SalesOrderID yra 43659 ir 43664.
--
-- Lentelės:
--   ● Sales_SalesOrderDetail
--
-- Išvesti:
--   ● SalesOrderID
--   ● ProductID
--   ● OrderQty
--   ● suminį kiekį
--   ● vidurkį
--   ● užsakymų skaičių
--   ● minimalų kiekį
--   ● maksimalų kiekį
--
-- Naudoti šias window funkcijas: SUM(), AVG(), COUNT(), MIN(), MAX() kartu su
-- OVER (PARTITION BY SalesOrderID) — kad būtų galima skaičiuoti reikšmes pagal
-- kiekvieną užsakymo ID nesugrupuojant eilučių.
-- --------------------------------------------------------------

SELECT
    SalesOrderID,
    ProductID,
    OrderQty,
    SUM(OrderQty) OVER win AS total_quantity,
    AVG(OrderQty) OVER win AS avg_quantity,
    COUNT(OrderQty) OVER win AS order_count,
    MIN(OrderQty) OVER win AS min_quantity,
    MAX(OrderQty) OVER win AS max_quantity
FROM sales_salesorderdetail
WHERE SalesOrderID IN (43659, 43664)
WINDOW win AS (PARTITION BY SalesOrderID);
