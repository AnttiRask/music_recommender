library(rsconnect)

# # GitHub
# setAccountInfo(
#     name   = Sys.getenv("SHINY_APPS_NAME"),
#     token  = Sys.getenv("SHINY_APPS_TOKEN"),
#     secret = Sys.getenv("SHINY_APPS_SECRET")
# )

# Locally
source("app/www/secret.R")

setAccountInfo(
    name   = SHINY_APPS_NAME,
    token  = SHINY_APPS_TOKEN,
    secret = SHINY_APPS_SECRET
)

deployApp(
    appDir      = "app/",
    appName     = "music-recommender",
    account     = "youcanbeapirate",
    forceUpdate = TRUE
)

rsconnect::setProperty()