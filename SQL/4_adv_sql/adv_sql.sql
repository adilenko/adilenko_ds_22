
-- create 5 tables


create table language (
	language_name varchar(50) PRIMARY key,
	description varchar(250) default 'some description'
)

create table nation (
	nation_name varchar(50) PRIMARY key,
	description varchar(250) default 'some description'
	)

create table country (
	country_name varchar(50) PRIMARY key,
	description varchar(250) default 'some description'
)

CREATE TABLE population (
id serial PRIMARY KEY,
country_name varchar(50),
nation_name varchar(50),
foreign key (country_name) references country(country_name),
foreign key (nation_name) references nation(nation_name)
)


CREATE TABLE nation_language (
id serial PRIMARY KEY,
nation_name varchar(50) REFERENCES nation(nation_name),
language_name varchar(50) REFERENCES "language"(language_name)
)

INSERT INTO language (language_name)
select unnest(array['lang1', 'lang2', 'lang3', 'lang4', 'lang5'])
  
INSERT INTO nation (nation_name)
select unnest(array['nation1', 'nation2', 'nation3', 'nation4', 'nation5'])
  
INSERT INTO country (country_name)
select unnest(array['country1', 'country2', 'country3', 'country4', 'country5'])
  
INSERT INTO population (country_name, nation_name)
select unnest(array['country1', 'country2', 'country3', 'country1', 'country2']),
	   unnest(array['nation1', 'nation2', 'nation3', 'nation4', 'nation5'])

INSERT INTO nation_language (nation_name, language_name)
select unnest(array['nation1', 'nation2', 'nation3', 'nation1', 'nation2']),
	   unnest(array['lang1', 'lang2', 'lang3', 'lang4', 'lang5'])
	   


--foregin key  in CREATE TABLE and ALTER TABLE 	   
create table currency (
	currency_name varchar(50) PRIMARY key,
	description varchar(250) default 'some description'
)

CREATE TABLE country_currency (
continent varchar(50) PRIMARY KEY,
nation_name varchar(50) REFERENCES nation(nation_name),
currency_name varchar(3)
)

alter table country_currency add constraint currency_fkey foreign key (currency_name) references currency(currency_name) 


---scale table using: timestamp, boolean è text[]	fields   
alter table population add column "data" timestamp

alter table population add column officila_language boolean

alter table population add column history text

update population
set "data"='2021-01-01' , officila_language = true , history = '{"text1","text2","text3"}'::text[]


