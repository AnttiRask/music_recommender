# Load needed packages
library(shiny)              # Core Shiny package
library(shinyBS)            # For Bootstrap components in Shiny
library(shinycssloaders)    # For adding CSS loaders/spinners

ui <- fluidPage(

    # The tab title and favicon
    tags$head(
        tags$title("Music Recommender"),
        tags$link(rel = "shortcut icon", type = "image/png", href = "favicon.png")
    ),
    
    # Custom CSS styles
    includeCSS("www/styles.css"),
    
    # Main container
    div(
        class = "container",
        # The app title
        titlePanel(title = list(icon("spotify", lib = "font-awesome" ), "Music Recommender")),
        sidebarLayout(
            sidebarPanel(
                # Text prompt input
                textAreaInput(
                    inputId     = "prompt",
                    label       = NULL,
                    height      = "160px",
                    placeholder = "Describe to me, in 190 characters or less, what kind of music you would like to hear.",
                    resize      = "none"
                ),
                # Button to get the recommendation
                actionButton(
                    inputId = "go",
                    label   = "Get Recommendation",
                    width   = "100%",
                    class   = "button"
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
                        color            = "#1DB954",
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