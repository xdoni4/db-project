--Индексы

--Создаем индексы в таблицах tablename_x_tablename,
--т.к они разрешают many-to-many отношения, то есть можно
--разделить строки на бакеты по какому-то столбцу, и т.о.
--ускорить работу запросов
CREATE INDEX cars_by_part ON cars_db.car_part_x_car(part_id);
CREATE INDEX parts_by_car ON cars_db.car_part_x_car(car_id);
CREATE INDEX upgrades_by_part ON cars_db.car_part_x_upgrade(part_id);
CREATE INDEX parts_by_upgrade ON cars_db.car_part_x_upgrade(upgrade_id);

--Создаем индекс автомобиля по владельцу, поскольку у владельца
--может быть несколько автомобилей
CREATE INDEX cars_by_owner ON cars_db.car(car_owner_id);

--Создаем индекс запчасти по типу, поскольку много запчастей
--одного типа
CREATE INDEX parts_by_type ON cars_db.car_part(part_tp);

--Создаем индекс улучшения по типу, поскольку много улучшений
--одного типа
CREATE INDEX upgrades_by_type ON cars_db.upgrade(upgrade_tp);

--Создаем индекс покупки по запчасти, поскольку можем купить одну запчасть несколько раз
CREATE INDEX purch_by_part ON cars_db.purchase(purch_part_id);

--Создаем индекс услуги по запчасти, поскольку можем "продать" одну запчасть несколько раз
CREATE INDEX service_by_part ON cars_db.service(service_part_id);

--Функции

--Функция для маскировки имени
CREATE FUNCTION mask_name(text) RETURNS text
   LANGUAGE SQL IMMUTABLE AS
$$SELECT
    overlay($1 placing repeat('*', length($1) - 1) from 2 for length($1) - 1 ) $$;

--Функция для пересчета курса валют
CREATE FUNCTION change_currency(real) RETURNS real AS $$
    DECLARE exchange_rate real := 75;
    BEGIN
        RETURN exchange_rate * $1;
    END;
$$ LANGUAGE plpgsql;

--Триггеры

--Триггер, сообщающий об обновлении таблицы
CREATE FUNCTION warn() RETURNS trigger AS $warn$
    BEGIN
        RAISE NOTICE 'An update will be performed for cars_db.car_part';
        RETURN NULL;
    END
$warn$ LANGUAGE plpgsql;

CREATE TRIGGER warning
BEFORE UPDATE on cars_db.car_part
FOR EACH STATEMENT
EXECUTE FUNCTION warn();

--Триггер, выводящий обновленные строки таблицы
CREATE FUNCTION log_update() RETURNS trigger AS $log_update$
    BEGIN
        RAISE NOTICE 'UPDATED VALUES';
        RAISE NOTICE 'part_price part_tp part_nm part_supplier_id part_in_stock';
        RAISE NOTICE '% % % % %', NEW.part_price, NEW.part_tp, NEW.part_nm,
            NEW.part_supplier_id, NEW.part_in_stock;
        RETURN NULL;
    END;
$log_update$ LANGUAGE plpgsql;

CREATE TRIGGER logging
AFTER UPDATE ON cars_db.car_part
FOR EACH ROW
WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION log_update();

--Представления
--1. Представление-конкатенация service и purchase
CREATE VIEW net_profit AS SELECT *, ROW_NUMBER() OVER (ORDER BY trans_id) AS id
FROM ((SELECT purch_id AS trans_id, -purch_price AS price FROM cars_db.purchase)
UNION ALL(SELECT service_id, service_price FROM cars_db.service)) AS biba;

--2. Представление client с максированным именем клиента
CREATE VIEW client_masked AS
SELECT client_id, concat(
    mask_name(split_part(client_nm, ' ', 1)),
    ' ',
    mask_name(split_part(client_nm, ' ', 2))) AS client_nm FROM cars_db.client;

--3. Представление car_part с названием производителя вместо id
CREATE VIEW car_part_w_supp_names AS
SELECT part_tp, part_nm, part_price, supplier_nm, part_in_stock
FROM cars_db.car_part LEFT JOIN cars_db.supplier
    ON car_part.part_supplier_id = cars_db.supplier.supplier_id;

--4. Представление с расширенной информацией для car_part_x_upgrade
CREATE VIEW part_x_upgrade_ext AS
SELECT car_part.part_id AS part_id, part_tp, part_nm, upgrade_nm, upgrade.part_id AS upgrade_part_id
FROM (cars_db.car_part_x_upgrade LEFT JOIN cars_db.car_part
ON cars_db.car_part_x_upgrade.part_id = cars_db.car_part.part_id)
                                 LEFT JOIN cars_db.upgrade
ON cars_db.car_part_x_upgrade.upgrade_id = cars_db.upgrade.upgrade_id;

--5. Представление с расширенной информацией для car_part_x_car
CREATE VIEW part_x_car_ext AS
SELECT car_id, cars_db.car_part_x_car.part_id AS part_id, part_tp,
       part_nm, part_price, part_supplier_id, part_in_stock FROM
cars_db.car_part_x_car LEFT JOIN cars_db.car_part
ON cars_db.car_part_x_car.part_id = cars_db.car_part.part_id;
SELECT * FROM part_x_car_ext;

--6. Представление с сокрытием технической информации из part_x_car_ext
CREATE VIEW part_x_car_names_only AS
SELECT car_id, part_tp, part_nm FROM part_x_car_ext;

--Осмысленные запросы

--1. Вывести среднюю стоимость по типу запчастей, где средняя стоимость >= 1000
--GROUP BY + HAVING
SELECT part_tp, AVG(part_price) AS avg_price
FROM cars_db.car_part
GROUP BY part_tp HAVING AVG(part_price) >= 1000;

--2. Вывести запчасти от производителя с supplier_id=0, отсортированные по стоимости
--ORDER BY
SELECT part_supplier_id, part_tp, part_id, part_price
FROM cars_db.car_part
WHERE part_supplier_id = 0
ORDER BY part_price DESC;

--3. Разделить все запчасти на 3 одинаковые по размеру группы "дорогой", "средний", "дешевый"
--Ранжирующая функция OVER(ORDER BY...)
SELECT a.part_id, part_tp, part_price,
        CASE
            WHEN price_tag1 = 3 THEN 'expensive'
            WHEN price_tag1 = 2 THEN 'moderate'
            WHEN price_tag1 = 1 THEN 'cheap'
        END AS price_tag
        FROM cars_db.car_part a INNER JOIN
        (SELECT part_id,
                NTILE(3) OVER
            (ORDER BY part_price) AS price_tag1
         FROM cars_db.car_part) b ON a.part_id = b.part_id
ORDER BY part_price, a.part_id;

--4. Посчитать, сколько всего было заказов каждого типа и записать соответствующее значение каждому заказу.
--Аггрегирующая функция OVER(PARTITION BY...)
SELECT *, COUNT(*) OVER
    (PARTITION BY service_tp)
FROM cars_db.service;

--5. Вывести текущую сумму прибыли
--Аггрегирующая функция OVER(ORDER BY...)
SELECT *, SUM(price) OVER
    (ORDER BY id) AS profit FROM net_profit;

--6. Вывести разницу между соседними запчастями одного типа, отсортированными в порядке возрастания
--Функция смещения OVER(PARTITION BY ... OVER BY ...)
SELECT part_id, part_tp, part_price, part_price-LAG(part_price, 1)
OVER(PARTITION BY part_tp ORDER BY part_price) AS delta
FROM cars_db.car_part ORDER BY (part_tp, part_price);
