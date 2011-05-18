# The PLUGIN_NAME variable determines the name of the final .so/.dll file. 
# It should  not include the .so/.dll postfix. 
# If left blank the name will default to 
# the project name

PLUGIN_NAME = 

# The flags passed to the compiler when building the application
# You can also set the following to override flags for a particular language:
#
#    CC_C_FLAGS, CC_CPP_FLAGS
#
# If the variable CC_MAP_FLAGS is set it overrides the flags passed to 
# compiler for the final link stage.

CC_FLAGS = 

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.


# Use the version of the plugin build from module_xmos_common
-include ../module_xmos_common/build/Makefile.plugin
-include ../../xcommon/module_xcommon/build/Makefile.plugin

clean: clean_common
