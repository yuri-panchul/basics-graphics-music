include Makefile

.PHONY: run_openroad_viewer
run_openroad_viewer:
	cd $(OPENLANE_DIR) && \
		$(ENV_COMMAND) sh -c "python3 gui.py --viewer openroad $(RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR)"
