type Interface
    name::String
    sigs::Vector
    tvar
end

subst_type(sig, tpe, tvar) = tuple(map(t -> t == tvar ? tpe : eval(t), sig.args)...)

function check_interface(iface::Interface, tpe::Type)
    hasmethods = falses(size(iface.sigs))
    for (sig, i) in enumerate(iface.sigs)
        # first put our new type in place
        args = subst_type(sig[2], tpe, iface.tvar)
        method = eval(sig[1])
        if isa(method, Function)
            # this is unfortunate--can't check the symbol table
            try
                hasmethods[i] = method_exists(method, args)
            catch err
                # this is hokey on top of unfortunate
                if isa(match(r" not defined$", err.msg), Nothing)
                    throw(err)
                end
            end
        end
    end
    hasmethods
end

function verify_interface(iface::Interface, tpe::Type)
    hasmethods = check_interface(iface, tpe)
    for sig in iface.sigs[!hasmethods]
        args = subst_type(sig[2], tpe, iface.tvar)
        println("Interface $(iface.name): Type $tpe is missing method $(sig[1])$args")
    end
    all(hasmethods)
end

macro interface(name, sigs)
    iname, tvar = if isa(name, Expr) && name.head == :curly
        (name.args[1], name.args[2])
    elseif isa(name, Symbol)
        (name, :())
    else
        error("must be a Symbol or have a single type parameter")
    end
    :($iname = Interface($(string(iname)), $sigs, $expr(:quote,tvar)))
end
