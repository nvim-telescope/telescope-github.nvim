local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local make_entry = require "telescope.make_entry"
local utils = require "telescope.utils"
local popup = require "plenary.popup"

local log = require "telescope.log"
local gh_p = require "telescope._extensions.gh_previewers"
local gh_a = require "telescope._extensions.gh_actions"
local gh_e = require "telescope._extensions.gh_make_entry"

local B = {}

local function parse_opts(opts, target)
  local query = {}
  local tmp_table = {}
  if target == "issue" then
    tmp_table = { "author", "assignee", "mention", "label", "milestone", "search", "state", "limit" }
  elseif target == "pr" then
    tmp_table = { "author", "assignee", "label", "search", "state", "base", "limit" }
  elseif target == "run" then
    tmp_table = { "workflow", "limit" }
  elseif target == "gist" then
    tmp_table = { "public", "secret", "limit" }
    if opts.public then
      opts.public = " "
    end
    if opts.secret then
      opts.secret = " "
    end
  end

  for _, value in pairs(tmp_table) do
    if opts[value] then
      if opts[value] == " " then
        table.insert(query, { "--" .. value })
      else
        table.insert(query, { "--" .. value, opts[value] })
      end
    end
  end
  return query
end

local function msgLoadingPopup(msg, cmd, complete_fn)
  local row = math.floor((vim.o.lines - 5) / 2)
  local width = math.floor(vim.o.columns / 1.5)
  local col = math.floor((vim.o.columns - width) / 2)
  for _ = 1, (width - #msg) / 2, 1 do
    msg = " " .. msg
  end
  local prompt_win, prompt_opts = popup.create(msg, {
    border = {},
    borderchars = conf.borderchars,
    height = 5,
    col = col,
    line = row,
    width = width,
  })
  vim.api.nvim_win_set_option(prompt_win, "winhl", "Normal:TelescopeNormal")
  vim.api.nvim_win_set_option(prompt_win, "winblend", 0)
  local prompt_border_win = prompt_opts.border and prompt_opts.border.win_id
  if prompt_border_win then
    vim.api.nvim_win_set_option(prompt_border_win, "winhl", "Normal:TelescopePromptBorder")
  end
  vim.defer_fn(
    vim.schedule_wrap(function()
      local results = utils.get_os_command_output(cmd)
      if not pcall(vim.api.nvim_win_close, prompt_win, true) then
        log.trace("Unable to close window: ", "ghcli", "/", prompt_win)
      end
      complete_fn(results)
    end),
    10
  )
end

-- b for builtin function
B.gh_issues = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts, "issue")
  local cmd = vim.tbl_flatten { "gh", "issue", "list", opts_query }
  local title = "Issues"
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_string(opts),
      },
      previewer = previewers.new_termopen_previewer {
        get_command = function(entry)
          local tmp_table = vim.split(entry.value, "\t")
          if vim.tbl_isempty(tmp_table) then
            return { "echo", "" }
          end
          return { "gh", "issue", "view", tmp_table[1] }
        end,
      },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(gh_a.gh_issue_insert)
        map("i", "<c-t>", gh_a.gh_web_view "issue")
        map("i", "<c-l>", gh_a.gh_issue_insert_markdown_link)
        return true
      end,
    }):find()
  end)
end

B.gh_pull_request = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts, "pr")
  local cmd = vim.tbl_flatten { "gh", "pr", "list", opts_query }
  local title = "Pull Requests"
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_string(opts),
      },
      previewer = gh_p.gh_pr_preview.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        map("i", "<c-e>", gh_a.gh_pr_v_toggle)
        -- can't map to <c-m
        map("i", "<c-r>", gh_a.gh_pr_merge)
        map("i", "<c-t>", gh_a.gh_web_view "pr")
        map("i", "<c-a>", gh_a.gh_pr_approve)
        map("i", "<c-f>", function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local pr_number = vim.split(selection.value, "\t")[1]

          B.gh_pull_request_files(opts, pr_number)
        end)
        actions.select_default:replace(gh_a.gh_pr_checkout)
        return true
      end,
    }):find()
  end)
end

B.gh_pull_request_files = function(opts, pr_number)
  opts = opts or {}
  opts.limit = opts.limit or 100

  local title_cmd = pr_number and { "gh", "pr", "view", pr_number, "--json", "title", "--jq", ".title" }
    or { "gh", "pr", "view", "--json", "title", "--jq", ".title" }

  local cmd = pr_number and { "gh", "pr", "view", pr_number, "--json", "files", "--jq", ".files.[].path" }
    or { "gh", "pr", "view", "--json", "files", "--jq", ".files.[].path" }

  local pr_title = '"' .. utils.get_os_command_output(title_cmd)[1] .. '"'
  local title = "Modified Files for " .. pr_title

  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_file(),
      },
      previewer = conf.file_previewer(opts),
    }):find()
  end)
end

B.gh_gist = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts, "gist")
  local title = "Gist"
  local cmd = vim.tbl_flatten { "gh", "gist", "list", opts_query }
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = gh_e.gen_from_gist(opts),
      },
      previewer = gh_p.gh_gist_preview.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(gh_a.gh_gist_append)
        map("i", "<c-t>", gh_a.gh_web_view "gist")
        map("i", "<c-e>", gh_a.gh_gist_edit)
        map("i", "<c-d>", gh_a.gh_gist_delete)
        map("i", "<c-n>", gh_a.gh_gist_create)
        return true
      end,
    }):find()
  end)
end

B.gh_secret = function(opts)
  opts = opts or {}
  local opts_query = parse_opts(opts, "secret")
  local title = "Secret"
  local cmd = vim.tbl_flatten { "gh", "secret", "list", opts_query }
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = gh_e.gen_from_secret(opts),
      },
      previewer = gh_p.gh_secret_preview.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(gh_a.gh_secret_append)
        map("i", "<c-e>", gh_a.gh_secret_set)
        map("i", "<c-n>", gh_a.gh_secret_set_new)
        map("i", "<c-d>", gh_a.gh_secret_remove)
        return true
      end,
    }):find()
  end)
end

B.gh_run = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  opts.wincmd = opts.wincmd or "botright vnew"
  opts.wrap = opts.wrap or "nowrap"
  opts.filetype = opts.filetype or "bash"
  opts.timeout = opts.timeout or 1000
  opts.wait_interval = opts.wait_interval or 2
  opts.mode = "async"

  if opts.cleanmeta == nil then
    opts.cleanmeta = true
  end
  local opts_query = parse_opts(opts, "run")
  local cmd = vim.tbl_flatten { "gh", "run", "list", opts_query }
  local title = "Workflow runs"
  msgLoadingPopup("Loading " .. title, cmd, function(results)
    if results[1] == "" then
      print("Empty " .. title)
      return
    end
    pickers.new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = results,
        entry_maker = gh_e.gen_from_run(opts),
      },
      previewer = gh_p.gh_run_preview.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        map("i", "<c-r>", gh_a.gh_run_rerun)
        map("i", "<c-t>", gh_a.gh_run_web_view)
        map("i", "<c-a>", gh_a.gh_run_cancel)
        actions.select_default:replace(gh_a.gh_run_view_log(opts))
        return true
      end,
    }):find()
  end)
end

return B
