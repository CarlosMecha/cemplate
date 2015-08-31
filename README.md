# Cemplate

A template engine for configuration files.

## Author

Carlos Mecha, 2015

- Version 0.1: Developed from 08/03/2015 and released on 08/31/2015.

## Instructions

This simple script reads one or multiple YAML files and renders a configuration
file using the values provided from these files.

```
Usage: ruby cemplate.rb [opts] <filename>

Specific options:
    -f, --force                      Overrides the output file if it already exists. Do it with precaution.
    -v, --verbose                    Run verbosely
    -s, --settings=FILE              Settings file (could be defined more than once)
    -o, --output=FILE                Output file

Common options:
    -h, --help                       Show this message
    -v, --version                    Show version
```

If the settings files are not defined, the script expects a `settings.yml` file. Also, more than
one file could be defined, giving preference to the later ones.

If the output file is not defined, the new file would be named as the template file without the `.cemp`
extension. e.g. my-conf.json.cemp will generate my-conf.json

## Examples
- `common.yml`:
    ```
    server:
        host: 10.0.0.1
        port: 8080
    ```

- `dev.yml`:
    ```
    server:
        host: localhost
    ```

- `my-config.json.cemp`:
    ```
    { 
        "server": {
            "url": "<%= server.host %>:<%= server.port %>"
        }
    }

    ```

If the script runs as:
```
$ ruby cemplate.rb --settings=common.yml my-config.json.cemp

my-config.json
{ 
    "server": {
        "url": "10.0.0.1:8080"
    }
}
```

But we can easly override these values if we are developing mode:

```
$ ruby cemplate.rb --settings=common.yml --settings=dev.yml my-config.json.cemp

my-config.json
{ 
    "server": {
        "url": "localhost:8080"
    }
}
```

## Tests
TODO.

## Contribute

These tiny pieces of code (notifications, mqlite, etc) are ideas or prototypes developed in ~6 hours. If you
find this code useful, feel free to do whatever you want with it. Help/ideas/bug reporting are also welcome.

Thanks!

