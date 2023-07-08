include Makefile

.PHONY: run_layout_editor
run_layout_editor:
	cd $(OPENLANE_DIR) && \
		$(ENV_COMMAND) sh -c "klayout"
