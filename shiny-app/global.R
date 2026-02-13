# global.R
# This file runs ONCE when the app starts up, before server.R and ui.R
# All data loading and heavy preprocessing happens here to improve performance

library(shiny)
library(leaflet)
library(dplyr)
library(ggplot2)
library(sf)
library(DT)
library(tidyr)
library(leaflet.extras)

# ============================================================================
# LOAD DATA ONCE AT STARTUP (not on every reactive call)
# ============================================================================

message("Loading crime data...")
final_crime_updated <- read.csv("final_crime_updated.csv")

message("Loading vacant lots data...")
vacant_lots_enriched <- readr::read_csv("vacant_lots_geo_enriched.csv", show_col_types = FALSE)

message("Loading healing spaces data...")
healing_spaces_data <- read.csv("HealingSpacesGeo.csv")

# ============================================================================
# PRE-PROCESS DATA TO REDUCE RUNTIME COMPUTATION
# ============================================================================

# Pre-filter and add category to crime data
message("Pre-processing crime data...")
final_crime_updated <- final_crime_updated %>%
  filter(!is.na(long), !is.na(lat)) %>%
  mutate(Category = ifelse(AssaultOffense | Homicide | Robbery | SexOffense, "Violent", "Property"))

# Pre-filter healing spaces
healing_spaces_data <- healing_spaces_data %>%
  filter(!is.na(lat), !is.na(long))

# Pre-filter vacant lots and remove NA column if it exists
vacant_lots_enriched <- vacant_lots_enriched %>%
  select(-any_of("NA")) %>%
  filter(!is.na(lat), !is.na(long))

# ============================================================================
# PRE-CREATE SPATIAL OBJECTS FOR STATS TAB (HUGE PERFORMANCE GAIN)
# ============================================================================

message("Converting crime data to spatial format (this takes a moment)...")
# Convert crime data to sf ONCE instead of every time stats tab is used
crimes_sf_2021_2023 <- final_crime_updated %>%
  filter(ReportedYear >= 2021, ReportedYear <= 2023) %>%
  mutate(
    Crime_Detail = case_when(
      SexOffense == 1 ~ "Rape/Sexual Assault",
      AssaultOffense == 1 ~ "Aggravated Assault",
      Robbery == 1 ~ "Robbery",
      Burglary == 1 ~ "Burglary",
      Arson == 1 ~ "Arson",
      CriminalDamage == 1 ~ "Vandalism",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(Crime_Detail)) %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)

# Full time range for stats plot
crimes_sf_full_range <- final_crime_updated %>%
  filter(ReportedYear >= 2018, ReportedYear <= 2023) %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)

message("Data loading complete! App ready to start.")
