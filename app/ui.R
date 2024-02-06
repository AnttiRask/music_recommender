library(dplyr)
library(shinyBS)
library(shinycssloaders)
library(shiny)
library(shinythemes)

ui <- fluidPage(
    
    tags$head(
        tags$title("Music Recommender"),
        tags$link(rel = "shortcut icon", type = "image/png", href = "www/favicon.png")
    ),
    
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
            sidebarPanel(
                textAreaInput(
                    inputId     = "prompt",
                    label       = "Text Prompt",
                    height      = "160px",
                    placeholder = "What are you in the mood for?",
                    resize      = "none"
                ),
                actionButton(
                    inputId = "go",
                    label   = "Get Recommendation",
                    width   = "100%",
                    class   = "button"
                    # class   = "get-recommendation-button"
                ),
                br(),
                br(),
                bsAlert("alert_anchor")
            ),
            mainPanel(
                div(
                    class = "artist-card",
                    uiOutput("artistInfo") %>% 
                        withSpinner(color = "#1DB954"),
                    br(),
                    uiOutput("spotifyButton")
                )
            )
        )
    )
)