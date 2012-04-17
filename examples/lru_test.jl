load("lru.jl")

const TestLRU = UnboundedLLRU{ASCIIString, ASCIIString}()
const TestBLRUs = BoundedLLRU{ASCIIString, ASCIIString}(100)
const TestBLRUm = BoundedLLRU{ASCIIString, ASCIIString}(1000)
const TestBLRUl = BoundedLLRU{ASCIIString, ASCIIString}(10000)
const TestBLRUxl = BoundedLLRU{ASCIIString, ASCIIString}(100000)

indent() = print("        ")
get_str(i) = ascii(vcat(map(x->[x>>4; x&0x0F], reinterpret(Uint8, [int32(i)]))...))

isbounded{L<:LRU}(::Type{L}) = any(map(n->n==:maxsize, L.names))
isbounded{L<:LRU}(l::L) = isbounded(L)

nmax = int(logspace(6, 6, 1))

println("LLRU consistency tests")
for lru in (
            #TestLRU, # Can kill this cache with an nmax > ~102000
            TestBLRUs,
            TestBLRUm,
            TestBLRUl,
            TestBLRUxl,
            )
    for n in nmax
        del_all(lru)
        printf("  %s, %d items\n", lru, n)
        print("    Simple eviction: ")
        for i in 1:n
            str = get_str(i)
            lru[str] = str
            @assert lru.lst.next.data == str
            if isbounded(lru) && length(lru) >= lru.maxsize
                tailstr = get_str(i-lru.maxsize+1)
                @assert lru.lst.prev.data == tailstr
            end
        end
        println("pass")

        print("    Lookup, random access: ")
        for i in 1:n
            str = get_str(randi(n))
            if has(lru, str) # the bounded LRUs can have cache misses
                blah = lru[str]
                @assert lru.lst.next.data == blah
            end
        end
        println("pass")
    end
    del_all(lru)
end