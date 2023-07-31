include Makefile

ifeq ($(LAYOUT_VIEWER),)
  LAYOUT_VIEWER_OPTION =
else ifeq ($(LAYOUT_VIEWER),openroad)
  LAYOUT_VIEWER_OPTION = --viewer openroad
else ifeq ($(LAYOUT_VIEWER),klayout)
  LAYOUT_VIEWER_OPTION = --viewer klayout
else
  $(error Unrecognized LAYOUT_VIEWER=$(LAYOUT_VIEWER))
endif

.PHONY: run_layout_viewer
run_layout_viewer:
	cd $(OPENLANE_DIR) && \
		$(ENV_COMMAND) sh -c "python3 gui.py $(LAYOUT_VIEWER_OPTION) $(RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR)"
