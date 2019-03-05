.PHONY: html clean

src_path:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
root:=$(realpath ${src_path}/..)
bld_path:=${root}/build/docs

html:
	sphinx-build -b html -q ${src_path} ${bld_path}

clean:
	rm -rf ${bld_path}
