import std/private/oscommon
import std/private/osdirs
import system/nimscript
import std/strformat
import std/algorithm
import std/parsecfg
import std/sequtils
import std/times
import std/re
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
    date            : DateTime # date of episode
    datec           : DateTime # date of adding episode
    favourite       : bool
    watched         : bool
    downloaded      : bool
    checked_quality : bool

  Data = object
    seasons  : seq[string]
    hermits  : seq[string]
    download : bool
    quality  : bool

const
  timef = "yyyy-MM-dd"         # time used for episode date
  timec = "yyyy-MM-dd'T'HH:mm" # time used for adding date

proc `$` (e: Episode): string =
    result = fmt"""
    title           : "{e.title}"
    number          : $e.number
    special         : "{e.special}"
    date            : "{format(e.date, timef)}"
    date_add        : "{format(e.date, timec)}"
    favourite       : $e.favourite
    watched         : $e.watched
    downloaded      : $e.downloaded
    checked_quality : $e.checked_quality
    """.unindent

proc alphSort (x, y: string): int =
  try:
    if parseInt(x) > parseInt(y): return -1 # descending order (most current is on top)
    else:                         return  1
  except:
    if x[0] > y[0]: return  1 # alphabetical
    else:           return -1

proc entrySort (x, y: Episode): int = # most recent on top
  if   x.date > y.date: return -1
  elif x.date < y.date: return 1
  elif x.date == y.date:
    if x.datec > y.datec: return -1
    else:                 return  1

proc newEpisode (path: string, hermit: string): Episode =
  let entry = loadConfig(path)
  result.title           = entry.getSectionValue("", "title")
  result.hermit          = hermit
  result.number          = parseInt(entry.getSectionValue("", "number"))
  result.special         = entry.getSectionValue("", "special", defaultVal = "")
  result.date            = parse(entry.getSectionValue("", "date"),                                      timef)
  result.datec           = parse(entry.getSectionValue("", "date_add", defaultVal = "2000-01-01T12:00"), timec) # now()
  result.favourite       = parseBool(entry.getSectionValue("", "favourite"))
  result.watched         = parseBool(entry.getSectionValue("", "watched"))
  result.downloaded      = parseBool(entry.getSectionValue("", "downloaded"))
  result.checked_quality = parseBool(entry.getSectionValue("", "checked_quality"))

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

let win = newWindow("HermitCraft Tracker (v1)")

let main   = newLayoutContainer(Layout_Vertical)
let picker = newLayoutContainer(Layout_Horizontal)
let viewer = newLayoutContainer(Layout_Horizontal)
let editer = newLayoutContainer(Layout_Vertical)
let info   = newLayoutContainer(Layout_Vertical)
let adder  = newLayoutContainer(Layout_Horizontal)

let list_seasons   = newComboBox(seasons)
let list_hermits   = newComboBox(walkHermits(fmt"data\{list_seasons.value}\").toSeq)
# episode view and edit
let season_summary = newTextArea("")
let ep_picker      = newComboBox(@[" "])
let ep_favourited  = newLabel("- ~~~~~~~~~~~~ -")
let ep_watched     = newLabel("- ~~~~~~~~~~~~ -")
let ep_downloaded  = newLabel("- ~~~~~~~~~~~~ -")
let ep_checked     = newLabel("- ~~~~~~~~~~~~ -")
# checkboxes
let check_watched  = newCheckbox("Show only unwatched")
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
  win.width  = 900
  win.height = 600
  info.width = 200
  ep_picker.width = 400
  picker.frame  = newFrame("Season picker")
  adder.frame   = newFrame("Add new episode")
  info.frame    = newFrame("Info")
  editer.xAlign = XAlign_Left
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
  picker.add(check_watched)
  main.add(viewer)
  viewer.add(season_summary)
  viewer.add(editer)
  editer.add(ep_picker)
  editer.add(info)
  info.add(ep_favourited)
  info.add(ep_watched)
  if hc_data.download:
    info.add(ep_downloaded)
  if hc_data.quality:
    info.add(ep_checked)
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

proc generateSeason (seasonNb: string, f_watched = check_watched.checked) =
  # resetting old entry
  season_summary.text = ""
  eps_shown.setLen(0)

  let filter = list_hermits.value
  var cbox   = newSeq[string]()

  for v in walkDirRec(fmt"data/{seasonNb}/"):
    if ".ini" in v:
      let fdata = v.split(r"\") # [1] season, [2] hermit, [3] ID
      if filter == " " or filter == fdata[2]:
        eps_shown.add(newEpisode(v, fdata[2]))

  eps_shown.sort(entrySort)

  for e in eps_shown:
    if not (f_watched and e.watched):
      season_summary.addLine(fmt"{e.hermit} - {e.number}: {e.title} | {e.date.month}, {e.date.monthday}") #  | {conversion[e.watched]}:{conversion[e.downloaded]}:{conversion[e.checked_quality]}
      cbox.add(fmt"{seasonNb}| {e.hermit} - {e.number}: {e.title}")
  ep_picker.options = cbox

proc updateEntry (entry: string) =
  if "|" in entry: # avoids None and other edge cases
    let data = split(entry, re"\| |: | - ")
    let info = newEpisode(fmt"data/{data[0]}/{data[1]}/{data[2]} - {data[3]}.ini", data[1])
    case info.favourite:
      of true:  ep_favourited.text = "Favourite"
      of false: ep_favourited.text = ""
    case info.watched:
      of true:  ep_watched.text = "Watched"
      of false: ep_watched.text = "Not watched"
    if hc_data.download:
      case info.downloaded:
        of true:  ep_downloaded.text = "Downloaded"
        of false: ep_downloaded.text = "Missing"
    if hc_data.quality:
      case info.checked_quality:
        of true:  ep_checked.text = "Quality checked"
        of false: ep_checked.text = "Quality unknown"

proc saveEntry (ep: Episode, season: string) =
  discard existsOrCreateDir(fmt"data/{season}/{ep.hermit}/")
  writeFile(fmt"data/{season}/{ep.hermit}/{$ep.number} - {ep.title}.ini", $ep)

list_seasons.onChange = proc (event: ComboBoxChangeEvent) =
  list_hermits.options = walkHermits(fmt"data\{list_seasons.value}\").toSeq
  generateSeason(list_seasons.value)

list_hermits.onChange = proc (event: ComboBoxChangeEvent) =
  generateSeason(list_seasons.value)

ep_picker.onChange = proc (event: ComboBoxChangeEvent) =
  echo ep_picker.value
  updateEntry(ep_picker.value)

add_ep.onClick = proc (event: ClickEvent) =
  proc processTitle (title: string): string =
    const chars_out = ["?"]
    if title == "": return "[No name]"
    else:
      result = title
      for c in chars_out:
        result = result.replace(c, "")

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
    add_ep_title.text = processTitle(add_ep_title.text)

    let add_ep_date  = fmt"{add_ep_date_y.text}-{add_ep_date_m.text}-{add_ep_date_d.text}"
    let add_ep_datec = format(now(), timec)
    let vals = fmt"""
    title           : "{add_ep_title.text}"
    number          : {add_ep_number.text}
    special         : "{add_ep_special.text}"
    date            : "{add_ep_date}"
    date_add        : "{add_ep_datec}"
    watched         : false
    downloaded      : false
    checked_quality : false
    favourite       : false
    """.unindent
    discard existsOrCreateDir(fmt"data/{add_ep_season.value}/{add_ep_hermit.value}/")
    writeFile(fmt"data/{add_ep_season.value}/{add_ep_hermit.value}/{add_ep_number.text} - {add_ep_title.text}.ini", vals)

    generateSeason(list_seasons.value)

check_watched.onToggle = proc (event: ToggleEvent) =
  generateSeason(list_seasons.value)
  updateEntry(ep_picker.value)

generateSeason(list_seasons.value)
updateEntry(ep_picker.value)

win.show()
app.run()