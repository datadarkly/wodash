
#Work order listing dashboard
#Ver. 2.0.1
#By Carter Richard

vers <- "2.0.2"
last_updated <- "2/4/2020"

library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(janitor)
library(tidyr)
library(timevis)
library(readxl)

dashboardPage(
    dashboardHeader(title = "WO Dashboard"),
    
    dashboardSidebar(
            em(helpText(paste(" Vers.", vers, "last updated", last_updated))),
            
            helpText("This dashboard loads a dummy dataset on initialization.
                     Upload your listing of work orders, then adjust the
                     filters below."),
            
            fileInput("file1", "Choose file to upload", accept = ".xlsx"),
            
            sidebarMenu(
                menuItem("Dashboard", tabName = "dashboard", icon = icon("chart-bar")),
                menuItem("Timeline", tabName = "timeline", icon = icon("clock")),
                menuItem("Table", tabName = "table", icon = icon("table"))
            ),
            
            dateRangeInput("dates", "Date Range",
                           start = "2019-10-01"),
            
            selectInput("assign", "Assigment", ""),
            
            checkboxGroupInput("status", "Status", NULL),
            
            radioButtons("type", "Type", c("Corrective Maintenance" = "CM",
                                           "Preventive Maintenance" = "PM",
                                           "Service Requests" = "SR"),
                         selected = "CM"),
            
            sliderInput("age", "Age (in days)",
                        0, 120,
                        value = c(0, 90),
                        step = 30,
                        ticks = "FALSE",
                        dragRange = "TRUE")
    ),
    
    dashboardBody(
        
        tabItems(
            tabItem(tabName = "dashboard",
                    h2("Dashboard"),
                    
                    fluidRow(
                        box(plotOutput("main_display"), width = 12)
                    ),
                    
                    fluidRow(
                        box(plotOutput("second_display"), width = 8),
                        
                    h3("KPI Tracking"),
                    h5("*Modified by filters"),
                    
                        valueBoxOutput("mean_days"),
                        valueBoxOutput("avg_labor"),
                        valueBoxOutput("perc_closed")
                    )
            ),
            
            tabItem(tabName = "timeline",
                    h2("Timeline (Experimental)"),
                    h4("This tab is only visible for individual assignments. 
                       You MUST select one technician to view at a time. **This feature is
                       experimental and can be easily broken. Use with caution when analyzing data.**"),
                    fluidRow(
                        box(timevisOutput("timeline"), width = 12, height = "auto")
                    )
            ),
            
            tabItem(tabName = "table",
                    h2("Table"),
                    h4("This tab is the raw report data as filtered down via
                       the parameters to the left, sorted by labor amount.
                       Assigments are the work order FIRST LINE only."),
                    box(tableOutput("contents"), width = 12)
            )
            
        )
    )
)
