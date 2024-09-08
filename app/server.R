# Load needed packages
library(dplyr)    # Data manipulation
library(httr2)    # HTTP requests made simple
library(jsonlite) # For JSON parsing
library(purrr)    # For pluck()
library(shiny)    # Core Shiny package
library(shinyBS)  # For Bootstrap components in Shiny
library(spotifyr) # For interfacing with the Spotify API
library(stringr)  # For string manipulation

# Source the script containing the latest prompt version
source("www/prompt_versions.R")

server <- function(input, output, session) {
    
    # Reactive value to store the Spotify URL, initialized to NULL
    spotify_url <- reactiveVal(NULL)
    
    # Event reactive expression triggered when 'Get Recommendation' button is clicked
    openai_recommendation <- eventReactive(input$go, {
        
        # Construct the prompt using the latest prompt version
        prompt_final <- str_glue(prompt_ver2)
        
        # Setup for OpenAI API request
        url <- "https://api.openai.com/v1/completions"
        body <- list(
            model       = "gpt-3.5-turbo-instruct",
            prompt      = prompt_final,
            n           = 1,
            temperature = 0.5,
            max_tokens  = 4000
        )
        
        # Perform the API request
        response <- request(url) %>%
            req_headers(Authorization = str_glue("Bearer {Sys.getenv('OPENAI_API_KEY')}")) %>%
            req_body_json(body) %>%
            req_perform()
        
        # Process the response from OpenAI
        if (response$status_code == 200) {
            # Parse the text from the response
            text <- response %>%
                resp_body_json() %>%
                pluck("choices") %>%
                unlist() %>%
                pluck("text") %>%
                str_trim()
            
            # Split the text into artist name and additional info
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
            
            # Combine artist name and info into a result list
            result_artist <- list(
                artist = artist_name,
                info   = artist_info
            )
            # Print the result to the console for debugging purposes
            print("result_artist:")
            print(result_artist)
            return(result_artist)
        } else {
            # Return NULL if the API request was unsuccessful
            return(NULL)
        }
    },
    ignoreNULL = TRUE # ignore initial state of NULL
    )
    
    # Observe changes in the 'Text Prompt' input and enforce character limit
    observeEvent(input$prompt, {
        if(str_length(input$prompt) > 190) {
            # Trim the string if it exceeds 190 characters
            newstring <- str_sub(input$prompt, end = 190)
            # Show an alert if the character limit is exceeded
            createAlert(
                session,
                anchorId = "alert_anchor",
                title    = "Character Limit Exceeded",
                content  = "You exceeded the 190 character limit!",
                dismiss  = TRUE
            )
            # Update the text input with the trimmed string
            updateTextInput(session, "prompt", value = newstring)
        }
    }, 
    ignoreInit = TRUE
    )
    
    # Listener for the Clear text button
    observeEvent(input$clearBtn, {
        updateTextAreaInput(
            session,
            "prompt",
            value       = "",
            placeholder = "Describe to me, in 190 characters or less, what kind of music you would like to hear."
        )
    }, 
    ignoreInit = TRUE
    )
    
    # Reactive expression to fetch artist details from Spotify
    artist_details <- reactive({
        # Wait for the OpenAI recommendation to complete
        req(openai_recommendation())
        # Retrieve the recommendation
        recommendation <- openai_recommendation()
        
        if (is.null(recommendation) || !is.list(recommendation)) {
            # If no recommendation, return NULL
            return(NULL)
        }
        
        # Extract artist name and format the info with HTML line breaks
        artist_name    <- recommendation$artist
        artist_info    <- str_c(recommendation$info, collapse = " ") %>% str_replace_all("  ", "<br><br>")
        
        # Fetch artist details from Spotify using {spotifyr} package
        artist_spotify <- search_spotify(
            artist_name,
            type          = "artist",
            limit         = 1,
            authorization = get_spotify_access_token(
                client_id     = Sys.getenv("SPOTIFY_CLIENT_ID"),
                client_secret = Sys.getenv("SPOTIFY_CLIENT_SECRET")
            )
        )
        
        # Check if the artist was found and has images
        if (!is.null(artist_spotify) && length(artist_spotify$images) > 0) {
            
            # Prepare the result list with details for rendering in the UI
            result_spotify <- list(
                followers  = artist_spotify %>% pull(followers.total),
                imageUrl   = artist_spotify %>% pluck("images", 1) %>% slice_head(n = 1) %>% pull(url),
                info       = artist_info,
                name       = artist_spotify %>% pull(name),
                spotifyUrl = artist_spotify %>% pull(external_urls.spotify)
            )
            # Print the result to the console for debugging purposes
            print("result_spotify:")
            print(result_spotify)
            return(result_spotify)
        } else {
            # If no images or artist is not found, return NULL
            return(NULL)
        }
    })
    
    # Observe the artist details and update the Spotify URL reactive value
    observe({
        details <- artist_details()
        if (!is.null(details) && is.list(details)) {
            # Update the spotify_url reactive value with the new URL
            spotify_url(details$spotifyUrl)
        }
    })
    
    output$artistInfo <- renderUI({
        # If there's no recommendation yet, show a placeholder image
        if (is.null(openai_recommendation())) {
            # Add a fallback text for debugging purposes
            return(tagList(
                h3("Placeholder Loaded"),
                img(src = "placeholder_image.png", alt = "Placeholder Image", height = "200px")
            ))
        }
        
        # Once there's a recommendation, show the actual artist details
        details <- artist_details()
        if (is.null(details)) {
            return(h3("No artist details available."))
        }
        
        # Render artist information
        tagList(
            h3(details$name),
            p(details$info),
            img(src = details$imageUrl, alt = "Artist Image", height = "200px"),
            p(paste("Spotify Followers:", format(details$followers, big.mark = ","))),
            a(href = details$spotifyUrl, "Listen on Spotify", target = "_blank")
        )
    })
    
    # Render the Spotify button as a UI element
    output$spotifyButton <- renderUI({
        if (is.null(spotify_url()) || !nzchar(spotify_url())) {
            return(NULL)
        }
        
        # Render the Spotify button only when a valid URL is available
        tags$a(
            href   = spotify_url(),                # The href attribute is the Spotify URL
            target = "_blank",                     # Opens the link in a new tab
            class  = "button-spotify",             # Class for CSS styling
            icon("spotify", lib = "font-awesome"), # Spotify icon from the font-awesome library
            "View on Spotify"                      # Button text
        )
        
    })
}