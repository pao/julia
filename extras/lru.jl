load("dllist.jl")

abstract LRU{K,V} <: Associative

abstract LLRU{K,V} <: LRU{K,V}

type UnboundedLLRU{K,V} <: LLRU{K,V}
    ht::HashTable{K,DLListItem{V}}
    lst::DLList{V}

    UnboundedLLRU() = new(HashTable{K, DLListItem{V}}(), DLList{V}())
end

## LRU with eviction ##
# Python has a default cache size defined as a global; should we?
const __MAXCACHE = 1024 # I totally just made that up
type BoundedLLRU{K,V} <: LLRU{K,V}
    ht::WeakValueHashTable # can't tighten the type here
    lst::DLList{V}
    maxsize::Integer

    BoundedLLRU(m) = new(WeakValueHashTable(), DLList{V}(), m)
    BoundedLLRU() = BoundedLLRU(__MAXCACHE)
end

show(lru::BoundedLLRU) = print("BoundedLLRU($(lru.maxsize))")

## collections ##

isempty(lru::LRU) = isempty(lru.lst)
numel(lru::LRU) = numel(lru.lst)
length(lru::LRU) = length(lru.lst)
has{K}(lru::LRU{K}, key::K) = has(lru.ht, key)

# Deal with weak value refs
function has{K}(lru::BoundedLLRU{K}, key::K)
    try
        item = lru.ht[key]
    catch e
        if isa(e, KeyError)
            return false
        else
            throw(e)
        end
    end
    true
end

## indexable ##

function ref{K}(lru::LLRU{K}, key::K)
    if !has(lru.ht, key)
        throw(KeyError(key))
    end
    item = lru.ht[key]
    move_to_head(lru.lst, item)
    item.data
end

function assign{K,V}(lru::LLRU{K,V}, v::V, key::K)
    local item
    try
        item = lru.ht[key]
    catch e
        if isa(e, KeyError)
            item = enqueue(lru.lst, v)
            lru.ht[key] = item
            return v
        else
            throw(e)
        end
    end
    move_to_head(lru.lst, item)
    item.data = v
end

# Eviction
function assign{K,V}(lru::BoundedLLRU{K,V}, v::V, key::K)
    invoke(assign, (LLRU{K,V}, V, K), lru, v, key)
    nrm = length(lru) - lru.maxsize
    for i in 1:nrm
        pop(lru.lst)
    end
end

## associative ##

# Should this check count as an access?
has{K}(lru::LRU{K}, key::K) = has(lru.ht, key)

get{K}(lru::LRU{K}, key::K, default) = has(lru, key) ? lru[key] : default

function del{K}(lru::LLRU{K}, key::K)
    remove(lru.lst, lru.ht[key])
    del(lru.ht, key)
end

function del_all(lru::LRU)
    del_all(lru.ht)
    del_all(lru.lst)
end

############ Vector based #############

abstract VLRU{K,V} <: LRU{K,V}

type Pair{S,T}
    a::S
    b::T
end

type UnboundedVLRU{K,V} <: VLRU{K,V}
    ht::HashTable{K,Pair{K,V}}
    lst::Vector{Pair{K,V}}

    UnboundedVLRU() = new(HashTable{K,Pair{K,V}}(), empty(Array(Pair{K,V},1)))
end

type BoundedVLRU{K,V} <: VLRU{K,V}
    ht::HashTable
    lst::Vector{Pair}
    maxsize::Int

    BoundedVLRU(m) = new(HashTable(), empty(Array(Pair,1)), m)
    BoundedVLRU() = BoundedVLRU(__MAXCACHE)
end

show(lru::BoundedVLRU) = print("BoundedVLRU($(lru.maxsize))")

## indexable ##

function locate(lst, x)
    for i = length(lst):-1:1
        if lst[i] == x
            return i
        end
    end
    error("Item not found.")
end

function ref{K}(lru::VLRU{K}, key::K)
    item = lru.ht[key]
    idx = locate(lru.lst, item)
    del(lru.lst, idx)
    push(lru.lst, item)
    item.b
end

function assign{K,V}(lru::VLRU{K,V}, v::V, key::K)
    if has(lru, key)
        item = lru.ht[key]
        idx = locate(lru.lst, item)
        item.b = v
        del(lru.lst, idx)
    else
        item = Pair(key, v)
        lru.ht[key] = item
    end
    push(lru.lst, item)
end

# Eviction
function assign{K,V}(lru::BoundedVLRU{K,V}, v::V, key::K)
    invoke(assign, (VLRU{K,V}, V, K), lru, v, key)
    nrm = length(lru) - lru.maxsize
    for i in 1:nrm
        rm = shift(lru.lst)
        del(lru.ht, rm.a)
    end
end

## associative ##

function del{K}(lru::VLRU{K}, key::K)
    item = lru.ht[key]
    idx = locate(lru.lst, item)
    del(lru.ht, key)
    del(lru.lst, idx)
end
