local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AInt = require(ReplicatedStorage.Shared.MultiPliers.std.AInt)

--[=[
	This is just a prototype i guess (sorta) for an (optional) Int type API that might even get scrapped. Will add codegen for it later.
	The idea is that Ints aren't affected by loss of precision, so you can use Ints where you REALLY need precision or MASSIVE numbers,
	and I mean storing 340.282.366.920.938.463.463.374.607.431.768.211.455 in a UInt128 type of massive.
	Also int8 takes up much less memory than a 64 bit float, especially if there's a lot of them.
	However, because there's no SIMD instruction support (or AT LEAST native int support) and all that, ints might be very very slow to use,
	and mass calculations might be quite intense.
	You will be able to turn off all Int APIs below 64 bits of size, and it'll use Lua's number type, which is probably more performant,
	because this one does a lot of bit shifting all over the buffers.
	Rules about how integers interact will be mostly based on C and C++ standards' take on integer types.
	Probably will add metadata to force use of Int APIs for a variable, if i even add them.

	Same thing planned for Floats too (float32 and float128 are planned at the very least,
	partially because floats less than 32 bits aren't even properly standardised,
	so there are multiple implementations of something like a float 16 with varying degrees of accuracy and range).
]=]
local Int8Impl = AInt

function Int8Impl.new()
	local instance = {}
	instance.buf = buffer.create(1)
	return setmetatable(instance, Int8Impl)
end

function Int8Impl:setNumber(num: number)
	self.buf = buffer.writei8(buffer.fill(self.buf, 0, 0), 0, math.floor(num))
end

function Int8Impl:setInt8(i: typeof(Int8Impl))
	self.buf = i.buf
end

function Int8Impl:setInt16(i: typeof(Int16Impl))
	self.buf = buffer.writei8(self.buf, 0, buffer.readi8(i, 0))
end

function Int8Impl:addNumber(num: number) end

return Int8Impl
