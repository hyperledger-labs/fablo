# down, start, stop

Controls lifecycle of an already generated network.

## Syntax

```bash
fablo down
fablo start
fablo stop
```

## Behavior

- down: Stops and removes running network containers.
- stop: Stops containers without deleting generated artifacts.
- start: Restarts previously stopped containers.

## Example

```bash
fablo stop
fablo start
```

## Expected output

- Container lifecycle actions similar to Docker Compose workflows.
