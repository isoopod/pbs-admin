# Setup
### Dependencies
PBS Admin needs a saving world to function. See the guides in the discord if you are unsure. 
I would recommend using PBS Autosave for place saving over the one that comes with Poor Man's PBS
You can get PBS Autosave from the PBS Marketplace channel in the discord

### Downloading
Download the latest version of PBS Admin from the GitHub releases page on the right of the page.
You may also download the extra command pack from the releases page as well.
(The rbxm files are what you want, ignore the source files)

### Installation
If a previous version has been installed, remove it now.
In roblox studio, right click on ServerScriptService in the explorer and select `insert from file`
Select the PBSAdmin vX.X.X.rbxm and press open.
A new script called PBSAdmin should have been created.
Navigate to PBSAdmin/Permissions and in the properties window, add an attribute
    Set the attribute's name to your roblox UserID (can be grabbed from the numbers in the url of your roblox profile)
    Make sure the attribute type is set to string
    Create the attribute
    Edit the attribute's value to be `owner`
    Repeat for any other owners, or add them as owners in-game later.
Place the stamper tools inside PBSAdmin/RoleAssets/member
(See [Usage](./Usage.md#role-assets) for more information on using the RoleAssets)

If you got the extra command pack, right click on PBSAdmin/Command and insert from file the extra command pack.
Next ungroup the extra command pack so all the command module scripts are children of PBSAdmin/Command.
(See [Usage](./Usage.md#editting-commands) for more information on editing commands)