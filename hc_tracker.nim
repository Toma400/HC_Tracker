import std/private/oscommon
import std/private/osdirs
import system/nimscript
import std/strformat
import std/algorithm
import std/parsecfg
import std/sequtils
import std/times
import questionable
import strutils
import streams
import tables
import yaml
import nigui

type
  Episode = object
    title           : string
    hermit          : string
    number          : int
    special         : string
    date            : DateTime
    watched         : bool
    downloaded      : bool
    checked_quality : bool
    favourite       : bool

  Data = object
    seasons: seq[string]
    hermits: seq[string]

const
  timef = "yyyy-MM-dd"

proc `$` (e: Episode): string =
  result = $e.number & ": " & $e.title

proc alphSort (x, y: string): int =
  try:
    if parseInt(x) > parseInt(y): return -1 # descending order (most current is on top)
    else:                         return  1
  except:
    if x[0] > y[0]: return  1 # alphabetical
    else:           return -1

proc entrySort (x, y: Episode): int = # most recent on top
  if x.date > y.date: return -1
  else:               return  1

iterator walkHermits (path: string): string =
  # remember to change '/' in path to '\' (at least on Windows)
  yield " "
  for k, v in walkDir(path):
    if k == pcDir:
      yield v.replace(path, "")

discard existsOrCreateDir("data")
app.init()

#-----------------------------------
# MAIN FLOW
var seasons:     seq[string]
var hc_data:     Data
var eps_shown:   seq[Episode]

block varSupplying:
  # season count
  for k, v in walkDir("data"):
    seasons.add(v.replace("data\\", ""))

  # hermits list & categories
  var file = newFileStream("hermits.yaml")
  load(file, hc_data)
  file.close()

  for sn in hc_data.seasons:
    discard existsOrCreateDir(fmt"data/{sn}")

  # sorting
  seasons.sort(alphSort)
  hc_data.hermits.sort(alphSort)

let win = newWindow("HermitCraft Tracker")

let main   = newLayoutContainer(Layout_Vertical)
let picker = newLayoutContainer(Layout_Horizontal)
let adder  = newLayoutContainer(Layout_Horizontal)

let list_seasons   = newComboBox(seasons)
let list_hermits   = newComboBox(walkHermits(fmt"data\{list_seasons.value}\").toSeq)
let season_summary = newTextArea("")
# adding episode
let add_ep_season  = newComboBox(seasons)
let add_ep_hermit  = newComboBox(hc_data.hermits)
let add_ep_number  = newTextBox("")
let add_ep_special = newTextBox("")
let add_ep_title   = newTextBox("")
let add_ep_date_y  = newTextBox("")
let add_ep_date_m  = newTextBox("")
let add_ep_date_d  = newTextBox("")
let add_ep         = newButton("Add")

block settings:
  win.x = 1200
  win.y = 600
  picker.frame = newFrame("Season picker")
  adder.frame  = newFrame("Add new episode")
  add_ep_number.placeholder  = "Number*"
  add_ep_special.placeholder = "Special"
  add_ep_title.placeholder   = "Title"
  add_ep_date_y.placeholder  = "Year*"
  add_ep_date_m.placeholder  = "Month*"
  add_ep_date_d.placeholder  = "Day*"
  season_summary.editable = false

block registry:
  win.add(main)
  main.add(picker)
  picker.add(list_seasons)
  picker.add(list_hermits)
  main.add(season_summary)
  main.add(adder)
  adder.add(add_ep_season)
  adder.add(add_ep_hermit)
  adder.add(add_ep_number)
  adder.add(add_ep_special)
  adder.add(add_ep_title)
  adder.add(add_ep_date_y)
  adder.add(add_ep_date_m)
  adder.add(add_ep_date_d)
  adder.add(add_ep)

proc generateSeason (seasonNb: string) =
  eps_shown.setLen(0) # clearing old entry
  # season.text = ""
  let filter = list_hermits.value

  for v in walkDirRec(fmt"data/{seasonNb}/"):
    if ".ini" in v:
      let fdata = v.split(r"\") # [1] season, [2] hermit, [3] ID
      if filter == " " or filter == fdata[2]:
        let entry = loadConfig(v)
        let ep    = Episode(title:      entry.getSectionValue("", "title"),
                            hermit:     fdata[2],
                            number:     parseInt(entry.getSectionValue("", "number")),      # special needs to have non-number
                            special:    entry.getSectionValue("", "special"),               # ?
                            date:       parse(entry.getSectionValue("", "date"), timef),
                            watched:    parseBool(entry.getSectionValue("", "watched")),
                            downloaded: parseBool(entry.getSectionValue("", "downloaded")),
                            favourite:  parseBool(entry.getSectionValue("", "favourite")))
        eps_shown.add(ep)
  eps_shown.sort(entrySort)
  for e in eps_shown:
    # let conversion = (true: "+", false: "-")
    season_summary.addLine(fmt"{e.hermit} - {e.number}: {e.title} | {e.date.month}, {e.date.monthday}") #  | {conversion[e.watched]}:{conversion[e.downloaded]}:{conversion[e.checked_quality]}

list_seasons.onChange = proc (event: ComboBoxChangeEvent) =
  list_hermits.options = walkHermits(fmt"data\{list_seasons.value}\").toSeq
  season_summary.text = ""
  generateSeason(list_seasons.value)

list_hermits.onChange = proc (event: ComboBoxChangeEvent) =
  season_summary.text = ""
  generateSeason(list_seasons.value)

add_ep.onClick = proc (event: ClickEvent) =
  let req = [
    add_ep_number.text,
    add_ep_date_y.text,
    add_ep_date_m.text,
    add_ep_date_d.text
  ]
  if all(req, proc (x: string): bool = x != "") == true and add_ep_hermit.value != " ":
    # format helpers (handles optionality & putting single number, while Nigui requires double even for one-digit ones)
    if add_ep_date_m.text.len == 1: add_ep_date_m.text = fmt"0{add_ep_date_m.text}"
    if add_ep_date_d.text.len == 1: add_ep_date_d.text = fmt"0{add_ep_date_d.text}"
    if add_ep_title.text == "":     add_ep_title.text = "[No name]"

    let add_ep_date = fmt"{add_ep_date_y.text}-{add_ep_date_m.text}-{add_ep_date_d.text}"
    let vals = fmt"""
    title           : "{add_ep_title.text}"
    number          : {add_ep_number.text}
    special         : "{add_ep_special.text}"
    date            : "{add_ep_date}"
    watched         : false
    downloaded      : false
    checked_quality : false
    favourite       : false
    """.unindent
    discard existsOrCreateDir(fmt"data/{add_ep_season.value}/{add_ep_hermit.value}/")
    writeFile(fmt"data/{add_ep_season.value}/{add_ep_hermit.value}/{add_ep_number.text} - {add_ep_title.text}.ini", vals)

    season_summary.text = ""
    generateSeason(list_seasons.value)

win.show()
app.run()