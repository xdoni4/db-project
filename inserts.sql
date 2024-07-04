INSERT INTO cars_db.client
            VALUES  (0,  'John John'),
                    (1,  'Andrew Andrew'),
                    (2,  'Robert Robert');

INSERT INTO cars_db.car
            VALUES  (0, 0),
                    (1, 0),
                    (2, 1),
                    (3, 2),
                    (4, 2);

INSERT INTO cars_db.supplier
            VALUES  (0, 'BBS', 'Germany'),
                    (1, 'HKS', 'Japan'),
                    (2, 'Skunk2', 'USA'),
                    (3, 'Russian Tuners', 'Russia'),
                    (4, 'Amazon Rice Burning', 'USA');

INSERT INTO cars_db.car_part
            VALUES  (0,  'Engine', 'Stock', 1000, 0, 0),
                    (1,  'Suspension', 'Stock', 1500, 1, 0),
                    (2,  'Transmission', 'Stock', 2500, 1, 0),
                    (3,  'Brakes', 'Stock', 800, 1, 0),
                    (4,  'Wheels', 'Stock', 500, 2, 0),
                    (5,  'Exhaust', 'Stock', 500, 2, 0),
                    (6,  'Body', 'Stock', 2500, 2, 0),
                    (7,  'Engine upgrade', 'Intercooler', 1000, 0, 0),
                    (8,  'Suspension upgrade', 'Kit_0', 1000, 0, 0),
                    (9,  'Brakes Upgrade', 'Kit_0', 1000, 2, 0),
                    (10, 'Engine', 'V6', 6000, 1, 0),
                    (11, 'Engine upgrade', 'Turbo', 2500, 0, 0);

INSERT INTO cars_db.car_part_x_car
            VALUES  (0, 0),
                    (1, 0),
                    (2, 0),
                    (3, 0),
                    (4, 0),
                    (5, 0),
                    (6, 0);

INSERT INTO cars_db.upgrade
            VALUES  (0, 'Engine', 'Intercooler', 7),
                    (1, 'Suspension', 'Kit_0', 8),
                    (2, 'Brakes', 'Kit_0', 9),
                    (4, 'Engine', 'Turbo', 11);

INSERT INTO cars_db.car_part_x_upgrade
            VALUES (1, 1),
                   (3, 2),
                   (10, 4);

INSERT INTO cars_db.purchase
            VALUES  (0, 10, 6000),
                    (1, 7, 1000),
                    (2, 8, 1000),
                    (3, 9, 1000);

UPDATE cars_db.car_part
SET part_in_stock = part_in_stock + 1
WHERE part_id in (SELECT purch_part_id FROM cars_db.purchase);

INSERT INTO cars_db.service
            VALUES  (0, 'Install', 10, 7000),
                    (1, 'Install', 7, 1500),
                    (2, 'Install', 8, 2500),
                    (3, 'Install', 9, 1200);

DELETE FROM cars_db.car_part_x_car
WHERE car_id = 0 AND part_id = 0;

INSERT INTO cars_db.car_part_x_car
            VALUES  (10, 0),
                    (7, 0),
                    (8, 0),
                    (9, 0);

UPDATE cars_db.car_part
SET part_in_stock = part_in_stock - 1
WHERE part_id in (SELECT service_part_id FROM cars_db.service);

INSERT INTO cars_db.service VALUES  (5, 'Repair', 1, 200),
                                    (6, 'Repair', 5, 400),
                                    (7, 'Repair', 9, 300);
