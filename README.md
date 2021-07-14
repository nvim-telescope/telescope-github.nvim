# Telescope-github.nvim
Integration with [github cli](https://cli.github.com/)

#### Installation
you need to install github cli (version 1.11 or greater) first
[Install Github cli](https://github.com/cli/cli#installation)

```viml
Plug 'nvim-lua/popup.nvim'
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
| assignee  | Filter by assignee                 |
| label     | Filter by label                    |
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
| state     | Filter by state: {open,closed,all} |
| limit     | limit default = 100                |

#### Key mappings

| key     | Usage    |
|---------|----------|
| `<cr>`  | nothing  |
| `<c-t>` | open web |

### Gist
#### Options Filter

[Detail](https://cli.github.com/manual/gh_gist_list)
| Query     | filter                             |
|-----------|------------------------------------|
| public    | Filter by public                   |
| secret    | Filter by secret                   |

### Key mappings
| key     | Usage                 |
|---------|-----------------------|
| `<cr>`  | append gist to buffer |
| `<c-t>` | open web              |

### Workflow runs
#### Options Filter
[Detail](https://cli.github.com/manual/gh_run_list)

| Query     | filter                                                |
|-----------|-------------------------------------------------------|
| workflow  | Filter runs by workflow                               |
| limit     | limit default = 100                                   |
| wincmd    | Command to open log window, default = 'botright vnew' |
| wrap      | Wrap lines in log window, default = 'nowrap'          |
| filetype  | Filetype to use on log window, default='bash'         |
| cleanmeta | Try to clean run log lines, default = 'true'          |

#### Key mappings

| key     | Usage                                        |
|---------|----------------------------------------------|
| `<cr>`  | open workflow summary/run logs in new window |
| `<c-t>` | open web                                     |
| `<c-r>` | request run rerun                            |
