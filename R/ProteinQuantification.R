#' Protein Quantification Domain
#' 
#' @name Protein Quantification Domain
#' @description The ImmPort study data generated from assays of types: ELISA and MBAA are grouped into the 
#' Cellular Quantification Domain. The data is reformated to a custom Protein Quantification domain model in 
#' CDISC SDTM standards, and is a list of 2 data frames containing 1) Protein Quantification data \code{\link{ZA}} 
#' and 2) any supplemental Protein Quantification data \code{\link{SUPP}}
NULL
#> NULL 

pq_cols <- c("STUDYID", "DOMAIN", "USUBJID", "ZASEQ", "ZATEST", "ZACAT", "ZAMETHOD", "ZAANALYT", "ZAORRES", 
    "ZAORRESU", "ZASPEC", "ZASPECSB", "VISIT", "ZAELTM", "ZATPTREF", "ZATPT0", "ZATPT0SP", "ZAREFID", "ZAXFN")

supppq_cols <- c("STUDYID", "RDOMAIN", "USUBJID", "IDVAR", "IDVARVAL", "QNAM", "QLABEL", "QVAL")

# call to globalVariables to prevent from generating NOTE: no visible binding for global variable <variable name>
# this hack is to satisfy CRAN (http://stackoverflow.com/questions/9439256/how-can-i-handle-r-cmd-check-no-visible-binding-for-global-variable-notes-when)
globalVariables(c("subject_id", "result_id", "experiment_title", "assay_purpose", "measurement_technique",
                  "analyte", "value", "unit", "specimen_type",
                  "specimen_subtype", "visit_name", "elapsed_time_of_specimen_collection", "time_point_reference",
                  "biosample_accession", "file_name", "concentration_value", "concentration_unit", 
                  "mfi", "mfi_coordinate", "QNAM", "QVAL", "ZAMFI", "ZAMFICRD"))

# Get Protein Quantification data of a specific study
# 
# The function \code{getProteinQuantification} queries the ImmPort database for Protein Quantification data and 
# reformats it to a custom Protein Quantification domain model in CDISC SDTM standards. 
# 
# @param data_src A data_srcection handle to ImmPort (MySQL or SQLite) database instance or 
# a directory handle to folder where study RDS files are located
# @param study_id Identifier of a specific study
# @param assay_type Assay Type **optional**
# @return a list of 2 data frames containing 1) Protein Quantification data \code{\link{ZA}} and 2) any supplemental 
#   Protein Quantification data \code{\link{SUPPZA}}
# @examples
# \dontrun{
#   # get all of study SDY1's Protein Quantification data
#   pq_l <- getProteinQuantification(data_src, "SDY1")
#   
#   # get study SDY1's Protein Quantification data that was generated using ELISA assay
#   pq_l <- getProteinQuantification(data_src, "SDY1", "ELISA")
# }
#' @importFrom dplyr %>% select
#' @importFrom reshape2 melt 
#' @importFrom plyr rename
getProteinQuantification <- function(data_src, study_id, assay_type="ALL") {
    cat("loading Protein Quantification data....")
    
    pq_df = data.frame()
    supppq_df = data.frame()

    if ((class(data_src)[1] == 'MySQLConnection') || 
        (class(data_src)[1] == 'SQLiteConnection')) {
      if ((assay_type == "ALL") || (assay_type =="ELISA")) {
        # get ELISA results
        measurement_types <- list("Protein_Quantification", "Cytokine_Quantification")
        els.df <- getElisaResults(data_src, study_id, "")
        if (nrow(els.df) > 0) {
            els.df <- select(els.df, STUDYID = study_id, USUBJID = subject_id, ZASEQ = result_id, ZATEST = experiment_title, 
                ZACAT = assay_purpose, ZAMETHOD = measurement_technique, ZAANALYT = analyte, ZAORRES = value, ZAORRESU = unit, 
                ZASPEC = specimen_type, ZASPECSB = specimen_subtype, 
                VISIT = visit_name, ZAELTM = elapsed_time_of_specimen_collection, ZATPTREF = time_point_reference, 
                ZAREFID = biosample_accession, ZAXFN = file_name)
            
            els.df$DOMAIN <- "ZA"
            
            els.df <- els.df[, c("STUDYID", "DOMAIN", "USUBJID", "ZASEQ", "ZATEST", "ZACAT", "ZAMETHOD", "ZAANALYT", "ZAORRES", 
                "ZAORRESU", "ZASPEC", "ZASPECSB", "VISIT", "ZAELTM", "ZATPTREF", "ZAREFID", "ZAXFN")]
  
            pq_df <- rbind(pq_df, els.df)
            
        }
      }
      
      if ((assay_type == "ALL") || (assay_type =="MBAA")) {
        
        # get MBAA results
        
        # mbaa_column_names <- c('study_id', 'subject_id', 'result_id', 'analyte', 'concentration_unit',
        # 'concentration_value', 'mfi', 'mfi_coordinate', 'experiment_title', 'assay_purpose', 'measurement_technique',
        # 'biosample_accession', 'specimen_type', 'specimen_subtype', 'elapsed_time_of_specimen_collection',
        # 'time_point_reference', 'file_name')
        measurement_types <- list("Cytokine_Quantification")
        mbaa_df <- getMbaaResults(data_src, study_id, "")
        if (nrow(mbaa_df) > 0) {
            mbaa_df <- mbaa_df %>% 
              select(STUDYID = study_id, USUBJID = subject_id, ZASEQ = result_id, ZATEST = experiment_title, 
                ZACAT = assay_purpose, ZAMETHOD = measurement_technique, ZAANALYT = analyte, ZAORRES = concentration_value, 
                ZAORRESU = concentration_unit, ZASPEC = specimen_type, ZASPECSB = specimen_subtype, 
                VISIT = visit_name, ZAELTM = elapsed_time_of_specimen_collection, 
                ZATPTREF = time_point_reference, 
                ZAREFID = biosample_accession, ZAXFN = file_name, ZAMFI = mfi, ZAMFICRD = mfi_coordinate)
            
            mbaa_df$DOMAIN <- "ZA"
            
            mbaa_df <- mbaa_df[, c("STUDYID", "DOMAIN", "USUBJID", "ZASEQ", "ZATEST", "ZACAT", "ZAMETHOD", "ZAANALYT", 
                "ZAORRES", "ZAORRESU", "ZASPEC", "ZASPECSB", "VISIT", "ZAELTM", "ZATPTREF", "ZAREFID", "ZAXFN", 
                "ZAMFI", "ZAMFICRD")]
    
            qnam_values = c("ZAMFI", "ZAMFICRD")
            qlabel_values= c("MFI", "MFI Coordinate")
            
            supp_mbaa_df <- melt(mbaa_df, 
                                           id = c("STUDYID", "DOMAIN", "USUBJID", "ZASEQ"), 
                                           measure = qnam_values, 
                                           variable.name = "QNAM", 
                                           value.name = "QVAL")
            supp_mbaa_df <- transform(supp_mbaa_df, QLABEL = unlist(qlabel_values[QNAM]))
            supp_mbaa_df <- rename(supp_mbaa_df, c("DOMAIN" = "RDOMAIN", "ZASEQ" = "IDVARVAL"))
            supp_mbaa_df$IDVAR <- "ZASEQ"
            
            supp_mbaa_df <- supp_mbaa_df[supppq_cols]
            
            # remove rows that have empty QVAL values
            supp_mbaa_df <- subset(supp_mbaa_df,QVAL!="")      
            
            mbaa_df <- subset(mbaa_df, select = -c(ZAMFI, ZAMFICRD))
    
            pq_df <- rbind(pq_df, mbaa_df)
            supppq_df <- rbind(supppq_df, supp_mbaa_df)
            
        }
      }
    } else {
      l <- loadSerializedStudyData(data_src, study_id, "Protein Quantification")
      if (assay_type == "ALL") {
        pq_df <- l[[1]]
        supppq_df <- l[[2]]
      } else {
        
      }
    }   

    cat("done", "\n")
    
    pq_l <- list()
    if (nrow(pq_df) > 0)
      pq_l <- list(za_df=pq_df, suppza_df=supppq_df)
    
    pq_l
} 

# Get count of Protein Quantification data of a specific study
# 
# The function \code{getCountOfProteinQuantification} queries the ImmPort database for count 
# of Protein Quantification data 
# 
# @param data_src A connection handle to ImmPort database instance
# @param assay_type Assay Type **optional**
# @param study_id Identifier of a specific study
# @return a count of Protein Quantification data 
# @examples
# \dontrun{
#   # get count of all of study SDY1's Protein Quantification data
#   count <- getCountOfProteinQuantification(data_src, "SDY1")
#   
#   # get count of study SDY1's Protein Quantification data that was generated using ELISA assay
#   count <- getCountOfProteinQuantification(data_src, "SDY1", "ELISA")
# }
getCountOfProteinQuantification <- function(data_src, study_id, assay_type="ALL") {
  count <- 0
  if ((assay_type == "ALL") || (assay_type =="ELISA")) 
    count <- count + getCountOfElisaResults(data_src, study_id)
  if ((assay_type == "ALL") || (assay_type =="MBAA")) 
    count <- count + getCountOfMbaaResults(data_src, study_id)
  
  count
}

##' Protein Quantification Domain Variables
##' @name ZA
##' @description {
##'   \tabular{ll}{
##'     \strong{Variable Name  } \tab \strong{Variable Label} \cr
##'     STUDYID \tab Study Identifier \cr
##'     DOMAIN  \tab Domain Abbreviation \cr
##'     USUBJID \tab Unique Subject Identifier \cr
##'     ZASEQ \tab Sequence Number \cr
##'     ZATEST \tab Protein Quantification Test Name \cr
##'     ZACAT \tab Category for Protein Quantification \cr
##'     ZAMETHOD \tab Measurement Technique \cr
##'     ZAANALYT \tab Analyte \cr
##'     ZAORRES \tab Result or Finding in Original Units \cr
##'     ZAORRESU \tab Original Units \cr
##'     ZASPEC \tab Specimen Type \cr
##'     ZASPECSB \tab Specimen Subtype \cr
##'     VISIT \tab Visit Name \cr
##'     ZAELTM \tab Planned Elapsed Time from Time Point Ref \cr
##'     ZATPTREF \tab Time Point Reference \cr
##'     ZAREFID \tab Specimen Identifier \cr
##'     ZAXFN \tab Raw Data File or Life Science Identifier
##'   }
##' }
NULL
#> NULL 

##' Protein Quantification Domain Supplemental Variables
##' @name SUPPZA
##' @description {
##'   \tabular{ll}{
##'     \strong{Variable Name} \tab \strong{Variable Label} \cr
##'     STUDYID \tab Study Identifier \cr
##'     RDOMAIN  \tab Related Domain Abbreviation \cr
##'     USUBJID \tab Unique Subject Identifier \cr
##'     IDVAR \tab Identifying Variable \cr
##'     IDVARVAL \tab Identifying Variable Value \cr
##'     QNAM \tab Qualifier Variable Name \cr
##'     QLABEL \tab Qualifier Variable Label \cr
##'     QVAL \tab Data Value
##'   }
##' }   
##' @note The following table enumerates the values in QNAM and QLABEL variables {
##'   \tabular{ll}{
##'     \strong{QNAM} \tab \strong{QLABEL} \cr
##'     ZAMFI \tab MFI \cr
##'     ZAMFICRD \tab MFI Coordinate 
##'   }
##' }
NULL
#> NULL

