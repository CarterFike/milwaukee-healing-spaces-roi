# GitHub Portfolio Setup Checklist

## 🎯 Goal
Create a professional GitHub repository that showcases your Milwaukee Healing Spaces ROI project to entry-level Data Analyst recruiters.

---

## ✅ Step-by-Step Setup

### 1. Create Repository
```bash
# On GitHub.com:
1. Click "New Repository"
2. Name: milwaukee-healing-spaces-roi
3. Description: "Geospatial cost-benefit analysis: Do urban healing spaces reduce crime? 2:1 ROI proven. Built with R, Shiny, Tableau."
4. ✅ Public
5. ✅ Add README (we'll replace it)
6. ✅ Add .gitignore (choose "R" template)
7. ❌ Don't add license yet (we'll add MIT later)
```

### 2. Clone Locally
```bash
git clone https://github.com/YOUR_USERNAME/milwaukee-healing-spaces-roi.git
cd milwaukee-healing-spaces-roi
```

### 3. Folder Structure
Create this exact structure:
```
milwaukee-healing-spaces-roi/
├── README.md                    # ⭐ Main portfolio showcase
├── .gitignore                   # Excludes large files
├── LICENSE                      # MIT License
├── analysis/
│   ├── 01_data_cleaning.R
│   ├── 02_spatial_analysis.R
│   ├── 03_cost_benefit_model.R
│   ├── 04_visualization.R
│   └── harambee_combined_analysis.R
├── shiny-app/
│   ├── global.R
│   ├── server.R
│   ├── ui.R
│   └── www/
│       ├── bench.png
│       ├── med.png
│       ├── medbef.png
│       └── trail.png
├── data/
│   ├── sample_crime_data.csv         # 1K rows only!
│   ├── healing_spaces.csv
│   ├── vacant_lots_sample.csv
│   └── data_dictionary.md
├── visuals/
│   ├── crime_density_plot.png
│   ├── roi_breakdown.png
│   ├── dashboard_screenshot.png
│   └── map_screenshot.png
└── docs/
    └── methodology.md
```

### 4. Add Files

#### Essential Files (DO THIS FIRST)
```bash
# Copy from your downloads:
cp ~/Downloads/README.md .
cp ~/Downloads/methodology.md docs/
cp ~/Downloads/data_dictionary.md data/

# Your analysis scripts:
cp ~/COSC\ 5500/finalProject/Harambee_Analysis/harambee_combined_analysis.R analysis/

# Your Shiny app:
cp ~/COSC\ 5500/finalProject/CleanApp_Backup/global.R shiny-app/
cp ~/COSC\ 5500/finalProject/CleanApp_Backup/server.R shiny-app/
cp ~/COSC\ 5500/finalProject/CleanApp_Backup/ui.R shiny-app/
cp ~/COSC\ 5500/finalProject/CleanApp_Backup/www/* shiny-app/www/
```

#### Sample Data (IMPORTANT: Limit Size)
```r
# In RStudio, create small samples:

# 1. Crime data sample (1,000 rows)
setwd("~/COSC 5500/finalProject")
full_crime <- read.csv("final_crime_updated.csv")

set.seed(42)
sample_crime <- full_crime %>%
  group_by(ReportedYear, CrimeType) %>%
  slice_sample(n = 30) %>%  # 30 per year per type
  ungroup()

write.csv(sample_crime, 
          "~/milwaukee-healing-spaces-roi/data/sample_crime_data.csv", 
          row.names = FALSE)

# 2. Healing spaces (full dataset is tiny)
file.copy("HealingSpacesGeo.csv", 
          "~/milwaukee-healing-spaces-roi/data/healing_spaces.csv")

# 3. Vacant lots sample (top 100)
vacant <- read.csv("vacant_lots_geo_enriched.csv")
sample_vacant <- vacant %>%
  arrange(desc(CrimeCount_2023_Violent)) %>%
  slice_head(n = 100)

write.csv(sample_vacant,
          "~/milwaukee-healing-spaces-roi/data/vacant_lots_sample.csv",
          row.names = FALSE)
```

### 5. Create Visualizations

#### Export from R
```r
# Crime density plot
png("~/milwaukee-healing-spaces-roi/visuals/crime_density_plot.png", 
    width = 1200, height = 800, res = 150)
# [paste your ggplot code here]
dev.off()

# ROI breakdown
png("~/milwaukee-healing-spaces-roi/visuals/roi_breakdown.png", 
    width = 1200, height = 600, res = 150)
# [paste your cost-benefit table visualization]
dev.off()
```

#### Screenshots
1. **Dashboard:** 
   - Open https://anp4it-carterfike.shinyapps.io/cleanapp_backup/
   - Screenshot the main map view
   - Save as `visuals/dashboard_screenshot.png`

2. **Interactive Map:**
   - Zoom to Harambee with healing spaces visible
   - Screenshot
   - Save as `visuals/map_screenshot.png`

### 6. Update README Placeholders

Edit `README.md` and replace:
- `YOUR_LINKEDIN_URL` → Your actual LinkedIn profile
- `your.email@example.com` → Your email
- `[Your Name]` → Your full name
- All image paths: Verify they match your `/visuals/` folder

### 7. Add MIT License
```bash
# Create LICENSE file
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
```

### 8. Commit & Push
```bash
# Check what you're adding
git status

# Add all files
git add .

# Commit with professional message
git commit -m "Initial commit: Milwaukee Healing Spaces ROI analysis

- Add geospatial crime analysis (40K records processed)
- Include cost-benefit model (2:1 ROI demonstrated)
- Deploy Shiny dashboard with interactive crime heatmap
- Document methodology & data dictionary"

# Push to GitHub
git push origin main
```

---

## 🎨 Make It Pretty

### Repository Settings

1. **About Section** (top-right on GitHub repo page):
   ```
   Website: https://anp4it-carterfike.shinyapps.io/cleanapp_backup/
   Topics: data-analysis, geospatial, r-shiny, cost-benefit-analysis, 
           urban-planning, public-policy
   ```

2. **Pin Repository:**
   - Go to your GitHub profile
   - Click "Customize your pins"
   - Select this repo (shows up first to visitors!)

3. **Social Preview Image:**
   - Settings → Social Preview → Upload Image
   - Use `visuals/dashboard_screenshot.png`

---

## 📣 Promotion Strategy

### LinkedIn Post Template
```
🌳 New Project: Can urban greening reduce crime AND save taxpayer money?

I analyzed 40,000+ crime incidents in Milwaukee to prove healing spaces 
deliver a 2:1 return on investment—$315K saved for just 7 sites.

Key skills demonstrated:
✅ Geospatial analysis (R + sf package)
✅ ETL at scale (40K+ addresses geocoded)
✅ Cost-benefit modeling
✅ Interactive dashboards (Shiny)

Live demo: [your shinyapps.io URL]
Code: [your GitHub URL]

#DataAnalysis #Geospatial #PublicPolicy #RStats #UrbanPlanning

[Tag any Milwaukee organizations, R communities, or data science groups]
```

### Resume Bullet Points
```
📊 Milwaukee Healing Spaces ROI Analysis
• Processed 40,000+ crime records using R (dplyr, sf) and batch geocoding 
  via university server, achieving 98% success rate
• Quantified 15% crime reduction near urban greening sites through geospatial 
  buffer analysis (EPSG:3071 projection)
• Calculated 2:1 benefit-cost ratio ($315K savings vs. $158K investment) 
  using FBI crime cost data
• Deployed interactive Shiny dashboard with Leaflet heatmaps for stakeholder 
  decision-making

Tech: R, Shiny, Tableau, sf (geospatial), ggplot2, tidygeocoder
Live Demo: [shinyapps.io URL] | Code: [GitHub URL]
```

---

## ✨ Quality Checklist

Before sharing with recruiters, verify:

- [ ] README renders perfectly on GitHub (check images display)
- [ ] All links work (Shiny app, LinkedIn, email)
- [ ] Sample data files are < 5MB each (check file sizes)
- [ ] Code is commented & readable
- [ ] No hardcoded file paths (use relative paths like `data/`)
- [ ] .gitignore excludes large files (full crime CSV)
- [ ] Repository is Public (not Private)
- [ ] No sensitive info (API keys, personal addresses)
- [ ] Visuals are high-resolution (not blurry screenshots)
- [ ] Methodology doc is technically accurate

---

## 🚀 Next Steps

1. **Test Locally:**
   ```bash
   # Can someone else clone and run your code?
   git clone [your repo URL]
   cd milwaukee-healing-spaces-roi
   # Try running analysis/harambee_combined_analysis.R
   ```

2. **Get Feedback:**
   - Share with a mentor/peer
   - Ask: "Is the README clear?" "Would you hire this person?"

3. **Apply to Jobs:**
   - Include GitHub link in resume
   - Reference in cover letters: "See my Milwaukee crime analysis for 
     geospatial skills demonstration"

4. **Keep Building:**
   - Add projects every 2-3 months
   - Show progression in complexity
   - Document everything!

---

## 📚 Resources

- [GitHub README Best Practices](https://github.com/matiassingers/awesome-readme)
- [Data Science Portfolio Guide](https://towardsdatascience.com/how-to-build-a-data-science-portfolio-5f566517c79c)
- [Shiny Gallery](https://shiny.rstudio.com/gallery/) (for inspiration)

---

**Questions?** DM me on LinkedIn: [your profile]

*Good luck on your job search! 🎉*
