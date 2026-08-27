# Contributing Guidelines

Thank you for considering contributing to our project! We welcome contributions from everyone and appreciate your interest in making our project better.

## Sign off Your Work

The Developer Certificate of Origin (DCO) is a lightweight way for contributors to certify that they wrote or otherwise have the right to submit the code they are contributing to the project. Here is the full text of the [DCO](http://developercertificate.org/). Contributors must sign-off that they adhere to these requirements by adding a `Signed-off-by` line to commit messages.

```text
This is my commit message

Signed-off-by: John Doe <john.doe@fablo.com>
```

See `git help commit`:

```text
-s, --signoff
    Add Signed-off-by line by the committer at the end of the commit log
    message. The meaning of a signoff depends on the project, but it typically
    certifies that committer has the rights to submit this work under the same
    license and agrees to a Developer Certificate of Origin (see
    http://developercertificate.org/ for more information).
```

## Getting Started

1. **Fork the repository**: Click the "Fork" button at the top right corner of the repository's page on GitHub.
2. **Clone your fork**: Use `git clone` to clone the repository to your local machine.
3. **Set up remote upstream**: Add the original repository as a remote named "upstream" using `git remote add upstream [original repository URL]`.
4. **Create a new branch**: Use `git checkout -b [branch-name]` to create a new branch for your contribution.

## Making Changes

1. **Make your changes**: Implement the changes or additions you want to make. Please follow any coding standards and guidelines provided in the project.
2. **Test your changes**: Ensure that your changes work as expected and don't introduce any new issues. Depending on the scope of your changes you may rely on our CI pipelines or run the following tests:
   - **Unit tests**: Execute unit tests using the provided scripts. Use: `npm run test:unit`.
   - **End-to-End (E2E) tests**: Execute E2E tests using the provided scripts. Use: `npm run test:e2e`.
   - **Ent-to-End network tests**: Execute relevant shell scripts from `e2e-network` directory with E2E network tests.
3. **Update snapshots**: If you've made changes that affect snapshots (esp. any template changes), update them using `npm run test:e2e-update`.

## Running Fablo locally

You may want to verify some changes by running Fablo locally. To do so:

1. Execute `./fablo-build.sh` script to create a Fablo Docker image locally.
2. Use `./fablo.sh` from source root directory to call Fablo commands.

## Submitting Changes

1. **Push your changes**: Once you've made and tested your changes, push them to your forked repository with `git push origin [branch-name]`.
2. **Create a pull request**: Go to the original repository on GitHub and create a pull request from your forked branch to the main branch.
3. **Provide details**: Give your pull request a descriptive title and provide details about the changes you've made.
4. **Review process**: Your pull request will be reviewed by maintainers. Be responsive to any feedback and make necessary changes.

## Implementing an issue from a comment (maintainers)

Maintainers with write access can ask CI to implement an issue. Comment on the issue, first line only:

```text
@fablo-bot implement
```

`/implement` on the first line works the same way. Extra lines after that are passed to the agent as steering. The workflow verifies that the commenter currently has `write`, `maintain`, or `admin` permission on the repository.

The Action (`.github/workflows/implement-issue.yml`) then:

1. Acknowledges the comment
2. Runs the Jaiph workflow `.jaiph/implement_issue.jh` (Claude Code edits the tree; Jaiph does not push)
3. Runs `npm run build` and `npm run test:unit`
4. Opens a pull request with `Fixes #<n>` (draft if those checks still fail)

Full Fabric network tests stay on the existing Tests workflow. A human reviews and merges. The agent cannot edit `.github/` or `.jaiph/`, and it does not merge.

Until this workflow is on the default branch, test it with **Actions → Implement issue → Run workflow** and an issue number. A manual run targets the branch selected in the Actions UI; the comment trigger targets the repository's default branch.

Required repository secret (already used by docs-parity): `CLAUDE_CODE_OAUTH_TOKEN`.

PRs opened with the default `GITHUB_TOKEN` do not start Checks by themselves. Until the optional App is installed, manually dispatch the **Tests** workflow against the generated PR branch. Later, install the `fablo-bot` GitHub App (`FABLO_BOT_APP_ID`, `FABLO_BOT_PRIVATE_KEY`) so Checks start automatically. The App needs Contents, Issues, and Pull requests (read/write), no webhook, and no Workflows permission.

We appreciate your contributions and look forward to working with you!
