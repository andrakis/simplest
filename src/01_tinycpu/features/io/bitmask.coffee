# Bitmask feature for TinyCPU
#
# It has the following features:
#   bitmask_mask
#   bitmask_operator
#   bitmask_value
#   bitmask_result
# To use it,
#   select your mask:
#     add abs0, 0x010101, BITMASK_MASK
#   select operator:
#     add abs0, BITMASK_OP_XOR, BITMASK_OP
#   set value:
#     add abs0, 0x001001, BITMASK_VALUE
#   get result:
#     add BITMASK_RESULT, 0, r1

feature = require('features/feature')
dma = require('features/dma')
{Buffer} = require('features/buffer')
{vlog} = require('verbosity')
{decSymbol} = require('symbols')

DMA = dma[feature.FEATURE_CLASS]

FEATURE_BITMASK = decSymbol 'FEATURE_BITMASK', 'bitmask'

# Memory ranges
BITMASK_MASK     = decSymbol 'BITMASK_MASK', -20
BITMASK_OP       = decSymbol 'BITMASK_OP', -21
BITMASK_VALUE    = decSymbol 'BITMASK_VALUE', -22
BITMASK_RESULT   = decSymbol 'BITMASK_RESULT', -23
BITMASK_RANGE    = decSymbol 'BITMASK_RANGE', [-20, -23]

BITMASK_OP_NONE  = decSymbol 'BITMASK_OP_NONE', 0
BITMASK_OP_OR    = decSymbol 'BITMASK_OP_OR', 1
BITMASK_OP_AND   = decSymbol 'BITMASK_OP_AND', 2
BITMASK_OP_NOT   = decSymbol 'BITMASK_OP_NOT', 3
BITMASK_OP_XOR   = decSymbol 'BITMASK_OP_XOR', 10
BITMASK_OP_SHLEFT= decSymbol 'BITMASK_OP_SHLEFT', 30
BITMASK_OP_SHRIGHT=decSymbol 'BITMASK_OP_SHRIGHT', 40

class Bitmask extends DMA
	constructor: (flush_callback) ->
		@bitmask_mask   = 0
		@bitmask_op     = BITMASK_OP_NONE
		@bitmask_value  = 0
		@bitmask_result = 0
		super
			name: "bitmask"
			rangeStart: BITMASK_RANGE[0]
			rangeEnd: BITMASK_RANGE[1]
	
	recalculate: () ->
		mask = @bitmask_mask
		value = @bitmask_value
		@bitmask_result = switch @bitmask_op
			when BITMASK_OP_NONE    then 0
			when BITMASK_OP_OR      then value | mask
			when BITMASK_OP_AND     then value & mask
			when BITMASK_OP_NOT     then ~value
			when BITMASK_OP_XOR     then value ^ mask
			when BITMASK_OP_SHLEFT  then value << mask
			when BITMASK_OP_SHRIGHT then value >> mask
	
	dma_read: (loc, cpu) ->
		result = switch loc
			when BITMASK_MASK       then @bitmask_mask
			when BITMASK_OP         then @bitmask_op
			when BITMASK_VALUE      then @bitmask_value
			when BITMASK_RESULT     then @bitmask_result
		vlog(70, "bitmask.dma_read(", loc, ")")
		result
	
	dma_write: (loc, value, cpu) ->
		result = switch loc
			when BITMASK_MASK       then @bitmask_mask = value
			when BITMASK_OP         then @bitmask_op   = value
			when BITMASK_VALUE      then @bitmask_value = value
			when BITMASK_RESULT     then 0  # Not supported
		@recalculate()
		vlog(70, "bitmask.dma_write(", loc, ",", value, ")")
		result
	
decSymbol 'Bitmask', Bitmask

exports = module.exports =
	BITMASK_MASK: BITMASK_MASK
	BITMASK_OP: BITMASK_OP
	BITMASK_VALUE: BITMASK_VALUE
	BITMASK_RESULT: BITMASK_RESULT
	BITMASK_RANGE: BITMASK_RANGE
	BITMASK_OP_NONE: BITMASK_OP_NONE
	BITMASK_OP_OR: BITMASK_OP_OR
	BITMASK_OP_AND: BITMASK_OP_AND
	BITMASK_OP_NOT: BITMASK_OP_NOT
	BITMASK_OP_XOR: BITMASK_OP_XOR
	BITMASK_OP_SHLEFT: BITMASK_OP_SHLEFT
	BITMASK_OP_SHRIGHT: BITMASK_OP_SHRIGHT
	Bitmask: Bitmask
exports[feature.FEATURE_NAME] = FEATURE_BITMASK
exports[feature.FEATURE_CLASS] = Bitmask

decSymbol 'Bitmask.exports', exports
