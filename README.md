# CMake GENERATED bug

A minimal example to showcase a potential bug in CMake.

## Usage

After cloning this repo to `$repo-root`, do the following:

```bash
cd $repo-root
mkdir build
cd build

# To showcase the expected behaviour
cmake -B . -S .. --log-context --log-level DEBUG -DTRIGGER_WRONG_SEARCH:BOOL=OFF

# To showcase the potential bug
cmake -B . -S .. --log-context --log-level DEBUG -DTRIGGER_WRONG_SEARCH:BOOL=ON
```

Depending on `TRIGGER_WRONG_SEARCH`, control flow differs in `cmake/AbsPath.cmake::is_generated`.
With `TRIGGER_WRONG_SEARCH=OFF`, a workaround is taken which avoids the potential bug.
With `TRIGGER_WRONG_SEARCH=ON`, `get_source_file_property` is called.
The latter tricks CMake into searching for non-generated files in the binary directory at generation time.
