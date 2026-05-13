import std/strutils
import std/strformat

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import cpu/errors/all as BINERRC
export BINERRC
export VINSTRS

proc FatalCrash*(errtype: typedesc, reason: string, procobj: ProcApi.ProcTypes.ProcessObject): void =
    echo(fmt"Fatal exception. {procobj.Name}:{procobj.Id} has experienced a crash that Nacto cannot recover.{'\n'}Nacto has crashed, with reason: {reason}{'\n'}{$errtype}")
    return

proc EvaluateInstr(base: string, args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): void =
    var ret: int = -1

    let handler = VINSTRS.vinstr_registry.lookup(base)
    if handler != nil:
        ret = handler(args, procobj)
    else:
        raise newException(BINERRC.InvalidInstruction, base)
    return

proc tokenizeInstr*(str: string): seq[string] =
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

proc MakeProcess(procobj: ProcApi.ProcTypes.ProcessObject, exe: string): int =
    let instructions = exe.split('\n')

    while procobj.ProcessState.IsRunning:
        let pc = procobj.ProcessState.ProgramCounter
        if pc >= instructions.len:
            raise newException(BINERRC.AttemptedExecuteNull, "attempted to execute null instruction") # this makes it so that a HALT instruction is required

        let instr = instructions[pc]
        if instr.len == 0:
            raise newException(BINERRC.AttemptedExecuteNull, "attempted to execute null instruction") # this makes it so that a HALT instruction is required

        
        let tokenized = tokenizeInstr(instr)

        if tokenized.len == 0:
            continue

        let base = tokenized[0]
        var args = tokenized[1..^1]
        EvaluateInstr(base, args, procobj)
        inc procobj.ProcessState.ProgramCounter
    return 0 # will be used as a proper error system soon enough

proc ExecuteBinary*(name: string, origin: string, exe: string): int =
    var process = ProcApi.CreateProcess(name, origin)

    process.ProcessState.RunningProcess =
      proc(procobj: ProcApi.ProcessObject): int =
        try:
            return MakeProcess(procobj, exe)
        except BINERRC.AttemptedExecuteNull as e:
            FatalCrash(BINERRC.AttemptedExecuteNull, e.msg, procobj)
            return -1 # will be used as a proper error system soon enough

    
    process.ProcessState.IsRunning = true
    ProcApi.LinkProcess(process)
    let ret = process.ProcessState.RunningProcess(process)
    return ret

