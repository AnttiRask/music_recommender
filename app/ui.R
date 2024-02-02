library(shiny)

ui <- fluidPage(
    titlePanel("Music Recommender"),
    sidebarLayout(
        sidebarPanel(
            textAreaInput("prompt", "Text Prompt", "Write your request here."),
            actionButton("go", "Get Recommendation")
        ),
        mainPanel(
            uiOutput("artistInfo"),
        )
    )
)