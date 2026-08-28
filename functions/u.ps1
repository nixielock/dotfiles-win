# ---- u/uX/uz/uXz - "up" functions
# for quickly hopping up directories

# use X number of 'u' or 'uX' to cd up X steps
#     u   /  u...uuuu
#     uX  /  u1...u4
# you can also append 'z' to use zd instead of cd:
#     uz  /  uz...uuuuz
#     uXz /  u1z...u4z

# ---- create functions via iex
# foreach ($ i in 1..4) {
#     # array of u...uuuu names
#     $u =  "".PadLeft($u,"u")
#     # array of u1...u4 names
#     $unum =  "u$i"
#     # array of strings for each number of levels up
#     $d =  $u -replace "u", "../"

#     # create u/uX functions
#     iex "function $u { cd $d }"
#     iex "function $unum { cd $d }"

#     # create uz/uXz functions
#     iex "function ${u}z { zd $d }"
#     iex "function ${unum}z { zd $d }"
# }

# ---- create functions manually to speed up sourcing
# only bothering with 3 levels of each tbh

function u { cd ".." }
function uu { cd "..\.." }
function uuu { cd "..\..\.." }

function uz { zd ".." }
function uuz { zd "..\.." }
function uuuz { zd "..\..\.." }
