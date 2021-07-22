# dart-samples/RoboDomo

[![MIT Licensed](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)
[![Powered by Modus_Create](https://img.shields.io/badge/powered_by-Modus_Create-blue.svg?longCache=true&style=flat&logo=data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgMzIwIDMwMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNOTguODI0IDE0OS40OThjMCAxMi41Ny0yLjM1NiAyNC41ODItNi42MzcgMzUuNjM3LTQ5LjEtMjQuODEtODIuNzc1LTc1LjY5Mi04Mi43NzUtMTM0LjQ2IDAtMTcuNzgyIDMuMDkxLTM0LjgzOCA4Ljc0OS01MC42NzVhMTQ5LjUzNSAxNDkuNTM1IDAgMCAxIDQxLjEyNCAxMS4wNDYgMTA3Ljg3NyAxMDcuODc3IDAgMCAwLTcuNTIgMzkuNjI4YzAgMzYuODQyIDE4LjQyMyA2OS4zNiA0Ni41NDQgODguOTAzLjMyNiAzLjI2NS41MTUgNi41Ny41MTUgOS45MjF6TTY3LjgyIDE1LjAxOGM0OS4xIDI0LjgxMSA4Mi43NjggNzUuNzExIDgyLjc2OCAxMzQuNDggMCA4My4xNjgtNjcuNDIgMTUwLjU4OC0xNTAuNTg4IDE1MC41ODh2LTQyLjM1M2M1OS43NzggMCAxMDguMjM1LTQ4LjQ1OSAxMDguMjM1LTEwOC4yMzUgMC0zNi44NS0xOC40My02OS4zOC00Ni41NjItODguOTI3YTk5Ljk0OSA5OS45NDkgMCAwIDEtLjQ5Ny05Ljg5NyA5OC41MTIgOTguNTEyIDAgMCAxIDYuNjQ0LTM1LjY1NnptMTU1LjI5MiAxODIuNzE4YzE3LjczNyAzNS41NTggNTQuNDUgNTkuOTk3IDk2Ljg4OCA1OS45OTd2NDIuMzUzYy02MS45NTUgMC0xMTUuMTYyLTM3LjQyLTEzOC4yOC05MC44ODZhMTU4LjgxMSAxNTguODExIDAgMCAwIDQxLjM5Mi0xMS40NjR6bS0xMC4yNi02My41ODlhOTguMjMyIDk4LjIzMiAwIDAgMS00My40MjggMTQuODg5QzE2OS42NTQgNzIuMjI0IDIyNy4zOSA4Ljk1IDMwMS44NDUuMDAzYzQuNzAxIDEzLjE1MiA3LjU5MyAyNy4xNiA4LjQ1IDQxLjcxNC01MC4xMzMgNC40Ni05MC40MzMgNDMuMDgtOTcuNDQzIDkyLjQzem01NC4yNzgtNjguMTA1YzEyLjc5NC04LjEyNyAyNy41NjctMTMuNDA3IDQzLjQ1Mi0xNC45MTEtLjI0NyA4Mi45NTctNjcuNTY3IDE1MC4xMzItMTUwLjU4MiAxNTAuMTMyLTIuODQ2IDAtNS42NzMtLjA4OC04LjQ4LS4yNDNhMTU5LjM3OCAxNTkuMzc4IDAgMCAwIDguMTk4LTQyLjExOGMuMDk0IDAgLjE4Ny4wMDguMjgyLjAwOCA1NC41NTcgMCA5OS42NjUtNDAuMzczIDEwNy4xMy05Mi44Njh6IiBmaWxsPSIjRkZGIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiLz4KPC9zdmc+)](https://moduscreate.com)

This directory contains implementations of a few of the [RoboDomo](https://Github.com/RoboDomo/) microservices.

At some point, a client may be implemented.

Each directory is a separate "project" in this monorepo.  They share custom packages in the pkg directory.

In the pkg directory, some of the packages are published on pub.dev:
* bravia/ - this package provides classes for monitoring and controlling Sony Bravia TVs.
* debug/ - this is a Dart implementation of TJ Holwaychuck's debug() for NodeJS and browser.
* myq/ - this package provides classes for monitoring and controlling MyQ garage door openers.
* statefulemitter/ - this package implements an EventEmitter that monitors its state, and when changed, it fires a
  'statechange' event.  You can think of this as the server-side equivalent of setState() in React.
  
The microservices all share the HostBase class defined in pkg/hostbase.

Some JavaScript-isms are implemented as well - JSON.stringify/JSON.parse in modus_JSON, for example.

The microservices monitor things and publish state updates via MQTT.  They receive commands to change state via MQTT as
well.  This is hellped by the HostBase class.

Microservices:
* bravia-microservice - monitor and control one or more Sony Bravia TVs.
* myq-microservice - monitor and control one or more MyQ garage door openers.
* presence-microservice - monitor persons' presence by seeing if their phone is present on the WiFi.
* weather-microservice - fetch weather conditions and forecast from here.com.

- [Getting Started](#getting-started)
- [How it Works](#how-it-works)
- [Developing](#developing)
  - [Prerequisites](#prerequisites)
  - [Testing](#testing)
  - [Contributing](#contributing)
- [Modus Create](#modus-create)
- [Licensing](#licensing)

# Getting Started

Pick a microservice you would like to try out, presence-microservice is easy, and cd to that directory.

From there, you do "pub get" to install the related packages and then you can run dart run bin/server.dart each time you
change your code.

# How it works

Each microservice has its own "thing" that it deals with.  Some microservices deal with cloud based APIs (myq) and
others work locally on the LAN (presence).  

RoboDomo microservices are designed to instantiate a derivitive of the HostBase class per instance of the thing to be
monitored.  For example, you might have a Sony Bravia TV in the bedroom and in the family room, so there would be a
separate instance of the BraviaHost (extends HostBase) class, one for each.

The HostBase derivitive instances can poll a remote or local API periodically and when state is obtained, setting 
thie HostBase's state will cause an MQTT message to be posted, but only if the state is truly changed.

The HostBase class is an abstract class.  Inheritors must implement a run() method (which does the polling) and a
command() method that handles  commands to alter state that come from MQTT.  So a message to the family room TV instance
will control that TV.

There is a robust ecosphere around NodeJS and JavaScript.  Finding modules that handle Bravia, for example, are easy to
find.  In Dart, we developed our own Bravia module and contributed it for the general public to use.

# Developing

When working on a single microservice, you can use dart run bin/server.dart.

You can use the build.sh script to build Docker containers for all the microservices.  Or you can use the
"docker-compose build" command to build it all.  You can use docker-compose up <service-name> to bring up one or all of
the microservices.


## Prerequisites

Docker is used to run (production) versions of the microservices.  You can use docker-compose without the -d switch to
run the microservices in debug mode as well.

## Contributing

PRs are welcome.

Ideally, you will fork this monorepo and do your work in a branch in your fork.  You can then submit PRs to have us
evaluate (and accept) your suggested changes.

# Modus Create

{replace dart-samples/RoboDomo in links below with the name of this project}

[Modus Create](https://moduscreate.com) is a digital product consultancy. We use a distributed team of the best talent in the world to offer a full suite of digital product design-build services; ranging from consumer facing apps, to digital migration, to agile development training, and business transformation.

<a href="https://moduscreate.com/?utm_source=labs&utm_medium=github&utm_campaign=dart-samples/RoboDomo"><img src="https://res.cloudinary.com/modus-labs/image/upload/h_80/v1533109874/modus/logo-long-black.svg" height="80" alt="Modus Create"/></a>
<br />

This project is part of [Modus Labs](https://labs.moduscreate.com/?utm_source=labs&utm_medium=github&utm_campaign=dart-samples/RoboDomo).

<a href="https://labs.moduscreate.com/?utm_source=labs&utm_medium=github&utm_campaign=dart-samples/RoboDomo"><img src="https://res.cloudinary.com/modus-labs/image/upload/h_80/v1531492623/labs/logo-black.svg" height="80" alt="Modus Labs"/></a>

# Licensing

This project is [MIT licensed](./LICENSE).

