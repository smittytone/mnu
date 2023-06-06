# MNU 1.7.0 #

For usage and other information, please see [the MNU web site](https://smittytone.net/mnu/index.html).

### Development Scripts ###

Run `mnuprep.sh` from the `Scripts` folder to prep in-app menu and popover graphics. Source: one or more large-size masters (PNGs or JPEGs).

The script `postinstall.sh` is used to kill an existing app instance after re-installation.

## Release Notes ##

- 1.7.0 *Unreleased*
    - Add key equiavalents with modifiers to menu items.
    - Replace the item show/hide gree/red dots with switches so...
    - ...end support for macOS 10.14: 10.15 (Catalina, 2019) is the new minium supported version.
    - Better Configure MNU item action icons.
    - Internal improvements.
    - Fix crash on clicking any help button.
    - Fix feedback system.
- 1.6.3 *8 May 2022*
    - Correct Help URL.
- 1.6.2 *5 October 2021*
    - Fix old, unchanged dates.
- 1.6.1 *23 July 2021*
    - Call external processes, eg. Terminal, from a secondary thread.
    - Attempt to fix issue in which changes to a menu item's code are not registered.
- 1.6.0 *6 June 2021*
    - Added iTerm2 support.
    - Added new default items.
    - Improved handling of spaces in direct commands’ path arguments.
    - Improved escape character handling.
    - Improved script and script title field presentation when editing a script.
- 1.5.2 *19 May 2021*
    - Correctly record the preference for starting MNU automatically at login.
    - Fix start up crash on systems that record binary values in Finder and GlobalDomain preferences in a different way to mine, eg. `1` vs `YES` (thanks to @jgoldhammer)
- 1.5.1 *28 April 2021*
    - Update `brew update` and `brew upgrade` scripts for M1 Macs:
        - Support brew at `/opt/homebrew` as well as `/usr/local`
    - Minor tweaks to the feedback system.
    - Update tests.
- 1.5.0 *1 February 2021*
    - Support all macOS app locations for ‘open app‘ actions:
        - `/Applications`
        - `/Applications/Utilities`
        - `/System/Applications`
        - `/System/Applications/Utilities`
        - `~/Applications`
    - Correctly update the Configure Window’s view of the menu contents.
    - Make sure mutually exclusive menu item actions can’t be selected together.
    - Make sure out-of-terminal commands use absolute paths.
        - And in-path relative elements are evaluated.
    - Warn user when commands used by default items are not installed.
- 1.4.6 *10 December 2020*
    - Fix scrunched **Configure MNU** menu items table.
- 1.4.5 *2 December 2020*
    - Minor icon tweak; no code changes.
- 1.4.4 *30 November 2020*
    - Big Sur UI fixes:
        - Fix table rendering oddness.
        - Fix control spacing oddness.
- 1.4.3 *17 November 2020*
    - Apple Silicon support.
- 1.4.2 *23 October 2020*
    - Packaging update.
- 1.4.1 *Not released*
    - Minor improvements.
- 1.4.0 *21 September 2020*
    - Big Sur support.
    - Preliminary Apple Silicon support.
- 1.3.0 *06 August 2020*
    - Preliminary support for double-quotes in Terminal commands.
    - Update code to avoid deprecated calls.
    - Better recovery when the MNU item list is damaged.
    - Better serialization and de-serialization.
    - Add unit tests.
- 1.2.2 *9 June 2020*
    - Add ability to run items directly, without a shell.
- 1.2.1 *4 February 2020*
    - Add copy, cut, paste, select all, undo and redo to the **Add/Edit User Item** text fields.
- 1.2.0 *14 January 2020*
    - Add ability to launch named apps.
    - Better handling of duplicate menu item titles.
- 1.1.1 *20 November 2019*
    - Add app restart script for installer package.
- 1.1.0 *28 October 2019*
    - Add an extra controls button to the Configure window:
        - Export a JSON representation of the current menu item lits for backup and/or sync across Macs.
        - Import JSON backups.
    - Add tooltips to key UI items.
- 1.0.1 *9 October 2019*
    - Minor improvements.
    - Show correct version in MNU menu bar tooltip.
- 1.0.0 *17 September 2019*
    - Initial public release.

## Copyright ##

MNU is copyright &copy; 2023, Tony Smith.

## Licence ##

MNU’s source code is issued under the [MIT Licence](./LICENSE). MNU’s graphics are not included in the source code.
