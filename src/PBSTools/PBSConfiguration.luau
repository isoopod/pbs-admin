-- Integrate with the PBSConfiguration module from rewrite for some rewrite commands. Like the PBSData module, test in rewrite and dont use this.

local config = {}

config.LogDuration = 1

export type PBSConfiguration = {
	LogDuration: number,
}

return config
