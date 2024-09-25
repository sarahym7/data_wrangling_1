Tidy_data
================
Sarahy Martinez
2024-09-25

``` r
library(tidyverse)
```

    ## ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
    ## ✔ dplyr     1.1.4     ✔ readr     2.1.5
    ## ✔ forcats   1.0.0     ✔ stringr   1.5.1
    ## ✔ ggplot2   3.5.1     ✔ tibble    3.2.1
    ## ✔ lubridate 1.9.3     ✔ tidyr     1.3.1
    ## ✔ purrr     1.0.2     
    ## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()
    ## ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors

``` r
options(tibble.print_min = 5)
```

## `pivot_longer`

This will convert from wide format to longer

``` r
#this data is SAS format, so we will use the haven package 
pulse_data = 
  haven::read_sas("./data/public_pulse_data.sas7bdat") %>%
  janitor::clean_names()
```

each ID we have 4 diff observation on the BDI score as well as visit, we
want to end up with instead of having 4 different columns for BDI score
we want for ID to have a column with visit, 1m , 6m, 12m and BDI score
observed of each and repeat sex and age. There will be duplicates but
thats okay.

Now go from wide fornmat to long format pivot_longer(dataset, columns
you need to take from a column by column spread out to wide that we want
longer )

``` r
pulse_data_tidy = 
  pivot_longer(
    pulse_data, 
    bdi_score_bl:bdi_score_12m,
    names_to = "visit", #specify range interested in, will end up with two new columns one visit and    
    names_prefix = "bdi_score", #specify range interested in, will end up with two new columns one visit and
    values_to = "bdi")          #values existing in rows, new column names need to exist in new variable
                                # so for this we do names_to, then names_prefix to assign the variable that                                  #will store these values 

pulse_data_tidy
```

    ## # A tibble: 4,348 × 5
    ##      id   age sex   visit   bdi
    ##   <dbl> <dbl> <chr> <chr> <dbl>
    ## 1 10003  48.0 male  _bl       7
    ## 2 10003  48.0 male  _01m      1
    ## 3 10003  48.0 male  _06m      2
    ## 4 10003  48.0 male  _12m      0
    ## 5 10015  72.5 male  _bl       6
    ## # ℹ 4,343 more rows

bdi_score_bl unnecessary we can use mutate and strings but instead we
can add name_prefix to will change the prefix bdi_score_bl to just \_bl

rewrite, combine, and extend (to add a mutate step )

``` r
pulse_data = 
  haven::read_sas("./data/public_pulse_data.sas7bdat") %>%
  janitor::clean_names() %>% 
  pivot_longer(
    bdi_score_bl:bdi_score_12m,
    names_to = "visit", 
    names_prefix = "bdi_score_",
    values_to = "bdi"
    )%>%  
relocate(id, visit) %>%               #so id and visit are next to each other in order, organized columns
  mutate( visit = recode(visit, "bl"= "00m")) # change visit column so bl value is 00m. 
```
