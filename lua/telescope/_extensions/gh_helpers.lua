local action_state = require('telescope.actions.state')

local H = {}

H.get_pr_number_for_entry_selection=function (prompt_bufnr)
  local selection = action_state.get_selected_entry(prompt_bufnr)
  local pr_number = vim.split(selection.value,"\t")[1]
  return pr_number
end

return H
