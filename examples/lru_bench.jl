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

srand(1234567)

nmax = int(logspace(1,4,4))

println(ARGS[1])
for lru in (:TestLRU, :TestBLRUs, :TestBLRUm, :TestBLRUl)
    @eval begin
        for n in nmax
            del_all($lru)
            gc()
            printf("  %s\n", $lru)
            println("    Assignment, $n items:")
            indent()
            @time begin
                for i in 1:n
                    str = get_str(i)
                    ($lru)[str] = str
                end
            end

            println("    Lookup, random access:")
            indent()
            @time begin
                for i in 1:n
                    str = get_str(randi(n))
                    if has($lru, str) # the bounded LRUs can have cache misses
                        blah = ($lru)[str]
                    end
                end
            end
        end
        del_all($lru)
    end
end