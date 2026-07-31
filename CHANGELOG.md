# Changelog

## 0.0.9

- self update: check GitHub releases in the background and offer the new version as a search result
- `ju` keyword to check for a new version on demand
- configuration to disable the automatic check or change how often it runs

## 0.0.8

- encode Alfred filter output as proper JSON
- create a release with the alfredworkflow archive when the version changes on main

## 0.0.7

- general house keeping
- create configuration section to all user full control
- add JSON module files; no need to install it
- only package the required files (plus LICENSE) in the archive

## 0.0.6

- update jn to be able to specify the title of the new note

## 0.0.5

- title search (jt) added

## 0.0.4

- better error handling if Joplin is not reachable

## 0.0.3

- CHANGELOG.md order change
- use Jundy::AlfredWorkflow::Filter::display
- jn - create new note (no title or body)

## 0.0.2

- set bundleid; this should allow for upgrading the workflow properly
- add CHANGELOG.md
- some error handling to provide feedback to user
- misc code clean up to standardize naming

## 0.0.1

- add `js` search
