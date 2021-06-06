# uiDivStats - WebUI for Diversion statistics
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/240224b6b96543a782f176f2435ffa03)](https://www.codacy.com/app/jackyaz/uiDivStats?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/uiDivStats&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/uiDivStats.svg?branch=master)](https://travis-ci.com/jackyaz/uiDivStats)

## v3.0.0
### Updated on 2021-06-06
## About
A graphical representation of domain blocking performed by Diversion.

uiDivStats is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

[**PayPal donation**](https://paypal.me/jackyaz21)

[**Buy me a coffee**](https://www.buymeacoffee.com/jackyaz)

## Supported firmware versions
You must be running firmware Merlin 384.15/384.13_4 or Fork 43E5 (or later) [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/)

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/uiDivStats/master/uiDivStats.sh" -o "/jffs/scripts/uiDivStats" && chmod 0755 /jffs/scripts/uiDivStats && /jffs/scripts/uiDivStats install
```

## Usage
### WebUI
uiDivStats can be configured via the WebUI, in the LAN section.

### CLI
To launch the uiDivStats menu after installation, use:
```sh
uiDivStats
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/uiDivStats
```

## Screenshots
![WebUI](https://puu.sh/HMN1D/a11fca5232.png)

![CLI UI](https://puu.sh/HMN1y/1309c8dc86.png)

## Help
Please post about any issues and problems here: [uiDivStats on SNBForums](https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=15)
