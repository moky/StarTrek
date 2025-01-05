# Star Trek: Interstellar Transport

[![License](https://img.shields.io/github/license/moky/StarTrek)](https://github.com/moky/StarTrek/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/moky/StarTrek/pulls)
[![Platform](https://img.shields.io/badge/Platform-Dart%203-brightgreen.svg)](https://github.com/moky/StarTrek/wiki)
[![Issues](https://img.shields.io/github/issues/moky/StarTrek)](https://github.com/moky/StarTrek/issues)
[![Repo Size](https://img.shields.io/github/repo-size/moky/StarTrek)](https://github.com/moky/StarTrek/archive/refs/heads/main.zip)
[![Tags](https://img.shields.io/github/tag/moky/StarTrek)](https://github.com/moky/StarTrek/tags)
[![Version](https://img.shields.io/pub/v/startrek)](https://pub.dev/packages/startrek)

[![Watchers](https://img.shields.io/github/watchers/moky/StarTrek)](https://github.com/moky/StarTrek/watchers)
[![Forks](https://img.shields.io/github/forks/moky/StarTrek)](https://github.com/moky/StarTrek/forks)
[![Stars](https://img.shields.io/github/stars/moky/StarTrek)](https://github.com/moky/StarTrek/stargazers)
[![Followers](https://img.shields.io/github/followers/moky)](https://github.com/orgs/moky/followers)

## Network Module

* Channel
	* Socket
* Connection
	* TimedConnection
	* ConnectionState
	* ConnectionDelegate
* Hub
	* ConnectionPool

```
/**
 *  Architecture:
 *
 *                 Connection        Connection      Connection
 *                 Delegate          Delegate        Delegate
 *                     ^                 ^               ^
 *                     :                 :               :
 *        ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                     :                 :               :
 *          +===+------V-----+====+------V-----+===+-----V------+===+
 *          ||  | connection |    | connection |   | connection |  ||
 *          ||  +------------+    +------------+   +------------+  ||
 *          ||          :                :               :         ||
 *          ||          :      HUB       :...............:         ||
 *          ||          :                        :                 ||
 *          ||     +-----------+           +-----------+           ||
 *          ||     |  channel  |           |  channel  |           ||
 *          +======+-----------+===========+-----------+============+
 *                 |  socket   |           |  socket   |
 *                 +-----^-----+           +-----^-----+
 *                       : (TCP)                 : (UDP)
 *                       :               ........:........
 *                       :               :               :
 *        ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                       :               :               :
 *                       V               V               V
 *                  Remote Peer     Remote Peer     Remote Peer
 */
```

* Ship
	* Arrival
	* Departure
* Dock
	* ArrivalHall
	* DepartureShip
* Porter
	* PorterDelegate
* Gate
	* PorterPool

```
/**
 *  Architecture:
 *
 *              Porter Delegate   Porter Delegate   Porter Delegate
 *                     ^                 ^               ^
 *                     :                 :               :
 *        ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                     :                 :               :
 *          +==========V=================V===============V==========+
 *          ||         :                 :               :         ||
 *          ||         :      Gate       :               :         ||
 *          ||         :                 :               :         ||
 *          ||  +------------+    +------------+   +------------+  ||
 *          ||  |   porter   |    |   porter   |   |   porter   |  ||
 *          +===+------------+====+------------+===+------------+===+
 *          ||  | connection |    | connection |   | connection |  ||
 *          ||  +------------+    +------------+   +------------+  ||
 *          ||          :                :               :         ||
 *          ||          :      HUB       :...............:         ||
 *          ||          :                        :                 ||
 *          ||     +-----------+           +-----------+           ||
 *          ||     |  channel  |           |  channel  |           ||
 *          +======+-----------+===========+-----------+============+
 *                 |  socket   |           |  socket   |
 *                 +-----^-----+           +-----^-----+
 *                       : (TCP)                 : (UDP)
 *                       :               ........:........
 *                       :               :               :
 *        ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                       :               :               :
 *                       V               V               V
 *                  Remote Peer     Remote Peer     Remote Peer
 */
```

## Finite State Machine

* State
	* Transition
* Machine
	* BaseMachine
	* AutoMachine
* MachineDelegate

## Others

* Runner
* Ticker
* Metronome

Copyright &copy; 2023 Albert Moky
