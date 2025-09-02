---
  title: "Tidy_data"
author: "Sarahy Martinez"
date: "2024-09-25"
output: html_document
---
  
  
  ```{r}
library(tidyverse)
options(tibble.print_min = 5)

```


- For tidying single tables 
a. pivot_longer 
b. separate 

- For untidying single tables 
A. pivot_wider 

- For combining multiple tables 
A. bind_rows
B. *_join

# pivot_longer
```{r}
pulse_df = 
  haven::read_sas("./data/public_pulse_data.sas7bdat") |>
  janitor::clean_names()

pulse_df
```

With our new understanding of tidy data, we quickly recognize a problem: the BDI score is spread across four columns, which correspond to four observation times. We can fix this problem using pivot_longer:
  
  ```{r}
pulse_tidy_df = 
  pivot_longer(
    pulse_df, 
    bdi_score_bl:bdi_score_12m,
    names_to = "visit", 
    values_to = "bdi")

pulse_tidy_df
```
This looks much better! However, now visit is an issue. The original column names were informative but we probably don’t need to keep the bdi_score_ prefix in each case. I’ll use an additional option in pivot_longer to address this:
  
  ```{r}
pulse_tidy_df = 
  pivot_longer(
    pulse_df, 
    bdi_score_bl:bdi_score_12m,
    names_to = "visit", 
    names_prefix = "bdi_score_",
    values_to = "bdi")

pulse_tidy_df
```

In the preceding I’ve saved intermediate datasets to make each step clear. While this can be a helpful crutch as you’re trying out code, it is generally bad practice. There are also some additional transformations needed to wrap up the data wrangling process, like changing bl to 00m for consistency across visits and converting visit to a factor variable. (It’s possible that you would want visit to be a numeric variable instead, which could be done with a different call to mutate.)

Altogether, then, the code below will import, tidy, and transform the PULSE dataset into a usable format:
  ```{r}
pulse_df = 
  haven::read_sas("./data/public_pulse_data.sas7bdat") |>
  janitor::clean_names() |>
  pivot_longer(
    bdi_score_bl:bdi_score_12m,
    names_to = "visit", 
    names_prefix = "bdi_score_",
    values_to = "bdi") |>
  mutate(
    visit = replace(visit, visit == "bl", "00m"),
    visit = factor(visit)) 

print(pulse_df, n = 12)
```


# Learning Assessment 

In the litters data, the variables gd0_weight and gd18_weight give the weight of the mother mouse on gestational days 0 and 18. Write a data cleaning chain that retains only litter_number and these columns; produces new variables gd and weight; and makes gd a numeric variable taking values 0 and 18 (for the last part, you might want to use recode …). Is this version “tidy”

# pivot_wider

```{r}
analysis_result = 
  tibble(
    group = c("treatment", "treatment", "placebo", "placebo"),
    time = c("pre", "post", "pre", "post"),
    mean = c(4, 8, 3.5, 4)
  )

analysis_result
```

An alternative presentation of the same data might have groups in rows, times in columns, and mean values in table cells. This is decidedly non-tidy; to get there from here we’ll need to use pivot_wider, which is the inverse of pivot_longer:
  
  ```{r}
pivot_wider(
  analysis_result, 
  names_from = "time", 
  values_from = "mean")
```

We’re pretty much there now – in some cases you might use select to reorder columns, and (depending on your goal) use knitr::kable() to produce a nicer table for reading


# Binding Rows 
We’ve looked at single-table non-tidy data, but non-tidiness often stems from relevant data spread across multiple tables. In the simplest case, these tables are basically the same and can be stacked to produce a tidy dataset. That’s the setting in LotR_words.xlsx, where the word counts for different races and genders in each movie in the trilogy are spread across distinct data rectangles (these data are based on this example).

To produce the desired tidy dataset, we first need to read each table and do some cleaning.

```{r}
fellowship_ring = 
  readxl::read_excel("./data/LotR_Words.xlsx", range = "B3:D6") |>
  mutate(movie = "fellowship_ring")

two_towers = 
  readxl::read_excel("./data/LotR_Words.xlsx", range = "F3:H6") |>
  mutate(movie = "two_towers")

return_king = 
  readxl::read_excel("./data/LotR_Words.xlsx", range = "J3:L6") |>
  mutate(movie = "return_king")
```

Here it was necessary to add a variable to each dataframe indicating the movie; that information had stored elsewhere in the original spreadsheet. As an aside, the three code snippets above are all basically the same except for the range and the movie name – later we’ll see a better way to handle cases like this by writing our own functions, but this works for now.

Once each table is ready to go, we can stack them up using bind_rows and tidy the result:
  
  ```{r}
lotr_tidy = 
  bind_rows(fellowship_ring, two_towers, return_king) |>
  janitor::clean_names() |>
  pivot_longer(
    female:male,
    names_to = "gender", 
    values_to = "words") |>
  mutate(race = str_to_lower(race)) |> 
  select(movie, everything()) 

lotr_tidy
```
Having the data in this form will make it easier to make comparisons across movies, aggregate within races across the trilogy, and perform other analyses


# Joining Datasets 

Data can be spread across multiple related tables, in which case it is necessary to combine or join them prior to analysis. We’ll focus on the problem of combining two tables only; combining three or more is done step-by-step using the same ideas.

There are four major ways join dataframes x and y:
  
  Inner: keeps data that appear in both x and y
Left: keeps data that appear in x
Right: keeps data that appear in y
Full: keeps data that appear in either x or y
Left joins are the most common, because they add data from a smaller table y into a larger table x without removing anything from x.

As an example, consider the data tables in FAS_pups.csv and FAS_litters.csv, which are related through the Litter Number variable. The former contains data unique to each pup, and the latter contains data unique to each litter. We can combine these using a left join of litter data into pup data; doing so retains data on each pup and adds data in new columns.

(While revisiting this example, take a look at the group variable in the litters dataset: this encodes both dose and day of treatment! We’ll fix that bit of untidiness as part of the processing pipeline. I’m also going to address a pet peeve of mine, which is coding sex as an ambiguous numeric variable.)


```{r}
pup_df = 
  read_csv(
    "./data/FAS_pups.csv",
    na = c("NA", "", ".")) |>
  janitor::clean_names() |>
  mutate(
    sex = 
      case_match(
        sex, 
        1 ~ "male", 
        2 ~ "female"),
    sex = as.factor(sex)) 



litter_df = 
  read_csv(
    "./data/FAS_litters.csv",
    na = c("NA", ".", "")) |>
  janitor::clean_names() |>
  separate(group, into = c("dose", "day_of_tx"), sep = 3) |>
  relocate(litter_number) |>
  mutate(
    wt_gain = gd18_weight - gd0_weight,
    dose = str_to_lower(dose))


fas_df = 
  left_join(pup_df, litter_df, by = "litter_number")

fas_df



```

We made the key explicit in the join. By default, the *_join functions in dplyr will try to determine the key(s) based on variable names in the datasets you want to join. This is often but not always sufficient, and an extra step to make the key clear will help you and others reading your code.

Note that joining is not particularly amenable to the |> operator because it is fundamentally non-linear: two separate datasets are coming together, rather than a single dataset being processed in a step-by-step fashion.

As a final point, the *_join functions are very much related to SQL syntax, but emphasize operations common to data analysis.

Learning Assessment: The datasets in this zip file contain de-identified responses to surveys included in past years of this course. Both contain a unique student identifier; the first has responses to a question about operating systems, and the second has responses to questions about degree program and git experience. Write a code chunk that imports and cleans both datasets, and then joins them.


```{r}

```




