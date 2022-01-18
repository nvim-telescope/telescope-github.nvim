local entry_display = require "telescope.pickers.entry_display"
local gh_make_entry = {}

function gh_make_entry.gen_from_run(opts)
  opts = opts or {}
  local icons = {
    failed = "X",
    success = "✓",
    working = "-",
    cancelled = "C",
  }

  local displayer = entry_display.create {
    separator = "|",
    items = {
      { width = 2 },
      { width = 40 },
      { width = 12 },
      { remaining = true },
    },
  }

  local status_map = {
    ["success"] = { icon = icons.success, hl = "TelescopeResultsDiffAdd" },
    ["failure"] = { icon = icons.failed, hl = "TelescopeResultsDiffDelete" },
    ["startup_failure"] = { icon = icons.failed, hl = "TelescopeResultsDiffDelete" },
    ["active"] = { icon = icons.working, hl = "TelescopeResultsDiffChange" },
    ["cancelled"] = { icon = icons.cancelled, hl = "TelescopeResultsDiffDelete" },
  }

  local make_display = function(entry)
    local status_x = {}
    if entry.active ~= "completed" then
      status_x = status_map["active"]
    else
      status_x = status_map[entry.status] or {}
    end

    local empty_space = ""
    return displayer {
      { status_x.icon or empty_space, status_x.hl },
      entry.value,
      entry.workflow,
      entry.branch,
      entry.id,
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end
    local tmp_table = vim.split(entry, "\t")
    local active = tmp_table[1] or ""
    local status = tmp_table[2] or ""
    local description = tmp_table[3] or ""
    local workflow = tmp_table[4] or ""
    local branch = tmp_table[5] or ""
    local id = ""

    if #tmp_table > 8 then
      id = tmp_table[7]
    else
      id = tmp_table[#tmp_table]
    end

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

function gh_make_entry.gen_from_gist(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = "|",
    items = {
      { width = 40 },
      { width = 2 },
      { width = 6 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    return displayer {
      entry.value,
      entry.files,
      entry.visibility,
      entry.age,
      entry.id,
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end
    local tmp_table = vim.split(entry, "\t")
    local id = tmp_table[1] or ""
    local description = tmp_table[2] or ""
    local files = tmp_table[3] or ""
    local visibility = tmp_table[4] or ""
    local age = tmp_table[5] or ""

    return {
      age = age,
      display = make_display,
      files = files,
      id = id,
      ordinal = entry,
      value = description,
      visibility = visibility,
    }
  end
end

function gh_make_entry.gen_from_secret(opts)
  opts = opts or {}

  -- TODO: pass secret type, so far only repository supported
  local icons = {
    repository = "R",
    environment = "E",
    organization = "O",
    user = "U",
  }

  local status_map = {
    ["repository"] = { icon = icons.repository, hl = "TelescopeResultsDiffAdd" },
    ["environment"] = { icon = icons.failed, hl = "TelescopeResultsDiffUntracked" },
    ["organization"] = { icon = icons.failed, hl = "TelescopeResultsDiffDelete" },
    ["user"] = { icon = icons.working, hl = "TelescopeResultsDiffChange" },
  }

  local displayer = entry_display.create {
    separator = "|",
    items = {
      { width = 2 },
      { width = 40 },
      { remaining = true },
    },
  }

  local status_x = {}
  if opts.environment then
    status_x = status_map["environment"]
  elseif opts.organization then
    status_x = status_map["organization"]
  elseif opts.user then
    status_x = status_map["user"]
  else
    status_x = status_map["repository"]
  end

  local make_display = function(entry)
    return displayer {
      { status_x.icon or " ", status_x.hl },
      entry.value,
      entry.age,
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end
    local tmp_table = vim.split(entry, "\t")
    local name = tmp_table[1] or ""
    local age = tmp_table[2] or ""

    return {
      display = make_display,
      age = age,
      value = name,
      ordinal = entry,
    }
  end
end

return gh_make_entry
