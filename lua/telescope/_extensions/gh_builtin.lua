local actions = require('telescope.actions')
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local previewers = require('telescope.previewers')
local pickers = require('telescope.pickers')
local utils = require('telescope.utils')
local conf = require('telescope.config').values
local Job = require('plenary.job')
local builtin = require('telescope.builtin')

local gh_p= require('telescope._extensions.gh_previewers')
local gh_a= require('telescope._extensions.gh_actions')

local B={ }

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

-- b for builtin function
B.gh_issues = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'issue')
  local cmd = 'gh issue list '.. opts_query
  pickers.new(opts, {
    prompt_title = 'Issues',
    finder = finders.new_oneshot_job(
      vim.split(cmd,' '),
      opts
    ),
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
      map('i','<c-t>',gh_a.gh_web_view('issue'))
      return true
    end
  }):find()
end

B.gh_pull_request = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'pr')
  local cmd = 'gh pr list ' .. opts_query
  pickers.new(opts, {
    prompt_title = 'Pull Requests' ,
    finder = finders.new_oneshot_job(
      vim.split(cmd,' '),
      opts
    ),
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
      actions.goto_file_selection_edit:replace(gh_a.gh_pr_checkout)
      map('i','<c-t>',gh_a.gh_web_view('pr'))
      return true
    end
  }):find()
end

B.gh_gist = function(opts)
  opts = opts or {}
  opts.limit = opts.limit or 100
  local opts_query = parse_opts(opts , 'gist')
  local cmd = 'gh gist list '..opts_query
  pickers.new(opts, {
    prompt_title = 'gist list' ,
    finder = finders.new_oneshot_job(
      vim.split(cmd,' '),
      opts
    ),
    previewer = gh_p.gh_gist_preview.new(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_,map)
      actions.goto_file_selection_edit:replace(gh_a.gh_gist_append)
      map('i','<c-t>',gh_a.gh_web_view('gist'))
      return true
    end
  }):find()
end
return B
