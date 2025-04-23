# ---- u/uX/uz/uXz - "up" functions
# for quickly hopping up directories

# use X number of 'u' or 'uX' to cd up X steps
#     u   /  u...uuuuu
#     uX  /  u1...u5
# you can also append 'z' to use zd instead of cd:
#     uz  /  uz...uuuuuz
#     uXz /  u1z...u5z

# ---- create functions via iex
1..5 |% {
    # array of u...uuuuu names
    $u =  "".PadLeft($_,"u")
    # array of u1...u5 names
    $unum =  "u$_"
    # array of strings for each number of levels up
    $d =  $u.Replace("u","../")

    # create u/uX functions
    iex "function $u { cd $d }"
    iex "function $unum { cd $d }"

    # create uz/uXz functions
    iex "function ${u}z { zd $d }"
    iex "function ${unum}z { zd $d }"
}
