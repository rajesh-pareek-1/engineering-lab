# JavaScript this, bind, apply, call, and Closures

## call

`call` executes a function immediately with a custom `this`.

```js
show.call(obj, 1, 2);
```

Key line:

```text
call executes now.
```

## apply

`apply` is like `call`, but arguments are passed as an array.

```js
show.apply(obj, [1, 2]);
```

## bind

`bind` returns a new function with fixed `this` and optional pre-filled arguments.

```js
const fn = show.bind(obj, 1);
fn(2);
```

Key line:

```text
bind returns later.
```

## setTimeout Trap

Wrong:

```js
setTimeout(show.call(obj), 0);
```

Why:

```text
show.call(obj) executes immediately and returns its result. setTimeout expects a function.
```

Correct:

```js
setTimeout(show.bind(obj), 0);
setTimeout(() => show.call(obj), 0);
```

## Method Extraction Bug

```js
const fn = obj.show;
setTimeout(fn, 0);
```

Problem:

```text
Function is detached from object, so this is lost.
```

Fix:

```js
setTimeout(obj.show.bind(obj), 0);
setTimeout(() => obj.show(), 0);
```

## Arrow vs Normal Function

| Function | this behavior |
| --- | --- |
| Normal function | Dynamic `this`, depends on caller |
| Arrow function | Lexical `this`, inherited from surrounding scope |

Key line:

```text
Arrow functions ignore bind/call/apply for this binding.
```

## Partial Application

```js
function multiply(a, b, c) {
  return a * b * c;
}

const doubleThen = multiply.bind(null, 2);
console.log(doubleThen(3, 4)); // 24
```

## Constructor plus bind

```js
function Person(name) {
  this.name = name;
}

const obj = { name: "Arena" };
const BoundPerson = Person.bind(obj);
const p = new BoundPerson("JS");

console.log(p.name); // JS
```

Rule:

```text
new beats bind. Constructor call creates a fresh this.
```

## Missing Arguments

```js
function show(a, b) {
  console.log(a, b);
}

show.call(null, 1);     // 1 undefined
show.apply(null, [1]);  // 1 undefined
```

Rule:

```text
JavaScript does not enforce argument count. Missing args become undefined.
```

## Closures

A closure is when a function remembers variables from its outer scope.

```js
function makeCounter() {
  let count = 0;

  return function () {
    count++;
    return count;
  };
}
```

Common loop trap:

```js
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
```

Output:

```text
3 3 3
```

Fix:

```js
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
```

## React / React Native Callback Line

```text
Most callback bugs come from lost this, stale closures, or functions executing now instead of being passed for later.
```

