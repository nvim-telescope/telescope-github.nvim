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

  local qf_entry={}
  local on_output = function(_, line)
    table.insert(qf_entry,{
        text = line
      })
  end

  local completed = false
  local job = Job:new({
      enable_recording = true ,
      command = "gh",
      args = {"pr", "checkout" ,tmp_table[1]},
      on_stdout = on_output,
      on_stderr = on_output,

      on_exit = function(_,status)
        if status == 0 then
          completed=true
        end
      end,
    })
  job:sync()

  if completed then
    print("Pull request completed")
  else
    vim.fn.setqflist(qf_entry,"r")
    vim.cmd[[copen]]
  end

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
