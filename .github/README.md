# GitHub Actions Setup

This directory contains GitHub Actions workflows for automated CI/CD of the RbxTrace project.

## Workflows

### 1. Release and Publish (`release.yml`)

**Triggers:**

- Push to `main` branch with changes to `src/`, `wally.toml`, or `default.project.json`
- Manual trigger via GitHub Actions UI

**What it does:**

- Automatically detects version bump type based on commit messages
- Updates version in `wally.toml`
- Generates changelog entries
- Builds the project using Rojo
- Publishes to Wally registry
- Creates GitHub release with built assets
- Tags the release

**Setup Required:**

1. **Wally Authentication (Required for publishing to Wally):**
   - Go to [Wally](https://wally.run/) and login
   - Generate an authentication token
   - Add it as a repository secret named `WALLY_AUTH_TOKEN`
   - Go to: Repository Settings → Secrets and variables → Actions → New repository secret

### 2. CI/CD (`ci.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` branch

**What it does:**

- Validates `wally.toml` format
- Validates project structure and build process
- Checks version format consistency
- Performs basic linting on Luau files
- Security scanning for potential secrets

## Version Bumping

The release workflow automatically determines version bump type based on commit message keywords:

- **Major bump**: Commit messages containing "breaking" or "major"
- **Minor bump**: Commit messages containing "feat", "feature", or "minor"
- **Patch bump**: All other commits (default)

### Manual Version Control

You can manually trigger a release with a specific version bump:

1. Go to Actions tab in GitHub
2. Select "Release and Publish" workflow
3. Click "Run workflow"
4. Choose version bump type (patch/minor/major)

## Commit Message Guidelines

For automatic version detection to work properly, use conventional commit messages:

```
feat: add new logging feature          # triggers minor bump
fix: resolve memory leak issue         # triggers patch bump
feat!: breaking API change             # triggers major bump
docs: update README                    # triggers patch bump
```

## Setup Checklist

- [ ] Add `WALLY_AUTH_TOKEN` repository secret
- [ ] Ensure `main` branch is protected
- [ ] Enable GitHub Actions in repository settings
- [ ] Verify Rojo and Wally compatibility with your project

## Troubleshooting

### Failed Wally Publish

- Verify `WALLY_AUTH_TOKEN` is correctly set
- Check that package name in `wally.toml` matches your Wally account
- Ensure version number follows semantic versioning

### Failed GitHub Release

- Check that `GITHUB_TOKEN` has sufficient permissions
- Verify repository settings allow Actions to create releases

### Build Failures

- Ensure `default.project.json` is valid
- Check that all source files are properly structured
- Verify Rojo version compatibility

## File Structure

```
.github/
├── workflows/
│   ├── release.yml    # Main release and publish workflow
│   └── ci.yml         # Continuous integration testing
└── README.md          # This file
```

## Security Notes

- Never commit actual API tokens or secrets to the repository
- The workflows scan for potential secrets in source code
- Use GitHub repository secrets for sensitive information
- Review workflow permissions before enabling
