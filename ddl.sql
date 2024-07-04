CREATE SCHEMA IF NOT EXISTS cars_db;

CREATE TABLE IF NOT EXISTS cars_db.client(
    client_id           INTEGER         PRIMARY KEY,
    client_nm           VARCHAR(255)    NOT NULL
);

CREATE TABLE IF NOT EXISTS cars_db.car(
    car_id              INTEGER         PRIMARY KEY,
    car_owner_id        INTEGER         REFERENCES cars_db.client(client_id)
);

CREATE TABLE IF NOT EXISTS cars_db.supplier(
    supplier_id         INTEGER         PRIMARY KEY,
    supplier_nm         VARCHAR(255)    NOT NULL,
    supplier_country    VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS cars_db.car_part(
    part_id             INTEGER         PRIMARY KEY,
    part_tp             VARCHAR(255)    NOT NULL,
    part_nm             VARCHAR(255)    NOT NULL,
    part_price          INTEGER         NOT NULL CHECK (part_price >= 0),
    part_supplier_id    INTEGER         REFERENCES cars_db.supplier(supplier_id),
    part_in_stock       INTEGER         NOT NULL
);

CREATE TABLE IF NOT EXISTS cars_db.car_part_x_car(
    part_id             INTEGER         REFERENCES cars_db.car_part(part_id),
    car_id              INTEGER         REFERENCES cars_db.car(car_id),
    PRIMARY KEY (part_id, car_id)
);

CREATE TABLE IF NOT EXISTS cars_db.purchase(
    purch_id             INTEGER        PRIMARY KEY,
    purch_part_id        INTEGER        REFERENCES cars_db.car_part(part_id),
    purch_price          INTEGER        NOT NULL CHECK (purch_price >= 0)
);

CREATE TABLE IF NOT EXISTS cars_db.service(
    service_id           INTEGER        PRIMARY KEY,
    service_tp           VARCHAR(255)   NOT NULL,
    service_part_id      INTEGER        REFERENCES cars_db.car_part(part_id),
    service_price        INTEGER        NOT NULL CHECK (service_price >= 0)
);

CREATE TABLE IF NOT EXISTS cars_db.upgrade(
    upgrade_id           INTEGER        PRIMARY KEY,
    upgrade_tp           VARCHAR(255)   NOT NULL,
    upgrade_nm           VARCHAR(255)   NOT NULL,
    part_id              INTEGER        REFERENCES cars_db.car_part(part_id)
);

CREATE TABLE IF NOT EXISTS cars_db.car_part_x_upgrade(
    part_id             INTEGER         REFERENCES cars_db.car_part(part_id),
    upgrade_id          INTEGER         REFERENCES cars_db.upgrade(upgrade_id),
    PRIMARY KEY (part_id, upgrade_id)
);
