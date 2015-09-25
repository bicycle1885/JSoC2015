using Bio.Seq
using IntArrays
using FMIndexes

# encode a DNA sequence with 3-bit unsigned integers
function encode(seq)
    encoded = IntVector{3,UInt8}(length(seq))
    for i in 1:endof(seq)
        encoded[i] = convert(UInt8, seq[i])
    end
    return encoded
end

# read a chromosome from a FASTA file
filepath = ARGS[1]
record = first(open(filepath, FASTA))
println(record.name, ": ", length(record.seq), "bp")
# build an FM-Index
fmindex = FMIndex(encode(record.seq))
# save it in a file file
open(string(filepath, ".index"), "w+") do io
    serialize(io, fmindex)
end
