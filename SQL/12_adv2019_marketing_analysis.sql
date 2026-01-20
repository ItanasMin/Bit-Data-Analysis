-- vim:fenc=utf-8:tw=79:nu:ai:si:et:ts=4:sw=4

-- ==============================================================
-- MySQL Intermediate Practice – Marketingo analizė (intermediate)
-- Duomenų bazė: AdventureWorks2019
--
-- 7 užduotys, kurios seka viena kitą (mini BI ataskaita):
--   ● 1–2 užduotys: produktas ir kainodara (marketingo offer / pricing)
--   ● 3–4 užduotys: pardavimai pagal kanalą / teritoriją
--                   (marketingo performance)
--   ● 5 užduotis: finalinis „report“ viename rezultate
--   ● 6-6.1 užduotys - advanced BI
-- ==============================================================

USE adv;

-- --------------------------------------------------------------
-- [Task 1] – Pigiausias produktas subkategorijoje (Pricing / Offer)
--
-- Parašyk SQL užklausą, kuri grąžintų produkto pavadinimą, katalogo kainą
-- (ListPrice) ir ListPrice su alias „LeastExpensive“ tam produktui, kurio
-- pardavimo kaina yra mažiausia pasirinktoje produkto subkategorijoje
-- (**ProductSubcategoryID = 37**).
--
-- Lentelės:
--   ● Production_Product
--
-- Reikalavimai:
--   ● Išvesti:
--     • Name
--     • ListPrice
--     • ListPrice su alias „LeastExpensive“
--   ● Filtruoti pagal ProductSubcategoryID = 37
--   ● Teisingai nustatyti pigiausią produktą (naudok MIN)
-- --------------------------------------------------------------

SELECT
    p.Name,
    p.ListPrice,
    p.ListPrice AS LeastExpensive
FROM production_product AS p
WHERE
    p.ProductSubcategoryID = 37
    AND p.ListPrice = (
        SELECT MIN(p2.ListPrice)
        FROM production_product AS p2
        WHERE p2.ProductSubcategoryID = 37
    );

-- --------------------------------------------------------------
-- [Task 2] – Produktų kainų segmentavimas (Pricing segmentation)
--
-- Parašyk SQL užklausą, kuri klasifikuotų produktus toje pačioje
-- subkategorijoje (ProductSubcategoryID = 37) į kainų segmentus.
--
-- Lentelės:
--   ● Production_Product
--
-- Reikalavimai:
--   ● Išvesti:
--     • Produkto pavadinimą (Name)
--     • ListPrice
--     • Kainų segmentą (PriceSegment):
--         < 20 → 'Budget'
--         20–30 → 'Mid'
--         > 30 → 'Premium'
--   ● Naudoti CASE, WHERE
-- --------------------------------------------------------------

SELECT
    Name,
    ROUND(ListPrice, 2) AS ListPrice,
    CASE
        WHEN ListPrice < 20 THEN 'Budget'
        WHEN ListPrice BETWEEN 20 AND 30 THEN 'Mid'
        ELSE 'Premium'
    END AS PriceSegment
FROM production_product
WHERE ProductSubcategoryID = 37
ORDER BY ListPrice;

-- --------------------------------------------------------------
-- [Task 3] – Pardavimų kanalų palyginimas (Channel performance)
--            (verslo žvalgyba)
--
-- Parašyk SQL užklausą, kuri parodytų, kiek užsakymų buvo atlikta kiekvienu
-- pardavimo kanalu (Online / Direct).
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
--
-- Reikalavimai:
--   ● Išvesti:
--     • Pardavimo kanalą (SalesChannel)
--     • Užsakymų skaičių (Orders)
--   ● Naudoti COUNT(), CASE, GROUP BY
--   ● Naudoti OnlineOrderFlag kanalų nustatymui (Online / Direct)
-- --------------------------------------------------------------

SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Direct'
    END AS SalesChannel,
    COUNT(*) AS Orders
FROM sales_salesorderheader
GROUP BY SalesChannel;

-- --------------------------------------------------------------
-- [Task 4] – Sales channels pagal teritorijas (Channel + Territory)
--            (verslo žvalgyba)
--
-- Kiek užsakymų buvo kiekvienoje teritorijoje per kiekvieną pardavimo kanalą?
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
--   ● Sales_SalesTerritory
--
-- Reikalavimai:
--   ● Išvesti:
--     • Teritorijos pavadinimą (TerritoryName)
--     • Pardavimo kanalą (SalesChannel)
--     • Užsakymų skaičių (Orders)
--   ● Naudoti JOIN, COUNT(), CASE, GROUP BY
-- --------------------------------------------------------------

SELECT
    st.Name AS TerritoryName,
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Direct'
    END AS SalesChannel,
    COUNT(*) AS Orders
FROM sales_salesorderheader AS soh
INNER JOIN sales_salesterritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    TerritoryName, SalesChannel
ORDER BY
    TerritoryName, SalesChannel;

-- --------------------------------------------------------------
-- [Task 5] – Apžvalginė marketingo ataskaita (mini BI marketing report)
--
-- Parašyk SQL užklausą, kuri sukurtų galutinę, apžvalginę marketingo ataskaitą
-- pagal teritorijas.
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
--   ● Sales_SalesTerritory
--
-- Reikalavimai:
--   ● Išvesti:
--     • TerritoryName
--     • OrdersOnline (Online užsakymų skaičių)
--     • OrdersDirect (Direct užsakymų skaičių)
--     • TotalOrders
--     • ChannelWinner – kuris kanalas dominuoja teritorijoje
--       (Online, Direct, Equal)
--   ● Naudoti SUM(CASE WHEN ...), GROUP BY, CASE
--   ● SUM(CASE WHEN ...) leidžia daryti pivot'ą be PIVOT funkcijos.
-- --------------------------------------------------------------

-- Solution no. 1
SELECT
    st.Name AS TerritoryName,

    SUM(CASE WHEN soh.OnlineOrderFlag = 1 THEN 1 ELSE 0 END) AS OrdersOnline,
    SUM(CASE WHEN soh.OnlineOrderFlag = 0 THEN 1 ELSE 0 END) AS OrdersDirect,

    COUNT(*) AS TotalOrders,

    CASE
        WHEN
            SUM(CASE WHEN soh.OnlineOrderFlag = 1 THEN 1 ELSE 0 END)
            > SUM(CASE WHEN soh.OnlineOrderFlag = 0 THEN 1 ELSE 0 END)
            THEN 'Online'
        WHEN
            SUM(CASE WHEN soh.OnlineOrderFlag = 1 THEN 1 ELSE 0 END)
            < SUM(CASE WHEN soh.OnlineOrderFlag = 0 THEN 1 ELSE 0 END)
            THEN 'Direct'
        ELSE 'Equal'
    END AS ChannelWinner

FROM sales_salesorderheader AS soh
INNER JOIN sales_salesterritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    TerritoryName
ORDER BY
    TotalOrders DESC;

-- Solution no. 2 (does not duplicate SUM calculations with CASE/WHEN)
WITH territory_orders AS (
    SELECT
        st.Name AS TerritoryName,
        SUM(CASE WHEN soh.OnlineOrderFlag = 1 THEN 1 ELSE 0 END)
            AS OrdersOnline,
        SUM(CASE WHEN soh.OnlineOrderFlag = 0 THEN 1 ELSE 0 END)
            AS OrdersDirect
    FROM sales_salesorderheader AS soh
    INNER JOIN sales_salesterritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        st.Name
)

SELECT
    TerritoryName,
    OrdersOnline,
    OrdersDirect,
    OrdersOnline + OrdersDirect AS TotalOrders,
    CASE
        WHEN OrdersOnline > OrdersDirect THEN 'Online'
        WHEN OrdersOnline < OrdersDirect THEN 'Direct'
        ELSE 'Equal'
    END AS ChannelWinner
FROM territory_orders
ORDER BY
    TotalOrders DESC;

-- --------------------------------------------------------------
-- [Task 6] – Periodų analizė pagal kanalus (metai–mėnuo)
--
-- Parašyk SQL užklausą, kuri parodytų **metinius ir mėnesinius pardavimus
-- pagal kanalus**, naudojant TotalDue: Orders + SUM(TotalDue).
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
--
-- Reikalavimai:
--   ● Išvesti:
--     • OrderYear (metai)
--     • OrderMonth (mėnuo)
--     • SalesChannel (Online / Direct pagal OnlineOrderFlag)
--     • Orders (užsakymų skaičius)
--     • Revenue (SUM(TotalDue))
--   ● Naudoti funkcijas: YEAR(), MONTH(), CASE, COUNT(), SUM()
--   ● Grupavimas: pagal **metus, mėnesį ir kanalą**
--   ● Rikiavimas: pagal metus, mėnesį, kanalą
-- --------------------------------------------------------------

SELECT
    YEAR(soh.OrderDate) AS OrderYear,
    MONTH(soh.OrderDate) AS OrderMonth,
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Direct'
    END AS SalesChannel,
    COUNT(soh.SalesOrderID) AS Orders,
    ROUND(SUM(soh.TotalDue), 2) AS Revenue
FROM sales_salesorderheader AS soh
GROUP BY
    OrderYear,
    OrderMonth,
    SalesChannel
ORDER BY
    OrderYear,
    OrderMonth,
    SalesChannel;

-- --------------------------------------------------------------
-- [Task 6.1] – Reitingavimas: teritorijų rangai pagal sales channel
--
-- Parašyk SQL užklausą, kuri kiekvienam **metų–mėnesio periodui**
-- išreitinguotų teritorijas pagal **pajamas (SUM(TotalDue))**, bet **atskirai
-- Online ir Direct kanalams**.
--
-- Lentelės:
--   ● Sales_SalesOrderHeader
--   ● Sales_SalesTerritory
--
-- Reikalavimai:
--   ● Išvesti:
--     • OrderYear
--     • OrderMonth
--     • SalesChannel (Online / Direct)
--     • TerritoryName
--     • Revenue (SUM(TotalDue))
--     • RevenueRank (rangas teritorijoms pagal pajamas)
--   ● Naudoti **window function**: RANK() arba DENSE_RANK()
--   ● Funkcijos: YEAR(), MONTH(), CASE, SUM(), RANK() / DENSE_RANK(), CTE
--   ● Rangą skaičiuok taip, kad:
--     • Kiekvienam **metų–mėnesio periodui** būtų atskiras reitingas
--     • Kiekvienam **kanalui** būtų atskiras reitingas
--     • Rikiavimas rezultate: pagal metus, mėnesį, kanalą, rangą (nuo 1)
-- --------------------------------------------------------------

WITH territory_monthly AS (
    SELECT
        st.TerritoryID,
        st.Name AS TerritoryName,

        YEAR(soh.OrderDate) AS OrderYear,
        MONTH(soh.OrderDate) AS OrderMonth,
        CASE
            WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
            ELSE 'Direct'
        END AS SalesChannel,

        SUM(soh.TotalDue) AS Revenue
    FROM sales_salesorderheader AS soh
    INNER JOIN sales_salesterritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        st.TerritoryID,
        st.Name,
        OrderYear,
        OrderMonth,
        SalesChannel
)

-- Window functions (RANK / DENSE_RANK) taikomos PO agregacijos.
-- Todėl pirmiausia agreguojame (SUM),
-- o reitingavimą atliekame tik išorinėje užklausoje.
SELECT
    OrderYear,
    OrderMonth,
    SalesChannel,
    TerritoryName,
    ROUND(Revenue, 2) AS Revenue,
    -- Jei nori be „skylučių“ ranguose, vietoje RANK() naudok DENSE_RANK()
    RANK() OVER (
        PARTITION BY OrderYear, OrderMonth, SalesChannel
        ORDER BY Revenue DESC
    ) AS RevenueRank
FROM territory_monthly
ORDER BY
    OrderYear,
    OrderMonth,
    SalesChannel,
    RevenueRank,
    TerritoryName;
