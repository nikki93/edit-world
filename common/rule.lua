local rule = {}


rule.DEFAULTS = {
    enabled = true,
    condition = 'think',
    action = 'code',
    description = '',
}

rule.ACTION_DEFAULTS = {
    code = {
        edited = nil,
        applied = '',
    },
}

rule.DESCRIPTION_DEFAULTS = {
    code = 'run_code',
}


function rule.getDescription(rule)
    return rule.description == '' and rule.DESCRIPTION_DEFAULTS[rule.action] or rule.description
end


return rule