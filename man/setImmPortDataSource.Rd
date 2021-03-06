% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/Study.R
\name{setImmPortDataSource}
\alias{setImmPortDataSource}
\title{Set ImmPort data ource}
\usage{
setImmPortDataSource(data_src)
}
\arguments{
\item{data_src}{A connection handle to ImmPort (MySQL or SQLite) database instance or
a directory handle to folder where study RImmPort-formatted (.rds) files located}
}
\description{
The function \code{setImmPortDataSource} sets the data source variable in RImmPort environment,
to the connection handle to the MySQL or SQLite database, or to the file directory where the
pre-created RImmPort-formatted files are stored.
}
\examples{
\dontrun{
  # example 1: ImmPort data source is MySQL database
  # set approriate values for dbUser, dbPassword, dbDatabase, dbHost, and dbPort in the
  # connection statement
  conn <- dbConnect(dbDriver('MySQL'), user=dbUser, password=dbPassword,
                    dbname=dbDatabase, host=dbHost, port=dbPort)
  setImmPortDataSource(conn)

  # example 2: ImmPort data source is SQLite database
  db_dir <- "~/ImmPortStudies/Db/" # directory where the SQLite database file is stored
  conn <- dbConnect(SQLite(), dbname=file.path(db_dir, "ImmPort.sqlite"))
  setImmPortDataSource(conn)

  # example 3: ImmPort data source is RImmPort-formatted(.rds) data
  rds_dir <- "~/ImmPortStudies/Rds/" # directory where RImmPort-formatted(.rds) studyfiles
  are stored
  setImmPortDataSource(rds_dir)
}
}

