# HermitCraft Tracker
HermitCraft tracker is small software I designed to keep my HermitCraft watchlist
of episodes cleaner, as I were a bit lost keeping track of it on paper.

- [Installation & preparation](#1-installation--preparation)
- [How to use it?](#2-how-to-use-it)
  - [Adding episodes](#adding-new-episodes)
  - [Episode status](#status)
  - [Specials](#specials)
- [License](#license) 

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
download: false
quality: false
```
This file controls what seasons and hermits you can use, so you add seasons or hermits
simply by putting them in such scheme as shown above.  
Initially, file will contain all hermits who appeared from season 7 onwards, and
seasons 7-10. Feel free to curate the list.

Two last options, `download` and `quality`, are by default turned off.  
Those are mostly my personal features that I wanted to add, since I download HC
episodes, so I can watch them offline or just keep personal copy. I doubt many
of you would find that useful, but if you'd need two additional checks, feel
free to change this value to `true`.

### 2. How to use it?
There are two parts of HC Tracker - browser and adder. Browser let you browse
through season episodes list (with newest episodes on top) and filter it through
hermits having episodes in said season, and by episodes' qualities, such as them
not being watched, or being marked as favourite.

#### Adding new episodes
Menu at the bottom allows you to add new episodes. Simply put respective data into
its fields, and once you click "Add" button, new entry will be added.  
Be aware that if episode title contains symbols like `?`, those will be removed.
It's sadly limitation of how I made this program work, sorry :<

#### Status
To keep track of whether you watched the episode, you can select it from list and
check its status - or switch it with the button!

#### Specials
Special means any episode that doesn't fall under regular episode scheme, for example
being live recording, or some bonus. This feature isn't implemented yet,
but will simply let you categorise/filter through special's name in the future.

---

### Future plans
As of writing v1 version (8.2.2024), my minimal plans for this software is done:
it should work without any bigger issues, and all features needed for it are made.  

Feel free to report issues on it in [GitHub issues page](https://github.com/Toma400/HC_Tracker/issues)
or [my Discord server](https://discord.gg/GbTw9KqnrE).  

You can suggest any ideas too, however be aware that I will implement them only if
they have enough purpose and also can be implemented within technological limitations
of Nigui library (which is reason behind a bit ugly interface of current program).  
I may rewrite this program to different language/library one day, but I wanted this
to be made relatively fast, so I can make it to Season 10 beginning <3

### License
The software code is made under All Rights Reserved, however you can freely download
its releases and use for your own personal purposes.

2024 (C) Tomasz Stępień, All Rights Reserved