# set working directory to the folder containing this script
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load required packages
library(tidyverse)
library(sf)
library(tidycensus)
library(janitor)

# load arrests data from most recent two Data Deportation Project releases
arrests_old <- readRDS("data/arrests_old.rds")
arrests_new <- readRDS("data/arrests_new.rds")

# combine into a single dataset for second Trump administration, 
# using newer data with less detailed landmark/location data only from 2026-03-01
trump_arrests_old <- arrests_old %>%
  filter(apprehension_date < "2026-03-01" & apprehension_date >= "2025-01-20" &  duplicate_likely == FALSE)

trump_arrests_new <- arrests_new %>%
  filter(apprehension_date >= "2026-03-01" & duplicate_likely == FALSE) %>%
  rename(apprehension_state = apprehension_state,
         apprehension_site_landmark = event_landmark)

trump_arrests <- bind_rows(trump_arrests_old,trump_arrests_new)

#############
# analysis for the nation
population_nation <- get_acs(
  geography = "us",
  variables = c(
    total_pop = "B05002_001", 
    immigrant_pop = "B05002_013",
    immigrant_naturalized = "B05002_014",
    immigrant_noncitizen = "B05002_021"
  ),
  year = 2024,
  output = "wide") %>%
  clean_names() %>%
  mutate(name = str_to_upper(name))

trump_arrests_nation_pop <- population_nation %>%
  mutate(arrests = nrow(trump_arrests),
         immigrant_percent = immigrant_pop_e/total_pop_e,
         immigrant_naturalized_percent = immigrant_naturalized_e/total_pop_e,
         immigrant_noncitizen_percent = immigrant_noncitizen_e/total_pop_e,
         arrests_per10k_population = arrests / total_pop_e * 10^4,
         arrests_per10k_immigrant_population = arrests / immigrant_pop_e * 10^4,
         arrests_per10k_immigrant_naturalized = arrests / immigrant_naturalized_e * 10^4,
         arrests_per10k_immigrant_noncitizen = arrests / immigrant_noncitizen_e * 10^4) %>%
  select(arrests,
         total_population=total_pop_e,
         immigrant_population=immigrant_pop_e,
         immigrant_percent,
         immigrant_naturalized=immigrant_naturalized_e,
         immigrant_naturalized_percent,
         immigrant_noncitizen=immigrant_noncitizen_e,
         immigrant_noncitizen_percent,
         arrests_per10k_population,
         arrests_per10k_immigrant_population,
         arrests_per10k_immigrant_naturalized,
         arrests_per10k_immigrant_noncitizen)

write_csv(trump_arrests_nation_pop, "processed_data/trump_arrests_nation_pop.csv", na = "")

# analysis by ICE Area of Responsibility (AOR)
aor <- download.file("https://github.com/deportationdata/ice-offices/raw/refs/heads/main/data/ice-aor-shp.zip", destfile = "data/aor.zip")
unzip("data/aor.zip", exdir = "data/aor")

aor <- st_read("data/aor/ice-aor-shp.shp")

aor_counties <- download.file("https://github.com/deportationdata/ice-offices/raw/refs/heads/main/data/ice-aor-county-shp.zip", destfile = "data/aor_counties.zip")
unzip("data/aor_counties.zip", exdir = "data/aor_counties")

aor_counties <- st_read("data/aor_counties/ice-aor-county-shp.shp") %>% 
  clean_names()

aor_counties_join <- aor_counties %>%
  st_drop_geometry() %>%
  select(geoid, offc_nm)

population_counties <- get_acs(
  geography = "county",
  variables = c(
    total_pop = "B05002_001", 
    immigrant_pop = "B05002_013",
    immigrant_naturalized = "B05002_014",
    immigrant_noncitizen = "B05002_021"
  ),
  year = 2024,
  output = "wide") %>%
  clean_names()

population_aor <- population_counties %>%
  left_join(aor_counties_join, by = "geoid") %>%
  group_by(offc_nm) %>%
  summarize(total_population = sum(total_pop_e, na.rm = TRUE),
            immigrant_population = sum(immigrant_pop_e, na.rm = TRUE),
            immigrant_naturalized = sum(immigrant_naturalized_e, na.rm = TRUE),
            immigrant_noncitizen = sum(immigrant_noncitizen_e, na.rm = TRUE))

trump_arrests_aor <- trump_arrests %>%
  mutate(offc_nm = str_replace_all(apprehension_aor, " Area of Responsibility",""),
         offc_nm = str_replace_all(offc_nm, "St. Paul","St Paul")) %>%
  group_by(apprehension_aor,offc_nm) %>%
  count() %>%
  arrange(-n) %>%
  rename(arrests = n)

trump_arrests_aor_pop <- inner_join(trump_arrests_aor, population_aor, by = "offc_nm") %>%
  mutate(immigrant_percent = immigrant_population/total_population,
         immigrant_naturalized_percent = immigrant_naturalized/total_population,
         immigrant_noncitizen_percent = immigrant_noncitizen/total_population,
         arrests_per10k_population = arrests / total_population * 10^4,
         arrests_per10k_immigrant_population = arrests / immigrant_population * 10^4,
         arrests_per10k_immigrant_naturalized = arrests / immigrant_naturalized * 10^4,
         arrests_per10k_immigrant_noncitizen = arrests / immigrant_noncitizen  * 10^4) %>%
  select(apprehension_aor,
         office = offc_nm,
         arrests,
         total_population,
         immigrant_population,
         immigrant_percent,
         immigrant_naturalized,
         immigrant_naturalized_percent,
         immigrant_noncitizen,
         immigrant_noncitizen_percent,
         arrests_per10k_population,
         arrests_per10k_immigrant_population,
         arrests_per10k_immigrant_naturalized,
         arrests_per10k_immigrant_noncitizen)

write_csv(trump_arrests_aor_pop, "processed_data/trump_arrests_aor_pop.csv", na = "")

#############
# analysis by state

population_states <- get_acs(
  geography = "state",
  variables = c(
    total_pop = "B05002_001", 
    immigrant_pop = "B05002_013",
    immigrant_naturalized = "B05002_014",
    immigrant_noncitizen = "B05002_021"
  ),
  year = 2024,
  output = "wide") %>%
  clean_names() %>%
  mutate(name = str_to_upper(name))
  
trump_arrests_state <- trump_arrests %>%
  group_by(apprehension_state) %>%
  count() %>%
  arrange(-n) %>%
  rename(arrests = n)

trump_arrests_state_pop <- inner_join(trump_arrests_state, population_states, by = c("apprehension_state" = "name")) %>%
  mutate(immigrant_percent = immigrant_pop_e/total_pop_e,
         immigrant_naturalized_percent = immigrant_naturalized_e/total_pop_e,
         immigrant_noncitizen_percent = immigrant_noncitizen_e/total_pop_e,
         arrests_per10k_population = arrests / total_pop_e * 10^4,
         arrests_per10k_immigrant_population = arrests / immigrant_pop_e * 10^4,
         arrests_per10k_immigrant_naturalized = arrests / immigrant_naturalized_e * 10^4,
         arrests_per10k_immigrant_noncitizen = arrests / immigrant_noncitizen_e * 10^4) %>%
  select(apprehension_state,
         arrests,
         total_population=total_pop_e,
         immigrant_population=immigrant_pop_e,
         immigrant_percent,
         immigrant_naturalized=immigrant_naturalized_e,
         immigrant_naturalized_percent,
         immigrant_noncitizen=immigrant_noncitizen_e,
         immigrant_noncitizen_percent,
         arrests_per10k_population,
         arrests_per10k_immigrant_population,
         arrests_per10k_immigrant_naturalized,
         arrests_per10k_immigrant_noncitizen)

write_csv(trump_arrests_state_pop, "processed_data/trump_arrests_state_pop.csv", na = "")

#############
# analysis for three Gulf States

gulf_states_trump_arrests <- trump_arrests %>%
  filter(grepl("MISSISS|ALAB|LOUIS", apprehension_state))

# by citizenship of arrested individual  
gulf_states_citizenship <- gulf_states_trump_arrests %>%
  group_by(apprehension_state, citizenship_country) %>%
  count() %>%
  pivot_wider(names_from = apprehension_state, values_from = n) %>%
  mutate(across(where(is.numeric), ~replace_na(., 0))) %>%
  mutate(total = MISSISSIPPI + ALABAMA + LOUISIANA)

write_csv(gulf_states_citizenship, "processed_data/gulf_states_arrests_citizenship.csv", na = "")

# by apprehension site landmark
al_apprehension_sites <- gulf_states_trump_arrests %>%
  filter(apprehension_state == "ALABAMA") %>%
  group_by(apprehension_site_landmark) %>%
  count() %>%
  arrange(-n)

write_csv(al_apprehension_sites, "processed_data/al_apprehension_sites.csv", na = "")

la_apprehension_sites <- gulf_states_trump_arrests %>%
  filter(apprehension_state == "LOUISIANA") %>%
  group_by(apprehension_site_landmark) %>%
  count() %>%
  arrange(-n)

write_csv(la_apprehension_sites, "processed_data/la_apprehension_sites.csv", na = "")

ms_apprehension_sites <- gulf_states_trump_arrests %>%
  filter(apprehension_state == "MISSISSIPPI") %>%
  group_by(apprehension_site_landmark) %>%
  count() %>%
  arrange(-n)

write_csv(ms_apprehension_sites, "processed_data/ms_apprehension_sites.csv", na = "")

