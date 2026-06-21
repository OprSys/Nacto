const HIGH* = 32
const LOW* = 512

type
    RandomAccessMemory* = ref object
        Reg*: array[HIGH, array[LOW, int]]

var internal_shared_state = RandomAccessMemory()
var RAM* = internal_shared_state

import error/errorapi as ErrorApi

proc GetAddr*(highslot: int, lowslot: int): int =
    if highslot < 0 or highslot >= HIGH:
        ErrorApi.ThrowError(ErrorApi.newerr("RAM high-level slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    if lowslot < 0 or lowslot >= LOW:
        ErrorApi.ThrowError(ErrorApi.newerr("RAM low-level slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    return RAM.Reg[highslot][lowslot]

proc ReadRange*(highslot: int, low_start: int, low_end: int): seq[int] =
    result = newSeq[int]()
    for lowslot in low_start .. low_end:
        result.add(GetAddr(highslot, lowslot))

proc SetAddr*(highslot: int, lowslot: int, value: int): void =
    if highslot < 0 or highslot >= HIGH:
        ErrorApi.ThrowError(ErrorApi.newerr("RAM high-level slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    if lowslot < 0 or lowslot >= LOW:
        ErrorApi.ThrowError(ErrorApi.newerr("RAM low-level slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    RAM.Reg[highslot][lowslot] = value