# HermitCraft Tracker
HermitCraft tracker is small software I designed to keep my HermitCraft watchlist
of episodes cleaner, as I were a bit lost keeping track of it on paper.

### 1. Installation & preparation
If you downloaded .zip file, simply unpack its contents into any folder you want.

Before you start the program, I'd suggest customising `hermits.yaml` file to your
needs - open it with notebook, and edit:
```yaml
seasons:
  - 7
  - 8
  - 9
  - 10
hermits:
  - Bdouble
  - Cubfan
  - Doc
  - Etho
```
This file controls what seasons and hermits you can use, so you add seasons or hermits
simply by putting them in such scheme as shown above.  
Initially, file will contain all hermits who appeared from season 6 onwards, and
seasons 7-10. Feel free to curate the list.

### 2. How to use it?
There are two parts of HC Tracker - browser and adder. Browser let you browse
through season episodes list (with newest episodes on top) and filter it through
hermits having episodes in said season.

Adder allows you to add new episodes. Simply put respective data into its fields,
and once you click "Add" button, new entry will be added.  

#### Specials
Special means any episode that doesn't fall under regular episode scheme, for example
being live recording, or some bonus. This feature isn't implemented yet fully,
but will simply let you categorise/filter through special's name in the future.

#### Status
There are some fields in episodes data that are yet unused - whether you watched,
downloaded, checked quality of the download or favourited the episode.  
I will add those options being changeable in the future, so you can mark the episode
as watched or favourite and maybe also filter through that, too.

### License
The software code is made under All Rights Reserved, however you can freely download
its releases and use for your own purposes.

2024 (C) Tomasz Stępień, All Rights Reserved