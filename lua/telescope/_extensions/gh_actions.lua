local actions = require('telescope.actions')
local utils = require('telescope.utils')
local Job = require('plenary.job')
local state = require('telescope.state')

local A ={}
-- a for actions
A.gh_pr_checkout = function(prompt_bufnr)
  local selection = actions.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local tmp_table = vim.split(selection.value,"\t");
  if vim.tbl_isempty(tmp_table) then
    return
  end

  local qf_entry = {{
      text="Checking out pull request #" .. tmp_table[1] ..", please wait ..."
  }}

  local on_output = function(_, line)
    table.insert(qf_entry,{
        text = line
      })
    pcall(vim.schedule_wrap( function()
      vim.fn.setqflist(qf_entry,"r")
     end))
  end

  local job = Job:new({
      enable_recording = true ,
      command = "gh",
      args = {"pr", "checkout" ,tmp_table[1]},
      on_stdout = on_output,
      on_stderr = on_output,

      on_exit = function(_,status)
        if status == 0 then
          pcall(vim.schedule_wrap( function()
                vim.cmd[[cclose]]
           end))
           print("Pull request completed")
        end
      end,
    })

  vim.fn.setqflist(qf_entry,"r")
  vim.cmd[[copen]]
  local timer = vim.loop.new_timer()
  timer:start(200, 0, vim.schedule_wrap(function()
    -- increase timeout to 10000ms and wait interval to 20
    -- default value is 5000ms and 10
    job:sync(10000,20)
  end))

end


A.gh_web_view=function(type)
  return function(prompt_bufnr)
    local selection = actions.get_selected_entry(prompt_bufnr)
    actions.close(prompt_bufnr)
    local tmp_table = vim.split(selection.value,"\t");
    if vim.tbl_isempty(tmp_table) then
      return
    end
    os.execute('gh ' .. type .. ' view --web ' .. tmp_table[1])
  end
end

A.gh_gist_append=function(prompt_bufnr)
  local selection = actions.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local tmp_table = vim.split(selection.value,"\t");
  if vim.tbl_isempty(tmp_table) then
    return
  end
  local gist_id = tmp_table[1]
  local text = utils.get_os_command_output('gh gist view ' .. gist_id .. ' -r')
  if text and vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "modifiable") then
    vim.api.nvim_put(vim.split(text,'\n'), 'b', true, true)
  end
end

A.gh_pr_v_toggle = function(prompt_bufnr)
  local status = state.get_status(prompt_bufnr)
  if status.gh_pr_preview == 'diff' then
    status.gh_pr_preview = 'detail'
  else
    status.gh_pr_preview = 'diff'
  end
  local entry = actions.get_selected_entry(prompt_bufnr)
  actions.get_current_picker(prompt_bufnr).previewer:preview(
      entry,
      status
  )
end

return A
