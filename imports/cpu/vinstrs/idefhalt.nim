import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if procobj.ProcessState.ReturnBack.len == 0:
        raise newException(BINERRC.InvalidInstruction, "unknown instruction \"IEND\"")
    let retAddr = procobj.ProcessState.ReturnBack.pop()
    discard procobj.ProcessState.CurrentCustomInstr.pop()
    discard vinstr_registry.lookup("JMP")(@[$retAddr], procobj)
    return 0

register("IEND", execute)