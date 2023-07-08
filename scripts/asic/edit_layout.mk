include Makefile

.PHONY: edit_layout
edit_layout:
	cd $(OPENLANE_DIR) && \
		$(ENV_COMMAND) sh -c "klayout"
