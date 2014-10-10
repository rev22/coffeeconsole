TARGETS=coffee-script.js
# TARGETS=console.js inject.js prettify.js

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

%.html: %.html.coffee
	rm $@; (sh -c "coffee $< >$@.new" && mv $@.new $@ && touch -r $< $@) || rm -f $@

%.html: %.htmlcup
	(sh -c "coffee $< >$@.new" && mv $@.new $@ && touch -r $< $@) || rm -f $@

%.js: %.coffee
	coffee -c $<

coffee-script.js: ../../reflective-coffeescript/extras/coffee-script.js
	cp -av $< $@
