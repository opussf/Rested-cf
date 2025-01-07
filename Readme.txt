Welcome to Rested

Rested shows the rested status of your alts.

How to use:
Install the addon for any alt you wish to track. Log into that alt.
Type '/rested' to see a list of alts and their rested status.

Commands:
/rested                   -> Rested Report
/rested rm name[-realm]   -> Remove a character, optionally on specific realm
/rested ignore name|realm -> Ignore a named character, or characters on a realm.  Will ignore what ever matches.
                          -> Use . to ignore all.
/rested help              -> Show all available commands / reports


The rested window Title shows the name of the report shown, and the number of lines.
Reports are shown, 6 lines at a time, with a search window to limit values for most reports.

The Nag and Stale reports show max level characters who have not been visited in a certain amount of time.
The Nag report shows max level characters older than the nagStart, but younger than the staleStart cutoff times.
The Nag report will auto show if there are any characters who would be in it.
The Stale report shows any max level character who has not been visited after the staleStart cutoff time.

Time Since visiting character >= nagStart and < staleStart -->  show in Nag report.
Time Since visiting character >= staleStart -->  show in Stale report.

A character can be 'ignored' for 1 week at a time.
This is a way to not see a toon for a while (say to make sure they are rested, or to get them out of the nag report).



Change Log:
3.19    - Added: Darkmoon Faire report (quests, last time visiting the island)
        - Added: Garrison Cache report added back in.
        - Updated: Profession Concentration report to show full Conc for 2 days
3.18.4  - Fixed: UI Resize issue
3.18.3  - Fixed: Pandarian Farm plot size checking
3.18.2  - Fixed: Pandarian Farm plot size checking
3.18.1  - Fixed: Guild Rep and Rank
3.18    - Added: Mythic ranking and key tracking
3.17.1  - Fixed: Pandarian Farm report
3.17    - Added: Pandarian Farm report (plots and last time harvested)
        - Added: Quest tracker
3.16    - Added: Window lock support
3.15    - Added: Window resize support
3.14    - Added: CSV report
        - Added: Mouse wheel support for scrolling
3.13.1  - Updated: 110005
3.13    - Added: Track the quests that reward the Cache Rewards
        - Added: Option to allow report to be sorted in reverse (ascending instead of default descending)
3.12.2  - Fixed: Concentration reminders
3.12.1  - Added: Concentration reminders
3.12    - Cleaned: Trade Cooldowns
        - Added: Trade Concentration
3.11    - Added: CSV export
        - Fixed: Recording Cooldowns for Professions
3.10.1  - Fixed: Pandarian also gain rested at 2x the rate.
3.10    - Added: Structure to allow Pandarian to track 300% rested pool.
        - Structure: Use the table given by the client.
        - Changed: Consolidate TextToTime functions
        - Changed: Cleaner way to get guild rep info.
        - Changed: Mount report Aura changes
        - Changed: Tests use Test Realm with space in name
3.9     - Changed: Guild Standing report changes
3.8     - Added: Vault Report
        - Added: Zone Change also updates iLvl
        - Changed: Rested_Export now sorts values
3.7     - Added: "nonag <search> [ignore duration]" command to allow toons to not show up in the nag report
3.6     - NagTimeOut option to autohide nag window
3.5     - Some UI work
        - Removing some prof CDs
3.4     - Sorted Help list
        - Help report
        - Remove Azerite tracking
3.3.0   - Auctions tracking
3.2.0   - Offline report
3.1.0   - Gold Report
        - Many Changes
3.0.0   - Total rewrite.  Register events through commands, make reports and data gathering more modular.
        - Added a new data store for non-option values.
        - Found and removed tainted execution cause.
2.6.1   - Modifying missions complete time based on a follower with an Epic Mount
        - Adding code to prune missions that are no longer active (on opening mission NPC table)
2.6     - Bringing the version numbers back into sync
        - Garrison Cache (gcache) tracking
2.5     - Messed up versions with git tags
        - Garrison Mission tracking
2.4     - Gender
2.3     - New layout - shrunk search bar, and moved dropdown up next to it
        - right click menu
2.2     - Changed the ALL report to show: Level (Expected Rested) Name
2.1     - Some clean ups
2.0     - adding UI interface

1.4     - added dynamic maxLevel value based on account type
1.3     - updated for Cataclysm
        - added the find function.
1.2     - added a function to show the time since level 80's have been seen.
        - inits cutoff value at 7 days.
		- /rested nagtime # sets cutoff value
		- status massage shows character and realm count
		- stale value set to 10 days
		- stale report
1.1		- changed output to show time till fully rested.
