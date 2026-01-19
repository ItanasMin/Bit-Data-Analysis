-- vim:fenc=utf-8:tw=79:nu:ai:si:et:ts=4:sw=4

-- ===================================================================
-- UŽDUOTIS 3: Produktų kategorijų pelningumo analizė per laiką, teritorijose
-- ir pardavimo kanaluose
--
-- Naudok Production_Product, Production_ProductSubcategory,
-- Production_ProductCategory, Sales_SalesOrderDetail, Sales_SalesTerritory ir
-- Sales_SalesOrderHeader lenteles.
--
-- Šiose lentelėse NETURIME savikainos (COGS), todėl „pelningumas“ šiame
-- uždavinyje reiškia PAJAMAS (Revenue).
--
-- Pajamos imamos iš Sales_SalesOrderDetail.LineTotal (eilutės suma).
--
-- + Visur pateikite informaciją apie pinigus!
--   Visose užklausose, net jei neprašoma, turi būti bent vienas stulpelis su
--   pinigais - visada reikalinga pateikti pinigus (Sales duomenų bazė,
--   darbdavys žiūrės į pinigus iškart).
-- ===================================================================

USE adv;

-- [1.1] Susiek produktus su jų subkategorijomis, kategorijomis, teritorijomis
-- ir pardavimo kanalais.
SELECT
    pp.ProductID,
    pp.Name AS product,
    ps.ProductSubcategoryID,
    ps.Name AS subcategory,
    pc.ProductCategoryID,
    pc.Name AS category,
    st.Name AS territory,
    ss.SalesOrderID,
    soh.Status,
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'online'
        ELSE 'direct'
    END AS sales_channel,
    ROUND(ss.LineTotal, 2) AS revenue
FROM production_product AS pp
INNER JOIN production_productsubcategory AS ps
    ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN production_productcategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
INNER JOIN sales_salesorderdetail AS ss
    ON pp.ProductID = ss.ProductID
INNER JOIN sales_salesorderheader AS soh
    ON ss.SalesOrderID = soh.SalesOrderID
INNER JOIN sales_salesterritory AS st
    ON soh.TerritoryID = st.TerritoryID;

-- [1.2] Susiek produktus su subkategorijomis, kategorijomis, teritorijomis ir
-- pardavimo kanalais.
--
-- Idėja: pirmiausia pasidarom „švarią bazę“ su teisingu grūdėtumu:
-- Category x Territory x Channel x Year x Quarter.
SELECT
    pc.ProductCategoryID,
    pc.Name AS category,
    st.Name AS territory,
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'online'
        ELSE 'direct'
    END AS sales_channel,
    YEAR(soh.OrderDate) AS order_year,
    QUARTER(soh.OrderDate) AS order_quarter,
    SUM(ss.LineTotal) AS revenue
FROM production_product AS pp
INNER JOIN production_productsubcategory AS ps
    ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN production_productcategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
INNER JOIN sales_salesorderdetail AS ss
    ON pp.ProductID = ss.ProductID
INNER JOIN sales_salesorderheader AS soh
    ON ss.SalesOrderID = soh.SalesOrderID
INNER JOIN sales_salesterritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    pc.ProductCategoryID,
    category,
    territory,
    sales_channel,
    order_year,
    order_quarter;

-- [2] Apskaičiuok bendras pajamas bei Running Total kiekvienai kategorijai
-- pagal metus ir ketvirčius.
WITH base_revenue AS (
    SELECT
        pc.ProductCategoryID,
        pc.Name AS category,
        st.Name AS territory,
        CASE
            WHEN soh.OnlineOrderFlag = 1 THEN 'online'
            ELSE 'direct'
        END AS sales_channel,
        YEAR(soh.OrderDate) AS order_year,
        QUARTER(soh.OrderDate) AS order_quarter,
        SUM(ss.LineTotal) AS revenue
    FROM production_product AS pp
    INNER JOIN production_productsubcategory AS ps
        ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN production_productcategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    INNER JOIN sales_salesorderdetail AS ss
        ON pp.ProductID = ss.ProductID
    INNER JOIN sales_salesorderheader AS soh
        ON ss.SalesOrderID = soh.SalesOrderID
    INNER JOIN sales_salesterritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        pc.ProductCategoryID,
        category,
        territory,
        sales_channel,
        order_year,
        order_quarter
)

SELECT
    category,
    order_year,
    order_quarter,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(
        SUM(SUM(revenue)) OVER (
            PARTITION BY category
            ORDER BY order_year, order_quarter
            ROWS UNBOUNDED PRECEDING
        ),
        2
    ) AS running_total_revenue
FROM base_revenue
GROUP BY
    category,
    order_year,
    order_quarter
ORDER BY
    category,
    order_year,
    order_quarter;

-- [3] Naudok CASE, kad kategorijas suskirstytum į „High Profit“ ir „Low
-- Profit“.
WITH category_revenue AS (
    SELECT
        pc.Name AS category,
        SUM(ss.LineTotal) AS revenue
    FROM production_product AS pp
    INNER JOIN production_productsubcategory AS ps
        ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN production_productcategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    INNER JOIN sales_salesorderdetail AS ss
        ON pp.ProductID = ss.ProductID
    GROUP BY
        pc.Name
)

SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    CASE
        WHEN revenue >= AVG(revenue) OVER () THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_group
FROM category_revenue
ORDER BY
    revenue DESC;

-- [4] Naudok procentinį skaičiavimą, kad parodytum, kiek kiekviena kategorija
-- sudaro bendrų pajamų.
WITH category_revenue AS (
    SELECT
        pc.Name AS category,
        SUM(ss.LineTotal) AS revenue
    FROM production_product AS pp
    INNER JOIN production_productsubcategory AS ps
        ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN production_productcategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    INNER JOIN sales_salesorderdetail AS ss
        ON pp.ProductID = ss.ProductID
    GROUP BY
        pc.Name
)

SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue * 100.0) / SUM(revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM category_revenue
ORDER BY
    revenue DESC;

-- [5] Panaudok RANK ir DENSE_RANK funkciją, kad išreitinguotum kategorijas
-- pagal pelningumą teritorijose ir kanaluose. Įtrauk tendencijų analizę, ar
-- kategorijos pajamos auga, mažėja ar lieka stabilios laikui bėgant.
WITH base_revenue AS (
    SELECT
        pc.ProductCategoryID,
        pc.Name AS category,
        st.Name AS territory,
        CASE
            WHEN soh.OnlineOrderFlag = 1 THEN 'online'
            ELSE 'direct'
        END AS sales_channel,
        YEAR(soh.OrderDate) AS order_year,
        QUARTER(soh.OrderDate) AS order_quarter,
        SUM(ss.LineTotal) AS revenue
    FROM production_product AS pp
    INNER JOIN production_productsubcategory AS ps
        ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN production_productcategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    INNER JOIN sales_salesorderdetail AS ss
        ON pp.ProductID = ss.ProductID
    INNER JOIN sales_salesorderheader AS soh
        ON ss.SalesOrderID = soh.SalesOrderID
    INNER JOIN sales_salesterritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        pc.ProductCategoryID,
        category,
        territory,
        sales_channel,
        order_year,
        order_quarter
)

SELECT
    category,
    territory,
    sales_channel,
    order_year,
    order_quarter,
    ROUND(revenue, 2) AS revenue,

    RANK() OVER (
        PARTITION BY territory, sales_channel, order_year, order_quarter
        ORDER BY revenue DESC
    ) AS revenue_rank,

    DENSE_RANK() OVER (
        PARTITION BY territory, sales_channel, order_year, order_quarter
        ORDER BY revenue DESC
    ) AS revenue_dense_rank,

    CASE
        -- Check if there is NO previous data (first quarter)
        WHEN
            LAG(revenue) OVER (
                PARTITION BY category, territory, sales_channel
                ORDER BY order_year, order_quarter
            ) IS NULL
            THEN 'New / N/A'

        -- Current revenue is higher than previous
        WHEN
            revenue > LAG(revenue) OVER (
                PARTITION BY category, territory, sales_channel
                ORDER BY order_year, order_quarter
            )
            THEN 'Growing'

        -- Current revenue is lower than previous
        WHEN
            revenue < LAG(revenue) OVER (
                PARTITION BY category, territory, sales_channel
                ORDER BY order_year, order_quarter
            )
            THEN 'Declining'

        ELSE 'Stable'
    END AS revenue_trend

FROM base_revenue
ORDER BY
    territory,
    sales_channel,
    order_year,
    order_quarter,
    revenue_rank;
