local rule_constants = {}


rule_constants.EVENT_EVERY_FRAME = 'every frame'

rule_constants.ACTION_RUN_CODE = 'run code'

rule_constants.EVENTS = {
    rule_constants.EVENT_EVERY_FRAME,
}

rule_constants.ACTIONS = {
    rule_constants.ACTION_RUN_CODE,
}

rule_constants.DEFAULTS = {
    enabled = true,
    event = rule_constants.EVENT_EVERY_FRAME,
    action = rule_constants.ACTION_RUN_CODE,
    description = '',
}

rule_constants.ACTION_DEFAULTS = {
    [rule_constants.ACTION_RUN_CODE] = {
        edited = nil,
        applied = '',
    },
}

rule_constants.MAX_DESCRIPTION_LENGTH = 32
                        

return rule_constants