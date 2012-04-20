type Signature
    method::Symbol
    args
end

type Interface
    name::String
    sigs::Vector{Signature}
end

function check_interface(iface::Interface, tpe::Type)
    hasmethods = falses(size(iface.sigs))
    for (sig, i) in enumerate(iface.sigs)
        # this is unfortunate--can't check the symbol table
        try
            hasmethods[i] = method_exists(eval(sig.method), tuple(tpe, sig.args...))
        catch err
            # this is hokey on top of unfortunate
            if isa(match(r" not defined$", err.msg), Nothing)
                throw(err)
            end
        end
    end
    hasmethods
end

function verify_interface(iface::Interface, tpe::Type)
    hasmethods = check_interface(iface, tpe)
    for sig in iface.sigs[!hasmethods]
        args = tuple(tpe, sig.args...)
        println("Interface $(iface.name): Type $tpe is missing method $(sig.method) with argument types $args")
    end
    all(hasmethods)
end

macro interface(name, sigs)
    :($name = Interface($(string(name)), $sigs))
end