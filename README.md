# Telescope-github.nvim
Integration with [github cli](https://cli.github.com/)

### Installation
you need to install github cli (version 2.2.0 or greater) first
[Install Github cli](https://github.com/cli/cli#installation)

#### Packer
```lua
use {
    "nvim-telescope/telescope.nvim",
    requires = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope-github.nvim" },
    },
}

```

#### vim-plug
```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-github.nvim'

```
## Setup

``` lua
require('telescope').load_extension('gh')

```

## Available commands
```viml
Telescope gh issues
Telescope gh pull_request
Telescope gh gist
Telescope gh run

"Using lua function
lua require('telescope').extensions.gh.issues()<cr>
lua require('telescope').extensions.gh.pull_request()<cr>
lua require('telescope').extensions.gh.gist()<cr>
lua require('telescope').extensions.gh.run()<cr>

```

## Options

You can add more filter to issue in commands

```viml
" filter with author and label
Telescope gh issues author=windwp label=bug
```

### Pull Request
#### Options Filter
[Detail](https://cli.github.com/manual/gh_pr_list)

| Query     | filter                             |
|-----------|------------------------------------|
| author    | Filter by author                   |
| assignee  | Filter by assignee                 |
| label     | Filter by label                    |
| search    | Filter by query                    |
| state     | Filter by state: {open,closed,all} |
| base      | Filter by base branch              |
| limit     | limit default = 100                |

#### Key mappings

| key     | Usage                         |
|---------|-------------------------------|
| `<cr>`  | checkout pull request         |
| `<c-t>` | open web                      |
| `<c-e>` | toggle to view detail or diff |
| `<c-r>` | merge request                 |
| `<c-a>` | approve pull request          |
| `<c-f>` | browse modified files         |

### Issue

#### Options Filter
[Detail](https://cli.github.com/manual/gh_issue_list)

| Query     | filter                             |
|-----------|------------------------------------|
| author    | Filter by author                   |
| assignee  | Filter by assignee                 |
| mention   | Filter by mention                  |
| label     | Filter by label                    |
| milestone | Filter by milestone                |
| search    | Filter by query                    |
| state     | Filter by state: {open,closed,all} |
| limit     | limit default = 100                |

#### Key mappings

| key     | Usage    |
|---------|----------|
| `<cr>`  | insert a reference to the issue |
| `<c-t>` | open web |
| `<c-l>` | insert a markdown-link to the issue |

### Gist
#### Options Filter

[Detail](https://cli.github.com/manual/gh_gist_list)
| Query     | filter                             |
|-----------|------------------------------------|
| public    | Filter by public                   |
| secret    | Filter by secret                   |
| limit     | limit default = 100                |

### Key mappings
| key     | Usage                    |
|---------|--------------------------|
| `<cr>`  | append gist to buffer    |
| `<c-t>` | open web                 |
| `<c-e>` | edit gist in TMUX window |
| `<c-d>` | delete selected gist     |
| `<c-n>` | create new empty gist    |

### Secret

**Note: only repository secrets are supported for now**

[Detail](https://cli.github.com/manual/gh_secret_list)

### Key mappings
| key     | Usage                           |
|---------|---------------------------------|
| `<cr>`  | append secret name to buffer    |
| `<c-e>` | set new secret value            |
| `<c-n>` | set new secret (name and value) |
| `<c-d>` | delete selected secret          |

### Workflow runs
#### Options Filter
[Detail](https://cli.github.com/manual/gh_run_list)

| Query         | filter                                                |
|---------------|-------------------------------------------------------|
| workflow      | Filter runs by workflow                               |
| limit         | limit default = 100                                   |
| wincmd        | Command to open log window, default = 'botright vnew' |
| wrap          | Wrap lines in log window, default = 'nowrap'          |
| filetype      | Filetype to use on log window, default='bash'         |
| cleanmeta     | Try to clean run log lines, default = 'true'          |
| timeout       | Timeout for sync mode, default = '10000'              |
| wait_interval | Wait interval for sync mode, default = '5'            |
| mode          | Mode to populate log window, default = 'async'        |

#### Key mappings

| key     | Usage                                        |
|---------|----------------------------------------------|
| `<cr>`  | open workflow summary/run logs in new window |
| `<c-t>` | open web                                     |
| `<c-r>` | request run rerun                            |
| `<c-a>` | request run cancel                           |
