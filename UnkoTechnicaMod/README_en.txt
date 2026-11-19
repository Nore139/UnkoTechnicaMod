==============================================================
 UNKO TECHNICA Unofficial MOD (GPU rendering + CANNON fix)  v1.0.1
==============================================================

This is an UNOFFICIAL MOD. Use it at your own risk.
Please do not contact the game's developer about this MOD.


- What this MOD does
--------------------------------------------------------------
1. Fixes stutter (GPU rendering)
   Replaces the game's runtime (NW.js) from the bundled old version (0.29.0) with a newer version (0.118.0).
   On some PCs the old runtime cannot use the graphics card and draws everything with the CPU,
   which makes later stages stutter. With the newer runtime, the game renders with your graphics card.

2. Fixes the CANNON direction bug
   If you enter a rotating CANNON on the exact moment it rotates, it turns one extra step (90 degrees).
   This MOD fixes that. Game version 1.0.6 includes an almost identical official fix;
   this MOD does not double-correct when combined with it.

Stages, save data and other game content are not changed.


- Requirements
--------------------------------------------------------------
- Steam version of "UNKO TECHNICA"
  Tested game versions: 1.0.5 / 1.0.6
  (The game version is shown on the title screen and in the MOD window.)
- Windows 10 / 11 (64-bit)
- Internet connection (about 216 MB is downloaded the first time)
- About 1 GB of free disk space


- How to install
--------------------------------------------------------------
1. Close the game.
2. Right-click the downloaded ZIP file and choose "Extract All...".
   (It will not work if you run it directly from inside the ZIP.)
3. Double-click "UnkoTechnicaMod.bat" in the extracted folder.
4. Check that "Game folder" has been filled in automatically, then press "Apply MOD".
   - If the folder is empty, press "Browse..." and select the folder that contains Game.exe.
     (In Steam: right-click the game > Manage > Browse local files)
5. When "Done!" appears, you are finished. Start the game from Steam as usual.

* The first time, the runtime is downloaded from the official NW.js site (dl.nwjs.io). It may take a few minutes.
* The downloaded file is verified with SHA-256 before it is used.


- If you see a warning
--------------------------------------------------------------
- "Windows protected your PC": click "More info", then "Run anyway".
- "The publisher could not be verified": click "Run".
- "Could not write to the game folder": right-click "UnkoTechnicaMod.bat" and choose "Run as administrator".


- How to uninstall
--------------------------------------------------------------
1. Close the game.
2. Double-click "UnkoTechnicaMod.bat" and press "Restore original".

If something still looks wrong, in Steam right-click the game > Properties > Installed Files >
"Verify integrity of game files". This restores the official files.


- After a game update
--------------------------------------------------------------
A Steam update or "Verify integrity of game files" may undo part of the MOD.
In that case, simply press "Apply MOD" again. (The "Status" line tells you when this has happened.)


- About save data
--------------------------------------------------------------
- The save data location does not change. Your saves work with or without the MOD.
- Just in case, your save data is backed up every time you apply the MOD:
    %LOCALAPPDATA%\UnkoTechnicaMod\save_backups\
  (Type this into the File Explorer address bar to open it.)


- Technical details
--------------------------------------------------------------
- Downloads NW.js 0.118.0 (Windows 64-bit) from the official site and stores it in
    %LOCALAPPDATA%\UnkoTechnicaMod\
- Moves the game's runtime files (Game.exe, nw.dll, etc.) to _unko_mod\runtime_backup inside the game folder,
  then copies in the new runtime.
- Adds the CANNON fix plugin (CannonPhaseFix.js) to www\js\plugins and registers it in plugins.js.
- The only network access is the download from the official NW.js site.
- A log is written to %LOCALAPPDATA%\UnkoTechnicaMod\mod_log.txt.
  Please attach this file when reporting a problem.

To remove the MOD completely, press "Restore original", then delete the
%LOCALAPPDATA%\UnkoTechnicaMod folder and this MOD's folder.


- Notes
--------------------------------------------------------------
- Whether this MOD may be used for speedrun or other records depends on each leaderboard's rules.


- Terms of use
--------------------------------------------------------------
- Redistribution of this MOD is not allowed. To share it, please link to the download page.
  (For your safety, the genuine MOD is only available from the download page.)
- You may modify it for your own personal use. If you want to publish a modified version, please contact me first.
- The author is not responsible for any problems caused by using this MOD.


- Contact
--------------------------------------------------------------
X (Twitter): https://x.com/Nore139
Download page: https://github.com/Nore139/UnkoTechnicaMod


- Changelog
--------------------------------------------------------------
v1.0.1  Supports game version 1.0.6
        - The MOD window now shows the game version and whether it has been tested
        - Shows a confirmation message before applying to an untested game version
        - Added a safety check so the CANNON fix cannot affect other events after a game update
v1.0.0  First public release
