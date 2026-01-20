
/*1. Klientų lojalumo analizė.  
Scenarijus: Įmonės rinkodaros komanda 2014 m. birželio 30 d.siekia įvertinti klientų 
lojalumą. Jūsų užduotis skirta įvertinti klientų elgseną laike. Reikia nustatyti, kurie klientai 
pirmą kartą užsakė 2013 metais ir kiek vidutiniškai išleido tais metais, ir ar jie užsakė dar 
kartą ir kiekvieno užsakymo sumą 2014 metais.  
Naudojamos lentelės: sales_salesorderheader, sales_customer, person_person.  
Naudojamos window function: DENSE_RANK().  
Laukiamas rezultatas: 
+-------+---------+----------+------------------------+-------------+----------------+--------+---------+ 
|  id   | vardas  | pavarde  | uzsakymo_vidurkis_2013 | uzsakymoID  | uzsakymo_data  |  suma  | ranking | 
+-------+---------+----------+------------------------+-------------+----------------+--------+---------+ 
| 11012 | Lauren  | Walker   | 82.85                  
| 11013 | Ian            
| Jenkins  | 43.07                        
| 11014 | Sydney  | Bennett  | 76.49                  
| 68413       
| 2014-03-16     |  6.94  |   1     | 
| 74908       
| 2014-06-22     | 82.85  |   1     | 
| NULL        | NULL               
| NULL   |   1     | 
+-------+---------+----------+------------------------+-------------+----------------+--------+---------+*/

WITH FirstOrders AS (
    SELECT
        c.CustomerID AS id,
        p.FirstName AS vardas,
        p.LastName AS pavarde,
        s.SalesOrderID,
        s.OrderDate,
        s.TotalDue,
        DENSE_RANK() OVER (
            PARTITION BY c.CustomerID
            ORDER BY s.OrderDate
        ) AS ranking
    FROM sales_customer c
    JOIN person_person p ON c.PersonID = p.BusinessEntityID
    JOIN sales_salesorderheader s ON c.CustomerID = s.CustomerID
),
FirstOrder2013 AS (
    SELECT
        id,
        vardas,
        pavarde,
        ROUND(AVG(TotalDue), 2) AS uzsakymo_vidurkis_2013,
        ranking
    FROM FirstOrders
    WHERE ranking = 1
      AND YEAR(OrderDate) = 2013
    GROUP BY id, vardas, pavarde, ranking
)
SELECT
    f.id,
    f.vardas,
    f.pavarde,
    f.uzsakymo_vidurkis_2013,
    s.SalesOrderID AS uzsakymoID,
    DATE(s.OrderDate) AS uzsakymo_data,
    ROUND(s.TotalDue,2) AS suma,
    f.ranking AS ranking
FROM FirstOrder2013 f
LEFT JOIN sales_salesorderheader s
    ON f.id = s.CustomerID
    AND YEAR(s.OrderDate) = 2014
ORDER BY f.id, s.OrderDate;




/*2. Produktų pardavimų analizė pagal prekių kategorijas ir regionus  
Užduotis: Parašykite užklausą, kuri apskaičiuoja bendrą produktų pardavimų sumą pagal prekių  
kategorijas ir rodo rezultatus pagal regionus. Užklausoje turi būti šie stulpeliai:  
• Prekės kategorija (iš ProductCategory)  
• Regionas (iš SalesTerritory)  
• Bendros pardavimų sumos  
Užuomina: Susijunkite SalesOrderDetail su Product ir ProductCategory, tada susijunkite  
SalesOrderHeader su SalesTerritory naudojant atitinkamus Foreign Keys. Filtruokite  
rezultatus pagal 2013 metų pardavimus.  
Tikėtinas rezultatas:  
• Prekės kategorija  
• Regionas  
• Bendros pardavimų sumos  
Tikėtini rezultatai: 
# kategorija, regionas, suma 
 */


SELECT 
    pc.name kategorija,
    st.name regionas, 
    ROUND(SUM(sod.linetotal),2) suma
FROM sales_salesorderdetail sod
JOIN production_product p ON sod.productid = p.productid
JOIN production_productsubcategory psc ON p.productsubcategoryid = psc.productsubcategoryid
JOIN production_productcategory pc ON psc.productcategoryid = pc.productcategoryid
JOIN sales_salesorderheader soh ON sod.salesorderid = soh.salesorderid
JOIN sales_salesterritory st ON soh.territoryid = st.territoryid
WHERE YEAR(soh.orderdate) = 2013
GROUP BY pc.name, st.name
ORDER BY st.name, suma desc;



/*3. Pardavimų departamento darbuotojų našumas  
Užduotis: Vadovybė nori įvertinti pardavimų darbuotojų efektyvumą pagal jų priskirtus 
departamentus. Naudojant duomenis iš lentelių SalesOrderHeader, Person, 
EmployeeDepartmentHistory ir Department, reikia apskaičiuoti bendrą kiekvieno darbuotojo 
pardavimų sumą, nustatyti, kuriam departamentui jis priklauso, ir palyginti darbuotojo 
rezultatus su to departamento vidurkiu. Skaičiavimui naudojama window function AVG(...) 
OVER (PARTITION BY DepartmentID), kuri leidžia gauti departamento vidutinę pardavimų sumą. 
Palyginimui reikia pridėti stulpelį, rodantį darbuotojo santykinį našumą procentais, ir tekstinį 
įvertinimą (ar darbuotojo rezultatas viršija, atitinka ar nesiekia vidurkio), naudojant CASE.  */


WITH EmployeeSales AS (
    SELECT
        soh.SalesPersonID id,
        p.FirstName vardas,
        p.LastName pavarde,
        hd.Name departamentas,
        dh.departmentid departmentid,
        SUM(soh.TotalDue) AS darbuotojo_pardavimai
    FROM sales_salesorderheader soh
    JOIN person_person p ON soh.SalesPersonID = p.BusinessEntityID
    JOIN humanresources_employeedepartmenthistory dh ON p.BusinessEntityID = dh.BusinessEntityID
    JOIN humanresources_department hd ON dh.DepartmentID = hd.DepartmentID
    GROUP BY soh.SalesPersonID, p.FirstName, p.LastName, hd.Name, hd.DepartmentID
),
departamento_avg AS (
	SELECT 
		id,
        vardas,
        pavarde,
        departamentas,
        darbuotojo_pardavimai,
		avg(darbuotojo_pardavimai) OVER ( PARTITION BY departmentid) departamento_pard_vidurkis,
        (darbuotojo_pardavimai/avg(darbuotojo_pardavimai) OVER ( 
										PARTITION BY departmentid)) * 100 santykis_nasumas_proc
	FROM employeesales
	)
SELECT
	id,
    vardas,
    pavarde,
    departamentas,
    ROUND(darbuotojo_pardavimai,2) darbuotojo_pardavimai,
	ROUND(departamento_pard_vidurkis,2) departamento_pard_vidurkis,
    ROUND(santykis_nasumas_proc,1) santykis_nasumas_proc,
    CASE
		WHEN darbuotojo_pardavimai > departamento_pard_vidurkis THEN 'Virsija'
        WHEN darbuotojo_pardavimai < departamento_pard_vidurkis THEN 'Nesiekia vidurkio'
        ELSE 'Atitinka'
	END AS ivertinimas
FROM departamento_avg
ORDER BY santykis_nasumas_proc desc;



/*4. Pardavimų analize pagal laikotarpį ir produktų grupes  
Užduotis: Parašykite užklausą, kuri apskaičiuoja bendrą pardavimų sumą per metus (2013)  
pagal produktų grupes ir pateikia šiuos duomenis:  
• Prekės grupė (iš ProductSubcategory)  
• Bendros pardavimų sumos  
• Pardavimų kiekis  
• Vidutinė pardavimo kaina  
Užuomina: Susijunkite SalesOrderDetail su Product ir ProductSubcategory. Filtruokite pagal  
2013 metų pardavimus ir apskaičiuokite bendrą pardavimų sumą, kiekį ir vidutinę pardavimo  
kainą (rikiuojant desc).. 
Tikėtinas rezultatas:  
# prekes_grupe, kiekis, pardavimu_suma, vidutine_pardavimo_kaina*/

SELECT
	ps.name,
	SUM(sod.orderqty) kiekis,
	ROUND(SUM(linetotal),2) pardavimu_suma,
	ROUND((SUM(linetotal) / SUM(sod.orderqty)),2) vidutine_pardavimo_kaina
FROM sales_salesorderdetail sod 
JOIN production_product p ON sod.productid = p.productid
JOIN production_productsubcategory ps ON p.productsubcategoryid = ps.productsubcategoryid
WHERE YEAR(sod.ModifiedDate) = 2013
GROUP BY ps.name
ORDER BY vidutine_pardavimo_kaina DESC;


/*5. Gamybos ir tiekimo grandinės efektyvumo analizė  
Užduotis: Parašykite užklausą, kuri apskaičiuoja prekių tiekimo laiką pagal gamintoją.  
Pateikite šiuos duomenis:  
• Tiekimo grandinės tiekėjo pavadinimas (iš Supplier)  
• Prekės pavadinimas (iš Product)  
• Laikas nuo užsakymo iki pristatymo (laiko skirtumas tarp OrderDate ir ShipDate)  
Užuomina: Susijunkite Product su ProductSupplier, o ProductSupplier su Supplier.  
Apskaičiuokite vidutinį tiekimo laiką pagal tiekėją. Išrūšiuokite pagal tiekėją ir produktą.*/


SELECT 
	pv.name tiekejas,
    p.name produktas,
    ROUND(AVG(DATEDIFF(poh.ShipDate, poh.OrderDate)), 0)  vid_pristatymo_laikas
FROM production_product p
JOIN purchasing_productvendor ppv ON p.productid = ppv.productid
JOIN purchasing_vendor pv ON ppv.businessentityid = pv.businessentityid
JOIN purchasing_purchaseorderheader poh ON pv.businessentityid = poh.vendorid
GROUP BY pv.name, p.name
ORDER BY tiekejas, produktas;



/*6. Pardavimų sezoniškumo analizė  
Užduotis: Parašykite užklausą, kuri apskaičiuoja mėnesio pardavimus 2013 metais,  
naudodamiesi SalesOrderHeader duomenimis. Užklausoje turi būti:  
• Mėnuo (iš OrderDate)  
• Bendros pardavimų sumos  
• Pardavimų kiekis  
Užuomina: Filtruokite pagal 2023 metus, naudokite MONTH() funkciją, kad išgautumėte  
mėnesio reikšmę ir MONTHNAME() mėnesio pavadinimui, ir apskaičiuokite bendrą pardavimų 
sumą bei kiekį kiekvienam mėnesiui. 
# menuo, menuo_pavadinimas, pardavimu_kiekis, pardavimu_suma 
'1', 'January', '407', '2354903.68'*/

SELECT
	MONTH(orderdate) menuo,
    MONTHNAME(orderdate) menuo_pavadinimas,
    COUNT(salesorderid) pardavimu_kiekis,
    ROUND(SUM(totaldue),2) pardavimu_suma
FROM sales_salesorderheader
WHERE YEAR(orderdate) = 2013 
GROUP BY MONTH(orderdate), MONTHNAME(orderdate)