include common

type 
  Point = tuple[x, y: int]
  Piece = ref object
    points: HashSet[Point]
  Move = enum
    mLeft, mRight, mFall
  Board = ref object
    points: OrderedSet[Point]
    width: int
    cushion: int
    highest: int

let PIECES = @[
  Piece(points: toHashSet([(x: 2, y: 0), (x: 3, y: 0), (x: 4, y: 0), (x: 5, y: 0)])),
  Piece(points: toHashSet([(x: 3, y: 0), (x: 2, y: 1), (x: 3, y: 1), (x: 4, y: 1), (x: 3, y: 2)])),
  Piece(points: toHashSet([(x: 2, y: 0), (x: 3, y: 0), (x: 4, y: 0), (x: 4, y: 1), (x: 4, y: 2)])),
  Piece(points: toHashSet([(x: 2, y: 0), (x: 2, y: 1), (x: 2, y: 2), (x: 2, y: 3)])),
  Piece(points: toHashSet([(x: 2, y: 0), (x: 2, y: 1), (x: 3, y: 0), (x: 3, y: 1)]))
]

proc getPiece(i: int64): Piece =
  PIECES[euclMod(i, 5)]

proc getMove(moves: seq[Move], i: int): Move =
  moves[euclMod(i, moves.len)]

proc getStart(b: Board, piece: Piece): Piece =
  let start: Piece = Piece(points: initHashSet[Point]())
  for p in piece.points:
    start.points.incl((x: p.x, y: p.y+b.cushion+b.highest))
  return start

proc canMove(b: Board, piece: Piece, m: Move): bool =
  case m:
    of mLeft:
      for p in piece.points:
        if p.x == 0:
          # echo "cannot move, px == 0"
          return false
        if (x: p.x-1, y: p.y) in b.points:
          # echo "cannot move, px-1 in points"
          return false
    of mRight:
      for p in piece.points:
        if p.x == b.width - 1:
          # echo "cannot move, px == cushion-1"
          return false
        if (x: p.x+1, y: p.y) in b.points:
          # echo "cannot move, px+1 in points"
          return false
    of mFall:
      for p in piece.points:
        if p.y == 1:
          # echo "cannot move, py == 1"
          return false
        if (x: p.x, y: p.y-1) in b.points:
          # echo "cannot move, py-1 in points"
          return false
  return true

proc movePiece(piece: Piece, m: Move): Piece =
  var moved = Piece(points: initHashSet[Point]())
  case m:
    of mLeft:
      for p in piece.points:
        moved.points.incl((x: p.x-1, y: p.y))
    of mRight:
      for p in piece.points:
        moved.points.incl((x: p.x+1, y: p.y))
    of mFall:
      for p in piece.points:
        moved.points.incl((x: p.x, y: p.y-1))
  return moved

proc getHighest(b: Board, piece: Piece): int =
  result = b.highest
  for p in piece.points:
    if p.y > result:
      result = p.y

proc readMoves(filename: string): seq[Move] =
  for line in filename.lines:
    for c in line:
      case c:
        of '<': result.add(mLeft)
        of '>': result.add(mRight)
        else: 
          discard

proc part1(moves: seq[Move], totalPieces: int64): int64 =
  var tick = 0
  let board = Board(points: initOrderedSet[Point](), width: 7, highest: 0, cushion: 4)
  var pieceNum: int64 = 0
  while pieceNum <= totalPieces-1:
    if euclMod(pieceNum, 100000) == 0:
      echo "At piece ", pieceNum, " kept top ", board.points.len
    var falling = getStart(board, getPiece(pieceNum))
    while (true):
      var move = getMove(moves, tick)
      # echo falling.points
      # echo move
      inc tick
      if canMove(board, falling, move):
        falling = movePiece(falling, move)
        # echo falling.points
      if canMove(board, falling, mFall):
        falling = movePiece(falling, mFall)
        # echo falling.points
      else:
        board.highest = getHighest(board, falling)
        for p in falling.points:
          board.points.incl(p)
        if euclMod(board.points.len, 10000) == 0:
          # try to prune
          let toPrune = toSeq(board.points)
          var i: int64 = toPrune.len - 1
          var xFound = initHashSet[int]()
          while i >= 0:
            xFound.incl(toPrune[i].x)
            dec i
            if xFound.len == 7:
              break
          # echo "pruning to [", i, ", ", toPrune.len, "], now keeping ", toPrune.len - i, " at pieceNum ", pieceNum
          board.points.clear()
          if i > 0:
            # var newPoints = initOrderedSet[Point]()
            while i < toPrune.len:
              let toKeep = toPrune[i]
              board.points.incl(toKeep)
              inc i
            # board.points = newPoints
        break
    # echo board.points
    # echo board.highest
    # echo ""
    inc pieceNum
  return board.highest

proc part2(moves: seq[Move], totalPieces: int64): int64 =
  return part1(moves, totalPieces)

when isMainModule:
  let input = inputFilename(17)
  let moves = readMoves(input)

  echo "Part 1 ", part1(moves, if input.contains "sample": 2022 else: 2022)
  echo "Part 2 ", part2(moves, if input.contains "sample": 1000000000000 else: 1000000000000)
