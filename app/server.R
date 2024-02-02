# Load needed packages ----
library(conflicted)
library(httr2)
library(jsonlite)
library(shiny)
library(spotifyr)
library(tidyverse)

# Source the API keys ----
source("www/secret.R")

server <- function(input, output, session) {
    
    # Reactive expression for handling OpenAI API request
    openai_recommendation <- eventReactive(
        input$go, {
            
            # Construct the prompt using user inputs
            prompt_final <- str_glue(
                "Could you provide a single recommendation for a/an artist/band based on the following prompt: {input$prompt}.
                Don't necessarily go for the most well known artist/band. Format the answer to have the name of the artist/band
                on the first line. Then have a line break. Then write a short description of the chosen artist/band and an 
                explanation why you chose to recommend that particular artist/band."
            )
            
            # OpenAI API request setup
            url <- "https://api.openai.com/v1/completions"
            body <- list(
                model       = "gpt-3.5-turbo-instruct",
                prompt      = prompt_final,
                n           = 1,
                # temperature = 0,
                max_tokens  = 4000
            )
            
            # Replace '<OPENAI_API_KEY>' with your actual OpenAI API key
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
                
                result <- list(
                    artist = artist_name,
                    info   = artist_info
                )
                print(result)  # Temporarily print the result to the console
                return(result)
            } else {
                return(NULL) # Handle errors or unsuccessful requests appropriately
            }
        },
        ignoreNULL = TRUE # ignore initial state of NULL
    )
    
    # Reactive expression for fetching artist details from Spotify
    artist_details <- reactive({
        req(openai_recommendation()) # Ensure this only runs after a successful OpenAI recommendation
        
        recommendation <- openai_recommendation() # Get the reactive value
        
        if (is.null(recommendation) || !is.list(recommendation)) {
            return(NULL) # Correctly return NULL for consistency
        }
        
        artist_name    <- recommendation$artist
        artist_info    <- str_c(recommendation$info, collapse = " ") %>% str_squish()
        
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
            list(
                followers  = artist_spotify %>% pull(followers.total),
                imageUrl   = artist_spotify %>% pluck("images", 1) %>% slice_head(n = 1) %>% pull(url),
                info       = artist_info,
                name       = artist_spotify %>% pull(name),
                spotifyUrl = artist_spotify %>% pull(external_urls.spotify)
            )
        } else {
            return(NULL) # Handle cases where the artist is not found
        }
    })
    
    # Displaying the artist's details in the UI
    output$artistInfo <- renderUI({
        details <- artist_details()
        if (is.null(details) || !is.list(details)) {
            return("No data available.")
        }
        print(details)
        if (!is.null(details)) {
            tagList(
                img(src = details$imageUrl, alt = "Artist Image", height = "200px"),
                h3(details$name),
                h4(details$info),
                p(paste("Followers:", format(details$followers, big.mark = ","))),
                a(href = details$spotifyUrl, "View on Spotify", target = "_blank")
            )
        } else {
            "Artist details not available."
        }
    })
    
    # Additional server logic for fetching and displaying top tracks can follow a similar pattern
}