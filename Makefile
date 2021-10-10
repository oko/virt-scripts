VIRT_SCRIPTS_BIN = /opt/virt-scripts/bin

install:
	rm -rf $(VIRT_SCRIPTS_BIN)
	install -d $(VIRT_SCRIPTS_BIN)
	find src -type f -executable | tee /dev/stderr | xargs -r -IQ install -m 755 Q $(VIRT_SCRIPTS_BIN)
