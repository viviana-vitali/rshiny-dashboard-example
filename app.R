library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(tidyr)

source("ausiliary_functions.R", local = TRUE)

# Define the list of EU countries
eu_country_codes <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", 
                      "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", 
                      "PL", "PT", "RO", "SK", "SI", "ES", "SE")

eu_countries <- c("Austria", "Belgium", "Bulgaria", "Croatia", "Cyprus", "Czech Republic", 
                  "Denmark", "Estonia", "Finland", "France", "Germany", "Greece", 
                  "Hungary", "Ireland", "Italy", "Latvia", "Lithuania", "Luxembourg", 
                  "Malta", "Netherlands", "Poland", "Portugal", "Romania", 
                  "Slovakia", "Slovenia", "Spain", "Sweden")

# Cache for data from extract_data.R
cached_data <- NULL  # Declare a global variable to store the data

ui <- page_fluid(
  tags$head(
    tags$style(HTML("
      .centered-box {
        display: flex;
        justify-content: center;
        width: 100%;
        align-items: center;
        min-height: 100vh;
        padding: 2rem;
        background-color: #f8f9fa;
      }
      .settings-card {
        width: 100%;
        max-width: 600px;
        margin: auto;
      }
      .settings-button-container {
        position: fixed;
        top: 30px; /* Position adjustment */
        right: 10px; /* Position adjustment */
        z-index: 1000;
        padding: 2px; /* Reduce padding to make the container smaller */
        margin: 0; /* Remove extra margin */
        width: auto; /* Allow the container to shrink based on content */
        height: auto; /* Let the height adjust dynamically */
        display: flex;
        gap: 10px;
      }

      .tabs-container {
        margin-top: -10px; /* Move tabs upwards slightly */
        display: flex;
        align-items: center;
        justify-content: flex-start;
        border-bottom: 1px solid #ddd;
        padding: 5px 20px;
      }
      .tab-item {
        margin-right: 15px; /* Space between tabs */
        font-size: 1rem;
        font-weight: bold;
        color: #007bff;
        cursor: pointer;
      }
      .tab-item.active {
        text-decoration: underline;
      }
      .input-description {
        color: #6c757d;
        font-size: 0.875rem;
        margin-top: 0.25rem;
        margin-bottom: 1rem;
      }
      .input-container {
        margin-bottom: 1rem;
      }
      .value-box {
        cursor: pointer;
        background-color: #f5f5f5 !important; /* Very light grey background Pastel Pink: #fce4ec, Pastel Blue: #d1ecf1*/
        border: 2px solid #ccc; /* Grey border */
        width: 250px !important;
        height: 150px !important;
        margin: 10px !important;
        padding: 1rem; /* Adjust padding as needed */
        border-radius: 0.5rem; /* Soft rounded corners */
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); /* Subtle shadow for depth */
      }
      .value-box:hover {
        transform: scale(1.02);
        transition: transform 0.2s;
      }
      .value-box .value-box-title {
        font-size: 1.75rem !important;
        margin-top: 0.5rem !important;
      }
      .value-box .value-box-value {
        font-size: 1rem !important;
        margin-bottom: 0.5rem !important;
      }
      .country-grid {
        display: flex;
        flex-wrap: wrap;
        justify-content: flex-start;
        gap: 10px;
      }
      .full-screen-content {
        width: 100%;
        padding: 2rem;
      }
      .modal-dialog {
        max-width: 600px;
      }

    "))
  ),
  
  # Settings button container
  conditionalPanel(
    condition = "input.submit_settings",
    div(
      class = "settings-button-container",
      actionButton(
        "show_time_settings",
        "Change Time Period",
        class = "btn-primary",
        icon = icon("calendar")
      ),
      actionButton(
        "show_threshold_settings",
        "Change Threshold",
        class = "btn-warning",
        icon = icon("chart-line")
      )
    )
  ),
  
  # Render either the settings or the full-screen dashboard
  uiOutput("main_content")
)


server <- function(input, output, session) {
  # Initial parameters
  time_settings <- reactiveValues(
    latest_period = "2026M04",
    period_start = "2026-06-19 11:00:00",
    period_end = "2026-07-15 11:00:00"
  )
  
  threshold_settings <- reactiveValues(
    growth_threshold = 0.1
  )
  
  # Step 2: Handle the settings submission
  settings_submitted <- reactiveVal(FALSE)
  
  # Step 1: Cache the output of new_extraction_data_outliers.R (l_transmission and l_outliers lists)
  l_transmission_cache <- reactiveVal(NULL)
  l_outliers_cache <- reactiveVal(NULL)
  
  
  # Add a reactive value to store the selected country
  selected_country_rv <- reactiveVal(NULL)
  
  # Handle initial settings submission
  observeEvent(input$submit_settings, {
    # Store initial settings
    time_settings$latest_period <- input$latest_period
    time_settings$period_start <- input$period_start
    time_settings$period_end <- input$period_end
    threshold_settings$growth_threshold <- input$growth_threshold
    
    settings_submitted(TRUE)
    
  })
  
  # Time period settings modal
  observeEvent(input$show_time_settings, {
    showModal(modalDialog(
      title = "Time Period Settings",
      textInput(
        "latest_period_modal",
        "Latest Period",
        value = time_settings$latest_period,
        placeholder = "e.g., 2026M05, 2026Q1"
      ),
      div(class = "input-description", "Format: YYYYM## or YYYYQ#"),
      textInput(
        "period_start_modal",
        "Period Start",
        value = time_settings$period_start,
        placeholder = "YYYY-MM-DD HH:MM:SS"
      ),
      textInput(
        "period_end_modal",
        "Period End",
        value = time_settings$period_end,
        placeholder = "YYYY-MM-DD HH:MM:SS"
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("update_time_settings", "Update", class = "btn btn-primary")
      ),
      size = "m",
      easyClose = TRUE
    ))
  })
  
  # Threshold settings modal
  observeEvent(input$show_threshold_settings, {
    showModal(modalDialog(
      title = "Growth Threshold Settings",
      numericInput(
        "growth_threshold_modal",
        "Growth Rate Threshold",
        value = threshold_settings$growth_threshold,
        min = 0,
        step = 0.1
      ),
      #div(class = "input-description", "Enter a value between 0 and 1"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("update_threshold_settings", "Update", class = "btn btn-primary")
      ),
      size = "m",
      easyClose = TRUE
    ))
  })
  
  # Update time settings on confirmation
  observeEvent(input$update_time_settings, {
    time_settings$latest_period <- input$latest_period_modal
    time_settings$period_start <- input$period_start_modal
    time_settings$period_end <- input$period_end_modal
    
    # Refresh any dependent calculations
    if(!is.null(l_transmission_cache())) {
      l_transmission_cache(NULL)  # Force recalculation with new time settings
      
      # Reload data with new time settings
      l_transmission <- source("new_extraction_data_outliers.R", local = TRUE)$value$l_transmission
      
      if (!is.null(l_transmission)) {
        l_transmission_cache(l_transmission)
        print("Data reloaded with new time settings")
        
        # Update country boxes with new data
        updateCountryBoxes()
        
        # If a country was selected, update series selector
        if (!is.null(selected_country_rv())) {
          updateRevSeriesSelector(selected_country_rv())
        }
      }
    }
    
    # Refresh any dependent calculations
    if(!is.null(l_outliers_cache())) {
      l_outliers_cache(NULL)  # Force recalculation with new time settings
      
      # Reload data with new time settings
      l_outliers <- source("new_extraction_data_outliers.R", local = TRUE)$value$l_outliers
      
      if (!is.null(l_outliers)) {
        l_outliers_cache(l_outliers)
        print("Data reloaded with new time settings")
        
        # Update country boxes with new data
        updateCountryBoxes()
        
        # If a country was selected, update series selector
        if (!is.null(selected_country_rv())) {
          updateRevSeriesSelector(selected_country_rv())
        }
      }
    }
    
    removeModal()
  })
  
  # Update threshold settings on confirmation
  observeEvent(input$update_threshold_settings, {
    threshold_settings$growth_threshold <- input$growth_threshold_modal
    
    # Update country boxes with new threshold
    updateCountryBoxes()
    
    # If a country was selected, update series selector
    if (!is.null(selected_country_rv())) {
      updateRevSeriesSelector(selected_country_rv())
    }
    
    removeModal()
  })
  
  # Function to update country boxes based on current settings
  updateCountryBoxes <- function() {
    req(settings_submitted())
    req(l_transmission_cache())
    req(l_outliers_cache())
    
    lapply(eu_country_codes, function(country_code) {
      output[[paste0("value_box_", country_code)]] <- renderUI({
        l_transmission <- l_transmission_cache()
        l_outliers <- l_outliers_cache()
        
        if (!is.null(l_transmission[[country_code]]) || !is.null(l_outliers[[country_code]])) {
          count <- get_full_flagged_series_new(
            country_code, 
            threshold_settings$growth_threshold, 
            l_transmission
          )$num_flagged_series
          
          count_outliers <- get_outliers_series_new(
            country_code, 
            threshold_settings$growth_threshold, 
            l_outliers
          )
          
          div(
            class = "value-box",
            h4(eu_countries[match(country_code, eu_country_codes)], class = "value-box-title"),
            
            # Buttons for Revisions and Outliers (small buttons inside the box)
            div(
              class = "button-group",
              style = "display: flex; gap: 5px; margin-top: 10px;",
              
              # Revisions button with title and subtext
              div(
                style = "width: 180px;",# text-align: left;",  # Ensure proper alignment and space for the title and subtext
                actionButton(
                  paste0("details_button_", country_code),
                  div(
                    style = "display: flex; flex-direction: column; align-items: center;",
                    span("Revisions", style = "color: #007bff; font-weight: bold; font-size: 14px;"),  # Title in black
                    span(paste("Flagged series:", count), style = "color: red; font-size: 12px;")  # Subtext in red
                  ),
                  class = "btn btn-sm",  # Remove the 'btn-primary' class to avoid the default Bootstrap color
                  style = "background-color: transparent; border: none;",  # No background, no border
                  onclick = sprintf("Shiny.setInputValue('selected_country', '%s'); Shiny.setInputValue('tab_select', 'details');", country_code)
                )
              ),
              
              # Outliers button
              div(
                style = "width: 180px;", # text-align: left;",  # Ensure proper alignment and space for the title and subtext
                actionButton(
                  paste0("outliers_button_", country_code),
                  div(
                    style = "display: flex; flex-direction: column; align-items: center;",
                    span("Outliers", style = "color: #007bff; font-weight: bold; font-size: 14px;"),  # Title in black
                    span(paste("Flagged series:", count_outliers), style = "color: red; font-size: 12px;")  # Subtext in red
                  ),
                  class = "btn btn-sm",  # Remove the 'btn-primary' class to avoid the default Bootstrap color
                  style = "width: 100px; background-color: transparent; border: none; color: #007bff;",  # No background, no border, set text color
                  onclick = sprintf("Shiny.setInputValue('selected_country', '%s'); Shiny.setInputValue('tab_select', 'outliers');", country_code)
                )
              )
            )
          )
          
          
        } else {
          div(
            class = "value-box",
            h4(eu_countries[match(country_code, eu_country_codes)], class = "value-box-title"),
            p("No data available", class = "value-box-value"),
            
            div(
              class = "button-group",
              style = "display: flex; gap: 5px; margin-top: 10px;",
              
              actionButton(
                paste0("details_button_", country_code),
                "Revisions",
                class = "btn btn-sm",  # Remove the 'btn-primary' class to avoid the default Bootstrap color
                style = "width: 100px; background-color: transparent; border: none; color: #007bff;",  # No background, no border, set text color
              ),
              
              actionButton(
                paste0("outliers_button_", country_code),
                "Outliers",
                class = "btn btn-sm",  # Remove the 'btn-primary' class to avoid the default Bootstrap color
                style = "width: 100px; background-color: transparent; border: none; color: #007bff;",  # No background, no border, set text color
              )
            )
          )
        }
      })
    })
  }
  
  observeEvent(input$tab_select, {
    req(input$tab_select)
    
    if (input$tab_select == "details") {
      nav_select("nav", "details")  # Switch to Country Details tab
    } else if (input$tab_select == "outliers") {
      nav_select("nav", "outliers")  # Switch to Outliers tab
    }
  })
  
  
  # Function to update series selector for selected country
  updateRevSeriesSelector <- function(country_code) {
    req(l_transmission_cache())
    l_transmission <- l_transmission_cache()
    
    if (!is.null(l_transmission[[country_code]])) {
      result <- get_full_flagged_series_new(
        country_code, 
        threshold_settings$growth_threshold, 
        l_transmission
      )
      
      # Reactive filtering based on user input
      filtered_series <- reactive({
        filter_text <- input$series_filter
        
        # If the filter is empty, return all series; otherwise, apply the filter
        if (filter_text == "") {
          result$base_series
        } else {
          # Escape the period in the filter text if the user is searching for periods
          escaped_filter_text <- gsub("\\.", "\\\\.", filter_text)  # Escape periods in user input
          # Filter series that match the user input, case-insensitive
          grep(escaped_filter_text, result$base_series, value = TRUE, ignore.case = TRUE)
        }
      })
      
      # Initialize series_selector with all series
      updateSelectInput(session, "series_selector", choices = filtered_series())
      
      # Dynamically update series_selector when series_filter input changes
      observeEvent(input$series_filter, {
        updateSelectInput(session, "series_selector", choices = filtered_series())
      })
      
      # Display the selected country name
      output$selected_country_name <- renderText({
        paste("Revision details for", eu_countries[match(country_code, eu_country_codes)])
      })
    }
  }

  # Function to update series selector for selected country
  updateOutSeriesSelector <- function(country_code) {
    req(l_outliers_cache())
    l_outliers <- l_outliers_cache()
    
    if (!is.null(l_outliers[[country_code]])) {
      result <- l_outliers[[country_code]]

      # Reactive filtering based on user input
      filtered_series <- reactive({
        filter_text <- input$series_filter_outliers

        # If the filter is empty, return all series; otherwise, apply the filter
        if (filter_text == "") {
          result$SERIES_KEY
        } else {
          # Escape the period in the filter text if the user is searching for periods
          escaped_filter_text <- gsub("\\.", "\\\\.", filter_text)  # Escape periods in user input
          # Filter series that match the user input, case-insensitive
          grep(escaped_filter_text, result$SERIES_KEY, value = TRUE, ignore.case = TRUE)
        }
      })

      # Initialize series_selector_outliers with all series
      updateSelectInput(session, "series_selector_outliers", choices = filtered_series())

      # Dynamically update series_selector_outliers when series_filter_outliers input changes
      observeEvent(input$series_filter_outliers, {
        updateSelectInput(session, "series_selector_outliers", choices = filtered_series())
      })

      # Display the selected country name
      output$selected_country_name_outliers <- renderText({
        paste("Outlier details for", eu_countries[match(country_code, eu_country_codes)])
      })
    }

  }
  
  # Step 3: Render main content based on settings submission
  output$main_content <- renderUI({
    if (!settings_submitted()) {
      # Show the settings input form if not submitted
      div(
        class = "centered-box",
        card(
          class = "settings-card",
          card_header(
            class = "bg-primary text-white",
            h4("Analysis Parameters", class = "mb-0")
          ),
          layout_columns(
            fill = FALSE,
            gap = "1rem",
            col_widths = c(6, 6),
            card(
              card_header("Time Period Settings"),
              card_body(
                textInput(
                  "latest_period",
                  "Latest Period",
                  value = time_settings$latest_period,
                  placeholder = "e.g., 2024M09, 2025Q1"
                ),
                div(class = "input-description", "Format: YYYYM## or YYYYQ#"),
                textInput(
                  "period_start",
                  "Period Start",
                  value = time_settings$period_start,
                  placeholder = "YYYY-MM-DD HH:MM:SS"
                ),
                textInput(
                  "period_end",
                  "Period End",
                  value = time_settings$period_end,
                  placeholder = "YYYY-MM-DD HH:MM:SS"
                )
              )
            ),
            card(
              card_header("Analysis Settings"),
              card_body(
                numericInput(
                  "growth_threshold",
                  "Growth Rate Threshold",
                  value = threshold_settings$growth_threshold,
                  min = 0,
                  max = 1,
                  step = 0.1
                ),
                div(class = "input-description", "Enter a value between 0 and 1"),
                div(
                  class = "d-grid gap-2",
                  actionButton(
                    "submit_settings",
                    "Start Analysis",
                    class = "btn-lg btn-primary",
                    icon = icon("play")
                  )
                )
              )
            )
          )
        )
      )
    } else {
      # Show the country boxes if settings are submitted
      div(
        class = "full-screen-content",
        navset_card_tab(
          id = "nav",
          nav_panel(
            title = "Overview",
            div(
              class = "country-grid",
              lapply(seq_along(eu_country_codes), function(i) {
                uiOutput(paste0("value_box_", eu_country_codes[i]))
              })
            )
          ),
          nav_panel(
            title = "Revisions",
            value = "details",
            card(
              card_header(
                textOutput("selected_country_name")
              ),
              layout_columns(
                col_widths = c(7,3),
                selectInput("series_selector", 
                            label = "Select a series", 
                            choices = NULL, 
                            width = "100%"), 
                textInput("series_filter", 
                          "Filters:", 
                          value = "")
              ),
              layout_columns(
                col_widths = c(12),
                card(
                  card_header("Input and Primary tables comparison"),
                  tableOutput("current_previous_table")
                )
              ),
              layout_columns(
                col_widths = c(12),
                card(
                  card_header("Growth rate"),
                  tableOutput("growth_rate_table")
                )
              ),
              layout_columns(
                col_widths = c(12), # c(6, 6),
                card(
                  card_header("Input and Primary tables comparison"),
                  plotOutput("current_previous_plot", height = "400px")
                ),
                # ),
                card(
                  card_header("Growth Rates"),
                  plotOutput("growth_rate_plot", height = "400px")
                )
              )
            )
          ), 
          nav_panel(
            title = "Outliers",  # New tab for outliers
            value = "outliers",
            card(
              card_header(
                textOutput("selected_country_name_outliers")
                ), #to be changed 
              layout_columns(
                col_widths = c(7,3),
                selectInput("series_selector_outliers", 
                            label = "Select a series", 
                            choices = NULL, 
                            width = "100%"), 
                textInput("series_filter_outliers", 
                          "Filters:", 
                          value = "")
              ),
              layout_columns(
                col_widths = c(12),
                card(
                  card_header("Outliers Table"),
                  tableOutput("outliers_table")
                )
              ),
              layout_columns(
                col_widths = c(12),
                card(
                  card_header("Outliers Plot"),
                  plotOutput("outliers_plot", height = "400px")
                )
              )
            )
          )
        )
      )
    }
  })
  
  # When country is selected in Overview
  observeEvent(input$selected_country, {
    selected_country_rv(input$selected_country)
    
    # Switch to the details view when a country is selected
    nav_select("nav", "details")
    
    # Update the series selector
    updateRevSeriesSelector(input$selected_country)
    updateOutSeriesSelector(input$selected_country)
  })
  
  # Load initial data when settings are submitted
  observe({
    req(settings_submitted())
    
    if (is.null(l_transmission_cache()) || is.null(l_outliers_cache())) {
      # Load data if not already loaded
      extracted_data <- source("new_extraction_data_outliers.R", local = TRUE)$value
      l_transmission <- extracted_data$l_transmission
      l_outliers <- extracted_data$l_outliers
      
      if (!is.null(l_transmission) || !is.null(l_outliers)) {
        l_transmission_cache(l_transmission)
        l_outliers_cache(l_outliers)
        updateCountryBoxes()
        print("Initial data loaded and country boxes updated")
      }
    } else {
      # Update country boxes with cached data
      updateCountryBoxes()
    }
  })
  
  # Handle revisions series selection for a country
  observeEvent(input$series_selector, {
    req(input$series_selector)
    req(selected_country_rv())
    req(l_transmission_cache())
    
    country_code <- selected_country_rv()
    series_id <- input$series_selector
    l_transmission <- l_transmission_cache()
    
    # Get the current data for the selected series
    series_data <- get_full_flagged_series_new(country_code, threshold_settings$growth_threshold, l_transmission)$related_series
    # get_series_data(country_code, series_id, l_transmission)
    
    
    if (!is.null(series_data)) {
      # Table outputs
      output$current_previous_table <- renderTable({
        series_data %>%
          filter(SERIES_KEY %in% c(
            paste0(input$series_selector, "_NEW"),
            paste0(input$series_selector, "_OLD")
          ))
      })
      
      output$growth_rate_table <- renderTable({
        series_data %>%
          filter(SERIES_KEY %in% c(
            paste0(input$series_selector, "_ABS"),
            paste0(input$series_selector, "_REL")
          ))
      })
      
      # Plot outputs
      output$current_previous_plot <- renderPlot({
        
        data <- series_data %>%
          filter(SERIES_KEY %in% c(
            paste0(input$series_selector, "_NEW"),
            paste0(input$series_selector, "_OLD")
          )) %>%
          pivot_longer(cols = -SERIES_KEY, names_to = "TIME_PERIOD", values_to = "OBS_VALUE") %>%
          mutate(
            series_type = case_when(
              grepl("NEW", SERIES_KEY) ~ "NEW",
              grepl("OLD", SERIES_KEY) ~ "OLD",
              TRUE ~ SERIES_KEY
            )
          )
        
        ggplot(data, aes(x = TIME_PERIOD, y = OBS_VALUE, color = series_type, group = series_type)) +
          geom_line() + geom_point() +
          labs(x = "Time Period", y = "Observation Value", color = "Series Type") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
      })
      
      output$growth_rate_plot <- renderPlot({

        data <- series_data %>%
          filter(SERIES_KEY %in% c(
            paste0(input$series_selector, "_ABS"),
            paste0(input$series_selector, "_REL")
          )) %>%
          pivot_longer(cols = -SERIES_KEY, names_to = "TIME_PERIOD", values_to = "OBS_VALUE") %>%
          mutate(
            series_type = case_when(
              grepl("CURRENT", SERIES_KEY) ~ "CURRENT",
              grepl("PREVIOUS", SERIES_KEY) ~ "PREVIOUS",
              TRUE ~ SERIES_KEY
            )
          )

        ggplot(data, aes(x = TIME_PERIOD, y = OBS_VALUE, color = series_type, group = series_type)) +
          geom_line() + geom_point() +
          labs(x = "Time Period", y = "Growth Rate", color = "Series Type") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
      })
      
    }
  })
  
  
  # Handle outliers series selection for a country
  observeEvent(input$series_selector_outliers, {
    req(input$series_selector_outliers)
    req(selected_country_rv())
    req(l_outliers_cache())
    
    country_code <- selected_country_rv()
    series_id <- input$series_selector_outliers
    l_outliers <- l_outliers_cache()
    
    # Get the previous and current data for the selected series
    series_data <- l_outliers[[country_code]]
    
    if (!is.null(l_outliers)) {
      # Table outputs
      output$outliers_table <- renderTable({
        series_data %>%
          filter(SERIES_KEY %in% input$series_selector_outliers)
      })
      
      
      # Plot outputs
      output$outliers_plot <- renderPlot({

        data <- series_data %>%
          filter(SERIES_KEY %in% input$series_selector_outliers) %>%
          pivot_longer(cols = -SERIES_KEY, names_to = "TIME_PERIOD", values_to = "OBS_VALUE") # %>%
          # mutate(
          #   series_type = case_when(
          #     grepl("NEW", SERIES_KEY) ~ "NEW",
          #     grepl("OLD", SERIES_KEY) ~ "OLD",
          #     TRUE ~ SERIES_KEY
          #   )
          # )

        ggplot(data, aes(x = TIME_PERIOD, y = OBS_VALUE, colour = group)) +
          geom_line(aes(color = group), linewidth = 1) + 
          geom_point(aes(color = group), size = 2) +
          scale_color_manual(values = c("Normal" = "#00FFFF", "Outlier" = "#FF6F6F")) +
          labs(title = "Time Series with Outliers Highlighted",
               x = "Time Period", y = "Value", color = "Point Type") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
      })
      
    }
  })
}


shinyApp(ui, server)
