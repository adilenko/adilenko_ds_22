
---выведите магазины, имеющие больше 300-от покупателей
select s.store_id, count(c.customer_id)
from store s 
left join customer c on s.store_id = c.store_id 
group by s.store_id
having  count(c.customer_id) > 300

---выведите у каждого покупател€ город в котором он живет
select concat(c2.first_name, ' ', c2.last_name ), c3.city 
from customer c2 
left join address a2 on c2.address_id = a2.address_id 
left join city c3 on a2.city_id = c3.city_id 
order by concat(c2.first_name, ' ', c2.last_name )

---выведите ‘»ќ сотрудников и города магазинов, имеющих больше 300-от покупателей
select concat(c4.first_name, ' ', c4.last_name ), ct4.city 
from customer c4 
left join (
select s.store_id, s.address_id 
from store s 
left join customer c on s.store_id = c.store_id 
group by s.store_id
having  count(c.customer_id) > 300
) s4 on c4.store_id = s4.store_id
left join address a4 on s4.address_id = a4.address_id 
left join city ct4 on a4.city_id = ct4.city_id 
where s4.store_id is not null 

---выведите количество актеров, снимавшихс€ в фильмах, которые сдаютс€ в аренду за 2,99
select f3.title, count(fa.actor_id) as actors_count, f3.rental_rate
from film_actor fa 
join film f3 on fa.film_id = f3.film_id and f3.rental_rate = 2.99
group by fa.film_id, f3.title, f3.rental_rate  
order by f3.title