# JSoC2015


Efficient data structures and algorithms for sequence analysis in BioJulia
--------------------------------------------------------------------------

Applicant: Kenta Sato (GitHub: @bicycle1885)
Mentor: Daniel C. Jones (GitHub: @dcjones)


Summary
-------
Large-scale sequence analysis is a fundamental part of recent bioinformatics.
High-throughput DNA sequencers generate massive amount of short DNA fragments from biological samples and these fragments should be located where they come from in other long sequences for downstream analyses.
In order to search the matching locations of these short sequences in a long sequence like the human genome, efficient data structures and algorithms are indispensable.
In this project, under the BioJulia project (https://github.com/BioJulia), we will develop a full-text search and alignment library based on the FM-index[4].
The result will enhance the use of the Julia language for sequence analysis in the bioinformatics community and hence encourage more developers to write programs in the related fields of biology.


What I will make
----------------
I will implement sequence searcher/aligner based on the FM-index to handle genome-scale sequence data from high-throuput sequencing.
This would be the most commonly used technique to build fast and compact indices for full-text search, adopted by Burrows-Wheeler Aligner (BWA)[2] and bowtie2[1] software when aligning massive short sequences to a huge genome sequence.
The FM-index search is run over a text of Burrow-Wheeler transform (BWT)[3] of the original text and the transformed text need to be stored in a compact data structure that supports fast occurrence count of characters[5].
To fulfill the demands, I will develop Julia packages about succinct data structures: bit vector and Wavelet tree/matrix.
These data structures enable occurrence count of characters for a sequence of arbitrary length in constant time.

Since the BioJulia project already has basic data structures to represent sequences, I will implement these tools on the top of them for seamless integration.
As for biological sequences, the alignment algorithm should allow small mismatches or gaps to be robust against noises and genetic variants.
I will consult other implementations to handle short mismatches well.


Demonstration
-------------
I have made two new packages required to create the search engine in order to show the implementability of this project:
* IndexedBitVectors.jl https://github.com/bicycle1885/IndexedBitVectors.jl
* WaveletMatrices.jl https://github.com/bicycle1885/WaveletMatrices.jl

IndexedBitVectors.jl is for a data structure like a bit vector, which allows some operations like bit count in constant time with small memory overhead.
WaveletMatrices.jl is built on the top of IndexedBitVectors.jl, which supports to store 8bit elements rather boolean elements.

Using these data structures and the FM-index, I implemented a DNA fragment searcher in the human genome.
It can calculate the number of occurrences of the query fragment in a chromosome for 10-100μ seconds while linear search requires nearly x1000 time (10-100m seconds).

For more details, please refer to the following links:
https://github.com/bicycle1885/WaveletMatrices.jl#demo
https://github.com/bicycle1885/WaveletMatrices.jl/blob/master/fmindex.jl


Plan
----
* June 15-30 - Choose and implement data structures
     There are several variants of succinct data structures.
     I will survey researches and try proposed data structures.
* July 1-14 - Implement efficient operations and FM-index.
     Fast and low memory constructions are needed when handling large data.
     I will implement constructors, FM-index search, and other APIs at this point.
* July 15-31: Specialization for BioJulia
     Support search and alignment for biological sequences defined in BioJulia including short mismatches and gaps.
* September 1-15: Debug and performance tuning.
     Brush up details of the program.


Impact
------
This will be a meaningful step toward sequence analysis because sequence search and alignment are indispensable building blocks of bioinformatics.
Almost all of the existing programs related to this kind of sequence analysis are implemented in C, C++, and Java, but simplicity and dynamic nature of Julia would be appealing if comparable performance can be achieved.


About me
--------
I am a graduate school student at the University of Tokyo, Japan, studying bioinformatics and human genetics.
I have about 1.5 years’ experience of intensive Julia programming and have developed several packages in Julia:
* DocOpt.jl - a command-line argument parser (registered in METADATA)
* RandomForests.jl - a machine learning method that builds lots of decision trees
* Snappy.jl - a binding to a fast compression library
* ANMS.jl - a derivative-free multivariate optimization method with adaptive parameters for high dimensions

I am one of founders of the JuliaTokyo user group and we held meetups for three times in 2014 and 2015, the total turnout was about 150.


References
----------
1. Langmead, Ben, et al. "Ultrafast and memory-efficient alignment of short DNA sequences to the human genome." Genome Biol 10.3 (2009): R25.
2. Li, Heng, and Richard Durbin. "Fast and accurate short read alignment with Burrows–Wheeler transform." Bioinformatics 25.14 (2009): 1754-1760.
3. Burrows, Michael, and David J. Wheeler. "A block-sorting lossless data compression algorithm." (1994).
4. Ferragina, Paolo, and Giovanni Manzini. "Opportunistic data structures with applications." Foundations of Computer Science, 2000. Proceedings. 41st Annual Symposium on. IEEE, 2000.
5. Ferragina, Paolo, et al. "Compressed text indexes: From theory to practice."Journal of Experimental Algorithmics (JEA) 13 (2009): 12.

