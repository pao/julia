abstract ListNode{T}

type ListItem{T} <: ListNode{T}
    data::T
    prev::ListNode{T}
    next::ListNode{T}

    ListItem(a, p, n) = new(a, p, n)
    ListItem(a) = new(a)
end
type List{T} <: ListNode{T}
    prev::ListNode{T}
    next::ListNode{T}

    List() = (l = new(); l.next = l; l.prev = l)
end

eltype{T}(::Type{List{T}}) = T
eltype{T}(lst::List{T}) = T

function show(lst::List)
    println(summary(lst))
    for item in lst
        show(item)
        print(", ")
    end
end
show(it::ListItem) = show(it.data)

## collections ##

isempty(lst::List) = isequal(lst, lst.next)
length(lst::List) = numel(lst)
numel(lst::List) = reduce((l, it) -> l+1, 0, lst)

## iterable ##

function reduce(op::Function, v0, lst::List)
    v = v0
    for dat in lst
        v = op(v, dat)
    end
    v
end
start(lst::List) = lst.next
next(lst::List, l::ListNode) = (l.data, l.next)
done(lst::List, l::ListNode) = isa(l, List)

## indexable ##

function itemsat{T,I<:Integer}(lst::List{T}, idxs::AbstractVector{I})
    if isempty(lst)
        error("Attempted to retrieve items from empty list.")
    end
    ls = Array(ListNode{T}, length(idxs))
    l = lst
    for i in 1:max(idxs)
        l = l.next
        if isa(l, List)
            error("Access past end of list.")
        end
        ls[idxs == i] = l
    end
    ls
end
itemsat{T}(lst::List{T}, idx::Integer) = itemsat(lst, [idx])[1]
itemsat{T,I<:Integer}(lst::List{T}, idxs::Ranges{I}) = itemsat(lst, [idxs])

ref(lst::List, i::Integer) = itemsat(lst, i).data
ref{I<:Integer}(lst::List, idxs::AbstractVector{I}) = map((l) -> l.data, itemsat(lst, idxs))
ref{I<:Integer}(lst::List, idxs::Ranges{I}) = map((l) -> l.data, itemsat(lst, [idxs]))

function assign(lst::List, item, idxs::Integer...)
    for elem in itemsat(lst, idxs)
        elem.data = item
    end
end
assign(lst::List, item, idx::Integer) = itemsat(lst, idx).data = item

## dequeue ##

function push{T}(lst::List{T}, item::T)
    node = ListItem{T}(item, lst.prev, lst)
    lst.prev.next = node
    lst.prev = node
end

function pop(lst::List)
    if isempty(lst)
        error("Attempted to pop from empty list.")
    end
    ret = lst.prev.data
    lst.prev = lst.prev.prev
    lst.prev.next = lst
    ret
end

function enqueue{T}(lst::List{T}, item::T)
    nxt = ListItem{T}(item, lst, lst.next)
    lst.next.prev = nxt
    lst.next = nxt
end

function shift(lst::List)
    if isempty(lst)
        error("Attempted to shift from empty list.")
    end
    ret = lst.next.data
    lst.next = lst.next.next
    lst.next.prev = lst
    ret
end

function insert{T}(lst::List{T}, idx::Integer, item::T)
    if idx == 1 #skip the lookup
        enqueue(lst, item)
    else
        insert(lst, idx, ListItem{T}(item))
    end
end

function del(lst::List, idx::Integer)
    if isempty(lst)
        error("Attempted to delete from empty list.")
    end
    rm = itemsat(lst, idx)
    remove(rm)
end

grow(lst::List, n) = nothing # doesn't make sense for this structure

function append{T}(lst::List{T}, items)
    nlst = length(lst)
    ret = Vector{T}(nlst + numel(items))
    ret = [lst[:]; items[:]]
end

function append!{T}(lst::List{T}, items)
    for item in items
        push(lst, item)
    end
end

## dangerous direct operations ##

function remove{T}(lst::List{T}, item::ListItem{T})
    before = item.prev
    after = item.next
    before.next = after
    after.next = before
end

function enqueue{T}(lst::List{T}, item::ListItem{T})
    item.prev = lst
    item.next = lst.next
    lst.next.prev = item
    lst.next = item
end

function insert{T}(lst::List{T}, idx::Integer, item::ListItem{T})
    after = itemsat(lst, idx)
    before = after.prev
    item.prev = before
    item.next = after
    before.next = item
    after.prev = item
end

function move_to_head{T}(lst::List{T}, item::ListItem{T})
    remove(lst, item)
    enqueue(lst, item)
end
