#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

    myData <- reactive({
        inFile <- input[["file1"]]
        if(is.null(inFile)) {
            d <- read_excel("data/AHPFM008.xlsx", 1, skip = 13)
        } else {
            d <- read_xlsx(inFile[["datapath"]], skip = 13)
        }
        
        d <-  clean_names(d)
                
        d <-  transmute(d,
                wo_id = wo_id_task,
                sr_id = sr_id,
                wo_type = wo_type,
                wo_status = wo_status,
                wo_days_open = as.integer(wo_days_open),
                wo_start = wo_reqd_start_dt,
                labor_pend = as.character(wo_pending_labor_cost),
                labor_fin = as.character(wo_final_labor_cost),
                wo_desc = wo_description,
                wo_assign = technician)
        
        d <- unite(d, "labor", c(labor_pend, labor_fin), na.rm = TRUE)
        d[["labor"]] <- as.numeric(d[["labor"]]) / 20

        
        d
    })
    
    observe({
        updateSelectInput(session, "assign",
                          label = "Assignment",
                          choices = c("All", unique(myData()[["wo_assign"]])),
                          selected = "All")
        
        updateCheckboxGroupInput(session, "status",
                                 label = "Status",
                                 choices = unique(myData()[["wo_status"]]),
                                 selected = c("OPEN",
                                              "ON HOLD",
                                              "WORK IN PROGRESS",
                                              "AWAITING SCHEDULING",
                                              "SCHEDULED"))
        
    })
    
    myDataFilt <- reactive({
        
        d <- filter(myData(),
                        wo_start >= input[["dates"]][1] &
                        wo_start <= input[["dates"]][2] &
                        
                        wo_days_open >= input[["age"]][1] &
                        wo_days_open <= input[["age"]][2] &
                        
                        wo_status %in% input[["status"]] &
                        
                        (if(input[["type"]] == "SR"){!is.na(sr_id)}
                         else if(input[["type"]] == "PM"){wo_type == "PREVENTATIVE MAINTENANCE"}
                         else if(input[["type"]] == "CM"){wo_type == "CORRECTIVE MAINTENANCE"}) &
                        
                        if(input[["assign"]] != "All"){wo_assign == input[["assign"]]}
                    else{wo_assign == wo_assign} 
        ) %>%         
            arrange(desc(labor))
    })
    
    output[["main_display"]] <- renderPlot({
        ggplot(myDataFilt(), aes(x = wo_start, 
                                 y = wo_days_open, 
                                 color = wo_status,
                                 size = labor)) + 
            geom_jitter() +
            ggtitle("Work Order listing by Age and Start Date") +
            xlab("Start Date") +
            ylab("Age (Days)") + 
            labs(size = "Labor (Hours)",
                 color = "Status")
    })
    
    output[["second_display"]] <- renderPlot({
        
        ggplot(myDataFilt(), aes(x = fct_infreq(wo_assign),
                                 fill = wo_status)) +
            geom_bar() +
            coord_flip() +
            ggtitle("Work Order count by First Line Assignment") +
            xlab("Assignment") +
            ylab("# of WO's") +
            labs(fill = "Status")
    })
    
    output[["timeline"]] <- renderTimevis({
        
        if(input[["assign"]] == "All"){"Timeline only available for individuals!"}
            else{
                filter(myDataFilt(),
                    !is.na(sr_id), wo_assign == input[["assign"]]) %>% 
                transmute(
                            start = wo_start,
                            end = as.Date(wo_start) + wo_days_open,
                            content = paste(wo_assign, "-", wo_desc),
                            title = paste("WO#:", wo_id)
                        ) %>% 
                timevis(fit = FALSE)
            }
    })
    
    output[["contents"]] <- renderTable({
        d <- myDataFilt() %>% 
            mutate(wo_start = as.character(wo_start))
        
        colnames(d) <- c("Work Order ID",
                         "Service Request ID",
                         "Type",
                         "Status",
                         "# of Days Open",
                         "Start Date",
                         "Labor (Hours)",
                         "Description",
                         "Assignment")
        d
    })
    
    output[["mean_days"]] <- renderValueBox({
        mean_days <- mean(myDataFilt()[["wo_days_open"]], na.rm = TRUE)
        
        valueBox(
            paste(as.integer(mean_days), "days"), "Work Order Average Age", icon = icon("clock"),
            color = "yellow"
        )
        
    })
    
    output[["avg_labor"]] <- renderValueBox({
        avg_labor <- mean(myDataFilt()[["labor"]], na.rm = TRUE)
        
        valueBox(
            paste(as.integer(avg_labor), "hours"), "Average labor applied", icon = icon("ruler"),
            color = "green"
        )
    })
    
    output[["perc_closed"]] <- renderValueBox({
        
        num_closed <- filter(myDataFilt(), wo_status == "CLOSED" | wo_status == "COMPLETE") %>% 
            nrow()
        
        perc_closed <- num_closed / nrow(myDataFilt()) * 100
        
        valueBox(
            paste(as.integer(perc_closed), "%"), "Percentage of work worders closed or completed", icon = icon("check"),
                  color = "blue"
        )
    })
    
})
