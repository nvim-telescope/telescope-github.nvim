local gh_b= require('telescope._extensions.gh_builtin')



return require('telescope').register_extension {
    exports= {
      gist = gh_b.gh_gist ,
      issues = gh_b.gh_issues,
      pull_request = gh_b.gh_pull_request ,
    },
}
