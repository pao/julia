abstract ListNode{T}

type ListItem{T} <: ListNode{T}
    prev::ListNode{T}
    next::ListNode{T}
    data::T
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
length(lst::List) = reduce((l, it) -> l+1, 0, lst)
numel(lst::List) = length(lst)

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

function itemat{T,I<:Integer}(lst::List{T}, idxs::AbstractVector{I})
    if isempty(lst)
        error("Attempted to retrieve items from empty list.")
    end
    idxs = sort(idxs) # make sure we can do this in one traversal
    ls = Array(ListNode{T}, length(idxs))
    l = lst
    for i in 1:idxs[end]
        l = l.next
        if isa(l, List)
            error("Access past end of list.")
        end
        ls[idxs == i] = l
    end
    ls
end
itemat{T}(lst::List{T}, idx::Integer) = itemat(lst, [idx])[1]

ref(lst::List, i::Integer) = itemat(lst, i)[1].data
ref{I<:Integer}(lst::List, idxs::AbstractVector{I}) = map((l) -> l.data, itemat(lst, idxs))

function assign(lst::List, item, idxs::Integer...)
    for elem in itemat(lst, idxs)
        elem.data = item
    end
end
assign(lst::List, item, idx::Integer) = itemat(lst, idx).data = item

## dequeue ##

function push{T}(lst::List{T}, item::T)
    node = ListItem(lst.prev, lst, item)
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
    nxt = ListItem(lst, lst.next, item)
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
    after = !isempty(lst) ? itemat(lst, idx) : lst
    before = after.prev
    ins = ListItem(before, after, item)
    before.next = ins
    after.prev = ins
end

function del(lst::List, idx::Integer)
    if isempty(lst)
        error("Attempted to delete from empty list.")
    end
    rm = itemat(lst, idx)
    before = rm.prev
    after = rm.next
    before.next = after
    after.prev = before
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
