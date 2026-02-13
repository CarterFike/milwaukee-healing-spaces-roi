# Healing Spaces ROI Analysis

Geospatial cost-benefit analysis quantifying the impact of urban greening initiatives on crime rates in Milwaukee, Wisconsin.

**Key Finding:** 2:1 return on investment. 10.3% reduction in violent crime density within 0.1 miles of healing space sites.

[Live Dashboard](https://anp4it-carterfike.shinyapps.io/cleanapp_backup/) | [LinkedIn](https://www.linkedin.com/in/carter-fike-870320226)

---

## Problem Statement

Milwaukee city planners needed data-driven evidence to justify $180,000 in funding for converting vacant lots into "healing spaces" (community gardens, peace parks, green spaces). This analysis quantifies both crime reduction and economic return on investment.

**Research Question:** Do healing spaces reduce local crime rates in the immediate vicinity, and what is the economic ROI in avoided societal costs?

---

## Methodology

### Data Sources
- **Crime Incidents:** 882,915 records (Milwaukee Open Data Portal, 2018-2023)
- **Vacant Lots:** 3,241 properties (Milwaukee Assessor's Office)
- **Healing Spaces:** 15 sites citywide, 8 in Harambee study area (community partners + field verification)
- **Demographics:** U.S. Census Bureau (2022 ACS 5-year estimates)

### ETL Pipeline

**Scale:** 882,915 raw crime records → 129,617 analysis-ready incidents (2018-2023, index crimes) → 58,408 unique addresses geocoded

**Challenge:** Inconsistent address formats required custom cleaning before geocoding.

**Address Standardization (Custom Regex):**
- Removed unit numbers (#2A, #APT-5)
- Standardized street suffixes: "BL" → "BLVD", "STREET" → "ST"
- Converted intersection notation: "/" and "&" → "AND"
- Added "Milwaukee, WI" context to intersections to prevent geocoder mismatches

**Geocoding Strategy:**
- Geocoded 58,408 unique addresses (many crime incidents share the same location)
- Primary: OpenStreetMap (free tier)
- Fallback: ArcGIS for failed addresses
- Manual corrections: 3 healing space locations verified via field visits
- Force-calibrated to Milwaukee ZIP codes to prevent matching to Philadelphia/Chicago
- Runtime: 48+ hours on Marquette University server
- **Final success rate: 97.4%** (~56,900 addresses successfully geocoded)

**Filtered Dataset:**
- 882,915 raw records → 129,617 analysis-ready incidents (2018-2023, index crimes only)
- Excluded: traffic violations, ordinance violations, non-index offenses

### Geospatial Analysis

**Coordinate System:** EPSG:3071 (Wisconsin State Plane, meters)
- Standard lat/long (EPSG:4326) creates distortion in buffer radii
- 0.1-mile buffer = exactly 160.9 meters in projected CRS

**Study Design:**
- **Study Area:** Harambee neighborhood (8 healing spaces)
- **Control Zones:** Crimes outside 0.1-mile buffers within same neighborhood
- **Temporal Baseline:** 2021 used as intervention point based on Milwaukee Healing Spaces Initiative launch date (January 2021, per Milwaukee DCD). Exact construction dates for individual sites unavailable; analysis assumes sites were operational during 2021-2023 period.
- **Buffer Analysis:** Spatial join to classify crimes inside vs. outside 0.1-mile radius

**Why This Design Works:**
- Inside/outside buffer comparison controls for citywide crime trends
- If crime dropped everywhere, it would drop outside buffers too
- Crime stayed flat/increased outside buffers while dropping inside

### Statistical Approach

**Crime Density Calculation:**
```
Crimes per km² = Total Crimes / Area
```
Area-normalization accounts for unequal buffer vs. non-buffer zones (buffer zone = 0.623 km², non-buffer = 2.517 km²).

---

## Results

### Crime Reduction (Harambee Neighborhood)

| Zone | Violent Crime Change | Property Crime Change |
|------|---------------------|----------------------|
| Inside Buffers (0.1 mi) | -10.3% | -15.4% |
| Outside Buffers | +18.4% | +0.5% |

**Interpretation:** Crime reduction was hyperlocal to healing space sites. The rest of Harambee saw violent crime increase 18.4%, suggesting the effect is attributable to the intervention rather than neighborhood-wide trends.

**Raw Numbers:**
- Inside buffers: 233 → 209 violent crimes (Pre → Post)
- Outside buffers: 1,020 → 1,208 violent crimes (Pre → Post)

### Cost-Benefit Analysis

**Investment:**
- 8 sites × $22,500 per site = $180,000 total
- Cost source: Milwaukee Department of City Development RFP #58004 (2024)

**Savings Calculation (3-year period, 2021-2023):**

Crime reductions inside 0.1-mile buffers:
- Assault: 4 fewer incidents × $12,600 = $50,400
- Robbery: 15 fewer incidents × $20,200 = $303,000
- Burglary: 16 fewer incidents × $6,020 = $96,320
- Vandalism: -14 incidents (increase) × $6,070 = -$84,980
- **Total:** $364,740

**Cost Basis:** FBI "Victim Costs and Consequences" (2008), criminal justice system costs only, CPI-adjusted to 2024 dollars using 46% inflation rate.

**ROI:** $364,740 / $180,000 = **2.03:1**

**Homicide Exclusion:** 8 homicides occurred inside buffer zones Pre-2021, zero Post-2021. However, homicides were excluded from ROI calculation for the following reasons:

1. **Small sample size:** n=8 is insufficient to attribute reduction to intervention with statistical confidence
2. **Outlier effect:** Single homicide cost ($1.2M) would represent 96% of total calculated savings, masking the effects of more common crimes
3. **Weak causal mechanism:** Homicides typically involve targeted/domestic violence; the causal link to healing spaces is theoretically weak compared to crimes of opportunity (assault, burglary, vandalism)

Excluding homicides provides a more conservative and defensible ROI estimate focused on crime types with clearer causal mechanisms.

---

## Technical Implementation

### Stack
- **Data Processing:** R (dplyr, tidyr, stringr, tidygeocoder)
- **Geospatial:** sf package (EPSG:3071 projection, spatial joins, buffer creation)
- **Visualization:** ggplot2 (crime density plots), leaflet (interactive maps)
- **Deployment:** Shiny (live dashboard on shinyapps.io)

### Repository Structure
```
milwaukee-healing-spaces-roi/
├── analysis/
│   ├── 01_data_cleaning_geocoding.R      # ETL pipeline
│   └── harambee_combined_analysis.R      # Spatial analysis + ROI
├── shiny-app/
│   ├── global.R                          # Pre-load data
│   ├── server.R                          # Backend logic
│   ├── ui.R                              # Frontend
│   └── www/                              # Images
├── data/
│   ├── sample_crime_data.csv             # 1,000-row sample
│   ├── healing_spaces.csv                # 15 locations
│   ├── vacant_lots_sample.csv            # Top 100 by crime count
│   └── data_dictionary.md                # Variable descriptions
├── visuals/
│   ├── crime_density_plot.png
│   ├── roi_breakdown.png
│   └── dashboard_screenshot.png
└── docs/
    └── methodology.md                    # Full technical writeup
```

---

## Interactive Dashboard

[**View Live Dashboard**](https://anp4it-carterfike.shinyapps.io/cleanapp_backup/)

Features:
- Crime heatmap (2018-2023, toggle violent/property crimes)
- 8 Harambee healing space locations with contact information
- Top 10 vacant lot candidates for future sites (ranked by nearby crime density)
- Community proposal submission form

---

## Key Insights

### For City Planners
- 0.1-mile radius captures maximum crime reduction effect
- Each $22,500 investment returns ~$45,000 in avoided costs over 3 years
- Effect is hyperlocal - benefits concentrate within immediate walking distance

### For Policymakers
- Evidence-based alternative to enforcement-focused crime strategies
- Measurable economic benefit beyond community health/property value gains
- Scalable intervention (26 ZIP codes with high vacant lot density identified)

### For Researchers
- Demonstrates importance of projected CRS (EPSG:3071) for buffer accuracy
- Inside/outside buffer comparison isolates treatment effect from citywide trends
- Full methodology documented for replication in other cities

---

## Limitations

**Data Quality:**
- 2.6% of crime incidents could not be geocoded (missing/invalid addresses)
- Crime data reflects reported incidents only (potential underreporting bias)
- Intersection addresses geocoded to centroid (50-100m spatial error)

**Causal Inference:**
- Assumes healing spaces caused crime reduction (not reverse causation)
- Mitigation: control zones show crime increased outside buffers
- Cannot rule out unmeasured confounders (concurrent community programs)

**Temporal:**
- Post-intervention period is only 3 years (2021-2023)
- Individual healing space construction dates unknown; analysis uses 2021 initiative launch date as baseline, which may misclassify some pre-intervention crime if sites were built later in 2021-2023
- Long-term persistence of effects unknown

**External Validity:**
- Results may not generalize to cities with different demographics, policing, or urban form
- Linear ROI assumption may not hold for 50+ sites (diminishing returns possible)

---

## Files & Data

**Sample Data:** 1,000-row crime sample, 100 vacant lots, 15 healing spaces (included in repository)

**Full Dataset:** 129,617 geocoded crime records available upon request (full dataset excluded from GitHub due to size)

**Source:** Milwaukee Open Data Portal (public domain)

---

## Contact

**Carter Fike**  
Email: carterfike@outlook.com  
LinkedIn: [Your Profile](https://www.linkedin.com/in/carter-fike-870320226)

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
- Milwaukee Department of City Development for funding documentation