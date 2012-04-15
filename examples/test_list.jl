load("list.jl")

head = List{Int64}()
@assert eltype(head) == Int64

append!(head, 1:3)
@assert head[:] == [1:3]

@assert 3 == pop(head)
@assert head[:] == [1; 2]

@assert 2 == pop(head)
@assert 1 == pop(head)
@assert isempty(head)

enqueue(head, 4)
@assert head[:] == [4]

enqueue(head, 5)
@assert head[:] == [5; 4]

push(head, 6)
@assert head[:] == [5; 4; 6]

insert(head, 3, 7)
@assert head[:] == [5; 4; 7; 6]

@assert 5 == shift(head)

insert(head, 1, 8)
@assert head[:] == [8; 4; 7; 6]

head = List{Int64}()
println("(4) tests should each print a line")
try
    pop(head)
catch
    println("Caught pop(empty)")
end
try
    shift(head)
catch
    println("Caught shift(empty)")
end
try
    del(head, 1)
catch
    println("Caught del(empty, 1)")
end
try
    insert(head, 2, 1)
catch
    println("Caught insert(empty, 2, 1)")
end