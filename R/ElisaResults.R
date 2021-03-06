
elisa_cols <- c("study_id", "subject_id", "result_id",
                                "analyte", "comments", 
                                "value", "unit",
                                "experiment_title", "assay_purpose", "measurement_technique",
                                "biosample_accession", "specimen_type", "specimen_subtype",
                                "visit_name", "study_time_of_specimen_collection", "unit_of_study_time_of_specimen_collection",
                                "study_time_t0_event", "study_time_t0_event_specify",
                                "file_name")

getElisaResults <- function(conn,study_id, measurement_types) {
  cat("loading ELISA Results data....")

#   old <- options(stringsAsFactors = FALSE)
#   on.exit(options(old), add = TRUE)
#   options(useFancyQuotes = FALSE)
#   measurement_types <- paste(mapply(sQuote, measurement_types), collapse=", ")
  
  sql_stmt <- paste("
                    SELECT distinct
                    els.study_accession,
                    els.subject_accession,
                    els.result_id,
                    els.analyte, 
                    els.comments, 
                    els.value_reported, 
                    els.unit_reported, 
                    ex.title,
                    ex.purpose,
                    ex.measurement_technique,
                    bs.biosample_accession,
                    bs.type,
                    bs.subtype,
                    pv.visit_name,
                    bs.study_time_collected,
                    bs.study_time_collected_unit,
                    bs.study_time_t0_event,
                    bs.study_time_t0_event_specify,
                    fi.name
                    FROM  
                      elisa_result els
					          INNER JOIN
						          experiment ex ON els.experiment_accession=ex.experiment_accession
					          INNER JOIN
						          biosample bs ON els.biosample_accession=bs.biosample_accession
                    INNER JOIN
                      planned_visit pv ON bs.planned_visit_accession=pv.planned_visit_accession
                    LEFT OUTER JOIN
                    expsample_2_file_info es2fi ON els.expsample_accession=es2fi.expsample_accession
                    LEFT OUTER JOIN
                      file_info fi ON es2fi.file_info_id=fi.file_info_id
                    WHERE els.study_accession in (\'", study_id,"\') AND
                          ex.purpose != 'Neutralizing_Antibody_Titer'
                    ORDER BY els.subject_accession",sep="")

  elisa_df <- dbGetQuery(conn,statement=sql_stmt)
  if (nrow(elisa_df) > 0) {
    colnames(elisa_df) <- elisa_cols 
    elisa_df <- ddply(elisa_df, .(study_id, subject_id, result_id), mutate, elapsed_time_of_specimen_collection = 
                      covertElaspsedTimeToISO8601Format(study_time_of_specimen_collection, 
                                                        unit_of_study_time_of_specimen_collection))
    
    elisa_df <- ddply(elisa_df, .(study_id, subject_id, result_id), mutate, time_point_reference = 
                      getTimePointReference(study_time_t0_event, study_time_t0_event_specify))
    
  }
  
  cat("done", "\n")
  elisa_df
}

getCountOfElisaResults <- function(conn,study_id) {  
  sql_stmt <- paste("
                    SELECT count(*)
                    FROM  
                      elisa_result els
                    INNER JOIN
                      experiment ex ON els.experiment_accession=ex.experiment_accession
                    INNER JOIN
                      biosample bs ON els.biosample_accession=bs.biosample_accession
                    LEFT OUTER JOIN
                      expsample_2_file_info es2fi ON els.expsample_accession=es2fi.expsample_accession
                    LEFT OUTER JOIN
                      file_info fi ON es2fi.file_info_id=fi.file_info_id
                    WHERE els.study_accession in (\'", study_id,"\') AND
                          ex.purpose != 'Neutralizing_Antibody_Titer'", sep="")
  
  count <- dbGetQuery(conn,statement=sql_stmt)
  
  count[1,1]
}