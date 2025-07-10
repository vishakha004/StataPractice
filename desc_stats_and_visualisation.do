
***********************************************************************
**# ******* 1- Descriptive Statistics & Data Visualisations ***********
***********************************************************************

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/holiday_merged_data.dta",clear

*we will use the holiday_merged_dataset which only takes the first observation corresponding to every date. This ensures there is no repetition of tweet count variables.

*(a)


*function to calculate the required statistics

program define stats_matrix, rclass
    syntax varname

    quietly summarize `varlist'

    matrix stats = (r(N), r(mean), r(min), r(p50), r(max), r(sd))
    matrix colnames stats = N mean min median max sd
    matrix rownames stats = `varlist'
    matrix list stats
    return matrix stats = stats
end

*initialize empty matric and rownames
matrix all_stats = (., ., ., ., ., .)
local all_rownames placeholder


foreach var in tweet_count_all tweet_count_blm tweet_count_islam{
	stats_matrix `var'
	matrix row = r(stats)
    matrix all_stats = all_stats \ row
    local all_rownames `all_rownames' `var'
}
* Step 4: Set row and column names
matrix rownames all_stats = `all_rownames'
matrix colnames all_stats = N mean min median max sd

* Step 5: Display
matrix list all_stats

tempname memhold

postfile `memhold' str20 varname N mean min median max sd using "resultss.dta",replace
describe tweet_count_all tweet_count_islam tweet_count_blm
foreach v in tweet_count_all tweet_count_islam tweet_count_blm {
    quietly summarize `v', detail
	local N=r(N)
	local mean=r(mean)
	local min=r(min)
	local max=r(max)
	local median=r(p50)
	local sd=r(sd)
    post `memhold' ("`v'") (`N') (`mean') (`min') (`max') (`median') (`sd')
}

postclose `memhold'

use resultss, clear
list

*resultss is the required dataset

*******************************************
**# ******* Data Visualisations ***********
*******************************************

*(b) visualisation of individual tweet count variables

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/holiday_merged_data.dta",clear

*histogram-  all 3 variables shows heavily right skewed distributions as depicted by both histogram and the kernel density estimates. 
histogram tweet_count_all
histogram tweet_count_all, bins(50)

histogram tweet_count_islam
histogram tweet_count_islam, bins(50)

histogram tweet_count_blm
histogram tweet_count_blm, bins(50)

kdensity tweet_count_all
kdensity tweet_count_all, bw(100)

kdensity tweet_count_islam
kdensity tweet_count_islam, bw(100)

kdensity tweet_count_blm
kdensity tweet_count_blm, bw(100)

*comparative kdensity plots- we first normalise the variables o getter a magnitude-adjusted picture

summarize tweet_count_all
gen z_all = (tweet_count_all - r(mean)) / r(sd)

summarize tweet_count_islam
gen z_islam = (tweet_count_islam - r(mean)) / r(sd)

summarize tweet_count_blm
gen z_blm = (tweet_count_blm - r(mean)) / r(sd)

twoway (kdensity z_all, lcolor(blue) lpattern(solid)) (kdensity z_islam, lcolor(red) lpattern(dash)) (kdensity z_blm, lcolor(green) lpattern(dot)), legend(order(1 "All" 2 "Islam" 3 "BLM")) title("Kernel Density Estimates") 

*quantile plot- the quantile plot also shows severe non-normality in the variables
quantile tweet_count_all

quantile tweet_count_islam

quantile tweet_count_blm

*boxplot- right skewed non normal distribution- good for showing outliers in the dataset
graph box tweet_count_all tweet_count_islam tweet_count_blm

*The best graph for such visualisations is a kernel density estimate. It accurately depicts the distribution, can be plotted together for comparison and we do not have to worry about breaks in the data due to bandwidth smoothing.

*(c) The distribution of all three variables is highly right skewed. This could cause issues such as non-normality of residuals when running regressions, which violates Gauss Markov assumptions. It can also leads to heteroskedasticity. The influence of outliers could also dominate regression results, pulling coefficients and increasing standard errors. All this can lead to poor model fit.

*we use this command to check for better fits-the gladder command shows that the log transformation can be used to normalise the data.
gladder tweet_count_all
gladder tweet_count_islam
gladder tweet_count_blm

*LOG TRANFORMATION: we can use the log(x+1) transformation, since there are some zero responses in the islam and blm tweet variables. 
gen log_tweet_all = log(tweet_count_all + 1)
gen log_tweet_blm = log(tweet_count_blm + 1)
gen log_tweet_islam = log(tweet_count_islam + 1)

*SQUARE ROOT TRANSFORMATION: 
gen sqrt_tweet_all = sqrt(tweet_count_all)
gen sqrt_tweet_blm = sqrt(tweet_count_blm)
gen sqrt_tweet_islam = sqrt(tweet_count_islam)

*WINSORIZATION
ssc install winsor, replace
winsor tweet_count_all, gen(wi_tweet_all) p(0.05)
winsor tweet_count_islam, gen(wi_tweet_islam) p(0.05)
winsor tweet_count_blm, gen(wi_tweet_blm) p(0.05)

*checking if the transformations produced the desired result

*LOG TRANSFORMATION

histogram log_tweet_all, normal bin(30)
histogram tweet_count_all
kdensity log_tweet_all
kdensity tweet_count_all

histogram log_tweet_islam, normal bin(30)
histogram tweet_count_islam
kdensity log_tweet_islam
kdensity tweet_count_all

*blm variable is at danger of suffering from zero-inflation, so keeping in mind that, winzorisation is possibly the best method to deal with this data. 
histogram log_tweet_blm, normal bin(30)
histogram tweet_count_blm
kdensity log_tweet_blm
kdensity tweet_count_all

*SQUARE ROOT TRANSFORMATION: 

histogram sqrt_tweet_all, normal bin(30)
histogram tweet_count_all
kdensity sqrt_tweet_all
kdensity tweet_count_all

histogram sqrt_tweet_islam, normal bin(30)
histogram tweet_count_islam
kdensity sqrt_tweet_islam
kdensity tweet_count_islam

histogram sqrt_tweet_blm, normal bin(30)
histogram tweet_count_blm
kdensity sqrt_tweet_blm
kdensity tweet_count_blm

*WINSORIZATION

histogram wi_tweet_all, normal bin(30)
histogram tweet_count_all
kdensity wi_tweet_all
kdensity tweet_count_all

histogram wi_tweet_islam, normal bin(30)
histogram tweet_count_islam
kdensity wi_tweet_islam
kdensity tweet_count_all

*blm variable 
histogram wi_tweet_blm, normal bin(30)
histogram tweet_count_blm
kdensity wi_tweet_blm
kdensity tweet_count_all
gen log_wi_tweet_blm=log(wi_tweet_blm)
kdensity log_wi_tweet_blm

*mostly the issue is fixed through the above transformations, though the blm variable requires double transformations, primarily due to zero inflation error.

*(d)

*using log transformed variables for plotting due to differing scales of the tweet count variables
twoway (line log_tweet_all date, lcolor(blue))(line log_tweet_blm date, lcolor(red)) (line log_tweet_islam date, lcolor(green)),title("IRA Tweet Count Over Time")legend(label(1 "All Tweets") label(2 "BLM") label(3 "Islam"))xtitle("Date") ytitle("Tweet Count")

*smooth curves
twoway (lowess log_tweet_all date, lcolor(blue))(lowess log_tweet_blm date, lcolor(red)) (lowess log_tweet_islam date, lcolor(green)),title("IRA Tweet Count Over Time")legend(label(1 "All Tweets") label(2 "BLM") label(3 "Islam"))xtitle("Date") ytitle("Tweet Count")

gen ymin = 0
gen ymax = 11  // Adjust based on your y-axis scale

twoway (rbar ymin ymax date if holiday == 1, color(gs13)) (lowess log_tweet_all date, lcolor(blue))(lowess log_tweet_blm date, lcolor(red)) (lowess log_tweet_islam date, lcolor(green)),legend(order(2 "All Tweets" 3 "BLM" 4 "Islam" 1 "Holiday"))title("Smoothed IRA Tweet Count with Holiday Shading")ytitle("log(Tweet Count + 1)") xtitle("Date")

*we find that using raw data is showing several spikes, making data analysis difficult. However, LOWESS fit is oversimplying the graph and hiding important patterns. We thus use a 10 day moving average for graphing.
tsset date
tssmooth ma sma14_all = log_tweet_all, window(7 1 6)
tssmooth ma sma14_blm = log_tweet_blm, window(7 1 6)
tssmooth ma sma14_islam = log_tweet_islam, window(7 1 6)

twoway (rbar ymin ymax date if te_russia == 1, color(gs13)) (rbar ymin ymax date if te_islam_russia == 1, color(lavender)) (line sma14_all date, lcolor(blue)) (line sma14_blm date, lcolor(red)) (line sma14_islam date, lcolor(green)), title("IRA Tweet Trends (14-Day Moving Average)") legend(label(2 "All Tweets") label(3 "BLM") label(4 "Islam") label(1 "Russia Event") label(1 "Russia Event" 2 "Russia Islamist Event") size(vsmall)) ytitle("log(Tweet Count + 1)") xtitle("Date")

twoway (rbar ymin ymax date if te_russia == 1, color(gs13)) (rbar ymin ymax date if te_islam_russia == 1, color(lavender)) (line sma14_all date, lcolor(blue)) (line sma14_blm date, lcolor(red)) (line sma14_islam date, lcolor(green)), title("IRA Tweet Trends (14-Day Moving Average)") legend(off) ytitle("log(Tweet Count + 1)") xtitle("Date")

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/holiday_merged_data.dta",replace

*the above shows a 14 day moving average of the time series plot of the three tweet count variable. The decision behind using such a plot is to balance precision and noise reduction in the data- LOWESS curves were giving oversimplified fits and raw log data was giving too much noise. The gray and lavender color bars represent the occurance of terrorist events in russia, corresponding to the te_russia and te_islam_russia indicator varibles. The idea is to see how the tweet count variables move across these terror event dates to check if a pattern exists. 


***************************************










