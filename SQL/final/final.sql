--1. � ����� ������� ������ ������ ���������?
--��������� �� �������, ���� ����� � ������ ���������� ������ 1
select a.city 
from airports a 
group by a.city 
having count(a.airport_name) >1


--2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- ����� ������� �� ������ ���������, ��-����� distinct
select distinct f.departure_airport 
from flights f 
join aircrafts a on f.aircraft_code  = a.aircraft_code
--���� ������ �� ������� ������ ������� � ������������ ����������
where a."range" = (select max(a2."range") from aircrafts a2) 


--3. ������� 10 ������ � ������������ �������� �������� ������
select f.flight_no
from flights f 
--������ ����� ��� ������� ��� ������ � �������� actual_departur � scheduled_departure
where f.actual_departure is not null and f.scheduled_departure is not null 
-- �������� �� ��������� ������� ����� �������� �������� ������ � ��������������� 
order by  (f.actual_departure - f.scheduled_departure) desc 
limit 10


--4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?
select 
--���� ���� ������ ��� ����������� ������ �� ��������� �� ����� ���
case 
  when  count(t2.book_ref) > 0 then '��'
  else '���'
end  is_bookings_without_bording
from tickets t2 
-- � ���������� left join ������� ��� ��� ������� ��� ����������� ������  �� ������� null  �������� ��� ������ �������
left join boarding_passes bp on t2.ticket_no = bp.ticket_no 
--������� ������ ��� bording pass 
where bp.boarding_no is null 

--5. ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����.
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
-- round((total_seats - used_seats)::numeric/total_seats * 100,2) - % ��������� ������� ���� � ������ ���������� ����
select f.flight_id, f.flight_no,  f.departure_airport, f.scheduled_departure,
used.used_seats, total.total_seats, round((total_seats - used_seats)::numeric/total_seats * 100,2) free_to_used,
-- ���������� ����� ��������� ����������. ��������� �� departure_airport, scheduled_departure::date  ���� ��� ������� ��������� � ���
-- ��� ����� �������. �������� ��  scheduled_departure::timestamp ���� ����������� ����� �� ����� �  ����� � ������� ���
sum(used_seats) over (partition by departure_airport, scheduled_departure::date order by scheduled_departure)
from flights f 
-- ������ � ����������� ������� ������������� ���������� ������� ���� �� �����
join (select flight_id, max(boarding_no) used_seats  from boarding_passes  group by flight_id) used using(flight_id)
-- ������ � ����������� ������� ������������� ����� ���������� ���� ��  ������� �������������� ������ ����
join (select aircraft_code, count(seat_no) total_seats from seats group by aircraft_code) total using(aircraft_code)


--6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
-- round(flight_num::numeric / (select count(f.flight_id) from flights f) * 100, 2) - 
--select count(f.flight_id) from flights f - ����� ���������� ��������
--����������� ��������� �� ����� ��������� �� ������ ����������
select aircraft_code, round(flight_num::numeric / (select count(f.flight_id) from flights f) * 100, 2) aircraft_flight_to_total
-- ��������� ���-�� �������� ��� ������� ���� �������
from (select f2.aircraft_code, count(flight_id) flight_num
from flights f2 
group by f2.aircraft_code) aircraft_flights



--7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

with cte_min_eco as (
--���������� ����������� ��������� ������� � ������ ������ ��� ������� 
select flight_id , min(amount) as min_amount_econom, f2.arrival_airport   
from flights f2 
join ticket_flights tf using(flight_id)
where tf.fare_conditions = 'Economy'
group by f2.flight_id, f2.arrival_airport  
),
--���������� ����������� ��������� ������� � ������ ������ ��� �����
cte_min_bus as (
select flight_id, min(amount) as min_amount_business
from flights f2 
join ticket_flights tf using(flight_id)
where tf.fare_conditions = 'Business'
group by f2.flight_id 
)
select a2.city 
-- ��������� ��� ������������ ����������� ��������� ������� ��� ������ � ������ ������ ��� �����
from  cte_min_eco cme
join cte_min_bus cmb using(flight_id)
-- ����� ��� ��������� ����� ������ �� ���� ���������
join airports a2 on cme.arrival_airport =a2.airport_code 
-- �������  ������ ��� �������� ����������� ��������� � ������ ����� ��� ����� ������ ����������� ���������  ������� � ������ ������
where cme.min_amount_econom > cmb.min_amount_business



--8. ����� ������ �������� ��� ������ ������?
--���������� ��� ���������� �������� �������
create view all_cities as 
	select a1.city departure, a2.city arrival
	from (select distinct city from airports) a1, (select distinct city from airports) a2
	where a1.city <> a2.city

-- ���������� ������ �������������� ��������� ������ � ������
create view aeroport_city as
 select f.flight_id , a.city departure, a2.city arrival
 from flights f
 join airports a on a.airport_code = f.departure_airport 
 join airports a2 on a2.airport_code =f.arrival_airport  
 
--�� ���� ��������� ��������� ������� �������  ������������ �������	
with cte_cities as (
select departure, arrival
 from all_cities
 except
 select distinct departure, arrival
 from  aeroport_city
 )
-- ������ ���������� ������
 select a1.departure, a1.arrival
 from cte_cities a1 
 where a1.departure > (select a2.departure
 from cte_cities a2
 where a1.departure = a2.arrival and a1.arrival = a2.departure)     
--���-�� � ���� � ���� �������� �� ����������
--select c1.departure, c2.arrival
--from cte_cities c1, cte_cities c2
--where c1.departure < c2.departure


--9. ��������� ���������� ����� �����������, ���������� ������� �������, 
--�������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *

-- cte ���������� ������ ������� ��������� ������ ������
with cte_cities as (
select distinct f.flight_no, a.city as departure_city, a2.city as arrival_city, f.aircraft_code ,
a.latitude as departure_lat, a.longitude as departure_long, a2.latitude  as arrival_lat, a2.longitude as arrival_long
from flights f
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport )
--�������� ���������� ����� ����������� 
select c1.departure_city, c1.arrival_city, a."range" as aircraft_distance, 
round(acos(sind(c1.departure_lat)*sind(c1.arrival_lat) + cosd(c1.departure_lat)*cosd(c1.arrival_lat)*cosd(c1.departure_long - c1.arrival_long))*6371)  as distance
from cte_cities c1
join aircrafts a using(aircraft_code)
