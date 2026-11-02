/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор:Топольскова О.Ф.
 * Дата: 24.09.2025
*/


-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats LEFT JOIN real_estate.type AS t USING (type_id)
    LEFT JOIN real_estate.advertisement AS a USING(id)
    WHERE
        a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-31'-- убираем неполные годы
        AND t.type='город' -- оставляем только тип н.п. город
        AND total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- Продолжите запрос здесь
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
category AS(
    SELECT fi.id,
    CASE WHEN c.city ='Санкт-Петербург' THEN 'Санкт-Петербург'  
        ELSE 'ЛенОбл'
    END AS region,
CASE 
	WHEN a.days_exposition < 31 THEN '1 месяц'
    WHEN a.days_exposition BETWEEN 31 AND 90 THEN '1-3 месяца'
    WHEN a.days_exposition BETWEEN 91 AND 180 THEN '3-6 месяцев'
    WHEN a.days_exposition >=181 THEN '6+ месяцев'
        ELSE 'non category'
    END AS activ_category,
a.last_price/f.total_area AS cost_of_area
FROM filtered_id AS fi LEFT JOIN real_estate.advertisement AS a USING(id)
LEFT JOIN real_estate.flats AS f USING(id)
LEFT JOIN real_estate.city AS c USING(city_id)
)
SELECT region,
activ_category,
count(id) AS count_adv,
round(count(id) * 100/ SUM(count(id)) OVER (PARTITION BY region), 0) AS share_adv,
AVG(cost_of_area)::int AS avg_price_sq_m,
AVG(total_area)::int AS avg_total_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY rooms) AS median_rooms,
round(AVG(ceiling_height)::numeric,1) AS avg_ceiling_height,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY floors_total) AS median_floors_total,
AVG(living_area)::int AS avg_living_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY floor) AS median_floor,
sum(is_apartment) AS count_apartment,
sum(open_plan) AS count_open_plan,
AVG(kitchen_area)::int AS avg_kitchen_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY balcony) AS median_balcony,
AVG(airports_nearest)::int AS avg_airports_nearest,
round(AVG(parks_around3000)::numeric,1) AS avg_count_parks,
round(AVG(ponds_around3000)::numeric,1) AS avg_count_ponds
FROM category AS c LEFT JOIN real_estate.flats AS f USING(id)
WHERE activ_category<>'non category'
GROUP BY region,
activ_category;


--сравнение показателей недвижимости Лен.области и Санкт-Петербурга без детализации по сегментам активности
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats LEFT JOIN real_estate.type AS t USING (type_id)
    LEFT JOIN real_estate.advertisement AS a USING(id)
    WHERE
        a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-31'-- убираем неполные годы
        AND t.type='город' -- оставляем только тип н.п. город
        AND total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
category AS(
    SELECT fi.id,
    CASE WHEN c.city ='Санкт-Петербург' THEN 'Санкт-Петербург'  
        ELSE 'ЛенОбл'
    END AS region,
a.last_price/f.total_area AS cost_of_area
FROM filtered_id AS fi LEFT JOIN real_estate.advertisement AS a USING(id)
LEFT JOIN real_estate.flats AS f USING(id)
LEFT JOIN real_estate.city AS c USING(city_id)
)
SELECT region AS регион,
count(id) AS count_adv,
AVG(cost_of_area)::int AS avg_price_sq_m,
AVG(total_area)::int AS avg_total_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY rooms) AS median_rooms,
round(AVG(ceiling_height)::numeric,1) AS avg_ceiling_height,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY floors_total) AS median_floors_total,
AVG(living_area)::int AS avg_living_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY floor) AS median_floor,
round(sum(is_apartment)*100/count(id)::numeric,1) AS share_apartment,
round(sum(open_plan)*100/count(id)::numeric,1) AS share_open_plan,
AVG(kitchen_area)::int AS avg_kitchen_area,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY balcony) AS median_balcony,
AVG(airports_nearest)::int AS avg_airports_nearest,
round(AVG(parks_around3000)::numeric,1) AS avg_count_parks,
round(AVG(ponds_around3000)::numeric,1) AS avg_count_ponds
FROM category AS c LEFT JOIN real_estate.flats AS f USING(id)
LEFT JOIN real_estate.advertisement AS a  USING(id) 
WHERE a.days_exposition IS NOT NULL 
GROUP BY region;

-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats LEFT JOIN real_estate.type AS t USING (type_id)
    LEFT JOIN real_estate.advertisement AS a USING(id)
    WHERE
        a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-31'-- убираем неполные годы
        AND t.type='город' -- оставляем только тип н.п. город
        AND total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
   id_month AS(
-- Продолжите запрос здесь
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных 
 SELECT f.id,
 EXTRACT (MONTH FROM a.first_day_exposition::timestamp) AS month_number,
    TO_CHAR(a.first_day_exposition, 'Month') AS month_start,
    TO_CHAR(a.first_day_exposition + INTERVAL '1 day' * a.days_exposition, 'Month') AS month_finish
FROM filtered_id AS f 
LEFT JOIN real_estate.advertisement AS a USING(id)
),
month_start AS(
SELECT month_number,
im.month_start,
count(im.id) AS count_adv,
ROUND(count(im.id)*100/sum(count(im.id)) OVER (),2) AS share_count_adv,
AVG(a.last_price/f.total_area)::int AS avg_price_sq_m_sale,
AVG(f.total_area)::int AS avg_total_area_sale
FROM id_month AS im LEFT JOIN real_estate.advertisement AS a USING(id)
LEFT JOIN real_estate.flats AS f USING(id)
GROUP BY im.month_start,month_number
),
month_finish AS (
SELECT im.month_finish,
count(im.id) AS count_sold,
ROUND(count(im.id)*100/sum(count(im.id)) OVER (),2) AS share_count_sold,
AVG(a.last_price/f.total_area)::int AS avg_price_sq_m_sold,
AVG(f.total_area)::int AS avg_total_area_sold
FROM id_month AS im LEFT JOIN real_estate.advertisement AS a USING(id)
LEFT JOIN real_estate.flats AS f USING(id)
WHERE ((a.first_day_exposition + INTERVAL '1 day' * a.days_exposition)::date) BETWEEN '2015-01-01' AND '2018-12-31'
GROUP BY im.month_finish
)
SELECT month_number,
month_start,
RANK()OVER(ORDER BY ms.share_count_adv DESC) AS rank_count_adv,
count_adv,
share_count_adv,
RANK()OVER(ORDER BY mf.share_count_sold DESC) AS rank_count_sold,
count_sold,
share_count_sold,
avg_price_sq_m_sale,
avg_price_sq_m_sold,
avg_total_area_sale,
avg_total_area_sold
FROM month_start AS ms FULL JOIN month_finish AS mf ON ms.month_start=mf.month_finish;
