load("dllist.jl")

abstract LRU{K,V} <: Associative

type UnboundedLRU{K,V} <: LRU{K,V}
    ht::HashTable{K,ListItem{V}}
    lst::DLList{V}

    UnboundedLRU() = new(HashTable{K, ListItem{V}}(), List{V}())
end

## LRU with eviction ##
# This actually doesn't work, because we need weak values, not weak keys
# Python has a default cache size defined as a global; should we?
const __MAXCACHE = 1024 # I totally just made that up
type BoundedLRU{K,V} <: LRU{K,V}
    ht::WeakValueHashTable # can't tighten the type here
    lst::DLList{V}
    maxsize::Integer

    BoundedLRU(m) = new(WeakValueHashTable(), List{V}(), m)
    BoundedLRU() = BoundedLRU(__MAXCACHE)
end

## collections ##

isempty(lru::LRU) = isempty(lru.lst)
numel(lru::LRU) = numel(lru.lst)
length(lru::LRU) = length(lru.lst)

## indexable ##

function ref{K}(lru::LRU{K}, key::K)
    item = lru.ht[key]
    move_to_head(lru.lst, item)
    item.data
end

function assign{K,V}(lru::LRU{K,V}, v::V, key::K)
    if has(lru, key)
        item = lru.ht[key]
        move_to_head(lru.lst, item)
        item.data = v
    else
        enqueue(lru.lst, v)
        lru.ht[key] = itemsat(lru.lst, 1)
    end
end

# Eviction
function assign{K,V}(lru::BoundedLRU{K,V}, v::V, key::K)
    invoke(assign, (LRU{K,V}, V, K), lru, v, key)
    nrm = length(lru) - lru.maxsize
    for i in 1:nrm
        pop(lru.lst)
    end
end

## associative ##

# Should this check count as an access?
has{K}(lru::LRU{K}, key::K) = has(lru.ht, key)

get{K}(lru::LRU{K}, key::K, default) = has(lru, key) ? lru[key] : default

function del{K}(lru::LRU{K}, key::K)
    remove(lru.lst, lru.ht[key])
    del(lru.ht, key)
end

function del_all(lru::LRU)
    del_all(lru.ht)
    lru.lst = List{V}()
end
