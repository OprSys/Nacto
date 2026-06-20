import std/strutils
import std/strformat

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import cpu/errors/all as BINERRC
import fs/errors/all as FSERRC
export BINERRC
export VINSTRS

# Debug, used for development. Should not be used in final builds.
const DEBUG_MODE = false
# Verbose debug. Requires DEBUG_MODE to work.
const DEBUG_VERBOSE = false

proc trace(err: ref CatchableError, procobj: ProcApi.ProcTypes.ProcessObject, isFatal: bool): void =
    var groupName: string
    var errCode: string
    if err of BINERRC.BinaryError:
        groupName = "BinaryError"
        errCode = "(BINERRC)"
    elif err of FSERRC.FSError:
        groupName = "FSError"
        errCode = "(FSERRC)"
    else:
        groupName = "Error"
        errCode = "(UNKERRC)"
    let crashType = if isFatal: "FatalCrash" else: "Error"
    let article = if isFatal: "A fatal crash" else: "An error"
    let suspectedLine = if procobj.ProcessState.ProgramCounter >= procobj.ProcessState.RunningProcessString.len: "<eof>" else: procobj.ProcessState.RunningProcessString[procobj.ProcessState.ProgramCounter]
    echo(fmt"{article} has been triggered.{'\n'}{crashType} Trace{'\n'}{'\n'}{'\n'}General{'\n'}Occured at: {suspectedLine}{'\n'}Crash reason: {err.msg}{'\n'}Crash type: {errCode} {groupName}.{err.name}{'\n'}{'\n'}Program{'\n'}Name: {procobj.Name}{'\n'}Id: {procobj.Id}{'\n'}ProgramCounter: {$procobj.ProcessState.ProgramCounter}")

proc ResolveOperand(token: string, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if token.len >= 2 and token[0] == 'x':
        let regNum = parseInt(token[1..^1])

        if regNum < 0 or regNum >= ProcApi.ProcTypes.VM_SIZE:
            raise newException(BINERRC.OutOfBounds, "exceeded confined space of CPU VM array")

        return $procobj.ProcessState.Vm[regNum]

    return token

proc EvaluateInstr(base: string, args: var seq[string], procobj: ProcApi.ProcTypes.ProcessObject): void =
    var ret: int = -1

    if args.len > 0:
        for i in 0..<args.len:
            args[i] = ResolveOperand(args[i], procobj)

    let handler = VINSTRS.vinstr_registry.lookup(base)
    if handler != nil:
        ret = handler(args, procobj)
    else:
        raise newException(BINERRC.InvalidInstruction, "unknown instruction \"" & base & "\"")
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
    if DEBUG_MODE and DEBUG_VERBOSE:
        echo("The CPU has been invoked.")
        echo("Program \"" & procobj.Name & "\", ID \"" & $(procobj.Id) & "\".")
    let instructions = exe.split('\n')
    if DEBUG_MODE:
        echo("Instructions to run: " & $(instructions.len))

    procobj.ProcessState.RunningProcessString = instructions

    while procobj.ProcessState.IsRunning:
        let pc = procobj.ProcessState.ProgramCounter
        if pc >= procobj.ProcessState.RunningProcessString.len:
            let error = newException(BINERRC.AttemptedExecuteNull, "went beyond program bounds")
            trace(error, procobj, true)
            procobj.ProcessState.IsRunning = false
            break

        let instr = procobj.ProcessState.RunningProcessString[pc]
        if DEBUG_MODE:
            echo("instr = " & instr)
            echo("pc = " & $pc)

        if instr.len == 0:
            let error = newException(BINERRC.ImplicitAbsentInstruction, "encountered an empty line")
            trace(error, procobj, true)
            procobj.ProcessState.IsRunning = false
            break

        
        let tokenized = tokenizeInstr(instr)

        if tokenized.len == 0:
            continue

        let base = tokenized[0]
        var args = tokenized[1..^1]

        if DEBUG_MODE and DEBUG_VERBOSE:
            echo("Instruction RunningProcessString[" & $pc & "] tokenized.")
            echo("tokenized = " & $tokenized)
            echo("base = " & base)
            echo("args = " & $args)

        let cur = if procobj.ProcessState.CurrentCustomInstr.len > 0: procobj.ProcessState.CurrentCustomInstr[^1] else: nil
        if cur != nil:
            for i in 0..<args.len:
                if args[i].len > 1 and args[i][0] == '$':
                    let argName = args[i][1..^1]
                    for argDef in cur.Arguments:
                        if argDef.Name == argName:
                            args[i] = $argDef.Value
                            break

        let prevPc = procobj.ProcessState.ProgramCounter
        let prevLen = procobj.ProcessState.RunningProcessString.len
        if DEBUG_MODE and DEBUG_VERBOSE:
            echo("prevPc, prevLen = " & $prevPc & ", " & $prevLen)
        try:
            if DEBUG_MODE and DEBUG_VERBOSE:
                echo("Executing instruction \"" & base & "\"...")
            EvaluateInstr(base, args, procobj)
        except BINERRC.BinaryError as e:
            if DEBUG_MODE:
                trace(e, procobj, true)
            procobj.ProcessState.IsRunning = false
        except FSERRC.FSError as e:
            if DEBUG_MODE:
                trace(e, procobj, e.IsFatal)
            if e.IsFatal:
                procobj.ProcessState.IsRunning = false

        if procobj.ProcessState.ProgramCounter == prevPc:
            if procobj.ProcessState.RunningProcessString.len == prevLen:
                inc procobj.ProcessState.ProgramCounter
    return 0

proc ExecuteBinary*(name: string, origin: string, exe: string): int =
    var process = ProcApi.CreateProcess(name, origin)

    process.ProcessState.RunningProcess =
      proc(procobj: ProcApi.ProcessObject): int =
            return MakeProcess(procobj, exe)


    process.ProcessState.IsRunning = true
    ProcApi.LinkProcess(process)
    let ret = process.ProcessState.RunningProcess(process)
    return ret

