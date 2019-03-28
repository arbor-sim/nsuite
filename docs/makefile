.PHONY: all html force nuke

src_path:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
root:=$(realpath ${src_path}/..)

prefix?=${root}/build
docdir?=${prefix}/docs

custom_css:=${docdir}/_static/custom.css

all:: html ${custom_css}

${custom_css}: ${src_path}/static/custom.css
	cp "$<" "$@"

html:
	sphinx-build -b html -q ${src_path} ${docdir}

force:
	sphinx-build -a -E -b html -q ${src_path} ${docdir}

nuke:
	rm -rf ${docdir}
