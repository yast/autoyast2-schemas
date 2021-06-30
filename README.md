# AutoYaST Schemas

This repository contains AutoYaST schemas for multiple (open)SUSE versions. **Beware it is still a
work in progress****. Check the TODO list at the end of this document.

## yast2-schema limitations

The [yast2-schema](https://github.com/yast/yast-schema) package contains the RNG schema to validate
AutoYaST profiles. The problem is that it only contains the schema for the (open)SUSE version where
the package is installed. Thus it is not possible, for instance, to validate an AutoYaST profile for
Leap 15.3 in a Leap 15.2 machine (or viceversa).

## Building all schemas

### The old way

To build the schema, you need the `rnc` and the `desktop` files of all modules, as listed in
[yast2-schema.spec](https://github.com/yast/yast-schema/blob/master/package/yast2-schema.spec#L41-L75).
Once all those packages are installed, the `collect.sh` script takes care of fetching all the
required files.

The problem? You are building the schema using only the packages from the distribution version where
you are compiling.

### The proposed way

Instead of relying on packages dependencies, we might have a repository which contains the `rnc` and
`desktop` files from different branches. This repository contains a Rake task that synchronizes all
those files for you.

This following command retrieves `rnc` and `desktop` files for all [known
branches](data/targets.yml) and store them under [src](src/). In order to avoid GitHub rate limits,
you should create a [personal access
token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token).

```sh
export GITHUB_ACCESS_TOKEN="your-access-token"
rake schema:update
```

If you want to update just one target, specify its name as argument:

```sh
bundle exec rake "schema:update[sle15sp3]"
```

Finally, generate the tarball (`rake tarball`) and use OBS to build the package.

## Requirements

In order to run the `schema:update` task you need [Octokit gem](https://rubygems.org/gems/octokit/).
You can find a package in the [devel:languages:ruby:extensions
project](https://build.opensuse.org/project/show/devel:languages:ruby:extensions).

# TODO

- [ ] Check whether the generated schemas are complete.
- [ ] Simplify the `collect.sh` script now that all assets are in a single repository.
- [ ] Check if we can simplify things by getting rid of the `desktop` files and centralizing all the
      `rnc` files instead of synchronizing them.
- [ ] Filter by architecture (s390, x86_64, etc.)
