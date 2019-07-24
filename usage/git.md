## Core Concepts
  - De-centralized (there may be multiple remote):
      - You have to specify remote name when trying to operate on remote. This is unintuitive and cumbersome if you are working on only one remote
      - Most git oddities comes from this. When a command doesn't make sense, try to think in a de-centralized way.
  - Branch is not really a branch
    - Branch is just a pointer, as a base pointer telling git to grow from here
      - We does not know how this pointer comes to this point. This is by design. git is decentralized, meaning different people can have the same branch going different paths but ended up at the same point. There is no canonical path.
      - To know how branch comes to this point "locally", use `git reflog`.
  - Content hierarchy
    - Your current working set
    - Repo tree (inspected by `git log`)
    - Local branch tip history (that is, the meat of the "branch")
      - Inspected by `git reflog`
      - Contains hidden commits. e.g. Middle commit between `git commit --amend`
  - Expect you to manage hsitory well
    - Learn skills on how to manage history (like a mini historian)
      - Write good commit log
      - Organize commit tree
      - Know when to branch, when to merge, and when to rebase
    - Take time to manage history

### Force empty folder into version control:
In .gitignore:
```
*
!.gitignore
```

## Merge Disjointed Branches 
(e.g. pull from new remote location)
```bash
git pull origin master --allow-unrelated-histories
```

## Generate Patch
```bash
git format-patch --stdout HEAD^ > path-name.diff
```

## Discard Unpushed Local Changes
```bash
git reset --hard <commit> # restore commit content to local files set HEAD memory to commit
```

## Submodule
You will need this when pushing submodule for others: https://www.vogella.com/tutorials/GitSubmodules/article.html

## Tips
- If .gitignore doesn't seem to work after modifying, run this [script](https://stackoverflow.com/questions/1139762/ignore-files-that-have-already-been-committed-to-a-git-repository)
```bash
git rm -r --cached .
```

## Windows only:
Add executable bit: `git add --chmod=+x file_name`
