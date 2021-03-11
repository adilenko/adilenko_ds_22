--Сделайте запрос к таблице rental. Используя оконую функцию добавьте колонку с порядковым номером аренды для 
--каждого пользователя (сортировать по rental_date)

--Для каждого пользователя подсчитайте сколько он брал в аренду фильмов со специальным атрибутом Behind the Scenes
---напишите этот запрос
---создайте материализованное представление с этим запросом
---обновите материализованное представление
---напишите три варианта условия для поиска Behind the Scenes

--Дополнительная часть:
---открыть по ссылке sql запрос [https://letsdocode.ru/sql-hw5.sql], сделать explain analyze запроса
---основываясь на описании запроса, найдите узкие места и опишите их
---сравните с Вашим запросом из основной части (если Ваш запрос изначально укладывается в 15мс - отлично!)
---оптимизируйте запрос, сократив время обработки до максимум 15мс
---сделайте построчное описание explain analyze на русском языке оптимизированного запроса.
--Описание строк в explain можно посмотреть тут - [https://use-the-index-luke.com/sql/explain-plan/postgresql/operations]



--Task 1
select *, row_number() over (partition by r.customer_id order by r.rental_date)
from rental r


--Task 2
create materialized view task1 as
select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, count(c.customer_id) films_number
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id and
	'Behind the Scenes' =any(f.special_features)
group by c.customer_id 
order by c.customer_id
with no data

refresh materialized view task1


select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, count(c.customer_id) films_number
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id and
	f.special_features @> array['Behind the Scenes']
group by c.customer_id 
order by c.customer_id


select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, count(c.customer_id) films_number
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id and
	f.special_features::text like '%Behind the Scenes%'
group by c.customer_id 
order by c.customer_id

--Additional tasks

--Query from https://letsdocode.ru/sql-hw5.sql
--Execution time ~ 45 ms
explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

Возможные узкие места
Использование distinct что приводит к дополнительной сортировки
Вложенные full join приводит к тому что мы работаем с большим количеством данных чем необходимо
Использование оконной функции приводит к вызову ресурсозатратной сортировки



--Execution time ~ 9.6 ms
explain analyze 
select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, count(c.customer_id) films_number
from customer c 
join rental r on c.customer_id = r.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id and
	'Behind the Scenes' =any(f.special_features)
group by c.customer_id 
order by count(c.customer_id) desc

--HashAggregate  (cost=694.64..702.13 rows=599 width=44) (actual time=8.799..8.946 rows=599 loops=1)
Вызов агригирующей функции cost=702  time = 8.9
--  Group Key: c.customer_id
Группируем по customer_id
--  ->  Hash Join  (cost=233.78..651.48 rows=8632 width=17) (actual time=1.245..7.715 rows=8608 loops=1)
--        Hash Cond: (r.customer_id = c.customer_id)
Объединяем хэши для таблиц  rental и  customer. cost=651 time=7.7
--        ->  Hash Join  (cost=211.30..606.19 rows=8632 width=2) (actual time=1.104..6.284 rows=8608 loops=1)
--              Hash Cond: (i.film_id = f.film_id)
Объединяем хэши для таблиц  inventory и  film cost=606 time=6.284
--              ->  Hash Join  (cost=128.07..480.67 rows=16044 width=4) (actual time=0.781..4.479 rows=16044 loops=1)
--                    Hash Cond: (r.inventory_id = i.inventory_id)
Объединяем хэши для таблиц rental и inventory cost= 480 time = 4.479
--                    ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.005..0.915 rows=16044 loops=1)
Сканируем таблицу rental
--                    ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=0.755..0.755 rows=4581 loops=1)
--                          Buckets: 8192  Batches: 1  Memory Usage: 234kB
Вычисляем хэш, использовано 234kB для размещения хэша таблицы cost=70.81 time 0.755
--                          ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.007..0.372 rows=4581 loops=1)
Сканируем таблицу inventory
--              ->  Hash  (cost=76.50..76.50 rows=538 width=4) (actual time=0.318..0.319 rows=538 loops=1)
--                    Buckets: 1024  Batches: 1  Memory Usage: 27kB
Вычисляем хэш, использовано 27kB для размещения хэша таблицы cost=76.5 time=0.319
--                    ->  Seq Scan on film f  (cost=0.00..76.50 rows=538 width=4) (actual time=0.006..0.273 rows=538 loops=1)
--                          Filter: ('Behind the Scenes'::text = ANY (special_features))
--                          Rows Removed by Filter: 462
Сканируем таблицу film с фильтрацией и удалением 462 строк
--        ->  Hash  (cost=14.99..14.99 rows=599 width=17) (actual time=0.134..0.134 rows=599 loops=1)
--              Buckets: 1024  Batches: 1  Memory Usage: 38kB
Вычисляем хэш, использовано 38kB для размещения хэша таблицы cost 14.99 time=0.134
--              ->  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=17) (actual time=0.008..0.064 rows=599 loops=1)
Сканируем таблицу customer. 
--Planning Time: 0.501 ms
--Execution Time: 9.037 ms

