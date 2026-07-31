# Joplin Alfred Workflow Contributor Guidelines

## Requirements

- Curl
- Perl 5

### Jundy::AlfredWorkflow

[This repository](https://github.com/skeletonkey/Jundy_AlfredWorkflow) contains all reusable code. You will also want to fork it.

## Tests

```
make test
```

`Test::More` and `prove` both ship with the Perl that Apple installs, so nothing needs installing first.
The tests run every pull request.

The suite never reaches the network, Joplin or GitHub: `t/bin/curl` shadows the real Curl on `PATH`,
records how it was called and replies with whatever the test asked for. That is deliberate - most of the
bugs worth catching here are about exactly what gets handed to Curl.

Tests run the scripts the same way Alfred does, from the workflow directory with no switches of their
own. Perl only honours the `-I` and `-s` on a script's `#!` line when it is started that way, so adding
switches to the command line quietly changes how the script parses its arguments.

### Coverage

```
make coverage
```

This one needs [`Devel::Cover`](https://metacpan.org/pod/Devel::Cover), which is not part of a default
Perl:

```
cpan Devel::Cover
```

Coverage is reported on every pull request but is not a gate.

## Packaging

`make alfredworkflow` builds the archive. Anything that should not ship to users - the tests included -
belongs in `.excluded-files`.

## Contribute

- create (or claim) an [issue](https://github.com/skeletonkey/joplin_alfred_workflow/issues)
  - assign it to yourself
  - all communication will be done through Github Issues
- submit pull request
  - a code owner should review and provide feedback within a week of submittal/response
  - the PR author is required to response to all feedback within a month of it being provided
  - PRs not responded to within 2 months will be removed
