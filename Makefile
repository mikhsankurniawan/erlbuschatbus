REBAR = $(shell which rebar3)

EPMD_PROC_NUM = $(shell ps -ef | grep epmd | grep -v "grep")

LOCAL_SUITES = "test/ebus_ps_SUITE,test/ebus_ps_local_SUITE,test/ebus_handler_SUITE"

.PHONY: all check_rebar compile clean distclean dialyzer test shell doc

all: check_rebar compile

compile: check_rebar
	$(REBAR) compile

clean: check_rebar
	rm -rf ebin/* test/*.beam logs log
	$(REBAR) clean

distclean: clean
	$(REBAR) clean --all
	rm -rf _build logs log doc *.dump *_plt *.crashdump priv

dialyzer: check_rebar
	$(REBAR) dialyzer

test: check_rebar check_epmd check_plt
	$(REBAR) do ct --name ct@127.0.0.1, cover
	rm -rf test/*.beam

local_test: check_rebar check_epmd
	$(REBAR) do ct --suite=$(LOCAL_SUITES), cover
	rm -rf test/*.beam

dist_test: check_rebar check_epmd
	$(REBAR) do ct --name ct@127.0.0.1 --suite=test/ebus_dist_SUITE, cover
	rm -rf test/*.beam

## The option '--readable=false' is added due to the compatibility issue of rebar3 with OTP 21
ci: check_epmd check_plt
	$(call get_rebar)
	$(REBAR) do ct --suite=$(LOCAL_SUITES) --readable=false, cover
	rm -rf rebar3

shell: check_rebar
	$(REBAR) shell

doc: check_rebar
	$(REBAR) edoc

check_rebar:
ifeq ($(REBAR),)
ifeq ($(wildcard rebar3),)
	$(call get_rebar)
else
	$(eval REBAR=./rebar3)
endif
endif

check_plt:
ifeq (,$(wildcard ./*_plt))
	@echo " ---> Running dialyzer ..."
	$(REBAR) dialyzer
endif

check_epmd:
ifeq ($(EPMD_PROC_NUM),)
	epmd -daemon
	@echo " ---> Started epmd!"
endif

define get_rebar
	curl -O https://s3.amazonaws.com/rebar3/rebar3
	chmod a+x rebar3
	./rebar3 update
	$(eval REBAR=./rebar3)
endef
