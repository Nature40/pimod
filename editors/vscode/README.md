# Pifile for Visual Studio Code

Syntax and language support for [Pifile](https://github.com/Nature40/pimod) files.

Highlighting follows the Pifile commands in this repository. The extension version is independent of the pimod release version.

## Features

- Recognizes `.Pifile` files as the Pifile language.
- Highlights Pifile commands: `INCLUDE`, `FROM`, `TO`, `INPLACE`, `PUMP`, `ADDPART`, `INSTALL`, `EXTRACT`, `PATH`, `WORKDIR`, `ENV`, `RUN`, `HOST`, `ZERO`, and `SHRINK`.
- Highlights shell syntax used in command arguments, including comments, strings, variables, and redirections.

## Run locally

Open this `editors/vscode` folder in Visual Studio Code and press F5. That launches an Extension Development Host with this extension loaded.

To build a package:

```sh
npx @vscode/vsce package
```

Run that command from this directory. It writes a `.vsix` you can install with **Extensions: Install from VSIX...**.

## Credit

Based on [disaac/vscode-pifile](https://github.com/disaac/vscode-pifile).
