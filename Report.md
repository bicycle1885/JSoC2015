# JSoC 2015: The Final Report

* Participant: Kenta Sato ([@bicycle1885](https://github.com/bicycle1885))
* Mentor: Daniel C. Jones ([@dcjones](https://github.com/dcjones))

Thanks to a grant from the Gordon and Betty Moore Foundation, I've enjoyed the Julia Summer of Code 2015 program administered by the NumFOCUS and a travel to the JuliaCon 2015.
Though Julia had lots of fancy packages for numerical computing on floating-point numbers, it lacked tools that are fundamental in bioinformatics.
My project was about creating packages of sequence analysis for bioinformatics, especially an index for full-text search.
In the course towards this destination, I've created and released several packages that are useful as a building block for other data structures.
I'll introduce you these packages in this post.


## IntArrays.jl

[IntArrays.jl](https://github.com/bicycle1885/IntArrays.jl) is a package for unsigned integer arrays.
So, is it useful? Yes, it is! This is because the `IntArray` type can store integers as small space as possible.
The `IntArray` type has a type parameter `w` that represents the number of bits required to encode elements in an array.
For example, if each element is between 0 and 3, you only need to use two bits to encode it and `w` can be set to 2 or greater.
These `w`-bit integers are packed into a buffer and therefore the array consumes one forth of the usual array.

The exact type definition is `IntArray{w,T,n}`, where `w` is the number of bits for each element as I said, `T` is the type of elements,
and `n` is the dimension of an array.
This type is a subtype of the `AbstractArray{T,n}`, and will behave like a familiar array.
`IntVector` and `IntMatrix` are also defined like `Vector` and `Matrix`.

Here is an example:

```julia
julia> array = IntVector{2,UInt8}(6)
6-element IntArrays.IntArray{2,UInt8,1}:
 0x00
 0x00
 0x03
 0x03
 0x02
 0x00

julia> array[1] = 0x02
0x02

julia> array
6-element IntArrays.IntArray{2,UInt8,1}:
 0x02
 0x00
 0x03
 0x03
 0x02
 0x00

julia> sort!(array)
6-element IntArrays.IntArray{2,UInt8,1}:
 0x00
 0x00
 0x02
 0x02
 0x03
 0x03

```

Since packing and unpacking integers in a buffer require extra operations, there are overheads compared to normal arrays.
I try to keep this discrepancy as small as possible, but the `IntArray` is about 4-5 times slower when sorting:

```julia
julia> array = rand(0x00:0x03, 2^24);

julia> sort(array); @time sort(array);
  0.488779 seconds (8 allocations: 16.000 MB)

julia> iarray = IntVector{2}(array);

julia> sort(iarray); @time sort(iarray);
  2.290878 seconds (18 allocations: 4.001 MB)

```

If you have an idea to improve the performance, please let me know!


## IndexableBitVectors.jl

The next package is [IndexableBitVectors.jl](https://github.com/BioJulia/IndexableBitVectors.jl).
You must already know about the `BitVector` type in the standard library; types defined in this package is an indexable version of it.
Here "indexable" means that the number of bits between an arbitrary range can be answered in constant time.
If you are already familiar with [succinct data structures](https://en.wikipedia.org/wiki/Succinct_data_structure), you may know this is an important building block of other succinct data structures like wavelet trees, LOUDS, etcetera.

The package exports two variants of such bit vectors: `SucVector` and `RRR`.
`SucVector` is simpler and faster than `RRR`, but `RRR` is compressible and will be smaller if bits are localized in a bit vector.
Both types split a bit vector into blocks and cache the number of bits up to the position.
In `SucVector`, the extra space is about 1/4 bits per bit, so it will be ~25% larger than the original bit vector.

The most important query operation over these data structures would be the `rank1(bv, i)` query, which counts the number of bits within `bv[1:i]`.
The performance gain is really impressive:

```julia
julia> using IndexableBitVectors

julia> bv = bitrand(2^30);

julia> function myrank1(bv, i)
           r = 0
           for j in 1:i
               r += bv[j]
           end
           return r
       end
myrank1 (generic function with 1 method)

julia> myrank1(bv, 2^29); @time myrank1(bv, 2^29);
  0.714866 seconds (6 allocations: 192 bytes)

julia> sbv = SucVector(bv);

julia> rank1(sbv, 2^29); @time rank1(sbv, 2^29);
  0.000003 seconds (6 allocations: 192 bytes)

julia> rrr = RRR(bv);

julia> rank1(rrr, 2^29); @time rank1(rrr, 2^29);
  0.000004 seconds (6 allocations: 192 bytes)

```

The `select1(bv, j)` query is also useful in many cases, which locates the `j`-th bit in the bit vector `bv`.
For example, if a set of positive integers is represented in this bit vector, you can efficiently query the `j`-th smallest member in the set.

There would be many other applications on this data structure, the next package is one of them.


## WaveletMatrices.jl

You may know about the [wavelet tree](https://en.wikipedia.org/wiki/Wavelet_Tree), which supports the *rank* and *select* queries like `SucVector` and `RRR`, but elements are not restricted to boolean bits.
In fact, the *rank* and *select* queries are available on arbitrary unsigned integer types. The wavelet tree can be thought as a generaliation of indexable bit vectors in this respect.
What I've implemented is not the well-known wavelet tree, it is a variant of it called "wavelet matrix".
You can find an implementation and an original paper at [WaveletMatrices.jl](https://github.com/BioJulia/WaveletMatrices.jl).
According to the authors of the paper, the wavelet matrix is "simpler to build, simpler to query, and faster in practice than the levelwise wavelet tree".
The `WaveletMatrix` type takes three type parameters: `w`, `T`, and `B`.
`w` and `T` are similar to `IntArray{w,T,n}`, and `B` is a type of indexable bit vector.

```julia
julia> using WaveletMatrices

julia> WaveletMatrix{2}([0x00, 0x01, 0x02, 0x03])
4-element WaveletMatrices.WaveletMatrix{2,UInt8,IndexableBitVectors.SucVector}:
 0x00
 0x01
 0x02
 0x03

julia> wm = WaveletMatrix{2}([0x00, 0x01, 0x02, 0x03])
4-element WaveletMatrices.WaveletMatrix{2,UInt8,IndexableBitVectors.SucVector}:
 0x00
 0x01
 0x02
 0x03

julia> wm[3]
0x02

julia> rank(0x02, wm, 2)
0

julia> rank(0x02, wm, 3)
1

```

There are other operations that the wavelet matrix can run efficiently.
Those operations will be added in the future. WaveletMatrices.jl will be much more useful.


## FMIndices.jl

Yes, this is the final package I made.
90% of sequence analysis in bioinformatics is about sequence search.
Pattern search, homologous gene search, genome comparison, short-read mapping, etc.
The [FM-Index](https://en.wikipedia.org/wiki/FM-index) is often regarded as the most efficient index for full-text search (citation needed) and I've implemented it in the [FMIndices.jl](https://github.com/BioJulia/FMIndices.jl) package.
Thanks to the packages I've introduced so far, the code of it looks really simple.

A unique property the FM-Index has is that an index itself is just a permutation of characters of the original text and character counts.
This permutation is called [Burrows-Wheeler transform](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform) (also known as BWT), and the permuted text is stored into a wavelet matrix (or a wavelet tree) to efficiently count the number of characters in a region.
Therefore, the space required to index a text will not become so large as other full-text indices (efficiently locating query positions needs auxiliary data as well).
Moreover, this transform is bijective, hence the original text can be restored from an index.

The `FMIndex` type supports two main queries: `count` and `locate`.
The `count(query, index)` query literally counts the number of occurrences of the `query` string and the `locate(query, index)` locates starting positions of the `query`.
In order to restore the original text, you can use the `restore` function.
Here is a simple usage:

```julia
julia> using FMIndices

julia> fmindex = FMIndex("abracadabra");

julia> count("a", fmindex)
5

julia> count("abra", fmindex)
2

julia> count("abrac", fmindex)
1

julia> locate("a", fmindex) |> collect
5-element Array{Any,1}:
 11
  8
  1
  4
  6

julia> locate("abra", fmindex) |> collect
2-element Array{Any,1}:
 8
 1

julia> bytestring(restore(fmindex))
"abracadabra"

```

At the moment, indexable texts are limited to a byte sequence.


## Applications

The aim of having created these packages is to prove that Julia is a suitable language to implement this kind of data structures.
I'm pretty sure that it is true, but it may be skeptical to others.
So, I'm going to prove it by writing a useful and performant application using these packages.
Now I'm working on [FMM.jl](https://github.com/bicycle1885/FMM.jl), which aligns massive amounts of DNA fragments to a genome sequence.

The [BioJulia](https://github.com/BioJulia) project is also under active development.
The packages I made are intended to work with the [Bio.jl](https://github.com/BioJulia/Bio.jl) package.
If you are interested in the BioJulia project, we really welcome your contributions!
