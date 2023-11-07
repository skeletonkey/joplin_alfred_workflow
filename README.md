# Joplin Alfred Workflow

Alfred Workflow to interact with the Joplin API.

## Requirements

- Curl
- Perl 5
  - JSON module

## Installation

### Workflow Installation

Find the latest release on the right-hand side of the main [README](https://github.com/skeletonkey/joplin_alfred_workflow) page (right side). Download the '.alfredworkflow' file for the release you wish to install. Next, open the file on your desktop - this should open/install the workflow in Alfred.

#### Workflow Configuration

In Alfred, select the Joplin Workflow and open the Configuration Build (top right, it looks like '(x)').
![Configuration Build](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/650cb170-dd02-4f2b-ad9a-144d17e9e131)

On the Environment Variables tab, provide your token for JOPLIN_TOKEN and ensure that JOPLIN_URL has the correct port.
![Env Vars](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/924a089c-492c-4f09-b207-bdba0ae89984)

### Joplin Web Clipper

To use Joplin's API, the Web Clipper needs to be enabled.

This is done by going to Joplin Preferences (Options) -> Web Clipper and enabling the web clipper.
![Joplin Clipper](https://github.com/skeletonkey/joplin_alfred_workflow/assets/1487600/59880df4-e59d-43d9-a27f-ecd1039e72ef)

Note the Port that it is running on and copy your Authorization Token.

### Curl

```bash
brew install curl
```

[Brew Install Insturctions](https://brew.sh/)

### Perl

Perl should be installed on your Mac device.

```bash
brew install perl
```

[Brew Install Insturctions](https://brew.sh/)

#### JSON Module

```bash
cpan install JSON
```

## Usage

### Search

#### jn _folder_

Create a new note and open it in the specified folder.

Currently only an empty note (no title, no body) is created.  [Issue #9](https://github.com/skeletonkey/joplin_alfred_workflow/issues/9) has been created to address this shortcoming.

#### js _search words_

Search all of Joplin for the string entered.

*BUG* currently, words separated with a space are treated as two tokens with an AND operation instead of one string.
