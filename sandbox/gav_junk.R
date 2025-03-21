#rm(list = ls())
#setwd("C:/Users/macristina.perez/Documents/GitHub/hydra_diag/Diagnostics")
library(tidyverse)
source("R/read.report.R")
rundir <- "~/research/hydra_sim/"
output<-reptoRlist(paste0(rundir,"hydra_sim.rep"))
names(output)
head(output)

#Ncatch_obs 720
#Ncatch_size_obs 608
#Nsurvey_size_obs 1680
#Ndietprop_obs 4721
#catch_size_pred 1855

######### READ OBSERVED AND ESTIMATED SURVEY VALUES ###################
# need to make these reads dynamic
obs_survey<-read.table(paste0(rundir,"hydra_sim_NOBA-ts.dat"), skip=1695, nrows=1680, header=F)
colnames(obs_survey) <- c('number','year','species','type','InpN','1','2','3','4','5')
obs_survey<-obs_survey %>% pivot_longer(cols=6:10, names_to = "lenbin") %>%
  filter(value != -999)%>%
  mutate(lenbin = as.integer(str_remove(lenbin, "V")))
obs_survey$label<-rep(("survey"),each=7189)
#dim(obs_survey) #7189

pred_surv<-output$pred_survey_size
obs_survey$pred_surv<-pred_surv
nll_survey<-output$nll_survey_size
obs_survey$nll_surv<-nll_survey
obs_survey$pearson<-((obs_survey$value-obs_survey$pred_surv)/sqrt(obs_survey$pred_surv))

colnames(obs_survey) <- c('number','year','species','type','InpN','lenbin','obs_value','label',
                          'pred_value','nll','pearson')


######### READ OBSERVED AND PREDICTED CATCH VALUES ###################

obs_catch<-read.table("hydra_sim_NOBA-ts.dat", skip=4109, nrows=608, header=F)
colnames(obs_catch) <- c('number','area','year','species','type','InpN','1','2','3','4','5')
obs_catch<-obs_catch %>% pivot_longer(cols=7:11, names_to = "lenbin") %>%
  mutate(lenbin = as.integer(str_remove(lenbin, "V"))) %>%
  filter(value != -999)
obs_catch$label<-rep(("catch"),each=1855)
#dim(obs_catch) #1855

pred_catch<-output$pred_catch_size
obs_catch$pred_catch<-pred_catch
nll_catch<-output$nll_catch_size
obs_catch$nll_catch<-nll_catch
obs_catch$pearson<-((obs_catch$value-obs_catch$pred_catch)/sqrt(obs_catch$pred_catch))

colnames(obs_catch) <- c('number','area','year','species','type','InpN','lenbin','obs_value','label',
                         'pred_value','nll','pearson')


diet_catch<-full_join(obs_catch, obs_survey, by = NULL,copy = FALSE)

######### READ OBSERVED AND PREDICTED DIET PROPORTION VALUES ###################

obs_diet<-read.table("hydra_sim_NOBA-ts.dat", skip=4724, nrows=4721, header=F)
#obs_diet$label<-rep(("diet"),each=4721)
obs_diet<-obs_diet %>% pivot_longer(cols=6:17, names_to = "lenbin") %>%
  mutate(lenbin = as.integer(str_remove(lenbin, "V"))) %>%
  filter(value >0 )
obs_diet$label<-rep(("diet"),each=22810)
#dim(obs_diet) #22810

pred_diet<-output$pred_dietprop
obs_diet$pred_diet<-pred_diet
nll_diet<-output$nll_dietprop
obs_diet$nll_diet<-nll_diet
obs_diet$pearson<-((obs_diet$value-obs_diet$pred_diet)/sqrt(obs_diet$pred_diet))
colnames(obs_diet) <- c('number','year','species','lenbin','InpN','prey','obs_value','label', 'pred_value','nll','pearson')


mydata<-full_join(diet_catch, obs_diet, by = NULL,copy = FALSE)
mydata$prey[is.na(mydata$prey)] <- -99
mydata$area[is.na(mydata$area)] <- 1
mydata$type[is.na(mydata$type)] <- 0


#write.csv(mydata, file = "mydata.csv", row.names = T)


#####################################
############# PLOTS ##################
#####################################


rm(list = ls())
setwd("C:/Users/macristina.perez/Documents/GitHub/hydra_diag/Diagnostics")
data<-read.csv("mydata.csv", header = T)
head(data)

library(ggplot2)


names(data)
str(data)

#data.frame':	31854 obs. of  13 variables:
# $ number    : int  1 1 1 1 1 1 1 1 1 1 ...
# $ area      : int  1 1 1 1 1 1 1 1 1 1 ...
# $ year      : int  15 15 15 16 16 16 16 17 17 17 ...
# $ species   : int  1 1 1 1 1 1 1 1 1 1 ...
# $ type      : int  0 0 0 0 0 0 0 0 0 0 ...
# $ InpN      : int  605 605 605 792 792 792 792 820 820 820 ...
# $ lenbin    : int  2 3 4 2 3 4 5 2 3 4 ...
# $ obs_value : num  0.0281 0.557 0.4149 0.0278 0.5202 ...
# $ label     : chr  "catch" "catch" "catch" "catch" ...
# $ pred_value: num  0.3838 0.2157 0.0369 0.3505 0.2321 ...
# $ nll       : num  44.4 -319.8 -607.2 55.8 -332.5 ...
# $ pearson   : num  -0.574 0.735 1.967 -0.545 0.598 ...
# $ prey      : int  -99 -99 -99 -99 -99 -99 -99 -99 -99 -99 ...

# SPECIES
# 1 spinydog
# 2 winterskate
# 3 Aherring
# 4 Acod
# 5 haddock
# 6 yellowtailfl
# 7 winterfl
# 8 Amackerel
# 9 silverhake
# 10 goosefish
# 11 ?


#select type of data "label= catch, survey or diet"
temp.catch = data[which(data$label == "catch"),]
temp.surv = data[which(data$label == "survey"),]

#plot 1 length composition plots by species (catch)
#x11()
tiff("complot_catch.jpeg", width=3000, height=2500, res=250)
a<- ggplot(temp.catch[which(temp.catch$species == 1),], aes(x = lenbin, y = obs_value), ylim=c(0,0.8))
a<- a + geom_line() + theme(title = element_text(angle = 0, hjust = 0.5, size=15, colour="black"))
a<- a + geom_point() + labs(x="length bin", y="proportion value", title="Catch length comp by year")
a<- a + geom_line(aes(x = lenbin, y = pred_value), color = "green")
a<- a + facet_wrap(.~year)
a<- a + annotate("text",  x = 4.0, y = 0.6, label = "Sample size=", size=3)
a
dev.off()


# trying to add each sample size per year ..... NOT WORKING
#tapply(temp$InpN[which(temp$species == 1)], temp$year[which(temp$species == 1)], function(x) length(unique(x)))
N<-as.numeric(t(tapply(temp$InpN[which(temp$species == 1)], temp$year[which(temp$species == 1)], unique)))
a<- a + annotate("text",  x = 4.0, y = 0.6, label = paste("Sample size:", N, sep=""), size=3)



#plot 1 length composition plots by species (survey)
tiff("complot_survey.jpeg", width=3000, height=2500, res=250)
a<- ggplot(temp.surv[which(temp.surv$species == 1 & temp.surv$number == 1),], aes(x = lenbin, y = obs_value), ylim=c(0,0.8))
a<- a + geom_line() + theme(title = element_text(angle = 0, hjust = 0.5, size=15, colour="black"))
a<- a + geom_point() + labs(x="length bin", y="proportion value", title="Survey length comp by year")
a<- a + geom_line(aes(x = lenbin, y = pred_value), color = "blue")
a<- a + facet_wrap(.~year)
a<- a + annotate("text",  x = 4.0, y = 0.6, label = "Sample size=", size=3)
a
dev.off()

#plot 2 pearson residuals bubble plot

tiff("bubbleplot_catch.jpeg", width=3000, height=2500, res=250)
ggplot(temp.catch, aes(x=year, y=lenbin, size = res_abs, color=factor(resid))) +
  geom_point(alpha=0.7) + theme(title = element_text(angle = 0, hjust = 0.5, size=15, colour="black")) +
  facet_wrap(.~species) + labs(x="year", y="length bin", title="Pearson residuals")
dev.off()

# adding some text
#data_text = data.frame(x = 20, y = 3.5, species = unique(temp$species), label = c("Text_1", "", "Text_3", "Text_", "", "Text", "Text_R", "", ""))

#ggplot(temp.catch, aes(x = year, y = lenbin)) +
# geom_point(aes(color = factor(resid), size = res_abs), alpha = 0.5) +
#  scale_color_manual(values = c("blue", "lightblue")) +  theme(title = element_text(angle = 0, hjust = 0.5, size=15, colour="black")) +
#  facet_wrap(.~species) + theme(legend.position = ' ') + labs(x="year", y="length bin", title="Pearson residuals (catch)")# +
# geom_text(data = data_text, aes(x = x, y = y, label = label))


# plot 3 length composition plots by species aggregated by year (catch)

temporal2 = numeric()
especie = numeric(); especie = sort(unique(temp.catch$species)) # especies
for(e in 1:length(especie)){
  pos1 = numeric(); pos1 = which(temp.catch$species == especie[e])

  temporal1 = numeric()
  year = numeric(); year = sort(unique(temp.catch$year[pos1])) # ano
  for(y in 1:length(year)){
    pos2 = numeric(); pos2 = which(temp.catch$year[pos1] == year[y])

    N = numeric(); N = unique(temp.catch$InpN[pos1][pos2]) # sample size para el estrato especie ano
    n_ejemplares_obs = numeric(); n_ejemplares_obs = round(N * temp.catch$obs_value[pos1][pos2] , 0) # crea vector de proporcion por el sample size
    n_ejemplares_est = numeric(); n_ejemplares_est = round(N * temp.catch$pred_value[pos1][pos2], 0)

    tt1 = numeric()
    tt1 = data.frame(YEAR = year[y], BIN = temp.catch$lenbin[pos1][pos2], N = N, N_EJEM_OBS = n_ejemplares_obs, N_EJEM_EST = n_ejemplares_est)

    temporal1 = rbind(temporal1, tt1) # guarda la proporcion * sample size para la especie seleccionada y ano
  }

  bin1_obs = numeric(); bin1_obs = sum(temporal1$N_EJEM_OBS[which(temporal1$BIN == 1)])
  bin2_obs = numeric(); bin2_obs = sum(temporal1$N_EJEM_OBS[which(temporal1$BIN == 2)])
  bin3_obs = numeric(); bin3_obs = sum(temporal1$N_EJEM_OBS[which(temporal1$BIN == 3)])
  bin4_obs = numeric(); bin4_obs = sum(temporal1$N_EJEM_OBS[which(temporal1$BIN == 4)])
  bin5_obs = numeric(); bin5_obs = sum(temporal1$N_EJEM_OBS[which(temporal1$BIN == 5)])

  total_obs = sum(bin1_obs, bin2_obs, bin3_obs, bin4_obs, bin5_obs)
  prop_new_obs = numeric(); prop_new_obs = c(bin1_obs, bin2_obs, bin3_obs, bin4_obs, bin5_obs) / total_obs

  bin1_pred = numeric(); bin1_pred = sum(temporal1$N_EJEM_EST[which(temporal1$BIN == 1)])
  bin2_pred = numeric(); bin2_pred = sum(temporal1$N_EJEM_EST[which(temporal1$BIN == 2)])
  bin3_pred = numeric(); bin3_pred = sum(temporal1$N_EJEM_EST[which(temporal1$BIN == 3)])
  bin4_pred = numeric(); bin4_pred = sum(temporal1$N_EJEM_EST[which(temporal1$BIN == 4)])
  bin5_pred = numeric(); bin5_pred = sum(temporal1$N_EJEM_EST[which(temporal1$BIN == 5)])

  total_pred = sum(bin1_pred, bin2_pred, bin3_pred, bin4_pred, bin5_pred)
  prop_new_est = numeric(); prop_new_est = c(bin1_pred, bin2_pred, bin3_pred, bin4_pred, bin5_pred) / total_pred

  tt2 = numeric()
  tt2 = data.frame(ESPECIE = especie[e], BIN = seq(1, 5, 1), PROP_NEW_OBS = prop_new_obs, PROP_NEW_EST = prop_new_est)

  temporal2 = rbind(temporal2, tt2) # almacena por cada especie
}

# SUMA DE PROPORCIONES

x11()
tiff("compplot_year.jpeg", width=3000, height=2500, res=250)
ggplot(temporal2, aes(x = BIN, y = PROP_NEW_OBS)) +
  geom_line() +
  geom_point() +
  geom_line(aes(x = BIN, y = PROP_NEW_EST), color = "green") +
  annotate("text",  x = 4.3, y = 0.9, label = "Sample size=", size=4) +
  theme(title = element_text(angle = 0, hjust = 0.5, size=15, colour="black")) +
  labs(x="length bin", y="proportion value", title="Length composition aggregated by year") +
  facet_wrap(.~ESPECIE)
dev.off()

