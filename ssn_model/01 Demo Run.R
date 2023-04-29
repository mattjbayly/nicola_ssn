# This script provides a demo of the SSN package by
# Jay Ver Hoef, Erin Peterson and David Clfford

# See full tutorial here
# SSN: An R Package for Spatial Statistical Modeling on Stream Network
# https://www.fs.usda.gov/rm/boise/AWAE/projects/SSN_STARS/downloads/SSN/SSNvignette2014.pdf

# Load the SSN library of functions
library(SSN)

# Import SSN object
project_path <- "/NICA.ssn"
ssn_path <- "NICA.ssn"

# Example data include the BC Stream Invectory Sample Sites
# Load in the prediction points (2 mins)
nic_preds <- importSSN(ssn_path, predpts="preds")
names(nic_preds)

# Create distance matrices (5 mins)
createDistMat(nic_preds, o.write = FALSE, predpts="preds", amongpreds=T)

# Create raw torgegram
nic_preds <- Torgegram(nic_preds,"CHANNEL_WI",nlag=20)
plot(nic_preds, main = "Raw Data Torgegram")




spoktg <- Torgegram(spok,"WETD_WDTH",nlag=20)
plot(spoktg, main = "Raw Data Torgegram")
spoktg <- Torgegram(spok,"GRADIENT",nlag=20)
plot(spoktg, main = "Raw Data Torgegram")




# Function to standardize variables
stand <- function(x) { (x-mean(x))/(2*sd(x))}

# Function to standardize a prediction dataset based on the fitting dataset
stdpreds <- function(newset,originalset) {
  xnames <- colnames(newset)
  sx <- matrix(rep(NA,ncol(newset)*nrow(newset)),nrow=nrow(newset))
  for(i in 1:ncol(newset)) {
    var <- with(originalset,get(xnames[i]))
    sx[,i] <- (newset[,i]-mean(var))/(2*sd(var))
  }
  colnames(sx) <- colnames(newset)
  return(sx)
}

# Function to get fixed effects and SEs from glmssn. Used to make tables of outputs.
ests <- function(x) {
  means <- round(x$estimates$betahat,3)
  ses <- round(sqrt(diag(x$estimates$covb)),3)
  output <- cbind(means,ses)
  colnames(output) <- c("Estimate","SE")
  return(output)
}

# Set the working directory to the parent folder of the SSN.
setwd(project_path)
list.files()

# Load the ssn and all sets of prediction points
# Points were divided into three groups to prevent memory errors in ArcGIS.
# This wasnâ€™t necessary for later production units.
spok <- importSSN(ssn_path, predpts="preds")

# Create distance matrices
createDistMat(spok,o.write=T,predpts="preds",amongpreds=T)

names(spok)
# Create raw torgegram
spoktg <- Torgegram(spok,"CHNL_WDTH",nlag=20)
plot(spoktg, main = "Raw Data Torgegram")
spoktg <- Torgegram(spok,"WETD_WDTH",nlag=20)
plot(spoktg, main = "Raw Data Torgegram")
spoktg <- Torgegram(spok,"GRADIENT",nlag=20)
plot(spoktg, main = "Raw Data Torgegram")


# Extract dataframe and fit basic aspatial model with un-standardized predictors
spokdf <- getSSNdata.frame(spok)
head(spokdf, 1)
spok.lm <- lm(CHNL_WDTH ~ H2OAreaA + us_slope + us_vbf + us_frst, data=spokdf)
summary(spok.lm)

# Standardize continuous covariates and add factor for year
continuous <- spokdf[,c("H2OAreaA", "us_slope", "us_vbf", "us_frst")]
cont.s <- apply(continuous,2,stand)
colnames(cont.s) <- c("H2OAreaA_s", "us_slope_s", "us_vbf_s", "us_frst_s")
spokdf.s <- data.frame(spokdf, cont.s)
spoks <- putSSNdata.frame(spokdf.s,spok,"Obs")



# Version without glacier
spok.lm2 <- lm(CHNL_WDTH ~ H2OAreaA_s + us_slope_s + us_vbf_s + us_frst_s, data=spokdf.s)

# Extract pure aspatial parameter estimates, back-transform, and save both versions of estimates
# Must be careful about the order of parameters! No attempt is made to match them by name.
# This WILL need to be adjusted depending if glaciers are or are not used in the model.
# Ditto for tailwater.

spokAe <- summary(spok.lm2)$coefficients

# Aspatial performance
predictA <- predict(spok.lm2)
sqrt(mean((predictA-spokdf.s$CHNL_WDTH)^2))
# 2.399

# Examine correlations
library(ellipse)
cor(cont.s)
plotcorr(cor(cont.s),type="lower")
dev.off()

# Get VIFs from linear model as an indicator of multicollinearity
library(car)
vif(spok.lm)


###########
# Model1  #
###########

# We run all models with the same predictor variables, whether significant or not, except:
# Glacier and Tailwater are omitted as a covariates in units where they are absent
# In this unit we use tailwater but not glacier.

# Note that the correlation model structure was developed after testing of the Salmon and
# Clearwater production units. Once the model structure was finalized, we decided
# to run all final models using EstMeth= â€œMLâ€.
names(spoks)
starttime <- Sys.time() # not necessary; just for timing longer runs
spok1 <- glmssn(CHNL_WDTH ~ H2OAreaA + us_slope, spoks, EstMeth= "ML", family="gaussian", CorModels = c("Exponential.taildown","Exponential.Euclid"), addfunccol = "H2OAreaA")

elapsed <- Sys.time()-starttime # See above note
elapsed

# Extract predictions/ Leave-one-out cross validation predictions
spok1r <- residuals(spok1, cross.validation=T)
spok1rdf <- getSSNdata.frame(spok1r)

# Torgegram of fitted model residuals
spok1t <- Torgegram(spok1r,"_resid.crossv_",nlag=20)
plot(spok1t, main= "Model1 Residuals Torgegram")



#Root mean squared error (RMSE) of cross-validated predictions
sqrt(mean((spok1rdf[,"_CrossValPred_"]-spok1rdf$obsval)^2))
# 2.399

#RMSE of fixed effects only
sqrt(mean((spok1rdf[,"_fit_"]-spok1rdf$obsval)^2))
# 1.935

# Null RMSE
sqrt(mean((spok1rdf$obsval-mean(spok1rdf$obsval))^2))
# 2.996

#Pseudo-r2 of cross-validated predictions.
cor(spok1rdf$obsval,spok1rdf[,"_CrossValPred_"])^2
# 0.895



###############
# Predictions #
###############


# Split prediction datasets into pieces for computers with lowish RAM.
# The "chunksof" setting depends on available memory on the computer.
# 10-12K is about the limit on a machine with 16GB RAM.
# Used chunks of 7000 for predse and predsw just to make the two batches even, but 10K would have been OK too.
# Many datasets run without splitting on machines with 32GB RAM;
# I think all will run without splitting on machines with 64GB RAM.

# spok1$ssn.object <- splitPredictions(spok1$ssn.object, "prednorth",chunksof=10000)



# Make predictions
names(spok1)
class(spok1)
spok1p1 <- predict(spok1, predpointsID = "preds")
# spok1p2 <- predict(spok1,"prednorth-2")
# spok1p3 <- predict(spok1,"prednorth-3")
# spok1p4 <- predict(spok1,"predse-1")
# spok1p5 <- predict(spok1,"predse-2")
# spok1p6 <- predict(spok1,"predsw-1")
# spok1p7 <- predict(spok1,"predsw-2")

# Extrac prediction data frames
pred1df <- getSSNdata.frame(spok1p1,"preds")

plot(spok1p1)
?plot.glmssn.predict
plot.glmssn.predict(
  spok1p1,
  VarPlot = "Both",
  SEcex.min = 0.1,
  SEcex.max = 2)

head(pred1df)
class(pred1df)



# pred2df <- getSSNdata.frame(spok1p2,"prednorth-2")
# pred3df <- getSSNdata.frame(spok1p3,"prednorth-3")
# pred4df <- getSSNdata.frame(spok1p4,"predse-1")
# pred5df <- getSSNdata.frame(spok1p5,"predse-2")
# pred6df <- getSSNdata.frame(spok1p6,"predsw-1")
# pred7df <- getSSNdata.frame(spok1p7,"predsw-2")

# # Reassemble the pieces into one batch.
# allpreds <- rbind(pred1df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred2df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred3df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred4df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred5df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred6df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")],pred7df[,c("OBSPREDID","STREAM_AUG","STREAM_AUG.predSE")])
# # colnames(allpreds) <- c("OBSPREDID","predtemp","predtempse")
#
# # Export prediction dataset as a csv (good for general use) and dbf (good for GIS)
# write.csv(allpreds,"spok1preds.csv",row.names=F)
# write.dbf(allpreds,"spok1preds.dbf")

# # Compare predicted and observed at fitting sites, and export.
# predobs <- data.frame(spok1rdf$OBSPREDID,spok1rdf[,"_CrossValPred_"],spok1rdf$obsval)
# colnames(predobs) <- c("obspredid","predicted","observed")
# write.csv(predobs,"predobs.csv",row.names=F)
#
#
# ###########
# # Model2  #
# ###########
#
# # â€œAspatialâ€ model. Same predictors as spatial model. Includes random effects for site and year.
#
# starttime <- Sys.time()
# spok2 <- glmssn(STREAM_AUG ~ elev + canopy + slope + precip + drainage + lat + water + bfi + TAILWATER + airtemp + flow, spoks, EstMeth= "ML", family="gaussian",CorModels = c("locID","yearf"), addfunccol = "afvArea")
# elapsed <- Sys.time()-starttime
# elapsed
#
# # Extract predictions/ LOO CV predictions
# spok2r <- residuals(spok2,cross.validation=T)
# spok2rdf <- getSSNdata.frame(spok2r)
#
# # Create Torgegram of residuals
# spok2t <- Torgegram(spok2r,"_resid.crossv_",nlag=20)
# jpeg("spok2residtorg.jpg")
# plot(spok2t, main= "Model2 Residuals Torgegram")
# dev.off()
#
# #RMSPE of cross-validated predictions
# sqrt(mean((spok2rdf[,"_CrossValPred_"]-spok2rdf$obsval)^2))
# # 1.176
#
# #RMSPE of fixed effects only
# sqrt(mean((spok2rdf[,"_fit_"]-spok2rdf$obsval)^2))
# # 1.890
#
# # Null RMSPE
# sqrt(mean((spok2rdf$obsval-mean(spok2rdf$obsval))^2))
# # 2.996
#
# #r2 of cross-validated predictions.
# cor(spok2rdf$obsval,spok2rdf[,"_CrossValPred_"])^2
# # r2 = 0.846
#
# # Get parameter estimates, back-transform, and save both versions of estimates
# spok2e <- summary(spok2)$fixed.effects.estimates
# backtrans <- spok2e[-c(1,10),2:3]/(2*sapply(continuous[,c(1:7,9:11)],sd))
# esttable <- cbind(spok2e[,1],rbind(spok2e[1,2:3],backtrans[1:8,],spok2e[10,2:3],backtrans[9:10,]),spok2e[,2:5])
# write.csv(esttable,"spok2estimates.csv")
#
# # Save the full image including all modeling results. Optional.
# save.image(file = â€œspok.RData")
