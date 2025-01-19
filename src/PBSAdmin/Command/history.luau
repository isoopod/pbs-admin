local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PBSData = require(ServerScriptService.PBSServer.PBSData)
local command = require(script.Parent)

local PBSConfiguration = require(ReplicatedStorage.PBSTools.PBSConfiguration)

local Bytenet = command.PublicUtils.Bytenet

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = {}

cmd.help = `Opens a list of PBS related actions (e.g. place, delete) performed by all players from the past {PBSConfiguration.LogDuration} hours.`

-- Is using a min-heap structure to merge all the history logs into one overkill? Yes.
-- Insert a HeapNode into the heap
type HeapNode = { value: PBSData.HistoryEntry, arrayIndex: number, itemIndex: number }

-- Function to push an element into the min-heap
local function heapPush(heap: { HeapNode }, item: HeapNode)
	table.insert(heap, item)
	local i = #heap
	while i > 1 do
		local parent = i // 2
		if heap[parent].value.timestamp <= item.value.timestamp then break end
		heap[i] = heap[parent]
		i = parent
	end
	heap[i] = item
end

-- Function to pop the smallest element from the min-heap
local function heapPop(heap: { HeapNode }): HeapNode?
	if #heap == 0 then return nil end
	local root = heap[1]
	local last = table.remove(heap)
	if #heap == 0 then return root end

	heap[1] = last
	local i = 1
	while true do
		local left = 2 * i
		local right = left + 1
		local smallest = i

		if left <= #heap and heap[left].value.timestamp < heap[smallest].value.timestamp then smallest = left end
		if right <= #heap and heap[right].value.timestamp < heap[smallest].value.timestamp then smallest = right end
		if smallest == i then break end

		heap[i], heap[smallest] = heap[smallest], heap[i]
		i = smallest
	end

	return root
end

-- Merge function
local function mergeSortedArraysByTimestamp(arrays: { { PBSData.HistoryEntry } }): { PBSData.HistoryEntry }
	local result = {}
	local minHeap = {}

	-- Initialize heap with the first element from each array
	for i, array in arrays do
		if #array > 0 then heapPush(minHeap, { value = array[1], arrayIndex = i, itemIndex = 1 }) end
	end

	-- Merge arrays using the min-heap
	while #minHeap > 0 do
		-- Extract the smallest element from the heap
		local smallest = heapPop(minHeap)
		table.insert(result, smallest.value)

		-- Add the next element from the same array to the heap
		local arrayIndex = smallest.arrayIndex
		local nextIndex = smallest.itemIndex + 1
		if nextIndex <= #arrays[arrayIndex] then heapPush(minHeap, { value = arrays[arrayIndex][nextIndex], arrayIndex = arrayIndex, itemIndex = nextIndex }) end
	end

	return result
end

-- This will send the data to the client reversed, so it should be iterated in reverse order to display correctly
function cmd.__call(self: command.Command, player: Player): (number, string)
	-- Collect all the arrays and merge them in order
	local arrays = {}
	for user, data in PBSData.IterateOverData() do
		-- Add the userids to all history entries
		data = table.clone(data)
		for _, v in data.history do
			v.userid = user
		end

		table.insert(arrays, data.history)
	end
	-- We will offload the task of converting the userids to a username to the client

	local globalHistory = mergeSortedArraysByTimestamp(arrays)

	Bytenet.HISTORY.sendTo(globalHistory, player)
	return self.Responses.Success, "Opened history"
end

return cmd
