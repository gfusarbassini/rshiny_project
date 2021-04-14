library(shiny)
library(rvest)
library(ggplot2)
library(parallel)

source("helpers.r")


athletes <- fetch()# fetch info from FIDAL website
athletes <- select_athletes(athletes)# select athletes born after 2007
athletes <- tidy(athletes)# tidy data
superdata <<- data.frame()
opp <- create_opp_table(athletes)
data <- data.frame()
### create ui
ui <- fluidPage(
  titlePanel("Nuova Virtus Crema"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select an athlete and a discipline"),
      textInput("athlete", "Athlete",athletes[1,1]),
      selectInput("discipline", "Discipline", c(""), selected = 1),
      htmlOutput("text1"),
      selectInput("opponents", "Comparable athletes:", c(""), selected = 1),
      br(),
      br(),
      helpText("Athletes"),
      htmlOutput("text2")
    ),
    
    mainPanel(
      plotOutput("plot2"),
      DT::dataTableOutput("res_table"))

  )
)

### create server
server <- function(input, output, session) {
      
  #list of athletes
  output$text2 <- renderUI({
    HTML(paste(athletes[,1],"<br/>"))
  })
  
  #discipline
  observeEvent(input$athlete,{
    disc_list <- get_disciplines(input$athlete,athletes)
    updateSelectInput(session,'discipline',
                      choices=unique(disc_list))
    
  })

  observeEvent(input$discipline,{
    req(input$discipline)
    indisc <- input$discipline
    #check if a discipline is selected
    if(indisc != "Select a discipline" & indisc != "No competition available" & indisc != "Not an athlete"){
      num_athlete <- which(sapply(athletes[,1], FUN=function(X) input$athlete %in% X))
      if(length(num_athlete) != 0){
        #delete athlete from its own opponents
        opp[num_athlete] <- list(c("No Data"))
        #retrive athlete results
        matrix_y <- retrive_results(indisc,athletes[num_athlete,3])
      }
      #perform operations to clean the results in order to plot them
      result <- format_result(matrix_y)
      
      #create a dataframe
      data <- data.frame(
        day = as.Date(matrix_y[,1],format='%Y/%m/%d'),
        result = as.numeric(result)
      )
      
      #find the mean (always possible)
      mean_result <- mean(unlist(as.numeric(result)))
      mean_result <- format(round(mean_result, 2), nsmall = 2)
      #initialize forecast
      next_result <- "/"
      #create env variable -> selected person's data
      superdata <<- data
      if(input$opponents == "Compare Athlete" | input$opponents == "No athlete to compare"){
        p <- ggplot(data, aes(x=day, y=result)) +
          stat_smooth(formula = y ~ x, method = lm) +
          ylab("") +
          xlab("")
        if(length(matrix_y)>9){
          #line and forecast are possible only if there is more than one record
          p <- p + geom_line(color="darkseagreen3",size=1)
          model <- lm(result ~ day, data = data)
          next_result <- coef(model)["(Intercept)"] + coef(model)["day"] * as.numeric(as.Date(Sys.Date()))
          next_result <- format(round(next_result, 2), nsmall = 2)
        }
        #plot points
        p <- p + geom_point(color="darkseagreen4",size=4)
        
        #render mean and forecast
        output$text1 <- renderUI({
          HTML(paste("Mean:<br/>",mean_result,"<br/>Today's forecast:<br/>",next_result))
        })
        #render plot
        output$plot2 <- renderPlot({
          p
        })
      }
    }
    else{
      #dummy plot for empty cases
      matrix_y <- t(c("2000/01/01","0","0","0","0"))
      data <- data.frame(
        day = as.Date(matrix_y[,1],format='%Y/%m/%d'),
        result = as.numeric(matrix_y[,3])
      )
      p <- ggplot(data, aes(x=day, y=result)) +
        ylab("") +
        xlab("")
      matrix_y <- t(c("","","","",""))
      output$text1 <- renderUI({
        HTML("Mean:<br/>/<br/>Today's forecast:<br/>/")
      })
      output$plot2 <- renderPlot({
          p
      })

    }
    
    #create the list of opponents indexes
    opponents_list <- find_opp(input$discipline,opp,athletes)
    
    opponents_names <- list()
    #index to name
    if(length(opponents_list) == 0) opponents_names[1] <- "No athlete to compare"
    else{
      for(i in 1:length(opponents_list)){
        opponents_names[i] <- athletes[unlist(opponents_list[i]),1]
      }
    }
    #output possible opponents
    updateSelectInput(session,'opponents',
                      choices=unique(c("Compare Athlete",as.vector(opponents_names))))
    
    #output table & plot  
    output$res_table <- DT::renderDataTable({
      DT::datatable({  
        matrix_y},
        options = list(
          columns = list(
            list(title = 'Date'),
            list(title = 'Group'),
            list(title = 'Result'),
            list(title = 'Wind'),
            list(title = 'Location')
          )
        )
      )
    })
  })

  #reactive to opponent choice + plot data
  observeEvent(input$opponents,{
    req(input$opponents)
    inp <- input$opponents
    #plot main athlete data
    if(length(superdata) != 0){
      p <- ggplot(superdata, aes(x=day, y=result)) +
        stat_smooth(formula = y ~ x, method = lm) +
        ylab("") +
        xlab("") +
        geom_line(color="darkseagreen3",size=1) +
        geom_point(color="darkseagreen4",size=4)
         
      if(input$opponents != "Compare Athlete" & input$opponents != "No athlete to compare"){
        
        get_link <- athletes[match(input$opponents,athletes[,1]),3]
        matrix_y <- retrive_results(input$discipline,get_link)
        result <- format_result(matrix_y)
        
        #plot opponent data
        data <- data.frame(
          day = as.Date(matrix_y[,1],format='%Y/%m/%d'),
          result = as.numeric(result)
        )
        if(length(matrix_y)>9){
          p <- p + geom_line(data=data,color="brown3",size=1)
        }
        p <- p + geom_point(data=data,colour="brown4",size=4)
      
      }
      #render all
      output$plot2 <- renderPlot({
         p
      })
    }

 })
    
}



# Create Shiny app ----
shinyApp(ui = ui, server = server)
