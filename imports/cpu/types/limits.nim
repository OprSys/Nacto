const LIM_MINIMUM* = 0 # FatalCrash if exceeded
const LIM_MAXIMUM* = 2^16 # FatalCrash if exceeded
const LIM_DGRZONETHRESHOLD* = 3
const LIM_DGRZONE* = LIM_MAXIMUM div LIM_DGRZONETHRESHOLD # used to determine if a number is getting too high