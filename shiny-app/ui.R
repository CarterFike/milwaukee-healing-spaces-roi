# ui.R
# Optimized version - uses pre-loaded data from global.R

ui <- navbarPage(
  title = "Crime Heatmap",
  
  tabPanel(
    "Home",
    fluidPage(
      titlePanel("Welcome to the Milwaukee Crime & Healing Spaces Dashboard"),
      
      fluidRow(
        column(
          8,
          h3("Project Overview"),
          p("This interactive dashboard explores the impact of community healing spaces on crime rates in Milwaukee neighborhoods from 2018 to 2023."),
          p("Use the tabs to navigate through visual crime data, evaluate proximity-based trends, and see how these spaces may contribute to neighborhood well-being."),
          br(),
          
          h4("How to Use This Dashboard"),
          tags$ul(
            tags$li("🗺️ 'Map': View crime heatmaps and healing space locations."),
            tags$li("📊 'Stats': Explore trends and potential cost savings near each healing space."),
            tags$li("📥 'Submit': Provide feedback or proposals.")
          ),
          br(),
          
          h4("What is a Healing Space?"),
          p("Healing spaces are grassroots community areas designed for rest, reflection, and connection. These parks have been implemented in neighborhoods like Harambee to support healing and reduce trauma."),
          br(),
          
          h4("Meditation Meadow (Before & After)"),
          fluidRow(
            column(
              6,
              img(src = "medbef.png", width = "100%", height = "250px",
                  style = "object-fit: cover; border-radius:8px; box-shadow:0px 0px 8px rgba(0,0,0,0.1);"),
              p(em("Before"))
            ),
            column(
              6,
              img(src = "med.png", width = "100%", height = "250px",
                  style = "object-fit: cover; border-radius:8px; box-shadow:0px 0px 8px rgba(0,0,0,0.1);"),
              p(em("After"))
            )
          )
        ),
        
        column(
          4,
          h4("Example Healing Spaces"),
          img(src = "bench.png", width = "100%", height = "250px",
              style = "margin-bottom:10px;border-radius:8px;box-shadow:0px 0px 8px rgba(0,0,0,0.1);"),
          p(em("Polonia Peace Park")),
          img(src = "trail.png", width = "100%", height = "250px",
              style = "margin-bottom:10px;border-radius:8px;box-shadow:0px 0px 8px rgba(0,0,0,0.1);"),
          p(em("Tranquility on the Trail"))
        )
      )
    )
  ),
  
  tabPanel(
    "Map",
    sidebarLayout(
      sidebarPanel(
        checkboxInput("show_heat", "Show Crime Density", value = TRUE),
        checkboxInput("show_healing", "Show Healing Spaces", value = TRUE),
        checkboxInput("show_vacant", "Show Vacant Lot Candidates", value = TRUE),
        selectInput("crime_type", "Crime Category:", choices = c("Violent", "Property"), selected = "Violent"),
        sliderInput("years", "Select Years:", min = 2018, max = 2023, value = c(2021, 2023)),
        DTOutput("vacant_table")
      ),
      mainPanel(
        leafletOutput("map", height = "600px")
      )
    )
  ),
  
  tabPanel(
    "Stats",
    sidebarLayout(
      sidebarPanel(
        # OPTIMIZED: Uses pre-loaded data from global.R instead of reading CSV
        selectInput("selected_space", "Select Healing Space:",
                    choices = unique(healing_spaces_data$Name)),
        radioButtons("crime_type_stats", "Crime Type:", choices = c("All", "Violent", "Property"), selected = "All")
      ),
      mainPanel(
        h4(textOutput("table_title")),
        DTOutput("stats_table"),
        plotOutput("stats_plot", height = "400px")
      )
    )
  ),
  
  tabPanel(
    "Submit",
    fluidPage(
      titlePanel("Submit a Healing Space Proposal"),
      fluidRow(
        column(
          6,
          textInput("submit_name", "Your Name"),
          textInput("submit_email", "Your Email"),
          textInput("submit_location", "Proposed Location or Address"),
          textAreaInput("submit_description", "Description", rows = 5),
          actionButton("submit_btn", "Submit Proposal", class = "btn-primary"),
          br(),
          br(),
          textOutput("submit_status")
        )
      )
    )
  )
)
