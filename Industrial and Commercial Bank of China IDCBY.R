library(forecast)
library(fpp)
library(quantmod) #Quantitative Financial Modelling
library(xts)
library(TTR) #Technical Trading Rules pkg
library(tseries)

## 1. Kunlun Energy Company 

####################### Getting Data ###################################
getSymbols("IDCBY", from="2013-01-01", to="2018-02-28")
class(IDCBY)
str(IDCBY)
head(IDCBY)
tail(IDCBY)
IDCBY$IDCBY.Close[1:5]
# dates -> index
dt=index(IDCBY); length(dt); dt[1]; dt[length(dt)]
sum(is.na(IDCBY)) ## NO MISSING 
######################### Plotting ######################################
#plot data
chartSeries(IDCBY, type = c("auto", "candlesticks", "matchsticks", "bars","line"), 
            subset = NULL,
            show.grid = TRUE, 
            name = NULL,
            log.scale = FALSE,
            TA = 'addVo()',
            TAsep=';',
            line.type = "l",
            bar.type = "ohlc",
            theme = chartTheme("black"))

# plot a subset of the data
chartSeries(IDCBY, subset='2014-01-01/2014-12-31', type='line', name ='IDCBY.Close', TA=NULL)
chartSeries(IDCBY, subset='last 4 months', type='bars', name ='IDCBY.Close', TA=NULL)
chartSeries(IDCBY, subset='last 4 months', theme="black", TA=NULL) #draw the chart 
addSMA()
addVo() #add volume 
addBBands() #add Bollinger Bands 
addCCI() #add Commodity Channel Index

#Simple plotting the Close
IDCBY.c=IDCBY$IDCBY.Close
plot(IDCBY.c, main='IDCBY.Close')

# add the 50 period simple moving average to panel 1 of the plot
lines(SMA(IDCBY.c, n = 50), on=1, col="green")

# add month end points to the chart
points(IDCBY.c[endpoints(IDCBY.c, on = "months")], col="red", pch=40, on=1)

# add legend to panel 1
addLegend("topright", on=1,legend.names = c("Close", "SMA(50)"),lty=c(1, 1), lwd=c(2, 1),
          col=c("black", "green", "red"))

######################### Returns #############################
#######################################################################
head(IDCBY)
IDCBY.c=IDCBY$IDCBY.Close

# simple return
simple.ret = Delt(IDCBY.c, type="arithmetic")[-1] #simple return R = P(t)/P(t-1) - 1
# plot the close and add a panel with the simple returns
plot(IDCBY.c, main='IDCBY.Close')
lines(simple.ret, type="h", on=NA)

# log return
log.ret = Delt(IDCBY.c, type="log")[-1]  #log return r = ln(1+R) = ln(P(t)/P(t-1))
# plot the close and add a panel with the simple returns
plot(IDCBY.c, main='IDCBY.Close')
lines(log.ret, type="h", on=NA)

###############################################################################
##################################################################################
#if we want to use xts format for derived variables:
df.tmp = data.frame(IDCBY$IDCBY.Volume[-1])
df.tmp$IDCBY.lrt <- log.ret
IDCBY.xts.lrt = as.xts(df.tmp$IDCBY.lrt)
chartSeries(IDCBY.xts.lrt, subset='last 4 years', theme="white", TA=NULL, type='line', name ='IDCBY.log.ret')

#please read quantmod manual to familiarize yourself with capabilities
addSMA() #simple moving average
addEMA(100) #exponential moving average
###addVo() #add volume 
addBBands() #add Bollinger Bands 
addCCI() #add Commodity Channel Index    

########################### Distributional properties of returns ##############
#############################################################################
IDCBY.c.v=as.numeric(IDCBY.c);
acf(IDCBY.c.v)
plot(IDCBY.c.v, type='l')
summary(IDCBY.c.v)
log.ret.v=as.numeric(log.ret);
plot(log.ret.v, type='l')
########################### Normality tests ###################################
#need additional tools
library(moments)
library(fitdistrplus)
library(metRology)  #has implementation of scaled and shifted t distribution.
library(goftest)
## Perform the Shapiro-Wilk normality test
shapiro.test(log.ret.v)
#Anderson-Darling test 
ad.test(log.ret.v,null='pnorm')
#Cramer-Von Mises Test
cvm.test(log.ret.v, null='pnorm')  

###############################################################################
###################### Normal and log-Normal distributions ######################
mean(IDCBY.c); var(IDCBY.c); skewness(IDCBY.c); kurtosis(IDCBY.c)
mean(log.ret); var(log.ret); skewness(log.ret); kurtosis(log.ret)

plot(density(log.ret.v))
plot(density(exp(log.ret.v)))
plot(ecdf(log.ret.v),main="Empirical CDF")
fit <- fitdist(log.ret.v, "norm")
plot(fit, histo = FALSE, demp = TRUE)
gofstat(fit)
#or one by one
cdfcomp(fit, addlegend=FALSE)
denscomp(fit, addlegend=FALSE,breaks=100)
ppcomp(fit, addlegend=FALSE)
qqcomp(fit, addlegend=FALSE)          

######################## Check stationarity ##################################
### Rejecting the null hypothesis suggests that a time series is stationary
adf.test(IDCBY.c);#- p=0.1741 # non-stationary
kpss.test(IDCBY.c)  # p << 0.01 #Clearly non-stationary!!!!!!!!!!!!!          

log.ret = Delt(IDCBY.c, type="log")[-1]  
adf.test(log.ret);#- p<<0.01  # stationary
kpss.test(log.ret)  # p > 0.1 #Clearly stationary!!!!!!!!!!!!

#chartSeries(TCEHY)
chartSeries(log.ret)          

###################### Is the TS really stationary? ####################################
log.ret.1 <- log.ret['2014-09-22/2015-09-21']
mean(log.ret.1); var(log.ret.1)
log.ret.2 <- log.ret['2016-09-22/2017-09-21']
mean(log.ret.2); var(log.ret.2)

#mu2 > 5*mu1;  var2 < 0.25*var1 
#Conclusion the TS of log-returns of BABA is NOn-Stationary!!!!!!!!!!!!!!!
###########################################################################
################# Check serial correlation vs. i.i.d. ####################
############### Dynamic trend / Seasonality #################################
#############################################################################################
acf(log.ret)  
acf(log.ret.1) 
acf(log.ret.2) 
#Conclusion - the market's regime has changed
#Box-Pierce test for serial correlation
Box.test(log.ret)   #p-value = 0.2479 Conclusion - there is NO serial correlation !!!!!
Box.test(log.ret.1)  #p-value = 0.003632Conclusion - there is serial correlation
Box.test(log.ret.2)  #p-value = 0.01707 - there is serial correlation !!!!

############################# Modelling Patterns ##############################
# Plot daily closing prices for Alibab (IDCBY & AMZN)
getSymbols("IDCBY", src="google")
plot(Cl(IDCBY))

getSymbols("AMZN", src="google")
plot(Cl(AMZN))

# Create differenced log returns 
# and plot their values and correlogram
IDCBYrt = diff(log(Cl(IDCBY)))[-1]
head(IDCBYrt); tail(IDCBYrt)
plot(IDCBYrt)
plot(density(IDCBYrt))
acf(IDCBYrt, na.action=na.omit)
wilcox.test(as.numeric(IDCBYrt))
adf.test(IDCBYrt) #-stationary
kpss.test(IDCBYrt)
Box.test(IDCBYrt) 

amznrt = diff(log(Cl(AMZN)))[-1]
head(amznrt); tail(amznrt)
plot(amznrt)
plot(density(amznrt))
acf(amznrt, na.action=na.omit)
wilcox.test(as.numeric(amznrt))  #not Normal
adf.test(amznrt) #-stationary
kpss.test(amznrt)
Box.test(amznrt) #- p-value = 0.6298 - No serial correlation !!!!

# Plot the correlogram
acf(abs(IDCBYrt))
acf(abs(amznrt))

#fit to normal
fit_amzn <- fitdist(as.numeric(amznrt), "norm")
gofstat(fit_amzn)

fit_IDCBY <- fitdist(as.numeric(IDCBYrt), "norm")
gofstat(fit_IDCBY)

#summary(fit)
plot(fit_amzn, histo = FALSE, demp = TRUE)
kurtosis(as.numeric(amznrt))

plot(fit_IDCBY, histo = FALSE, demp = TRUE)
kurtosis(as.numeric(IDCBYrt))  #### not normal!!!!

#fit to Student's t distribution for 'df' degrees of freedom, shifted by 'mean' and scaled by 'sd'.
library("metRology") #--#has implementation of the non-standard t-distribution
fit_amzn <- fitdist(as.numeric(amznrt),"t.scaled",
                    start=list(df=3,mean=mean(as.numeric(amznrt)),sd=sd(as.numeric(amznrt))))
plot(fit_amzn, histo = FALSE, demp = TRUE)
fit_amzn$estimate                    

fit_IDCBY <- fitdist(as.numeric(IDCBYrt),"t.scaled",
                     start=list(df=3,mean=mean(as.numeric(IDCBYrt)),sd=sd(as.numeric(IDCBYrt))))
plot(fit_IDCBY, histo = FALSE, demp = TRUE)
fit_IDCBY$estimate 
# ---> better fit to T distribution
###################################################################################
########################### MA(q) process #######################################
# Fit an ARIMA(0, 0, 1) model (i.e. MA(1) ) 
# and plot the correlogram of the residuals
IDCBYrt.ma <- arima(IDCBYrt, order=c(0, 0, 1))
acf(IDCBYrt.ma$res[-1])

# Fit an ARIMA(0, 0, 2) model (i.e. MA(2) ) 
# and plot the correlogram of the residuals
IDCBYrt.ma <- arima(IDCBYrt, order=c(0, 0, 2))
acf(IDCBYrt.ma$res[-1]) 
# the distribution of baba MA[1] AND MA[2] are THE SAME!!!

#######################################################################
################## ARMA(p,q) ###########################################
# Loop over p = 0 to 4, q = 0 to 4 and create each
# ARMA(p,q) model, then fit to the previous amznrt 
# returns, using the AIC to find the best fit
IDCBYfinal.aic <- Inf
IDCBYfinal.order <- c(0,0,0)
for (i in 0:4) for (j in 0:4) {
  IDCBYcurrent.aic <- AIC(arima(IDCBYrt, order=c(i, 0, j)))
  if (IDCBYcurrent.aic < IDCBYfinal.aic) {
    IDCBYfinal.aic <- IDCBYcurrent.aic
    IDCBYfinal.order <- c(i, 0, j)
    IDCBYfinal.arma <- arima(IDCBYrt, order=IDCBYfinal.order)
  }
}

# Output the results of the fit
IDCBYfinal.order  #[1] 2 0 4 

# Plot the residuals of the final model
acf(resid(IDCBYfinal.arma), na.action=na.omit)

# Carry out a Ljung-Box test for realisation
# of discrete white noise
Box.test(resid(IDCBYfinal.arma), lag=20, type="Ljung-Box")

plot(density(IDCBYfinal.arma$residuals))

wilcox.test(resid(IDCBYfinal.arma))
adf.test(resid(IDCBYfinal.arma)) #-stationary
kpss.test(resid(IDCBYfinal.arma))

# Plot the correlogram
acf(abs(resid(IDCBYfinal.arma)))   ## still correlated

#fit to normal
fit_IDCBY <- fitdist(as.numeric(resid(IDCBYfinal.arma)), "norm")
gofstat(fit_IDCBY)
#summary(fit)
plot(fit_IDCBY, histo = FALSE, demp = TRUE)
## ----> fit to normal? rather than T dist??????

#fit to Student's t distribution for 'df' degrees of freedom, shifted by 'mean' and scaled by 'sd'.
fit_IDCBY <- fitdist(as.numeric(resid(IDCBYfinal.arma)),"t.scaled",
                     start=list(df=3,mean=mean(as.numeric(resid(IDCBYfinal.arma))),sd=sd(as.numeric(resid(IDCBYfinal.arma)))))
plot(fit_IDCBY, histo = FALSE, demp = TRUE)
fit_IDCBY$estimate 

library(PerformanceAnalytics)  #great pkg
#######################################################################
################## ARIMA ###########################################
getSymbols("IDCBY", src="google")
IDCBY.c=IDCBY$IDCBY.Close
log.ret = Delt(IDCBY.c, type="log")[-1]  #log return r = ln(1+R) = ln(P(t)/P(t-1))
# plot the close and add a panel with the simple returns
plot(IDCBY.c, main='IDCBY.Close')
plot(log.ret, type="l", on=NA)
acf(log.ret)  #no correlation in log-returns
pacf(log.ret)
Box.test(log.ret)
#proxy for volatility
plot(abs(log.ret), type="l", on=NA)
acf(abs(log.ret))
Box.test(abs(log.ret))  # p-value = 0.0009208: NO correlation in volatility?
#########################################################
# Determine the best fitting ARIMA model
IDCBYfinal.aic <- Inf
IDCBYfinal.order <- c(0,0,0)
for (p in 1:4) for (d in 0:1) for (q in 1:4) {
  IDCBYcurrent.aic <- AIC(arima(log.ret, order=c(p, d, q)))
  if (IDCBYcurrent.aic < IDCBYfinal.aic) {
    IDCBYfinal.aic <- IDCBYcurrent.aic
    IDCBYfinal.order <- c(p, d, q)
    IDCBYfinal.arima <- arima(log.ret, order=IDCBYfinal.order)
  }
}

IDCBYfinal.order  ## 2 0 4 

# Plot a correlogram of the residuals, calculate 
# the Ljung-Box test and predict the next 25 daily
# values of the series
acf(resid(IDCBYfinal.arima), na.action=na.omit)
Box.test(resid(IDCBYfinal.arima), lag=20, type="Ljung-Box") #no correlations!
plot(resid(IDCBYfinal.arima))
acf(abs(resid(IDCBYfinal.arima)))  #still have some unused information
#try to fit to normal distribution
fit_IDCBY <- fitdist(as.numeric(resid(IDCBYfinal.arima)), "norm")
plot(fit_IDCBY, histo = FALSE, demp = TRUE)  # not normal!!!

#fit to Student's t distribution for 'df' degrees of freedom, shifted by 'mean' and scaled by 'sd'.
fit_IDCBY <- fitdist(as.numeric(resid(IDCBYfinal.arima)),"t.scaled",
                     start=list(df=3,mean=mean(as.numeric(resid(IDCBYfinal.arima))),sd=sd(as.numeric(resid(IDCBYfinal.arima)))))
plot(fit_IDCBY, histo = FALSE, demp = TRUE)  # clearly fat-tailedl!!!
##############################################################

#use the forecast library to automatically determine ARIMA coefficients
fit_IDCBY <- auto.arima(log.ret)
fit_IDCBY ## 0 0 0 ???
fit_IDCBY$arima$coef  #forecast pkg yields AR(1)
plot(fit_IDCBY$residuals)
Acf(fit_IDCBY$residuals)  # bad fitting
plot(forecast(IDCBY.c, h=50)) #bad forcast

############################### GARCH ######################################################
# Fit a GARCH model to resid(tencnetfinal.arima)
ft.garch <- garch(resid(IDCBYfinal.arima), trace=F)
ft.res <- ft.garch$res[-1]
length(resid(IDCBYfinal.arima))
#fit to Student's t distribution for 'df' degrees of freedom, shifted by 'mean' and scaled by 'sd'.
fit <- fitdist(ft.res,"t.scaled", start=list(df=3,mean=mean(ft.res),sd=sd(ft.res)))
plot(fit, histo = FALSE, demp = TRUE)

# Plot the residuals and abs residuals
acf(ft.res)
acf(abs(ft.res))  # no correlations/no information left!!!         





########## Uderlying Stock: Hong Kong Exchange ###############
### library(Quandl)
### Quandl.api_key("xPCxT4avL3ymcTUyvT7N")
### aacay <- Quandl("XHKG/00914", start_date="2013-01-01", end_date="2018-01-01")

getSymbols("1398.HK", from="2013-01-01", to="2018-02-28")

head(`1398.HK`)
tail(`1398.HK`)
sum(is.nan(`1398.HK`))  ### no missing values
# dates -> index
dt=index(`1398.HK`); length(dt); dt[1]; dt[length(dt)]

######################### Plotting ######################################
#plot data
chartSeries(`1398.HK`, type = c("auto", "candlesticks", "matchsticks", "bars","line"), 
            subset = NULL,
            show.grid = TRUE, 
            name = NULL,
            log.scale = FALSE,
            TA = 'addVo()',
            TAsep=';',
            line.type = "l",
            bar.type = "ohlc",
            theme = chartTheme("black"))
#######---> in HK more volitile...????

# plot a subset of the data
chartSeries(`1398.HK`, subset='2014-01-01/2014-12-31', type='line', name ='1398.HK.Close', TA=NULL)
chartSeries(`1398.HK`, subset='last 4 months', type='bars', name ='1398.HK.Close', TA=NULL)
chartSeries(`1398.HK`, subset='last 4 months', theme="white", TA=NULL) #draw the chart 
addSMA()
addVo() #add volume 
addBBands() #add Bollinger Bands 
addCCI() #add Commodity Channel Index

###### the same steps
##### Normality
##### Stationality
##### ARMA & ARIMA
##### GARCH