# Data Dictionary

## Sample Crime Data (`sample_crime_data.csv`)

A 1,000-row sample of the Milwaukee crime dataset (2018–2023). Full dataset contains 40,687 records.

| Column Name | Data Type | Description | Example |
|-------------|-----------|-------------|---------|
| `IncidentID` | String | Unique crime incident identifier | `2023-001234` |
| `ReportedYear` | Integer | Year crime was reported | `2023` |
| `CrimeType` | String | FBI crime classification | `Violent: Assault` |
| `AssaultOffense` | Binary (0/1) | Assault flag | `1` |
| `Burglary` | Binary (0/1) | Burglary flag | `0` |
| `CriminalDamage` | Binary (0/1) | Vandalism/property damage flag | `0` |
| `Robbery` | Binary (0/1) | Robbery flag | `0` |
| `SexOffense` | Binary (0/1) | Sexual assault flag | `0` |
| `Homicide` | Binary (0/1) | Homicide flag | `0` |
| `Arson` | Binary (0/1) | Arson flag | `0` |
| `lat` | Float | Latitude (WGS84) | `43.0456` |
| `long` | Float | Longitude (WGS84) | `-87.9123` |
| `Address` | String | Incident location (anonymized) | `N 35TH ST & W FOND DU LAC AVE` |

### Notes
- **Binary Flags:** A single incident may have multiple flags (e.g., Robbery + Assault)
- **Geocoding:** 98.4% of records have valid coordinates
- **Privacy:** Exact addresses rounded to nearest intersection per Milwaukee PD policy

---

## Healing Spaces (`healing_spaces.csv`)

Locations of community healing spaces (parks, community gardens, greened vacant lots) in Milwaukee.

| Column Name | Data Type | Description | Example |
|-------------|-----------|-------------|---------|
| `Name` | String | Healing space name | `Meditation Meadow` |
| `Address` | String | Street address | `3451 N 12TH ST` |
| `Neighborhood` | String | Milwaukee neighborhood | `Harambee` |
| `lat` | Float | Latitude (WGS84) | `43.0712` |
| `long` | Float | Longitude (WGS84) | `-87.9201` |
| `DateOpened` | Date | Installation date | `2021-06-15` |
| `Garden.Leader` | String | Community organization | `Walnut Way Conservation Corp` |
| `Contact.Name` | String | Primary contact person | `Sharon Adams` |
| `Contact.Email` | String | Email for inquiries | `sharon@walnutway.org` |
| `Contact.Phone` | String | Phone number | `(414) 555-0123` |
| `Organization.URL` | String | Website | `https://walnutway.org` |

### Notes
- **Harambee Sites:** 7 healing spaces installed 2021–2023
- **Other Neighborhoods:** 8 sites in Lindsay Heights, Midtown, etc.
- **Verification:** Locations field-verified via site visits (2024)

---

## Vacant Lots Enriched (`vacant_lots_sample.csv`)

Sample of 100 vacant lots with pre-computed crime counts within 0.1-mile radius.

| Column Name | Data Type | Description | Example |
|-------------|-----------|-------------|---------|
| `ADDRFULLLINE` | String | Full property address | `2627 N 35TH ST` |
| `DATEOPENED` | Date | Date lot became vacant | `2019-03-12` |
| `VALUEIMPROVED` | Integer | Assessed property value | `45000` |
| `lat` | Float | Latitude (WGS84) | `43.0634` |
| `long` | Float | Longitude (WGS84) | `-87.9345` |
| `CrimeCount_2023_Violent` | Integer | Violent crimes within 0.1mi (2023) | `49` |
| `CrimeCount_2023_Property` | Integer | Property crimes within 0.1mi (2023) | `87` |

### Notes
- **Crime Counts:** Pre-computed using 160.9-meter buffers (EPSG:3071)
- **High-Priority Lots:** Top 10 by crime count displayed in Shiny dashboard
- **Use Case:** Identifies optimal locations for future healing space installations

---

## Derived Variables

### Created During Analysis

| Variable | Formula | Description |
|----------|---------|-------------|
| `near_healing` | `st_within(crime, buffer_0.1mi)` | Binary flag: crime within 0.1 miles of healing space |
| `period` | `ifelse(year >= 2021, "Post", "Pre")` | Temporal baseline grouping |
| `crime_category` | `ifelse(Assault OR Homicide OR Robbery OR SexOffense, "Violent", "Property")` | Aggregated crime type |
| `crimes_per_km2` | `total_crimes / area_km2` | Crime density (area-adjusted) |
| `crime_change` | `Pre_count - Post_count` | Crime reduction metric |
| `net_savings` | `crime_change × cost_per_crime` | Dollar value of prevented crimes |

---

## Data Provenance

### Source Datasets (Full Versions)
- **Crime:** [Milwaukee Open Data Portal - Crime Incidents](https://data.milwaukee.gov/dataset/wibr) (Public Domain)
- **Vacant Lots:** Milwaukee Assessor's Office (Public Records Request)
- **Healing Spaces:** Field research + community partner records

### Processing History
1. **Raw Download:** February 2024
2. **Geocoding:** March 2024 (Marquette University server)
3. **Spatial Enrichment:** April 2024 (buffer creation, joins)
4. **Sample Creation:** May 2024 (random 1K-row sample for GitHub)

### Privacy & Ethics
- **De-identification:** No victim/suspect names included
- **Address Rounding:** Exact crime locations rounded to intersections per MPD policy
- **Contact Info:** Healing space contacts consented to public listing

---

## File Formats

### CSV Standards
- **Encoding:** UTF-8
- **Delimiter:** Comma (`,`)
- **Missing Values:** `NA` (not blank cells)
- **Date Format:** ISO 8601 (`YYYY-MM-DD`)

### Coordinate Systems
- **Stored CRS:** EPSG:4326 (WGS84 lat/long)
- **Analysis CRS:** EPSG:3071 (Wisconsin State Plane, meters)
  - *Always reproject to 3071 before distance calculations*

---

## Sample Size Rationale

**Why 1,000 rows for GitHub?**
- **Size:** Full crime dataset (40K rows) is 23MB → too large for free GitHub LFS
- **Representativeness:** Stratified sample maintains:
  - Temporal distribution (equal years)
  - Spatial distribution (proportional neighborhoods)
  - Crime type proportions
- **Reproducibility:** Allows code testing without full dataset download

**To obtain full dataset:** Contact author or pull from [Milwaukee Open Data Portal](https://data.milwaukee.gov).

---

*Data Dictionary Version 1.0 | Last Updated: February 2026*
