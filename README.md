# PBS Admin
PBS Admin exists to make it simple to manage permissions in your PBS. Compared to its predecessor, PBS Admin includes a simplified set of commands and the ability to manage players not currently in the server by using their UserId. PBS Admin can also be used to verify a players permissions in other scripts, allowing you to make sure a player should be able to do something.

### [Installation Guide](docs/Installation.md)

### [Usage Guide](docs/Usage.md)

### [Modding/Integration Guide](docs/Modding.md)


## Setup Instructions
All PBS Admin requires to set up is for it to be placed into ServerScriptService and for tools to be placed in the folder. You should also add yourself as owner by adding an attribute with Type set to string to the permissions module with the attribute name as your roblox UserId and the value as "owner".

### PBS Admin can integrate with our discord server.
This feature is only available for PBS's hosted under our roblox group, to ensure the safety of the API key. To enable this feature you will need to message @isoopod, and I will create the Secret for your PBS. Note that you can only test this feature in a team test or the live game, as Secrets do not work in local tests.
We aim to make hosting PBSes under the group much easier in the future.

### Agreement
If using the integration feature, you are not to modify the permissions module in a way that would break the TOS of RoVer's API, Discord, or ROBLOX.
Anyone is allowed to create their own custom commands as long as they follow the ROBLOX terms and conditions.
you may freely get a users permissions from the module anywhere else, but you should only call .EditPersistentRole or directly edit the attributes for things like moderator integration with a custom leaderboard GUI