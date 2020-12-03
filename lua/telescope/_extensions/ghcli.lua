
local builtin = require('telescope.builtin')
local gh_b= require('telescope._extensions.gh_builtin')



return require('telescope').register_extension {
    setup = function()
      builtin.gh_gist =gh_b.gh_gist
      builtin.gh_issues = gh_b.gh_issues
      builtin.gh_pull_request =gh_b.gh_pull_request
    end;
}
