/*
* Covid 19 Data Exploration 
* Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


SELECT * 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT * 
FROM CovidVaccinations
ORDER BY location, date

------ Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population 
FROM CovidDeaths
ORDER BY location, date

------ changing data type

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases float

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths float

------ Total Cases vs Total Deaths 
------ Shows likelihood of dying if you contract covid in your country


SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS DeathPercentage
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND location like 'India'
ORDER BY location, date

------ Shows location with highest death percentage

SELECT Top 10 location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS DeathPercentage
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND continent IS NOT NULL
ORDER BY date DESC, DeathPercentage DESC

------ Shows location with highest cases and their death rates

SELECT Top 10 location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS DeathPercentage
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND continent IS NOT NULL
ORDER BY date DESC, total_cases DESC
 
------ Shows what percentage of population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND location like 'India'
ORDER BY location, date

------ Shows highest infection rates compare to the population

SELECT Top 10 location, date, population, total_cases,  total_cases/population *100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY date DESC, PercentPopulationInfected DESC

------ Shows countries highest death count per population

SELECT Top 10 location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC 

------ Shows continent highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT IN ('World','High income','Upper middle income','Low income','Lower middle income','European Union')
GROUP BY location
ORDER BY TotalDeathCount DESC

------ Shows Global death percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 

------ Using CTE to calculate percentage of people in a country that are vaccinated per day

with VaccinatedPopulation (continent, location, date, population, new_vaccinations, VaccineCumulativeSum)
AS
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations, 
SUM(CONVERT(float,Vac.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date ) AS VaccineCumulativeSum
FROM CovidDeaths Dea
JOIN CovidVaccinations Vac
	ON Dea.location=vac.location
	AND Dea.date=Vac.date
WHERE Dea.continent IS NOT NULL 
)
SELECT *, (VaccineCumulativeSum/population)*100 AS VaccinatedPercentage
FROM VaccinatedPopulation
ORDER BY location, date

------ Using Temp Table to Store number of covid cases and vaccinations as compare to population

DROP TABLE IF EXISTS #CountryInfo
CREATE TABLE #CountryInfo(
location varchar(50),
population int,
total_vaccinations bigint,
total_cases int
)

INSERT INTO #CountryInfo
SELECT Dea.location, MAX(Dea.population) population, MAX(CAST(Vac.total_vaccinations AS bigint)) total_vaccinations, MAX(Dea.total_cases) total_cases
FROM CovidDeaths Dea
JOIN CovidVaccinations Vac
	ON Dea.location=vac.location
	AND Dea.date=Vac.date
WHERE Dea.location is NOT NULL AND  Dea.continent is NOT NULL
GROUP BY Dea.location
ORDER BY Dea.location

SELECT * FROM #CountryInfo


------ Creating View to store data for later visualizations

CREATE VIEW CountryInfoView AS
SELECT Dea.location, MAX(Dea.population) population, MAX(CAST(Vac.total_vaccinations AS bigint)) total_vaccinations, MAX(Dea.total_cases) total_cases
FROM CovidDeaths Dea
JOIN CovidVaccinations Vac
	ON Dea.location=vac.location
	AND Dea.date=Vac.date
WHERE Dea.location is NOT NULL AND  Dea.continent is NOT NULL
GROUP BY Dea.location

