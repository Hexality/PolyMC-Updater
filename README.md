# THIS UPDATER REQUIRES [POWERSHELL 7](https://github.com/powershell/powershell/releases/latest)
## The code is a mess, don't ask about it.
This is a standalone cli-based updater I made to autoupdate my [PolyMC](https://github.com/polymc/polymc) on Windows.

I didn't test this on other machines, use at your own risk.

### Installation:
> Drag both files on PolyMC's root folder.

> You can copy the updater.lnk to wherever u want.

### What it does?
> The updater checks for updates on script launch, if a new update is available, it asks you if you want to update or not. If no updates are available or you postpone the update, it imediately opens polymc and closes the script.
>> Note: a pwsh instance keeps running in windowless mode as a background process cause it was the only way I found to be able to close the main script as polymc's outputs a lot of crap when ran through cli (PolyMC contributors, please make it outputless if no --verbose is provided lol).
