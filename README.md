# ALPHA
# divStats - WebUI for Diversion statistics
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/240224b6b96543a782f176f2435ffa03)](https://www.codacy.com/app/jackyaz/divStats?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/divStats&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/divStats.svg?branch=master)](https://travis-ci.com/jackyaz/divStats)

## v0.1.0
### Updated on 2019-04-22
## About
Track your Internet uptime, on your router. Graphs available for on the Tools page of the WebUI.

divStats is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

![Menu UI](https://puu.sh/DfKf9/b90295e188.png)

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!
[**PayPal donation**](https://paypal.me/jackyaz21)

## Supported Models
All modes supported by [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). Models confirmed to work are below:
*   RT-AC86U

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/divStats/master/divStats.sh" -o "/jffs/scripts/divStats" && chmod 0755 /jffs/scripts/divStats && /jffs/scripts/divStats install
```

## Usage
To launch the divStats menu after installation, use:
```sh
divStats
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/divStats
```

## Updating
Launch divStats and select option u

## Help
Please post about any issues and problems here: [divStats on SNBForums](https://www.snbforums.com/threads/spdmerlin-automated-speedtests-with-graphs.55904/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
