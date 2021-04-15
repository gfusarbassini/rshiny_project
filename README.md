# FIDAL-scraper project

This app is designed to analyse the performances of Nuova Virtus Crema athletics team.

## Introduction
I've been in an athletics team for ten years and our website has always been the same. Manual insertion of the results, neither statistics nor possibility to see our progression. We're about to launch our new website and I thought to kill two birds with one stone with this project. After some researches, I couldn't find any accessible API from FIDAL (Federazione Italiana di Atletica Leggera, the Italian Athletics Federation) so I went for web-scraping. Its main disadvantages are lower speed and the amount of useless informations downloaded. In fact, the website doesn't have a strong semantic structure. As a consequence, selecting needed information is a pretty dirty job. On the other hand, FIDAL website is a reliable source for it has not changed in years, just like my team's one. The app heads to the team main page and retrieves every athlete's personal webpage link. For this project, I decided to delete the younglings sector for simplicity.

## Features
### Athlete
The interface is pretty intuitive, the main goal is to watch an athlete progression in specific disciplines during time. You can choose an athlete by typing her/his name in the box. The first atlhete in the list is displayed by default. The list of athletes is displayed in the side panel as well.

### Discipline
The available discipline displayed are the only one that the specific athlete ever raced in, thus this list changes every time the user selects a different person. Some athletes are registered but never raced.
The choice of the discipline will trigger the plot as well as the table in the main panel. You can both read and watch the progression, as well as see a linear regression. Dates in the table may seem uncomfortable at first sight; their format is chosen due to the fact that users can decide to order results by date in this way.

### Mean & Forecast
Athletes always want to know the possibility of having specific results that would allow them to the national competitions.
That's why in this app you can also read the mean of the results and - if results are more than one - the prediction of a result if the athlete races today. Being it not the specific purpose of this project, I didn't bother the fact that this analyisis is sometimes obviously silly and can lead to nonsense results, such as negative performances. It works much better where there is a certain number of results well spanned in time, with some recent ones (e.g. my 200 mt and 400 mt progression and relative forecast).

### Plot and table
The table is always relative to the main athlete selected and allows to order results in different ways. Wind is not registered in many cases; being it a very important information the column is kept even when empty, just as FIDAL does.
The plot is responsive to the time span of the progression and the results. In certain disciplines, results are taken as seconds or minutes even if they are more than sixty seconds/minutes and formatted in a different way in the table, in order to plot them in a useful way.

### Comparable athletes
The plot lets athletes choose another key feature for their analysis - or sometimes just their ego: compare an athlete progression to another one's results. In the side panel, you can indeed find a dropdown menu with all the registered athletes that raced at least once in the selected discipline. When you choose a person, the plot automatically updates with the second athlete path in red, adjusting its dimension to the best for the two. You can quickly go back to the previous visualization selectiong the first record of the dropdown ("Compare Athlete").

## Code informations
Some data were stored in different ways and needed some further work on format to plot them/work on them (marathons, long runs). The code takes into account the possibility of wrong inserts (typos) in the page only if there is a useless space after the athlete surname (in the specific case, "Moussa Assef" was found to be saved "Moussa Assef ") and had its last character cut.
The app is designed to perform a multicore operation in Windows - main reason for its bootstrap is slow: to get the list of disciplines raced by every athlete, it visits a significant number of web pages and performs operations on their code. This could take up to over 20 seconds. The app detect the number of cores and divides the work thus the time between them, leading to a crystal clear better performance.
