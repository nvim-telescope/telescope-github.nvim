local entry_display = require('telescope.pickers.entry_display')
local gh_make_entry = {}
-- local utils = require('telescope.utils')

function gh_make_entry.gen_from_run(opts)
  opts = opts or {}
  local icons = {
    failed    = "X",
    success   = "✓",
    working   = "-",
    cancelled = "C",
  }

  local displayer = entry_display.create {
  separator = "|",
  items = {
      { width = 2 },
      { width = 40 },
      { width = 12 },
      { remaining = true },
    }
  }

  local status_map = {
    ["success"]          = {icon = icons.success,   hl = "TelescopeResultsDiffAdd"},
    ["failure"]          = {icon = icons.failed,    hl = "TelescopeResultsDiffDelete"},
    ["startup_failure"]  = {icon = icons.failed,    hl = "TelescopeResultsDiffDelete"},
    ["active"]           = {icon = icons.working,   hl = "TelescopeResultsDiffChange"},
    ["cancelled"]        = {icon = icons.cancelled, hl = "TelescopeResultsDiffDelete"},
  }

  local make_display = function(entry)
    local status_x = {}
    if entry.active ~= "completed" then
      status_x = status_map["active"]
    else
      status_x = status_map[entry.status] or {}
    end

    local empty_space = ("")
    return displayer {
      { status_x.icon or empty_space, status_x.hl },
      entry.value,
      entry.workflow,
      entry.branch,
      entry.id,
    }
  end

  return function (entry)
    if entry == '' then return nil end
    local tmp_table = vim.split(entry,"\t");
    local active = tmp_table[1] or ""
    local status = tmp_table[2] or ""
    local description = tmp_table[3] or ""
    local workflow = tmp_table[4] or ""
    local branch = tmp_table[5] or ""
    local id = tmp_table[#tmp_table] or ""

    return {
      value = description,
      active = active,
      status = status,
      workflow = workflow,
      branch = branch,
      id = id,
      ordinal = entry,
      display = make_display,
    }
  end
end

return gh_make_entry
