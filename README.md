# uiDivStats - WebUI for Diversion statistics
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/240224b6b96543a782f176f2435ffa03)](https://www.codacy.com/app/jackyaz/uiDivStats?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/uiDivStats&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/uiDivStats.svg?branch=master)](https://travis-ci.com/jackyaz/uiDivStats)

## v1.0.0
### Updated on 2019-05-14
## About
See statistics and graphs for Diversion Ad-blocking on your router.

uiDivStats is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

![Menu UI](https://puu.sh/DrqWN/ca8911697b.png)

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!
[**PayPal donation**](https://paypal.me/jackyaz21)

## Supported Models
All modes supported by [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). Models confirmed to work are below:
*   RT-AC86U

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/uiDivStats/master/uiDivStats.sh" -o "/jffs/scripts/uiDivStats" && chmod 0755 /jffs/scripts/uiDivStats && /jffs/scripts/uiDivStats install
```

## Usage
To launch the uiDivStats menu after installation, use:
```sh
uiDivStats
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/uiDivStats
```

## Updating
Launch uiDivStats and select option u

## Help
Please post about any issues and problems here: [uiDivStats on SNBForums](https://www.snbforums.com/threads/uidivstats-webui-for-diversion-statistics.56393/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
