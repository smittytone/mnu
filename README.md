# MNU 1.2.2 #

Please see [the MNU web site](https://smittytone.github.io/mnu/index.html).

### Scripts ###

Run `mnuprep.sh` from the `scripts` folder to prep in-app menu and popover graphics. Source: one or more large-size masters (PNGs or JPGs).

The script `postinstall.sh` is used to kill an existing app instance after re-installation.

## Release Notes ##

- 1.2.2 *9 June 2920*
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

MNU is copyright &copy; 2019-20, Tony Smith.

## Licence ##

MNU’s source code is issued under the [MIT Licence](./LICENSE). MNU’s graphics are not included in the source code.