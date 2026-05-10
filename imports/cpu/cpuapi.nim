import cpu/instr as VINSTR

proc tokenize*(str: string): seq[string] =
  var inGroup = false
  var cur: string
  for c in str:
    if c == '|':
      if inGroup:
        result.add(cur)
        cur.setLen(0)
        inGroup = false
      else:
        inGroup = true
    elif inGroup:
      cur.add(c)
    elif c != ' ':
      cur.add(c)
    elif cur.len > 0:
      result.add(cur)
      cur.setLen(0)
  if cur.len > 0:
    result.add(cur)

proc execute_binary*(exe: string): void =
    for instr in exe:
      var tokenized = tokenize(instr)
      