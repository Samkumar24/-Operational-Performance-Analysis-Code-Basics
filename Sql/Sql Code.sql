use trips_db;
use targets_db;

select * from fact_trips;

##-----------------------------------------------------------------query 1

select city_name , count(*) as Total_trips , 
	round((sum(fare_amount)/sum(distance_travelled_km)),2) as avg_fare_per_km,
    round((sum(fare_amount)/count(city_name)),2) as avg_fare_per_trip,
    round((count(*) / sum(count(*)) over ()*100),2) as '%_contribution_total'
    from trips_db.fact_trips ft 
join trips_db.dim_city dc on ft.city_id = dc.city_id
group by city_name;

##------------------------------------------------------------------------query 2


with t1 as (
	select city_id , monthname(date) as Month_name ,count(*) as Actual_trips  from trips_db.fact_trips a 
    group by city_id , monthname(date)
    ),
t2 as ( select city_id ,monthname(month) as Month_name ,sum(total_target_trips) as Actual_target from targets_db.monthly_target_trips a
group by city_id , monthname(month))

select city_name , t1.Month_name , t1.Actual_trips , t2.Actual_target ,
	(case when t1.Actual_trips > t2.Actual_target then "Above target " else "Below target" end ) as Performance_status,
    round(((t1.Actual_trips -  t2.Actual_target)/( t2.Actual_target))*100,2) as '% Difference'
from t1 
join t2 on 
	t1.city_id = t2.city_id 
and 
	t1.Month_name = t2.Month_name
join 
trips_db.dim_city c
on
 t1.city_id = c.city_id;

###---------------------------------------------------------------------query 3


select  
    city_name, 
    round(sum(case when trip_count = '2-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 2_trip,
    round(sum(case when trip_count = '3-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 3_trip,
    round(sum(case when trip_count = '4-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 4_trip,
    round(sum(case when trip_count = '5-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 5_trip,
    round(sum(case when trip_count = '6-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 6_trip,
    round(sum(case when trip_count = '7-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 7_trip,
    round(sum(case when trip_count = '8-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 8_trip,
    round(sum(case when trip_count = '9-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 9_trip,
    round(sum(case when trip_count = '10-trips' then repeat_passenger_count else 0 end) / sum(repeat_passenger_count) * 100, 2) as 10_trip
from  
    trips_db.dim_repeat_trip_distribution a 
join  
    trips_db.dim_city b  
on  
    a.city_id = b.city_id
group by 
    city_name;	


##---------------------------------------------------------------query 4


with t1 as (
select city_name , sum(new_passengers) as new_passengers ,
rank() over ( order by sum(new_passengers) desc) as rank_df
 from trips_db.fact_passenger_summary a join 
trips_db.dim_city b on a.city_id = b.city_id
group by city_name),

t2 as (select city_name , new_passengers , 'Top' as 'Top/Bottom' , rank_df as Rank_ from t1 where rank_df < 4),
t3 as ( select city_name , new_passengers , 'Bottom' , rank() over (order by new_passengers asc ) as Rank_ from t1 
			where rank_df >=(select max(rank_df) - 2 from t1))
select * from t2
union 
select * from t3;

##---------------------------------------------query 5
with t1 as (
    select city_name,  month_name,  revenue 
    from (
        select city_name,  monthname(date) as month_name, sum(fare_amount) as revenue,
            row_number() over (partition by city_name order by sum(fare_amount) desc) as aa
        from trips_db.fact_trips tf 
        join trips_db.dim_city dc 
            on tf.city_id = dc.city_id
        group by city_name, month_name
    ) a1 
    where aa < 2
),

t2 as (
    select city_name,  sum(fare_amount) as total_amount 
    from trips_db.fact_trips a 
    join trips_db.dim_city b 
        on a.city_id = b.city_id
    group by city_name
)

select 
    t2.city_name, t1.month_name, t1.revenue as Highest_revenue ,
    (t1.revenue / t2.total_amount) * 100 as revenue_percentage
from t2 join t1 
    on t1.city_name = t2.city_name;

##-------------------------------------------------------------query 6

select city_name ,monthname(month) as Month , sum(total_passengers) as Total_passengers , 
sum(repeat_passengers) as Repeat_passengers , 
round(sum(repeat_passengers)/sum(total_passengers)*100,2) as Repeat_passengers_percent
 from trips_db.fact_passenger_summary a 
join 
trips_db.dim_city b on a.city_id = b.city_id
group by city_name , Month;

###__________________________________________________________________________________

