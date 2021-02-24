--����������� ��� ������� � ��������� ����� � ���� ������

--	��������� ������� 	��������� ����
--	inventory       		inventory_id
--	film_actor			actor_id, film_id
--	actor					actor_id
--	film					film_id
--	language				languahe_id
--	film_category			film_id, category_id
--	rental					rental_id
--	staff					staff_id
--	customer				customer_id
--	category				category_id
--	city					city_id
--	payment					payment_id
--	store					store_id
--	address					address_id
--	country					country_id
--	author					id
--	orders					id


--������� ���� ���������� �����������
select concat(t.first_name, ' ',t.last_name) as customer  from public.customer as t
where t.active = 1

--������� ��� ������, ���������� � 2006 ����
select film.title, film.release_year from film
where film.release_year ='2006'

--������� 10 ��������� �������� �� ������ �������
select * from payment p 
order by p.payment_date desc 
limit 10

---������� ��������� ����� ����� ������. ��� ��������� �������� ������� ������ ��������������� information_schema.table_constraints
select distinct kcu.table_name, kcu.column_name
from information_schema.key_column_usage kcu
join information_schema.table_constraints tc on tc.constraint_name = kcu.constraint_name 
where lower(tc.constraint_type) = 'primary key'
order by kcu.table_name 

--��������� ������ � ���������� �������, ������� ���������� �� ���� ������ information_schema.columns
select distinct kcu.table_name, kcu.column_name, c.data_type 
from information_schema.key_column_usage kcu
join information_schema.table_constraints tc on tc.constraint_name = kcu.constraint_name 
join information_schema.columns c on kcu.column_name = c.column_name and kcu.table_name = c.table_name 
where lower(tc.constraint_type) = 'primary key'
order by kcu.table_name 
