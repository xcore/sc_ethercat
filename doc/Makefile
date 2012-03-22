SPHINX_PROJECT_NAME=Ethercat
VERSION=0v1
DOXYGEN_DIRS=../../sc_ethercat/module_ethercat
SOURCE_INCLUDE_DIRS=../../sc_ethercat
XDOC_DIR ?= ../../xdoc
include $(XDOC_DIR)/Makefile.inc

all: html pdf
	@if [ ! -d ../../sc_ethercat_gh_pages ] ; then echo '**** no gh_pages checked out ****'; exit 0; else cp -r _build/html/* ../../sc_ethercat_gh_pages/; cp -r _build/html/.doctrees ../../sc_ethercat_gh_pages/; echo 'HTML files copied to sc_ethercat_gh_pages'; echo 'Now go to sc_ethercat_gh_pages, commit, and push to publish the documentation'; fi
