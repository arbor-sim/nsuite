# Layout / conventions for validation tests.

Each _model_ lives in its own subdirectory under `validation/`.
This document will detail the structure of tests to be run
under a model `example`.

## Model configuration

A model configuration comprises a model and an optional parameter set.

Parameter sets are simple text files containing a series of _key_=_value_
pairs, terminated by newlines. A parameter set named `set` for the model
`example` will be found in the file `example/set.param`.

A model configuration is referred to by either the model name _model_ alone
(corresponding to no parameter set) or by _model_/_paramsetname_; the
example configuration above would have the name `example/set`.

## Run scripts

A 'run script' is an executable script that runs the model and validation for a particular
simulator. It will:
    1. Take the name of the simulator as the first argument.
    2. Confirm that the simulator model implementation exists and is executable.
    3. Test (and create if required) the output subdirectory.
    4. Collect any configuration key/value pairs from the command line.
    5. Run the simulator model implementation with the configuration key/values, directing output
       to the output subdirectory.
    6. Generate any required validation reference data (use the cache directory as required).
    7. Run an analysis script on the simulator model output + reference data, directing output
       to the output subdirectory.

The simulator model implementation will be an executable program or script with the name
_model__sim_ found either in the model directory or the binary installation directory.

The run scripts will generally use helper functions defined in `model_functions.sh`:

   * `find_model_impl`
     Takes name of simulator as first argument, and deduces model name from CWD.
     Exit with error if missing implementation script for model+sim, or else return
     path to script.

   * `make_model_out`
     Takes name of simulator and parameter set name.
     Create output directory for this model configuration and simulator run, based
     on nsuite environment set up. Returns path to this directory.

   * `read_model_params`
     Takes name of pararmeter set as argument.
     If paramer set name is non-empty, assert existence of corresponding `.param`
     file and emit the contents.

   * `die`
     Emit argument to stderr and exit with non-zero status.






