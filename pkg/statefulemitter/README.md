# StatefulEmitter

Child classes that inherit from EventEmitter can use the standard event emit, subscribe, unsubscribe, etc., methods of EventEmitter. This class adds a private _state member and a setState(object) and getState() method as well as getter/setter for the getState/SetState methods.

Whenever the state is changed, a 'statechange' event will be emitted with the previous state as argument.  This allows the handler to compare old state with new state, if desired.

