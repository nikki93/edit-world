local node_base = require 'common.node_base'
local ui_utils = require 'common.ui_utils'
local ui = castle.ui
local code_loader = require 'common.code_loader'
local table_utils = require 'common.table_utils'
local lib = require 'common.lib'
local rule_constants = require 'common.rule_constants'


local node_group = {}


node_group.DEFAULTS = {
    rules = {},
}


node_group.proxyMethods = setmetatable({}, { __index = node_base.proxyMethods })
node_group.proxyMetatable = { __index = node_group.proxyMethods }


--
-- Draw
--

function node_group.proxyMethods:draw(transform)
end


--
-- Rules
--

local function formatRuleTitle(rule)
    if rule.description == '' then
        return 'on ' .. rule.event .. ', ' .. rule.action
    else
        return rule.description
    end
end

function node_group.proxyMethods:runRules(event, params)
    local node = self.__node
    local rules = node.group.rules

    local ruleHolders = {}
    for ruleIndex = 1, #rules do
        local rule = rules[ruleIndex]
        if rule.enabled and rule.event == event then
            local code

            if rule.action == rule_constants.ACTION_RUN_CODE then
                code = rule[rule_constants.ACTION_RUN_CODE].applied
            end

            local compiledHolder = code_loader.compile(code, formatRuleTitle(rule))
            ruleHolders[ruleIndex] = compiledHolder

            local err = compiledHolder.err
            if compiledHolder.compiled then
                local succeeded
                succeeded, err = pcall(compiledHolder.compiled, self, params)
            end
            if err then
                debug_utils.throttledPrint(err, err)
            end
        end
    end
    self.__ruleHolders = ruleHolders
end


--
-- UI
--

function node_group.proxyMethods:uiRulesPart(props)
    local node = self.__node
    local rules = node.group.rules

    -- Add
    if ui.button('add rule') then
        props.validateChange(function()
            local newRuleData = table_utils.clone(rule_constants.DEFAULTS)
            newRuleData.id = lib.uuid()
            newRuleData[newRuleData.action] = rule_constants.ACTION_DEFAULTS[newRuleData.action]
            rules[#rules + 1] = newRuleData
            self.__ruleSectionOpenIndex = #rules
        end)()
    end

    local ruleIndicesToRemove = {}

    for ruleIndex = 1, #rules do
        local rule = rules[ruleIndex]

        local sectionOpened = ui.section(formatRuleTitle(rule), {
            id = rule.id,
            open = self.__ruleSectionOpenIndex == ruleIndex,
        }, function()
            -- Event, action
            ui_utils.row('event-action', function()
                ui.dropdown('event', rule.event, rule_constants.EVENTS, {
                    onChange = props.validateChange(function(newEvent)
                        rule.event = newEvent
                    end),
                })
            end, function()
                ui.dropdown('action', rule.action, rule_constants.ACTIONS, {
                    onChange = props.validateChange(function(newAction)
                        rule[rule.action] = nil
                        rule.action = newAction
                        rule[rule.action] = rule_constants.ACTION_DEFAULTS[rule.action]
                    end),
                })
            end)

            -- Enabled, description
            ui.box('enabled-description', { flexDirection = 'row', alignItems = 'center' }, function()
                ui.box('enabled', { width = 104, justifyContent = 'center' }, function()
                    ui.toggle('rule off', 'rule on', rule.enabled, {
                        onToggle = props.validateChange(function(newEnabled)
                            rule.enabled = newEnabled
                        end),
                    })
                end)

                ui.box('description', { flex = 1 }, function()
                    ui.textInput('description', rule.description, {
                        maxLength = rule_constants.MAX_DESCRIPTION_LENGTH,
                        onChange = props.validateChange(function(newDescription)
                            rule.description = newDescription:sub(1, rule_constants.MAX_DESCRIPTION_LENGTH)
                        end),
                    })
                end)
            end)

            -- Action settings
            if rule.action == rule_constants.ACTION_RUN_CODE then
                local runCode = rule[rule_constants.ACTION_RUN_CODE]

                ui.codeEditor('code', runCode.edited or runCode.applied, {
                    onChange = props.validateChange(function (newEdited)
                        if newEdited == runCode.applied then
                            runCode.edited = nil
                        else
                            runCode.edited = newEdited
                        end
                    end),
                })

                ui_utils.row('status-apply', function()
                    if runCode.edited then
                        ui.markdown('edited')
                    else
                        ui.markdown('applied')
                    end
                end, function()
                    if runCode.edited then
                        if ui.button('apply') then
                            props.validateChange(function()
                                runCode.applied = runCode.edited
                                runCode.edited = nil
                            end)()
                        end
                    end
                end)
            end

            -- Remove
            if ui.button('remove rule', { kind = 'danger' }) then
                ruleIndicesToRemove[ruleIndex] = true
            end
        end)

        if sectionOpened then
            self.__ruleSectionOpenIndex = ruleIndex
        end
    end

    -- Apply removes
    local inIndex, n = 1, #rules
    for outIndex = 1, n do
        while ruleIndicesToRemove[inIndex] do -- Skip if should remove
            inIndex = inIndex + 1
        end
        rules[outIndex] = rules[inIndex]
        inIndex = inIndex + 1
    end
    if ruleIndicesToRemove[self.__ruleSectionOpenIndex] then
        self.__ruleSectionOpenIndex = nil
    end
end

function node_group.proxyMethods:uiTypePart(props)
    ui.tabs('group-tabs', function()
        ui.tab('rules', function()
            self:uiRulesPart(props)
        end)
    end)
end


return node_group