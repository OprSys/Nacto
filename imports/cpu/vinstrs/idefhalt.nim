import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if procobj.ProcessState.ReturnBack == 0:
        raise newException(BINERRC.InvalidInstruction, "unknown instruction \"IEND\"")
    procobj.ProcessState.CurrentCustomInstr = nil
    discard vinstr_registry.lookup("JMP")(@[$procobj.ProcessState.ReturnBack], procobj)
    return 0

register("IEND", execute)