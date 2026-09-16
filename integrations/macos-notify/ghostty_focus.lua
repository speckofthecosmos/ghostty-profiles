-- ghostty_focus: clickable notifications that focus the Ghostty window that raised them.
--
-- Ghostty posts its own notifications but clicking one does not focus the surface
-- (ghostty-org/ghostty#9145), and with several Ghostty instances running, anything
-- routing by bundle id cannot tell which one to raise. Hammerspoon posts instead,
-- and focuses by pid.
--
-- Called from a Claude Code Notification hook:
--   hs -c "ghostty_focus.notify(12345, 'body text')"

local M = {}

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

function M.notify(pid, body, id)
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
        withdrawAfter = 0,
    })

    -- One notification per session: a newer one replaces the older rather than
    -- stacking three banners for the same window.
    if M.pending[key] then M.pending[key]:withdraw() end
    M.pending[key] = n
    n:send()
end

return M
