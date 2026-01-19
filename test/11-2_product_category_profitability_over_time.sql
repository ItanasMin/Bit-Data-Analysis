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
-- REFACTORED VERSIJA (NAUDOJANT SQL VIEW)
--
-- REFACTOR = pertvarkyti arba perrašyti kodą, kad jis būtų efektyvesnis ar
-- lengviau suprantamas, nekeičiant jo išorinio elgesio ar funkcionalumo.
--
-- Ši versija laikosi „DRY“ (Don't Repeat Yourself) principo. Mes apibrėžiame
-- sudėtingus JOIN sujungimus vieną kartą „View“ (rodinyje) ir naudojame tai
-- visose kitose užklausose.
-- ===================================================================

USE adv;

-- VALYMAS IR PARUOŠIMAS
-- Sukuriame View, kuriame laikysime bazinius duomenis.
-- Tai leidžia laikyti visą JOIN logiką vienoje vietoje.
DROP VIEW IF EXISTS v_SalesAnalyticsBase;

CREATE VIEW v_SalesAnalyticsBase AS
SELECT
    pp.ProductID,
    pp.Name AS product_name,
    ps.ProductSubcategoryID,
    ps.Name AS subcategory,
    pc.ProductCategoryID,
    pc.Name AS category,
    st.Name AS territory,
    soh.SalesOrderID,
    soh.Status,
    soh.OrderDate,
    ss.LineTotal AS line_revenue,
    YEAR(soh.OrderDate) AS order_year,
    QUARTER(soh.OrderDate) AS order_quarter,
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'online'
        ELSE 'direct'
    END AS sales_channel
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

-- ===================================================================
-- Analizės pradžia
-- ===================================================================

-- [1.1] Susiek produktus su jų subkategorijomis, kategorijomis, teritorijomis
-- ir pardavimo kanalais.
--
-- Čia JOIN nebereikalingi! Tiesiog imame paruoštus duomenis iš View.
SELECT
    ProductID,
    product_name AS product,
    ProductSubcategoryID,
    subcategory,
    ProductCategoryID,
    category,
    territory,
    SalesOrderID,
    Status,
    sales_channel,
    ROUND(line_revenue, 2) AS revenue
FROM v_SalesAnalyticsBase;

-- [1.2] Susiek produktus su subkategorijomis, kategorijomis, teritorijomis ir
-- pardavimo kanalais.
--
-- Idėja: pirmiausia pasidarom „švarią bazę“ su teisingu grūdėtumu:
-- Category x Territory x Channel x Year x Quarter.
SELECT
    ProductCategoryID,
    category,
    territory,
    sales_channel,
    order_year,
    order_quarter,
    ROUND(SUM(line_revenue), 2) AS order_revenue
FROM v_SalesAnalyticsBase
GROUP BY
    ProductCategoryID,
    category,
    territory,
    sales_channel,
    order_year,
    order_quarter;

-- [2] Apskaičiuok bendras pajamas bei Running Total kiekvienai kategorijai
-- pagal metus ir ketvirčius.
WITH grouped_revenue AS (
    SELECT
        category,
        order_year,
        order_quarter,
        SUM(line_revenue) AS revenue
    FROM v_SalesAnalyticsBase
    GROUP BY
        category,
        order_year,
        order_quarter
)

SELECT
    category,
    order_year,
    order_quarter,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        SUM(revenue) OVER (
            PARTITION BY category
            ORDER BY order_year, order_quarter
            ROWS UNBOUNDED PRECEDING
        ),
        2
    ) AS running_total_revenue
FROM grouped_revenue
ORDER BY
    category,
    order_year,
    order_quarter;

-- [3] Naudok CASE, kad kategorijas suskirstytum į „High Profit“ ir „Low
-- Profit“.
WITH category_totals AS (
    SELECT
        category,
        SUM(line_revenue) AS revenue
    FROM v_SalesAnalyticsBase
    GROUP BY
        category
)

SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    CASE
        WHEN revenue >= AVG(revenue) OVER () THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_group
FROM category_totals
ORDER BY
    revenue DESC;

-- [4] Naudok procentinį skaičiavimą, kad parodytum, kiek kiekviena kategorija
-- sudaro bendrų pajamų.
WITH category_totals AS (
    SELECT
        category,
        SUM(line_revenue) AS revenue
    FROM v_SalesAnalyticsBase
    GROUP BY
        category
)

SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue * 100.0) / SUM(revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM category_totals
ORDER BY
    revenue DESC;

-- [5] Panaudok RANK ir DENSE_RANK funkciją, kad išreitinguotum kategorijas
-- pagal pelningumą teritorijose ir kanaluose. Įtrauk tendencijų analizę, ar
-- kategorijos pajamos auga, mažėja ar lieka stabilios laikui bėgant.
--
-- Atkreipkite dėmesį, koks švarus dabar CTE. Tiesiog agreguojame View
-- duomenis.
WITH base_revenue AS (
    SELECT
        category,
        territory,
        sales_channel,
        order_year,
        order_quarter,
        SUM(line_revenue) AS revenue
    FROM v_SalesAnalyticsBase
    GROUP BY
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

-- Pasirinktinai: pabaigoje išvalome sukurtą View
DROP VIEW IF EXISTS v_SalesAnalyticsBase;
