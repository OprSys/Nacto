# All instructions known at compile-time.

import cpu/vinstr_registry
export vinstr_registry

import cpu/vinstrs/debugprocdump
import cpu/vinstrs/halt
import cpu/vinstrs/setval
import cpu/vinstrs/addi
import cpu/vinstrs/subt
import cpu/vinstrs/mult
import cpu/vinstrs/divi
import cpu/vinstrs/jmp
import cpu/vinstrs/jz
import cpu/vinstrs/jnz
import cpu/vinstrs/jeq
import cpu/vinstrs/store
import cpu/vinstrs/debugramdump
import cpu/vinstrs/load
import cpu/vinstrs/syscall
import cpu/vinstrs/includee
import cpu/vinstrs/idef
import cpu/vinstrs/idefhalt
import cpu/vinstrs/icall
import cpu/vinstrs/nothing
import cpu/vinstrs/debugvmregdump