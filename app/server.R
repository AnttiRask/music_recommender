# Load needed packages ----
library(conflicted)
library(httr2)
library(jsonlite)
library(shiny)
library(shinyBS)
library(spotifyr)
library(tidyverse)

# Source the API keys ----
source("www/prompt_versions.R")
source("www/secret.R")

server <- function(input, output, session) {
    
    # OpenAI API request ----
    openai_recommendation <- eventReactive(
        input$go, {
            
            # Construct the prompt using user inputs ----
            prompt_final <- str_glue(prompt_ver2)
            
            # OpenAI API request setup ----
            url <- "https://api.openai.com/v1/completions"
            body <- list(
                model       = "gpt-3.5-turbo-instruct",
                prompt      = prompt_final,
                n           = 1,
                temperature = 0.5,
                max_tokens  = 4000
            )
            
            response <- request(url) %>%
                req_headers(Authorization = str_glue("Bearer {OPENAI_API_KEY}")) %>%
                req_body_json(body) %>%
                req_perform()
            
            if (response$status_code == 200) {
                text <- response %>%
                    resp_body_json() %>%
                    pluck("choices") %>%
                    unlist() %>%
                    pluck("text") %>%
                    str_trim()
                
                split_text <- str_split(text, pattern = "\n")[[1]]
                
                artist_name <- split_text %>%
                    as_tibble() %>%
                    slice_head(n = 1) %>%
                    # "^(?!.*:).*" captures any text at the start of a line, only if there is no colon
                    # "(?<=: )\\s?.*"" captures any text following a colon, ignoring one leading whitespace
                    str_extract("^(?!.*:).*|(?<=: )\\s?.*")
                
                artist_info <- split_text %>% 
                    as_tibble() %>%
                    slice(-c(1:2)) %>%
                    pull()
                
                result_artist <- list(
                    artist = artist_name,
                    info   = artist_info
                )
                print("result_artist:")
                print(result_artist) # Temporarily print the result to the console
                return(result_artist)
            } else {
                return(NULL) # Handle errors or unsuccessful requests appropriately
            }
        },
        ignoreNULL = TRUE # ignore initial state of NULL
    )
    
    # Limit input character count and alert
    observeEvent(input$prompt, {
        if(str_length(input$prompt) > 190) {
            newstring <- str_sub(input$prompt, end = 190)
            createAlert(
                session,
                anchorId = "alert_anchor",
                title    = "Character Limit Exceeded",
                content  = "You exceeded the 190 character limit!",
                dismiss  = TRUE
            )
            updateTextInput(session, "prompt", value = newstring)
        }
    }, 
    ignoreInit = TRUE
    )
    
    # Fetching artist details from Spotify
    artist_details <- reactive({
        req(openai_recommendation()) # Ensure this only runs after a successful OpenAI recommendation
        
        recommendation <- openai_recommendation() # Get the reactive value
        
        if (is.null(recommendation) || !is.list(recommendation)) {
            return(NULL) # Correctly return NULL for consistency
        }
        
        artist_name    <- recommendation$artist
        artist_info    <- str_c(recommendation$info, collapse = " ") %>% str_replace_all("  ", "<br><br>")
        
        artist_spotify <- search_spotify(
            artist_name,
            type          = "artist",
            limit         = 1,
            authorization = get_spotify_access_token(
                client_id     = SPOTIFY_CLIENT_ID,
                client_secret = SPOTIFY_CLIENT_SECRET
            )
        )
        
        if (!is.null(artist_spotify) && length(artist_spotify$images) > 0) {
            
            result_spotify <- list(
                followers  = artist_spotify %>% pull(followers.total),
                imageUrl   = artist_spotify %>% pluck("images", 1) %>% slice_head(n = 1) %>% pull(url),
                info       = artist_info,
                name       = artist_spotify %>% pull(name),
                spotifyUrl = artist_spotify %>% pull(external_urls.spotify)
            )
            print("result_spotify:")
            print(result_spotify) # Temporarily print the result to the console
            return(result_spotify)
        } else {
            return(NULL) # Handle cases where the artist is not found
        }
    })
    
    # The artist's details
    output$artistInfo <- renderUI({
        details <- artist_details()
        if (is.null(details) || !is.list(details)) {
            return("No data available.")
        }
        if (!is.null(details)) {
            tagList(
                img(src = details$imageUrl, alt = "Artist Image", height = "200px"),
                h3(details$name),
                HTML(details$info),
                HTML("<br><br>"),
                p(paste("Spotify Followers:", format(details$followers, big.mark = ","))),
                a(href = details$spotifyUrl, "View on Spotify", target = "_blank")
            )
        } else {
            "Artist details not available."
        }
    })
}