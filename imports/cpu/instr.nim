import tables

type
    InstructionSet* = enum
        DEBUGPROCDUMP, HALT

let InstrMap* = toTable({
    "DEBUGPROCDUMP": InstructionSet.DEBUGPROCDUMP,
    "HALT": InstructionSet.HALT
})
