#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def setup(app):
    app.add_stylesheet('custom.css')

extensions = ['sphinx.ext.mathjax']
source_suffix = '.rst'
master_doc = 'index'

project = 'NSuite'
copyright = '2019, ETHZ & FZ Julich'
author = 'ETHZ & FZ Julich'

html_theme = "sphinx_rtd_theme"
html_static_path = ['static']
