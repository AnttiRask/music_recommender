library(dplyr)
library(shinyBS)
library(shinycssloaders)
library(shiny)
library(shinythemes)

ui <- fluidPage(
    
    # Set the theme and custom CSS
    includeCSS("www/styles.css"),
    
    # Application title
    div(
        class = "container",
        titlePanel(
            title = list(
                icon(
                    "spotify",
                    lib = "font-awesome"
                ),
                "Music Recommender"
            )
        ),
        sidebarLayout(
            div(
                class = "sidebar",
                sidebarPanel(
                    textAreaInput(
                        inputId     = "prompt",
                        label       = "Text Prompt",
                        height      = "80px",
                        placeholder = "Write your music mood...",
                        resize      = "none"
                    ),
                    actionButton(
                        inputId = "go",
                        label   = "Get Recommendation",
                        class   = "btn btn-success"
                    ),
                    br(),
                    br(),
                    bsAlert("alert_anchor")
                )
            ),
            mainPanel(
                div(
                    class = "artist-card",
                    uiOutput("artistInfo") %>% 
                        withSpinner(color = "#1DB954"),
                )
            )
        )
    )
)