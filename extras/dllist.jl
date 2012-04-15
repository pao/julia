abstract DLListNode{T}

type DLListItem{T} <: DLListNode{T}
    data::T
    prev::DLListNode{T}
    next::DLListNode{T}

    DLListItem(a, p, n) = new(a, p, n)
    DLListItem(a) = new(a)
end
type DLList{T} <: DLListNode{T}
    prev::DLListNode{T}
    next::DLListNode{T}

    DLList() = (l = new(); l.next = l; l.prev = l)
end

eltype{T}(::Type{DLList{T}}) = T
eltype{T}(lst::DLList{T}) = T

function show(lst::DLList)
    println(summary(lst))
    for item in lst
        show(item)
        print(", ")
    end
end
show(it::DLListItem) = show(it.data)

## collections ##

isempty(lst::DLList) = isequal(lst, lst.next)
length(lst::DLList) = numel(lst)
numel(lst::DLList) = reduce((l, it) -> l+1, 0, lst)

## iterable ##

start(lst::DLList) = lst.next
next(lst::DLList, l::DLListNode) = (l.data, l.next)
done(lst::DLList, l::DLListNode) = isa(l, DLList)

## indexable ##

function itemsat{T,I<:Integer}(lst::DLList{T}, idxs::AbstractVector{I})
    if isempty(lst)
        error("Attempted to retrieve items from empty list.")
    end
    ls = Array(DLListNode{T}, length(idxs))
    l = lst
    for i in 1:max(idxs)
        l = l.next
        if isa(l, DLList)
            error("Access past end of list.")
        end
        ls[idxs == i] = l
    end
    ls
end
itemsat{T}(lst::DLList{T}, idx::Integer) = itemsat(lst, [idx])[1]
itemsat{T,I<:Integer}(lst::DLList{T}, idxs::Ranges{I}) = itemsat(lst, [idxs])

ref(lst::DLList, i::Integer) = itemsat(lst, i).data
ref{I<:Integer}(lst::DLList, idxs::AbstractVector{I}) = map((l) -> l.data, itemsat(lst, idxs))
ref{I<:Integer}(lst::DLList, idxs::Ranges{I}) = map((l) -> l.data, itemsat(lst, [idxs]))

function assign(lst::DLList, item, idxs::Integer...)
    for elem in itemsat(lst, idxs)
        elem.data = item
    end
end
assign(lst::DLList, item, idx::Integer) = itemsat(lst, idx).data = item

## dequeue ##

function push{T}(lst::DLList{T}, item::T)
    node = DLListItem{T}(item, lst.prev, lst)
    lst.prev.next = node
    lst.prev = node
end

function pop(lst::DLList)
    if isempty(lst)
        error("Attempted to pop from empty list.")
    end
    ret = lst.prev.data
    lst.prev = lst.prev.prev
    lst.prev.next = lst
    ret
end

function enqueue{T}(lst::DLList{T}, item::T)
    nxt = DLListItem{T}(item, lst, lst.next)
    lst.next.prev = nxt
    lst.next = nxt
end

function shift(lst::DLList)
    if isempty(lst)
        error("Attempted to shift from empty list.")
    end
    ret = lst.next.data
    lst.next = lst.next.next
    lst.next.prev = lst
    ret
end

function insert{T}(lst::DLList{T}, idx::Integer, item::T)
    if idx == 1 #skip the lookup
        enqueue(lst, item)
    else
        insert(lst, idx, DLListItem{T}(item))
    end
end

function del(lst::DLList, idx::Integer)
    if isempty(lst)
        error("Attempted to delete from empty list.")
    end
    rm = itemsat(lst, idx)
    remove(rm)
end

grow(lst::DLList, n) = nothing # doesn't make sense for this structure

function append{T}(lst::DLList{T}, items)
    nlst = length(lst)
    ret = Vector{T}(nlst + numel(items))
    ret = [lst[:]; items[:]]
end

function append!{T}(lst::DLList{T}, items)
    for item in items
        push(lst, item)
    end
end

## dangerous direct operations ##

function remove{T}(lst::DLList{T}, item::DLListItem{T})
    before = item.prev
    after = item.next
    before.next = after
    after.prev = before
end

function enqueue{T}(lst::DLList{T}, item::DLListItem{T})
    item.prev = lst
    item.next = lst.next
    lst.next.prev = item
    lst.next = item
end

function insert{T}(lst::DLList{T}, idx::Integer, item::DLListItem{T})
    after = itemsat(lst, idx)
    before = after.prev
    item.prev = before
    item.next = after
    before.next = item
    after.prev = item
end

function move_to_head{T}(lst::DLList{T}, item::DLListItem{T})
    remove(lst, item)
    enqueue(lst, item)
end
