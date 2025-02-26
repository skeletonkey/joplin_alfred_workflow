# Joplin Alfred Workflow

Alfred Workflow to interact with the Joplin API.

## Requirements

- Curl
- Perl 5
  - JSON module

Perl 5 and Curl should be preinstalled on all Macs. The JSON module is provided by the workflow.

Hence, there shouldn't be a need to install anything before using the workflow.

## Installation

### Workflow Installation

Find the latest release on the right-hand side of the main [README](https://github.com/skeletonkey/joplin_alfred_workflow) page (right side). Download the '.alfredworkflow' file for the release you wish to install. Next, open the file on your desktop - this should open/install the workflow in Alfred.

#### Workflow Configuration

In Alfred, select the Joplin Workflow and open the Configuration Build (top right, it looks like '(x)').
![Configuration Build](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/650cb170-dd02-4f2b-ad9a-144d17e9e131)

On the Environment Variables tab, provide your token for JOPLIN_TOKEN and ensure that JOPLIN_URL has the correct Port.
![Env Vars](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/924a089c-492c-4f09-b207-bdba0ae89984)

### Joplin Web Clipper

To use Joplin's API, the Web Clipper needs to be enabled.

Web Clipper can be enabled by going to Joplin Preferences (Options) -> Web Clipper and enabling the web clipper.
![Joplin Clipper](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/59880df4-e59d-43d9-a27f-ecd1039e72ef)

Note the Port that it is running on and copy your Authorization Token.

## Usage

### Create

#### jn _folder_

Create a new note, in a specific folder with a specified name.

Type `jn` to select a folder, then enter the note title and press Enter to create it.

### Search

#### js _search words_

Search all of Joplin for the string entered.

_NOTE:_ Joplin search operates on 'Words'; therefore, partial strings may not return what you expect.

_BUG_ currently, words separated with a space are treated as two tokens with an AND operation instead of one string.

#### jt _search words_

Search Joplin Note Titles for the string entered.

_NOTE:_ Joplin search operates on 'Words'; therefore, partial strings may not return what you expect.
