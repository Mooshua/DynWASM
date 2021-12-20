
local Dynwasm = {}

function Dynwasm.New()
    local o = {
        Sections = {}
    }

    for i = 0, 12 do
        Sections[i] = {}
    end

    return o
end

function Dynwasm.Append(Dst, idx, data)
    table.insert(Dst.Sections[idx], data)
end

--  CTRL+C
local function ULEB128(num)

    local bytes = {}
    local value = num

    repeat
        
        local now = bit.band(value, 127)

        local islast = (now ~= value and 128) or 0
        --  if the AND did not remove any bits from the value,
        --  then there are no more bits.
        table.insert(bytes, string.char(now + islast))

        value = bit.rshift(value, 7);

    until value == 0

    return bytes
end

local function LinkStep(Dst, Step)
    Dst[Step] = table.concat(Dst[Step],"")
end

function Dynwasm.Link(Dst)
    local buf = {"\0asm\1\0\0\0"}

    for k,v in ipairs(Dst.Sections) do

        local concat = table.concat(Dst.Sections, "")
        local size = #concat
        local mode = k

        table.insert(buf, )
    end
end


return Dynwasm