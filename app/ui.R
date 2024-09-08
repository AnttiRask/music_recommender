# Load needed packages
library(shiny)              # Core Shiny package
library(shinyBS)            # For Bootstrap components in Shiny
library(shinycssloaders)    # For adding CSS loaders/spinners

ui <- fluidPage(

    # The tab title and favicon
    tags$head(
        tags$title("TuneTeller"),
        tags$link(rel = "shortcut icon", type = "image/png", href = "favicon.png")
    ),
    
    # Custom CSS styles
    includeCSS("www/styles.css"),
    
    # Main container
    div(
        class = "container",
        # The app title
        titlePanel(title = "TuneTeller"),
        sidebarLayout(
            sidebarPanel(
                # Text prompt input
                textAreaInput(
                    inputId     = "prompt",
                    label       = NULL,
                    height      = "200px",
                    placeholder = "Describe to me, in 190 characters or less, what kind of music you would like to hear. \n\nI will then recommend you an artist to listen to!",
                    resize      = "none"
                ),
                # Button to get the recommendation
                actionButton(
                    inputId = "go",
                    label   = "Get Recommendation",
                    width   = "100%",
                    class   = "button-recommendation"
                ),
                br(),
                br(),
                # Button to clear the text area
                actionButton(
                    inputId = "clearBtn",
                    label   = "Clear Text",
                    class   = "button-clear"
                ),
                br(),
                br(),
                # Bootstrap alert placeholder
                bsAlert("alert_anchor")
            ),
            mainPanel(
                # The artist card
                div(
                    class = "artist-card",
                    withSpinner(
                        uiOutput("artistInfo"),
                        type             = 3,
                        color            = "#C1272D",
                        color.background = "#191919"
                    ),
                    br(),
                    # Output for the Spotify button (dynamically rendered)
                    uiOutput("spotifyButton")
                ) # div
            ) # mainPanel
        ) # sidebarLayout
    ) # div
) # fluidPage