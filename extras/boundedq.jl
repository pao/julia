# Supply (parts of) a dequeue interface with boundedness

type BoundedQ{T} <: AbstractArray
    q::Array{T}
    maxSize::Int
    _ptr::Int
    _len::Int
end
function BoundedQ(T::Type, maxSize::Int, rowSize::Int, _ptr::Int, _len::Int)
    if !(maxSize >= 0);  error("BoundedQ: maxSize must be non-negative"); end
    BoundedQ(Array(T, maxSize, rowSize), maxSize, _ptr, _len)
end
BoundedQ(T::Type, maxSize::Integer) = BoundedQ(T, int(maxSize), 1, 1, 0)
BoundedQ(T::Type, maxSize::Integer, rowSize::Integer) = BoundedQ(T, int(maxSize), int(rowSize), 1, 0)
BoundedQ(maxSize::Integer) = BoundedQ(Any, int(maxSize))

# These will make life easier
wrap(bq::BoundedQ, loc::Integer) = mod(loc - 1, bq.maxSize) + 1
wrap(bq::BoundedQ, locs::AbstractArray) = [wrap(bq, l) | l in locs]
length(bq::BoundedQ) = bq._len
function size(bq::BoundedQ)
    if length(size(bq.q)) == 1
        return length(bq)
    else
        return tuple(append(length(bq), size(bq.q)[2:end])...)
    end
end
size(bq::BoundedQ, dim::Integer) = size(bq)[dim]

# Adding elements

function push(bq::BoundedQ, item)
    bq.q[wrap(bq, bq._ptr + bq._len),:] = item
    if bq._len < bq.maxSize
        bq._len += 1
    else
        bq._ptr = wrap(bq, bq._ptr + 1)
    end
end

function enqueue(bq::BoundedQ, item)
    bq.q[wrap(bq, bq._ptr - 1),:] = item
    if length(bq) < bq.maxSize
        bq._len += 1
    end
    bq._ptr = wrap(bq, bq._ptr - 1)
end

function append!(bq::BoundedQ, items::AbstractVector)
    if length(items) >= bq.maxSize
        bq.q = items[end-bq.maxSize+1:end]
        bq._ptr = 1
        bq._len = bq.maxSize
    else
        for item in items
            push(bq, item)
        end
    end
end

# Removing elements

function pop(bq::BoundedQ)
    if length(bq) <= 0; error("Cannot pop from empty queue."); end
    ret = bq.q[wrap(bq, bq._ptr + bq._len - 1),:]
    bq._len -= 1
    return ret
end

function shift(bq::BoundedQ)
    if length(bq) <= 0; error("Cannot shift from empty queue."); end
    ret = bq.q[bq._ptr,:]
    bq._len -= 1
    bq._ptr = wrap(bq, bq._ptr + 1)
    return ret
end

# Reference

ref(bq::BoundedQ, args...) = ref(bq.q, wrap(bq, args[1] + bq._ptr - 1), args[2:end]...)

# No implementations yet for start(), next(), done()
# No implementations for append(), del(), insert(), grow()
