cd("../extras") do
require("suitesparse")

se33 = speye(3)
do33 = ones(3)
@test isequal(se33 \ do33, do33)

end # cd
