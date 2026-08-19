-- Mouse behaviour macOS cannot express and Karabiner cannot be approved for.
-- See docs/MACOS_INPUT.md.
--
-- Taps live in a global table on purpose. hs.eventtap objects are garbage
-- collected as soon as nothing references them, and a collected tap stops
-- firing with no error. File-scope locals are not enough: Hammerspoon does not
-- retain this chunk once init.lua finishes, so its locals become collectable.
-- The global also lets `hs -c` inspect them.

-- Exposes the `hs` CLI, which bootstrap.sh uses to ask whether Accessibility
-- was actually granted instead of assuming a running process means a working one.
require("hs.ipc")

local props = hs.eventtap.event.properties
local types = hs.eventtap.event.types

local AEROSPACE = "/opt/homebrew/bin/aerospace"

-- Button numbers are zero-based, so the thumb buttons sold as "mouse4"/"mouse5"
-- report 3 and 4.
local THUMB_BACK = 3
local THUMB_FORWARD = 4

-- --no-stdin is required, not optional. AeroSpace v0.20.0 forbids implicit
-- stdin, so invoked from anything without a TTY -- hs.task here, but equally a
-- launchd job -- it errors out instead of switching. It works when typed in a
-- terminal, which is what makes the omission easy to miss.
local WORKSPACE_COMMAND = {
	[THUMB_BACK] = { "workspace", "--no-stdin", "--wrap-around", "prev" },
	[THUMB_FORWARD] = { "workspace", "--no-stdin", "--wrap-around", "next" },
}

-- macOS has one global scroll direction for every pointing device, which is why
-- this exists at all. Trackpads emit pixel-precise continuous events; a notched
-- wheel emits discrete ticks. Inverting only the discrete ones leaves the
-- trackpad natural without needing to identify the device.
inputTaps = {}

inputTaps.scroll = hs.eventtap.new({ types.scrollWheel }, function(event)
	if event:getProperty(props.scrollWheelEventIsContinuous) ~= 0 then
		return false
	end
	for _, axis in ipairs({
		props.scrollWheelEventDeltaAxis1,
		props.scrollWheelEventFixedPtDeltaAxis1,
		props.scrollWheelEventPointDeltaAxis1,
	}) do
		event:setProperty(axis, -event:getProperty(axis))
	end
	return false
end)

inputTaps.thumb = hs.eventtap.new({ types.otherMouseDown, types.otherMouseUp }, function(event)
	local command = WORKSPACE_COMMAND[event:getProperty(props.mouseEventButtonNumber)]
	if not command then
		return false
	end
	-- Both down and up are swallowed; releasing a button whose press never
	-- arrived leaves apps that track drag state confused.
	if event:getType() == types.otherMouseDown then
		hs.task.new(AEROSPACE, nil, command):start()
	end
	return true
end)

inputTaps.scroll:start()
inputTaps.thumb:start()

-- Parity with aerospace.toml's auto-reload-config. Watches the repo directory,
-- not hs.configdir: init.lua is a symlink into this repo, and FSEvents on
-- ~/.hammerspoon never fires for writes made to the link's target.
local CONFIG_DIR = os.getenv("HOME") .. "/.config/hammerspoon"

inputTaps.configWatcher = hs.pathwatcher.new(CONFIG_DIR, function(files)
	for _, file in ipairs(files) do
		if file:sub(-4) == ".lua" then
			hs.reload()
			return
		end
	end
end)
inputTaps.configWatcher:start()
