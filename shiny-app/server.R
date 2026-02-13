# server.R
# Optimized version - all data loading moved to global.R

server <- function(input, output) {
  
  # Healing spaces reactive - uses pre-loaded data from global.R
  healing_spaces <- reactive({
    healing_spaces_data %>%
      mutate(
        popup_content = paste0(
          "<div style='min-width:250px'>",
          "<h4 style='margin:0;color:#2c7bb6'>", Name, "</h4>",
          "<hr style='margin:5px 0'>",
          "<p style='margin:2px 0'><strong>Address:</strong> ", Address, "</p>",
          "<p style='margin:2px 0'><strong>Neighborhood:</strong> ", Neighborhood, "</p>",
          ifelse(!is.na(Garden.Leader),
                 paste0("<p style='margin:2px 0'><strong>Managed by:</strong> ", Garden.Leader, "</p>"), ""),
          ifelse(!is.na(Organization.URL),
                 paste0("<a href='", Organization.URL, "' target='_blank' style='display:block;margin:5px 0'>Visit Organization Website</a>"), ""),
          ifelse(!is.na(Contact.Name),
                 paste0(
                   "<div style='margin-top:8px;border-top:1px solid #eee;padding-top:5px'>",
                   "<p style='margin:3px 0'><strong>Contact:</strong> ", Contact.Name, "</p>",
                   ifelse(!is.na(Contact.Phone), paste0("<p style='margin:3px 0'><strong>Phone:</strong> ", Contact.Phone, "</p>"), ""),
                   ifelse(!is.na(Contact.Email), paste0("<p style='margin:3px 0'><strong>Email:</strong> ", Contact.Email, "</p>"), ""),
                   "</div>"
                 ), ""),
          "</div>"
        )
      )
  })
  
  # Filtered crime data - uses pre-loaded and pre-filtered data
  crime_data <- reactive({
    req(input$crime_type, input$years)
    final_crime_updated %>%
      filter(
        ReportedYear >= input$years[1],
        ReportedYear <= input$years[2],
        Category == input$crime_type
      )
  })
  
  # Base map
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -87.9065, lat = 43.0389, zoom = 11) %>%
      addScaleBar() %>%
      addLayersControl(
        overlayGroups = c("Crime Heatmap", "Healing Spaces", "Vacant Lots"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
  
  # Dynamic layers
  observe({
    crime <- crime_data()
    healing <- healing_spaces()
    proxy <- leafletProxy("map", data = crime)
    
    # Clear existing layers
    proxy %>%
      clearGroup("Crime Heatmap") %>%
      clearGroup("Healing Spaces") %>%
      clearGroup("Vacant Lots")
    
    # Add crime heatmap if selected
    if(input$show_heat && nrow(crime) > 0) {
      proxy %>%
        addHeatmap(
          group = "Crime Heatmap",
          lng = ~long, lat = ~lat,
          intensity = 0.8,
          radius = 18,
          blur = 22,
          gradient = colorNumeric(palette = c("blue", "yellow", "red"), domain = NULL),
          max = 1
        )
    }
    
    # Add healing spaces if selected
    if(input$show_healing && nrow(healing) > 0) {
      proxy %>%
        addMarkers(
          data = healing,
          lng = ~long, lat = ~lat,
          group = "Healing Spaces",
          popup = ~popup_content,
          icon = makeIcon(
            iconUrl = "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png",
            shadowUrl = "https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png",
            iconWidth = 25, iconHeight = 41,
            iconAnchorX = 12, iconAnchorY = 41,
            shadowWidth = 41, shadowHeight = 41
          )
        )
    }
    
    # Add vacant lots if selected
    if (input$show_vacant) {
      try({
        # Filter top 10 based on selected crime type
        top_lots <- vacant_lots_enriched %>%
          mutate(
            CrimeCount = case_when(
              input$crime_type == "Violent" ~ CrimeCount_2023_Violent,
              input$crime_type == "Property" ~ CrimeCount_2023_Property,
              TRUE ~ NA_real_
            ),
            CrimeCount = replace_na(CrimeCount, 0)
          ) %>%
          filter(CrimeCount > 0) %>%
          arrange(desc(CrimeCount)) %>%
          slice_head(n = 10)
        
        if(nrow(top_lots) > 0) {
          proxy %>%
            addMarkers(
              data = top_lots,
              lng = ~long, lat = ~lat,
              group = "Vacant Lots",
              popup = ~paste0(
                "<b>Address:</b> ", ADDRFULLLINE, "<br>",
                "<b>Date Opened:</b> ", DATEOPENED, "<br>",
                "<b>Value:</b> $", formatC(VALUEIMPROVED, format = "f", big.mark = ",", digits = 0), "<br>",
                "<b>2023 ", input$crime_type, " Crimes (0.1mi):</b> ", CrimeCount
              ),
              icon = makeIcon(
                iconUrl = "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png",
                shadowUrl = "https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png",
                iconWidth = 25, iconHeight = 41,
                iconAnchorX = 12, iconAnchorY = 41,
                shadowWidth = 41, shadowHeight = 41
              )
            )
        }
      })
    }
    
    # Toggle layer visibility
    proxy <- proxy %>%
      {if(input$show_heat) showGroup(., "Crime Heatmap") else hideGroup(., "Crime Heatmap")} %>%
      {if(input$show_healing) showGroup(., "Healing Spaces") else hideGroup(., "Healing Spaces")} %>%
      {if(input$show_vacant) showGroup(., "Vacant Lots") else hideGroup(., "Vacant Lots")}
  })
  
  # Vacant lots table
  output$vacant_table <- renderDT({
    req(input$show_vacant)
    
    # Filter top 10 vacant lots based on selected crime type
    top_lots <- vacant_lots_enriched %>%
      mutate(
        CrimeCount = case_when(
          input$crime_type == "Violent" ~ CrimeCount_2023_Violent,
          input$crime_type == "Property" ~ CrimeCount_2023_Property,
          TRUE ~ NA_real_
        ),
        CrimeCount = replace_na(CrimeCount, 0)
      ) %>%
      filter(CrimeCount > 0) %>%
      arrange(desc(CrimeCount)) %>%
      slice_head(n = 10)
    
    datatable(
      top_lots %>%
        transmute(
          Address = ADDRFULLLINE,
          `2023 Crime Count (0.1 mi)` = CrimeCount
        ),
      options = list(
        pageLength = 10,
        dom = 't',
        scrollX = TRUE
      )
    )
  })
  
  
  # Stats tab: Detailed Crime Breakdown Table
  # OPTIMIZED: Uses pre-converted spatial data from global.R
  output$stats_table <- renderDT({
    req(input$selected_space, healing_spaces())
    
    # Define radius and costs
    radius_meters <- 805
    crime_costs <- tribble(
      ~Crime_Detail, ~Cost,
      "Rape/Sexual Assault", 38600,
      "Aggravated Assault", 12600,
      "Robbery", 20200,
      "Burglary", 6020,
      "Arson", 6400,
      "Vandalism", 6070
    )
    
    # Selected healing space - convert to sf
    selected_space <- healing_spaces() %>%
      filter(Name == input$selected_space) %>%
      st_as_sf(coords = c("long", "lat"), crs = 4326)
    
    # Create buffer around selected space
    buffer <- st_buffer(selected_space, radius_meters)
    
    # Use PRE-CONVERTED spatial crime data from global.R
    crimes_near <- st_join(crimes_sf_2021_2023, buffer) %>%
      st_drop_geometry() %>%
      filter(!is.na(Name), !is.na(Crime_Detail)) %>%
      group_by(ReportedYear, Crime_Detail) %>%
      summarise(Count = n(), .groups = "drop") %>%
      pivot_wider(names_from = ReportedYear, values_from = Count, values_fill = 0)
    
    # Calculate financial impacts
    if(all(c("2021", "2022", "2023") %in% names(crimes_near))) {
      results <- crimes_near %>%
        left_join(crime_costs, by = "Crime_Detail") %>%
        mutate(
          change_2022 = `2022` - `2021`,
          change_2023 = `2023` - `2021`,
          impact_2022 = -change_2022 * Cost,
          impact_2023 = -change_2023 * Cost,
          total_impact = impact_2022 + impact_2023,
          Financial_Impact = case_when(
            is.na(total_impact) ~ "$0",
            total_impact > 0 ~ paste0("+$", format(round(total_impact/1000), big.mark = ",", trim = TRUE), "K 🟢"),
            total_impact < 0 ~ paste0("-$", format(round(abs(total_impact)/1000), big.mark = ",", trim = TRUE), "K 🔴"),
            TRUE ~ "$0"
          )
        ) %>%
        arrange(factor(Crime_Detail, levels = crime_costs$Crime_Detail)) %>%
        select(`Crime Type` = Crime_Detail, `2021 (Baseline)` = `2021`, `2022`, `2023`, Financial_Impact, total_impact)
      
      # Total row
      total_impact_value <- sum(results$total_impact, na.rm = TRUE)
      total_row <- tibble(
        `Crime Type` = "TOTAL",
        `2021 (Baseline)` = sum(results$`2021 (Baseline)`, na.rm = TRUE),
        `2022` = sum(results$`2022`, na.rm = TRUE),
        `2023` = sum(results$`2023`, na.rm = TRUE),
        Financial_Impact = ifelse(
          total_impact_value >= 0,
          paste0("+$", format(round(total_impact_value/1000), big.mark = ",", trim = TRUE), "K 🔵"),
          paste0("-$", format(round(abs(total_impact_value)/1000), big.mark = ",", trim = TRUE), "K 🔴")
        ),
        total_impact = total_impact_value
      )
      
      results <- bind_rows(
        results %>% select(-total_impact),
        total_row %>% select(-total_impact)
      )
    } else {
      results <- tibble(
        `Crime Type` = "No data available",
        `2021 (Baseline)` = NA,
        `2022` = NA,
        `2023` = NA,
        Financial_Impact = NA
      )
    }
    
    # Render datatable
    datatable(
      results,
      options = list(dom = 't', pageLength = nrow(results), scrollX = TRUE)
    ) %>%
      formatStyle(
        'Financial_Impact',
        backgroundColor = styleEqual(
          levels = c(
            grep("🟢", results$Financial_Impact, value = TRUE),
            grep("🔴", results$Financial_Impact, value = TRUE),
            grep("🔵", results$Financial_Impact, value = TRUE)
          ),
          values = c(
            rep("rgba(0,200,0,0.1)", length(grep("🟢", results$Financial_Impact, value = TRUE))),
            rep("rgba(200,0,0,0.1)", length(grep("🔴", results$Financial_Impact, value = TRUE))),
            rep("rgba(0,0,200,0.1)", length(grep("🔵", results$Financial_Impact, value = TRUE)))
          )
        )
      )
  })
  
  
  # Stats Tab plot
  # OPTIMIZED: Uses pre-converted spatial data from global.R
  output$stats_plot <- renderPlot({
    req(healing_spaces())
    radius_meters <- 805
    selected_space <- healing_spaces() %>% filter(Name == input$selected_space)
    
    # Filter by crime type if not "All"
    crimes_for_plot <- crimes_sf_full_range
    if(input$crime_type_stats != "All") {
      crimes_for_plot <- crimes_for_plot %>% filter(Category == input$crime_type_stats)
    }
    
    # Convert selected space to sf and create buffer
    space_sf <- st_as_sf(selected_space, coords = c("long", "lat"), crs = 4326)
    buffer <- st_buffer(space_sf, dist = radius_meters)
    
    # Find crimes within buffer
    crimes_near <- st_join(crimes_for_plot, buffer) %>%
      filter(!is.na(Name)) %>%
      group_by(ReportedYear, Category) %>%
      summarise(Count = n(), .groups = "drop")
    
    ggplot(crimes_near, aes(x = ReportedYear, y = Count, color = Category)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_x_continuous(breaks = 2018:2023) +
      scale_color_manual(values = c("Violent" = "#e41a1c", "Property" = "#377eb8")) +
      labs(
        title = paste("Crime Trends Near", input$selected_space),
        subtitle = "0.5 Mile Radius | 2018-2023",
        x = "Year", y = "Crime Count"
      ) +
      theme_minimal()
  })
  
  # Table title
  output$table_title <- renderText({
    paste("Crime Breakdown (0.5 mile radius):", input$selected_space)
  })
  
  # Proposal submission
  observeEvent(input$submit_btn, {
    req(input$submit_name, input$submit_email, input$submit_location, input$submit_description)
    
    proposal <- data.frame(
      Name = input$submit_name,
      Email = input$submit_email,
      Location = input$submit_location,
      Description = input$submit_description,
      Timestamp = Sys.time()
    )
    
    write.table(
      proposal,
      "submissions.csv",
      sep = ",",
      row.names = FALSE,
      col.names = !file.exists("submissions.csv"),
      append = TRUE
    )
    
    output$submit_status <- renderText("✅ Proposal submitted successfully. Thank you!")
  })
}
