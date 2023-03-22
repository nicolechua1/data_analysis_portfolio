select *
from covid_deaths cd 
where continent is not null
order by 3,4;

--select *
--from covid_vaccinations cv 
--order by 3,4 

select location, date, total_cases, new_cases, total_deaths, population 
from covid_deaths cd 
order by 1,2;

-- Covid death rate
-- Shows the likelihood of dying from covid in different countries

select location, date, total_cases, total_deaths, (total_deaths/cast(total_cases as float))*100 as DeathPercentage
from covid_deaths cd 
-- where location like '%Singapore%'
order by 1,2;

-- Covid rate
-- Shows the percentage of population who contracted covid in different countries

select location, date, total_cases, population , (total_cases /cast(population  as float))*100 as CovidPercentage
from covid_deaths cd 
-- where location like '%Singapore%'
order by 1,2;

-- Country with the highest infection rates

select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/cast(population  as float))*100 as PercentPopulationInfected
from covid_deaths cd 
group by location, population
order by PercentPopulationInfected desc;

-- Country with the highest death count per population

select location, max(total_deaths) as TotalDeathCount
from covid_deaths cd 
where continent !='' and continent is not null
group by location
order by TotalDeathCount desc;

-- Continent with the highest death count

select location, max(total_deaths) as TotalDeathCount
from covid_deaths cd 
where continent = ''
group by location
order by TotalDeathCount desc;

-- Global numbers

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/cast(nullif(sum(new_cases),0) as float)*100 as DeathPercentage
from covid_deaths cd 
-- where location like '%Singapore%'
where continent !=''
-- group by date
order by 1;

-- Vaccination percentage
-- cumulative vaccination numbers

select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	, sum(cast(nullif(new_vaccinations,'') as bigint)) over (partition by cd.location order by cd.location, cd.date)
as cumulative_vaccinations
from covid_deaths cd 
join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent !='' and cd.location like '%Albania%'
order by 2,3;

-- CTE for cumulative vaccination percentage

with PopvsVac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	, sum(cast(nullif(new_vaccinations,'') as bigint)) over (partition by cd.location order by cd.location, cd.date)
as cumulative_vaccinations
from covid_deaths cd 
join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent !='' --and cd.location like '%Albania%'
order by 2,3
)
select *, (cumulative_vaccinations/population)*100 as percent_vaccinated
from PopvsVac

-- CTE for max vaccination percentage by country  

with PopvsVac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	, sum(cast(nullif(new_vaccinations,'') as bigint)) over (partition by cd.location order by cd.location, cd.date)
as cumulative_vaccinations
from covid_deaths cd 
join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent !='' --and cd.location like '%Albania%'
order by 2,3
)
select location, population, max(cumulative_vaccinations) as highest_vaccination_count, max(cumulative_vaccinations/population)*100 as max_percent_vaccinated
from PopvsVac
--where continent !=''
group by location, population

-- above code has an issue. More vaccinations than actual people. could be due to 
-- the new_vaccinations tracking multiple vaccinations per person.


-- Temp table 
-- change table name because it is not actually a count of people vaccinated
-- but a count of vaccinations administered
drop table if exists PercentPopulationVacc
create temporary table PercentPopulationVacc
(
continent varchar(50),
location varchar(50),
date date,
population numeric,
new_vaccinations varchar(50),
cumulative_vaccinations numeric
)

insert into PercentPopulationVacc (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	, sum(cast(nullif(new_vaccinations,'') as bigint)) over (partition by cd.location order by cd.location, cd.date)
	as cumulative_vaccinations
from covid_deaths cd 
join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
--where cd.continent !='' --and cd.location like '%Albania%'
--order by 2,3

select *, (cumulative_vaccinations/population)*100 as percent_vaccinated
from PercentPopulationVacc

-- Creating View to store data for later visualizations

create view percentpopulationvacc as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
	, sum(cast(nullif(new_vaccinations,'') as bigint)) over (partition by cd.location order by cd.location, cd.date)
	as cumulative_vaccinations
from covid_deaths cd 
join covid_vaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent !='' --and cd.location like '%Albania%'

select *, (cumulative_vaccinations/population)*100 as percent_vaccinated
from percentpopulationvacc p 

