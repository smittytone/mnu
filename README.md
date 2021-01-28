# MNU 1.5.0 #

Please see [the MNU web site](https://smittytone.net/mnu/index.html).

### Scripts ###

Run `mnuprep.sh` from the `scripts` folder to prep in-app menu and popover graphics. Source: one or more large-size masters (PNGs or JPEGs).

The script `postinstall.sh` is used to kill an existing app instance after re-installation.

## Release Notes ##

- 1.5.0 *Unreleased*
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

MNU is copyright &copy; 2021, Tony Smith.

## Licence ##

MNU’s source code is issued under the [MIT Licence](./LICENSE). MNU’s graphics are not included in the source code.