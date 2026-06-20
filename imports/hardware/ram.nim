import cpu/errors/all as BINERRC

const HIGH* = 32
const LOW* = 512

type
    RandomAccessMemory* = ref object
        Reg*: array[HIGH, array[LOW, int]]

var internal_shared_state = RandomAccessMemory()
var RAM* = internal_shared_state

proc GetAddr*(highslot: int, lowslot: int): int =
    if highslot < 0 or highslot >= HIGH:
        let HIGHl = HIGH - 1
        raise newException(BINERRC.OutOfBounds, "RAM high-level slot " & $highslot & " is not in the range of 0 to " & $HIGHl)
    if lowslot < 0 or lowslot >= LOW:
        let LOWl = LOW - 1
        raise newException(BINERRC.OutOfBounds, "RAM low-level slot " & $lowslot & " is not in the range of 0 to " & $LOWl)
    return RAM.Reg[highslot][lowslot]

proc ReadRange*(highslot: int, low_start: int, low_end: int): seq[int] =
    result = newSeq[int]()
    for lowslot in low_start .. low_end:
        result.add(GetAddr(highslot, lowslot))

proc SetAddr*(highslot: int, lowslot: int, value: int): void =
    if highslot < 0 or highslot >= HIGH:
        let HIGHl = HIGH - 1
        raise newException(BINERRC.OutOfBounds, "RAM high-level slot " & $highslot & " is not in the range of 0 to " & $HIGHl)
    if lowslot < 0 or lowslot >= LOW:
        let LOWl = LOW - 1
        raise newException(BINERRC.OutOfBounds, "RAM low-level slot " & $lowslot & " is not in the range of 0 to " & $LOWl)
    RAM.Reg[highslot][lowslot] = value