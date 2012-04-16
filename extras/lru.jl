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
    if has(lru.ht, key)
        item = lru.ht[key]
        if isa(item, Nothing)
            false
        else
            true
        end
    else
        false
    end
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
    if has(lru, key)
        item = lru.ht[key]
        move_to_head(lru.lst, item)
        item.data = v
    else
        item = enqueue(lru.lst, v)
        lru.ht[key] = item
    end
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

function ref{K}(lru::VLRU{K}, key::K)
    item = lru.ht[key]
    idx = find(map(x-> x==item, lru.lst))[1]
    del(lru.lst, idx)
    enqueue(lru.lst, item)
    item.b
end

function assign{K,V}(lru::VLRU{K,V}, v::V, key::K)
    if has(lru, key)
        item = lru.ht[key]
        idx = find(map(x-> x==item, lru.lst))[1]
        item.b = v
        del(lru.lst, idx)
        enqueue(lru.lst, item)
    else
        item = Pair(key, v)
        lru.ht[key] = item
        enqueue(lru.lst, item)
    end
end

# Eviction
function assign{K,V}(lru::BoundedVLRU{K,V}, v::V, key::K)
    invoke(assign, (VLRU{K,V}, V, K), lru, v, key)
    nrm = length(lru) - lru.maxsize
    for i in 1:nrm
        rm = pop(lru.lst)
        del(lru.ht, rm.a)
    end
end

## associative ##

function del{K}(lru::VLRU{K}, key::K)
    item = lru.ht[key]
    idx = find(map(x-> x==item, lru.lst))[1]
    del(lru.ht, key)
    del(lru.lst, idx)
end
