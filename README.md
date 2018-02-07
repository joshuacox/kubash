# kubash
Kubash

[![Waffle.io - Columns and their card count](https://badge.waffle.io/joshuacox/kubash.svg?columns=all)](https://waffle.io/joshuacox/kubash)

### Oneliner

Install with one easy line

```
curl -L git.io/kubash|bash
```


### Usage

This script automates the setup and maintenance of a kubernetes cluster

```
kubash COMMAND
```

### Commands:

```
commands:

build - build a base image

provision - provision individual nodes

init - initialize the cluster

decommission - tear down the cluster and decommission nodes

show - show the analyzed input of the hosts file

ping - Perform ansible ping to all hosts

auto - Full auto will provision and initialize all hosts

masters - Perform initialization of masters

nodes - Perform initialization of nodes

dotfiles - Perform dotfiles auto configuration

grab - Grab the .kube/config from the master

hosts - Write ansible hosts file

dry - Perform dry run
```

### Options

These options are parsed using GNU getopt

```
options:

 -h --help - Print usage

 -c --csv FILE - Set the csv file to be parsed

 --parallel NUMBER_OF_THREADS - set the number of parallel jobs for tasks that support it

 -v --verbose - Increase the verbosity (can set multiple times to incrementally increase e.g. `-vvvv`

 --verbosity NUMBER - or you can set the verbosity directly

 --debug - adds the debug flag
```

There is an example csv file in this repo which shows how to compose this file

### Debugging

First start by adding a few -vvv to the command to bump up the verbosity e.g.

```
kubash -vvvvv init
```

or

```
kubash --verbosity 22 init
```

Alternatively there is an environment variable `VERBOSITY`

```
export VERBOSITY=25
kubash init
```

And you can also add a debug flag:

```
kubash --debug --verbosity 100 init
```

### Detailed documentation on the commands

[build](./docs/build.md)

try `kubash COMMAND --help`

### [GNU Parallel](https://www.gnu.org/software/parallel/)

This project takes advantage of [GNU Parallel](https://www.gnu.org/software/parallel/) gnu parallel and so should you, for more info see:

```
  O. Tange (2011): GNU Parallel - The Command-Line Power Tool,                                                                                                                                                     
  ;login: The USENIX Magazine, February 2011:42-47.                                                                                                                                                                
                                                       
```
