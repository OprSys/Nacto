import process/procapi as ProcApi
import cpu/vinstr_registry

const SYSC_PRINT* = 1

import hardware/ram as RAM
import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS
import cpu/types/ascii as ASCII

proc PRINT(highslot: int, lowslot: int): int =
    let val = RAM.GetAddr(highslot, lowslot)
    let character = ASCII.ToChar(val)
    stdout.write(character)
    return 0

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let syscall_number = procobj.ProcessState.Vm[0]
    let arg1 = procobj.ProcessState.Vm[1]
    let arg2 = procobj.ProcessState.Vm[2]
    let arg3 = procobj.ProcessState.Vm[3]

    case syscall_number
    of SYSC_PRINT:
        return PRINT(arg1, arg2)
    else:
        discard
    return 0

register("SYSCALL", execute)