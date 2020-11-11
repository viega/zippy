import common

const
  hashBits = 16
  hashSize = 1 shl hashBits
  hashMask = hashSize - 1
  hashShift = (hashBits + minMatchLen - 1) div minMatchLen

func lz77Encode*(
  src: seq[uint8], config: CompressionConfig
): (seq[uint16], seq[int], seq[int], int) =
  assert (hashSize and hashMask) == 0
  assert hashBits <= 16 # Ensure uint16 works

  const windowSize = maxWindowSize

  var
    encoded = newSeq[uint16](src.len div 2)
    freqLitLen = newSeq[int](286)
    freqDist = newSeq[int](baseDistance.len)
    op, literalsTotal: int

  freqLitLen[256] = 1 # Alway 1 end-of-block symbol

  template addLiteral(length: int) =
    encoded[op] = length.uint16
    inc op
    inc(literalsTotal, length)

  template addLookBack(offset, length: int) =
    let
      lengthIndex = findCodeIndex(baseLengths, length.uint16)
      distIndex = findCodeIndex(baseDistance, offset.uint16)
    inc freqLitLen[lengthIndex + firstLengthCodeIndex]
    inc freqDist[distIndex]

    # The length and dist indices are packed into this value with the highest
    # bit set as a flag to indicate this starts a run.
    encoded[op] = ((lengthIndex shl 8) or distIndex) or (1 shl 15)
    encoded[op + 1] = offset.uint16
    encoded[op + 2] = length.uint16
    inc(op, 3)

  if src.len <= minMatchLen:
    for c in src:
      inc freqLitLen[c]
    encoded.setLen(1)
    addLiteral(src.len)
    return (encoded, freqLitLen, freqDist, literalsTotal)

  encoded.setLen(src.len div 2)

  var
    pos, literalLen: int
    windowPos, hash: uint16
    head = newSeq[uint16](hashSize)    # hash -> pos
    chain = newSeq[uint16](windowSize) # pos a -> pos b

  template updateHash(value: uint8) =
    hash = ((hash shl hashShift) xor value) and hashMask

  template updateChain() =
    chain[windowPos] = head[hash]
    head[hash] = windowPos

  for i in 0 ..< minMatchLen - 1:
    updateHash(src[i])

  while pos < src.len:
    if op + 3 > encoded.len: # At least 3 bytes to add a copy
      encoded.setLen(encoded.len * 2)

    if pos + minMatchLen > src.len:
      for c in src[pos ..< src.len]:
        inc freqLitLen[c]
      addLiteral(literalLen + src.len - pos)
      break

    windowPos = (pos and (windowSize - 1)).uint16

    updateHash(src[pos + minMatchLen - 1])
    updateChain()

    var
      hashPos = chain[windowPos]
      limit = min(src.len, pos + maxMatchLen)
      tries = 32
      prevOffset, longestMatchOffset, longestMatchLen: int
    for i in countdown(tries, 1):
      var offset: int
      if hashPos <= windowPos:
        offset = (windowPos - hashPos).int
      else:
        offset = (windowPos - hashPos + windowSize).int

      if offset <= 0 or offset < prevOffset:
        break

      prevOffset = offset

      let matchLen = findMatchLength(src, pos - offset, pos, limit)
      if matchLen > longestMatchLen:
        longestMatchLen = matchLen
        longestMatchOffset = offset

      if longestMatchLen >= 32 or hashPos == chain[hashPos]:
        break

      hashPos = chain[hashPos]

    if longestMatchLen > minMatchLen:
      if literalLen > 0:
        addLiteral(literalLen)
        literalLen = 0

      addLookBack(longestMatchOffset, longestMatchLen)
      for i in 1 ..< longestMatchLen:
        inc pos
        windowPos = (pos and (windowSize - 1)).uint16
        if pos + minMatchLen < src.len:
          updateHash(src[pos + minMatchLen - 1])
          updateChain()
    else:
      inc freqLitLen[src[pos]]
      inc literalLen
      if literalLen == maxLiteralLength:
        addLiteral(literalLen)
        literalLen = 0
    inc pos

  encoded.setLen(op)
  (encoded, freqLitLen, freqDist, literalsTotal)
