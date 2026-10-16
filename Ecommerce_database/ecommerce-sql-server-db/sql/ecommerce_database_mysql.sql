-- =====================================================================
-- E-Commerce Database System  |  MySQL 8.0
-- Exactly 8 tables: Customers, Categories, Products, Orders,
--                   OrderDetails, Payments, Shipments, Reviews
-- =====================================================================

DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE ecommerce_db;

-- =====================================================================
-- 1. CREATE TABLES (in dependency order)
-- =====================================================================

-- 1. Customers
CREATE TABLE Customers (
    customer_id    INT           NOT NULL AUTO_INCREMENT,
    first_name     VARCHAR(50)   NOT NULL,
    last_name      VARCHAR(50)   NOT NULL,
    email          VARCHAR(100)  NOT NULL,
    phone          VARCHAR(20)   NULL,
    password_hash  VARCHAR(255)  NOT NULL,
    address        VARCHAR(255)  NULL,
    city           VARCHAR(100)  NULL,
    country        VARCHAR(100)  NULL,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email)
) ENGINE=InnoDB;

-- 2. Categories
CREATE TABLE Categories (
    category_id    INT           NOT NULL AUTO_INCREMENT,
    category_name  VARCHAR(100)  NOT NULL,
    description    TEXT          NULL,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_name UNIQUE (category_name)
) ENGINE=InnoDB;

-- 3. Products
CREATE TABLE Products (
    product_id      INT            NOT NULL AUTO_INCREMENT,
    category_id     INT            NOT NULL,
    product_name    VARCHAR(150)   NOT NULL,
    description     TEXT           NULL,
    price           DECIMAL(10,2)  NOT NULL,
    stock_quantity  INT            NOT NULL DEFAULT 0,
    sku             VARCHAR(50)    NOT NULL,
    is_active       BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES Categories (category_id),
    CONSTRAINT chk_products_price CHECK (price >= 0),
    CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0)
) ENGINE=InnoDB;

-- 4. Orders
CREATE TABLE Orders (
    order_id          INT            NOT NULL AUTO_INCREMENT,
    customer_id       INT            NOT NULL,
    order_date        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status            ENUM('pending','confirmed','processing','shipped','delivered','cancelled')
                                     NOT NULL DEFAULT 'pending',
    shipping_address  VARCHAR(255)   NOT NULL,
    shipping_city     VARCHAR(100)   NOT NULL,
    shipping_country  VARCHAR(100)   NOT NULL,
    total_amount      DECIMAL(12,2)  NOT NULL DEFAULT 0,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES Customers (customer_id),
    CONSTRAINT chk_orders_total CHECK (total_amount >= 0)
) ENGINE=InnoDB;

-- 5. OrderDetails
CREATE TABLE OrderDetails (
    order_detail_id  INT            NOT NULL AUTO_INCREMENT,
    order_id         INT            NOT NULL,
    product_id       INT            NOT NULL,
    quantity         INT            NOT NULL,
    unit_price       DECIMAL(10,2)  NOT NULL,
    subtotal         DECIMAL(12,2)  NOT NULL,
    CONSTRAINT pk_orderdetails PRIMARY KEY (order_detail_id),
    CONSTRAINT uq_orderdetails_order_product UNIQUE (order_id, product_id),
    CONSTRAINT fk_orderdetails_order FOREIGN KEY (order_id)
        REFERENCES Orders (order_id),
    CONSTRAINT fk_orderdetails_product FOREIGN KEY (product_id)
        REFERENCES Products (product_id),
    CONSTRAINT chk_orderdetails_quantity CHECK (quantity > 0),
    CONSTRAINT chk_orderdetails_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_orderdetails_subtotal CHECK (subtotal >= 0)
) ENGINE=InnoDB;

-- 6. Payments
CREATE TABLE Payments (
    payment_id            INT            NOT NULL AUTO_INCREMENT,
    order_id              INT            NOT NULL,
    payment_date          DATETIME       NULL,
    amount                DECIMAL(12,2)  NOT NULL,
    payment_method        ENUM('cash_on_delivery','credit_card','debit_card','digital_wallet')
                                         NOT NULL,
    payment_status        ENUM('pending','paid','failed','refunded')
                                         NOT NULL DEFAULT 'pending',
    transaction_reference VARCHAR(100)   NULL,
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT uq_payments_txn UNIQUE (transaction_reference),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES Orders (order_id),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

-- 7. Shipments
CREATE TABLE Shipments (
    shipment_id              INT           NOT NULL AUTO_INCREMENT,
    order_id                 INT           NOT NULL,
    tracking_number          VARCHAR(100)  NULL,
    shipping_company         VARCHAR(100)  NULL,
    shipped_date             DATETIME      NULL,
    estimated_delivery_date  DATE          NULL,
    actual_delivery_date     DATETIME      NULL,
    shipment_status          ENUM('preparing','shipped','in_transit','delivered','returned')
                                           NOT NULL DEFAULT 'preparing',
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),
    CONSTRAINT uq_shipments_order UNIQUE (order_id),
    CONSTRAINT uq_shipments_tracking UNIQUE (tracking_number),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES Orders (order_id)
) ENGINE=InnoDB;

-- 8. Reviews
CREATE TABLE Reviews (
    review_id    INT        NOT NULL AUTO_INCREMENT,
    customer_id  INT        NOT NULL,
    product_id   INT        NOT NULL,
    rating       TINYINT    NOT NULL,
    comment      TEXT       NULL,
    review_date  DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT uq_reviews_customer_product UNIQUE (customer_id, product_id),
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
        REFERENCES Customers (customer_id),
    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id)
        REFERENCES Products (product_id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- =====================================================================
-- 2. INDEXES (foreign keys + frequently searched columns)
-- =====================================================================
CREATE INDEX idx_customers_last_name     ON Customers (last_name, first_name);
CREATE INDEX idx_customers_country_city  ON Customers (country, city);
CREATE INDEX idx_products_category       ON Products (category_id);
CREATE INDEX idx_products_name           ON Products (product_name);
CREATE INDEX idx_products_price          ON Products (price);
CREATE INDEX idx_products_active         ON Products (is_active);
CREATE INDEX idx_orders_customer         ON Orders (customer_id);
CREATE INDEX idx_orders_date             ON Orders (order_date);
CREATE INDEX idx_orders_status           ON Orders (status);
CREATE INDEX idx_orderdetails_product    ON OrderDetails (product_id);
CREATE INDEX idx_payments_order          ON Payments (order_id);
CREATE INDEX idx_payments_status         ON Payments (payment_status);
CREATE INDEX idx_shipments_status        ON Shipments (shipment_status);
CREATE INDEX idx_reviews_product         ON Reviews (product_id);
CREATE INDEX idx_reviews_rating          ON Reviews (rating);


-- =====================================================================
-- 4. SAMPLE DATA  (inserted in dependency order)
-- =====================================================================

-- ---- Customers (10) ----
INSERT INTO Customers (first_name, last_name, email, phone, password_hash, address, city, country, created_at) VALUES
('Ahmed',   'Hassan',   'ahmed.hassan@example.com',   '+20 100 123 4567', '$2b$12$KIXQ1m3vZ9hE7oQe1wYbLuT8pJcF2nRkVx5Ds0aGq4Wz6Hn7YyB3e', '12 Tahrir Street',        'Cairo',      'Egypt',                '2026-01-10 09:00:00'),
('Sara',    'Mahmoud',  'sara.mahmoud@example.com',   '+20 101 234 5678', '$2b$12$Wq8Zc1Lr5TnYx0Pd3Hv7UeJm9KsA2bFgNo6Rt4Iy1Ew8Xz5Qa7Cu', '45 Corniche Road',        'Alexandria', 'Egypt',                '2026-01-15 11:20:00'),
('Omar',    'Khaled',   'omar.khaled@example.com',    '+20 102 345 6789', '$2b$12$Hn3Vb7Xc1Zq9Lk5Pd0Tr8UeYm2JsA4wFgNo6Iy1Ew3Qa5Cu7Rt9s', '7 Nile Avenue',           'Giza',       'Egypt',                '2026-02-02 14:05:00'),
('Mona',    'Ibrahim',  'mona.ibrahim@example.com',   '+20 106 456 7890', '$2b$12$Rt5Yc9Hn1Vb3Xz7Lq0Pd4UeKm8JsA2wFgNo6Iy1Ew9Qa3Cu5Tr7s', '23 Al-Mansoura Street',  'Mansoura',   'Egypt',                '2026-02-20 16:45:00'),
('Fahad',   'Al-Otaibi','fahad.otaibi@example.com',   '+966 50 123 4567', '$2b$12$Lk9Pd3Tr7UeYm1JsA5wFgNo2Iy6Ew8Qa4Cu0Rt3Hn7Vb1Xc5Zq9s', '88 King Fahd Road',       'Riyadh',     'Saudi Arabia',         '2026-03-05 08:30:00'),
('Layla',   'Nasser',   'layla.nasser@example.com',   '+971 50 765 4321', '$2b$12$Zq1Xc5Vb9Hn3Rt7Tr0Pd4UeKm8JsA2wFgNo6Iy1Ew5Qa9Cu3Lk7s', '5 Sheikh Zayed Road',    'Dubai',      'United Arab Emirates', '2026-03-18 19:10:00'),
('Karim',   'Haddad',   'karim.haddad@example.com',   NULL,               '$2b$12$Ew7Qa1Cu5Rt9Hn3Vb7Xc0Zq4UeYm8JsA2wFgNo6Iy1Lk5Pd9Tr3s', '19 Hamra Street',        'Beirut',     'Lebanon',              '2026-04-01 12:00:00'),
('Rania',   'Saleh',    'rania.saleh@example.com',    '+962 79 123 4567', '$2b$12$Iy3Lk7Pd1Tr5UeKm9JsA2wFgNo6Ew8Qa4Cu0Rt3Hn7Vb1Xc5Zq9s', '31 Rainbow Street',      'Amman',      'Jordan',               '2026-04-22 10:40:00'),
('Emily',   'Carter',   'emily.carter@example.com',   '+44 7700 900123',  '$2b$12$Xc9Zq3Vb7Hn1Rt5Tr0Pd4UeYm8JsA2wFgNo6Iy1Ew5Qa9Cu3Lk7s', '102 Victoria Street',   'London',     'United Kingdom',       '2026-05-09 15:25:00'),
('Youssef', 'Farouk',   'youssef.farouk@example.com', '+20 109 876 5432', '$2b$12$Pd5Tr9UeKm3JsA7wFgNo1Iy6Ew2Qa8Cu4Rt0Hn3Vb7Xc1Zq5Lk9s', '60 Zamalek Street',      'Cairo',      'Egypt',                '2026-06-14 13:50:00');

-- ---- Categories (10) ----
INSERT INTO Categories (category_name, description) VALUES
('Electronics',            'Audio, video and general consumer electronics'),
('Computers & Laptops',    'Laptops, desktops and computer accessories'),
('Mobile Phones',          'Smartphones and mobile devices'),
('Home Appliances',        'Kitchen and household appliances'),
('Fashion',                'Clothing, shoes and accessories'),
('Books',                  'Printed and educational books'),
('Sports & Outdoors',      'Fitness equipment and outdoor gear'),
('Beauty & Personal Care', 'Skin care, hair care and personal hygiene'),
('Toys & Games',           'Toys, puzzles and board games'),
('Groceries',              'Packaged food and pantry staples');

-- ---- Products (13) ----
INSERT INTO Products (category_id, product_name, description, price, stock_quantity, sku, is_active) VALUES
(3,  'Samsung Galaxy S24 128GB',        '6.2-inch AMOLED smartphone, 50MP camera',            899.99,  40, 'PH-SAM-S24',   TRUE),
(3,  'Apple iPhone 15 128GB',           '6.1-inch Super Retina display, A16 Bionic chip',      799.00,  35, 'PH-APL-IP15',  TRUE),
(2,  'Dell Inspiron 15 Laptop',         '15.6-inch FHD, Intel Core i5, 16GB RAM, 512GB SSD',   649.50,  20, 'CP-DEL-INS15', TRUE),
(2,  'Logitech MX Master 3S Mouse',     'Wireless ergonomic mouse with silent clicks',          99.99, 120, 'CP-LOG-MX3S',  TRUE),
(1,  'Sony WH-1000XM5 Headphones',      'Wireless noise-cancelling over-ear headphones',       349.99,  55, 'EL-SON-XM5',   TRUE),
(4,  'Philips Air Fryer XL',            '6.2L digital air fryer, 2000W',                       129.90,  60, 'HA-PHI-AFXL',  TRUE),
(5,  'Men''s Cotton T-Shirt',           '100% cotton crew-neck t-shirt',                        19.99, 300, 'FA-MEN-TSH',   TRUE),
(6,  'Clean Code by Robert C. Martin',  'A handbook of agile software craftsmanship',           38.50,  80, 'BK-CLEANCODE', TRUE),
(7,  'Yoga Mat 6mm',                    'Non-slip eco-friendly yoga mat',                       24.95, 150, 'SP-YOGA-6MM',  TRUE),
(8,  'Vitamin C Serum 30ml',            'Brightening face serum with 15% Vitamin C',            17.49, 200, 'BT-VITC-30',   TRUE),
(9,  'LEGO Classic Brick Box',          '790-piece creative building set',                      44.99,  70, 'TY-LEGO-CLS',  TRUE),
(10, 'Extra Virgin Olive Oil 1L',       'Cold-pressed olive oil, 1 litre bottle',               12.75, 250, 'GR-OLIVE-1L',  TRUE),
(3,  'Samsung Galaxy S21 128GB',        'Previous generation smartphone (discontinued)',       549.00,   0, 'PH-SAM-S21',   FALSE);

-- ---- Orders (13) : total_amount is filled after the order items are inserted ----

INSERT INTO Orders (customer_id, order_date, status, shipping_address, shipping_city, shipping_country, total_amount) VALUES

(1, '2026-08-03 10:15:00', 'delivered', '12 Tahrir Street', 'Cairo', 'Egypt', 0),
(2, '2026-08-07 14:40:00', 'delivered', '45 Corniche Road', 'Alexandria', 'Egypt', 0),
(3, '2026-08-12 09:05:00', 'delivered', '7 Nile Avenue', 'Giza', 'Egypt', 0),
(4, '2026-09-02 18:22:00', 'shipped', '23 Al-Mansoura Street', 'Mansoura', 'Egypt', 0),
(5, '2026-09-05 11:30:00', 'delivered', '88 King Fahd Road', 'Riyadh', 'Saudi Arabia', 0),
(6, '2026-09-20 16:48:00', 'processing', '5 Sheikh Zayed Road', 'Dubai', 'United Arab Emirates', 0),
(7, '2026-09-28 20:10:00', 'confirmed', '19 Hamra Street', 'Beirut', 'Lebanon', 0),
(8, '2026-10-02 08:55:00', 'pending', '31 Rainbow Street', 'Amman', 'Jordan', 0),
(9, '2026-08-20 13:12:00', 'delivered', '102 Victoria Street', 'London', 'United Kingdom', 0),
(10, '2026-10-05 12:00:00', 'shipped', '60 Zamalek Street', 'Cairo', 'Egypt', 0),
(1, '2026-09-10 17:35:00', 'delivered', '12 Tahrir Street', 'Cairo', 'Egypt', 0),
(2, '2026-10-08 10:20:00', 'cancelled', '45 Corniche Road', 'Alexandria', 'Egypt', 0),
(3, '2026-10-12 19:45:00', 'pending', '7 Nile Avenue', 'Giza', 'Egypt', 0);


-- ---- OrderDetails (23) : unit_price keeps the product price at order time ----

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price, subtotal) VALUES

(1, 1, 1, 899.99, 899.99),
(1, 4, 1, 99.99, 99.99),
(2, 3, 1, 649.50, 649.50),
(2, 4, 2, 99.99, 199.98),
(3, 7, 3, 19.99, 59.97),
(3, 9, 1, 24.95, 24.95),
(4, 5, 1, 349.99, 349.99),
(5, 8, 2, 38.50, 77.00),
(5, 10, 2, 17.49, 34.98),
(6, 6, 1, 129.90, 129.90),
(6, 12, 4, 12.75, 51.00),
(7, 2, 1, 799.00, 799.00),
(8, 11, 2, 44.99, 89.98),
(8, 7, 2, 19.99, 39.98),
(9, 10, 3, 17.49, 52.47),
(9, 9, 2, 24.95, 49.90),
(9, 12, 2, 12.75, 25.50),
(10, 3, 1, 649.50, 649.50),
(10, 5, 1, 349.99, 349.99),
(11, 8, 1, 38.50, 38.50),
(11, 11, 1, 44.99, 44.99),
(12, 1, 1, 899.99, 899.99),
(13, 6, 2, 129.90, 259.80);


-- ---- Keep Orders.total_amount = SUM(OrderDetails.subtotal) ----
UPDATE Orders o
SET o.total_amount = (SELECT COALESCE(SUM(od.subtotal), 0) FROM OrderDetails od WHERE od.order_id = o.order_id);


-- ---- Payments (14) : order 5 has a failed attempt followed by a successful retry ----

INSERT INTO Payments (order_id, payment_date, amount, payment_method, payment_status, transaction_reference) VALUES

(1, '2026-08-03 10:17:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 1), 'credit_card', 'paid', 'TXN-20260803-0001'),
(2, '2026-08-07 14:42:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 2), 'digital_wallet', 'paid', 'TXN-20260807-0002'),
(3, '2026-08-14 12:30:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 3), 'cash_on_delivery', 'paid', NULL),
(4, '2026-09-02 18:24:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 4), 'credit_card', 'paid', 'TXN-20260902-0004'),
(5, '2026-09-05 11:31:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 5), 'credit_card', 'failed', 'TXN-20260905-0005A'),
(5, '2026-09-05 11:38:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 5), 'debit_card', 'paid', 'TXN-20260905-0005B'),
(6, '2026-09-20 16:50:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 6), 'digital_wallet', 'paid', 'TXN-20260920-0006'),
(7, '2026-09-28 20:12:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 7), 'credit_card', 'paid', 'TXN-20260928-0007'),
(8, NULL, (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 8), 'cash_on_delivery', 'pending', NULL),
(9, '2026-08-20 13:14:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 9), 'debit_card', 'paid', 'TXN-20260820-0009'),
(10, '2026-10-05 12:02:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 10), 'credit_card', 'paid', 'TXN-20261005-0010'),
(11, '2026-09-10 17:36:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 11), 'digital_wallet', 'paid', 'TXN-20260910-0011'),
(12, '2026-10-08 10:22:00', (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 12), 'credit_card', 'refunded', 'TXN-20261008-0012'),
(13, NULL, (SELECT total_amount FROM (SELECT order_id, total_amount FROM Orders) t WHERE t.order_id = 13), 'cash_on_delivery', 'pending', NULL);


-- ---- Shipments (10) : at most one shipment per order ----

INSERT INTO Shipments (order_id, tracking_number, shipping_company, shipped_date, estimated_delivery_date, actual_delivery_date, shipment_status) VALUES

(1, 'AWB-EG-100001', 'Aramex', '2026-08-04 09:00:00', '2026-08-08', '2026-08-07 15:20:00', 'delivered'),
(2, 'AWB-EG-100002', 'Bosta', '2026-08-08 10:30:00', '2026-08-12', '2026-08-11 13:05:00', 'delivered'),
(3, 'AWB-EG-100003', 'Egypt Post', '2026-08-13 08:45:00', '2026-08-17', '2026-08-14 12:30:00', 'delivered'),
(4, 'AWB-EG-100004', 'Aramex', '2026-09-03 11:00:00', '2026-09-07', NULL, 'shipped'),
(5, 'AWB-SA-200005', 'DHL Express', '2026-09-06 09:30:00', '2026-09-12', '2026-09-11 16:10:00', 'delivered'),
(6, NULL, NULL, NULL, '2026-09-27', NULL, 'preparing'),
(7, NULL, NULL, NULL, '2026-10-05', NULL, 'preparing'),
(9, 'AWB-UK-300009', 'DHL Express', '2026-08-21 10:00:00', '2026-08-28', '2026-08-27 11:45:00', 'delivered'),
(10, 'AWB-EG-100010', 'Bosta', '2026-10-06 09:15:00', '2026-10-10', NULL, 'in_transit'),
(11, 'AWB-EG-100011', 'Aramex', '2026-09-11 10:00:00', '2026-09-15', '2026-09-14 14:00:00', 'delivered');


-- ---- Reviews (13) : one review per customer per product ----

INSERT INTO Reviews (customer_id, product_id, rating, comment, review_date) VALUES

(1, 1, 5, 'Excellent phone, the camera is outstanding.', '2026-08-10 18:00:00'),
(1, 4, 4, 'Very comfortable mouse, battery lasts for weeks.', '2026-08-10 18:10:00'),
(2, 3, 4, 'Fast laptop for the price, fan is a little noisy.', '2026-08-15 20:30:00'),
(2, 4, 5, 'Best mouse I have ever owned.', '2026-08-15 20:35:00'),
(3, 7, 3, 'Good quality but runs slightly small.', '2026-08-18 09:00:00'),
(3, 9, 5, 'Great grip and very comfortable.', '2026-08-18 09:05:00'),
(5, 8, 5, 'A must-read for every developer.', '2026-09-14 21:00:00'),
(5, 10, 4, 'Nice serum, noticeable results after two weeks.', '2026-09-14 21:10:00'),
(9, 10, 5, 'Absolutely love it, will order again.', '2026-08-30 12:00:00'),
(9, 9, 4, 'Solid yoga mat, a bit thin for hard floors.', '2026-08-30 12:05:00'),
(9, 12, 5, 'Excellent flavour and fresh.', '2026-08-30 12:10:00'),
(1, 8, 5, 'Changed the way I write code.', '2026-09-18 19:00:00'),
(1, 11, 4, 'My kids loved it.', '2026-09-18 19:05:00');


-- =====================================================================
-- 5. VIEWS
-- =====================================================================

-- View 1: product catalog with category names
CREATE OR REPLACE VIEW v_product_catalog AS
SELECT p.product_id, p.sku, p.product_name, c.category_name,
       p.price, p.stock_quantity, p.is_active
FROM Products p
JOIN Categories c ON c.category_id = p.category_id;

-- View 2: order summary with customer information
CREATE OR REPLACE VIEW v_order_summary AS
SELECT o.order_id, o.order_date, o.status,
       CONCAT(cu.first_name, ' ', cu.last_name) AS customer_name,
       cu.email, o.shipping_city, o.shipping_country,
       COUNT(od.order_detail_id)  AS distinct_items,
       COALESCE(SUM(od.quantity), 0) AS total_units,
       o.total_amount
FROM Orders o
JOIN Customers cu ON cu.customer_id = o.customer_id
LEFT JOIN OrderDetails od ON od.order_id = o.order_id
GROUP BY o.order_id, o.order_date, o.status, cu.first_name, cu.last_name,
         cu.email, o.shipping_city, o.shipping_country, o.total_amount;

-- View 3: product sales statistics (cancelled orders excluded)
-- Sales and reviews are aggregated separately to avoid row multiplication.
CREATE OR REPLACE VIEW v_product_sales_stats AS
SELECT p.product_id, p.product_name, c.category_name,
       COALESCE(s.units_sold, 0) AS units_sold,
       COALESCE(s.revenue, 0)    AS revenue,
       COALESCE(rv.reviews_count, 0) AS reviews_count,
       rv.avg_rating
FROM Products p
JOIN Categories c ON c.category_id = p.category_id
LEFT JOIN (
    SELECT od.product_id, SUM(od.quantity) AS units_sold, SUM(od.subtotal) AS revenue
    FROM OrderDetails od
    JOIN Orders o ON o.order_id = od.order_id AND o.status <> 'cancelled'
    GROUP BY od.product_id
) s ON s.product_id = p.product_id
LEFT JOIN (
    SELECT product_id, COUNT(*) AS reviews_count, ROUND(AVG(rating), 2) AS avg_rating
    FROM Reviews
    GROUP BY product_id
) rv ON rv.product_id = p.product_id;

-- View 4: order fulfilment status (payment + shipment)
CREATE OR REPLACE VIEW v_order_fulfilment AS
SELECT o.order_id, o.status AS order_status, o.total_amount,
       COALESCE(SUM(CASE WHEN pay.payment_status = 'paid' THEN pay.amount END), 0) AS paid_amount,
       s.shipment_status, s.tracking_number, s.shipping_company
FROM Orders o
LEFT JOIN Payments  pay ON pay.order_id = o.order_id
LEFT JOIN Shipments s   ON s.order_id   = o.order_id
GROUP BY o.order_id, o.status, o.total_amount,
         s.shipment_status, s.tracking_number, s.shipping_company;


-- =====================================================================
-- 6. SQL QUERIES (20)
-- =====================================================================

-- Q1. SELECT + WHERE + ORDER BY: active products over 100, most expensive first
SELECT product_id, product_name, price
FROM Products
WHERE is_active = TRUE AND price > 100
ORDER BY price DESC;

-- Q2. WHERE + LIKE: customers living in Egypt whose email contains 'a'
SELECT customer_id, first_name, last_name, email, city
FROM Customers
WHERE country = 'Egypt' AND email LIKE '%a%'
ORDER BY last_name;

-- Q3. Aggregate functions: product statistics overview
SELECT COUNT(*) AS total_products,
       MIN(price) AS cheapest, MAX(price) AS most_expensive,
       ROUND(AVG(price), 2) AS avg_price, SUM(stock_quantity) AS total_stock
FROM Products
WHERE is_active = TRUE;

-- Q4. GROUP BY: number of customers per country
SELECT country, COUNT(*) AS customers
FROM Customers
GROUP BY country
ORDER BY customers DESC, country;

-- Q5. GROUP BY + HAVING: countries with more than one customer
SELECT country, COUNT(*) AS customers
FROM Customers
GROUP BY country
HAVING COUNT(*) > 1;

-- Q6. INNER JOIN: products with their category names
SELECT p.product_name, c.category_name, p.price
FROM Products p
INNER JOIN Categories c ON c.category_id = p.category_id
ORDER BY c.category_name, p.product_name;

-- Q7. JOIN (3 tables): orders with customer name and items
SELECT o.order_id, CONCAT(cu.first_name, ' ', cu.last_name) AS customer,
       p.product_name, od.quantity, od.unit_price, od.subtotal
FROM Orders o
JOIN Customers cu    ON cu.customer_id = o.customer_id
JOIN OrderDetails od ON od.order_id = o.order_id
JOIN Products p      ON p.product_id = od.product_id
ORDER BY o.order_id, p.product_name;

-- Q8. LEFT JOIN: categories with product counts (including empty categories)
SELECT c.category_name, COUNT(p.product_id) AS products_count
FROM Categories c
LEFT JOIN Products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY products_count DESC, c.category_name;

-- Q9. LEFT JOIN + IS NULL: customers who have never placed an order
SELECT cu.customer_id, cu.first_name, cu.last_name
FROM Customers cu
LEFT JOIN Orders o ON o.customer_id = cu.customer_id
WHERE o.order_id IS NULL;

-- Q10. LEFT JOIN + IS NULL: products that were never ordered
SELECT p.product_id, p.product_name
FROM Products p
LEFT JOIN OrderDetails od ON od.product_id = p.product_id
WHERE od.order_detail_id IS NULL;

-- Q11. Subquery in WHERE: products priced above the average price
SELECT product_name, price
FROM Products
WHERE price > (SELECT AVG(price) FROM Products)
ORDER BY price DESC;

-- Q12. Subquery with IN: customers who ordered a Mobile Phones product
SELECT DISTINCT cu.customer_id, cu.first_name, cu.last_name
FROM Customers cu
WHERE cu.customer_id IN (
    SELECT o.customer_id
    FROM Orders o
    JOIN OrderDetails od ON od.order_id = o.order_id
    JOIN Products p      ON p.product_id = od.product_id
    JOIN Categories c    ON c.category_id = p.category_id
    WHERE c.category_name = 'Mobile Phones');

-- Q13. Correlated subquery: each customer's most recent order date
SELECT cu.customer_id, cu.first_name,
       (SELECT MAX(o.order_date) FROM Orders o WHERE o.customer_id = cu.customer_id) AS last_order_date
FROM Customers cu
ORDER BY last_order_date DESC;

-- Q14. GROUP BY + SUM: revenue per category (cancelled orders excluded)
SELECT c.category_name, SUM(od.subtotal) AS revenue
FROM OrderDetails od
JOIN Orders o     ON o.order_id = od.order_id AND o.status <> 'cancelled'
JOIN Products p   ON p.product_id = od.product_id
JOIN Categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;

-- Q15. GROUP BY + HAVING: customers who spent more than 1000 in total
SELECT cu.customer_id, CONCAT(cu.first_name, ' ', cu.last_name) AS customer,
       SUM(o.total_amount) AS total_spent
FROM Customers cu
JOIN Orders o ON o.customer_id = cu.customer_id
WHERE o.status <> 'cancelled'
GROUP BY cu.customer_id, cu.first_name, cu.last_name
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spent DESC;

-- Q16. Top 5 best-selling products by quantity
SELECT p.product_name, SUM(od.quantity) AS units_sold
FROM OrderDetails od
JOIN Products p ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC
LIMIT 5;

-- Q17. Average rating per product with review counts (HAVING at least 2 reviews)
SELECT p.product_name, COUNT(r.review_id) AS reviews, ROUND(AVG(r.rating), 2) AS avg_rating
FROM Products p
JOIN Reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(r.review_id) >= 2
ORDER BY avg_rating DESC;

-- Q18. Orders by status with totals
SELECT status, COUNT(*) AS orders_count, SUM(total_amount) AS total_value
FROM Orders
GROUP BY status
ORDER BY orders_count DESC;

-- Q19. Orders that have a failed payment followed by a successful one (retry)
SELECT o.order_id, COUNT(*) AS payment_attempts
FROM Orders o
JOIN Payments p ON p.order_id = o.order_id
GROUP BY o.order_id
HAVING COUNT(*) > 1 AND SUM(p.payment_status = 'paid') >= 1;

-- Q20. Data integrity check: orders whose total differs from the sum of their items
SELECT o.order_id, o.total_amount, SUM(od.subtotal) AS items_total
FROM Orders o
JOIN OrderDetails od ON od.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <> SUM(od.subtotal);

-- Q21. Late deliveries: delivered after the estimated date
SELECT s.order_id, s.shipping_company, s.estimated_delivery_date, s.actual_delivery_date
FROM Shipments s
WHERE s.shipment_status = 'delivered'
  AND DATE(s.actual_delivery_date) > s.estimated_delivery_date;

-- Q22. Query the views
SELECT * FROM v_product_catalog ORDER BY category_name, product_name;
SELECT * FROM v_order_summary ORDER BY order_date DESC;
SELECT * FROM v_product_sales_stats ORDER BY revenue DESC;
SELECT * FROM v_order_fulfilment ORDER BY order_id;


-- =====================================================================
-- 7. EXAMPLE INSERT / UPDATE / DELETE OPERATIONS
-- =====================================================================

-- INSERT: a new customer
INSERT INTO Customers (first_name, last_name, email, phone, password_hash, address, city, country)
VALUES ('Nour', 'Elsayed', 'nour.elsayed@example.com', '+20 111 222 3333',
        '$2b$12$Mn4Qa8Cu2Rt6Hn0Vb3Xc7Zq1UeYm5JsA9wFgNo6Iy1Ew2Lk8Pd4Tr7s',
        '14 Gamal Abdel Nasser St', 'Damanhour', 'Egypt');

-- INSERT: a complete order in one transaction (order + items + stock + total)
START TRANSACTION;

INSERT INTO Orders (customer_id, shipping_address, shipping_city, shipping_country)
VALUES (LAST_INSERT_ID(), '14 Gamal Abdel Nasser St', 'Damanhour', 'Egypt');
SET @new_order = LAST_INSERT_ID();

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price, subtotal)
SELECT @new_order, p.product_id, 2, p.price, 2 * p.price FROM Products p WHERE p.product_id = 9;

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price, subtotal)
SELECT @new_order, p.product_id, 1, p.price, p.price FROM Products p WHERE p.product_id = 8;

UPDATE Products SET stock_quantity = stock_quantity - 2 WHERE product_id = 9;
UPDATE Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 8;

UPDATE Orders
SET total_amount = (SELECT SUM(subtotal) FROM OrderDetails WHERE order_id = @new_order)
WHERE order_id = @new_order;

COMMIT;

-- INSERT: same product added again -> update the quantity instead of a duplicate row
INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price, subtotal)
SELECT @new_order, 9, 1, price, price FROM Products WHERE product_id = 9
ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity),
                        subtotal = (quantity) * unit_price;
UPDATE Orders
SET total_amount = (SELECT SUM(subtotal) FROM OrderDetails WHERE order_id = @new_order)
WHERE order_id = @new_order;

-- INSERT: payment and shipment for the new order
INSERT INTO Payments (order_id, payment_date, amount, payment_method, payment_status, transaction_reference)
SELECT @new_order, NOW(), total_amount, 'digital_wallet', 'paid', 'TXN-20261016-0014'
FROM Orders WHERE order_id = @new_order;

INSERT INTO Shipments (order_id, tracking_number, shipping_company, estimated_delivery_date, shipment_status)
VALUES (@new_order, 'AWB-EG-100014', 'Bosta', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'preparing');

-- UPDATE: change order status, price change (old orders keep their unit_price)
UPDATE Orders    SET status = 'confirmed' WHERE order_id = @new_order;
UPDATE Products  SET price = 849.99 WHERE product_id = 1;
UPDATE Shipments SET shipment_status = 'shipped', shipped_date = NOW() WHERE order_id = @new_order;

-- INSERT + DELETE: a test review that is then removed
INSERT INTO Reviews (customer_id, product_id, rating, comment)
VALUES (4, 5, 5, 'Test review to be deleted');
DELETE FROM Reviews WHERE customer_id = 4 AND product_id = 5;

-- DELETE: remove the cancelled order together with its dependents (child rows first)
DELETE FROM Payments     WHERE order_id = 12;
DELETE FROM OrderDetails WHERE order_id = 12;
DELETE FROM Orders       WHERE order_id = 12;
