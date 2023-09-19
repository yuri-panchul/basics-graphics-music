# A Minimalistic Git Cheat Sheet
Yuri Panchul

## 1. At the beginning

### 1.1. Config your name and email

```bash
git config --global user.name  "Your Name"
git config --global user.email your@email.com
```

### 1.2. Set caching your password

```bash
git config credential.helper 'cache --timeout=3600'
```

If you don't set it, you have to enter your username and password every time
you do "git push". The timeout is set in seconds. After the timeout git will
ask your username and password again. The command above sets the timeout for
10 hours.

### 1.3. Clone a git repository from github

```bash
git clone https://github.com/yuri-panchul/basics-graphics-music
```

## 2. The development cycle

### 2.1. Update your copy of repository files with the changes made by other people

```bash
git pull
```

### 2.2. Add new files or directories (recursively)

```bash
git add file_or_directory_name
```

### 2.3. Edit the files

### 2.4. Check the status before you check in

Note changed, added, deleted files.
Note the files you intended to add but forgot to do it.

```bash
git status
```

### 2.5. Check the differenced against the repository to review your changes in the code

```bash
git diff
```

### 2.6. Make sure not to check in any text with tabs

Different editors treats tabs in different ways and many users do not like it.
Developers should not need to configure the tab width
of their text editors in order to be able to read the source code.
There are some exceptions, most notably Makefiles.
To find the tabs in your text files, you can use the following command:

```bash
grep -rlI --exclude-dir=.git --exclude=*.mk $'\t' .
```

The meaning of the grep options:

* -r - recursive
* -l - file list
* -I - Ignore binary files

You can fix the tabs by doing the following, but make sure to review the fixes:

```bash
grep -rlI --exclude-dir=.git --exclude=*.mk $'\t' . | xargs sed -i 's/\t/    /g'
```

### 2.7. If you want to undo uncommitted changes to a file or a directory, use this command:

```bash
git checkout file_or_directory_name
```

### 2.8. If you want to undo uncommitted changes for all files in the current directory, including uncommitted deletions, use this command:

```bash
git checkout .
```

### 2.9. If you want to undo any commited changes or even pushed changes, ask some power git user or read the git documentation carefully, making sure you understand everything.

### 2.10. After you finish editing, commit

Note that -a option automatically stages all modifications and file deletions, but not the additions.
You need to use 'git add' to add files or directories explicitly.

**Important Note 1: Please run "git status" and "git diff" before any commit.
Undoing committed and especially pushed changes is more difficult than undoing uncommitted changes.**

**Important Note 2: Please put a meaningful comment for each commit.**

```bash
git commit -a -m "A meaningful comment"
```

### 2.11. Officially publish all your committed changes in git repository (such as GitHub).
Now everybody can see your changes.

```bash
git push
```

## 3. Other practices

### 3.1. You can browse the repository history on http://github.com itself using web browser interface

### 3.2. If you need Git to ignore some files, put them in .gitignore

Such files may include automatically generated binaries, temporaries,
or unrelated files you don't want to checkin or to appear in git status.
Please read about .gitignore in Git documentation before doing it.

### 3.3. If you want to see the files in your tree untracked by Git, use:

```bash
git clean -d -n
```

This command works from the current directory all the way down.

After reviewing (be careful!), you can remove the files by running:

```bash
git clean -d -f
```

### 3.4. If you want to see the files in your tree ignored by Git

To keep things clean, periodically remove files in the tree,
ignored by git based on .gitignore list.
You definitely need to remove them before preparing a release package.

```bash
git clean -d -x -n
```

After reviewing (be careful!), you can remove the files by running:

```bash
git clean -d -x -f
```

### 3.5. If you need to do anything non-trivial (merging, undoing committed or pushed changes), please carefully consult Git documentation.

Otherwise you may introduce mess, bugs, or checkin some large binary files polluting the repository.

Updated on 2023.09.16
