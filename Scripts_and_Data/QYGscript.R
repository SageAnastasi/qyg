## Welcome to the code for Quantify Your Gays! This script requires the data to have been
## downloaded in order to run

library(dplyr)
library(car)
tvdata <- read.csv("queer-character-data.csv")
tvdata <- tvdata[c(-11,-12,-13,-14)]

#obtaining death rate per year
make_atomised <- function(tvrow){
  #because it is a mix of data it gets treated as text
  show <- tvrow["show"]
  name <- tvrow["name"]
  start <- as.numeric(tvrow["year_introduced"])
  stop <- as.numeric(tvrow["year_finished"])
  season <- start:stop
  report <- data.frame(season = season)
  report$show <- show
  report$name <- name
  report$dead <- FALSE
  print(tvrow["dead"])
  print(typeof(tvrow["dead"]))
  if(trimws(tvrow["dead"]) == "TRUE"){ #note there is a leading space in the original
    report$dead[length(report$dead)] <- TRUE #last is TRUE if orginal was TRUE
  }
  return(report)
}

longformlist <- apply(tvdata,1,make_atomised)
liveOrDie <- do.call(rbind, longformlist) #liveordie is the by year records
rm(longformlist)
percyr <- liveOrDie %>% group_by(season) %>% summarise(percentDead = sum(dead)/n(), total_n = n())
View(percyr)

percyrModern <- percyr[percyr$season >= 1995,]

tvMen <- tvdata[tvdata$is_male==T,]
longformlist <- apply(tvMen,1,make_atomised)
liveOrDie <- do.call(rbind, longformlist) #liveordie is the by year records
rm(longformlist)
percyrMen <- liveOrDie %>% group_by(season) %>% summarise(percentDead = sum(dead)/n(), total_n = n())
View(percyrMen)

percyrMenModern <- percyrMen[percyrMen$season >= 1995,]

tvWomen <- tvdata[tvdata$is_male==F,]
longformlist <- apply(tvWomen,1,make_atomised)
liveOrDie <- do.call(rbind, longformlist) #liveordie is the by year records
rm(longformlist)
percyrWomen <- liveOrDie %>% group_by(season) %>% summarise(percentDead = sum(dead)/n(), total_n = n())
View(percyrWomen)

percyrWomenModern <- percyrWomen[percyrWomen$season >= 1995,]


#descrptive stats
table(tvdata$dead,tvdata$is_male)

#chisq
tbl <- matrix(c(617,888,130,93),ncol=2,byrow=T)
colnames(tbl) <- c("Female","Male")
rownames(tbl) <- c("Alive","Dead") #accounting for a true\n bug
print(tbl)
chisq.test(tbl)

alldeath <- percyrModern$percentDead*100 #conversion out of decimal
mendeath <- percyrMenModern$percentDead*100
womendeath <- percyrWomenModern$percentDead*100

mean(alldeath)
mean(mendeath)
mean(womendeath)
median(alldeath)
median(mendeath)
median(womendeath)

#linear regression
allregr <- lm(alldeath~percyrModern$season)
summary(allregr)
durbinWatsonTest(allregr) #testing the model for serial correlation
allintercept <- lm(alldeath~1)
plot(percyrModern$season,alldeath)
abline(allregr)
abline(allintercept,lty=2)

#time squared regression
allsquared <- lm(alldeath~percyrModern$season+I(percyrModern$season^2))
summary(allsquared)
durbinWatsonTest(allsquared)
plot(percyrModern$season,alldeath)
lines(percyrModern$season,allsquared$fitted.values)
abline(allintercept,lty=2)

#by gender
mensquared <- lm(mendeath~percyrMenModern$season+I(percyrMenModern$season^2))
summary(mensquared)
menintercept <- lm(mendeath~1)
durbinWatsonTest(mensquared)
plot(percyrMenModern$season,mendeath)
lines(percyrMenModern$season,mensquared$fitted.values)
abline(menintercept,lty=2)

womensquared <- lm(womendeath~percyrWomenModern$season+I(percyrWomenModern$season^2))
summary(womensquared)
womenintercept <- lm(womendeath~1)
durbinWatsonTest(womensquared)
plot(percyrWomenModern$season,womendeath)
lines(percyrWomenModern$season,womensquared$fitted.values)
abline(womenintercept,lty=2)

#cook's distances

plot(cooks.distance(allsquared))
abline(4/22,0,lty=2)
plot(cooks.distance(mensquared))
abline(4/22,0,lty=2)
plot(cooks.distance(womensquared))
abline(4/22,0,lty=2)
abline(1,0)

#regressions without 2016
alldeath <- alldeath[-22]#2016 is the 22nd entry; this drops it from the vector
year <- percyrModern$season[-22]
yearsquared <- year^2
allsquared <- lm(alldeath~year+yearsquared)
interceptall <- lm(alldeath~1)
summary(allsquared)
durbinWatsonTest(allsquared)

mendeath <- mendeath[-22]
mensquared <- lm(mendeath~year+yearsquared)
menintercept <- lm(mendeath~1)
summary(mensquared)
durbinWatsonTest(mensquared)

womendeath <- womendeath[-22]
womensquared <- lm(womendeath~year+yearsquared)
womenintercept <- lm(womendeath~1)
summary(womensquared)
durbinWatsonTest(womensquared)

#generating figures for paper
alldeath <- percyrModern$percentDead*100
year <- percyrModern$season
yearsquared <- year^2

allintercept <- lm(alldeath~1)
allsquared <- lm(alldeath~year+yearsquared)

allregr <- lm(alldeath~year)
plot(year,alldeath,xlab = "Year",ylab = "Death rate (percent of population)",main = "Death rate of all queer characters per year")
lines(percyrModern$season,allregr$fitted.values)
abline(allintercept,0,lty=2)

plot(percyrModern$season,alldeath,xlab = "Year",ylab = "Death rate (percent of population)",main = "Death rate of all queer characters per year")
lines(percyrModern$season,allsquared$fitted.values)
abline(allintercept,0,lty=2)

plot(cooks.distance(allsquared),xlab = "Year (normalised, 1995 -> 1)",ylab = "Cook's Distance",main = "Cook's Distances from the time-squared model")
abline(4/22,0,lty=2)

alldeath <- alldeath[-22]
year <- percyrModern$season[-22]
yearsquared <- year^2
allsquared <- lm(alldeath~year+yearsquared)
plot(year,alldeath,xlab = "Year",ylab = "Death rate (percent of population)",main = "Death rate of all queer characters per year")
lines(year,allsquared$fitted.values)
abline(allintercept,0,lty=2)

par(mfrow=c(1,2))
plot(year,mendeath,xlab = "Year",ylab = "Death rate (percent of population)",main = "Men")
lines(year,mensquared$fitted.values)
menintercept <- lm(mendeath~1)
abline(menintercept,0,lty=2)
plot(year,womendeath,xlab = "Year",ylab = "Death rate (percent of population)",main = "Women")
lines(year,womensquared$fitted.values)
womenintercept <- lm(womendeath~1)
abline(womenintercept,0,lty=2)
