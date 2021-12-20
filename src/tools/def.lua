
local def = io.open("src/tools/def.def"):read("*a")

local ctx = {}

for prefix, op, name in def:gmatch("(0%w*),%s*(0x%w+), %w+, \"([%w%._]+)\"") do

    local ptr = ctx
    local r = ""
    for index, rest in name:gmatch("([%w_]*)%.([%w_]+)") do
        ptr[index] = ptr[index] or {}
        ptr = ptr[index]
        r = rest
    end
    ptr[r] = op
end

print "hi"
local function dive(t, i)
    i = i or 0
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("\t", i) .. k .. " = {")
            dive(v, i+1)
            print(string.rep("\t", i) .. "};")
        else
            print(string.rep("\t", i) .. k .. " = " .. v .. ";")
        end
    end
end


dive(ctx)
print "bye"