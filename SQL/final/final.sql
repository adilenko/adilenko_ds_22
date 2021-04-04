--1. В каких городах больше одного аэропорта?
--группирую по городам, беру город с числом аэропортоа больше 1
select a.city 
from airports a 
group by a.city 
having count(a.airport_name) >1


--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- много вылетов из одного аэропорта, по-этому distinct
select distinct f.departure_airport 
from flights f 
join aircrafts a on f.aircraft_code  = a.aircraft_code
--берём вылеты на которых летают самолёты с максимальной дальностью
where a."range" = (select max(a2."range") from aircrafts a2) 


--3. Вывести 10 рейсов с максимальным временем задержки вылета
select f.flight_no
from flights f 
--убираю рейсы для которых нет данных в столбцах actual_departur и scheduled_departure
where f.actual_departure is not null and f.scheduled_departure is not null 
-- сортирую на основании разницы между реальнвм временем вылета и запланированным 
order by  (f.actual_departure - f.scheduled_departure) desc 
limit 10


--4. Были ли брони, по которым не были получены посадочные талоны?
select 
--если есть билеты без посадочного билета то возвращаю Да иначе Нет
case 
  when  count(t2.book_ref) > 0 then 'Да'
  else 'Нет'
end  is_bookings_without_bording
from tickets t2 
-- в результате left join получаю что для билетов без посадочного билета  мы получим null  значения для правой таблицы
left join boarding_passes bp on t2.ticket_no = bp.ticket_no 
--выбераю билеты без bording pass 
where bp.boarding_no is null 

--5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день.
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
-- round((total_seats - used_seats)::numeric/total_seats * 100,2) - % отношение занятых мест к общему количеству мест
select f.flight_id, f.flight_no,  f.departure_airport, f.scheduled_departure,
used.used_seats, total.total_seats, round((total_seats - used_seats)::numeric/total_seats * 100,2) free_to_used,
-- накапливаю сумму улетевших пасажжиров. группирую по departure_airport, scheduled_departure::date  чтою для каждого аэропорта и дня
-- был новый счетчик. сортирую по  scheduled_departure::timestamp чтоб накапливать сумму от рейса к  рейсу в течении дня
sum(used_seats) over (partition by departure_airport, scheduled_departure::date order by scheduled_departure)
from flights f 
-- джойню с результатом запроса возвращающего количество занятых мест на рейсе
join (select flight_id, max(boarding_no) used_seats  from boarding_passes  group by flight_id) used using(flight_id)
-- джойню с результатом запроса возвращающего общее количество мест на  самолёте обслуживающего данный рейс
join (select aircraft_code, count(seat_no) total_seats from seats group by aircraft_code) total using(aircraft_code)


--6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- round(flight_num::numeric / (select count(f.flight_id) from flights f) * 100, 2) - 
--select count(f.flight_id) from flights f - общее количество перелётов
--соотношение перелетов по типам самолетов от общего количества
select aircraft_code, round(flight_num::numeric / (select count(f.flight_id) from flights f) * 100, 2) aircraft_flight_to_total
-- возвращаю кол-во перелётов для каждого типа самолёта
from (select f2.aircraft_code, count(flight_id) flight_num
from flights f2 
group by f2.aircraft_code) aircraft_flights



--7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

with cte_min_eco as (
--возвращает минимальную стоймость перелёта в эконом классе для перелёта 
select flight_id , min(amount) as min_amount_econom, f2.arrival_airport   
from flights f2 
join ticket_flights tf using(flight_id)
where tf.fare_conditions = 'Economy'
group by f2.flight_id, f2.arrival_airport  
),
--возвращает минимальную стоймость перелёта в бизнес классе для рейса
cte_min_bus as (
select flight_id, min(amount) as min_amount_business
from flights f2 
join ticket_flights tf using(flight_id)
where tf.fare_conditions = 'Business'
group by f2.flight_id 
)
select a2.city 
-- объеденяю сте возвращающие минимальную стоймость перелёта для бизнес и эконом класса для рейса
from  cte_min_eco cme
join cte_min_bus cmb using(flight_id)
-- джойн для получения имени города по коду аэропорта
join airports a2 on cme.arrival_airport =a2.airport_code 
-- вернуть  строки для которыых минимальная стоймость в эконом класе для рейса больше минимальной стоймости  перелёта в бизнес классе
where cme.min_amount_econom > cmb.min_amount_business



--8. Между какими городами нет прямых рейсов?
--возвращает все возможнвые варианты перелёта
create view all_cities as 
	select a1.city departure, a2.city arrival
	from (select distinct city from airports) a1, (select distinct city from airports) a2
	where a1.city <> a2.city

-- возвращает города соотетствующие аэропорту вылета и прилёта
create view aeroport_city as
 select f.flight_id , a.city departure, a2.city arrival
 from flights f
 join airports a on a.airport_code = f.departure_airport 
 join airports a2 on a2.airport_code =f.arrival_airport  
 
--из всех возможных вариантов перелёта вычитаю  существующие перелёты	
with cte_cities as (
select departure, arrival
 from all_cities
 except
 select distinct departure, arrival
 from  aeroport_city
 )
-- убираю зеркальные данные
 select a1.departure, a1.arrival
 from cte_cities a1 
 where a1.departure > (select a2.departure
 from cte_cities a2
 where a1.departure = a2.arrival and a1.arrival = a2.departure)     
--что-то у меня с этим запросом не получилось
--select c1.departure, c2.arrival
--from cte_cities c1, cte_cities c2
--where c1.departure < c2.departure


--9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
--сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *

-- cte возвращает список городов связанных прямым рейсом
with cte_cities as (
select distinct f.flight_no, a.city as departure_city, a2.city as arrival_city, f.aircraft_code ,
a.latitude as departure_lat, a.longitude as departure_long, a2.latitude  as arrival_lat, a2.longitude as arrival_long
from flights f
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport )
--вычисляю расстояние между аэропортами 
select c1.departure_city, c1.arrival_city, a."range" as aircraft_distance, 
round(acos(sind(c1.departure_lat)*sind(c1.arrival_lat) + cosd(c1.departure_lat)*cosd(c1.arrival_lat)*cosd(c1.departure_long - c1.arrival_long))*6371)  as distance
from cte_cities c1
join aircrafts a using(aircraft_code)
