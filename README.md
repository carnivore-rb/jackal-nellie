# Jackal Nellie

Run commands against a repository. That's it.

## Requirements

This service assumes the payload information provided via the code
fetcher service.

## Configuration

Available configuration options:

* `working_directory` - working directory on host system
* `script_name` - file name of nellie file (defaults to `.nellie`)
* `max_execution_time` - maximum number of seconds to allow execution

## Nellie file structure

Nellie supports two file styles:

1. Executable
2. JSON

### Executable format

If the file is not in a JSON format, nellie will attempt to execute
it using the `bash` shell.

### JSON format

Nellie also supports a JSON file with the following structure:

```json
{
  "commands": [
    "touch /tmp/test.txt"
  ],
  "environment": {
    "MY_VAR": "MY_VALUE"
  }
}
```

# Info

* Repository: https://github.com/carnivore-rb/jackal-nellie
* IRC: Freenode @ #carnivore
