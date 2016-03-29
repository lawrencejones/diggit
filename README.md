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
