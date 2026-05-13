import std/tables
import process/procapi as ProcApi

type InstrHandler* = proc(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int

var dispatchTable*: Table[string, InstrHandler]

proc register*(name: string, handler: InstrHandler): void =
    dispatchTable[name] = handler

proc lookup*(name: string): InstrHandler =
    dispatchTable.getOrDefault(name)
