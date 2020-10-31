import strformat, zippy

const zs = [
  "randtest1.z",
  "randtest2.z",
  "randtest3.z",
  "rfctest1.z",
  "rfctest2.z",
  "rfctest3.z",
  "tor-list.z",
  "zerotest1.z",
  "zerotest2.z",
  "zerotest3.z",
]

const golds = [
  "randtest1.gold",
  "randtest2.gold",
  "randtest3.gold",
  "rfctest1.gold",
  "rfctest2.gold",
  "rfctest3.gold",
  "tor-list.gold",
  "zerotest1.gold",
  "zerotest2.gold",
  "zerotest3.gold",
]

# for i, file in zs:
#   echo file
#   let
#     z = readFile(&"tests/data/{file}")
#     gold = readFile(&"tests/data/{golds[i]}")
#   assert uncompress(z) == gold

let compressed = compress(readFile("tests/data/randtest1.gold"))
let uncompressed = uncompress(compressed)

echo compress("A_DEAD_DAD_CEDED_A_BAD_BABE_A_BEADED_ABACA_BED")

# import random, fidget/opengl/perf, algorithm

# include zippy/compress

# var
#   a: seq[Node]
#   b: seq[Node]
# for i in 0 ..< 100000:
#   let n = Node()
#   n.weight = rand(high(uint16).int).uint16
#   a.add(n)
#   b.add(n)


# timeIt "quicksort":
#   quickSort(a)

# timeIt "sort":
#   sort(b)

# var prev: Node
# for _, n in a:
#   if prev != nil:
#     doAssert n.weight >= prev.weight
#   prev = n
