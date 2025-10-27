#!/bin/lua
for line in io.lines("/etc/fstab") do
	print(line)
	if not line:find("^#") then
		print("in")
		for a in line:gmatch("([%w=-]+)%s+([%w%/-_]+)%s+(%w+)%s+(%w+)") do
			print(a)
		end
	end
end
