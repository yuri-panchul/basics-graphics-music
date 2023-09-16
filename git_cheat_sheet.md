# A Minimalistic Git Cheat Sheet
Yuri Panchul

## 1. At the beginning.

### 1.2. Config your name and email

```bash
git config --global user.name  "Your Name"  
git config --global user.email your@email.com  
```

### 1.3. Clone a git repository from github

```bash
git clone https://github.com/yuri-panchul/basics-graphics-music
```

## 2. The development cycle.

### 2.1. Update your copy of repository files with the changes made by other people

```bash
git pull
```

### 2.2. Add new files or directories (recursively)

```bash
git add file_or_directory_name
```

### 2.3. Edit the files

### 2.4. Check the status before you check in.

Note changed, added, deleted files.
Note the files you intended to add but forgot to do it.

```bash
git status
```

### 2.5. Check the differenced against the repository to review your changes in the code.

Make sure not to check in any text with tabs - different editors treats tabs in different ways and many users do not like it.

```bash
git diff
```

### 2.6. If you want to undo uncommitted changes to a file or a directory, use this command:

```bash
git checkout file_or_directory_name
```

### 2.7. If you want to undo uncommitted changes for all files in the current directory, including uncommitted deletions, use this command:

```bash
git checkout .
```

### 2.8. If you want to undo any commited changes or even pushed changes, ask some power git user or read the git documentation carefully, making sure you understand everything.

### 2.9. After you finish editing, commit.

Note that -a option automatically stages all modifications and file deletions, but not the additions.
You need to use 'git add' to add files or directories explicitly.

**Important Note 1: Please run "git status" and "git diff" before any commit.
Undoing committed and especially pushed changes is more difficult than undoing uncommitted changes.**  

**Important Note 2: Please put a meaningful comment for each commit.**

```bash
git commit -a -m "A meaningful comment"
```

### 2.10. Officially publish all your committed changes in git repository (such as GitHub).
Now everybody can see your changes.

```bash
git push
```

## 3. Other practices.

### 3.1. You can browse the repository history on http://github.com itself using web browser interface.

### 3.2. If you need Git to ignore some files, put them in .gitignore.

Such files may include automatically generated binaries, temporaries,
or unrelated files you don't want to checkin or to appear in git status.
Please read about .gitignore in Git documentation before doing it.

### 3.3. If you need to do anything non-trivial (merging, undoing committed or pushed changes), please carefully consult Git documentation.

Otherwise you may introduce mess, bugs, or checkin some large binary files polluting the repository.

Updated on 2023.09.16
