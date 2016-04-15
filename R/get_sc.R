query_sc_single <- function(query, start_date, end_date, config_path, override_dates = TRUE) { 
 
  metrics <- ifelse(is.na(query$metrics), "NA", strsplit(query$metrics, ",")[[1]])
  elements <- ifelse(is.na(query$elements), "NA", strsplit(query$elements, ",")[[1]])
  
  if(override_dates){
    query$start_date <- start_date
    query$end_date <- end_date
  }
  
  query$start_date <- as.character(query$start_date)
  query$end_date <- as.character(query$end_date)
  
  if(is.na(query$date.granularity)) {
    query$date.granularity <- "day"
  }
  
  if(is.na(query$top)) {
    query$top <- 5000
  }
  if(is.na(query$search)) {
    query$search <- c()
  }
  if(query$queryType == "overtime"){
    data <- with(query, RSiteCatalyst::QueueOvertime(suite, start_date, end_date
                                         , metrics, date.granularity, segment.id = segment.id))
  } else if (query$queryType == "trended") {
    data <- with(query, RSiteCatalyst::QueueTrended(suite, start_date, end_date
                                        , metrics, elements, search = search, segment.id = segment.id
                                        , date.granularity, top = top))
  } else if (queryType == "ranked") {
    data <- with(query, RSiteCatalyst::QueueRanked(suite, start_date, end_date
                                       , metrics, elements, search = search
                                       , segment.id = segment.id, top = top))
  }
  
  if("datetime" %in% colnames(data)){
    data$datetime <- as.Date(data$datetime)
  }
  
  if("name" %in% colnames(data)){
    setnames(data, "name", elements)
  }

  data <- data.table(data)
  return(data)
}

#' @export
query_sc <- function(queries_table, start_date, end_date, config_path = "config.json",
                     override_dates = TRUE, include_query_data = FALSE) {
  
  config_data <- jsonlite::fromJSON(config_path)
  sc_token <- with(config_data$site_catalyst, RSiteCatalyst::SCAuth(client_id, client_secret))
  
  results <- list()
  
  if(!"suite" %in% colnames(queries_table)){
    warning("Suite missing from scQueries sheet")  
  }
  
  for (i in 1:nrow(queries_table)) {
    results[[i]] <- query_sc_single(as.list(queries_table[i,]),
                                    start_date, end_date, config_path,
                                    override_dates = override_dates)
    Sys.sleep(1)
  }
  results <- data.table::rbindlist(results, fill = TRUE)
  if(!include_query_data) {
    results[, query := NULL]
  }
  return(results)
}