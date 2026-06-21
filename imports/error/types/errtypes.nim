const CATEGORY_CPU* = 1
const CATEGORY_FS* = 2

const CPU_NOINSTR* = 1      # Invalid instruction
const CPU_DIVBYZERO* = 2    # Division by zero
const CPU_ABSENTINSTR* = 3  # Empty instruction
const CPU_INVIDX* = 4       # Invalid index
const CPU_INVSYN* = 5       # Invalid syntax
const CPU_PRGRMEND* = 6     # Went beyond program bounds or no HALT
const CPU_OOB* = 7          # Out of bounds
const CPU_LIMEXC* = 8       # Value not in LIM_MINIMUM-LIM_MAXIMUM

const FS_NOPATH* = 1        # No such file or directory
const FS_INVCDO* = 2        # Invalid CoreDataObject or file type