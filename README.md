# Healing Spaces ROI Analysis

Geospatial cost-benefit analysis quantifying the impact of urban greening initiatives on crime rates in Milwaukee, Wisconsin.

**Key Finding:** 2:1 return on investment. 15% reduction in violent crime density within 0.1 miles of healing space sites.

[Live Dashboard](https://anp4it-carterfike.shinyapps.io/cleanapp_backup/) | [LinkedIn](www.linkedin.com/in/carter-fike-870320226)

---

## Problem Statement

Milwaukee city planners needed data-driven evidence to justify $157,500 in funding for converting vacant lots into "healing spaces" (community gardens, peace parks, green spaces). This analysis quantifies both crime reduction and economic return on investment.

**Questions Addressed:**
1. Do healing spaces reduce local crime rates?
2. Is the effect statistically attributable to the intervention (vs. citywide trends)?
3. What is the economic ROI in avoided societal costs?

---

## Methodology

### Data Sources
- **Crime Incidents:** 882,915 records (Milwaukee Open Data Portal, 2018-2023)
- **Vacant Lots:** 2,142 properties (Milwaukee Assessor's Office)
- **Healing Spaces:** 15 sites (community partners + field verification)

### ETL Pipeline
Processed 882,915 raw crime records using custom Regex standardization and batch geocoding:

**Address Standardization:**
- Removed unit numbers, standardized street suffixes (e.g., "BL" → "BLVD")
- Converted intersection notation ("/" → "AND")
- Force-calibrated to Milwaukee ZIP codes to prevent geocoder mismatches

**Geocoding Strategy:**
- Primary: OpenStreetMap (free, good US coverage)
- Fallback: ArcGIS for failed addresses
- Manual fixes for 3 known problem locations (verified via field visits)
- Runtime: 48 hours on Marquette University server
- Success rate: 98.4% (40,687 of 40,000+ filtered records)

**Why It Mattered:**
- Inconsistent formats caused 15-20% failure rate before standardization
- Milwaukee addresses matched to Philadelphia/Chicago without ZIP forcing
- "BL" abbreviation alone accounted for 800+ geocoding failures

### Geospatial Analysis
**Coordinate System:** EPSG:3071 (Wisconsin State Plane) for accurate distance calculations
- Standard lat/long (EPSG:4326) creates distortion in buffer radii
- 0.1-mile buffer = exactly 160.9 meters in projected CRS

**Study Design:**
- **Treatment Group:** Harambee neighborhood (7 healing spaces installed 2021)
- **Control Group:** Lindsay Heights (matched demographics, no intervention)
- **Temporal Baseline:** 2018-2020 (pre) vs. 2021-2023 (post)
- **Buffer Analysis:** Crimes within 0.1 miles of healing spaces vs. outside buffers

### Statistical Approach
**Crime Density Calculation:**
```
Crimes per km² = Total Crimes / Area
```
Area-normalization accounts for unequal buffer vs. non-buffer zones.

**Difference-in-Differences:**
- Compared inside/outside buffers within Harambee
- Compared Harambee to Lindsay Heights (control for citywide trends)

---

## Results

### Crime Reduction
| Zone | Violent Crime Change | Property Crime Change |
|------|---------------------|----------------------|
| Inside Buffers (0.1 mi) | -15% | -8% |
| Outside Buffers (Harambee) | +2% | +1% |
| Lindsay Heights (Control) | +1% | +3% |

**Interpretation:** Crime reduction was hyperlocal to healing space sites, not a neighborhood-wide phenomenon.

### Cost-Benefit Analysis
**Investment:**
- 7 sites × $22,500 per site = $157,500 total
- Cost breakdown: land prep ($8,500), landscaping ($12,000), community engagement ($2,000)

**Savings (3-year period):**
- Assault: 12 fewer incidents × $12,600 = $151,200
- Robbery: 4 fewer incidents × $20,200 = $80,800
- Burglary: 9 fewer incidents × $6,020 = $54,180
- Vandalism: 5 fewer incidents × $6,070 = $30,350
- **Total:** $316,530

**ROI:** $316,530 / $157,500 = 2.01:1

**Note:** Homicides excluded from ROI calculation to avoid outlier skew (single homicide = $9.2M, would dominate mean).

---

## Technical Implementation

### Stack
- **Data Processing:** R (dplyr, tidyr, stringr, tidygeocoder)
- **Geospatial:** sf package (EPSG:3071 projection, spatial joins, buffer creation)
- **Visualization:** ggplot2 (crime density plots), leaflet (interactive maps)
- **Deployment:** Shiny (live dashboard on shinyapps.io)
- **Exploratory Analysis:** Tableau (initial crime hotspot identification)

### Repository Structure
```
milwaukee-healing-spaces-roi/
├── analysis/
│   ├── 01_data_cleaning_geocoding.R      # ETL pipeline
│   ├── 02_spatial_analysis.R              # Buffer creation, spatial joins
│   ├── 03_cost_benefit_model.R            # ROI calculations
│   └── 04_harambee_combined_analysis.R    # Neighborhood comparison
├── shiny-app/
│   ├── global.R                           # Pre-load data
│   ├── server.R                           # Backend logic
│   ├── ui.R                               # Frontend
│   └── www/                               # Images
├── data/
│   ├── sample_crime_data.csv              # 1,000-row sample
│   ├── healing_spaces.csv                 # 15 locations
│   ├── vacant_lots_sample.csv             # Top 100 by crime count
│   └── data_dictionary.md                 # Variable descriptions
├── visuals/
│   ├── crime_density_plot.png
│   ├── roi_breakdown.png
│   └── dashboard_screenshot.png
└── docs/
    └── methodology.md                     # Full technical writeup
```

---

## Interactive Dashboard

[**View Live Dashboard**](https://anp4it-carterfike.shinyapps.io/cleanapp_backup/)

Features:
- Crime heatmap (toggle violent/property, filter by year)
- 15 healing space locations with contact information
- Top 10 vacant lot candidates for future sites (ranked by nearby crime density)
- Community proposal submission form

---

## Key Insights

### For City Planners
- 0.1-mile radius captures maximum crime reduction effect
- Each $22,500 investment returns ~$45,000 in avoided costs over 3 years
- Vacant lot prioritization tool identifies optimal future sites

### For Policymakers
- Evidence-based alternative to enforcement-focused crime strategies
- Measurable economic benefit beyond community health/property value gains
- Scalable intervention (26 ZIP codes with high vacant lot density identified)

### For Researchers
- Demonstrates importance of projected CRS for buffer accuracy
- Matched-control design isolates treatment effect from citywide trends
- Full methodology documented for replication in other cities

---

## Limitations

**Data Quality:**
- 1.6% of crime incidents could not be geocoded (missing/invalid addresses)
- Crime data reflects reported incidents only (potential underreporting bias)
- Intersection addresses geocoded to centroid (50-100m spatial error)

**Causal Inference:**
- Assumes healing spaces caused crime reduction (not reverse causation)
- Mitigation: used control neighborhood + temporal baseline
- Cannot rule out unmeasured confounders (e.g., concurrent community programs)

**External Validity:**
- Results may not generalize to cities with different demographics, policing, or urban form
- Linear ROI assumption may not hold for 50+ sites (diminishing returns possible)

---

## Files & Data

**Sample Data:** 1,000-row crime sample, 100 vacant lots, 15 healing spaces (included in repo)

**Full Dataset:** 40,687 geocoded crime records available upon request (23MB, excluded from GitHub due to size)

**Source:** Milwaukee Open Data Portal (public domain)

---

## Contact

**Carter Fike**  
Email: your.email@example.com  
LinkedIn: [Your Profile](YOUR_LINKEDIN_URL)  
Portfolio: [yourwebsite.com](https://yourwebsite.com)

---

## License

MIT License - see LICENSE file for details

**Data:** Milwaukee Open Data Portal (Public Domain)  
**Analysis:** Original work by Carter Fike

---

## Acknowledgments

- Marquette University for server access (large-scale geocoding)
- Milwaukee Healing Spaces Initiative for community partnership
- FBI Uniform Crime Reporting for cost-of-crime statistics
