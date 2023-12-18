# Parse the OSRM names file
# The layout of the file is confusing, in my opinion overly so. The names are stored
# in variable-length blocks which can contain up to 17 names, in groups of five for name, ref, junction, pronunciation
# and destination.

# There is an index file that contains
# the 32-bit unsigned offset for a block, and a "descriptor" which is also a uint32. Each two bits
# of the descriptor represents the number of bytes needed to store the length of that name. At the start
# of each block in the names file, there are these number of bytes that tell the length of each name.
# The names themselves follow. A UInt32 can only hold 16 two-bit values, the 17th is implied by the remaining
# length of the block before the next one (or before the end of the file). Sometimes byteLen will be zero, this
# is because the name in question does not have a ref, etc.

# Format is documented here, but the documentation is confusing (not Telenav's fault though, the format is
# confusing as well): https://github.com/Telenav/open-source-spec/blob/master/osrm/doc/osrm-toolchain-files/map.osrm.names.md

# Unlike other parts of the Toolchain module, we don't directly refer to the mmaped file here

struct Name
    name::Union{String, Nothing}
    ref::Union{String, Nothing}
    junction_ref::Union{String, Nothing}
    name_pronunciation::Union{String, Nothing}
    destination::Union{String, Nothing}
end

Name(components::NTuple{5, Union{String, Nothing}}) = Name(components...)

struct Descriptor <: AbstractVector{UInt8}
    _value::UInt32
end

Base.getindex(d::Descriptor, i::Int) = i > 0 && i ≤ 16 ? convert(UInt8, getbits(d._value, (i - 1) * 2 + 1, (i - 1) * 2 + 2)) : throw(BoundsError(d, i))
Base.axes(::Descriptor) = (1:16,)
Base.size(::Descriptor) = 16

struct Block
    offset::UInt32
    descriptor::Descriptor
end

# read a block from the names file
function read_block!(block, nextoffset, namefile, names)
    lengths = UInt32[]
    current_offset = block.offset + one(UInt32)
    for bytelen in block.descriptor
        result = zero(UInt32)
        for byteidx in 1:bytelen
            result |= convert(UInt32, namefile[current_offset + byteidx - 1]) << ((byteidx - 1) * 8)
        end

        #@info convert(Int32, result)

        push!(lengths, result)
        current_offset += bytelen
    end


    # and the 17th item (implicit length)
    push!(lengths, nextoffset + 1 - (current_offset + sum(lengths)))

    # read the strings
    for length in lengths
        if length == 0
            push!(names, nothing)
        else
            push!(names, String(namefile[current_offset:current_offset + length - 1]))
        end
        current_offset += length
    end

    # @info sum(lengths)
    # @info nextoffset
    # @info block.offset
    # @info sum(block.descriptor)

    # @info current_offset, nextoffset
    @assert current_offset == nextoffset + 1
end

function read_names(osrm)
    nametar = read_tar_mmap(osrm * ".names", strict=false)

    nblocks = read_count(nametar, "/common/names/blocks.meta")
    blockraw = @view get_member(nametar, "/common/names/blocks")[1:(nblocks * sizeof(Block))]
    blocks = reinterpret(reshape, Block, reshape(blockraw, sizeof(Block), :))

    namefile = get_member(nametar, "/common/names/values")
    names = Union{String, Nothing}[]
    for (block, next) in zip(blocks[begin:end-1], blocks[begin+1:end])
        read_block!(block, next.offset, namefile, names)
    end

    # read the last block
    # next_offset is end of file, function assumes it is zero based since that is how recorded
    # in the blocks file
    read_block!(last(blocks), length(namefile), namefile, names)

    close(nametar)

    return map(Name, zip(
        names[1:5:end],
        names[2:5:end],
        names[3:5:end],
        names[4:5:end],
        names[5:5:end]
    ))
end