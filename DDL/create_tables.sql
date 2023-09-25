-- Создаем таблицу products
CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    price DOUBLE PRECISION NOT NULL
);

-- Создаем таблицу shops
CREATE TABLE IF NOT EXISTS shops (
    shop_id BIGINT PRIMARY KEY,
    shop_name VARCHAR(255) NOT NULL
);

-- Создаем таблицу sales
CREATE TABLE IF NOT EXISTS sales (
    product_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    date_sales DATE NOT NULL,
    sales_cnt BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES shops (shop_id) ON DELETE CASCADE,
    PRIMARY KEY (date_sales, shop_id, product_id)
);

-- Создаем таблицу plan
CREATE TABLE IF NOT EXISTS plan (
    product_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    plan_date DATE CHECK 
        (EXTRACT(DAY FROM plan_date) = EXTRACT(DAY FROM 
                                            DATE_TRUNC('MONTH', plan_date + INTERVAL '1 MONTH') - INTERVAL '1 DAY')),
    plan_cnt BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES shops (shop_id) ON DELETE CASCADE,
    PRIMARY KEY (plan_date, shop_id, product_id)
);

-- Создаем таблицу promo
CREATE TABLE IF NOT EXISTS promo (
    product_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    promo_date DATE NOT NULL,
    discount DOUBLE PRECISION NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES shops (shop_id) ON DELETE CASCADE,
    PRIMARY KEY (promo_date, shop_id, product_id)
);

