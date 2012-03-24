# Supply (parts of) a dequeue interface with boundedness

type BoundedQ{T}
    q::Vector{T}
    maxSize::Integer
end

# These will make life easier
length(bq::BoundedQ) = length(bq.q)
ref(bq::BoundedQ, args...) = ref(bq.q, args...)
start(bq::BoundedQ) = start(bq.q)
next(bq::BoundedQ, i) = next(bq.q, i)
done(bq::BoundedQ, i) = done(bq.q, i)
map(F, bq::BoundedQ) = map(F, bq.q)

function push(bq::BoundedQ, item)
    if length(bq) + 1 > bq.maxSize
        shift(bq)
    end
    push(bq.q, item)
end

function enqueue(bq::BoundedQ, item)
    if length(bq) + 1 > bq.maxSize
        pop(bq)
    end
    enqueue(bq.q, item)
end

# Ranges don't seem to work here for some reason...thought they were AbstractVector?
function append!(bq::BoundedQ, items::AbstractVector)
    for i in 1:((length(bq) + length(items)) - bq.maxSize)
        shift(bq)
    end
    append!(bq.q, items)
end

# Removing elements is no problem
pop(bq::BoundedQ) = pop(bq.q)
shift(bq::BoundedQ) = shift(bq.q)
del(bq::BoundedQ, index) = del(bq.q, index)
# As is the pure append
append(bq::BoundedQ, items) = append(bq.q, items)

# No implementations for insert(), grow()