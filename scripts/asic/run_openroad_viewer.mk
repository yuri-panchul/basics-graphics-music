include Makefile

# --stages available: floorplan, cts, placement, routing, signoff.
# For some reason "--stage signoff" does not work.
# Using "--stage routing" instead.

.PHONY: run_openroad_viewer
run_openroad_viewer:
	cd $(OPENLANE_DIR) && \
		$(ENV_COMMAND) sh -c "python3 gui.py --format def --viewer openroad --stage routing $(RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR)"
