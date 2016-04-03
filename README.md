# diggit ![diggit Build Status](https://circleci.com/gh/lawrencejones/diggit.png)

The goal of Diggit is to provide a tool capable of generating insights about
code changes in the context of all those that came before them. This tool would
be run in the code review process to aid decisions about whether the proposed
change will have a positive impact on the system.

Broadly speaking, the tool should be able to detect when...

- Files show signs of growing complexity
- Changes suggest the current architecture is hindering development
- Past modifications have included changes that are absent in the proposed
- Modifications are made to known problem hotspots

## Deployment

If deploying to heroku, it is required to configure the instance with all the
required environment variables, or the script will fail on boot. These variables
can be found in the `dummy-env` file or otherwise specified as `Prius` calls.

As each build requires a fresh javascript bundle, the heroku instance will also
require a node buildpack in addition to ruby. This can be added to the instance
by running...

```sh
rake heroku::configure_buildpacks
```

Running `heroku buildpacks` should now display something like the following,
indicating that both ruby and node buildpacks will be invoked during deployment.

```
=== diggit Buildpack URLs
1. heroku/nodejs
2. heroku/ruby
```
