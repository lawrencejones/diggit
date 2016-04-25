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

## Development

Running `rackup` will boot the development API server. Running `gulp` will
trigger the development BrowserSync environment.

Production bundles should not be used in development- instead, boot BrowserSync
which will start an HTTP proxy from port 4567 to 9292. This allows the API
server to listen on 9292 while BrowserSync serves front-end assets.

## Deployment

At time of writing diggit is deployed on a Digital Ocean droplet, with plans to
containerize the deployment process. The server is configured with Phusion
Passenger, instrumented by capistrano.

Environment variables should be configured on the server, with any missing
variables set to fail the boot.

As each build requires a fresh javascript bundle, the deployment will trigger
the npm `bundle` task to produce production front-end assets.

## Infrastructure

### [Bug Tracking](https://rollbar.com/lawrencejones/diggit-prod/)

[Rollbar](https://rollbar.com) is configured to listen for backend exceptions.
The listener is invoked via the `config.ru`.

### [OAuth App](https://github.com/settings/applications/331048)

This is the prod OAuth application for GitHub auths. Redirects are configured on
the `diggit-repo.com` domain.

### [diggit-bot](https://github.com/diggit-bot)

To interact with PR's, diggit must have an GitHub account. `diggit-bot` serves
this purpose.
