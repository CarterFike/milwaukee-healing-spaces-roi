# Combined Harambee Healing Spaces Analysis
# Combines neighborhood comparison + detailed impact analysis into one script
# No circular dependencies - runs sequentially

library(sf)
library(leaflet)
library(dplyr)
library(ggplot2)
library(tidyr)
library(knitr)

cat("\n========================================\n")
cat("HARAMBEE HEALING SPACES IMPACT ANALYSIS\n")
cat("========================================\n\n")

# ============================================================================
# PART 1: DATA LOADING
# ============================================================================

cat("Loading data...\n")

# Load crime data
final_crime_updated <- read.csv("final_crime_updated.csv")

# Load healing spaces
healing_spaces <- read.csv("HealingSpacesGeo.csv") %>%
  filter(!is.na(lat), !is.na(long))

cat("  ✓ Crime data loaded:", nrow(final_crime_updated), "records\n")
cat("  ✓ Healing spaces loaded:", nrow(healing_spaces), "locations\n")

# ============================================================================
# PART 2: NEIGHBORHOOD BOUNDARIES
# ============================================================================

cat("\nDefining neighborhood boundaries...\n")

# Lindsay Heights polygon
lindsay_coords <- matrix(
  c(
    -87.93738127848015, 43.07134751184442,  
    -87.92686701970244, 43.07119076252027,  
    -87.92716742709608, 43.0524720116947,   
    -87.93798209326744, 43.052691527647916, 
    -87.93738127848015, 43.07134751184442   
  ),
  ncol = 2,
  byrow = TRUE
)

lindsay_polygon <- st_polygon(list(lindsay_coords)) %>% 
  st_sfc(crs = 4326) %>% 
  st_make_valid()

# Harambee polygon
harambee_coords <- matrix(
  c(
    -87.921088, 43.081570,  
    -87.904961, 43.082064,  
    -87.905321, 43.060212,  
    -87.921404, 43.060311,  
    -87.921088, 43.081570   
  ),
  ncol = 2,
  byrow = TRUE
)

harambee_polygon <- st_polygon(list(harambee_coords)) %>%
  st_sfc(crs = 4326) %>%
  st_make_valid()

cat("  ✓ Harambee boundary defined\n")
cat("  ✓ Lindsay Heights boundary defined\n")

# ============================================================================
# PART 3: CONVERT TO SPATIAL FORMAT
# ============================================================================

cat("\nConverting to spatial format...\n")

# Convert crime data to spatial format
crimes_sf <- final_crime_updated %>%
  filter(!is.na(long), !is.na(lat)) %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)

# Convert healing spaces to spatial format
healing_sf <- st_as_sf(healing_spaces, coords = c("long", "lat"), crs = 4326)

# Project to Wisconsin State Plane (EPSG:3071) for accurate measurements
harambee_polygon_proj <- st_transform(harambee_polygon, 3071)
crimes_sf_proj <- st_transform(crimes_sf, 3071)
healing_sf_proj <- st_transform(healing_sf, 3071)

cat("  ✓ Spatial conversion complete\n")

# ============================================================================
# PART 4: FILTER HEALING SPACES TO HARAMBEE ONLY
# ============================================================================

cat("\nFiltering healing spaces...\n")

# Keep only healing spaces within Harambee
healing_sf_harambee <- healing_sf_proj[
  st_within(healing_sf_proj, harambee_polygon_proj, sparse = FALSE), 
]

num_healing_spaces <- nrow(healing_sf_harambee)
cat("  ✓", num_healing_spaces, "healing spaces found in Harambee\n")

# ============================================================================
# PART 5: CREATE BUFFER ZONES (0.1 mile = 160.9 meters)
# ============================================================================

cat("\nCreating buffer zones...\n")

buffer_dist <- 160.9  # 0.1 mile in meters

# Create buffers around each healing space
buffers_proj <- st_buffer(healing_sf_proj, dist = buffer_dist)
combined_buffer_proj <- st_make_valid(st_union(buffers_proj))

# Transform back to WGS84 for visualization
combined_buffer <- st_transform(combined_buffer_proj, 4326)

cat("  ✓ 0.1-mile buffers created\n")

# ============================================================================
# PART 6: CALCULATE AREAS
# ============================================================================

harambee_area <- st_area(harambee_polygon_proj) %>% as.numeric()
buffer_area <- st_area(combined_buffer_proj) %>% as.numeric()
non_buffer_area <- harambee_area - buffer_area

# Convert to km²
buffer_area_km2 <- buffer_area / 1e6
non_buffer_area_km2 <- non_buffer_area / 1e6

cat("\n--- Area Calculations ---\n")
cat("Total Harambee area:", round(harambee_area / 1e6, 3), "km²\n")
cat("Buffer zone area:", round(buffer_area_km2, 3), "km²\n")
cat("Non-buffer area:", round(non_buffer_area_km2, 3), "km²\n")
cat("Buffer coverage:", round((buffer_area / harambee_area) * 100, 1), "%\n")

# ============================================================================
# PART 7: EXTRACT CRIMES BY NEIGHBORHOOD
# ============================================================================

cat("\nExtracting crimes by neighborhood...\n")

# Extract crimes within each neighborhood
harambee_crimes <- crimes_sf[st_within(crimes_sf, harambee_polygon, sparse = FALSE), ]
lindsay_crimes <- crimes_sf[st_within(crimes_sf, lindsay_polygon, sparse = FALSE), ]

cat("  ✓ Harambee crimes:", nrow(harambee_crimes), "\n")
cat("  ✓ Lindsay Heights crimes:", nrow(lindsay_crimes), "\n")

# Classify Harambee crimes: near healing spaces vs not, and time period
harambee_crimes <- harambee_crimes %>%
  mutate(
    near_healing = st_within(harambee_crimes, combined_buffer, sparse = FALSE) %>% as.logical(),
    period = ifelse(ReportedYear >= 2021, "Post-2021", "Pre-2021")
  )

# Also get projected version for detailed analysis
harambee_crimes_proj <- crimes_sf_proj[
  st_within(crimes_sf_proj, harambee_polygon_proj, sparse = FALSE), 
]

harambee_crimes_proj <- harambee_crimes_proj %>%
  mutate(
    near_healing = st_within(harambee_crimes_proj, combined_buffer_proj, sparse = FALSE) %>% as.logical(),
    period = ifelse(ReportedYear >= 2021, "Post-2021", "Pre-2021"),
    crime_category = ifelse(grepl("Violent", CrimeType), "Violent", "Property")
  )

# ============================================================================
# PART 8: NEIGHBORHOOD COMPARISON - CRIME RATES
# ============================================================================

cat("\n========================================\n")
cat("PART A: NEIGHBORHOOD COMPARISON\n")
cat("========================================\n\n")

# Combine both neighborhoods
combined_crimes <- bind_rows(
  harambee_crimes %>% mutate(neighborhood = "Harambee"),
  lindsay_crimes %>% mutate(neighborhood = "Lindsay Heights")
) %>%
  mutate(
    crime_category = ifelse(grepl("Violent", CrimeType), "Violent", "Property")
  )

# Summarize crime counts
crime_summary <- combined_crimes %>%
  group_by(neighborhood, period, crime_category) %>%
  summarise(total_crimes = n(), .groups = "drop")

# Add neighborhood demographics
neighborhood_data <- data.frame(
  neighborhood = c("Harambee", "Lindsay Heights"),
  population = c(17899, 7905),
  median_income = c(31456, 30331)
)

# Calculate crime rates per 1,000 residents
crime_summary <- crime_summary %>%
  left_join(neighborhood_data, by = "neighborhood") %>%
  mutate(crime_rate = (total_crimes / population) * 1000)

# Display summary table
cat("\n--- Crime Rate Summary ---\n")
print(kable(
  crime_summary %>% 
    mutate(crime_rate = round(crime_rate, 2)) %>%
    select(neighborhood, period, crime_category, total_crimes, crime_rate),
  caption = "Crime Rates per 1,000 Residents"
))

# ============================================================================
# PART 9: VISUALIZATION 1 - Crime Rate vs Income
# ============================================================================

cat("\nGenerating Plot 1: Crime Rate vs Income...\n")

p1 <- ggplot(crime_summary, aes(x = median_income, y = crime_rate)) +
  geom_point(aes(color = neighborhood, shape = period), size = 4) +
  geom_label(aes(label = paste0(round(crime_rate, 2), "/1,000")), 
             hjust = 0.5, vjust = -0.8, size = 3) +
  facet_wrap(~crime_category, scales = "free_y") +
  labs(
    title = "Crime Rate vs Median Income Comparison",
    subtitle = "Harambee (with healing spaces) vs Lindsay Heights (control)",
    x = "Median Income ($)", 
    y = "Crime Rate per 1,000 Residents"
  ) +
  theme_minimal()

print(p1)

# ============================================================================
# PART 10: CRIME DENSITY ANALYSIS (HARAMBEE ONLY)
# ============================================================================

cat("\n========================================\n")
cat("PART B: DETAILED HARAMBEE ANALYSIS\n")
cat("========================================\n\n")

# Summarize crime counts by zone
crime_density <- harambee_crimes_proj %>%
  st_drop_geometry() %>%
  group_by(near_healing, period, crime_category) %>%
  summarise(total_crimes = n(), .groups = "drop")

# Ensure all combinations exist
all_combinations <- expand.grid(
  near_healing = c(TRUE, FALSE),
  period = c("Pre-2021", "Post-2021"),
  crime_category = c("Violent", "Property")
)

crime_density <- left_join(all_combinations, crime_density,
                           by = c("near_healing", "period", "crime_category")) %>%
  mutate(
    total_crimes = ifelse(is.na(total_crimes), 0, total_crimes),
    area_km2 = ifelse(near_healing, buffer_area_km2, non_buffer_area_km2),
    crimes_per_km2 = total_crimes / area_km2,
    zone = ifelse(near_healing, "Inside Buffer", "Outside Buffer")
  )

# Display density table
cat("\n--- Crime Density Summary ---\n")
print(kable(
  crime_density %>% 
    select(zone, period, crime_category, total_crimes, crimes_per_km2) %>%
    mutate(crimes_per_km2 = round(crimes_per_km2, 1)),
  caption = "Crime Density (crimes per km²)"
))

# ============================================================================
# PART 11: VISUALIZATION 2 - Crime Density Comparison
# ============================================================================

cat("\nGenerating Plot 2: Crime Density Comparison...\n")

crime_density <- crime_density %>%
  mutate(period = factor(period, levels = c("Pre-2021", "Post-2021")))

p2 <- ggplot(crime_density, aes(x = period, y = crimes_per_km2, group = zone, color = zone, fill = zone)) +
  geom_col(position = position_dodge(width = 0.9), width = 0.7, alpha = 0.7) +
  geom_text(
    aes(label = round(crimes_per_km2, 1)),
    position = position_dodge(width = 0.9),
    vjust = -0.5,
    size = 3.5
  ) +
  geom_line(aes(group = zone), position = position_dodge(width = 0.9), size = 1.2) +
  geom_point(position = position_dodge(width = 0.9), size = 3) +
  facet_wrap(~crime_category, scales = "free_y") +
  labs(
    title = "Crime Density: Inside vs Outside Healing Space Buffers",
    subtitle = "Harambee Neighborhood | 0.1-mile buffer zones",
    x = "Time Period",
    y = "Crimes per km²",
    color = "Zone",
    fill = "Zone"
  ) +
  scale_color_manual(values = c("Outside Buffer" = "#d32f2f", "Inside Buffer" = "#388e3c")) +
  scale_fill_manual(values = c("Outside Buffer" = "#d32f2f", "Inside Buffer" = "#388e3c")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p2)

# ============================================================================
# PART 12: COST-BENEFIT ANALYSIS
# ============================================================================

cat("\n========================================\n")
cat("PART C: COST-BENEFIT ANALYSIS\n")
cat("========================================\n\n")

# Drop geometry for tabular analysis
harambee_crimes_nogeo <- harambee_crimes_proj %>% st_drop_geometry()

# Count crimes by type, zone, and period
crime_counts <- harambee_crimes_nogeo %>%
  group_by(near_healing, period) %>%
  summarise(
    AssaultOffense = sum(AssaultOffense, na.rm = TRUE),
    Burglary = sum(Burglary, na.rm = TRUE),
    CriminalDamage = sum(CriminalDamage, na.rm = TRUE),
    Robbery = sum(Robbery, na.rm = TRUE),
    .groups = "drop"
  )

# Focus on inside buffer zone only
inside_crime_counts <- crime_counts %>%
  filter(near_healing == TRUE)

# Calculate changes (Pre-2021 minus Post-2021)
crime_changes <- inside_crime_counts %>%
  pivot_wider(
    names_from = period, 
    values_from = c(AssaultOffense, Burglary, CriminalDamage, Robbery),
    names_sep = "-"
  ) %>%
  mutate(
    AssaultChange = `AssaultOffense-Pre-2021` - `AssaultOffense-Post-2021`,
    BurglaryChange = `Burglary-Pre-2021` - `Burglary-Post-2021`,
    CriminalDamageChange = `CriminalDamage-Pre-2021` - `CriminalDamage-Post-2021`,
    RobberyChange = `Robbery-Pre-2021` - `Robbery-Post-2021`
  )

# Cost per crime
cost_per_crime <- c(
  AssaultChange = 12600,
  BurglaryChange = 6020,
  CriminalDamageChange = 6070,
  RobberyChange = 20200
)

# Calculate savings
savings_summary <- crime_changes %>%
  summarise(
    AssaultSavings = AssaultChange * cost_per_crime["AssaultChange"],
    BurglarySavings = BurglaryChange * cost_per_crime["BurglaryChange"],
    CriminalDamageSavings = CriminalDamageChange * cost_per_crime["CriminalDamageChange"],
    RobberySavings = RobberyChange * cost_per_crime["RobberyChange"]
  )

total_savings <- sum(savings_summary)

# Investment cost
cost_per_space <- 22500
total_investment <- num_healing_spaces * cost_per_space

# Benefit-cost ratio
benefit_cost_ratio <- total_savings / total_investment

# Print results
cat("\n--- Cost-Benefit Summary ---\n")
cat("Number of healing spaces:", num_healing_spaces, "\n")
cat("Cost per healing space: $", formatC(cost_per_space, format = "d", big.mark = ","), "\n")
cat("Total investment: $", formatC(total_investment, format = "d", big.mark = ","), "\n")
cat("Total estimated savings: $", formatC(round(total_savings), format = "d", big.mark = ","), "\n")
cat("Benefit-cost ratio:", round(benefit_cost_ratio, 2), ":1\n")
cat("Net benefit: $", formatC(round(total_savings - total_investment), format = "d", big.mark = ","), "\n")
cat("----------------------------\n\n")

# Detailed breakdown
crime_types <- c("Assault", "Burglary", "Criminal Damage", "Robbery")
crimes_change_vector <- c(
  crime_changes$AssaultChange,
  crime_changes$BurglaryChange,
  crime_changes$CriminalDamageChange,
  crime_changes$RobberyChange
)
costs_vector <- c(12600, 6020, 6070, 20200)
savings_vector <- crimes_change_vector * costs_vector

breakdown_table <- data.frame(
  `Crime Type` = crime_types,
  `Change (Pre - Post)` = crimes_change_vector,
  `Cost Per Crime` = paste0("$", formatC(costs_vector, format = "d", big.mark = ",")),
  `Net Savings` = paste0("$", formatC(savings_vector, format = "d", big.mark = ","))
)

breakdown_table <- rbind(
  breakdown_table,
  data.frame(
    `Crime Type` = "TOTAL",
    `Change (Pre - Post)` = sum(crimes_change_vector),
    `Cost Per Crime` = "—",
    `Net Savings` = paste0("$", formatC(sum(savings_vector), format = "d", big.mark = ","))
  )
)

cat("--- Breakdown by Crime Type ---\n")
print(kable(breakdown_table, caption = "Cost-Benefit Analysis Detail"))

# ============================================================================
# PART 13: PERCENT CHANGE ANALYSIS
# ============================================================================

cat("\n--- Percent Change Analysis ---\n")

crime_percent_change <- harambee_crimes_nogeo %>%
  group_by(near_healing, period, crime_category) %>%
  summarise(total_crimes = n(), .groups = "drop") %>%
  pivot_wider(
    names_from = period,
    values_from = total_crimes,
    values_fill = 0
  ) %>%
  mutate(
    percent_change = ((`Post-2021` - `Pre-2021`) / `Pre-2021`) * 100,
    zone = ifelse(near_healing, "Inside Buffer", "Outside Buffer")
  ) %>%
  select(zone, crime_category, `Pre-2021`, `Post-2021`, percent_change)

print(kable(
  crime_percent_change %>% mutate(percent_change = round(percent_change, 1)),
  caption = "Percent Change in Crimes (Pre-2021 to Post-2021)"
))

# ============================================================================
# PART 14: INTERACTIVE MAP
# ============================================================================

cat("\n========================================\n")
cat("PART D: INTERACTIVE MAP\n")
cat("========================================\n\n")

cat("Generating interactive map...\n")

# Transform layers to WGS84 for Leaflet
harambee_polygon_ll <- st_transform(harambee_polygon, 4326)
combined_buffer_ll <- st_transform(combined_buffer, 4326)
healing_sf_ll <- st_transform(healing_sf, 4326)
harambee_crimes_ll <- st_transform(harambee_crimes, 4326)

# Create map
map <- leaflet() %>%
  addTiles() %>%
  addPolygons(
    data = combined_buffer_ll,
    color = "#00FF00", 
    fillOpacity = 0.2,
    label = "0.1-mile Healing Space Buffer", 
    group = "Buffer"
  ) %>%
  addPolygons(
    data = harambee_polygon_ll,
    color = "black", 
    weight = 2, 
    fill = FALSE,
    label = "Harambee Boundary", 
    group = "Harambee Border"
  ) %>%
  addCircleMarkers(
    data = healing_sf_ll, 
    color = "blue", 
    radius = 5,
    label = ~Name, 
    group = "Healing Spaces"
  ) %>%
  addCircleMarkers(
    data = harambee_crimes_ll, 
    color = ~ifelse(grepl("Violent", CrimeType), "red", "orange"),
    radius = 0.5, 
    group = "Crimes"
  ) %>%
  addLayersControl(
    overlayGroups = c("Buffer", "Harambee Border", "Healing Spaces", "Crimes"),
    options = layersControlOptions(collapsed = FALSE)
  )

print(map)

cat("\n========================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("========================================\n")
