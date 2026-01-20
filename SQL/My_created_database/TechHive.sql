CREATE DATABASE IF NOT EXISTS techhive_db;

USE techhive_db;

CREATE TABLE customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    phone VARCHAR(40) NOT NULL
    );

CREATE TABLE customer_addresses (
	address_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    address_name VARCHAR(50) NULL,
    street VARCHAR(80) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    address_type VARCHAR(20) NOT NULL DEFAULT 'shipping'
    );
    

CREATE TABLE products (
	product_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INT NOT NULL , 
	brand_id INT NOT NULL,
    supplier_id INT,
    price DECIMAL (10,2) NOT NULL,
    cost DECIMAL (10,2) NOT NULL
    );
    

CREATE TABLE categories (
	category_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL
    );
    
    
CREATE TABLE brands (
	brand_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    brand_name VARCHAR(50) NOT NULL UNIQUE
    );
    

CREATE TABLE product_specifications (
	spec_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    product_id INT NOT NULL,
    spec_name VARCHAR(80) NOT NULL,
    spec_value VARCHAR(80) NOT NULL,
    spec_value_num DECIMAL(10,2)
    );

    
CREATE TABLE orders (
	order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL
    );
    
CREATE TABLE order_items (
	order_item_id INT PRIMARY KEY AUTO_INCREMENT, 
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL
    );
    
CREATE TABLE payments (
	payment_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(100)
    );
    
CREATE TABLE inventory (
	inventory_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL, 
    quantity_available INT NOT NULL,
    last_sale_date DATETIME NULL,
    reorder_point INT NOT NULL DEFAULT 0
    );
    
CREATE TABLE warehouse (
	warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_name VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL
    );
    
CREATE TABLE suppliers (
	supplier_id INT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    city VARCHAR(50) NOT NULL,
	country VARCHAR(50) NOT NULL
    );

CREATE TABLE returns (
	return_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    refunded_amount DECIMAL(10,2) NOT NULL
    );
    
    -------------------------------------------------------- FOREIGN KEYS ------------------------------------------------------

 -- 1. PRODUCTS (Jungiama su categories, brands, suppliers)
 
 -- a) Produktai -> Kategorijos
ALTER TABLE products
ADD CONSTRAINT fk_products_category
FOREIGN KEY (category_id)
REFERENCES categories(category_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;
    
    -- b) Produktai -> Prekės Ženklai (Brands)
ALTER TABLE products
ADD CONSTRAINT fk_products_brand
FOREIGN KEY (brand_id)
REFERENCES brands(brand_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;

-- c) Produktai -> Tiekėjai (Suppliers)
ALTER TABLE products
ADD CONSTRAINT fk_products_supplier
FOREIGN KEY (supplier_id)
REFERENCES suppliers(supplier_id)
ON UPDATE CASCADE
ON DELETE SET NULL;



-- 2. CUSTOMER ADDRESSES (Jungiama su customers) 

ALTER TABLE customer_addresses
ADD CONSTRAINT fk_addresses_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id)
ON UPDATE CASCADE
ON DELETE CASCADE;


-- 3. ORDERS (Jungiama su customers)

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;



-- 4. ORDER ITEMS (Jungiama su orders, products)

-- a) Užsakymo Eilutės -> Užsakymai
ALTER TABLE order_items
ADD CONSTRAINT fk_items_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id)
ON UPDATE CASCADE
ON DELETE CASCADE;

-- b) Užsakymo Eilutės -> Produktai
ALTER TABLE order_items
ADD CONSTRAINT fk_items_product
FOREIGN KEY (product_id)
REFERENCES products(product_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;



-- 5. PAYMENTS (Jungiama su orders)

ALTER TABLE payments
ADD CONSTRAINT fk_payments_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id)
ON UPDATE CASCADE
ON DELETE CASCADE;



-- 6. INVENTORY (Jungiama su products, warehouse)

-- a) Atsargos -> Produktai
ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id)
REFERENCES products(product_id)
ON UPDATE CASCADE
ON DELETE CASCADE;

-- b) Atsargos -> Sandėliai
ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_warehouse
FOREIGN KEY (warehouse_id)
REFERENCES warehouse(warehouse_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;



-- 7. PRODUCT SPECIFICATIONS (Jungiama su products)

ALTER TABLE product_specifications
ADD CONSTRAINT fk_specs_product
FOREIGN KEY (product_id)
REFERENCES products(product_id)
ON UPDATE CASCADE
ON DELETE CASCADE;



-- 8. RETURNS (Jungiama su orders, products)

-- a) Grąžinimai -> Užsakymai
ALTER TABLE returns
ADD CONSTRAINT fk_returns_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- b) Grąžinimai -> Produktai
ALTER TABLE returns
ADD CONSTRAINT fk_returns_product
FOREIGN KEY (product_id)
REFERENCES products(product_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;


INSERT INTO categories (category_name) VALUES
('TV');

INSERT INTO suppliers (name, email, phone, city, country) VALUES
('TechTrade UAB', 'info@techtrade.lt', '+37060010001', 'Vilnius', 'Lietuva');
 

INSERT INTO warehouse (warehouse_name, city, country) VALUES
('Rygos Sandėlis', 'Ryga', 'Latvija'),
('Talino Sandėlis', 'Talinas', 'Estija');




DELIMITER //

CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE inventory 
    SET quantity_available = quantity_available - NEW.quantity
    WHERE product_id = NEW.product_id;
END //

DELIMITER ;



ALTER TABLE products
ADD CONSTRAINT chk_price_positive CHECK (price > 0 AND cost > 0);

ALTER TABLE inventory
ADD CONSTRAINT chk_stock_not_negative CHECK (quantity_available >= 0);


ALTER TABLE returns 
CHANGE created_at returned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE orders ADD COLUMN delivery_date DATETIME;

ALTER TABLE products ADD COLUMN image_url VARCHAR(255);


ALTER TABLE brands ADD COLUMN logo_url VARCHAR(255);


ALTER TABLE categories ADD COLUMN icon_url VARCHAR(255);



UPDATE products SET image_url = 'https://images.unsplash.com/photo-1517336714460-4c5049c072e9' WHERE product_id = 1; 
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf' WHERE product_id = 2;
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf' WHERE product_id = 3; 
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1546868871-7041f2a55e12' WHERE product_id = 4; 
UPDATE products SET image_url = 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf' WHERE product_id = 5; 


UPDATE brands SET logo_url = 'https://logo.clearbit.com/lenovo.com' WHERE brand_id = 1;
UPDATE brands SET logo_url = 'https://logo.clearbit.com/samsung.com' WHERE brand_id = 2;
UPDATE brands SET logo_url = 'https://logo.clearbit.com/asus.com' WHERE brand_id = 3;
UPDATE brands SET logo_url = 'https://logo.clearbit.com/apple.com' WHERE brand_id = 4;



----------------------------------- JOIN --------------------------

-- parodyti kuriuos produktus uzsisako vienu metu daugiau negu 1

SELECT 
	p.product_id,
    p.product_name, 
    o.quantity
FROM products p
JOIN order_items o ON p.product_id = o.product_id
WHERE quantity > 1;


-- Raskite visų užsakymų sąrašą, pateikiant kliento vardą ir pavardę, užsakymo ID ir bendrą sumą.

SELECT 
	o.order_id,
    c.first_name,
    c.last_name,
    o.total_amount
FROM orders o
JOIN customers c USING(customer_id)
ORDER BY total_amount desc;



-- surasti pelningiausius klientus

SELECT
	c.customer_id,
	c.first_name,
    c.last_name,
    sum(o.total_amount) total_sum
FROM orders o
JOIN customers c USING(customer_id)
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_sum desc;

-- Raskite produkto pavadinimą ir visas jo specifikacijas.

SELECT 
	p.product_name,
    ps.spec_name,
    ps.spec_value,
    ps.spec_value_num
FROM products p
JOIN product_specifications ps ON p.product_id = ps.product_id;
	
    
------------------------------------ LEFT JOIN ---------------------

-- Raskite visus klientus ir jų užsakymų ID. Įtraukite ir tuos klientus, kurie niekada nepadarė užsakymo.

SELECT 
	c.customer_id,
	c.first_name,
    c.last_name,
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;


-- Raskite visus produktus ir jų turimą kiekį sandėlyje. Įtraukite ir tuos produktus, 
-- kurie neturi jokio įrašo inventory lentelėje.
    
SELECT 
	p.product_id,
    p.product_name,
    i.quantity_available
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
ORDER BY quantity_available desc;


------------------------ RIGHT JOIN ------------------

-- Raskite visus tiekėjus ir tuos produktus, kuriuos jie tiekia.
-- Įtraukite tiekėjus, kurie galbūt dar netiekia jokių produktų.

SELECT
	s.supplier_id,
    s.name AS supplier_name,
    p.product_name
FROM
    products p
RIGHT JOIN
    suppliers s ON p.supplier_id = s.supplier_id;



------------------------------ UNION ------------



SELECT 
    name AS Kontaktas, 
    email AS El_Paštas, 
    'Tiekėjas' AS Rolė
FROM 
    suppliers

UNION ALL


SELECT 
    CONCAT_WS(' ',first_name, last_name) AS Kontaktas, 
    email AS El_Paštas, 
    'Klientas' AS Rolė
FROM 
    customers;


