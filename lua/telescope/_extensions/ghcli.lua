
local actions = require('telescope.actions')
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local previewers = require('telescope.previewers')
local pickers = require('telescope.pickers')
local utils = require('telescope.utils')
local conf = require('telescope.config').values
local Job = require('plenary.job')
local defaulter = utils.make_default_callable
local flatten = vim.tbl_flatten
local builtin = require('telescope.builtin')

local GH={ }
local bat_options = {"bat" , "--style=plain" , "--color=always" , "--paging=always" , '--decorations=never','--pager=less'}

local function parse_opts(opts,target)
  local query={}
  local tmp_table={}
  if target=='issue' then
    tmp_table = {'author' , 'assigner' , 'mention' , 'label' , 'milestone' , 'state' , 'limit' }
  elseif target=='pr' then
    tmp_table = {'assigner' , 'label' , 'state' , 'base' , 'limit' }
  elseif target == 'gist' then
    tmp_table = {'public' , 'secret'}
    if opts.public then opts.public =' ' end
    if opts.secret then opts.secret =' ' end
  end

  for _, value in pairs(tmp_table) do
    if opts[value] then
      table.insert(query,"--" .. value .. ' ' .. opts[value])
    end
  end
  return table.concat(query," ")
end

-- p for preview
GH.p_gh_gist_preview = defaulter(function(opts)
    return previewers.new_termopen_previewer {
        get_command = opts.get_command or function(entry)
        local tmp_table = vim.split(entry.value,"\t");
        if vim.tbl_isempty(tmp_table) then
          return {"echo", ""}
        end
        local result={ 'gh' ,'gist' ,'view',tmp_table[1] ,'|'}
        if vim.fn.executable("bat") then
          table.insert(result , bat_options)
        else
          table.insert(result , "less")
        end
        -- print(vim.inspect(result))
        return flatten(result)
      end
  }
end, {})

-- a for actions
GH.a_gh_pr_checkout = function(prompt_bufnr)
  local selection = actions.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local tmp_table = vim.split(selection.value,"\t");
  if vim.tbl_isempty(tmp_table) then
    return
  end
  local job = Job:new({
      enable_recording = true ,
      command = "gh",
      args = {"pr", "checkout" ,tmp_table[1]}
    })
  -- need to display result in quickfix
  job:sync()
end


GH.a_gh_web_view=function(type)
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

GH.a_gh_gist_append=function(prompt_bufnr)
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

-- b for builtin function
GH.b_gh_issues = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'issue')
  local cmd = 'gh issue list '.. opts_query
  local results = vim.split(utils.get_os_command_output(cmd), '\n')
  pickers.new(opts, {
    prompt_title = 'Issues',
    finder = finders.new_table {
      results = results,
      entry_maker = make_entry.gen_from_string(opts),
    },
    previewer = previewers.new_termopen_previewer{
      get_command = function(entry)
        local tmp_table = vim.split(entry.value,"\t");
        if vim.tbl_isempty(tmp_table) then
          return {"echo", ""}
        end
        return { 'gh' ,'issue' ,'view',tmp_table[1] }
      end
    },
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_,map)
      actions.goto_file_selection_edit:replace(actions.close)
      map('i','<c-t>',GH.a_gh_web_view('issue'))
      return true
    end
  }):find()
end

GH.b_gh_pull_request = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'pr')
  local cmd = 'gh pr list ' .. opts_query
  local results = vim.split(utils.get_os_command_output(cmd) , '\n')
  pickers.new(opts, {
    prompt_title = 'Pull Requests' ,
    finder = finders.new_table {
      results = results,
      entry_maker = make_entry.gen_from_string(opts),
    },
    previewer = previewers.new_termopen_previewer{
      get_command = function(entry)
        local tmp_table = vim.split(entry.value,"\t");
        if vim.tbl_isempty(tmp_table) then
          return {"echo", ""}
        end
        return { 'gh' ,'pr' ,'view',tmp_table[1] }
      end
    },
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_,map)
      actions.goto_file_selection_edit:replace(GH.a_gh_pr_checkout)
      map('i','<c-t>',GH.a_gh_web_view('pr'))
      return true
    end
  }):find()
end

GH.b_gh_gist = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'gist')
  local cmd = 'gh gist list '..opts_query
  local results = vim.split(utils.get_os_command_output(cmd), '\n')
  pickers.new(opts, {
    prompt_title = 'gist list' ,
    finder = finders.new_table {
      results = results,
      entry_maker = make_entry.gen_from_string(opts),
    },
    previewer = GH.p_gh_gist_preview.new(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_,map)
      actions.goto_file_selection_edit:replace(GH.a_gh_gist_append)
      map('i','<c-t>',GH.a_gh_web_view('gist'))
      return true
    end
  }):find()
end

return require('telescope').register_extension {
    setup = function()
      builtin.gh_gist = GH.b_gh_gist
      builtin.gh_issues = GH.b_gh_issues
      builtin.gh_pull_request = GH.b_gh_pull_request
    end;
    export = GH
}
