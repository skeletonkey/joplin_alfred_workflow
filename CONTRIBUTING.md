# Joplin Alfred Workflow Contributor Guidelines

## TL:DR

- fork the [repo](https://github.com/skeletonkey/Jundy_AlfredWorkflow)
- create a branch with your work
- create PR against the [main](https://github.com/skeletonkey/joplin_alfred_workflow)

## Requirements

Minimum requirements should be part of a basic Mac install and not require additional installations.

- Curl
- Local copy of your forked code of [Joplin Alfred Workflow](https://github.com/skeletonkey/Jundy_AlfredWorkflow)
- Perl 5

## Tests

New code should be tested or existing tests extended to cover edge cases.

```sh
make test
```

The suite never reaches the network, Joplin or GitHub: `t/bin/curl` shadows the real Curl on `PATH`, records how it was called and replies with whatever the test asked for. That is deliberate - most of the bugs worth catching here are about exactly what gets handed to Curl.

Tests run the scripts the same way Alfred does, from the workflow directory with no switches of their own. Perl only honours the `-I` and `-s` on a script's `#!` line when it is started that way, so adding switches to the command line quietly changes how the script parses its arguments.

### Coverage

Coverage reporting requires [`Devel::Cover`](https://metacpan.org/pod/Devel::Cover), which is __NOT__ part of the default installation.

```sh
make coverage
make coverage-html
```

Coverage is reported on every pull request create and update - even on Draft PRs. Coverage output can be see in the associated [action workflow](https://github.com/skeletonkey/joplin_alfred_workflow/actions) -> Coverage -> Report Coverage Step (don't scroll down too much, it's right at the top).

## Packaging

`make alfredworkflow` builds the archive.

Any new files that should not ship to users belong in `.excluded-files`.

## Contribute

- create (or claim) an [issue](https://github.com/skeletonkey/joplin_alfred_workflow/issues)
  - assign it to yourself
  - all communication will be done through Github Issues
- submit pull request
  - a code owner should review and provide feedback within a week of submittal/response
  - the PR author is required to response to all feedback within a month of it being provided
  - PRs not responded to within 2 months will be removed
