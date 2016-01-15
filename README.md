# diggit ![diggit Build Status](https://circleci.com/gh/lawrencejones/diggit.png)

This project is a collection of tools that aim to expose coding behavioural patterns by examining
how code changes over time in projects under version control.

## Abstract

When working on a large codebase, it is easy not to see all of the dependencies and relationships.
Can we build a tool that aids the developer by saying "People who changed this method, often also
changed this test", or "People who changed this SQL query, often also changed this config file". If
we didn't know about this relationship, this could help us to change the code in a reliable way.

Version control may have the data from which a tool could generate these suggestions. Source code
repositories contain a lot of information and there has been a good deal of work done in recent
years on mining them in order to answer different types of questions. Some of the outputs of this
can be seen in the papers presented at the [MSR](http://2013.msrconf.org/program.php) (Mining
Software Repositories) conference and the [TICOSA conference](http://www.ticosa.org/). Other
related work is Adam Tornhill's book Your Code as a Crime Scene
(https://pragprog.com/book/atcrime/code-as-a-crime-scene)

Goal

The goal of this project is to design and build a tool (probably an IDE plugin) that provides
context sensitive information mined from software repositories, based on the programmer’s current
task and coding context to help them understand and change large codebases reliably, giving them
useful information about relevant historical changes as they work.

## Spikes

### Code Overview

Can we pull data from a repo that enables us to identify how the architectural shape of the project
changed over time?

This represents an experiment in data parsing and presentation. Aims are to gain familiarity with
the git API and gain some experience with data visualisation toolkits, along with extract genuine
insights from the code.
