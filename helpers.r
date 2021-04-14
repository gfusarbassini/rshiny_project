### fetch info from FIDAL website
fetch <- function() {
  
  #ptm <- proc.time()
  page <- read_html("http://www.fidal.it/societa/ASD-NUOVA-VIRTUS-CREMA/CR810")

  surname <- html_nodes(page, xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "col1", " " ))]/a')
  name <- html_nodes(page, xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "col2", " " ))]')
  age <- html_nodes(page, xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "col3", " " ))]')
  
  #cut useless info
  name <- name[1:(length(age))]
  
  #join data in a more human friendly way
  athletes <- cbind(paste(html_text(name),html_text(surname)),html_text(age),html_attr(surname,"href"))
  athletes
}


### select athletes born after 2007
select_athletes <- function(athletes) {
  i <- 1
  while (i <= nrow(athletes)){
    if(as.numeric(athletes[i,2]) > 2007){
      athletes <- as.matrix(athletes[-i:-i,])
          }
    else {
      i = i + 1
    }
  }
  athletes
}


opponents <- function(link){
  page <- read_html(link)
  x <- html_nodes(page,"div h2, tr td")
  #cut useless parts  
  if(as.character(x[6])!="<td>2021</td>\n"){
    x[1:5] <- NULL
    x[which(sapply(as.character(x), FUN=function(X) '<h2 class="title-table">Non ventosi</h2>\n' %in% X)):length(x)]<-NULL
    
    disc <- html_text(x[which(sapply(substr(as.character(x),1,3), FUN=function(X) '<h2' %in% X))])
    #get disciplines
    disc
  }
  else c("No data")
}


### web data into matrix
tidy <- function(athletes) {
  #tidy surnames (there are some mistake in FIDAL's database)
  i <- 1
  while (i < length(athletes[,1])){
    if(substring(athletes[i,1],nchar(athletes[i,1]),nchar(athletes[i,1])+1)==" "){
      athletes[i,1] <- as.character((substring(athletes[i,1],1,nchar(athletes[i,1])-1)))
    }
    i = i + 1
  }
  athletes
}




create_opp_table <- function(athletes){
  #speed up with multicore function for windows
  cores <- detectCores()
  #choose all minus one cluster -> time is divided by cores
  cl <-makeCluster(cores-1, type="PSOCK")
  clusterExport(cl,list("read_html","html_nodes","html_text"))
  opp <- parLapply(athletes[,3], opponents, cl = cl)
  #close
  stopCluster(cl)
  #output every discipline for every athlete
  opp
}

#find opponents in a given discipline
find_opp <- function(indisc,opp,athletes){
  disc_opp <- list()
  j <- 1
  for (i in 1:length(athletes[,2])){
    if(!is.na(match(indisc,opp[[i]]))) {
      disc_opp[j] <- i
      j <- j + 1
    }
  }
  disc_opp
}

###some data are saved in other ways
marathon <- function(r){
  if(substring(r,2,2)=="h"){
    as.numeric(substring(r,1,1))*60 + as.numeric(gsub(":",".",substring(r,3,7)))
  }
  else if(substring(r,2,2)==":"){
    as.numeric(substring(r,1,1))*60 + as.numeric(substring(r,4,nchar(r)))
  }
  else if(substring(r,3,3)==":"){
    as.numeric(substring(r,1,2))*60 + as.numeric(substring(r,4,nchar(r)))
  }
  else r
}


###select results
retrive_results <- function(indisc,athlete){
  page <- read_html(athlete)
  x <- html_nodes(page,"div h2, tr td")
  #clean up data
  if(as.character(x[6])!="<td>2021</td>\n"){
    x[1:5] <- NULL
    #get results
    x[which(sapply(substr(as.character(x),1,6), FUN=function(X) '<td><f' %in% X))]<-NULL
    
    #cutting the discipline results
    startp <- match(indisc, html_text(x))
    endp <- match('<h2',substr(as.character(x[(startp+2):length(x)]),1,3))
    y <- html_text(x[(startp+1):(startp+endp)])
    matrix_y <- matrix(unlist(y), ncol = 9, byrow = TRUE)
  
    #don't forget unimdimensional cases
    if(length(matrix_y)>9) matrix_y <- cbind(paste(matrix_y[,1],substr(matrix_y[,2],3,5),"/",substr(matrix_y[,2],1,2),sep = ""),matrix_y[,5],matrix_y[,-c(1:6)])
  
    else matrix_y <- t(c(paste(matrix_y[,1],substr(matrix_y[,2],3,5),"/",substr(matrix_y[,2],1,2),sep = ""),matrix_y[,5],matrix_y[,-c(1:6)]))
    matrix_y[,3] <- gsub(" ","",matrix_y[,3])
  }
  matrix_y
}


###select disciplines
retrive_disciplines <- function(x){
  x[1:5] <- NULL
  x[which(sapply(as.character(x), FUN=function(X) '<h2 class="title-table">Non ventosi</h2>\n' %in% X)):length(x)]<-NULL

  html_text(x[which(sapply(substr(as.character(x),1,3), FUN=function(X) '<h2' %in% X))])
}

get_disciplines <- function(athlete,athletes){
  num_athlete <- which(sapply(athletes[,1], FUN=function(X) athlete %in% X))
  if(length(num_athlete) != 0){
    page <- read_html(athletes[num_athlete,3])
    x <- html_nodes(page,"div h2, tr td")
    
    if(as.character(x[6])!="<td>2021</td>\n"){
      disc <- retrive_disciplines(x)
      c("Select a discipline",disc)
    }
    else c("No competition available")
  }
  else c("Not an athlete")

}




#formatting due to different discipline times
format_result <- function(matrix_y){
  i <- 1
  result = list()
  while(i <= length(matrix_y[,3])){
    result[i] <- marathon(matrix_y[i,3])
    i = i + 1
  }
  result
}