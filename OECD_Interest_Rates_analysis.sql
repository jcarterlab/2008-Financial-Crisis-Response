-- limits the interest table to the 2008-2011 period
with financial_crisis_interest as (
	select * 
		from interestrates as i
		where int(left(i.time, 4)) >= 2008 and int(left(i.time, 4)) <= 2011
),

-- limits the money supply table to the 2008-2011 period
financial_crisis_money_supply as (
	select * 
		from moneysupply as m
		where int(left(m.time, 4)) >= 2008 and int(left(m.time, 4)) <= 2011
),

-- calculates average interest rates for each country from 2003-2007
previous_interest_rate as (
	select i.country,
		left(round(avg(i.value), 2), 4) as average_interest_2003_2007
		from interestrates as i
		where int(left(i.time, 4)) >= 2003 and int(left(i.time, 4)) <= 2007
		group by i.country
),

-- calculates average money supply index values for each country from 2003-2007
previous_money_supply as (
	select m.country,
		left(round(avg(m.value), 2), 4) as average_money_supply_2003_2007
		from moneysupply as m
		where int(left(m.time, 4)) >= 2003 and int(left(m.time, 4)) <= 2007
		group by m.country
),

-- calculates the deepest interest rate cut from the 2003-2007 average to any time between 2008 and 2011
interest_rate_cuts as (
	select pi.country,
		left(round(pi.average_interest_2003_2007 - min_interest_2008_2011, 2), 4) as deepest_interest_cut_2008_2011,
		pi.average_interest_2003_2007,
		min_interest_2008_2011
	from (
		select ci.country,
			left(round(min(ci.value), 2), 4) as min_interest_2008_2011
		from financial_crisis_interest as ci 
		group by ci.country
	) as min_ci
	join previous_interest_rate as pi on pi.country = min_ci.country 
	order by deepest_interest_cut_2008_2011 desc 
),

-- calculates the largest money supply hike from the 2003-2007 average to any time between 2008 and 2011
money_supply_hikes as (
	select pm.country,
		left(round(max_money_supply_2008_2011 - pm.average_money_supply_2003_2007, 2), 4) as largest_money_supply_hike_2008_2011,
		pm.average_money_supply_2003_2007,
		max_money_supply_2008_2011
	from (
		select cm.country,
			left(round(max(cm.value), 2), 4) as max_money_supply_2008_2011
		from financial_crisis_money_supply as cm
		group by cm.country
	) as min_cm
	join previous_money_supply as pm on pm.country = min_cm.country 
	order by largest_money_supply_hike_2008_2011 desc
),

-- returns ranks for deepest interest rate cuts, largest money supply hikes and a combination of the two
rank as (
	select i.country, 
		rank() over (order by i.deepest_interest_cut_2008_2011 desc) as interest_rate_cut_rank,
		rank() over (order by m.largest_money_supply_hike_2008_2011 desc) as money_supply_hike_rank,
		rank() over (order by i.deepest_interest_cut_2008_2011 desc) + rank() over (order by m.largest_money_supply_hike_2008_2011 desc) as combined_ranks
	from interest_rate_cuts as i
	join money_supply_hikes as m on m.country = i.country
)

-- returns the desired metrics along with a calculated total action rank indicating agressiveness of response
select i.country,
	rank() over (order by r.combined_ranks asc) as total_action_rank,
	r.interest_rate_cut_rank,
	i.deepest_interest_cut_2008_2011,
	i.average_interest_2003_2007,
	i.min_interest_2008_2011,
	r.money_supply_hike_rank,
	m.largest_money_supply_hike_2008_2011,
	m.average_money_supply_2003_2007,
	m.max_money_supply_2008_2011
from interest_rate_cuts as i 
join money_supply_hikes as m on m.country = i.country
join rank as r on r.country = i.country
order by total_action_rank asc;

