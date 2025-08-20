# CLI

A command line interface for interacting with the API.

## Installation

Install via npm:

    npm install -g @meltwater/mlt-cli

## Usage

    mlt <command>

## Commands

### mlt user

Get and set user information.

#### mlt user get

Get the current user.

#### mlt user set

Set the current user.

    mlt user set <email>

### mlt project

Get and set project information.

#### mlt project get

Get the current project.

#### mlt project set

Set the current project.

    mlt project set <project_id>

### mlt task

Create and get tasks.

#### mlt task create

Create a new task.

    mlt task create <task_name>

#### mlt task get

Get a task.

    mlt task get <task_id>

### mlt job

Create and get jobs.

#### mlt job create

Create a new job.

    mlt job create <job_name>

#### mlt job get

Get a job.

    mlt job get <job_id>

### mlt worker

Get and set worker information.

#### mlt worker get

Get the current worker.

#### mlt worker set

Set the current worker.

    mlt worker set <worker_id>

### mlt status

Get the status of the API.

    mlt status
