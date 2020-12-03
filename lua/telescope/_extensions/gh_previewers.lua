local previewers = require('telescope.previewers')
local utils = require('telescope.utils')
local defaulter = utils.make_default_callable
local flatten = vim.tbl_flatten

local bat_options = {"bat" , "--style=plain" , "--color=always" , "--paging=always" , '--decorations=never','--pager=less'}
local P ={}

-- p for preview
P.p_gh_gist_preview = defaulter(function(opts)
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
return P
