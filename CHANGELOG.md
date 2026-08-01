# Changelog

## 0.0.10

- make search configurable
  - technically a breaking change as the old behavior is by last changed in Ascending order
  - old behavior can be restored by updating settings
- layout change to visually organize the workflow
- update CONTRIBUTING.md
- fix code coverage action

## 0.0.9

- self update: check GitHub releases in the background and offer the new version as a search result
- `ju` keyword to check for a new version on demand
- configuration to disable the automatic check or change how often it runs
- call curl directly instead of through a shell; a search containing a backtick used to be run as a command
- percent encode the whole query rather than a fixed list of characters
- creating a note whose title contains an apostrophe no longer fails
- accented and emoji characters survive searching and note creation
- searching for punctuation such as `(` no longer breaks the result list
- search results show when the note was last updated instead of an empty subtitle
- accented searches are encoded as UTF-8 rather than as a single latin-1 byte
- the background update check runs the refresh instead of quietly building a result list
- test suite, run on every pull request; `make test` and `make coverage`

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
