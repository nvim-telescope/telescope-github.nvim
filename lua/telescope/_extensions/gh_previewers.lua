local previewers = require "telescope.previewers"
local utils = require "telescope.utils"
local defaulter = utils.make_default_callable
local putils = require "telescope.previewers.utils"

local P = {}

-- p for preview
P.gh_gist_preview = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.id
    end,

    define_preview = function(self, entry)
      local gh_command = {}

      if entry.id then
        gh_command = { "gh", "gist", "view", entry.id }
      else
        gh_command { "echo", "empty" }
      end

      putils.job_maker(gh_command, self.state.bufnr, {
        value = entry.value,
        bufname = self.state.bufname,
        cwd = opts.cwd,
      })
      putils.regex_highlighter(self.state.bufnr, "text")
    end,
  }
end, {})

P.gh_secret_preview = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.id
    end,

    define_preview = function(self, entry)
      local gh_command = { "echo", "Unable to preview secrets" }

      putils.job_maker(gh_command, self.state.bufnr, {
        value = entry.value,
        bufname = self.state.bufname,
        cwd = opts.cwd,
      })
      putils.regex_highlighter(self.state.bufnr, "text")
    end,
  }
end, {})

P.gh_pr_preview = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, status)
      local tmp_table = vim.split(entry.value, "\t")
      local gh_command = { "gh", "pr", "view", tmp_table[1] }
      local filetype = "markdown"
      if status.gh_pr_preview == "diff" then
        gh_command = { "gh", "pr", "diff", tmp_table[1] }
        filetype = "diff"
      end

      if vim.tbl_isempty(tmp_table) then
        gh_command { "echo", "empty" }
      end

      putils.job_maker(gh_command, self.state.bufnr, {
        value = entry.value .. filetype,
        bufname = self.state.bufname,
        cwd = opts.cwd,
      })
      putils.regex_highlighter(self.state.bufnr, filetype)
    end,
  }
end, {})

P.gh_run_preview = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.id
    end,

    define_preview = function(self, entry)
      local gh_command = {}

      if entry.id then
        gh_command = { "gh", "run", "view", entry.id }
      else
        gh_command { "echo", "empty" }
      end

      putils.job_maker(gh_command, self.state.bufnr, {
        value = entry.value,
        bufname = self.state.bufname,
        cwd = opts.cwd,
      })
      putils.regex_highlighter(self.state.bufnr, "text")
    end,
  }
end, {})

return P
