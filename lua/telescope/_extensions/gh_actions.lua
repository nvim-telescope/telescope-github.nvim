local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local utils = require "telescope.utils"
local Job = require "plenary.job"
local state = require "telescope.state"
local flatten = vim.tbl_flatten

local A = {}

local function close_telescope_prompt(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  local tmp_table = vim.split(selection.value, "\t")
  if vim.tbl_isempty(tmp_table) then
    return
  end
  return tmp_table[1]
end
local function gh_qf_action(pr_number, action, msg)
  if pr_number == nil then
    return
  end

  local qf_entry = { {
    text = msg .. pr_number .. ", please wait ...",
  } }

  local on_output = function(_, line)
    table.insert(qf_entry, {
      text = line,
    })
    pcall(vim.schedule_wrap(function()
      vim.fn.setqflist(qf_entry, "r")
    end))
  end
  local job = Job:new {
    enable_recording = true,
    command = "gh",
    args = flatten { "pr", action, pr_number },
    on_stdout = on_output,
    on_stderr = on_output,

    on_exit = function(_, status)
      if status == 0 then
        pcall(vim.schedule_wrap(function()
          vim.cmd [[cclose]]
        end))
        print "Pull request completed"
      end
    end,
  }

  vim.fn.setqflist(qf_entry, "r")
  vim.cmd [[copen]]
  local timer = vim.loop.new_timer()
  timer:start(
    200,
    0,
    vim.schedule_wrap(function()
      -- increase timeout to 10000ms and wait interval to 20
      -- default value is 5000ms and 10
      job:sync(10000, 20)
    end)
  )
end
-- a for actions
A.gh_issue_insert = function(prompt_bufnr)
  -- Insert “#10” if issue 10 was selected
  local issue_number = close_telescope_prompt(prompt_bufnr)
  if vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "modifiable") then
    vim.api.nvim_put({ "#" .. issue_number }, "b", true, true)
  end
end

A.gh_issue_insert_markdown_link = function(prompt_bufnr)
  if not (vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "modifiable")) then
    return
  end
  local issue_number = close_telescope_prompt(prompt_bufnr)
  local text = utils.get_os_command_output {
    "gh",
    "issue",
    "view",
    issue_number,
    "--json",
    "number,title,url",
    "--template",
    '{{printf "[%s (#%.0f)](%s)" .title .number .url}}',
  }
  if text then
    vim.api.nvim_put(text, "b", true, true)
  end
end

A.gh_pr_checkout = function(prompt_bufnr)
  local pr_number = close_telescope_prompt(prompt_bufnr)
  gh_qf_action(pr_number, "checkout", "Checking out pull request #")
end

A.gh_web_view = function(type)
  return function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local id = ""
    actions.close(prompt_bufnr)
    local tmp_table = vim.split(selection.value, "\t")
    if vim.tbl_isempty(tmp_table) then
      return
    end
    if type == "gist" then
      id = selection.id
    else
      id = tmp_table[1]
    end
    os.execute("gh " .. type .. " view --web " .. id)
  end
end

A.gh_gist_append = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" then
    return
  end
  local text = utils.get_os_command_output { "gh", "gist", "view", selection.id, "-r" }
  if text and vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "modifiable") then
    vim.api.nvim_put(text, "b", true, true)
  end
end

A.gh_gist_create = function(prompt_bufnr)
  actions.close(prompt_bufnr)
  local ans = vim.fn.input "[GIST] Enter description: "
  if ans == "" then
    return
  end
  os.execute("echo 'new gist\r\n' | gh gist create -d '" .. ans .. "' -")
end

A.gh_gist_edit = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" then
    return
  end
  vim.cmd("! tmux neww gh gist edit " .. selection.id)
end

A.gh_gist_delete = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" then
    return
  end
  local ans = vim.fn.input "[GIST] are you sure you want to delete the gist? y/n: "
  if ans == "y" then
    print("Deleting the gist: ", selection.id)
    os.execute("gh gist delete " .. selection.id)
  end
end

A.gh_secret_append = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.value == "" then
    return
  end
  if vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "modifiable") then
    vim.api.nvim_put({ selection.value }, "b", true, true)
  end
end

A.gh_secret_remove = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.value == "" then
    return
  end
  local ans = vim.fn.input "[SECRET] are you sure you want to delete the secret? y/n: "
  if ans == "y" then
    print("Deleting the secret: ", selection.value)
    os.execute("gh secret remove " .. selection.value)
  end
end

A.gh_secret_set_new = function(prompt_bufnr)
  actions.close(prompt_bufnr)
  local secret_name = vim.fn.input "[SECRET] Enter secret name: "
  local secret_body = vim.fn.input "[SECRET] Enter secret value: "
  if secret_name == "" or secret_body == "" then
    return
  end
  print("Creating the secret: ", secret_name)
  os.execute("gh secret set " .. secret_name .. " -b " .. secret_body)
end

A.gh_secret_set = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  local secret_body = vim.fn.input "[SECRET] Enter secret value: "
  if secret_body == "" then
    return
  end
  print("Setting the secret: ", selection.value)
  os.execute("gh secret set " .. selection.value .. " -b " .. secret_body)
end

A.gh_pr_v_toggle = function(prompt_bufnr)
  local status = state.get_status(prompt_bufnr)
  if status.gh_pr_preview == "diff" then
    status.gh_pr_preview = "detail"
  else
    status.gh_pr_preview = "diff"
  end
  local entry = action_state.get_selected_entry()
  action_state.get_current_picker(prompt_bufnr).previewer:preview(entry, status)
end

A.gh_pr_merge = function(prompt_bufnr)
  local pr_number = close_telescope_prompt(prompt_bufnr)
  local type = vim.fn.input "What kind of merge ([m]erge / [s]quash / [r]ebase) : "
  local action = nil
  if type == "merge" or type == "m" then
    action = "-m"
  elseif type == "rebase" or type == "r" then
    action = "-s"
  elseif type == "squash" or type == "s" then
    action = "-s"
  end
  if action ~= nil then
    gh_qf_action(pr_number, { "merge", action }, "Merge pull request #")
  end
end

A.gh_pr_approve = function(prompt_bufnr)
  local pr_number = close_telescope_prompt(prompt_bufnr)
  gh_qf_action(pr_number, { "review", "--approve" }, "Approve pull request #")
end

A.gh_run_web_view = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" then
    return
  end
  os.execute("gh run view --web " .. selection.id)
end

A.gh_run_rerun = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" then
    return
  end
  print("Requested rerun of run: ", selection.id)
  os.execute("gh run rerun " .. selection.id)
end

A.gh_run_cancel = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection.id == "" or selection.active == "completed" then
    return
  end
  print("Requested cancel of run: ", selection.id)
  os.execute("gh run cancel " .. selection.id)
end

A.gh_run_view_log = function(opts)
  return function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    if selection.id == "" then
      return
    end
    local log_output = {}
    vim.api.nvim_command(opts.wincmd)
    local buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_name(0, "result #" .. buf)

    vim.api.nvim_buf_set_option(0, "buftype", "nofile")
    vim.api.nvim_buf_set_option(0, "swapfile", false)
    vim.api.nvim_buf_set_option(0, "filetype", opts.filetype)
    vim.api.nvim_buf_set_option(0, "bufhidden", "wipe")
    vim.api.nvim_command("setlocal " .. opts.wrap)
    vim.api.nvim_command "setlocal cursorline"

    local args = {}
    local run_completed = false
    if selection.status == "success" or selection.status == "failure" then
      run_completed = true
    end
    if run_completed then
      args = { "run", "view", "--log", selection.id }
    else
      args = { "run", "watch", selection.id }
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Retrieving log, please wait..." })

    local on_output = function(_, line)
      if not run_completed and string.find(line, "Refreshing") then
        log_output = {}
      end
      local cleanmsg = function(msgtoclean)
        local msgwithoutdate = string.match(msgtoclean, "T%d%d:%d%d:%d%d.%d+Z(.+)$")
        msgwithoutdate = string.gsub(msgwithoutdate, "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "")

        if msgwithoutdate ~= nil then
          return msgwithoutdate
        else
          return msgtoclean
        end
      end
      local tbl_msg = vim.split(line, "\t", true)
      if opts.cleanmeta and run_completed and #tbl_msg == 3 then
        line = cleanmsg(tbl_msg[3])
      end
      table.insert(log_output, line)

      pcall(vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, log_output)
        end
      end))
    end

    local job = Job:new {
      enable_recording = true,
      command = "gh",
      args = flatten(args),
      on_stdout = on_output,
      on_stderr = on_output,

      on_exit = function(_, status)
        if status == 0 then
          if run_completed then
            print "Log retrieval completed!"
          else
            print "Workflow run completed!"
          end
        end
      end,
    }
    if opts.mode == "sync" then
      job:sync(opts.timeout, opts.wait_interval)
    else
      job:start()
    end
  end
end

return A
