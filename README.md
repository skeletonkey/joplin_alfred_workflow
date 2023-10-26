# Joplin Alfred Workflow

Alfred Workflow to interact with the Joplin API.

## Requirements

* Curl
* Perl 5

## Installation

### Joplin Web Clipper

To use Joplin's API the Web Clipper needs to be enabled.

This is done by going to Joplin Prefernces (Options) -> Web Clipper and enable the web clipper.

Note the Port that it is running on and copy your Authorization Token.

### Workflow Installation

~~Find the latest release on the right-hand side of the main [README](https://github.com/skeletonkey/joplin_alfred_workflow) page (right side). Download the '.alfredworkflow' file for the release you wish to install. Next, open the file on your desktop - this should open/install the workflow in Alfred.~~

### Workflow Configuration

In Alfred select the Joplin Workflow and open the Configuration Build (top right, it looks like '(x)').

On the Environment Variables tab provide your token for JOPLIN_TOKEN and ensure that JOPLIN_URL has the correct port.

## Usage

### Search

#### js

Search all of Joplin for the string entered.
