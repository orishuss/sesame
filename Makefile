.PHONY: install uninstall release

install:
	src/sesame.sh --install

uninstall:
	src/sesame.sh --uninstall

release:
	mkdir -p release
	@read -p "What version is the new release? " version; \
		cp -r src/ sesame$${version}_release/; \
		tar cf sesame$${version}.tar sesame$${version}_release; \
		mv sesame$${version}.tar release/; \
		rm -r sesame$${version}_release/
