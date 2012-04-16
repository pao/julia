abstract DLListNode{T}

type DLListItem{T} <: DLListNode{T}
    data::T
    prev::DLListNode{T}
    next::DLListNode{T}

    DLListItem(a, p, n) = new(a, p, n)
    DLListItem(a) = new(a)
end

recycle(it::DLListItem) = (it.next = it.prev = it)

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
    #startl = length(lst)
    lst.prev.next = node
    lst.prev = node
    #@assert length(lst) - startl == 1
end

function pop(lst::DLList)
    if isempty(lst)
        error("Attempted to pop from empty list.")
    end
    #startl = length(lst)
    pitem = lst.prev
    before = pitem.prev
    lst.prev = before
    before.next = lst
    recycle(pitem)
    #@assert startl - length(lst) == 1
    pitem.data
end

function enqueue{T}(lst::DLList{T}, item::T)
    nxt = DLListItem{T}(item, lst, lst.next)
    #startl = length(lst)
    lst.next.prev = nxt
    lst.next = nxt
    #@assert true#length(lst) - startl == 1
end

function shift(lst::DLList)
    if isempty(lst)
        error("Attempted to shift from empty list.")
    end
    sitem = lst.next
    ret = sitem.data
    lst.next = lst.next.next
    lst.next.prev = lst
    recycle(sitem)
    sitem.data
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
    #startl = length(lst)
    rm = itemsat(lst, idx)
    remove(rm)
    #@assert startl - length(lst) == 1
end

function del_all(lst::DLList)
    lst.next.prev = lst.next
    lst.prev.next = lst.prev
    lst.next = lst.prev = lst
    #@assert length(lst) == 0
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
    #startl = length(lst)
    before = item.prev
    after = item.next
    before.next = after
    after.prev = before
    recycle(item)
    #@assert startl - length(lst) == 1
end

function enqueue{T}(lst::DLList{T}, item::DLListItem{T})
    #startl = length(lst)
    item.prev = lst
    item.next = lst.next
    lst.next.prev = item
    lst.next = item
    #@assert length(lst) - startl == 1
    item
end

function insert{T}(lst::DLList{T}, idx::Integer, item::DLListItem{T})
    after = itemsat(lst, idx)
    before = after.prev
    item.prev = before
    item.next = after
    before.next = item
    after.prev = item
    item
end

function move_to_head{T}(lst::DLList{T}, item::DLListItem{T})
    #startl = length(lst)
    remove(lst, item)
    enqueue(lst, item)
    #@assert startl - length(lst) == 0
end
