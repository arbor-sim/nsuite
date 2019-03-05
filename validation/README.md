# Layout / conventions for validation tests.

Each _model_ lives in its own subdirectory under `validation/`.
This document will detail the structure of tests to be run
under a model `example`.

## Model configuration

A model configuration comprises a model and an optional parameter set.

Parameter sets are simple text files containing a series of _key_=_value_
pairs, terminated by newlines. A parameter set named `set` for the model
`example` will be found in the file `example/set.param`.

A model configuration is referred to by '_model_/_paramsetname_'; '_model_'
alone is a shorthand for '_model_/default'.


## Run scripts

A 'run script' is an executable script that runs the model and validation for a
particular simulator. It takes an optional flag '-r' followed by two arguments:
the name of the simulator and the name of the parameter set.

Run scripts attempt to change to the directory in which the script resides, and then:

    1. Make any required cache and output directories.

    2. Run the simulator-specific model script. Conventionally, this will be a script
       in the current directory called 'run-_sim_', and will take an output file in the
       output directory as the first argument, followed by a key=value parameter settings
       taken from the .param file.

    3. Generate any required reference data for comparison, optionally checking for
       cached reference data. If '-r' was given to the run script, force the regeneration
       of any cached reference data.

    4. Run an analysis script on the simulator model output + reference data, directing output
       to the output subdirectory.

    5. Run a pass/fail test on the generated analysis data, and report result.

The run scripts will generally use helper functions defined in `model_common.sh`.
These require the `ns_base_path` variable to be set to the nsuite root directory.

   * `model_setup`

     Takes three or four arguments: the name of the model, an optional '-r' to indicate that
     reference data should be regenerated, the name of the simulator, and the name of parameter set.

     * Defines variables `model_name`, `model_refresh`, `model_sim`, `model_param`
       from the arguments.

     * Sets the corresponding `model_cache_dir` and `model_output_dir` paths, and creates
       these directories if they do not exist.

     * Reads the parameter data into `model_param_data`, and sets `model_status_path`
       to the path where the final pass or fail result should be written.

     * Prefixes the PATH variable with the current working directory and the nsuite
       install and common binary directories.

   * `model_find_cacheable`

     Looks for file in the current directory, and then in the model cache directory.
     Prints the path to the local or else cached file, and returns non-zero if the
     file does not exist.

   * `model_notify_pass_fail`

     Takes one parameter, 0 for pass or non-zero for fail (corresponding to e.g. the
     exit status of a test). It reports pass or fail status to stdout.
