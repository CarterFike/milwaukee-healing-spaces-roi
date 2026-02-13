# Milwaukee Crime & Vacant Lots: Complete ETL Pipeline
# 
# PURPOSE: Transform 40,000+ raw crime records into analysis-ready geocoded data
# RUNTIME: ~48 hours on Marquette University server for full geocoding
# 
# WORKFLOW:
# 1. Load raw data from Milwaukee Open Data Portal
# 2. Standardize addresses with custom Regex patterns
# 3. Batch geocode using OSM with ArcGIS fallback
# 4. Manual fixes for known problem addresses
# 5. Filter to high vacant-lot density ZIP codes
#
# Author: Carter Fike
# Last Updated: 2024

library(readr)
library(dplyr)
library(stringr)
library(tidygeocoder)

# =============================================================================
# PART 1: DATA LOADING
# =============================================================================

cat("========================================\n")
cat("MILWAUKEE CRIME DATA ETL PIPELINE\n")
cat("========================================\n\n")

cat("Loading raw datasets...\n")

# Crime incidents (2018-2023, all types)
crime_data <- read_csv("crimestats.csv")
cat("  ✓ Crime records:", nrow(crime_data), "\n")

# Vacant lots from Milwaukee Assessor's Office
vacant_lots <- read_csv("accelavacantbuilding.csv")
cat("  ✓ Vacant lots:", nrow(vacant_lots), "\n")

# Healing spaces (community gardens, peace parks)
healing_spaces <- read_csv("HealingSpaces_Sheet1.csv")
cat("  ✓ Healing spaces:", nrow(healing_spaces), "\n\n")

# =============================================================================
# PART 2: ADDRESS STANDARDIZATION
# =============================================================================

cat("========================================\n")
cat("STEP 1: ADDRESS CLEANING\n")
cat("========================================\n\n")

cat("Applying standardization rules...\n")

crime_filtered <- crime_data %>%
  # -------------------------------------------------------------------------
  # Filter to analysis scope
  # -------------------------------------------------------------------------
  filter(
    # Temporal scope: 6-year analysis window
    ReportedYear >= 2018 & ReportedYear <= 2023,
    
    # Crime type filter: Focus on index crimes (FBI classification)
    # Excludes: traffic violations, ordinance violations, misc offenses
    AssaultOffense == 1 | Homicide == 1 | Robbery == 1 | 
      SexOffense == 1 | Burglary == 1 | CriminalDamage == 1 | Arson == 1,
    
    # Data quality: Must have a location
    !is.na(Location),
    Location != ""
  ) %>%
  
  # -------------------------------------------------------------------------
  # Address standardization (Critical for geocoding success)
  # -------------------------------------------------------------------------
  mutate(
    # RULE 1: Remove apartment/unit numbers
    # Before: "123 MAIN ST #2A"
    # After:  "123 MAIN ST"
    # Why: Geocoders match to building, not units
    Location = str_remove_all(Location, "#[A-Z0-9-]+") %>%
      str_squish() %>%      # Remove extra whitespace
      toupper(),             # Standardize case
    
    # RULE 2: Standardize intersection notation
    # Before: "12TH ST / FOND DU LAC AVE"  or  "12TH ST & FOND DU LAC"
    # After:  "12TH ST AND FOND DU LAC AVE"
    # Why: OSM expects "AND", not "/" or "&"
    Location = str_replace_all(Location, "\\s*/\\s*|\\s*&\\s*", " AND "),
    
    # RULE 3: Expand street type abbreviations
    # Why: Geocoder databases use standardized suffixes
    # Common errors fixed:
    #   - "BL" → "BLVD" (manual data entry shortcut)
    #   - "STREET" → "ST" (consistency)
    Location = str_replace_all(Location,
                               c(
                                 "\\bSTREET\\b" = "ST",
                                 "\\bAVENUE\\b" = "AVE",
                                 "\\bROAD\\b" = "RD",
                                 "\\bBOULEVARD\\b" = "BLVD",
                                 "\\bBL\\b" = "BLVD",        # Critical fix!
                                 "\\bPLACE\\b" = "PL",
                                 "\\bDRIVE\\b" = "DR",
                                 "\\bCOURT\\b" = "CT",
                                 "\\bLANE\\b" = "LN",
                                 "\\bPARKWAY\\b" = "PKWY"
                               )
    ),
    
    # RULE 4: Add geographic context for intersections
    # Before: "MAIN ST AND 1ST AVE"
    # After:  "MAIN ST AND 1ST AVE, MILWAUKEE, WI"
    # Why: Prevents geocoder from matching to "Main & 1st" in Chicago/Philadelphia
    Location = ifelse(
      str_detect(Location, " AND "),
      paste0(Location, ", MILWAUKEE, WI"),
      Location
    ),
    
    # RULE 5: Quality flags for validation
    has_number = str_detect(Location, "\\d"),  # Does address contain a number?
    
    # -------------------------------------------------------------------------
    # Crime classification for analysis
    # -------------------------------------------------------------------------
    CrimeType = case_when(
      AssaultOffense == 1 ~ "Violent: Assault",
      Homicide == 1 ~ "Violent: Homicide",
      Robbery == 1 ~ "Violent: Robbery",
      SexOffense == 1 ~ "Violent: Sex Offense",
      Burglary == 1 ~ "Property: Burglary",
      CriminalDamage == 1 ~ "Property: Vandalism",
      Arson == 1 ~ "Property: Arson"
    )
  )

cat("  ✓ Filtered to", nrow(crime_filtered), "relevant crime records\n\n")

# =============================================================================
# PART 3: QUALITY ASSURANCE
# =============================================================================

cat("========================================\n")
cat("STEP 2: QUALITY CHECKS\n")
cat("========================================\n\n")

# Identify addresses that may fail geocoding
questionable_addresses <- crime_filtered %>%
  filter(
    # Red flags:
    str_detect(Location, "UNKNOWN|NA$|^\\s*$") |        # Placeholder text
      (!has_number & !str_detect(Location, " AND "))    # No number + not intersection = bad address
  ) %>%
  distinct(Location) %>%
  arrange(Location)

cat("  Found", nrow(questionable_addresses), "addresses flagged for manual review\n")

# Export for human verification
write_csv(questionable_addresses, "needs_manual_review.csv")
write_csv(crime_filtered, "cleaned_crime_data.csv")

cat("  ✓ Exported cleaned_crime_data.csv\n")
cat("  ✓ Exported needs_manual_review.csv\n\n")

# =============================================================================
# PART 4: GEOCODING (The Long Part)
# =============================================================================

cat("========================================\n")
cat("STEP 3: GEOCODING\n")
cat("========================================\n")
cat("This will take 24-48 hours on university server\n")
cat("========================================\n\n")

# -------------------------------------------------------------------------
# GEOCODING STRATEGY:
# - Primary: OpenStreetMap (free, 1 request/sec, good US coverage)
# - Fallback: ArcGIS (better accuracy for edge cases, rate limited)
# - Manual fixes: Hardcode known problem addresses
# -------------------------------------------------------------------------

# Step 4a: Geocode vacant lots
cat("Geocoding vacant lots...\n")
vacant_lots_geo <- vacant_lots %>%
  geocode(address = ADDRFULLLINE, method = "osm")

success_vacant <- sum(!is.na(vacant_lots_geo$lat)) / nrow(vacant_lots_geo) * 100
cat("  Success rate:", round(success_vacant, 1), "%\n\n")

# Step 4b: Geocode crime data (PASS 1: OSM)
cat("Geocoding crime data (Pass 1: OpenStreetMap)...\n")
crime_geo <- crime_filtered %>%
  geocode(address = Location, method = "osm")

success_pass1 <- sum(!is.na(crime_geo$lat)) / nrow(crime_geo) * 100
cat("  Pass 1 success:", round(success_pass1, 1), "%\n")

failures_count <- sum(is.na(crime_geo$lat))
cat("  Failures:", failures_count, "addresses\n\n")

# Step 4c: FALLBACK GEOCODING (PASS 2: ArcGIS for failures)
if (failures_count > 0) {
  cat("Re-geocoding failures (Pass 2: ArcGIS)...\n")
  
  # Extract failures
  geocode_failures <- crime_geo %>%
    filter(is.na(lat)) %>%
    select(-lat, -long)
  
  # Re-geocode with ArcGIS
  geocoded_fallback <- geocode_failures %>%
    geocode(address = Location, method = "arcgis") %>%
    rename(lat_new = lat, long_new = long)
  
  # Merge back using coalesce (keeps original if available, uses fallback otherwise)
  crime_geo_final <- crime_geo %>%
    left_join(
      geocoded_fallback %>% select(Location, lat_new, long_new),
      by = "Location"
    ) %>%
    mutate(
      lat = coalesce(lat, lat_new),
      long = coalesce(long, long_new)
    ) %>%
    select(-lat_new, -long_new)
  
  success_pass2 <- sum(!is.na(crime_geo_final$lat)) / nrow(crime_geo_final) * 100
  cat("  Pass 2 final success:", round(success_pass2, 1), "%\n\n")
} else {
  crime_geo_final <- crime_geo
}

# Step 4d: Geocode healing spaces
cat("Geocoding healing spaces...\n")
healing_spaces_geo <- healing_spaces %>%
  geocode(address = Address, method = "osm")

# Step 4e: MANUAL COORDINATE FIXES
# These addresses consistently failed geocoding or returned wrong locations
# Coordinates verified via:
#   - Google Maps satellite view
#   - On-site GPS readings (field visits, 2024)
#   - Cross-reference with Milwaukee GIS portal
cat("  Applying manual coordinate corrections...\n")

healing_spaces_geo <- healing_spaces_geo %>%
  mutate(
    lat = case_when(
      Name == "Tranquility on the Trail" ~ 43.0685,
      Name == "The Belonging Place" ~ 43.0649,
      Name == "Peace Place Park and Garden" ~ 43.0647,
      TRUE ~ lat  # Keep original for all others
    ),
    long = case_when(
      Name == "Tranquility on the Trail" ~ -87.9253,
      Name == "The Belonging Place" ~ -87.9328,
      Name == "Peace Place Park and Garden" ~ -87.9332,
      TRUE ~ long
    )
  )

cat("  ✓ Healing spaces geocoded:", nrow(healing_spaces_geo), "\n\n")

# =============================================================================
# PART 5: GEOGRAPHIC FILTERING
# =============================================================================

cat("========================================\n")
cat("STEP 4: FILTER TO VACANT LOT HOTSPOTS\n")
cat("========================================\n\n")

# Milwaukee ZIP codes with highest vacant lot density
# Source: Milwaukee Assessor's Office spatial analysis
# Used to focus analysis on most impacted neighborhoods
vacant_lot_zips <- c(
  53223, 53224, 53209, 53218, 53225,  # North Side
  53216, 53212, 53222, 53206,          # Central (highest density)
  53211, 53210, 53205, 53208,          # Near North/East
  53202, 53233, 53213, 53214,          # Downtown/West
  53226, 53204, 53215, 53207,          # South Side
  53219, 53227, 53220, 53221, 53228    # Far South/Southwest
)

# Filter crime data to these ZIPs
crime_vacant_zips <- crime_geo_final %>%
  filter(Zip %in% vacant_lot_zips)

cat("  Filtered to", length(vacant_lot_zips), "high vacant-lot ZIPs\n")
cat("  Records retained:", nrow(crime_vacant_zips), "/", nrow(crime_geo_final), "\n\n")

# =============================================================================
# PART 6: EXPORT FINAL DATASETS
# =============================================================================

cat("========================================\n")
cat("EXPORTING FINAL FILES\n")
cat("========================================\n\n")

# Primary analysis dataset (all Milwaukee)
write_csv(crime_geo_final, "final_crime_updated.csv")
cat("  ✓ final_crime_updated.csv (", nrow(crime_geo_final), "rows )\n")

# Subset for vacant lot analysis
write_csv(crime_vacant_zips, "cleaned_crime_data_vacant_zips.csv")
cat("  ✓ cleaned_crime_data_vacant_zips.csv (", nrow(crime_vacant_zips), "rows )\n")

# Supporting datasets
write_csv(vacant_lots_geo, "vacant_lots_geo.csv")
cat("  ✓ vacant_lots_geo.csv (", nrow(vacant_lots_geo), "rows )\n")

write_csv(healing_spaces_geo, "HealingSpacesGeo.csv")
cat("  ✓ HealingSpacesGeo.csv (", nrow(healing_spaces_geo), "rows )\n\n")

# =============================================================================
# SUMMARY STATISTICS
# =============================================================================

cat("========================================\n")
cat("FINAL SUMMARY\n")
cat("========================================\n\n")

cat("Crime Data Pipeline:\n")
cat("  Raw records loaded:", nrow(crime_data), "\n")
cat("  After filtering:", nrow(crime_filtered), "\n")
cat("  Successfully geocoded:", sum(!is.na(crime_geo_final$lat)), "\n")
cat("  Final success rate:", round(sum(!is.na(crime_geo_final$lat))/nrow(crime_geo_final)*100, 1), "%\n\n")

cat("Supporting Datasets:\n")
cat("  Vacant lots geocoded:", sum(!is.na(vacant_lots_geo$lat)), "/", nrow(vacant_lots_geo), "\n")
cat("  Healing spaces geocoded:", sum(!is.na(healing_spaces_geo$lat)), "/", nrow(healing_spaces_geo), "\n\n")

cat("ETL Pipeline Complete!\n")
cat("Next step: Run spatial analysis scripts\n")
