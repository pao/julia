load("lru.jl")

if ARGS[1] == "LLRU"
    const TestLRU = UnboundedLLRU{ASCIIString, ASCIIString}()
    const TestBLRUs = BoundedLLRU{ASCIIString, ASCIIString}(100)
    const TestBLRUm = BoundedLLRU{ASCIIString, ASCIIString}(1000)
    const TestBLRUl = BoundedLLRU{ASCIIString, ASCIIString}(10000)
elseif ARGS[1] == "VLRU"
    const TestLRU = UnboundedVLRU{ASCIIString, ASCIIString}()
    const TestBLRUs = BoundedVLRU{ASCIIString, ASCIIString}(100)
    const TestBLRUm = BoundedVLRU{ASCIIString, ASCIIString}(1000)
    const TestBLRUl = BoundedVLRU{ASCIIString, ASCIIString}(10000)
end

indent() = print("        ")
get_str(i) = ascii(map(x->x>>1, reinterpret(Uint8, [int32(2*i)])))


nmax = int(logspace(6, 6, 1))

println(ARGS[1])
for lru in (
            #TestLRU,
            #TestBLRUs,
            TestBLRUm,
            TestBLRUl,
            )
    for n in nmax
        srand(1234567)
        del_all(lru)
        gc()
        printf("  %s, %d items\n", lru, n/2)
        println("    Assignment:")
        indent()
        @time begin
            for i in 1:n
                str = get_str(i)
                lru[str] = str
            end
        end

        println("    Lookup, random access:")
        indent()
        @time begin
            for i in 1:n
                str = get_str(randi(n))
                if has(lru, str) # the bounded LRUs can have cache misses
                    blah = lru[str]
                end
            end
        end

        println("    Random mixed workload:")
        indent()
        @time begin
            for i in 1:n
                str = get_str(i)
                if randi(2) == 1
                    lru[str] = str
                else
                    if has(lru, str)
                        blah = lru[str]
                    end
                end
            end
        end
    end
    del_all(lru)
end