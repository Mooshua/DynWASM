
local ffi = require "ffi"
local buffer = require "string.buffer"
local utf8 = require "src.util.utf8"


local _U32 = ffi.typeof("uint32_t")
local _I32 = ffi.typeof("int32_t")
local _I64 = ffi.typeof("int64_t")
local _U64 = ffi.typeof("uint64_t")
local _F32 = ffi.typeof("float")
local _F64 = ffi.typeof("double")
local _VEC = "vec"

local Binary = 
{

    Numbers = 
    {
        i32 = 0x7F;
        i64 = 0x7E;
        f32 = 0x7D;
        f64 = 0x7C;
    };

    Vector = 
    {
        v128 = 0x7B;
    };

    Ref = {
        Func = 0x70;
        Extern = 0x6F;
    };

    Function = 0x60;

    Limits = {
        Min = 0x00;
        MinMax = 0x01;
    };

    Global = {
        Const = 0x00;
        Mutate = 0x01;
    };

    Sections = {
        Custom = 0;
        Type = 1;
        Import = 2;
        Function = 3;
        Table = 4;
        Memory = 5;
        Global = 6;
        Export = 7;
        Start = 8;
        Element = 9;
        Code = 10;
        Data = 11;
        DataCount = 12
    };

    Instructions = 
    {
        --  Metadata instructions

        End = 0x0B;

        --  Control instructions
        Unreachable = 0x00;
        Nop = 0x01;

        --  No clue what the standard wants me to do here
        --  "s33 (sic), byte, or 0x40"
        --  So i'll leave it as an s32; LEB128 will handle varying lengths.
        --  TODO: is s32 == blocktype a valid assumption?
        Block = { 0x02, i32 };
        Loop = { 0x03, i32 };
        If = { 0x04, i32 };
        Else = { 0x05, i32 };

        --  Labelidx, always u32
        Br = { 0x0C, u32 };
        Br_If = { 0x0D };
        Br_Table = { 0x0E, u32 };

        Return = 0x0F;

        Call = 0x10;
        CallTable = 0x11;

        --  Reference instructions
        Ref = 
        {
            Null = 0xD0;
            Is_Null = 0xD1;
            Func = 0xD2;
        };

        --  Parametric types
        Drop = 0x1A;
        Select = 0x1B;

        --  Table
        Table = 
        {
            Get = 0x25;
            Set = 0x26;
            Init = { 0xFC, _U32(12) };
            Copy = { 0xFC, _U32(14) };
            Grow = { 0xFC, _U32(15) };
            Size = { 0xFC, _U32(16) };
            Fill = { 0xFC, _U32(17) };
        };

        Elem = 
        {
            Drop = { 0xFC, _U32(13) };
        };

        --  Memory instructions
        --  oh no
        --  memarg: { _, _U32, _U32 }

        i32 = 
        {
            Load = { 0x28, _U32, _U32 };
            Load8_s = { 0x2C, _U32, _U32 };
            Load8_u = { 0x2D, _U32, _U32 };
            Load16_s = { 0x2E, _U32, _U32 };
            Load16_u = { 0x2F, _U32, _U32 };

            Store = { 0x36, _U32, _U32 };
            Store8 = { 0x3A, _U32, _U32 };
            Store16 = { 0x3B, _U32, _U32 };

            Const = { 0x41, _I32 };

            --  Automatically generated

            lt_u = 0x49;
            gt_s = 0x4a;
            gt_u = 0x4b;
            le_s = 0x4c;
            clz = 0x67;
            ["and"] = 0x71;
            le_u = 0x4d;
            ctz = 0x68;
            ge_s = 0x4e;
            popcnt = 0x69;
            ge_u = 0x4f;
            wrap_i64 = 0xa7;
            reinterpret_f32 = 0xbc;
            trunc_f32_s = 0xa8;
            mul = 0x6c;
            trunc_f32_u = 0xa9;
            ["or"] = 0x72;
            div_s = 0x6d;
            trunc_f64_s = 0xaa;
            div_u = 0x6e;
            trunc_f64_u = 0xab;
            rem_s = 0x6f;
            rem_u = 0x70;
            xor = 0x73;
            shl = 0x74;
            sub = 0x6b;
            shr_s = 0x75;
            eqz = 0x45;
            rotl = 0x77;
            add = 0x6a;
            ne = 0x47;
            rotr = 0x78;
            eq = 0x46;
            shr_u = 0x76;
            lt_s = 0x48;
        };

        i64 = 
        {
            Load = { 0x29, _U32, _U32 };
            Load8_s = { 0x30, _U32, _U32 };
            Load8_u = { 0x31, _U32, _U32 };
            Load16_s = { 0x32, _U32, _U32 };
            Load16_u = { 0x33, _U32, _U32 };
            Load32_s = { 0x34, _U32, _U32 };
            Load32_u = { 0x35, _U32, _U32 };

            Store = { 0x37, _U32, _U32 };
            Store8 = { 0x3C, _U32, _U32 };
            Store16 = { 0x3D, _U32, _U32 };
            Store32 = { 0x3E, _U32, _U32 };

            Const = { 0x42, _I64 };

            --  Automatically generated

            lt_u = 0x54;
            gt_s = 0x55;
            gt_u = 0x56;
            le_s = 0x57;
            clz = 0x79;
            ["and"] = 0x83;
            le_u = 0x58;
            ctz = 0x7a;
            ge_s = 0x59;
            popcnt = 0x7b;
            ge_u = 0x5a;
            add = 0x7c;
            trunc_f32_s = 0xae;
            reinterpret_f64 = 0xbd;
            mul = 0x7e;
            trunc_f32_u = 0xaf;
            ["or"] = 0x84;
            div_s = 0x7f;
            trunc_f64_s = 0xb0;
            div_u = 0x80;
            trunc_f64_u = 0xb1;
            rem_s = 0x81;
            extend_i32_s = 0xac;
            rem_u = 0x82;
            extend_i32_u = 0xad;
            xor = 0x85;
            shl = 0x86;
            sub = 0x7d;
            shr_s = 0x87;
            eqz = 0x50;
            rotl = 0x89;
            shr_u = 0x88;
            rotr = 0x8a;
            ne = 0x52;
            eq = 0x51;
            lt_s = 0x53;
        };

        f32 = 
        {
            Load = { 0x2A, _U32, _U32 };
            Store = { 0x38, _U32, _U32 };

            Const = { 0x43, _F32 };

            --  Automatically generated

            floor = 0x8e;
            ceil = 0x8d;
            sqrt = 0x91;
            nearest = 0x90;
            max = 0x97;
            demote_f64 = 0xb6;
            reinterpret_i32 = 0xbe;
            convert_i64_u = 0xb5;
            neg = 0x8c;
            div = 0x95;
            convert_i32_u = 0xb3;
            convert_i32_s = 0xb2;
            sub = 0x93;
            lt = 0x5d;
            copysign = 0x98;
            add = 0x92;
            gt = 0x5e;
            min = 0x96;
            convert_i64_s = 0xb4;
            le = 0x5f;
            mul = 0x94;
            ge = 0x60;
            ne = 0x5c;
            eq = 0x5b;
            trunc = 0x8f;
            abs = 0x8b;
        };

        f64 = 
        {
            Load = { 0x2B, _U32, _U32 };
            Store = { 0x39, _U32, _U32 };

            Const = { 0x44, _F64 };

            --  Automatically generated

            floor = 0x9c;
            ceil = 0x9b;
            sqrt = 0x9f;
            nearest = 0x9e;
            max = 0xa5;
            reinterpret_i64 = 0xbf;
            promote_f32 = 0xbb;
            convert_i64_u = 0xba;
            neg = 0x9a;
            div = 0xa3;
            convert_i32_u = 0xb8;
            convert_i32_s = 0xb7;
            sub = 0xa1;
            lt = 0x63;
            copysign = 0xa6;
            add = 0xa0;
            gt = 0x64;
            min = 0xa4;
            convert_i64_s = 0xb9;
            le = 0x65;
            mul = 0xa2;
            ge = 0x66;
            ne = 0x62;
            eq = 0x61;
            trunc = 0x9d;
            abs = 0x99;
        };
        
        Memory = 
        {
            Size = { 0x3F, 0x00 };
            Grow = { 0x40, 0x00 };
            Init = { 0xFC, _U32(8) };
            Copy = { 0xFC, _U32(10), 0x00, 0x00 };
            Fill = { 0xFC, _U32(11), 0x00 };
        };

        Data = 
        {
            Drop = { 0xFC, _U32(9) };
        };

    };

    Alias = 
    {
    };

    

}

local Const = {
    i32 = Binary.Numbers.i32;
    i64 = Binary.Numbers.i64;
    f32 = Binary.Numbers.f32;
    f64 = Binary.Numbers.f64;
    v128 = Binary.Vector.v128;
    funcref = Binary.Ref.Func;
    externref = Binary.Ref.Extern;
    functype = Binary.Function;
    limit_min = Binary.Limits.Min;
    limit_minmax = Binary.Limits.MinMax;
    const = Binary.Global.Const;
    mut = Binary.Global.Mutate;
    empty = 0x40;
}

local Encode = {}

function Encode:Byte(b)

    if type(b) == "string" then
        return self.Buffer:put(string.sub(b,1,1))
    end

    self.Buffer:put(string.char(b))
end

function Encode:Bytes(...)
    for k, v in pairs{...} do
        self:Byte(v)
    end
end

function Encode:ULEB128(num)

    --  **SHOULD ONLY BE USED ON UNSIGNED NUMBERS**
    --  Check abs(num) == num when not invoked from :LEB128()

    local value = num

    repeat
        
        local now = bit.band(value, 127)

        local islast = (now ~= value and 128) or 0
        --  if the AND did not remove any bits from the value,
        --  then there are no more bits.
        self:Byte(now + islast)

        value = bit.rshift(value, 7);

    until value == 0
end

do
    local u = ffi.typeof[[
        union {
            float num;
            uint32_t asInt;
        }
    ]]

    local d = ffi.typeof[[
        union {
            double num;
            uint64_t asInt;
        }
    ]]

    function Encode:Float(num)
        local cvt = u { num = num }
        self:ULEB128(cvt.asInt)
    end

    function Encode:Double(num)
        local cvt = d { num = num }
        self:ULEB128(cvt.asInt)
    end
end

function Encode:LEB128(num)

    --  !!LUAJIT NUMBERS ARE ALREADY SIGNED!!
    --  This means that all we need to do is calculate logarithm and negate.
    --  "easy" right?                                                                                   please help

    local length = math.floor(math.log(math.abs(num)) / math.log(2))
    local seven = (math.floor(length / 7) + 1) * 7

    local toand = 1
    for i = 1,seven-1 do
        toand = toand + (2 ^ i)
    end
    
    self:ULEB128(bit.band(num, toand))

end

function Encode:Unsigned32(value)
    local num = bit.band(value, 0xFFFFFFFF)

    self:ULEB128(num)
end

function Encode:Vector(length, callback)

    self:Unsigned32(length)

    for i = 1, length do
        callback(self, i)
    end

end

function Encode:AppendEncoderAsSection(id, other)

    self:Byte(id)

    self:Unsigned32(other.Buffer:len())

    self.Buffer:put(other.Buffer)

end

function Encode:String(str)

    local str8 = utf8.toutf8(str)

    self:Vector(#str8, function(self, i)
        self:Byte(string.sub(str8,i,i))
    end)

end

function Encode.New()
    local o = {
        Buffer = buffer.new()
    }

    return setmetatable(o, Encode)
end

local function do_vec(lang, vec)
    local a = string.gsub(lang.Vector, "<%-values%->", vec)
    return a 
end

local function do_vararg_vec(lang, ...)
    local v = {...}
    return do_vec(lang, table.concat(v, lang.ArgSeparator))
end

local function Compile(text, lang)

    text = text .. "\n"

    --  1.  GSUB over piped lines to generate output
    local emitted = text:gsub("(%s*)|(%C*)\n", function(spc, line)

        --  1. What's our directive (assembly/macro)
        --  2. Are we a macro?
        local isMacro, directive,drest = line:match("%s*(.?)([%w%._%-]+)(.+)")
        isMacro = isMacro == "."

        --  3. Convert vectors to tables
        drest = drest:gsub("%s+(%b())", function(vec)
            return do_vec(lang, string.sub(vec, 2, -2))
        end)

        --  Strings are just vectors, right?
        drest = drest:gsub('(%b"")', function(chars)
            chars = string.sub(chars, 2, -2)
            local str = utf8.toutf8(chars)
            local str2table = {}
            for i = 1, #str do
                table.insert(str2table, string.byte(string.sub(str, i, i)))
            end
            local l = #str
            return do_vararg_vec(lang, l, unpack(str2table))
        end)

        --  4. If macro, use language pack

        print(drest)
        

        return string.format("%s%s\n", spc, out)

    end)

    print(emitted)


end

Compile(io.open("examples/bf.dasm"):read("*a"), require("src/compiler/lua"))
