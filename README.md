# Joplin Alfred Workflow

An Alfred Workflow to interact with the Joplin API.

## Requirements

- Curl
- Perl 5
  - JSON module

Perl 5 and Curl should be preinstalled on all Macs. The workflow provides the JSON module.

Hence, there shouldn't be a need to install anything before using the workflow.

## Installation

### Workflow Installation

Find the latest release on the right-hand side of the main [README](https://github.com/skeletonkey/joplin_alfred_workflow) page (right side). Download the '.alfredworkflow' file for the release you wish to install. Next, open the file on your desktop - this should open/install the workflow in Alfred.

This only has to be done once. From 0.0.9 onwards the workflow keeps itself up to date - see [Updates](#updates).

### Joplin Web Clipper

To use Joplin's API, the Web Clipper needs to be enabled.

Web Clipper can be enabled by going to Joplin Preferences (Options) -> Web Clipper and enabling the web clipper.
![Joplin Clipper](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/59880df4-e59d-43d9-a27f-ecd1039e72ef)

Note the Port that it is running on and copy your Authorization Token.

## Usage

### Create

#### jn _folder_

Create a new note in a specific folder with a specified name.

Type `jn` to select a folder, enter the note title, and press Enter to create it.

### Search

#### js _search words_

Search all of Joplin for the string entered.

_NOTE:_ Joplin search operates on 'Words'; therefore, partial strings may not return what you expect.

_BUG_ Currently, words separated with a space are treated as two tokens with an AND operation instead of one string.

#### jt _search words_

Search Joplin Note Titles for the string entered.

_NOTE:_ Joplin search operates on 'Words'; therefore, partial strings may not return what you expect.

## Updates

The workflow updates itself. Once a day a background check asks GitHub for the newest release; if one is
newer than the installed version, an extra result is added to the end of the `js` and `jt` results:

> Joplin Workflow 0.1.0 is available

Action that result and the workflow downloads the release and hands it to Alfred, which installs it over
the current copy. Your configuration (token, URL, keywords) is kept.

### ju

Check for a new version immediately rather than waiting for the daily check.

### Configuration

- **Notify About New Versions** - turn the daily background check off. `ju` keeps working either way.
  The check only adds a result; nothing is downloaded or installed until you select it.
- **Update Check Frequency (days)** - how long to wait between automatic checks. Defaults to 1.

Only releases that are not pre-releases and that carry exactly one `.alfredworkflow` file are considered.
Nothing beyond Curl and Perl 5 is needed; the check and the download both use Curl.
