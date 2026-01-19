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
-- REFACTORED VERSIJA (NAUDOJANT TEMP TABLE)
--
-- REFACTOR = pertvarkyti arba perrašyti kodą, kad jis būtų efektyvesnis ar
-- lengviau suprantamas, nekeičiant jo išorinio elgesio ar funkcionalumo.
--
-- Ši versija skirta NAŠUMUI (Performance).
-- Vietoj to, kad kiekvienoje užklausoje iš naujo vykdytume sudėtingus JOIN
-- sujungimus (kaip 11-1 faile) arba kviestume View (kaip 11-2 faile),
-- mes vieną kartą išsaugome sujungtus duomenis RAM atmintyje.
--
-- Tai ypač naudinga dirbant su milijonais eilučių, nes duomenų bazė
-- darbą atlieka tik vieną kartą.
-- ===================================================================

USE adv;

-- CACHE (lietuviškai - PODĖLIS :) )
-- Atliekame sunkų 5 lentelių JOIN sujungimą tik VIENĄ KARTĄ ir
-- išsaugome rezultatą laikinojoje lentelėje (RAM atmintyje).
DROP TEMPORARY TABLE IF EXISTS temp_sales_cache;

CREATE TEMPORARY TABLE temp_sales_cache AS
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

-- Pasirinktinai: našumo padidinimas:
-- Sukuriame indeksą stulpeliams, pagal kuriuos dažniausiai grupuojame.
-- Tai padaro vėlesnes GROUP BY operacijas beveik momentinėmis.
CREATE INDEX idx_cat_terr ON temp_sales_cache (
    category, territory, order_year
);

-- Ši komanda leidžia peržiūrėti sukurtą indeksą.
-- Pastaba: uždarius ryšį, laikinoji lentelė (kartu su indeksu) išsitrina,
-- todėl indeksas nebebus rodomas.
-- SHOW INDEX FROM temp_sales_cache;

-- ===================================================================
-- Analizės pradžia (dabar skaitoma iš Cache / Podėlio)
-- ===================================================================

-- [1.1] Susiek produktus su jų subkategorijomis, kategorijomis, teritorijomis
-- ir pardavimo kanalais.
--
-- Skaitome tiesiai iš RAM (temp_sales_cache), tai veikia labai greitai.
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
FROM temp_sales_cache;

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
FROM temp_sales_cache
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
    FROM temp_sales_cache
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
    FROM temp_sales_cache
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
    FROM temp_sales_cache
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
-- Atkreipkite dėmesį, koks švarus dabar CTE. Tiesiog agreguojame laikinosios
-- lentelės duomenis.
WITH base_revenue AS (
    SELECT
        category,
        territory,
        sales_channel,
        order_year,
        order_quarter,
        SUM(line_revenue) AS revenue
    FROM temp_sales_cache
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

-- Išvalymas: MySQL automatiškai ištrina temp lenteles uždarius ryšį,
-- tačiau gera praktika yra ištrinti jas rankiniu būdu.
DROP TEMPORARY TABLE IF EXISTS temp_sales_cache;
