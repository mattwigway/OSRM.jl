struct MMapTarFile
    members::Dict{String, Tuple{Tar.Header, Int64}}
    io::IO
    contents::AbstractVector{UInt8}
end

function read_tar_mmap(filename; strict=true)::MMapTarFile
    current_offset = 1
    io = open(filename, "r")
    result = MMapTarFile(Dict(), io, mmap(io, Vector{UInt8}))
    Tar.list(filename, strict=strict) do header
        current_offset += 512
        result.members[header.path] = (header, current_offset)
        current_offset += if header.size % 512 == 0
            header.size
        else
            header.size + 512 - (header.size % 512)
        end
    end

    return result
end

function get_member(f::MMapTarFile, name)
    header, offset = f.members[name]

    @view f.contents[offset:offset + header.size]
end

Base.close(f::MMapTarFile) = close(f.io)