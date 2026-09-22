-- ghostty_focus: clickable notifications that focus the Ghostty window that raised them.
--
-- Ghostty posts its own notifications but clicking one does not focus the surface
-- (ghostty-org/ghostty#9145), and with several Ghostty instances running, anything
-- routing by bundle id cannot tell which one to raise. Hammerspoon posts instead,
-- and focuses by pid.
--
-- Called from a Claude Code Notification hook:
--   hs -c "ghostty_focus.notify(12345, 'body text', 'session-id', 'idle_prompt')"
--
-- The 4th argument is the Claude Code notification type; it selects the banner
-- duration from M.durations below. Omitted or unrecognised falls back to
-- M.withdrawAfter.

local M = {}

-- Seconds a banner stays up before withdrawing itself. hs.notify reads 0 as
-- "never withdraw", which is what this used to pass: banners stayed on screen
-- and stacked up in Notification Center until dismissed by hand. No entry below
-- uses 0 for that reason, including the blocking ones.
--
-- One duration for every type was too blunt. Measured over 17 hours, 94% of
-- notifications are idle_prompt -- pure "I am waiting", nothing is stuck -- and
-- giving those the same 20 seconds as a permission prompt that has a session
-- halted is backwards. Transient types are now short enough to ignore, blocking
-- types long enough to catch from across the room.
M.durations = {
    -- Transient: you are being told, not asked. Nothing is waiting on you.
    idle_prompt                = 4,
    agent_completed            = 8,
    auth_success               = 4,
    elicitation_complete       = 4,
    elicitation_response       = 4,
    quota_auto_resume_fired    = 8,

    -- Blocking: a session is stopped until a human answers.
    permission_prompt          = 60,
    agent_needs_input          = 60,
    elicitation_dialog         = 60,
    elicitation_url_dialog     = 60,

    -- Degraded: not blocking, but you want to know before relying on it.
    quota_auto_resume_stale    = 30,
    quota_auto_resume_disabled = 30,
}

-- Fallback for a type not in the table (a new one Claude Code adds later).
M.withdrawAfter = 20

-- Notifications are held until dismissed. Without a reference Lua's GC collects
-- them before the click arrives and the callback never fires.
M.pending = {}

local function windowTitle(app)
    if not app then return nil end
    local w = app:focusedWindow() or app:mainWindow()
    if not w then
        local all = app:allWindows()
        w = all and all[1]
    end
    local t = w and w:title()
    if t and t ~= "" then return t end
    return nil
end

function M.notify(pid, body, id, kind)
    pid = tonumber(pid)
    if not pid then return end

    local app = hs.application.applicationForPID(pid)
    if not app then return end

    -- Nothing to summon you back to a window you are already looking at.
    local front = hs.application.frontmostApplication()
    if front and front:pid() == pid then return end

    id = id or tostring(pid)
    local key = "gf_" .. id

    local n = hs.notify.new(function()
        local target = hs.application.applicationForPID(pid)
        if target then target:activate(true) end
        M.pending[key] = nil
    end, {
        title = windowTitle(app) or "Ghostty",
        informativeText = body or "",
        withdrawAfter = M.durations[kind] or M.withdrawAfter,
    })

    -- One notification per session: a newer one replaces the older rather than
    -- stacking three banners for the same window.
    if M.pending[key] then M.pending[key]:withdraw() end
    M.pending[key] = n
    n:send()
end

return M
