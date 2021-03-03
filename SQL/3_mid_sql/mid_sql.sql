
--shop with more than 300 customers
select s.store_id, count(c.customer_id) customer_num
from store s 
left join customer c on s.store_id = c.store_id 
group by s.store_id
having  count(c.customer_id) > 300

-- city name  for each customer
select concat(c2.first_name, ' ', c2.last_name ) customer_name, c3.city 
from customer c2 
left join address a2 on c2.address_id = a2.address_id 
left join city c3 on a2.city_id = c3.city_id 
order by concat(c2.first_name, ' ', c2.last_name )

-- First and last name of a staff, city of a shop for shops with more than 300 customers 
select concat(s2.first_name, ' ', s2.last_name ), ct4.city 
from staff s2 
left join (
select s.store_id, s.address_id 
from store s 
left join customer c on s.store_id = c.store_id 
group by s.store_id
having  count(c.customer_id) > 300
) s4 on s2.store_id = s4.store_id
left join address a4 on s4.address_id = a4.address_id 
left join city ct4 on a4.city_id = ct4.city_id 
where s4.store_id is not null 

-- number of actors staring in films with rating rate = 2.99
select f3.title, count(fa.actor_id) as actors_count, f3.rental_rate
from film_actor fa 
join film f3 on fa.film_id = f3.film_id and f3.rental_rate = 2.99
group by fa.film_id, f3.title, f3.rental_rate  
order by f3.title